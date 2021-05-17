import 'dart:async';
import 'dart:convert';

import 'package:barcode_scan/gen/protos/protos.pbenum.dart';
import 'package:barcode_scan/platform_wrapper.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:dart_extensions/dart_extensions.dart';
import 'package:estore_app/blocs/table_cashier_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_pay_mode.dart';
import 'package:estore_app/enums/module_key_code.dart';
import 'package:estore_app/enums/order_payment_status_type.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/print_ticket_enum.dart';
import 'package:estore_app/enums/promotion_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/member/member.dart';
import 'package:estore_app/member/member_card_recharge_scheme.dart';
import 'package:estore_app/member/member_elec_coupon.dart';
import 'package:estore_app/member/member_utils.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_pay.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/pay_utils.dart';
import 'package:estore_app/order/table_utils.dart';
import 'package:estore_app/pages/table_card_pay_dialog.dart';
import 'package:estore_app/pages/table_cash_pay_dialog.dart';
import 'package:estore_app/pages/table_maling_pay_dialog.dart';
import 'package:estore_app/pages/table_member_coupon_dialog.dart';
import 'package:estore_app/pages/table_member_dialog.dart';
import 'package:estore_app/pages/table_order_bargain_dialog.dart';
import 'package:estore_app/pages/table_order_discount_dialog.dart';
import 'package:estore_app/pages/table_other_pay_dialog.dart';
import 'package:estore_app/pages/table_remark_dialog.dart';
import 'package:estore_app/printer/printer_helper.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';

class TablePayPage extends StatefulWidget {
  final Map<String, List<String>> parameters;

  TablePayPage({this.parameters});

  @override
  _TablePayPageState createState() => _TablePayPageState();
}

class _TablePayPageState extends State<TablePayPage> with SingleTickerProviderStateMixin {
  //订单逻辑处理
  TableCashierBloc _tableCashierBloc;

  //支付结果查询的时间片
  Timer _timer;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _tableCashierBloc = BlocProvider.of<TableCashierBloc>(context);
    assert(this._tableCashierBloc != null);

    //加载支付方式
    _tableCashierBloc.add(LoadPayment());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String orderId = widget.parameters["orderId"].first;

      OrderObject orderObject = await OrderUtils.instance.builderOrderObject(orderId);

      print("订单ID:$orderId");

      OrderUtils.instance.calculateOrderObject(orderObject);

      //加载
      _tableCashierBloc.add(InitTableCashierData(orderObject: orderObject));
    });
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  void dispose() {
    super.dispose();

    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, //输入框抵住键盘
      backgroundColor: Constants.hexStringToColor("#656472"),
      body: SafeArea(
        top: true,
        child: BlocBuilder<TableCashierBloc, TableCashierState>(
          cubit: this._tableCashierBloc,
          buildWhen: (previousState, currentState) {
            return true;
          },
          builder: (context, state) {
            return Container(
              padding: Constants.paddingAll(0),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#656472"),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  this._buildHeader(state),
                  this._buildContent(state),
                  this._buildFooter(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(TableCashierState state) {
    return Expanded(
      child: Container(
        padding: Constants.paddingAll(5),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: Constants.getAdapterHeight(120),
              padding: Constants.paddingSymmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#E6E6EB"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(text: "应收:¥", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                          TextSpan(text: "${state.orderObject?.receivableAmount}", style: TextStyles.getTextStyle(fontSize: 48, color: Constants.hexStringToColor("#333333"))),
                        ]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: RichText(
                        text: TextSpan(text: "待收:¥", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                          TextSpan(text: "${state.orderObject?.unreceivableAmount}", style: TextStyles.getTextStyle(fontSize: 48, color: Constants.hexStringToColor("#333333"))),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Space(
              height: Constants.getAdapterHeight(5),
            ),
            Visibility(
              visible: state.member != null,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: Constants.getAdapterHeight(100),
                    child: _buildMemberCoupon(state),
                  ),
                  Space(
                    height: Constants.getAdapterHeight(5),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: Constants.getAdapterHeight(210), //320
              child: _buildPayment(state),
            ),
            Space(
              height: Constants.getAdapterHeight(5),
            ),
            _buildCheckout(state),
            Space(
              height: Constants.getAdapterHeight(5),
            ),
            Expanded(
              child: _buildTableList(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableList(TableCashierState state) {
    var tableGroupBy = state.orderObject.items.groupBy<OrderItem, String>((x) => x.tableId);
    return Container(
      padding: Constants.paddingAll(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: tableGroupBy.length,
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          var tableId = tableGroupBy.keys.toList()[index];
          var table = state.orderObject.tables.lastWhere((x) => x.tableId == tableId);
          var items = tableGroupBy[tableId];

          return ExpandableNotifier(
            initialExpanded: true,
            child: ScrollOnExpand(
              child: Column(
                children: <Widget>[
                  ExpandablePanel(
                    theme: ExpandableThemeData(
                      headerAlignment: ExpandablePanelHeaderAlignment.center,
                      tapBodyToExpand: false,
                      tapBodyToCollapse: false,
                      hasIcon: false,
                    ),
                    header: Container(
                      padding: Constants.paddingAll(10),
                      decoration: BoxDecoration(
                        color: Constants.hexStringToColor("#E6E6EB"),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4.0)),
                      ),
                      child: Row(
                        children: [
                          ExpandableIcon(
                            theme: ExpandableThemeData(
                              expandIcon: Icons.arrow_right,
                              collapseIcon: Icons.arrow_drop_down,
                              iconColor: Constants.hexStringToColor("#333333"),
                              iconSize: 28.0,
                              iconRotationAngle: 3.1415926 / 2,
                              iconPadding: Constants.paddingOnly(right: 1),
                              hasIcon: true,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "${table.tableName}",
                              style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    expanded: _buildCartList(items),
                  ),
                  Space(
                    height: Constants.getAdapterHeight(5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartList(List<OrderItem> items) {
    return Container(
      padding: Constants.paddingAll(3),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.0)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        shrinkWrap: true,
        physics: new NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          var item = items[index];
          return Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#FFFFFF"),
                border: Border(bottom: BorderSide(width: 0, color: Constants.hexStringToColor("#E0E0E0"))),
              ),
              child: InkWell(
                child: Container(
                  padding: Constants.paddingLTRB(15, 15, 15, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildOrderItemMake(item),
                        ),
                      ),
                      Container(
                        padding: Constants.paddingAll(0),
                        width: Constants.getAdapterWidth(160),
                        alignment: Alignment.centerRight,
                        child: RichText(
                          text: TextSpan(text: "x", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#7A73C7")), children: <TextSpan>[
                            TextSpan(text: "${item.quantity}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                      Container(
                        padding: Constants.paddingAll(0),
                        width: Constants.getAdapterWidth(160),
                        alignment: Alignment.centerRight,
                        child: RichText(
                          text: TextSpan(text: "¥", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#7A73C7")), children: <TextSpan>[
                            TextSpan(text: "${item.receivableAmount}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) {
          if (index + 1 == items.length) {
            return Container();
          }
          return Divider(
            height: Constants.getAdapterHeight(2),
          );
        },
      ),
    );
  }

  List<Widget> _buildOrderItemMake(OrderItem master) {
    var lists = new List<Widget>();

    lists.add(Text(
      "${master.displayName}",
      style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#010101"), fontSize: 28),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ));
    lists.add(Space(height: Constants.getAdapterHeight(5)));

    //退货内容
    if (master.refundQuantity > 0) {
      lists.add(Text(
        "(退)${master.refundReason}x${master.refundQuantity}份",
        style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#666666"), fontSize: 24),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ));

      lists.add(Space(height: Constants.getAdapterHeight(5)));
    }

    //优惠内容
    if (master.promotions.length > 0) {
      var promotions = new List<Widget>();
      master.promotions.forEach((item) {
        promotions.add(Text(
          "${item.promotionType == PromotionType.Gift ? '${item.displayReason}x${master.giftQuantity}份' : '${item.displayReason}'}",
          style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#666666"), fontSize: 24),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ));
        promotions.add(Space(height: Constants.getAdapterHeight(5)));
      });
      lists.addAll(promotions);
    }

    //做法
    var flavors = new List<Widget>();
    if (StringUtils.isNotBlank(master.flavorNames)) {
      flavors.add(Text(
        "${master.flavorNames}",
        style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#666666"), fontSize: 24),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ));
      flavors.add(Space(height: Constants.getAdapterHeight(5)));
    }

    if (flavors.length > 0) {
      lists.addAll(flavors);
    }

    return lists;
  }

  ///构建结账
  Widget _buildCheckout(TableCashierState state) {
    return Container(
      padding: Constants.paddingAll(0),
      height: Constants.getAdapterHeight(110.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#E6E6EB"),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#E6E6EB")),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: Constants.paddingLTRB(20, 0, 0, 0),
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(text: "找零:¥", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                  TextSpan(text: "${state?.orderObject?.changeAmount}", style: TextStyles.getTextStyle(fontSize: 48, color: Constants.hexStringToColor("#333333"))),
                ]),
              ),
            ),
          ),
          Space(
            width: Constants.getAdapterWidth(5),
          ),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#7A73C7"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border.all(width: 0, color: Constants.hexStringToColor("#7A73C7")),
              ),
              child: InkWell(
                onTap: () async {
                  bool allSuccess = true;
                  String notifyMessage = "";

                  OrderObject orderObject = state.orderObject;
                  try {
                    //结算
                    if (orderObject == null) {
                      ToastUtils.show("订单不存在");
                      return;
                    }

                    if (orderObject.orderStatus != OrderStatus.WaitForPayment) {
                      ToastUtils.show("订单状态非法，不能进行付款");
                      return;
                    }

                    //支付清单为空
                    var isVerify = OrderUtils.instance.checkOrderFullPay(orderObject);
                    if (!isVerify) {
                      ToastUtils.show("未付款或未全额付款，请检查");
                      return;
                    }

                    if (orderObject.pays.length == 0) {
                      OrderUtils.instance.addDefaultZeroPay(orderObject);
                    }

                    //是否存在待核销的券，如果只存在折扣券，这里特殊处理，优先处理折扣券的核销
                    var existDiscountCoupon = state.orderObject.promotions.any((x) => x.promotionType == PromotionType.Coupon && StringUtils.isNotBlank(x.couponId));
                    var existCouponPay = state.orderObject.pays.any((x) => x.no == Constants.PAYMODE_CODE_COUPON && StringUtils.isNotBlank(x.couponId));
                    if (!existCouponPay && existDiscountCoupon) {
                      //不存在代金券支付，但是存在待核销折扣券，特殊处理
                      var couponResult = await _verificationCoupone(state.orderObject, new OrderPay());
                      if (!couponResult.item1) {
                        //核销折扣券失败

                        ToastUtils.show(couponResult.item2);

                        return;
                      }
                    }

                    //获取待支付的清单
                    var waitPayList = state.orderObject.pays.where((x) => x.status == OrderPaymentStatus.NonPayment).toList();
                    if (waitPayList != null && waitPayList.length > 0) {
                      for (var pay in waitPayList) {
                        bool success = false;
                        String message = "";

                        switch (pay.no) {
                          case Constants.PAYMODE_CODE_CARD: //储值卡
                            {
                              var cardPayResult = await _memberCardConsume(state.orderObject, pay);
                              success = cardPayResult.item1;
                              message = cardPayResult.item2;
                            }
                            break;
                          case Constants.PAYMODE_CODE_COUPON: //代金券
                            {
                              //这样判断是因为用了多张券后会一次核销完，后续的代金券循环只让过就可以了
                              if (pay.status == OrderPaymentStatus.NonPayment) {
                                var couponResult = await _verificationCoupone(state.orderObject, pay);
                                success = couponResult.item1;
                                message = couponResult.item2;
                              } else {
                                success = true;
                                message = "";
                              }
                            }
                            break;
                          default:
                            {
                              success = false;
                              message = "不支持的支付方式:${pay.name}(${pay.no})";
                            }
                            break;
                        }

                        if (!success) {
                          ToastUtils.show(message);
                          allSuccess = success;
                          notifyMessage = message;
                          break;
                        }
                      }
                    }

                    if (allSuccess) {
                      var saveOrderObjectResult = await OrderUtils.instance.saveTableOrderObject(orderObject);
                      notifyMessage = saveOrderObjectResult.item2;
                      if (saveOrderObjectResult.item1) {
                        ToastUtils.show("交易成功");

                        /// 打印小票
                        PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, orderObject);
                        await MemberUtils.instance.sendOrderTicket(orderObject);
                        NavigatorUtils.instance.goBackWithParams(context, "交易成功");
                      }
                    } else {
                      ToastUtils.show(notifyMessage, milliseconds: 5000);
                    }
                  } catch (e, stack) {} finally {}
                },
                child: Container(
                  width: Constants.getAdapterWidth(355),
                  child: Center(
                    child: Text("完成结账", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// 会员卡余额支付
  Future<Tuple2<bool, String>> _memberCardConsume(OrderObject order, OrderPay pay) async {
    bool success = false;
    String message = "";
    try {
      ToastUtils.show("正在进行会员卡[${pay.cardNo}]支付[${pay.paidAmount}]元...");

      //如果当前卡支付和会员是同一个会员，计算当前订单需要的积分，本次卡消费，同时进行积分
      double point = 0;
      // if (order.PointDealStatus != OrderPointDealStatus.已处理 && pay.CardNo == order.MemberNo)
      // {
      //   //计算积分值
      //   var pointResult = MemberUtils.Instance.CalculateMemberOrderPoint(this._orderObject.Member, this._orderObject, null);
      //   if (pointResult.Item1)
      //   {
      //     point = pointResult.Item3;
      //   }
      // }

      int pointInt = (point * 100).toInt();
      int payAmountInt = (pay.paidAmount * 100).toInt();

      FLogger.info(">>>>>>>>>>>>>>>>#####>>>$pay");

      var res = await MemberUtils.instance.httpMemberConsume(pay.payNo, pay.memberId, pay.memberMobileNo, pay.cardNo, pay.useConfirmed, pay.password, payAmountInt, pointInt);
      FLogger.info(">>>>>>>>>>>>>>>>#####>>>$res");

      if (res.item1) {
        var payResponse = res.item3;
        if (payResponse != null) {
          if (payResponse.status == 1) {
            pay.status = OrderPaymentStatus.Paid;
            pay.voucherNo = payResponse.voucherNo;
            pay.cardPrePoint = OrderUtils.instance.fen2YuanByInt(payResponse.prePoint);
            pay.cardAftPoint = OrderUtils.instance.fen2YuanByInt(payResponse.aftPoint);
            pay.accountName = payResponse.name;
            pay.cardFaceNo = payResponse.cardFaceNo;
            pay.cardPreAmount = OrderUtils.instance.fen2YuanByInt(payResponse.preAmount);
            pay.cardChangeAmount = OrderUtils.instance.fen2YuanByInt(payResponse.totalAmount);
            pay.cardAftAmount = OrderUtils.instance.fen2YuanByInt(payResponse.aftAmount);
            pay.cardPrePoint = OrderUtils.instance.fen2YuanByInt(payResponse.prePoint);
            pay.cardChangePoint = OrderUtils.instance.fen2YuanByInt(payResponse.pointValue);
            pay.cardAftPoint = OrderUtils.instance.fen2YuanByInt(payResponse.aftPoint);
            pay.payTime = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
            pay.memo = payResponse.memo;

            //订单中没有会员，则将支付的会员信息带入订单中
            if (StringUtils.isBlank(order.memberId)) {
              order.memberId = payResponse.memberId;
              order.cardFaceNo = payResponse.cardFaceNo;
              order.isMember = 1;
              order.memberMobileNo = payResponse.mobile;
              order.memberName = payResponse.name;
              order.memberNo = payResponse.cardNo;
            }

            // //如果支付和前期刷的会员是同一个会员，将积分信息带入主单中
            // if (this._orderObject.MemberId == payResponse.MemberId && order.PointDealStatus != OrderPointDealStatus.已处理)
            // {
            // order.AddPoint = DecimalUtils.Fen2Yuan(payResponse.PointValue);
            // order.PrePoint = DecimalUtils.Fen2Yuan(payResponse.PrePoint);
            // order.AftPoint = DecimalUtils.Fen2Yuan(payResponse.AftPoint);
            // order.AftAmount = DecimalUtils.Fen2Yuan(payResponse.AftAmount);
            // if (order.AddPoint > 0)
            // {
            // order.PointDealStatus = OrderPointDealStatus.已处理;
            // }
            // }

            ToastUtils.show("储值卡支付成功");

            success = true;
            message = "储值卡支付成功";
          } else {
            // //更新在线支付日志支付结果
            // OnLinePayLogUtils.UpdatePayLogPayStatus(onlinePayLogId, OnLinePayPayStatusEnum.失败, res.Item2, null);

            success = false;
            message = "储值卡[${pay.cardNo}]支付失败:${res.item2}";
          }
        }
      } else {
        // //更新在线支付日志支付结果
        // OnLinePayLogUtils.UpdatePayLogPayStatus(onlinePayLogId, OnLinePayPayStatusEnum.失败, res.Item2, null);
        success = false;
        message = "储值卡[${pay.cardNo}]支付失败:${res.item2}";
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("储值卡支付异常:" + e.toString());

      success = false;
      message = "储值卡支付异常";
    }
    return Tuple2(success, message);
  }

  Future<Tuple2<bool, String>> _verificationCoupone(OrderObject order, OrderPay pay) async {
    bool success = false;
    String message = "";
    try {
      ToastUtils.show("正在进行优惠券核销...");

      //找到需要核销的优惠券
      var couponIdList = new List<String>();
      //折扣券
      order.promotions.where((x) => x.promotionType == PromotionType.Coupon && StringUtils.isNotBlank(x.couponId)).forEach((x) {
        couponIdList.add(x.couponId);
      });

      //代金券
      var payCouponList = order.pays.where((x) => x.no == Constants.PAYMODE_CODE_COUPON && StringUtils.isNotBlank(x.couponId)).forEach((x) {
        couponIdList.add(x.couponId);
      });
      //var couponIdStr = couponIdList.join(",");
      // //增加在线支付日志
      // var onlinePayLogId = OnLinePayLogUtils.SaveNewPayLog(OnLinePayBusTypeEnum.销售, order.TradeNo, pay.PayNo, pay.PaidAmount, decimal.Zero, couponIdStr, PayChannelEnum.无, pay.No, pay.Name, decimal.Zero, pay.Pwd);

      String cardNo = "";
      if (null != order.member && null != order.member.defaultCard) {
        cardNo = order.member.defaultCard.cardNo;
      }

      if (couponIdList.length > 0) {
        var couponIdsStr = json.encode(couponIdList);
        FLogger.info("订单[${order.tradeNo}]开始核销优惠券$couponIdsStr");

        var verificationResult = await MemberUtils.instance.orderElecCouponChargeOff(order);

        print(">>>>####@@@>>>>>>$verificationResult");

        if (verificationResult.item1) {
          var data = verificationResult.item3;

          print(">>>>####@@@>>>>>>$data");

          if (Convert.toStr(data["status"]) == "1") {
            var tradeNo = data["tradeNo"].toString();
            FLogger.info("订单[${order.tradeNo}]核销优惠券$couponIdsStr成功");

            //更新在线支付日志支付结果
            //OnLinePayLogUtils.UpdatePayLogPayStatus(onlinePayLogId, OnLinePayPayStatusEnum.成功, data["status"].ToString(), tradeNo);

            //更新支付状态
            order.pays.forEach((x) {
              if (x.no == Constants.PAYMODE_CODE_COUPON && StringUtils.isNotBlank(x.couponId)) {
                x.status = OrderPaymentStatus.Paid;
                x.voucherNo = tradeNo;
              }
            });

            success = true;
            message = verificationResult.item2;
          } else {
            //更新在线支付日志支付结果
            //OnLinePayLogUtils.UpdatePayLogPayStatus(onlinePayLogId, OnLinePayPayStatusEnum.失败, result.Item2, null);
            success = true;
            message = verificationResult.item2;

            FLogger.info("订单[${order.tradeNo}]核销优惠券$couponIdsStr失败:${data["msg"]}");
          }
        } else {
          success = false;
          message = verificationResult.item2;
          FLogger.info("订单[${order.tradeNo}]核销优惠券$couponIdsStr失败:$message");
        }
      } else {
        success = false;
        message = "没有需要核销的卡券";
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("优惠券核销异常:" + e.toString());

      success = false;
      message = "优惠券核销异常";
    }
    return Tuple2(success, message);
  }

  //构建优惠券
  Widget _buildMemberCoupon(TableCashierState state) {
    Member member = state.member;
    bool isMember = member != null && member.id != null;
    var couponList = (isMember && member.couponList != null && member.couponList.length > 0) ? member.couponList : <MemberElecCoupon>[];

    if (!isMember) {
      return Container();
    }

    return Container(
      width: double.infinity,
      padding: Constants.paddingLTRB(20, 0, 10, 0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#E6E6EB"),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(text: "卡余额:", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                      TextSpan(text: "${state.member?.defaultCard?.totalAmount}", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333"))),
                    ]),
                  ),
                  Space(
                    width: Constants.getAdapterWidth(20),
                  ),
                  RichText(
                    text: TextSpan(text: "积分:", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                      TextSpan(text: "${state.member?.totalPoint}", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333"))),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          Ink(
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#E6E6EB"),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              border: Border.all(width: 1, color: Constants.hexStringToColor("#7A73C7")),
            ),
            child: InkWell(
              onTap: couponList.length > 0
                  ? () {
                      this._showCoupon(context, state.orderObject, state.member.couponList, state.couponSelected);
                    }
                  : null,
              child: Container(
                width: Constants.getAdapterWidth(240),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${couponList.length == 0 ? '没有优惠券' : '${couponList.length}张优惠券'}",
                        maxLines: 21,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#7A73C7"), fontSize: 32),
                      ),
                      Icon(
                        CommunityMaterialIcons.chevron_right,
                        size: Constants.getAdapterWidth(48),
                        color: Constants.hexStringToColor("#7A73C7"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //构建支付方式
  Widget _buildPayment(TableCashierState state) {
    var payModeMap = state.showPayModeList;
    //移动端可用的支付方式列表
    var availablePayNo = ["00", "01", "02", "06"]; //, "03" "07"
    List<PayMode> payModeList = [];
    payModeMap.forEach((key, value) {
      //当前显示的支付方式
      var currentPayMode = value.item1;
      if (availablePayNo.contains(currentPayMode.no)) {
        payModeList.add(currentPayMode);
      }
    });

    return Container(
      height: double.infinity,
      padding: Constants.paddingAll(0),
      child: GridView.builder(
        padding: Constants.paddingAll(0),
        itemCount: payModeList.length,
        itemBuilder: (BuildContext context, int index) {
          var currPayMode = payModeList[index];
          var imgUrl = "home/payment_default";
          var imgWidth = 48.0;
          var imgHeight = 48.0;
          switch (currPayMode.no) {
            case "00": //扫码
              {
                imgUrl = "home/payment_scan";
              }
              break;
            case "01": //现金
              {
                imgUrl = "home/payment_cash";
              }
              break;
            case "02": //储值卡
              {
                imgUrl = "home/payment_card";
              }
              break;
          }

          var selected = state.orderObject.pays.any((x) => x.no == currPayMode.no);

          return Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: selected ? Constants.hexStringToColor("#F8F7FF") : Constants.hexStringToColor("#E6E6EB"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border.all(width: 1, color: selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#E6E6EB")),
              ),
              child: InkWell(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                onLongPress: () async {
                  //优先判断已经选择过当前支付方式
                  var isExits = state.orderObject.pays != null && state.orderObject.pays.any((x) => x.no == currPayMode.no);
                  if (isExits) {
                    var orderPay = state.orderObject.pays.lastWhere((x) => x.no == currPayMode.no);
                    var newOrderObject = await OrderUtils.instance.clearPayment(state.orderObject, orderPay: orderPay);
                    this._tableCashierBloc.add(ClearPayment(newOrderObject));
                  }
                },
                onTap: () async {
                  //判断订单状态是否合法
                  if (state.orderObject.orderStatus != OrderStatus.WaitForPayment) {
                    ToastUtils.show("订单状态非法，不能进行付款");
                    return;
                  }

                  //判断是否已经满足结账条件
                  var receivableAmount = state.orderObject.paidAmount.abs();
                  var receivedAmount = state.orderObject.receivedAmount.abs();
                  if (receivedAmount >= receivableAmount) {
                    ToastUtils.show("已满足结账条件，可以直接结账");
                    return;
                  }

                  switch (currPayMode.no) {
                    case Constants.PAYMODE_CODE_CASH:
                      {
                        this._buildCashPay(context, state.orderObject, currPayMode, title: "${currPayMode.name}");
                      }
                      break;
                    case Constants.PAYMODE_CODE_MALING:
                      {
                        this._buildMalingPay(context, state.orderObject, currPayMode, title: "${currPayMode.name}");
                      }
                      break;
                    case Constants.PAYMODE_CODE_CARD:
                      {
                        //判断是否有会员信息
                        if (state.member != null) {
                          this._buildCardPay(context, state.orderObject, currPayMode, title: "${currPayMode.name}");
                        } else {
                          _loadVip(context, state.orderObject);
                        }
                      }
                      break;
                    case Constants.PAYMODE_CODE_SCANPAY:
                      {
                        var scanResult = await BarcodeScanner.scan(options: scanOptions);
                        if (scanResult.type == ResultType.Barcode) {
                          //扫码成功
                          var format = scanResult.format;
                          var payCode = scanResult.rawContent;
                          FLogger.info("扫码成功:$format,$payCode");
                          ToastUtils.show("扫码成功,开始支付...");

                          var payResult = await PayUtils.instance.scanPayResult(payCode, state.orderObject);
                          if (payResult.item1) {
                            var newOrderObject = await OrderUtils.instance.addOrderPayByScanPayResult(state.orderObject, payResult.item3);
                            //支付清单为空
                            var isVerify = OrderUtils.instance.checkOrderFullPay(newOrderObject);
                            if (!isVerify) {
                              ToastUtils.show("未付款或未全额付款，请检查");
                              return;
                            }
                            var saveOrderObjectResult = await OrderUtils.instance.saveTableOrderObject(newOrderObject);
                            if (saveOrderObjectResult.item1) {
                              ToastUtils.show("交易成功");

                              PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, newOrderObject);
                              await MemberUtils.instance.sendOrderTicket(newOrderObject);
                              NavigatorUtils.instance.goBackWithParams(context, "交易成功");
                            } else {
                              ToastUtils.show("${saveOrderObjectResult.item2}");
                            }
                          } else {
                            ToastUtils.show("${payResult.item2}");
                          }
                        }
                      }
                      break;
                    default:
                      {
                        this._buildOtherPay(context, state.orderObject, currPayMode, title: "${currPayMode.name}");
                      }
                      break;
                  }
                },
                child: Stack(
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    Container(
                      padding: Constants.paddingLTRB(3, 3, 3, 3),
                      child: Row(
                        children: <Widget>[
                          Space(
                            width: Constants.getAdapterWidth(3),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: LoadImage(
                              "$imgUrl",
                              holderImg: "home/product_noimg",
                              width: Constants.getAdapterWidth(imgWidth),
                              height: Constants.getAdapterHeight(imgHeight),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: Constants.paddingLTRB(10, 3, 10, 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    "${currPayMode.name}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                    style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32),
                                  ),
                                  Expanded(
                                    child: Conditional.single(
                                      context: context,
                                      conditionBuilder: (BuildContext context) => state.orderObject.pays != null && state.orderObject.pays.any((x) => x.no == currPayMode.no),
                                      widgetBuilder: (BuildContext context) => Align(
                                        alignment: Alignment.centerRight,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            RichText(
                                              text: TextSpan(text: "¥", style: TextStyles.getTextStyle(fontSize: 24, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                                                TextSpan(text: "${state.orderObject.pays.lastWhere((x) => x.no == currPayMode.no).amount}", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333"))),
                                              ]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      fallbackBuilder: (BuildContext context) => Align(
                                        alignment: Alignment.centerRight,
                                        child: RichText(
                                          text: TextSpan(text: "", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                                            TextSpan(text: "", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333"))),
                                          ]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: selected,
                      child: Positioned.directional(
                        start: Constants.getAdapterWidth(0),
                        top: Constants.getAdapterHeight(0),
                        width: Constants.getAdapterWidth(30),
                        height: Constants.getAdapterHeight(40),
                        textDirection: TextDirection.ltr,
                        child: Container(
                          alignment: Alignment.topCenter,
                          padding: Constants.paddingLTRB(0, 0, 0, 0),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: ImageUtils.getAssetImage("home/home_discount"),
                            ),
                          ),
                          child: Text(
                            "选",
                            style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Constants.getAdapterWidth(5),
          crossAxisSpacing: Constants.getAdapterHeight(5),
          childAspectRatio: Constants.getAdapterWidth(720) / Constants.getAdapterHeight(208),
        ),
      ),
    );
  }

  //优惠券选择
  void _showCoupon(BuildContext context, OrderObject orderObject, List<MemberElecCoupon> couponList, List<MemberElecCoupon> couponSelected, {String title = "", double width = 600, double height = 910}) {
    //弹出框
    YYDialog dialog;
    //关闭支付弹窗
    var onClose = () {
      dialog?.dismiss();
    };
    //支付方式确认<OrderPayArgs>
    var onAccept = (args) async {
      dialog?.dismiss();
    };

    //电子券选择
    var widget = TableMemberCouponDialog(
      orderObject,
      couponList,
      couponSelected,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  void _buildCardPay(BuildContext context, OrderObject orderObject, PayMode payMode, {String title = "", double width = 600, double height = 820}) {
    //弹出框
    YYDialog dialog;
    //关闭支付弹窗
    var onClose = () {
      dialog?.dismiss();
    };
    //支付方式确认<OrderPayArgs>
    var onAccept = (args) async {
      dialog?.dismiss();

      var orderPay = args.orderPay;
      var newOrderObject = await OrderUtils.instance.addPayment(orderObject, orderPay);
      _tableCashierBloc.add(AddPayment(newOrderObject));
    };

    //支付金额输入
    var widget = TableCardPayDialog(
      title,
      orderObject,
      payMode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  //加载会员认证界面
  void _showVipInfo(BuildContext context, OrderObject orderObject) {
    YYDialog dialog;

    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };

    //如果会员存在，显示会员详细信息
    var onCancel = (args) {
      dialog?.dismiss();

      this._tableCashierBloc.add(RefreshUi("${orderObject.id}", member: Member.cancel()));
    };

    var onChanged = (args) {
      dialog?.dismiss();

      this._tableCashierBloc.add(RefreshUi("${orderObject.id}", member: Member.cancel()));
      //重新加载会员认证界面
      _loadVip(context, orderObject);
    };

    var widget = TableMemberViewDialog(
      orderObject,
      onChanged: onChanged,
      onCancel: onCancel,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: 600, height: 700);
  }

  ///会员认证
  void _loadVip(BuildContext context, OrderObject orderObject, {String title = "", double width = 600, double height = 800}) {
    //弹出框
    YYDialog dialog;
    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };
    //会员认证
    var onAccept = (args) async {
      dialog?.dismiss();

      Member member = args.member;

      MemberCardRechargeScheme scheme;
      List<MemberElecCoupon> couponSelected = <MemberElecCoupon>[];

      if (member != null) {
        var couponResult = await MemberUtils.instance.httpElecCouponList(member.id, "", 1, 1, 1000);
        if (couponResult.item1) {
          member.couponList = couponResult.item3;
          //检测优惠券可用情况并排序返回
          MemberUtils.instance.checkCouponEffect(member.couponList, couponSelected, orderObject, topSelect: true);
        }

        if (member.defaultCard != null) {
          var schemeResult = await MemberUtils.instance.httpMemberCardRechargeSchemeQuery(member.defaultCard.cardNo);
          if (schemeResult.item1) {
            scheme = schemeResult.item4;
          }
        }
      }

      this._tableCashierBloc.add(RefreshUi("${orderObject.id}", member: member));
    };

    //会员认证UI
    var widget = TableMemberDialog(
      orderObject,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  ///构建抹零支付方式
  void _buildMalingPay(BuildContext context, OrderObject orderObject, PayMode payMode, {String title = "", double width = 610, double height = 820}) {
    //弹出框
    YYDialog dialog;
    //关闭支付弹窗
    var onClose = () {
      dialog?.dismiss();
    };
    //支付方式确认<OrderPayArgs>
    var onAccept = (args) async {
      dialog?.dismiss();

      var orderPay = args.orderPay;
      var newOrderObject = await OrderUtils.instance.addPayment(orderObject, orderPay);
      _tableCashierBloc.add(AddPayment(newOrderObject));
    };

    //支付金额输入
    var widget = TableMalingPayDialog(
      title,
      orderObject,
      payMode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  ///构建人民币支付方式
  void _buildCashPay(BuildContext context, OrderObject orderObject, PayMode payMode, {String title = "", double width = 610, double height = 820}) {
    //弹出框
    YYDialog dialog;
    //关闭支付弹窗
    var onClose = () {
      dialog?.dismiss();
    };
    //支付方式确认<OrderPayArgs>
    var onAccept = (args) async {
      dialog?.dismiss();

      var orderPay = args.orderPay;
      var newOrderObject = await OrderUtils.instance.addPayment(orderObject, orderPay);
      _tableCashierBloc.add(AddPayment(newOrderObject));
    };

    //支付金额输入
    var widget = TableCashPayDialog(
      title,
      orderObject,
      payMode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  ///构建其他支付方式
  void _buildOtherPay(BuildContext context, OrderObject orderObject, PayMode payMode, {String title = "", double width = 610, double height = 820}) {
    //弹出框
    YYDialog dialog;
    //关闭支付弹窗
    var onClose = () {
      dialog?.dismiss();
    };
    //支付方式确认<OrderPayArgs>
    var onAccept = (args) async {
      dialog?.dismiss();

      var orderPay = args.orderPay;
      var newOrderObject = await OrderUtils.instance.addPayment(orderObject, orderPay);
      _tableCashierBloc.add(AddPayment(newOrderObject));
    };

    //支付金额输入
    var widget = TableOtherPayDialog(
      title,
      orderObject,
      payMode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  Widget _buildHeader(TableCashierState state) {
    return Container(
      padding: Constants.paddingAll(0),
      height: Constants.getAdapterHeight(100.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(bottom: BorderSide(color: Constants.hexStringToColor("#F2F2F2"), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              NavigatorUtils.instance.goBackWithParams(context, "返回");
            },
            child: SizedBox(
              width: Constants.getAdapterWidth(90),
              height: double.infinity,
              child: Icon(
                Icons.arrow_back_ios,
                size: Constants.getAdapterWidth(48),
                color: Constants.hexStringToColor("#2B2B2B"),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "结算台",
                    style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#383838"), fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              //会员认证
              var orderObject = state.orderObject;
              if (orderObject != null && orderObject.orderStatus != OrderStatus.Completed && orderObject.orderStatus != OrderStatus.ChargeBack && orderObject.member != null) {
                //如果会员存在，显示会员详细信息
                _showVipInfo(this.context, orderObject);
              } else {
                var permissionAction = (args) {
                  _loadVip(this.context, orderObject);
                };
                AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_115, ModuleKeyCode.$_115.permissionCode, orderObject, permissionAction);
              }
            },
            child: SizedBox(
              width: Constants.getAdapterWidth(120),
              height: double.infinity,
              child: Icon(
                CommunityMaterialIcons.card_account_details_star_outline,
                size: Constants.getAdapterWidth(64),
                color: Constants.hexStringToColor("#7A73C7"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///构建底部工具栏
  Widget _buildFooter(TableCashierState state) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(15, 5, 5, 5),
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "共${state.orderObject.tables.length}桌",
            style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 36),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MaterialButton(
                  child: Text("整单折扣", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#FFFFFF"))),
                  minWidth: Constants.getAdapterWidth(130),
                  color: Constants.hexStringToColor("#9898A1"),
                  textColor: Constants.hexStringToColor("#FFFFFF"),
                  shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
                  onPressed: () async {
                    bool isGo = true;

                    if (state.orderObject != null) {
                      if (state.orderObject.pays != null && state.orderObject.pays.length > 0) {
                        isGo = false;
                        ToastUtils.show("已存在支付信息，禁止整单折扣，如需继续，请先清空支付");
                      }
                    }

                    if (isGo) {
                      var permissionAction = (args) {
                        _showOrderDiscount(this.context, state.orderObject);
                      };
                      AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_118, ModuleKeyCode.$_118.permissionCode, state.orderObject, permissionAction);
                    }
                  },
                ),
                Space(
                  width: Constants.getAdapterWidth(10),
                ),
                MaterialButton(
                  child: Text("整单议价", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#FFFFFF"))),
                  minWidth: Constants.getAdapterWidth(130),
                  color: Constants.hexStringToColor("#9898A1"),
                  textColor: Constants.hexStringToColor("#FFFFFF"),
                  shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
                  onPressed: () async {
                    var permissionAction = (args) {
                      _showOrderBargain(this.context, state.orderObject);
                    };
                    AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_117, ModuleKeyCode.$_117.permissionCode, state.orderObject, permissionAction);
                  },
                ),
                Space(
                  width: Constants.getAdapterWidth(10),
                ),
                MaterialButton(
                  child: Text("备注", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#FFFFFF"))),
                  minWidth: Constants.getAdapterWidth(90),
                  color: Constants.hexStringToColor("#9898A1"),
                  textColor: Constants.hexStringToColor("#FFFFFF"),
                  shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
                  onPressed: () async {
                    var permissionAction = (args) {
                      _showOrderRemark(this.context, state.orderObject);
                    };
                    AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_117, ModuleKeyCode.$_117.permissionCode, state.orderObject, permissionAction);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //加载整单折扣界面
  void _showOrderDiscount(BuildContext context, OrderObject orderObject) {
    YYDialog dialog;

    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };

    var onAccept = (args) async {
      dialog?.dismiss();

      OrderObject orderObject = args.orderObject;
      double discountRate = args.discountRate;
      String discountReason = args.discountReason;
      bool restoreOriginalPrice = args.restoreOriginalPrice;

      var changeOrderDiscountResult = await TableUtils.instance.changeOrderDiscount(orderObject, discountRate, discountReason, restoreOriginalPrice: restoreOriginalPrice);
      if (changeOrderDiscountResult.item1) {
        _tableCashierBloc.add(RefreshUi("${orderObject.id}"));
      } else {
        ToastUtils.show(changeOrderDiscountResult.item2);
      }
    };

    var widget = TableOrderDiscountDialog(
      orderObject,
      ModuleKeyCode.$_118.permissionCode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: 610, height: 1100);
  }

  //加载整单议价界面
  void _showOrderBargain(BuildContext context, OrderObject orderObject) {
    YYDialog dialog;

    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };

    var onAccept = (args) async {
      dialog?.dismiss();

      OrderObject orderObject = args.orderObject;
      double inputAmount = args.inputAmount;
      String bargainReason = args.bargainReason;
      bool restoreOriginalPrice = args.restoreOriginalPrice;

      var changeOrderBargainResult = await TableUtils.instance.changeOrderBargain(orderObject, inputAmount, bargainReason, restoreOriginalPrice: restoreOriginalPrice);
      if (changeOrderBargainResult.item1) {
        _tableCashierBloc.add(RefreshUi("${orderObject.id}"));
      } else {
        ToastUtils.show(changeOrderBargainResult.item2);
      }
    };

    var widget = TableOrderBargainDialog(
      orderObject,
      ModuleKeyCode.$_117.permissionCode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: 610, height: 1100);
  }

  //加载整单备注界面
  void _showOrderRemark(BuildContext context, OrderObject orderObject) {
    YYDialog dialog;

    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };

    var onAccept = (args) async {
      dialog?.dismiss();

      // OrderObject orderObject = args.orderObject;
      // double inputAmount = args.inputAmount;
      // String bargainReason = args.bargainReason;
      // bool restoreOriginalPrice = args.restoreOriginalPrice;
      //
      // var changeOrderBargainResult = await TableUtils.instance.changeOrderBargain(orderObject, inputAmount, bargainReason, restoreOriginalPrice: restoreOriginalPrice);
      // if (changeOrderBargainResult.item1) {
      //   _tableCashierBloc.add(RefreshUi("${orderObject.id}"));
      // } else {
      //   ToastUtils.show(changeOrderBargainResult.item2);
      // }
    };

    var widget = TableRemarkDialog(
      orderObject,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: 610, height: 900);
  }
}

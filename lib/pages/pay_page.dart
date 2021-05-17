import 'dart:async';
import 'dart:convert';

import 'package:barcode_scan/gen/protos/protos.pbenum.dart';
import 'package:barcode_scan/platform_wrapper.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_pay_mode.dart';
import 'package:estore_app/enums/online_pay_bus_type_enum.dart';
import 'package:estore_app/enums/order_payment_status_type.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/pay_parameter_sign_enum.dart';
import 'package:estore_app/enums/print_ticket_enum.dart';
import 'package:estore_app/enums/promotion_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/member/member_elec_coupon.dart';
import 'package:estore_app/member/member_utils.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_pay.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/pay_utils.dart';
import 'package:estore_app/pages/select_coupon_page.dart';
import 'package:estore_app/payment/leshua_pay_utils.dart';
import 'package:estore_app/payment/saobei_pay_utils.dart';
import 'package:estore_app/printer/printer_helper.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:estore_app/widgets/common_widget.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'card_pay_page.dart';
import 'cash_pay_page.dart';
import 'order_pay_page.dart';

class PayPage extends StatefulWidget {
  @override
  _PayPageState createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();

  //订单逻辑处理
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);

    //加载支付方式
    _cashierBloc.add(LoadPayment());

    WidgetsBinding.instance.addPostFrameCallback((_) async {});
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter, // 10% of the width, so there are ten blinds.
            colors: [Constants.hexStringToColor("#4AB3FD"), Constants.hexStringToColor("#F7F7F7")], // whitish to gray
            tileMode: TileMode.repeated, // repeats the gradient over the canvas
          ),
        ),
        child: SafeArea(
          top: true,
          child: BlocBuilder<CashierBloc, CashierState>(
              cubit: this._cashierBloc,
              buildWhen: (previousState, currentState) {
                return true;
              },
              builder: (context, cashierState) {
                return Container(
                  padding: Constants.paddingAll(0),
                  decoration: BoxDecoration(
                    color: Constants.hexStringToColor("#656472"),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      this._buildHeader(cashierState),
                      Expanded(
                        child: Container(
                          padding: Constants.paddingAll(5),
                          child: SizedBox(
                            width: double.infinity,
                            height: Constants.getAdapterHeight(200),
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
                                              TextSpan(text: "${cashierState.orderObject?.receivableAmount}", style: TextStyles.getTextStyle(fontSize: 48, color: Constants.hexStringToColor("#333333"))),
                                            ]),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: RichText(
                                            text: TextSpan(text: "待收:¥", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                                              TextSpan(text: "${cashierState.orderObject?.unreceivableAmount}", style: TextStyles.getTextStyle(fontSize: 48, color: Constants.hexStringToColor("#333333"))),
                                            ]),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Space(
                                  height: Constants.getAdapterHeight(10),
                                ),
                                Visibility(
                                  visible: cashierState.orderObject.member != null,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: Constants.getAdapterHeight(100),
                                        child: _buildMemberCoupon(cashierState),
                                      ),
                                      Space(
                                        height: Constants.getAdapterHeight(10),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: Constants.getAdapterHeight(210), //320
                                  child: _buildPayment(cashierState),
                                ),
                                Space(
                                  height: Constants.getAdapterHeight(10),
                                ),
                                _buildCheckout(cashierState),
                                Space(
                                  height: Constants.getAdapterHeight(10),
                                ),
                                Expanded(
                                  child: _buildCartList(cashierState),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }

  Widget _buildMemberCoupon(CashierState cashierState) {
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
                      TextSpan(text: "${cashierState.orderObject?.member?.defaultCard?.totalAmount}", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333"))),
                    ]),
                  ),
                  Space(
                    width: Constants.getAdapterWidth(20),
                  ),
                  RichText(
                    text: TextSpan(text: "积分:", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                      TextSpan(text: "${cashierState.orderObject?.member?.totalPoint}", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333"))),
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
              onTap: cashierState.couponList.length > 0
                  ? () {
                      this._selectCoupon(context, cashierState.orderObject, cashierState.couponList, cashierState.couponSelected);
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
                        "${cashierState.couponList.length == 0 ? '没有优惠券' : '${cashierState.couponList.length}张优惠券'}",
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

  Widget _buildPayment(CashierState cashierState) {
    var payModeMap = cashierState.showPayModeList;
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

          var selected = cashierState.orderObject.pays.any((x) => x.no == currPayMode.no);

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
                  var isExits = cashierState.orderObject.pays != null && cashierState.orderObject.pays.any((x) => x.no == currPayMode.no);
                  if (isExits) {
                    var orderPay = cashierState.orderObject.pays.lastWhere((x) => x.no == currPayMode.no);
                    var newOrderObject = await OrderUtils.instance.clearPayment(cashierState.orderObject, orderPay: orderPay);
                    this._cashierBloc.add(ClearPayment(newOrderObject));
                  }
                },
                onTap: () async {
                  //判断订单状态是否合法
                  if (cashierState.orderObject.orderStatus != OrderStatus.WaitForPayment) {
                    ToastUtils.show("订单状态非法，不能进行付款");
                    return;
                  }

                  //判断是否已经满足结账条件
                  var receivableAmount = cashierState.orderObject.paidAmount.abs();
                  var receivedAmount = cashierState.orderObject.receivedAmount.abs();
                  if (receivedAmount >= receivableAmount) {
                    ToastUtils.show("已满足结账条件，可以直接结账");
                    return;
                  }

                  switch (currPayMode.no) {
                    case Constants.PAYMODE_CODE_CASH:
                      {
                        this._buildCashPay(context, cashierState.orderObject, currPayMode, title: "${currPayMode.name}");
                      }
                      break;
                    case Constants.PAYMODE_CODE_BANK:
                      {
                        ToastUtils.show("${currPayMode.name}");
                      }
                      break;
                    case Constants.PAYMODE_CODE_CARD:
                      {
                        //判断是否有会员信息
                        if (cashierState.orderObject.member != null) {
                          this._buildCardPay(context, cashierState.orderObject, currPayMode, title: "${currPayMode.name}");
                        } else {
                          loadVip(context, cashierState.orderObject, this._cashierBloc);
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

                          var payResult = await PayUtils.instance.scanPayResult(payCode, cashierState.orderObject);
                          if (payResult.item1) {
                            var newOrderObject = await OrderUtils.instance.addOrderPayByScanPayResult(cashierState.orderObject, payResult.item3);
                            //支付清单为空
                            var isVerify = OrderUtils.instance.checkOrderFullPay(newOrderObject);
                            if (!isVerify) {
                              ToastUtils.show("未付款或未全额付款，请检查");
                              return;
                            }
                            var saveOrderObjectResult = await OrderUtils.instance.saveOrderObject(newOrderObject);
                            if (saveOrderObjectResult.item1) {
                              ToastUtils.show("交易成功");

                              PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, newOrderObject);
                              await MemberUtils.instance.sendOrderTicket(newOrderObject);
                              this._cashierBloc.add(NewOrderObject());

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
                        this._buildOrderPay(context, cashierState.orderObject, currPayMode, title: "${currPayMode.name}");
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
                                      conditionBuilder: (BuildContext context) => cashierState.orderObject.pays != null && cashierState.orderObject.pays.any((x) => x.no == currPayMode.no),
                                      widgetBuilder: (BuildContext context) => Align(
                                        alignment: Alignment.centerRight,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            RichText(
                                              text: TextSpan(text: "¥", style: TextStyles.getTextStyle(fontSize: 24, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                                                TextSpan(text: "${cashierState.orderObject.pays.lastWhere((x) => x.no == currPayMode.no).amount}", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333"))),
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
          mainAxisSpacing: Constants.getAdapterWidth(10),
          crossAxisSpacing: Constants.getAdapterHeight(10),
          childAspectRatio: Constants.getAdapterWidth(720) / Constants.getAdapterHeight(208),
        ),
      ),
    );
  }

  //优惠券选择
  void _selectCoupon(BuildContext context, OrderObject orderObject, List<MemberElecCoupon> couponList, List<MemberElecCoupon> couponSelected, {String title = "", double width = 600, double height = 800}) {
    //弹出框
    YYDialog dialog;
    //关闭支付弹窗
    var onClose = () {
      dialog?.dismiss();
    };
    //支付方式确认<OrderPayArgs>
    var onAccept = (args) async {
      //var orderPay = args.orderPay;
      //var newOrderObject = await OrderUtils.instance.addPayment(orderObject, orderPay);
      //_cashierBloc.add(AddPayment(newOrderObject));

      //dialog?.dismiss();
    };

    //电子券选择
    var widget = SelectCouponPage(
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
      var orderPay = args.orderPay;
      var newOrderObject = await OrderUtils.instance.addPayment(orderObject, orderPay);
      _cashierBloc.add(AddPayment(newOrderObject));

      dialog?.dismiss();
    };

    //支付金额输入
    var widget = CardPayPage(
      title,
      orderObject,
      payMode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  ///构建人民币支付方式
  void _buildCashPay(BuildContext context, OrderObject orderObject, PayMode payMode, {String title = "", double width = 600, double height = 820}) {
    //弹出框
    YYDialog dialog;
    //关闭支付弹窗
    var onClose = () {
      dialog?.dismiss();
    };
    //支付方式确认<OrderPayArgs>
    var onAccept = (args) async {
      var orderPay = args.orderPay;
      var newOrderObject = await OrderUtils.instance.addPayment(orderObject, orderPay);
      _cashierBloc.add(AddPayment(newOrderObject));

      dialog?.dismiss();
    };

    //支付金额输入
    var widget = CashPayPage(
      title,
      orderObject,
      payMode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  //支付结果查询的时间片
  Timer _timer;

  void _scanPay(String payCode, OrderObject orderObject) async {
    try {
      //获取当前支付方式
      var currentPayMode = await OrderUtils.instance.getPayModeByPayCode(payCode);
      //支付参数
      var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.Sale);
      //获取支付参数失败
      if (!payParameterResult.item1) {
        ToastUtils.show(payParameterResult.item2);
        return;
      }
      FLogger.info("适配到支付通道:$payParameterResult");

      var payParameter = payParameterResult.item3;
      var paySign = PayParameterSignEnum.fromName(payParameter.sign);
      switch (paySign) {
        case PayParameterSignEnum.LeshuaPay:
          {
            FLogger.info("适配到乐刷支付通道,支付码:$payCode,订单号:${orderObject.tradeNo},待支付金额:${orderObject.unreceivableAmount}");
            var payResult = await LeshuaPayUtils.paymentResult(currentPayMode, payParameter, payCode, orderObject.tradeNo, orderObject.unreceivableAmount);
            //支付不成功
            if (!payResult.item1) {
              ToastUtils.show(payResult.item2);
            } else {
              //查询状态
              if (payResult.item3) {
                //
                var payNo = payResult.item4.payNo;
                _timer = Timer.periodic(const Duration(milliseconds: 3000), (timer) async {
                  var queryResult = await LeshuaPayUtils.queryPayment(currentPayMode, payParameter, orderObject.tradeNo, payNo);
                  if (!queryResult.item1) {
                    ToastUtils.show(queryResult.item2);
                  } else {
                    ToastUtils.show(queryResult.item2);

                    timer.cancel();
                    timer = null;

                    var newOrderObject = await OrderUtils.instance.addOrderPayByScanPayResult(orderObject, queryResult.item3);

                    FLogger.info(">>>>@@@@@@@@>>>>>${newOrderObject.pays.length}");
                    FLogger.info(">>>>@@@@@@@@>>>>>${newOrderObject.pays}");

                    //支付清单为空
                    var isVerify = OrderUtils.instance.checkOrderFullPay(newOrderObject);

                    if (!isVerify) {
                      ToastUtils.show("未付款或未全额付款，请检查");
                      return;
                    }

                    var saveOrderObjectResult = await OrderUtils.instance.saveOrderObject(newOrderObject);
                    if (saveOrderObjectResult.item1) {
                      ToastUtils.show("交易成功");

                      PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, newOrderObject);
                      await MemberUtils.instance.sendOrderTicket(newOrderObject);

                      this._cashierBloc.add(NewOrderObject());
                      NavigatorUtils.instance.goBack(context);
                    }
                  }
                });
              } else {
                //支付成功
                ToastUtils.show(payResult.item2);

                var newOrderObject = await OrderUtils.instance.addOrderPayByScanPayResult(orderObject, payResult.item4);

                //支付清单为空
                var isVerify = OrderUtils.instance.checkOrderFullPay(newOrderObject);

                if (!isVerify) {
                  ToastUtils.show("未付款或未全额付款，请检查");
                  return;
                }

                var saveOrderObjectResult = await OrderUtils.instance.saveOrderObject(newOrderObject);
                if (saveOrderObjectResult.item1) {
                  ToastUtils.show("交易成功");

                  PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, newOrderObject);
                  await MemberUtils.instance.sendOrderTicket(newOrderObject);

                  this._cashierBloc.add(NewOrderObject());
                  NavigatorUtils.instance.goBack(context);
                }
              }
            }
          }
          break;
        case PayParameterSignEnum.SaobeiPay:
          {
            FLogger.info("适配到扫呗支付通道,支付码:$payCode,订单号:${orderObject.tradeNo},待支付金额:${orderObject.unreceivableAmount}");
            var payResult = await SaobeiPayUtils.paymentResult(currentPayMode, payParameter, payCode, orderObject.tradeNo, orderObject.unreceivableAmount);
            if (payResult.item1) {
              //需要查询支付状态
              if (payResult.item3) {
                var payNo = payResult.item4.payNo;
                String voucherNo = payResult.item4.voucherNo;
                String payTime = payResult.item4.payTime;

                var queryResult = await SaobeiPayUtils.queryPayment(currentPayMode, payParameter, orderObject.tradeNo, payNo, voucherNo, payTime);
                if (!queryResult.item1) {
                  ToastUtils.show(queryResult.item2);
                } else {
                  ToastUtils.show(queryResult.item2);

                  var newOrderObject = await OrderUtils.instance.addOrderPayByScanPayResult(orderObject, payResult.item4);

                  //支付清单为空
                  var isVerify = OrderUtils.instance.checkOrderFullPay(newOrderObject);

                  if (!isVerify) {
                    ToastUtils.show("未付款或未全额付款，请检查");
                    return;
                  }

                  var saveOrderObjectResult = await OrderUtils.instance.saveOrderObject(newOrderObject);
                  if (saveOrderObjectResult.item1) {
                    ToastUtils.show("交易成功");

                    PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, newOrderObject);
                    await MemberUtils.instance.sendOrderTicket(newOrderObject);

                    this._cashierBloc.add(NewOrderObject());
                    NavigatorUtils.instance.goBack(context);
                  }
                }
              } else {
                //支付成功
                ToastUtils.show(payResult.item2);

                var newOrderObject = await OrderUtils.instance.addOrderPayByScanPayResult(orderObject, payResult.item4);

                //支付清单为空
                var isVerify = OrderUtils.instance.checkOrderFullPay(newOrderObject);

                if (!isVerify) {
                  ToastUtils.show("未付款或未全额付款，请检查");
                  return;
                }

                var saveOrderObjectResult = await OrderUtils.instance.saveOrderObject(newOrderObject);
                if (saveOrderObjectResult.item1) {
                  ToastUtils.show("交易成功");

                  PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, newOrderObject);
                  await MemberUtils.instance.sendOrderTicket(newOrderObject);

                  this._cashierBloc.add(NewOrderObject());
                  NavigatorUtils.instance.goBack(context);
                }
              }
            } else {
              //支付不成功
              ToastUtils.show(payResult.item2);
            }
          }
          break;
        default:
          {
            ToastUtils.show("暂不支持的支付通道");
          }
          break;
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("扫码支付发生异常:" + e.toString());
    } finally {}
  }

  // ///构建扫码支付方式
  // void _buildScanPay(BuildContext context, OrderObject orderObject, {String title = "", double width = 600, double height = 820}) {
  //   //弹出框
  //   YYDialog dialog;
  //   //关闭支付弹窗
  //   var onClose = () {
  //     dialog?.dismiss();
  //   };
  //   //支付方式确认<OrderPayArgs>
  //   var onPayment = (orderObject, payResult) async {
  //     //直接关闭
  //     if (orderObject == null && payResult == null) {
  //       dialog?.dismiss();
  //     } else {
  //       var newOrderObject = await OrderUtils.instance.addOrderPayByScanPayResult(orderObject, payResult);
  //
  //       // this._cashierBloc.add(OrderObjectFinished(newOrderObject));
  //
  //       //支付清单为空
  //       var isVerify = OrderUtils.instance.checkOrderFullPay(newOrderObject);
  //
  //       if (!isVerify) {
  //         ToastUtils.show("未付款或未全额付款，请检查");
  //         return;
  //       }
  //
  //       var saveOrderObjectResult = await OrderUtils.instance.saveOrderObject(newOrderObject);
  //       if (saveOrderObjectResult.item1) {
  //         ToastUtils.show("订单保存成功");
  //
  //         this._cashierBloc.add(NewOrderObject());
  //
  //         NavigatorUtils.instance.goBack(context);
  //       }
  //     }
  //     dialog?.dismiss();
  //   };
  //
  //   //支付金额输入
  //   var widget = PayScanPage(
  //     title,
  //     orderObject,
  //     onPayment: onPayment,
  //     onClose: onClose,
  //   );
  //
  //   dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  // }

  ///构建通用的支付方式
  void _buildOrderPay(BuildContext context, OrderObject orderObject, PayMode payMode, {String title = "", double width = 600, double height = 820}) {
    //弹出框
    YYDialog dialog;
    //关闭支付弹窗
    var onClose = () {
      dialog?.dismiss();
    };
    //支付方式确认<OrderPayArgs>
    var onAccept = (args) async {
      var orderPay = args.orderPay;
      var newOrderObject = await OrderUtils.instance.addPayment(orderObject, orderPay);
      _cashierBloc.add(AddPayment(newOrderObject));

      dialog?.dismiss();
    };

    //支付金额输入
    var widget = OrderPayPage(
      title,
      orderObject,
      payMode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: width, height: height);
  }

  Widget _buildCartList(CashierState cashierState) {
    var items = cashierState.orderObject.items;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: Constants.getAdapterHeight(90),
          padding: Constants.paddingLTRB(20, 10, 10, 10),
          decoration: BoxDecoration(
            color: Constants.hexStringToColor("#E6E6EB"),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4.0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "订单信息",
                style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32),
              ),
              // Expanded(
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     crossAxisAlignment: CrossAxisAlignment.center,
              //     children: [
              //       MaterialButton(
              //         child: Text("折扣", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#FFFFFF"))),
              //         minWidth: Constants.getAdapterWidth(90),
              //         color: Constants.hexStringToColor("#7A73C7"),
              //         textColor: Constants.hexStringToColor("#FFFFFF"),
              //         shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
              //         onPressed: () async {
              //           //
              //         },
              //       ),
              //       Space(
              //         width: Constants.getAdapterWidth(10),
              //       ),
              //       MaterialButton(
              //         child: Text("议价", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#FFFFFF"))),
              //         minWidth: Constants.getAdapterWidth(90),
              //         color: Constants.hexStringToColor("#7A73C7"),
              //         textColor: Constants.hexStringToColor("#FFFFFF"),
              //         shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
              //         onPressed: () async {
              //           //
              //         },
              //       ),
              //       Space(
              //         width: Constants.getAdapterWidth(10),
              //       ),
              //       MaterialButton(
              //         child: Text("单注", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#FFFFFF"))),
              //         minWidth: Constants.getAdapterWidth(90),
              //         color: Constants.hexStringToColor("#7A73C7"),
              //         textColor: Constants.hexStringToColor("#FFFFFF"),
              //         shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
              //         onPressed: () async {
              //           //
              //         },
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: Constants.paddingAll(3),
            height: Constants.getAdapterHeight(400),
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#FFFFFF"),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.0)),
              border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                var item = items[index];
                //是否标注为选中状态
                var selected = (item.id == cashierState.orderItem.id);
                return Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: (selected ? Constants.hexStringToColor("#EDEAFF") : Constants.hexStringToColor("#FFFFFF")),
                      border: Border(bottom: BorderSide(width: 1, color: Constants.hexStringToColor("#E0E0E0"))),
                    ),
                    child: InkWell(
                      onTap: () {
                        //选择单行
                        _cashierBloc.add(SelectOrderItem(orderItem: item));
                      },
                      child: Container(
                        padding: Constants.paddingLTRB(15, 15, 15, 10),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: showOrderItemMake(item),
                              ),
                            ),
                            Container(
                              padding: Constants.paddingAll(0),
                              width: Constants.getAdapterWidth(160),
                              alignment: Alignment.centerRight,
                              child: Text("x${item.quantity}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#7A73C7"), fontSize: 32, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: Constants.paddingAll(0),
                              width: Constants.getAdapterWidth(160),
                              alignment: Alignment.centerRight,
                              child: Text("¥${item.receivableAmount}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#7A73C7"), fontSize: 32, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  ///构建结账
  Widget _buildCheckout(CashierState cashierState) {
    return Container(
      height: Constants.getAdapterHeight(120.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#F7F7F7"),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#F7F7F7")),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Container(
          //   width: Constants.getAdapterWidth(140),
          //   height: Constants.getAdapterHeight(90),
          //   child: RaisedButton(
          //     padding: Constants.paddingAll(0),
          //     child: Text(
          //       "折扣",
          //       style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36),
          //     ),
          //     color: Constants.hexStringToColor("#9898A1"),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(4.0),
          //     ),
          //     onPressed: () async {
          //       //
          //     },
          //   ),
          // ),
          // Space(
          //   width: Constants.getAdapterWidth(10),
          // ),
          // Container(
          //   width: Constants.getAdapterWidth(140),
          //   height: Constants.getAdapterHeight(90),
          //   child: RaisedButton(
          //     padding: Constants.paddingAll(0),
          //     child: Text(
          //       "议价",
          //       style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36),
          //     ),
          //     color: Constants.hexStringToColor("#9898A1"),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(4.0),
          //     ),
          //     onPressed: () async {
          //       //
          //     },
          //   ),
          // ),
          // Space(
          //   width: Constants.getAdapterWidth(10),
          // ),
          // Expanded(
          //   child: Padding(
          //     padding: Constants.paddingLTRB(25, 0, 0, 0),
          //     child: Text("共${cashierState.orderObject.totalQuantity.toInt()}件", style: TextStyles.getTextStyle(color: Color(0xff333333), fontSize: 36, fontWeight: FontWeight.bold)),
          //   ),
          // ),
          Visibility(
            visible: cashierState.orderObject.changeAmount > 0,
            child: Expanded(
              child: Container(
                padding: Constants.paddingLTRB(25, 0, 0, 0),
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(text: "找零:¥", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                    TextSpan(text: "${cashierState?.orderObject?.changeAmount}", style: TextStyles.getTextStyle(fontSize: 48, color: Constants.hexStringToColor("#333333"))),
                  ]),
                ),
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
                  //结算
                  if (cashierState.orderObject == null) {
                    ToastUtils.show("订单不存在");
                    return;
                  }

                  if (cashierState.orderObject.orderStatus != OrderStatus.WaitForPayment) {
                    ToastUtils.show("订单状态非法，不能进行付款");
                    return;
                  }

                  //应收款金额为零，这时没有任何支付记录，默认添加金额为零的现金收款
                  if (cashierState.orderObject.pays.length == 0) {
                    await OrderUtils.instance.addDefaultZeroPay(cashierState.orderObject);
                  }

                  //支付清单为空
                  var isVerify = OrderUtils.instance.checkOrderFullPay(cashierState.orderObject);
                  if (!isVerify) {
                    ToastUtils.show("未付款或未全额付款，请检查");
                    return;
                  }

                  bool allSuccess = true;
                  String notifyMessage = "";

                  //是否存在待核销的券，如果只存在折扣券，这里特殊处理，优先处理折扣券的核销
                  var existDiscountCoupon = cashierState.orderObject.promotions.any((x) => x.promotionType == PromotionType.Coupon && StringUtils.isNotBlank(x.couponId));
                  var existCouponPay = cashierState.orderObject.pays.any((x) => x.no == Constants.PAYMODE_CODE_COUPON && StringUtils.isNotBlank(x.couponId));
                  if (!existCouponPay && existDiscountCoupon) {
                    //不存在代金券支付，但是存在待核销折扣券，特殊处理
                    var couponResult = await _verificationCoupone(cashierState.orderObject, new OrderPay());
                    if (!couponResult.item1) {
                      //核销折扣券失败

                      ToastUtils.show(couponResult.item2);

                      return;
                    }
                  }

                  //获取待支付的清单
                  var waitPayList = cashierState.orderObject.pays.where((x) => x.status == OrderPaymentStatus.NonPayment).toList();
                  if (waitPayList != null && waitPayList.length > 0) {
                    for (var pay in waitPayList) {
                      bool success = false;
                      String message = "";

                      switch (pay.no) {
                        case Constants.PAYMODE_CODE_CARD: //储值卡
                          {
                            var cardPayResult = await _memberCardConsume(cashierState.orderObject, pay);
                            success = cardPayResult.item1;
                            message = cardPayResult.item2;
                          }
                          break;
                        case Constants.PAYMODE_CODE_COUPON: //代金券
                          {
                            //这样判断是因为用了多张券后会一次核销完，后续的代金券循环只让过就可以了
                            if (pay.status == OrderPaymentStatus.NonPayment) {
                              var couponResult = await _verificationCoupone(cashierState.orderObject, pay);
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
                    var saveOrderObjectResult = await OrderUtils.instance.saveOrderObject(cashierState.orderObject);
                    if (saveOrderObjectResult.item1) {
                      ToastUtils.show("交易成功");

                      PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, cashierState.orderObject);

                      await MemberUtils.instance.sendOrderTicket(cashierState.orderObject);

                      this._cashierBloc.add(NewOrderObject());
                      NavigatorUtils.instance.goBack(context);
                    }
                  } else {
                    ToastUtils.show(notifyMessage, milliseconds: 5000);
                  }
                },
                child: Container(
                  width: Constants.getAdapterWidth(180),
                  child: Center(
                    child: Text("结账", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
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

  Widget _buildHeader(CashierState cashierState) {
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
            onTap: () => NavigatorUtils.instance.goBack(context),
            child: SizedBox(
              width: Constants.getAdapterWidth(120),
              height: double.infinity,
              child: Icon(
                Icons.arrow_back_ios,
                size: Constants.getAdapterWidth(48),
                color: Constants.hexStringToColor("#2B2B2B"),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "结算台",
                style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#383838"), fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              //
              //await OrderUtils.instance.deleteAllOrderObject();
            },
            child: SizedBox(
              width: Constants.getAdapterWidth(120),
              height: double.infinity,
              // child: Icon(
              //   CommunityMaterialIcons.card_account_details_outline,
              //   size: Constants.getAdapterWidth(48),
              //   color: Constants.hexStringToColor("#2B2B2B"),
              // ),
            ),
          ),
        ],
      ),
    );
  }
}

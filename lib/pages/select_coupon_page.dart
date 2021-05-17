import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/member/member_elec_coupon.dart';
import 'package:estore_app/member/member_utils.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional.dart';
import 'package:flutter_conditional_rendering/conditional_switch.dart';

class SelectCouponPage extends StatefulWidget {
  final OrderObject orderObject;
  final List<MemberElecCoupon> couponList;
  final List<MemberElecCoupon> couponSelected;
  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  SelectCouponPage(this.orderObject, this.couponList, this.couponSelected, {this.onAccept, this.onClose});

  @override
  _SelectCouponPageState createState() => _SelectCouponPageState();
}

class _SelectCouponPageState extends State<SelectCouponPage> with SingleTickerProviderStateMixin {
  //业务逻辑处理
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);

    //加载优惠券列表
    _cashierBloc.add(SelectCoupon(widget.orderObject, couponList: widget.couponList, couponSelected: widget.couponSelected));

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashierBloc, CashierState>(
      cubit: this._cashierBloc,
      buildWhen: (previousState, currentState) {
        return true;
      },
      builder: (context, cashierState) {
        return Material(
          child: Container(
            padding: Constants.paddingAll(0),
            child: Column(
              children: <Widget>[
                ///顶部标题
                _buildHeader(),

                ///中部操作区
                _buildContent(cashierState),

                ///底部操作按钮
                _buildFooter(cashierState),
              ],
            ),
          ),
        );
      },
    );
  }

  ///构建内容区域
  Widget _buildContent(CashierState cashierState) {
    return Container(
      padding: Constants.paddingLTRB(25, 20, 25, 10),
      height: Constants.getAdapterHeight(600),
      width: double.infinity,
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: GridView.builder(
              padding: Constants.paddingAll(0),
              itemCount: cashierState?.couponList?.length,
              itemBuilder: (BuildContext context, int index) {
                var coupon = cashierState.couponList[index];
                var selected = cashierState.couponSelected.any((x) => x.couponNo == coupon.couponNo);
                return Container(
                  decoration: BoxDecoration(
                    color: Constants.hexStringToColor("#FFFFFF"),
                    borderRadius: BorderRadius.all(Radius.circular(6.0)),
                    border: Border.all(width: 1, color: selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#FFFFFF")),
                  ),
                  child: Row(
                    children: <Widget>[
                      ConditionalSwitch.single<int>(
                        context: context,
                        valueBuilder: (BuildContext context) => coupon.discountType,
                        caseBuilders: {
                          1: (BuildContext context) => Container(
                                width: Constants.getAdapterWidth(120),
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(text: "¥", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#FF8625")), children: <TextSpan>[
                                      TextSpan(text: "${coupon.discountValue}", style: TextStyles.getTextStyle(fontSize: 42, color: Constants.hexStringToColor("#FF8625"))),
                                    ]),
                                  ),
                                ),
                              ),
                          2: (BuildContext context) => Container(
                                width: Constants.getAdapterWidth(120),
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(text: "${coupon.discountValue ~/ 10}", style: TextStyles.getTextStyle(fontSize: 36, color: Constants.hexStringToColor("#FF8625")), children: <TextSpan>[
                                      TextSpan(text: "折", style: TextStyles.getTextStyle(fontSize: 42, color: Constants.hexStringToColor("#FF8625"))),
                                    ]),
                                  ),
                                ),
                              ),
                        },
                        fallbackBuilder: (BuildContext context) => Text('不支持', style: TextStyles.getTextStyle(fontSize: 42, color: Constants.hexStringToColor("#FF8625"))),
                      ),
                      _buildVerticalSeparator(selected: selected, width: 1, height: 5),
                      Expanded(
                        child: Container(
                          padding: Constants.paddingLTRB(20, 10, 0, 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text("${coupon.name}", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#000000"))),
                              Space(height: Constants.getAdapterHeight(5)),
                              Text("适用范围:${coupon.fitRangeDes}", style: TextStyles.getTextStyle(fontSize: 24, color: Constants.hexStringToColor("#000000"))),
                              Space(height: Constants.getAdapterHeight(5)),
                              Conditional.single(
                                context: context,
                                conditionBuilder: (BuildContext context) => coupon.enable == true,
                                widgetBuilder: (BuildContext context) => Text("有效期至:${coupon.effectiveTime}", style: TextStyles.getTextStyle(fontSize: 20, color: Constants.hexStringToColor("#000000"))),
                                fallbackBuilder: (BuildContext context) => Text("不可用:${coupon.reason}", style: TextStyles.getTextStyle(fontSize: 20, color: Constants.hexStringToColor("#FF3600"))),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildVerticalSeparator(selected: selected, enable: coupon.enable),
                      Material(
                        color: Colors.transparent,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: coupon.enable ? (selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#FF8625")) : Constants.hexStringToColor("#656472"),
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(4.0)),
                            border: Border.all(width: 1, color: coupon.enable ? (selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#FF8625")) : Constants.hexStringToColor("#656472")),
                          ),
                          child: InkWell(
                            onTap: coupon.enable
                                ? () async {
                                    //当前订单
                                    var orderObject = OrderObject.clone(cashierState.orderObject);
                                    //会员全部优惠券
                                    List<MemberElecCoupon> couponList = cashierState.couponList ?? <MemberElecCoupon>[];
                                    //会员已选优惠券清单
                                    List<MemberElecCoupon> couponSelected = (cashierState.couponSelected ?? <MemberElecCoupon>[]).map((e) => MemberElecCoupon.clone(e)).toList();

                                    //如果已经存在，则移除
                                    if (couponSelected.any((x) => x.couponNo == coupon.couponNo)) {
                                      couponSelected.removeWhere((x) => x.couponNo == coupon.couponNo);
                                    } else {
                                      var newCoupon = MemberElecCoupon.clone(coupon);
                                      newCoupon.selected = true;
                                      couponSelected.add(newCoupon);
                                    }

                                    //处理折扣券
                                    await MemberUtils.instance.processDiscountCoupon(couponList, couponSelected, orderObject);

                                    //处理代金券
                                    await MemberUtils.instance.processCashCoupon(couponList, couponSelected, orderObject);

                                    //试算可用
                                    MemberUtils.instance.checkCouponEffect(couponList, couponSelected, orderObject, topSelect: false);

                                    //整单重算
                                    OrderUtils.instance.calculateOrderObject(orderObject);

                                    this._cashierBloc.add(SelectCoupon(
                                          orderObject,
                                          couponList: cashierState.couponList,
                                          couponSelected: couponSelected,
                                        ));
                                  }
                                : null,
                            child: Container(
                              width: Constants.getAdapterWidth(100),
                              child: Center(
                                child: Conditional.single(
                                  context: context,
                                  conditionBuilder: (BuildContext context) => coupon.enable == true,
                                  widgetBuilder: (BuildContext context) => Text(
                                    selected ? "已经\n选择" : "立即\n使用",
                                    style: TextStyles.getTextStyle(fontSize: 30, color: Constants.hexStringToColor("#FFFFFF")),
                                  ),
                                  fallbackBuilder: (BuildContext context) => Text(
                                    "不可\n使用",
                                    style: TextStyles.getTextStyle(fontSize: 30, color: Constants.hexStringToColor("#FFFFFF")),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: Constants.getAdapterWidth(10),
                crossAxisSpacing: Constants.getAdapterHeight(0),
                childAspectRatio: 332 / 80,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalSeparator({bool selected = false, bool enable = true, double width = 2.0, double height = 3.0}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxHeight = constraints.heightConstraints().maxHeight;
        final dashWidth = width;
        final dashHeight = height;
        final dashCount = (boxHeight / (2 * dashHeight)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: enable ? (selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#FF8625")) : Constants.hexStringToColor("#656472")),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.vertical,
        );
      },
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: Constants.getAdapterHeight(90.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#7A73C7"),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#7A73C7")),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: Constants.paddingOnly(left: 15),
              alignment: Alignment.centerLeft,
              child: Text("选择优惠券", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 32)),
            ),
          ),
          InkWell(
            onTap: () {
              if (widget.onClose != null) {
                widget.onClose();
              }
            },
            child: Padding(
              padding: Constants.paddingSymmetric(horizontal: 15),
              child: Icon(CommunityMaterialIcons.close_box, color: Constants.hexStringToColor("#FFFFFF"), size: Constants.getAdapterWidth(56)),
            ),
          ),
        ],
      ),
    );
  }

  ///构建底部工具栏
  Widget _buildFooter(CashierState cashierState) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(0, 14, 0, 16),
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(180),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("取消", style: TextStyles.getTextStyle(fontSize: 32, color: Color(0xFF333333))),
            ),
            color: Color(0xFFD0D0D0),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose();
              }
            },
          ),
          Space(
            width: Constants.getAdapterWidth(20),
          ),
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(180),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("确定", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#FFFFFF"))),
            ),
            color: Constants.hexStringToColor("#7A73C7"),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () {
              //
            },
          ),
        ],
      ),
    );
  }
}

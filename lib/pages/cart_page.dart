import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/enums/module_key_code.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/business_utils.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/common_widget.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/spinner_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  //业务逻辑处理
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {});
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, //输入框抵住键盘
      backgroundColor: Constants.hexStringToColor("#656472"),
      body: SafeArea(
        child: BlocListener<CashierBloc, CashierState>(
          cubit: this._cashierBloc,
          listener: (context, state) {
            //购物车商品数量为0的情况下跳转到点单界面
            if (state.orderObject.items.length == 0) {
              NavigatorUtils.instance.goBack(context);
            }
          },
          child: BlocBuilder<CashierBloc, CashierState>(
            cubit: this._cashierBloc,
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
                    this._buildSettlement(state),
                    Expanded(
                      child: Container(
                        padding: Constants.paddingAll(10),
                        child: _buildCartList(state),
                      ),
                    ),
                    Container(
                      height: Constants.getAdapterHeight(120.0),
                      decoration: BoxDecoration(
                        color: Constants.hexStringToColor("#F7F7F7"),
                        border: Border.all(width: 1, color: Constants.hexStringToColor("#D2D2D2")),
                      ),
                      child: _buildShortcut(state),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCartList(CashierState cashierState) {
    var items = cashierState.orderObject.items;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#F7F7F7"),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#D2D2D2")),
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
                color: (selected ? Constants.hexStringToColor("#EDEAFF") : Constants.hexStringToColor("#F7F7F7")),
                border: Border(bottom: BorderSide(width: 1, color: Constants.hexStringToColor("#E0E0E0"))),
              ),
              child: InkWell(
                onTap: () {
                  //选择单行
                  _cashierBloc.add(SelectOrderItem(orderItem: item));
                },
                child: Container(
                  padding: Constants.paddingLTRB(15, 15, 0, 10),
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
                        alignment: Alignment.center,
                        child: Text("¥${item.receivableAmount}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#7A73C7"), fontSize: 32, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: Constants.paddingAll(0),
                        width: Constants.getAdapterWidth(180),
                        alignment: Alignment.center,
                        child: SpinnerInput(
                          spinnerValue: item.quantity,
                          minValue: 1,
                          maxValue: 999,
                          disabledLongPress: false,
                          middleNumberWidth: Constants.getAdapterWidth(64),
                          middleNumberStyle: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#444444")),
                          middleNumberBackground: Colors.transparent,
                          plusButton: SpinnerButtonStyle(
                            elevation: 0,
                            width: Constants.getAdapterWidth(45),
                            height: Constants.getAdapterHeight(45),
                            color: Colors.transparent,
                            child: LoadAssetImage("home/home_plus", format: "png", width: Constants.getAdapterWidth(56), height: Constants.getAdapterHeight(56)),
                          ),
                          minusButton: SpinnerButtonStyle(
                            elevation: 0,
                            width: Constants.getAdapterWidth(45),
                            height: Constants.getAdapterHeight(45),
                            color: Colors.transparent,
                            child: LoadAssetImage("home/home_minus", format: "png", width: Constants.getAdapterWidth(56), height: Constants.getAdapterHeight(56)),
                          ),
                          onChange: (newValue) {
                            if (item.id != cashierState.orderItem.id) {
                              //选择单行
                              _cashierBloc.add(SelectOrderItem(orderItem: item));
                            }

                            //默认数量加操作
                            var moduleKeyCode = ModuleKeyCode.$_105;
                            var permissionCode = "10004";
                            //数量大于当前行的数量，标明是数量减操作
                            if (newValue < cashierState.orderItem.quantity) {
                              moduleKeyCode = ModuleKeyCode.$_106;
                              permissionCode = "10005";
                            }
                            var result = BusinessUtils.instance.beforeMenuActionValidate(cashierState.orderObject, cashierState.orderItem, moduleKeyCode);
                            if (!result.item1) {
                              ToastUtils.show(result.item2);
                              return;
                            }

                            this.menuAction(cashierState.orderObject, item, moduleKeyCode, permissionCode);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ///构建快捷菜单
  Widget _buildShortcut(CashierState state) {
    //临时解决办法，主要处理现阶段实现的功能和界面配置尚未支持
    var availableShortcuts = state.shortcuts.where((item) {
      List<String> names = ["会员", "删除", "数量", "消单", "折扣", "改价", "赠送"]; //, "规格", "做法"
      return names.contains(item.name);
    }).toList();
    return Container(
      padding: Constants.paddingAll(10),
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        itemExtent: Constants.getAdapterWidth(120),
        itemCount: availableShortcuts.length,
        itemBuilder: (context, index) {
          ///获取模块信息
          var module = availableShortcuts[index];
          return Container(
            padding: Constants.paddingOnly(right: index + 1 == state.shortcuts.length ? 0 : 10),
            child: RaisedButton(
              padding: Constants.paddingAll(0),
              child: Text(
                "${module.name}",
                style: TextStyles.getTextStyle(color: Color(0xFFFFFFFF), fontSize: 28),
              ),
              color: Constants.hexStringToColor("#9898A1"),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              onPressed: () async {
                var moduleKeyCode = ModuleKeyCode.fromName("${module.keycode}");
                var permissionCode = "${module.permission}";

                var result = BusinessUtils.instance.beforeMenuActionValidate(state.orderObject, state.orderItem, moduleKeyCode);
                if (!result.item1) {
                  ToastUtils.show(result.item2);
                  return;
                }
                this.menuAction(state.orderObject, state.orderItem, moduleKeyCode, permissionCode);
              },
            ),
          );
        },
      ),
    );
  }

  ///构建结算区
  Widget _buildSettlement(CashierState state) {
    return Container(
      height: Constants.getAdapterHeight(120.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#F7F7F7"),
        border: new Border.all(width: 1, color: Constants.hexStringToColor("#D2D2D2")),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              NavigatorUtils.instance.goBack(context);
            },
            child: Container(
              width: Constants.getAdapterWidth(120),
              height: double.infinity,
              color: Constants.hexStringToColor("#F7F7F7"),
              child: Icon(
                Icons.arrow_back_ios,
                size: Constants.getAdapterWidth(48),
                color: Constants.hexStringToColor("#333333"),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: Constants.paddingLTRB(25, 0, 0, 0),
              child: Text("共${state.orderObject.totalQuantity.toInt()}件", style: TextStyles.getTextStyle(color: Color(0xff333333), fontSize: 36, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: Constants.paddingLTRB(0, 0, 20, 0),
                child: Text("¥${state.orderObject.receivableAmount}", style: TextStyles.getTextStyle(color: Color(0xff7A73C7), fontSize: 36, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#7A73C7"),
                borderRadius: BorderRadius.horizontal(left: Radius.circular(0.0), right: Radius.circular(0.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: InkWell(
                onTap: () async {
                  ///结算
                  bool isGo = true;
                  if (state.orderObject.orderStatus == OrderStatus.Completed) {
                    isGo = false;
                    ToastUtils.show("订单已经结账");
                  }

                  if (isGo) {
                    //结算
                    NavigatorUtils.instance.push(context, RouterManager.PAY_PAGE, replace: true);
                  }
                },
                child: Container(
                  width: Constants.getAdapterWidth(180),
                  child: Center(
                    child: Text("去结算", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void menuAction(OrderObject orderObject, OrderItem orderItem, ModuleKeyCode moduleKeyCode, String permissionCode, {dynamic keyData}) {
    switch (moduleKeyCode) {
      case ModuleKeyCode.$_115: //会员
        {
          bool isGo = true;
          if (isGo && orderObject != null && orderObject.orderStatus != OrderStatus.Completed && orderObject.orderStatus != OrderStatus.ChargeBack && orderObject.member != null) {
            //如果会员存在，显示会员详细信息
            showVipInfo(this.context, orderObject, this._cashierBloc);
          } else {
            var permissionAction = (args) {
              loadVip(this.context, orderObject, this._cashierBloc);
            };
            AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_115, permissionCode, orderObject, permissionAction);
          }
        }
        break;
      case ModuleKeyCode.$_104: //数量
        {
          var permissionAction = (args) {
            showQuantity(this.context, orderObject, orderItem, this._cashierBloc);
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_104, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_105: //数量加
        {
          var permissionAction = (args) {
            double inputValue = orderItem.quantity + 1;
            this._cashierBloc.add(QuantityChanged(orderItem, inputValue));
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_105, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_106: //数量减
        {
          var permissionAction = (args) {
            double inputValue = orderItem.quantity - 1;
            this._cashierBloc.add(QuantityChanged(orderItem, inputValue));
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_106, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_109: //删除单品
        {
          var permissionAction = (args) {
            this._cashierBloc.add(DeleteOrderItem(orderItem));
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_109, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_108: //折扣
        {
          var permissionAction = (args) {
            showDiscount(this.context, orderObject, orderItem, permissionCode, this._cashierBloc);
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_108, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_107: //改价
        {
          var permissionAction = (args) {
            showBargain(this.context, orderObject, orderItem, permissionCode, this._cashierBloc);
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_107, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_110: //赠送
        {
          var permissionAction = (args) {
            showGift(this.context, orderObject, orderItem, permissionCode, this._cashierBloc);
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_110, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_114: //取消全单、消单
        {
          var permissionAction = (args) {
            bool isGo = true;
            //有称重商品
            if (isGo && orderObject.items.any((x) => x.weightFlag == 1 && x.weightWay == 1)) {}

            if (isGo) {
              DialogUtils.confirm(context, "操作提醒", "您确定要消单？", () {
                this._cashierBloc.add(NewOrderObject());
              }, () {
                FLogger.warn("用户放弃消单操作");
              }, width: 500);
            }
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_114, permissionCode, orderObject, permissionAction);
        }
        break;
    }
  }
}

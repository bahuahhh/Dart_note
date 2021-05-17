import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/assistant_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_make_info.dart';
import 'package:estore_app/entity/pos_product_spec.dart';
import 'package:estore_app/enums/module_key_code.dart';
import 'package:estore_app/enums/order_row_status.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/promotion_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/order/assistant_utils.dart';
import 'package:estore_app/order/business_utils.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_item_make.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_table.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/product_ext.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:getwidget/getwidget.dart';
import 'package:getwidget/shape/gf_icon_button_shape.dart';
import 'package:getwidget/size/gf_size.dart';

import 'assistant_gift_dialog.dart';
import 'assistant_quantity_dialog.dart';
import 'assistant_refund_quantity_dialog.dart';
import 'assistant_spec_make_page.dart';

class AssistantCartPage extends StatefulWidget {
  final Map<String, List<String>> parameters;

  AssistantCartPage({this.parameters});

  @override
  _AssistantCartPageState createState() => _AssistantCartPageState();
}

class _AssistantCartPageState extends State<AssistantCartPage> with SingleTickerProviderStateMixin {
  //搜索框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //业务逻辑处理
  AssistantBloc _assistantBloc;

  ///是否多桌同时点单，默认都是单桌
  bool isMultiple = false;

  //订单编号
  String orderId;
  //桌台编号
  String tableId;

  ///本次操作影响的桌台清单
  List<OrderTable> tables = <OrderTable>[];

  //当前选择的桌台
  OrderTable selectedTable;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _assistantBloc = BlocProvider.of<AssistantBloc>(context);
    assert(this._assistantBloc != null);

    ///初始化
    orderId = widget.parameters["orderId"].first;
    tableId = widget.parameters["tableId"].first;
    String multipleTable = widget.parameters["multipleTable"].first;
    //multipleTable=0单桌点单，multipleTable=1多桌点单
    isMultiple = ("1" == multipleTable);

    ///渲染完成，获取传递的参数
    WidgetsBinding.instance.addPostFrameCallback((_) async {});
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        resizeToAvoidBottomPadding: false, //输入框抵住键盘
        backgroundColor: Constants.hexStringToColor("#656472"),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Constants.hexStringToColor("#4AB3FD"), Constants.hexStringToColor("#F7F7F7")],
              tileMode: TileMode.repeated,
            ),
          ),
          child: SafeArea(
            top: true,
            child: BlocListener<AssistantBloc, AssistantState>(
              cubit: this._assistantBloc,
              listener: (context, state) {},
              child: BlocBuilder<AssistantBloc, AssistantState>(
                cubit: this._assistantBloc,
                buildWhen: (previousState, currentState) {
                  return true;
                },
                builder: (context, state) {
                  var orderObject = state.orderObject;
                  //当前选择的桌台
                  selectedTable = orderObject.tables.lastWhere((x) => x.tableId == tableId);

                  tables.clear();
                  if (isMultiple) {
                    tables.addAll(orderObject.tables);
                  } else {
                    tables.add(orderObject.tables.lastWhere((x) => x.tableId == tableId));
                  }

                  // if (state.orderItem == null) {
                  //   if (orderObject.items.length > 0) {
                  //     var orderItem = orderObject.items.first;
                  //
                  //     _assistantBloc.add(SelectOrderItem(orderItem: orderItem));
                  //   }
                  // }

                  return Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Container(
                        padding: Constants.paddingAll(0),
                        decoration: BoxDecoration(
                          color: Constants.hexStringToColor("#656472"),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            this._buildHeader(state),
                            this._buildContent(state),
                            this._buildMenu(state),
                            this._buildFooter(state),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: selectedTable != null,
                        child: Positioned.directional(
                          start: Constants.getAdapterWidth(45),
                          bottom: Constants.getAdapterHeight(75),
                          width: Constants.getAdapterWidth(80),
                          height: Constants.getAdapterHeight(30),
                          textDirection: TextDirection.ltr,
                          child: Container(
                            alignment: Alignment.center,
                            padding: Constants.paddingAll(0),
                            decoration: BoxDecoration(
                              color: Constants.hexStringToColor("#A52A2A"),
                              border: Border.all(color: Constants.hexStringToColor("#A52A2A"), width: 1),
                              borderRadius: BorderRadius.all(Radius.circular(2)),
                            ),
                            child: Text(
                              "共${selectedTable?.totalQuantity}件",
                              style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///构建菜单操作区域
  Widget _buildMenu(AssistantState state) {
    return Column(
      children: [
        Container(
          height: Constants.getAdapterHeight(70),
          padding: Constants.paddingAll(5),
          decoration: BoxDecoration(
            color: Constants.hexStringToColor("#F7F7F7"),
            border: Border.all(width: 1, color: Constants.hexStringToColor("#D2D2D2")),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                    padding: Constants.paddingAll(5),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: Constants.getAdapterWidth(15),
                          backgroundColor: Constants.hexStringToColor("#EEB422"),
                        ),
                        Space(
                          width: Constants.getAdapterWidth(10),
                        ),
                        Text(
                          "已下单",
                          style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 28),
                        ),
                      ],
                    )),
              ),
              Expanded(
                child: Container(
                    padding: Constants.paddingAll(5),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: Constants.getAdapterWidth(15),
                          backgroundColor: Constants.hexStringToColor("#CD5555"),
                        ),
                        Space(
                          width: Constants.getAdapterWidth(10),
                        ),
                        Text(
                          "未下单",
                          style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 28),
                        ),
                      ],
                    )),
              ),
              Expanded(
                child: Container(
                    padding: Constants.paddingAll(5),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: Constants.getAdapterWidth(15),
                          backgroundColor: Constants.hexStringToColor("#006633"),
                        ),
                        Space(
                          width: Constants.getAdapterWidth(10),
                        ),
                        Text(
                          "已出品",
                          style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 28),
                        ),
                      ],
                    )),
              ),
            ],
          ),
        ),
        Container(
          height: Constants.getAdapterHeight(100),
          padding: Constants.paddingAll(5),
          decoration: BoxDecoration(
            color: Constants.hexStringToColor("#F7F7F7"),
            border: Border.all(width: 0, color: Constants.hexStringToColor("#D2D2D2")),
          ),
          child: _buildShortcut(state),
        ),
      ],
    );
  }

  ///构建快捷菜单
  Widget _buildShortcut(AssistantState state) {
    return Container(
      padding: Constants.paddingSymmetric(horizontal: 0, vertical: 8),
      width: double.infinity,
      alignment: Alignment.center,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        itemExtent: Constants.getAdapterWidth(710 / 5),
        itemCount: state.shortcuts.length,
        itemBuilder: (context, index) {
          ///获取模块信息
          var module = state.shortcuts[index];
          return Container(
            padding: Constants.paddingOnly(right: index + 1 == state.shortcuts.length ? 0 : 10),
            child: RaisedButton(
              padding: Constants.paddingAll(0),
              child: Text(
                "${module.name}",
                style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 28),
              ),
              color: Constants.hexStringToColor("#9898A1"),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              onPressed: () async {
                var moduleKeyCode = ModuleKeyCode.fromName("${module.keycode}");
                var permissionCode = "${module.permission}";

                var result = BusinessUtils.instance.beforeTableMenuActionValidate(state.orderObject, state.orderItem, moduleKeyCode);
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

  void menuAction(OrderObject orderObject, OrderItem orderItem, ModuleKeyCode moduleKeyCode, String permissionCode, {dynamic keyData}) {
    switch (moduleKeyCode) {
      case ModuleKeyCode.$_104: //数量
        {
          var permissionAction = (args) {
            _showQuantity(this.context, orderObject, orderItem, this.tables);
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_104, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_109: //删除单品
        {
          var permissionAction = (args) async {
            this._assistantBloc.add(DeleteOrderItem(orderItem));
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_109, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_110: //赠送
        {
          var permissionAction = (args) {
            _showGift(this.context, orderObject, orderItem, permissionCode, this.tables);
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_110, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_122: //退货
        {
          var permissionAction = (args) {
            _showRefundQuantity(this.context, orderObject, orderItem, this.tables);
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_122, permissionCode, orderObject, permissionAction);
        }
        break;
      case ModuleKeyCode.$_111: //做法
        {
          var permissionAction = (args) async {
            var product = orderItem.productExt;
            //获取商品的做法清单
            List<MakeInfo> makeList = await OrderUtils.instance.getProductMakeList(product.id);
            List<ProductSpec> specList = product.specList;

            _showProductSpecAndMake(context, product, specList, makeList, this._assistantBloc, orderObject: orderObject, orderItem: orderItem);
          };
          AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_111, permissionCode, orderObject, permissionAction);
        }
        break;
    }
  }

  //商品规格和做法选择
  void _showProductSpecAndMake(BuildContext context, ProductExt product, List<ProductSpec> specList, List<MakeInfo> makeList, AssistantBloc bloc, {OrderObject orderObject, OrderItem orderItem}) {
    YYDialog dialog;

    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };

    var onAccept = (args) {
      ProductSpec productSpec = args.productSpec;

      //修改商品价格信息
      product.salePrice = productSpec.salePrice;
      product.purPrice = productSpec.purPrice;
      product.minPrice = productSpec.minPrice;
      product.vipPrice = productSpec.vipPrice;
      product.vipPrice2 = productSpec.vipPrice2;
      product.vipPrice3 = productSpec.vipPrice3;
      product.vipPrice4 = productSpec.vipPrice4;
      product.vipPrice5 = productSpec.vipPrice5;
      product.batchPrice = productSpec.batchPrice;
      product.otherPrice = productSpec.otherPrice;
      // product.plusFlag = productSpec.plusFlag;
      // product.plusPrice = productSpec.plusPrice;
      // product.validStartDate = productSpec.validStartDate;
      // product.validEndDate = productSpec.validendDate;
      product.postPrice = productSpec.postPrice;
      product.specId = productSpec.id;
      product.purchaseSpec = productSpec.purchaseSpec;
      product.specName = productSpec.specification;

      List<OrderItemMake> makeList = args.makeList;
      double inputQuantity = args.inputQuantity;

      if (makeList != null && orderObject != null && orderItem != null) {
        for (var item in orderObject.items) {
          if (item.id == orderItem.id) {
            item.flavors.addAll(makeList);
            item.flavors.forEach((x) {
              x.orderId = orderObject.id;
              x.tradeNo = orderObject.tradeNo;
              x.itemId = orderItem.id;
              x.tableId = orderItem.tableId;
              x.tableNo = orderItem.tableNo;
              x.tableName = orderItem.tableName;
            });

            OrderUtils.instance.calculateOrderItem(item);

            break;
          }
        }

        OrderUtils.instance.calculateOrderObject(orderObject);

        this._assistantBloc.add(LoadTableOrderObject(orderObject: orderObject));
      }

      // bloc.add(TouchProduct(
      //   product,
      //   quantity: inputQuantity,
      //   joinType: OrderItemJoinType.Touch,
      //   makeList: makeList,
      // ));

      dialog?.dismiss();
    };
    var widget = AssistantSpecAndMakePage(
      product,
      specList,
      makeList,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: 650, height: specList.length > 1 ? 1000 : 900);
  }

  //加载退货界面
  void _showRefundQuantity(BuildContext context, OrderObject orderObject, OrderItem orderItem, List<OrderTable> tables) {
    YYDialog dialog;

    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };

    var onAccept = (args) async {
      dialog?.dismiss();

      OrderItem orderItem = args.orderItem;
      double refundQuantity = args.refundQuantity;
      String refundReason = args.refundReason;

      //构建开台对象
      Map<String, dynamic> map = new Map<String, dynamic>();
      map["orderId"] = orderItem.orderId;
      map["itemId"] = orderItem.id;
      map["workerNo"] = Global.instance.worker.no;
      map["workerName"] = Global.instance.worker.name;
      map["reason"] = refundReason;
      map["quantity"] = refundQuantity;
      var returnItemResult = await AssistantUtils.instance.returnItem(map);
      if (returnItemResult.item1) {
        var orderObject = returnItemResult.item3;

        _assistantBloc.add(LoadTableOrderObject(orderObject: orderObject));
      } else {
        ToastUtils.show(returnItemResult.item2);
      }
    };

    var widget = AssistantRefundQuantityDialog(
      orderObject,
      orderItem,
      "",
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: 610, height: 850);
  }

  //加载赠送界面
  void _showGift(BuildContext context, OrderObject orderObject, OrderItem orderItem, String permissionCode, List<OrderTable> tables) {
    YYDialog dialog;

    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };

    var onAccept = (args) async {
      dialog?.dismiss();

      OrderItem orderItem = args.orderItem;
      double giftQuantity = args.giftQuantity;
      String giftReason = args.giftReason;
      bool cancelGift = args.cancelGift;

      //构建开台对象
      Map<String, dynamic> map = new Map<String, dynamic>();
      map["orderId"] = orderItem.orderId;
      map["itemId"] = orderItem.id;
      map["workerNo"] = Global.instance.worker.no;
      map["workerName"] = Global.instance.worker.name;
      map["reason"] = giftReason;
      map["quantity"] = cancelGift ? 0 : giftQuantity;
      var giftItemResult = await AssistantUtils.instance.giftItem(map);
      if (giftItemResult.item1) {
        var orderObject = giftItemResult.item3;

        _assistantBloc.add(LoadTableOrderObject(orderObject: orderObject));
      } else {
        ToastUtils.show(giftItemResult.item2);
      }
    };

    var widget = AssistantGiftDialog(
      orderObject,
      orderItem,
      permissionCode,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: 610, height: 1000);
  }

  //加载数量调整界面
  void _showQuantity(BuildContext context, OrderObject orderObject, OrderItem orderItem, List<OrderTable> tables) {
    YYDialog dialog;

    //关闭弹框
    var onClose = () {
      dialog?.dismiss();
    };

    var onAccept = (args) async {
      dialog?.dismiss();

      OrderItem orderItem = args.orderItem;
      double inputValue = args.inputValue;

      this._assistantBloc.add(QuantityChanged(orderItem, inputValue));
    };

    var widget = AssistantQuantityDialog(
      orderItem,
      onAccept: onAccept,
      onClose: onClose,
    );

    dialog = DialogUtils.showDialog(context, widget, width: 610, height: 800);
  }

  ///构建内容区域
  Widget _buildContent(AssistantState state) {
    return Expanded(
      child: Container(
        padding: Constants.paddingAll(5),
        child: _buildCartList(state),
      ),
    );
  }

  Widget _buildCartList(AssistantState state) {
    if (selectedTable == null || state.orderObject == null || state.orderObject.items == null) {
      return Container();
    }
    var selectedItems = state.orderObject.items.where((x) => x.tableId == selectedTable.tableId).toList();

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: Constants.paddingAll(5),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#F7F7F7"),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#D2D2D2")),
      ),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: selectedItems.length,
        itemBuilder: (BuildContext context, int index) {
          var item = selectedItems[index];
          //是否标注为选中状态
          var selected = state.orderItem != null && (item.id == state.orderItem.id);

          //每行菜品根据下单情况，显示不同的颜色
          Color orderRowColor = Constants.hexStringToColor("#EEB422");
          if (item.orderRowStatus == OrderRowStatus.New || item.orderRowStatus == OrderRowStatus.Save) {
            orderRowColor = Constants.hexStringToColor("#CD5555");
          }
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
                  _assistantBloc.add(SelectOrderItem(orderItem: item));
                },
                child: Container(
                    padding: Constants.paddingLTRB(5, 15, 0, 15),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: Constants.paddingAll(5),
                          width: Constants.getAdapterWidth(50),
                          alignment: Alignment.center,
                          child: CircleAvatar(
                            radius: Constants.getAdapterWidth(15),
                            backgroundColor: orderRowColor,
                            child: Center(),
                          ),
                        ),
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
                            text: TextSpan(text: "${item.quantity}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold), children: <TextSpan>[
                              TextSpan(text: "x份", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#7A73C7"))),
                            ]),
                          ),
                        ),
                        Container(
                          padding: Constants.paddingAll(0),
                          width: Constants.getAdapterWidth(160),
                          alignment: Alignment.center,
                          child: RichText(
                            text: TextSpan(text: "¥", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#7A73C7")), children: <TextSpan>[
                              TextSpan(text: "${item.receivableAmount}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
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

  ///构建底部结算区
  Widget _buildFooter(AssistantState state) {
    if (selectedTable == null || state.orderObject == null || state.orderObject.items == null) {
      return Container();
    }
    return Container(
      height: Constants.getAdapterHeight(100.0),
      padding: Constants.paddingLTRB(10, 5, 0, 5),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#F7F7F7"),
        border: Border.all(width: 1, color: Constants.hexStringToColor("#D2D2D2")),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Ink(
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#7A73C7"),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              border: Border.all(width: 0.0, style: BorderStyle.none),
            ),
            child: InkWell(
              child: Container(
                width: Constants.getAdapterWidth(100),
                height: Constants.getAdapterHeight(100),
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: Constants.paddingAll(0),
                  child: GFIconButton(
                    color: Constants.hexStringToColor("#EEC900"),
                    shape: GFIconButtonShape.circle,
                    borderSide: BorderSide(style: BorderStyle.none),
                    size: GFSize.LARGE,
                    iconSize: Constants.getAdapterWidth(48),
                    icon: Icon(
                      Icons.shopping_cart_sharp,
                      color: Constants.hexStringToColor("#FFFFFF"),
                      size: Constants.getAdapterWidth(64),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Space(width: Constants.getAdapterWidth(20)),
          Expanded(
            child: Container(
              padding: Constants.paddingAll(0),
              width: Constants.getAdapterWidth(170),
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(text: "¥", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold), children: <TextSpan>[
                  TextSpan(text: "${selectedTable.receivableAmount}", style: TextStyles.getTextStyle(fontSize: 38, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
          Space(width: Constants.getAdapterWidth(10)),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#7A73C7"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: InkWell(
                onTap: () async {
                  ///下单
                  bool isGo = true;
                  if (isGo && state.orderObject.orderStatus == OrderStatus.Completed || state.orderObject.orderStatus == OrderStatus.ChargeBack) {
                    isGo = false;
                    ToastUtils.show("订单已经完成");
                  }

                  if (isGo && state.orderObject.items.length == 0) {
                    isGo = false;
                    ToastUtils.show("请选择商品");
                  }

                  //查找当前订单中是否新增单品
                  var newItems = state.orderObject.items.where((x) => x.orderRowStatus == OrderRowStatus.New || x.orderRowStatus == OrderRowStatus.Save).toList();
                  //没有新增单品
                  if (isGo && newItems.length == 0) {
                    isGo = false;
                    ToastUtils.show("商品已全部下单");
                  }

                  if (isGo) {
                    var permissionAction = (args) async {
                      //提交下单数据
                      var tryOrderResult = await AssistantUtils.instance.tryOrder(newItems);
                      if (tryOrderResult.item1) {
                        //下单成功后更新订单信息
                        var orderObjectResult = await AssistantUtils.instance.getOrderObject(state.orderObject.id);
                        if (orderObjectResult.item1) {
                          var orderObject = orderObjectResult.item3;
                          //加载
                          _assistantBloc.add(LoadTableOrderObject(orderObject: orderObject));
                        }

                        //返回桌台界面
                        NavigatorUtils.instance.goBackWithParams(context, "返回");
                      } else {
                        DialogUtils.notify(context, "错误提示", "${tryOrderResult.item2}", () {});
                      }
                    };
                    AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_706, ModuleKeyCode.$_706.permissionCode, state.orderObject, permissionAction);
                  }
                },
                child: Container(
                  width: Constants.getAdapterWidth(150),
                  child: Center(
                    child: Text("下单", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          ),
          Space(width: Constants.getAdapterWidth(5)),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#7A73C7"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: InkWell(
                onTap: () async {
                  ///结账
                  bool isGo = true;

                  if (state.orderObject == null || state.orderObject.items.length == 0) {
                    isGo = false;
                    ToastUtils.show("请先点单");
                  }

                  if (state.orderObject.orderStatus == OrderStatus.Completed) {
                    isGo = false;
                    ToastUtils.show("订单已经结账");
                  }

                  //结算
                  if (isGo) {
                    NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_ASSISTANT_PAY_PAGE}?orderId=${state.orderObject.id}", (val) {
                      NavigatorUtils.instance.goBackWithParams(context, "交易成功");
                    });
                  }
                },
                child: Container(
                  width: Constants.getAdapterWidth(160),
                  child: Center(
                    child: Text("去结算", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AssistantState state) {
    if (selectedTable == null || state.orderObject == null || state.orderObject.items == null) {
      return Container();
    }

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
            child: Container(
              width: Constants.getAdapterWidth(90),
              height: double.infinity,
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios,
                size: Constants.getAdapterWidth(48),
                color: Constants.hexStringToColor("#2B2B2B"),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: Constants.paddingAll(0),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#FFFFFF"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border.all(width: 0, color: Constants.hexStringToColor("#FFFFFF")),
              ),
              child: Text("点单列表", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold)),
            ),
          ),
          InkWell(
            onTap: () async {
//
            },
            child: SizedBox(
              width: Constants.getAdapterWidth(90),
              height: double.infinity,
              child: Icon(
                CommunityMaterialIcons.printer,
                size: Constants.getAdapterWidth(64),
                color: Constants.hexStringToColor("#7A73C7"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

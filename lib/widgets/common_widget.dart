import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/blocs/table_bloc.dart';
import 'package:estore_app/blocs/trade_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_product_spec.dart';
import 'package:estore_app/entity/pos_store_table.dart';
import 'package:estore_app/enums/order_item_join_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/member/member_card_recharge_scheme.dart';
import 'package:estore_app/member/member_elec_coupon.dart';
import 'package:estore_app/member/member_utils.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_item_make.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/product_ext.dart';
import 'package:estore_app/pages/bargain_page.dart';
import 'package:estore_app/pages/discount_page.dart';
import 'package:estore_app/pages/gift_page.dart';
import 'package:estore_app/pages/input_price_page.dart';
import 'package:estore_app/pages/member_page.dart';
import 'package:estore_app/pages/quantity_page.dart';
import 'package:estore_app/pages/refund_page.dart';
import 'package:estore_app/pages/select_spec_page.dart';
import 'package:estore_app/pages/table_page.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';

///通用AppBar
Widget customAppbar({BuildContext context, String title = '', double height = 50.0, bool borderBottom = true, List actions}) {
  return PreferredSize(
    preferredSize: Size.fromHeight(height),
    child: AppBar(
      centerTitle: true,
      title: Text(
        title,
        style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#383838"), fontSize: 32, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Constants.hexStringToColor('#ffffff'),
      elevation: 0,
      leading: context == null
          ? null
          : InkWell(
              child: Icon(Icons.arrow_back_ios, size: Constants.getAdapterWidth(32), color: Constants.hexStringToColor("#2B2B2B")),
              onTap: () => NavigatorUtils.instance.goBack(context),
            ),
      bottom: PreferredSize(
        child: Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderBottom ? Constants.hexStringToColor("#F2F2F2") : Colors.transparent, width: 1))),
        ),
        preferredSize: Size.fromHeight(0),
      ),
      actions: actions,
    ),
  );
}

void fullScreenSetting() {
  SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  SystemChrome.setEnabledSystemUIOverlays([]);
}

void enterFullScreen() {
  SystemChrome.setEnabledSystemUIOverlays([]);
}

void exitFullScreen() {
  SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
  // 把状态栏显示出来，需要一起调用底部虚拟按键（华为系列某些手机有虚拟按键）
  SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
}

List<Widget> showOrderItemMake(OrderItem master) {
  var lists = new List<Widget>();

  lists.add(Text(
    "${master.displayName}",
    style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#010101"), fontSize: 28),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ));
  lists.add(Space(height: Constants.getAdapterHeight(5)));

  //优惠内容
  if (master.promotions.length > 0) {
    var promotions = new List<Widget>();
    master.promotions.forEach((item) {
      promotions.add(Text(
        "${item.displayReason}",
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

///会员认证
void loadVip(BuildContext context, OrderObject orderObject, CashierBloc bloc) {
  //弹出框
  YYDialog dialog;
  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };
  //会员认证
  var onAccept = (args) async {
    var newOrderObject = args.orderObject;

    MemberCardRechargeScheme scheme;
    List<MemberElecCoupon> newCouponList = <MemberElecCoupon>[];
    List<MemberElecCoupon> couponSelected = <MemberElecCoupon>[];

    if (newOrderObject.member != null) {
      var couponResult = await MemberUtils.instance.httpElecCouponList(newOrderObject.member.id, "", 1, 1, 1000);
      if (couponResult.item1) {
        newCouponList = couponResult.item3;
        //检测优惠券可用情况并排序返回
        MemberUtils.instance.checkCouponEffect(newCouponList, couponSelected, newOrderObject, topSelect: true);
      }

      if (newOrderObject.member.defaultCard != null) {
        var schemeResult = await MemberUtils.instance.httpMemberCardRechargeSchemeQuery(newOrderObject.member.defaultCard.cardNo);
        if (schemeResult.item1) {
          scheme = schemeResult.item4;
        }
      }
    }

    bloc.add(RefreshUi(newOrderObject, couponList: newCouponList, couponSelected: couponSelected));

    dialog?.dismiss();
  };

  //会员认证UI
  var widget = MemberPage(
    orderObject,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 600, height: 800);
}

//加载会员认证界面
void showVipInfo(BuildContext context, OrderObject orderObject, CashierBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  //如果会员存在，显示会员详细信息
  var onCancel = (args) {
    bloc.add(RefreshUi(args.orderObject));
    dialog?.dismiss();
  };

  var onChanged = (args) {
    bloc.add(RefreshUi(args.orderObject));
    dialog?.dismiss();

    //重新加载会员认证界面
    loadVip(context, orderObject, bloc);
  };

  var widget = MemberViewPage(
    orderObject,
    onChanged: onChanged,
    onCancel: onCancel,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 600, height: 700);
}

//加载数量调整界面
void showQuantity(BuildContext context, OrderObject orderObject, OrderItem orderItem, CashierBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    bloc.add(QuantityChanged(args.orderItem, args.inputValue));
    dialog?.dismiss();
  };

  var widget = QuantityPage(
    orderItem,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 600, height: 800);
}

//加载折扣界面
void showDiscount(BuildContext context, OrderObject orderObject, OrderItem orderItem, String permissionCode, CashierBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    bloc.add(DiscountChanged(args.orderItem, args.inputValue, args.reason, restoreOriginalPrice: args.restoreOriginalPrice));

    dialog?.dismiss();
  };

  var widget = DiscountPage(
    orderObject,
    orderItem,
    permissionCode,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 600, height: 1000);
}

//加载改价界面
void showBargain(BuildContext context, OrderObject orderObject, OrderItem orderItem, String permissionCode, CashierBloc bloc) {
  YYDialog dialog;
  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    bloc.add(BargainChanged(args.orderItem, args.inputValue, args.reason, restoreOriginalPrice: args.restoreOriginalPrice));

    dialog?.dismiss();
  };

  var widget = BargainPage(
    orderObject,
    orderItem,
    permissionCode,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 600, height: 1000);
}

//加载赠送界面
void showGift(BuildContext context, OrderObject orderObject, OrderItem orderItem, String permissionCode, CashierBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    bloc.add(GiftChanged(args.orderItem, args.reason));

    dialog?.dismiss();
  };

  var widget = GiftPage(
    orderObject,
    orderItem,
    permissionCode,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 600, height: 800);
}

//加载售价输入界面
void showInputPrice(BuildContext context, ProductExt product, CashierBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    product.salePrice = args.inputValue;

    bloc.add(TouchProduct(product));

    dialog?.dismiss();
  };

  var widget = InputPricePage(
    product,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 600, height: 800);
}

//加载数量输入界面
void showQuantityPrice(BuildContext context, ProductExt product, CashierBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    bloc.add(TouchProduct(product));

    dialog?.dismiss();
  };

  var widget = InputPricePage(
    product,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 600, height: 800);
}

//加载规格选择界面
void showSelectProductSpec(BuildContext context, ProductExt product, CashierBloc bloc) {
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

    bloc.add(TouchProduct(
      product,
      quantity: inputQuantity,
      joinType: OrderItemJoinType.Touch,
      makeList: makeList,
    ));

    dialog?.dismiss();
  };

  var widget = SelectSpecPage(
    product,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 650, height: 1000);
}

//加载退单界面
void showRefund(BuildContext context, OrderObject orderObject, String permissionCode, TradeBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    //bloc.add(DiscountChanged(args.orderItem, args.inputValue, args.reason, restoreOriginalPrice: args.restoreOriginalPrice));

    dialog?.dismiss();
  };

  var widget = RefundPage(
    orderObject,
    permissionCode,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 720, height: 1100);
}

//加载转台界面
void showTransferTable(BuildContext context, StoreTable sourceTable, TableBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    bloc.add(RefreshTable());
    dialog?.dismiss();
  };

  var widget = TransferTablePage(
    sourceTable,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 720, height: 1280);
}

//加载并台界面
void showMergeTable(BuildContext context, StoreTable masterTable, TableBloc bloc) {
  YYDialog dialog;

  //关闭弹框
  var onClose = () {
    dialog?.dismiss();
  };

  var onAccept = (args) {
    bloc.add(RefreshTable());
    dialog?.dismiss();
  };

  var widget = MergeTablePage(
    masterTable,
    onAccept: onAccept,
    onClose: onClose,
  );

  dialog = DialogUtils.showDialog(context, widget, width: 720, height: 1280);
}

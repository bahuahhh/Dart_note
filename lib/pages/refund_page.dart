import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/trade_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_base_parameter.dart';
import 'package:estore_app/enums/cashier_action_type.dart';
import 'package:estore_app/enums/module_key_code.dart';
import 'package:estore_app/enums/online_pay_bus_type_enum.dart';
import 'package:estore_app/enums/order_item_join_type.dart';
import 'package:estore_app/enums/order_item_row_type.dart';
import 'package:estore_app/enums/order_payment_status_type.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/pay_channel_type.dart';
import 'package:estore_app/enums/print_ticket_enum.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/member/member_utils.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_item_make.dart';
import 'package:estore_app/order/order_item_pay.dart';
import 'package:estore_app/order/order_item_promotion.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_pay.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/payment/leshua_pay_utils.dart';
import 'package:estore_app/payment/saobei_pay_utils.dart';
import 'package:estore_app/payment/xiaobei_pay_utils.dart';
import 'package:estore_app/printer/printer_helper.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/common_widget.dart';
import 'package:estore_app/widgets/line_separator.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:estore_app/widgets/spinner_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class RefundPage extends StatefulWidget {
  // 订单对象
  final OrderObject orderObject;

  //标识是否需要校验
  final String permissionCode;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  RefundPage(this.orderObject, this.permissionCode, {this.onAccept, this.onClose});

  @override
  _RefundPageState createState() => _RefundPageState();
}

class _RefundPageState extends State<RefundPage> with SingleTickerProviderStateMixin {
  ///搜索框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //业务逻辑处理
  TradeBloc _tradeBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _tradeBloc = BlocProvider.of<TradeBloc>(context);
    assert(this._tradeBloc != null);

    //加载退货原因
    _tradeBloc.add(LoadRefundData(widget.orderObject));

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    fullScreenSetting();

    return KeyboardDismissOnTap(
      child: BlocBuilder<TradeBloc, TradeState>(
        cubit: this._tradeBloc,
        buildWhen: (previousState, currentState) {
          return true;
        },
        builder: (context, tradeState) {
          return Material(
            child: Container(
              padding: Constants.paddingAll(0),
              child: Column(
                children: <Widget>[
                  ///顶部标题
                  _buildHeader(),

                  ///中部操作区
                  _buildContent(tradeState),

                  ///底部部操作区
                  _buildFooter(tradeState),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent(TradeState tradeState) {
    return Container(
      padding: Constants.paddingAll(10),
      height: Constants.getAdapterHeight(910),
      width: double.infinity,
      color: Constants.hexStringToColor("#656472"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: Constants.getAdapterHeight(80),
            padding: Constants.paddingAll(0),
            child: Container(
              padding: Constants.paddingOnly(left: 12, right: 12),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#FFFFFF"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border.all(width: 1, color: Constants.hexStringToColor("#FFFFFF")),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: this._buildTextField(tradeState),
                  ),
                  InkWell(
                    onTap: () {
                      //清空内容
                      _controller.clear();
                    },
                    child: Icon(
                      CommunityMaterialIcons.close_circle_outline,
                      color: Constants.hexStringToColor("#D0D0D0"),
                      size: Constants.getAdapterWidth(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Space(height: Constants.getAdapterHeight(10)),
          Expanded(
            child: Container(
              padding: Constants.paddingAll(0),
              child: _buildCartList(tradeState),
            ),
          ),
          Space(height: Constants.getAdapterHeight(10)),
          Container(
            width: double.infinity,
            height: Constants.getAdapterHeight(190),
            padding: Constants.paddingLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#F8F8F8"),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              border: Border.all(width: 1, color: Constants.hexStringToColor("#F8F8F8")),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text("退货原因", style: TextStyles.getTextStyle(fontSize: 32)),
                Space(height: Constants.getAdapterHeight(20)),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: Constants.paddingAll(0),
                    itemCount: tradeState?.reasonsList?.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return Space(width: Constants.getAdapterWidth(12));
                    },
                    physics: AlwaysScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      var item = tradeState.reasonsList[index];
                      var selected = (item.id == tradeState.reasonSelected.id);
                      return _buildReason(item, selected);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(TradeState tradeState) {
    var orderItems = widget.orderObject.items;
    return Container(
      padding: Constants.paddingAll(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#656472")),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        padding: Constants.paddingAll(0),
        itemCount: orderItems.length,
        physics: AlwaysScrollableScrollPhysics(),
        separatorBuilder: (BuildContext context, int index) {
          return Space(
            height: Constants.getAdapterHeight(10),
          );
        },
        itemBuilder: (BuildContext context, int index) {
          //当前记录
          var orderItem = orderItems[index];
          //当前退货记录
          var orderRefund = tradeState.refundList.firstWhere((x) => x.itemId == orderItem.id);

          var backgroundColor = orderRefund.selected ? Constants.hexStringToColor("#F8F7FF") : Constants.hexStringToColor("#FFFFFF");
          var borderColor = orderRefund.selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#D0D0D0");

          return Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(bottom: BorderSide(width: 1, color: borderColor)),
            ),
            child: InkWell(
              onTap: () {
                //选择单行
                _tradeBloc.add(SelectRefundItem(orderItem: orderItem));
              },
              onLongPress: () {
                //
                _tradeBloc.add(ClearRefundItem(orderItem: orderItem));
              },
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      border: Border.all(width: 1, color: borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: Constants.paddingLTRB(orderRefund.selected ? 40 : 25, 5, 25, 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: showOrderItemMake(orderItem),
                                ),
                              ),
                              Container(
                                padding: Constants.paddingAll(0),
                                width: Constants.getAdapterWidth(150),
                                alignment: Alignment.centerRight,
                                child: Text("x${orderItem.quantity}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#7A73C7"), fontSize: 28, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: Constants.paddingAll(0),
                                width: Constants.getAdapterWidth(150),
                                alignment: Alignment.centerRight,
                                child: Text("¥${orderItem.receivableAmount}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#7A73C7"), fontSize: 28, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        LineSeparator(
                          color: borderColor,
                        ),
                        Container(
                          width: double.infinity,
                          height: Constants.getAdapterHeight(80),
                          padding: Constants.paddingSymmetric(horizontal: 25, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(text: "可退金额:¥", style: TextStyles.getTextStyle(fontSize: 24, color: Constants.hexStringToColor("#666666")), children: <TextSpan>[
                                    TextSpan(text: "${orderRefund.refundAmount}", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"))),
                                  ]),
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text("可退数量:", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#666666"), fontSize: 24)),
                                    Space(
                                      width: Constants.getAdapterWidth(20),
                                    ),
                                    SpinnerInput(
                                      spinnerValue: orderRefund.refundQuantity,
                                      minValue: 1,
                                      maxValue: orderItem.quantity - orderItem.refundQuantity,
                                      disabledLongPress: false,
                                      middleNumberWidth: Constants.getAdapterWidth(64),
                                      middleNumberStyle: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#444444")),
                                      middleNumberBackground: Colors.transparent,
                                      plusButton: SpinnerButtonStyle(
                                        elevation: 0,
                                        width: Constants.getAdapterWidth(60),
                                        height: Constants.getAdapterHeight(60),
                                        color: Colors.transparent,
                                        child: LoadAssetImage("home/home_plus", format: "png", width: Constants.getAdapterWidth(56), height: Constants.getAdapterHeight(56)),
                                      ),
                                      minusButton: SpinnerButtonStyle(
                                        elevation: 0,
                                        width: Constants.getAdapterWidth(60),
                                        height: Constants.getAdapterHeight(60),
                                        color: Colors.transparent,
                                        child: LoadAssetImage("home/home_minus", format: "png", width: Constants.getAdapterWidth(56), height: Constants.getAdapterHeight(56)),
                                      ),
                                      onChange: (inputValue) {
                                        this._tradeBloc.add(SelectRefundItem(orderItem: orderItem));

                                        var permissionAction = (args) {
                                          this._tradeBloc.add(RefundQuantityChanged(orderItem, inputValue));
                                        };
                                        AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_105, ModuleKeyCode.$_105.permissionCode, tradeState.orderObject, permissionAction);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: orderRefund.selected,
                    child: Positioned.directional(
                      start: Constants.getAdapterWidth(4),
                      top: Constants.getAdapterHeight(4),
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
                          "退",
                          style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ///构建搜索框
  Widget _buildTextField(TradeState tradeState) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(96),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: false,
        textAlign: TextAlign.start,
        controller: this._controller,
        focusNode: this._focus,
        style: TextStyles.getTextStyle(fontSize: 32),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "请输订单号",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),

        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: true, //长按复制 剪切
        autocorrect: false,
        onFieldSubmitted: (inputValue) async {
          ///
        },
      ),
    );
  }

  ///构建折扣原因
  Widget _buildReason(BaseParameter item, bool selected) {
    var backgroundColor = selected ? Constants.hexStringToColor("#F8F7FF") : Constants.hexStringToColor("#FFFFFF");
    var borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#D0D0D0");
    var titleColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#333333");

    return InkWell(
      onTap: () {
        this._tradeBloc.add(SelectRefundReason(reason: item));
      },
      child: Container(
        padding: Constants.paddingAll(0),
        width: Constants.getAdapterWidth(155),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Text(
          "${item.name}",
          style: TextStyles.getTextStyle(fontSize: 28, color: titleColor),
        ),
      ),
    );
  }

  ///构建底部工具栏
  Widget _buildFooter(TradeState tradeState) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingAll(10),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(text: "退金额:¥", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                      TextSpan(text: "${tradeState.totalRefundAmount}", style: TextStyles.getTextStyle(fontSize: 48, color: Constants.hexStringToColor("#333333"))),
                    ]),
                  ),
                ),
                Space(
                  width: Constants.getAdapterWidth(30),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(text: "退数量:", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                      TextSpan(text: "${tradeState.totalRefundQuantity}", style: TextStyles.getTextStyle(fontSize: 48, color: Constants.hexStringToColor("#333333"))),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(120),
              height: Constants.getAdapterHeight(60),
              alignment: Alignment.center,
              child: Text("确定", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#FFFFFF"))),
            ),
            color: Constants.hexStringToColor("#7A73C7"),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () async {
              //退单列表
              var refundList = tradeState.refundList;
              //选择的有退单记录
              if (refundList != null && refundList.any((x) => x.selected)) {
                //原单对象
                var orderObject = OrderObject.clone(tradeState.orderObject);
                //生成新的退单对象
                var refundOrderObject = OrderObject.newOrderObject();
                //生成新的退单单号
                var ticketNoResult = await OrderUtils.instance.generateTicketNo();
                if (ticketNoResult.item1) {
                  refundOrderObject.tradeNo = ticketNoResult.item3;
                }

                refundOrderObject.orderNo = orderObject.orderNo;
                refundOrderObject.cashierAction = CashierAction.Refund;
                //退单对应的原单号
                refundOrderObject.orgTradeNo = orderObject.tradeNo;
                refundOrderObject.postWay = orderObject.postWay;
                refundOrderObject.orderStatus = OrderStatus.ChargeBack; //已退单
                refundOrderObject.paymentStatus = OrderPaymentStatus.Paid; //已支付

                //当退单原因为空时，也可以进行相关操作
                var reason = (tradeState.reasonSelected == null) ? "" : tradeState.reasonSelected.name;
                refundOrderObject.refundCause = reason;

                //会员信息
                refundOrderObject.isMember = orderObject.isMember ?? 0;
                refundOrderObject.memberMobileNo = orderObject.memberMobileNo ?? "";
                refundOrderObject.memberName = orderObject.memberName ?? "";
                refundOrderObject.memberId = orderObject.memberId ?? "";
                refundOrderObject.memberNo = orderObject.memberNo ?? "";
                refundOrderObject.cardFaceNo = orderObject.cardFaceNo ?? "";

                print("退单对象:${refundOrderObject.items.length}");

                //过滤可退单记录
                var newRefundList = refundList.where((x) => x.selected).toList();

                print("退单记录:${newRefundList.length}");

                for (var refundItem in newRefundList) {
                  //OrderItem的行ID
                  var id = refundItem.itemId;
                  //退数量
                  double quantity = refundItem.refundQuantity;
                  //价格
                  double price = refundItem.refundPrice;
                  //退金额
                  double amount = OrderUtils.instance.toRound(quantity * price);

                  if (orderObject.items.any((x) => x.id == id)) {
                    //原单-行对象
                    var orderItem = orderObject.items.singleWhere((x) => x.id == id);
                    if (orderItem.joinType == OrderItemJoinType.ScanAmountCode && orderItem.quantity == quantity) {
                      //扫描金额码商品特殊处理，如果全退，金额与原单金额一样
                      amount = orderItem.amount;
                    }

                    //新单-行对象,将参与退货的单品记入退货新单中
                    var refundOrderItem = OrderItem.clone(orderItem);
                    //新单行ID，单行允许多次退，需要生成新ID
                    refundOrderItem.id = IdWorkerUtils.getInstance().generate().toString();

                    //初始化退单信息
                    refundOrderItem.refundQuantity = 0;
                    refundOrderItem.refundAmount = 0;
                    refundOrderItem.orderId = refundOrderObject.id;
                    refundOrderItem.tradeNo = refundOrderObject.tradeNo;
                    refundOrderItem.orgItemId = id; //原单的行ID
                    refundOrderItem.addPoint = 0.0;
                    refundOrderItem.refundPoint = 0.0;
                    refundOrderItem.promotionInfo = "";
                    refundOrderItem.quantity = (0 - quantity);
                    refundOrderItem.amount = (0 - amount);
                    refundOrderItem.labelAmount = (0 - refundOrderItem.labelAmount);

                    //清空支付方式分摊
                    refundOrderItem.itemPays = new List<OrderItemPay>();

                    //做法
                    refundOrderItem.flavors = orderItem.flavors.map((e) => OrderItemMake.clone(e)).toList();
                    for (var f in refundOrderItem.flavors) {
                      f.id = IdWorkerUtils.getInstance().generate().toString();

                      f.orderId = refundOrderObject.id;
                      f.tradeNo = refundOrderObject.tradeNo;
                      f.itemId = refundOrderItem.id;
                      f.quantity = (0 - f.baseQuantity * quantity);

                      f.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
                      f.createUser = Constants.DEFAULT_CREATE_USER;
                    }

                    //部分退货情况下的占比=退数量/可退数量，用于处理促销优惠
                    double rate = quantity / orderItem.quantity;

                    //促销
                    refundOrderItem.promotions = orderItem.promotions.map((e) => OrderItemPromotion.clone(e)).toList();
                    for (var p in refundOrderItem.promotions) {
                      p.id = IdWorkerUtils.getInstance().generate().toString();

                      p.orderId = refundOrderObject.id;
                      p.tradeNo = refundOrderObject.tradeNo;
                      p.itemId = refundOrderItem.id;

                      p.amount = (0 - p.amount) * rate;
                      p.discountAmount = (0 - p.discountAmount) * rate;

                      p.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
                      p.createUser = Constants.DEFAULT_CREATE_USER;
                    }

                    //先计算OrderItem的行合计金额
                    OrderUtils.instance.calculateOrderItem(refundOrderItem);

                    print(">>>>>@@@>退单金额:${refundOrderItem.flavorAmount}");

                    refundOrderObject.items.add(refundOrderItem);

                    //原单-行对象退数量和退金额,支持多次退单，退数量和退金额需要累计
                    orderItem.refundQuantity += quantity;
                    orderItem.refundAmount += amount;

                    if (orderItem.rowType == OrderItemRowType.Detail) {
                      //捆绑商品处理,原始单据中的
                      var subItems = orderObject.items.where((x) => x.parentId == id && x.group == orderItem.group).toList();
                      for (var subItem in subItems) {
                        //新单-行对象,将参与退货的单品记入退货新单中
                        var newSubItem = OrderItem.clone(subItem);

                        //新单行ID，单行允许多次退，需要生成新ID
                        newSubItem.id = IdWorkerUtils.getInstance().generate().toString();

                        //初始化退单信息
                        newSubItem.refundQuantity = 0;
                        newSubItem.refundAmount = 0;

                        newSubItem.orderId = refundOrderObject.id;
                        newSubItem.tradeNo = refundOrderObject.tradeNo;
                        newSubItem.orgItemId = subItem.id;

                        newSubItem.addPoint = 0.0;
                        newSubItem.refundPoint = 0.0;
                        newSubItem.promotionInfo = "";

                        //优惠计算时需要依据原始数据，这里将优惠后的金额先忽略
                        newSubItem.price = newSubItem.salePrice;

                        newSubItem.quantity = (0 - quantity) * newSubItem.suitQuantity;
                        newSubItem.amount = newSubItem.quantity * newSubItem.price;

                        //有效数量
                        var _subEffectiveQuantity = subItem.quantity - subItem.refundQuantity;
                        if (_subEffectiveQuantity <= 0) {
                          //排除不可退的商品
                          continue;
                        }
                        //部分退货情况下的占比，用于处理促销优惠
                        double subRate = newSubItem.quantity / subItem.quantity;

                        //促销
                        newSubItem.promotions = subItem.promotions.map((e) => OrderItemPromotion.clone(e)).toList();
                        for (var p in newSubItem.promotions) {
                          p.id = IdWorkerUtils.getInstance().generate().toString();

                          p.orderId = refundOrderObject.id;
                          p.tradeNo = refundOrderObject.tradeNo;
                          p.itemId = newSubItem.id;

                          p.amount = (0 - p.amount) * rate;
                          p.discountAmount = (0 - p.discountAmount) * rate;

                          p.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
                          p.createUser = Constants.DEFAULT_CREATE_USER;
                        }

                        //1、先计算OrderItem的行合计金额
                        OrderUtils.instance.calculateOrderItem(newSubItem);

                        refundOrderObject.items.add(newSubItem);

                        //原单-行对象退数量和退金额,支持多次退单，退数量和退金额需要累计
                        subItem.refundQuantity += (0 - newSubItem.quantity);
                        subItem.refundAmount += (0 - newSubItem.amount);
                      }
                    }
                  }
                }

                FLogger.info("$refundOrderObject");

                if (refundOrderObject.items.length == 0) {
                  ToastUtils.show("请选择可退数量大于0的销售记录");
                  return;
                }

                //刷新排序
                OrderUtils.instance.refreshOrderNo(refundOrderObject);

                print(">>>>>>退单金额:${refundOrderObject.items[0].totalReceivableAmount}");

                //刷新OrderObject合计金额
                OrderUtils.instance.calculateOrderObject(refundOrderObject);

                //退款清单
                refundOrderObject.pays = new List<OrderPay>();

                print(">>>>>>退单金额:${refundOrderObject.items[0].totalReceivableAmount}");

                //退款，全部按照支付分摊退款
                List<OrderPay> newPayList = calculateRefundPay(refundOrderObject, orderObject);

                print(">>>>>>退单支付方式:${newPayList.length}");

                print(">>>>>>退单支付方式:$newPayList");

                StringBuffer bs = new StringBuffer();
                if (newPayList != null && newPayList.length > 0) {
                  for (var p in newPayList) {
                    bs.writeln("${p.name},${OrderUtils.instance.toRound(p.paidAmount) * -1}");
                  }
                }
                ToastUtils.show("${bs.toString()}");

                //原单支付方式清单(存在抹零的情况，金额为负数)
                var sourcePays = orderObject.pays.where((x) => (x.paidAmount - x.refundAmount) > 0 || x.amount != 0).toList();
                sourcePays.sort((x, y) => x.orderNo.compareTo(y.orderNo));
                double diffAmount = 0 - refundOrderObject.paidAmount;
                bool hasCardRefund = false;

                print(">>>>>>>>>>>>>>>>>>>>>$diffAmount");

                //支付清单遍历
                for (var p in sourcePays) {
                  //分摊新流程，按照分摊的金额进行扣款
                  OrderPay sharePay;
                  if (newPayList != null && newPayList.length > 0) {
                    sharePay = newPayList.firstWhere((x) => x.orgPayId == p.id, orElse: () => null);
                    if (sharePay == null) {
                      //存在分摊，但是当前支付方式不在本次应退范围（上面计算的商品分摊），跳过
                      continue;
                    }
                  }

                  var oldPay = orderObject.pays.firstWhere((x) => x.id == p.id);

                  print("@@@@@@@oldPay@@@@@@@@@>>>>>>$oldPay");

                  //原支付金额、支付单号
                  // var oldPaidAmount = oldPay.paidAmount;
                  // var oldPayNo = oldPay.payNo;
                  // var oldVoucherNo = oldPay.voucherNo;

                  p.orderId = refundOrderObject.id;
                  p.tradeNo = refundOrderObject.tradeNo;

                  p.payTime = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
                  p.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
                  p.createUser = Constants.DEFAULT_CREATE_USER;

                  if (sharePay != null) {
                    //启用了分摊，按照分摊中的支付进行扣款
                    p.id = sharePay.id;

                    p.amount = (sharePay.paidAmount);
                    //当前支付方式余额
                    var balanceAmount = p.paidAmount - p.refundAmount;
                    if (balanceAmount < (0 - p.amount)) {
                      //本次扣款不足，余额扣掉即可
                      p.amount = 0 - balanceAmount;
                    }
                    //除去代金券的剩余金额，每次应该减去代金券分摊金额
                    diffAmount -= (0 - p.amount);
                  } else {
                    //沿用旧的逻辑，按顺序扣款
                    p.id = IdWorkerUtils.getInstance().generate().toString();

                    //当前支付方式余额
                    var balanceAmount = p.paidAmount - p.refundAmount;

                    diffAmount -= balanceAmount;
                    if (diffAmount >= 0) {
                      //当前支付方式的金额不足，全部付款
                      p.amount = (0 - balanceAmount);
                    } else {
                      //足够，将剩余金额扣掉即可
                      p.amount = (0 - (balanceAmount + diffAmount));
                    }
                  }
                  p.inputAmount = p.amount;
                  p.paidAmount = p.amount;
                  p.refundAmount = 0.0;
                  //面额处理
                  if (p.faceAmount != 0) {
                    p.overAmount = 0 - p.faceAmount - p.paidAmount;
                  }
                  //原支付ID
                  p.orgPayId = oldPay.id;
                  //记录当前支付方式的已退款金额
                  oldPay.refundAmount += p.paidAmount * -1;
                  var tempRefundAmount = p.paidAmount * -1;

                  var storeInfo = await Global.instance.getStoreInfo();
                  var payNo = Global.instance.nextPayNoSuffix(refundOrderObject.tradeNo);
                  var refundPayNo = "${storeInfo.code}_${refundOrderObject.tradeNo}$payNo";

                  switch (p.no) {
                    case Constants.PAYMODE_CODE_CARD: //储值卡
                      {
                        ToastUtils.show("正在退会员卡金额积分...");
                        var refundAmountInt = (tempRefundAmount * 100).toInt();
                        //计算本次应退积分
                        var refundPoint = 0;
                        if (p.cardChangePoint > 0) //多张储值卡时需要只退款增加积分的那张卡
                        {
                          //refundPoint = OrderUtils.instance.calculateRefundMemberPoint(orgOrderObject, refundOrderObject);
                        }
                        var pointInt = (refundPoint * 100).toInt();
                        if (refundAmountInt > 0 || refundPoint > 0) {
                          var pointRes = await MemberUtils.instance.httpMemberRefund(refundPayNo, oldPay.payNo, refundOrderObject.refundCause, refundAmountInt, pointInt, p.voucherNo);
                          if (pointRes.item1) {
                            var payResponse = pointRes.item3;
                            if (payResponse != null) {
                              var pointValue = OrderUtils.instance.fen2YuanByInt(payResponse.pointValue);
                              //退款积分记为负数
                              if (pointValue != 0) {
                                refundOrderObject.addPoint = 0 - pointValue;
                                refundOrderObject.prePoint = OrderUtils.instance.fen2YuanByInt(payResponse.prePoint);
                                refundOrderObject.aftPoint = OrderUtils.instance.fen2YuanByInt(payResponse.aftPoint);
                                refundOrderObject.aftAmount = OrderUtils.instance.fen2YuanByInt(payResponse.aftAmount);
                              }

                              var totalAmount = OrderUtils.instance.fen2YuanByInt(payResponse.totalAmount);

                              p.accountName = payResponse.name;
                              p.cardNo = payResponse.cardNo;
                              p.cardFaceNo = payResponse.cardFaceNo;
                              p.cardPreAmount = OrderUtils.instance.fen2YuanByInt(payResponse.preAmount);
                              p.cardChangeAmount = totalAmount;
                              p.cardAftAmount = OrderUtils.instance.fen2YuanByInt(payResponse.aftAmount);
                              p.cardPrePoint = OrderUtils.instance.fen2YuanByInt(payResponse.prePoint);
                              p.cardChangePoint = OrderUtils.instance.fen2YuanByInt(payResponse.pointValue);
                              p.cardAftPoint = OrderUtils.instance.fen2YuanByInt(payResponse.aftPoint);
                              p.payNo = refundPayNo;

                              orderObject.refundPoint += pointValue;

                              FLogger.info("订单[${refundOrderObject.tradeNo}]退款[${p.paidAmount}]积分[${refundOrderObject.addPoint}]成功");
                              ToastUtils.show("会员卡金额积分退款成功");
                            }
                          } else {
                            // //更新在线支付日志支付结果
                            // OnLinePayLogUtils.UpdatePayLogPayStatus(onlinePayLogId, OnLinePayPayStatusEnum.失败, pointRes.Item2);

                            FLogger.info("订单[${refundOrderObject.tradeNo}]退款[${p.paidAmount}]退积分失败，原因${pointRes.item2}");

                            ToastUtils.show("会员卡退款失败：${pointRes.item2}");
                            return;
                          }
                        }
                        hasCardRefund = true;
                      }
                      break;
                    case Constants.PAYMODE_CODE_POINTPAY: //积分支付退款
                      {}
                      break;
                    case Constants.PAYMODE_CODE_ALIPAY: //支付宝
                      {
                        switch (p.payChannel) {
                          case PayChannelEnum.SaobeiPay:
                            {
                              ToastUtils.show("正在进行支付宝退款...");

                              //获取当前支付方式
                              var currentPayMode = await OrderUtils.instance.getPayMode(p.no);
                              //支付参数
                              var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.SaleRefund);
                              //获取支付参数失败
                              if (!payParameterResult.item1) {
                                ToastUtils.show(payParameterResult.item2);
                                return;
                              }
                              var payParameter = payParameterResult.item3;
                              var result = await SaobeiPayUtils.refundResult(currentPayMode, payParameter, oldPay.payNo, refundPayNo, tempRefundAmount);
                              if (result.item1) {
                                p.payNo = refundPayNo;
                              } else {
                                ToastUtils.show(result.item2);
                              }
                            }
                            break;
                          case PayChannelEnum.LeshuaPay:
                            {
                              ToastUtils.show("正在进行支付宝退款...");

                              //获取当前支付方式
                              var currentPayMode = await OrderUtils.instance.getPayMode(p.no);
                              //支付参数
                              var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.SaleRefund);
                              //获取支付参数失败
                              if (!payParameterResult.item1) {
                                ToastUtils.show(payParameterResult.item2);
                                return;
                              }
                              var payParameter = payParameterResult.item3;
                              var result = await LeshuaPayUtils.refundResult(currentPayMode, payParameter, oldPay.tradeNo, oldPay.payNo, tempRefundAmount);
                              if (result.item1) {
                                p.payNo = refundPayNo;
                              } else {
                                ToastUtils.show(result.item2);
                              }
                            }
                            break;
                          case PayChannelEnum.JCRCB:
                            {
                              ToastUtils.show("正在进行支付宝退款...");

                              //获取当前支付方式
                              var currentPayMode = await OrderUtils.instance.getPayMode(p.no);
                              //支付参数
                              var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.SaleRefund);
                              //获取支付参数失败
                              if (!payParameterResult.item1) {
                                ToastUtils.show(payParameterResult.item2);
                                return;
                              }
                              var payParameter = payParameterResult.item3;
                              var result = await XiaobeiPayUtils.refundResult(currentPayMode, payParameter, oldPay.payNo, oldPay.tradeNo, tempRefundAmount);
                              if (result.item1) {
                                p.payNo = refundPayNo;
                              } else {
                                ToastUtils.show(result.item2);
                              }
                            }
                            break;
                        }
                      }
                      break;
                    case Constants.PAYMODE_CODE_WEIXIN: //微信
                      {
                        switch (p.payChannel) {
                          case PayChannelEnum.SaobeiPay:
                            {
                              ToastUtils.show("正在进行微信退款...");

                              //获取当前支付方式
                              var currentPayMode = await OrderUtils.instance.getPayMode(p.no);
                              //支付参数
                              var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.SaleRefund);
                              //获取支付参数失败
                              if (!payParameterResult.item1) {
                                ToastUtils.show(payParameterResult.item2);
                                return;
                              }
                              var payParameter = payParameterResult.item3;
                              var result = await SaobeiPayUtils.refundResult(currentPayMode, payParameter, oldPay.payNo, refundPayNo, tempRefundAmount);
                              if (result.item1) {
                                p.payNo = refundPayNo;
                              } else {
                                ToastUtils.show(result.item2);
                              }
                            }
                            break;
                          case PayChannelEnum.LeshuaPay:
                            {
                              ToastUtils.show("正在进行微信退款...");

                              //获取当前支付方式
                              var currentPayMode = await OrderUtils.instance.getPayMode(p.no);
                              //支付参数
                              var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.SaleRefund);
                              //获取支付参数失败
                              if (!payParameterResult.item1) {
                                ToastUtils.show(payParameterResult.item2);
                                return;
                              }
                              var payParameter = payParameterResult.item3;
                              var result = await LeshuaPayUtils.refundResult(currentPayMode, payParameter, oldPay.tradeNo, oldPay.payNo, tempRefundAmount);
                              if (result.item1) {
                                p.payNo = refundPayNo;
                              } else {
                                ToastUtils.show(result.item2);
                              }
                            }
                            break;
                          case PayChannelEnum.JCRCB:
                            {
                              ToastUtils.show("正在进行微信退款...");

                              //获取当前支付方式
                              var currentPayMode = await OrderUtils.instance.getPayMode(p.no);
                              //支付参数
                              var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.SaleRefund);
                              //获取支付参数失败
                              if (!payParameterResult.item1) {
                                ToastUtils.show(payParameterResult.item2);
                                return;
                              }
                              var payParameter = payParameterResult.item3;
                              var result = await XiaobeiPayUtils.refundResult(currentPayMode, payParameter, oldPay.payNo, refundOrderObject.tradeNo, tempRefundAmount);
                              if (result.item1) {
                                p.payNo = refundPayNo;
                              } else {
                                ToastUtils.show(result.item2);
                              }
                            }
                            break;
                        }
                      }
                      break;
                    case Constants.PAYMODE_CODE_YUNSHANFU: //银联云闪付
                      {
                        switch (p.payChannel) {
                          case PayChannelEnum.SaobeiPay:
                            {
                              ToastUtils.show("正在进行微信退款...");

                              //获取当前支付方式
                              var currentPayMode = await OrderUtils.instance.getPayMode(p.no);
                              //支付参数
                              var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.SaleRefund);
                              //获取支付参数失败
                              if (!payParameterResult.item1) {
                                ToastUtils.show(payParameterResult.item2);
                                return;
                              }
                              var payParameter = payParameterResult.item3;
                              var result = await SaobeiPayUtils.refundResult(currentPayMode, payParameter, oldPay.payNo, refundPayNo, tempRefundAmount);
                              if (result.item1) {
                                p.payNo = refundPayNo;
                              } else {
                                ToastUtils.show(result.item2);
                              }
                            }
                            break;
                          case PayChannelEnum.LeshuaPay:
                            {
                              ToastUtils.show("正在进行云闪付退款...");

                              //获取当前支付方式
                              var currentPayMode = await OrderUtils.instance.getPayMode(p.no);
                              //支付参数
                              var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.SaleRefund);
                              //获取支付参数失败
                              if (!payParameterResult.item1) {
                                ToastUtils.show(payParameterResult.item2);
                                return;
                              }
                              var payParameter = payParameterResult.item3;
                              var result = await LeshuaPayUtils.refundResult(currentPayMode, payParameter, oldPay.tradeNo, oldPay.payNo, tempRefundAmount);
                              if (result.item1) {
                                p.payNo = refundPayNo;
                              } else {
                                ToastUtils.show(result.item2);
                              }
                            }
                            break;
                        }
                      }
                      break;
                    case Constants.PAYMODE_CODE_COUPON: //代金券
                      {}
                      break;
                    case Constants.PAYMODE_CODE_BANK: //银行
                      {}
                      break;
                  }

                  refundOrderObject.pays.add(p);

                  if (refundOrderObject.pays.map((e) => e.amount).fold(0, (prev, amount) => prev + amount) + diffAmount == 0) {
                    //退款完成。分摊支付，不走这个路径
                    break;
                  }
                }

                //判断是否需要退积分

                //处理退货商品金额为零

                //刷新OrderObject已收金额
                OrderUtils.instance.calculateOrderObject(refundOrderObject);

                //抹零附加记入支付方式
                await OrderUtils.instance.builderMalingPayMode(refundOrderObject);

                //分摊支付方式到商品明细
                await OrderUtils.instance.builderItemPayShared(refundOrderObject);

                var res = await OrderUtils.instance.saveRefundOrderObject(orderObject, refundOrderObject);
                if (res.item1) {
                  //小票打印
                  PrinterHelper.printCheckoutTicket(PrintTicketEnum.Statement, res.item3);

                  if (widget.onAccept != null) {
                    var args = RefundOrderObjectArgs(res.item3);
                    widget.onAccept(args);
                  }
                }
              } else {
                ToastUtils.show("请选择要退货的商品");
              }
            },
          ),
        ],
      ),
    );
  }

  /// 退款，全部按照支付分摊退款
  List<OrderPay> calculateRefundPay(OrderObject refundOrderObject, OrderObject orgOrderObject) {
    var newPayList = new List<OrderPay>();
    for (var item in refundOrderObject.items) {
      if (item.rowType == OrderItemRowType.Detail || item.rowType == OrderItemRowType.SuitDetail) {
        continue;
      }

      //转正
      var tempTotalReceivableAmount = 0 - item.totalReceivableAmount;

      //原订单明细项
      var oldOrderItem = orgOrderObject.items.firstWhere((x) => x.id == item.orgItemId, orElse: () => null);
      if (oldOrderItem != null && oldOrderItem.itemPays != null && oldOrderItem.itemPays.length > 0) {
        bool allRe = false;
        if (oldOrderItem.quantity == oldOrderItem.refundQuantity) {
          //本明细项全退，所有支付都退掉
          allRe = true;
        }
        //明细项
        for (var pay in oldOrderItem.itemPays) {
          //此明细还剩余金额
          var balance = pay.shareAmount - pay.refundAmount;

          //还有可分配的余额
          if (balance == 0) {
            //本分摊已完全使用
            continue;
          }
          var currentSharedPay = tempTotalReceivableAmount;
          if (balance < tempTotalReceivableAmount) {
            currentSharedPay = balance;
          }
          if (allRe) {
            //全退，余额全部推掉
            currentSharedPay = balance;
          }
          tempTotalReceivableAmount -= currentSharedPay;

          var existPay = newPayList.firstWhere((x) => x.orgPayId == pay.payId, orElse: () => null);
          if (existPay == null) {
            existPay = new OrderPay()
              ..id = IdWorkerUtils.getInstance().generate().toString()
              ..orgPayId = pay.payId
              ..no = pay.no
              ..name = pay.name
              ..couponId = pay.couponId
              ..couponNo = pay.couponNo
              ..sourceSign = pay.sourceSign
              ..couponName = pay.couponName
              ..faceAmount = pay.faceAmount
              ..couponLeastCost = pay.shareCouponLeastCost;
            newPayList.add(existPay);

            //直接分配
            OrderItemPay itemPay = new OrderItemPay()
              ..id = IdWorkerUtils.getInstance().generate().toString()
              ..tenantId = item.tenantId
              ..orderId = item.orderId
              ..tradeNo = item.tradeNo
              ..payId = existPay.id
              ..itemId = item.id
              ..no = pay.no
              ..name = pay.name
              ..productId = item.productId
              ..specId = item.specId
              ..couponId = existPay.couponId
              ..couponNo = existPay.couponNo
              ..sourceSign = existPay.sourceSign
              ..couponName = existPay.couponName
              ..faceAmount = existPay.faceAmount
              ..shareAmount = 0 - currentSharedPay
              ..shareCouponLeastCost = existPay.couponLeastCost
              ..refundAmount = 0;

            item.itemPays.add(itemPay);
          }
          existPay.paidAmount += (0 - currentSharedPay);
          //原分摊记录退款金额

          pay.refundAmount += currentSharedPay;

          if (!allRe && tempTotalReceivableAmount <= 0) {
            //排除全退的情况，全退，需要处理抹零，抹零也要退掉
            //该行明细分摊完成
            break;
          }
        }
      }
    }
    return newPayList;
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
              child: Text("退单", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 32)),
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
}

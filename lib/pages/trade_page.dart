import 'package:barcode_scan/platform_wrapper.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/trade_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/enums/module_key_code.dart';
import 'package:estore_app/enums/order_refund_status.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/trade_condition_enum.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/printer/printer_helper.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/widgets/common_widget.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:estore_app/widgets/toggle_switch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional.dart';
import 'package:flutter_conditional_rendering/conditional_switch.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class TradePage extends StatefulWidget {
  @override
  _TradePageState createState() => _TradePageState();
}

class _TradePageState extends State<TradePage>
    with SingleTickerProviderStateMixin {
  //搜索框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //分页信息
  final EasyRefreshController _refreshController = EasyRefreshController();
  final int pagerSize = 5;

  //业务逻辑处理
  TradeBloc _tradeBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _tradeBloc = BlocProvider.of<TradeBloc>(context);
    assert(this._tradeBloc != null);

    this
        ._tradeBloc
        .add(PagerDataEvent(pagerNumber: 0, pagerSize: this.pagerSize));

    WidgetsBinding.instance.addPostFrameCallback((_) async {});
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  void dispose() {
    this._focus.dispose();
    this._controller.dispose();
    this._refreshController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fullScreenSetting();

    return KeyboardDismissOnTap(
      child: Scaffold(
        resizeToAvoidBottomPadding: false, //输入框抵住键盘
        backgroundColor: Constants.hexStringToColor("#656472"),
        body: SafeArea(
          child: BlocListener<TradeBloc, TradeState>(
            cubit: this._tradeBloc,
            listener: (context, state) {},
            child: BlocBuilder<TradeBloc, TradeState>(
              cubit: this._tradeBloc,
              buildWhen: (previousState, currentState) {
                return true;
              },
              builder: (context, state) {
                return Container(
                  padding: Constants.paddingAll(0),
                  decoration: BoxDecoration(
                    color: Constants.hexStringToColor("#656472"),
                  ),
                  child: Container(
                    padding: Constants.paddingLTRB(5, 0, 5, 0),
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        this._buildHeader(state),
                        Space(height: Constants.getAdapterHeight(5)),
                        Container(
                          padding: Constants.paddingAll(0),
                          width: double.infinity,
                          height: Constants.getAdapterHeight(90),
                          child: ToggleSwitch(
                            minWidth: Constants.getAdapterWidth(704 / 4),
                            minHeight: Constants.getAdapterHeight(70),
                            initialLabelIndex:
                                TradeConditionEnum.getIndex("今日"),
                            activeBgColor:
                                Constants.hexStringToColor("#7A73C7"),
                            activeFgColor:
                                Constants.hexStringToColor("#FFFFFF"),
                            inactiveBgColor:
                                Constants.hexStringToColor("#F1F0F0"),
                            inactiveFgColor:
                                Constants.hexStringToColor("#333333"),
                            fontSize: 30,
                            labels: TradeConditionEnum.getValues()
                                .values
                                .map((e) => e.name)
                                .toList(),
                            onToggle: (index) {
                              var map = TradeConditionEnum.getValues();
                              var labelDate = map[index].name;
                              _refreshController.resetLoadState();
                              this._tradeBloc.add(PagerDataEvent(
                                  labelDate: labelDate,
                                  pagerNumber: 0,
                                  pagerSize: this.pagerSize));
                            },
                          ),
                        ),
                        Space(height: Constants.getAdapterHeight(10)),
                        Container(
                          padding: Constants.paddingAll(10),
                          width: double.infinity,
                          height: Constants.getAdapterHeight(140),
                          decoration: BoxDecoration(
                            color: Constants.hexStringToColor("#FFFFFF"),
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            border: Border.all(
                                width: 1,
                                color: Constants.hexStringToColor("#FFFFFF")),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: Constants.paddingAll(0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                            text: "",
                                            style: TextStyles.getTextStyle(
                                                fontSize: 36,
                                                color:
                                                    Constants.hexStringToColor(
                                                        "#333333")),
                                            children: <TextSpan>[
                                              TextSpan(
                                                  text: "${state.totalCount}",
                                                  style:
                                                      TextStyles.getTextStyle(
                                                          fontSize: 48,
                                                          color: Constants
                                                              .hexStringToColor(
                                                                  "#7A73C7"))),
                                            ]),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                            text: "",
                                            style: TextStyles.getTextStyle(
                                                fontSize: 36,
                                                color:
                                                    Constants.hexStringToColor(
                                                        "#333333")),
                                            children: <TextSpan>[
                                              TextSpan(
                                                  text: "${state.labelDate}单数",
                                                  style:
                                                      TextStyles.getTextStyle(
                                                          fontSize: 28,
                                                          color: Constants
                                                              .hexStringToColor(
                                                                  "#999999"))),
                                            ]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: Constants.paddingAll(0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                            text: "¥",
                                            style: TextStyles.getTextStyle(
                                                fontSize: 36,
                                                color:
                                                    Constants.hexStringToColor(
                                                        "#7A73C7")),
                                            children: <TextSpan>[
                                              TextSpan(
                                                  text: "${state.totalAmount}",
                                                  style:
                                                      TextStyles.getTextStyle(
                                                          fontSize: 48,
                                                          color: Constants
                                                              .hexStringToColor(
                                                                  "#7A73C7"))),
                                            ]),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                            text: "",
                                            style: TextStyles.getTextStyle(
                                                fontSize: 36,
                                                color:
                                                    Constants.hexStringToColor(
                                                        "#7A73C7")),
                                            children: <TextSpan>[
                                              TextSpan(
                                                  text: "${state.labelDate}营业额",
                                                  style:
                                                      TextStyles.getTextStyle(
                                                          fontSize: 28,
                                                          color: Constants
                                                              .hexStringToColor(
                                                                  "#999999"))),
                                            ]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Space(height: Constants.getAdapterHeight(10)),
                        Expanded(
                          child: Container(
                            padding: Constants.paddingAll(0),
                            width: double.infinity,
                            height: Constants.getAdapterHeight(130),
                            child: _buildOrderList(state),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(TradeState tradeState) {
    return EasyRefresh(
      enableControlFinishRefresh: false,
      enableControlFinishLoad: true,
      controller: _refreshController,
      header: BallPulseHeader(),
      footer: BallPulseFooter(),
      onRefresh: () async {
        ///向下滑刷新
        _refreshController.resetLoadState();

        int pagerNumber = 0;
        String labelDate = tradeState.labelDate ?? "今日";

        this._tradeBloc.add(PagerDataEvent(
            labelDate: labelDate,
            pagerNumber: pagerNumber,
            pagerSize: this.pagerSize));
      },
      onLoad: () async {
        ///向上滑加载
        int pagerNumber = (tradeState.pagerNumber.toInt() + 1);
        String labelDate = tradeState.labelDate ?? "今日";

        this._tradeBloc.add(PagerDataEvent(
            labelDate: labelDate,
            pagerNumber: pagerNumber,
            pagerSize: this.pagerSize));
        _refreshController.finishLoad(
            noMore: tradeState.orderList.length == tradeState.totalCount);
      },
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        padding: Constants.paddingAll(0),
        itemCount: tradeState?.orderList?.length,
        physics: AlwaysScrollableScrollPhysics(),
        separatorBuilder: (BuildContext context, int index) {
          return Space(
            height: Constants.getAdapterHeight(10),
          );
        },
        itemBuilder: (BuildContext context, int index) {
          var order = tradeState.orderList[index];
          return Container(
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: Constants.getAdapterHeight(110),
                      padding: Constants.paddingSymmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Constants.hexStringToColor("#FFFFFF"),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(8.0)),
                        border: Border.all(
                            width: 1,
                            color: Constants.hexStringToColor("#FFFFFF")),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              CircleAvatar(
                                radius: Constants.getAdapterWidth(26),
                                backgroundColor:
                                    Constants.hexStringToColor("#7A73C7"),
                                child: Center(
                                  child: Text(
                                    "堂",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.getTextStyle(
                                        color: Constants.hexStringToColor(
                                            "#FFFFFF"),
                                        fontSize: 28),
                                  ),
                                ),
                              ),
                              Space(
                                height: Constants.getAdapterHeight(5),
                              ),
                              //适配商米L2k 文本超屏增加Expanded
                              //2021年5月12日 Zhanghe
                              Expanded(
                                child: Text(
                                  "堂食自营",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.getTextStyle(
                                      color:
                                          Constants.hexStringToColor("#757575"),
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          Space(
                            width: Constants.getAdapterWidth(20),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                            text: "",
                                            style: TextStyles.getTextStyle(
                                                fontSize: 32,
                                                color:
                                                    Constants.hexStringToColor(
                                                        "#333333")),
                                            children: <TextSpan>[
                                              TextSpan(
                                                  text: "单号:${order.tradeNo}",
                                                  style:
                                                      TextStyles.getTextStyle(
                                                          fontSize: 28,
                                                          color: Constants
                                                              .hexStringToColor(
                                                                  "#333333"),
                                                          fontWeight:
                                                              FontWeight.bold)),
                                            ]),
                                      ),
                                      Conditional.single(
                                        context: context,
                                        conditionBuilder:
                                            (BuildContext context) =>
                                                order.uploadStatus == 1,
                                        widgetBuilder: (BuildContext context) =>
                                            Icon(
                                          CommunityMaterialIcons.cloud_check,
                                          size: Constants.getAdapterWidth(32),
                                          color: Colors.green,
                                        ),
                                        fallbackBuilder:
                                            (BuildContext context) => Icon(
                                          CommunityMaterialIcons.cloud_alert,
                                          size: Constants.getAdapterWidth(32),
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Space(
                                  height: Constants.getAdapterHeight(5),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: RichText(
                                    text: TextSpan(
                                        text: "",
                                        style: TextStyles.getTextStyle(
                                            fontSize: 32,
                                            color: Constants.hexStringToColor(
                                                "#333333")),
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: "时间:${order.finishDate}",
                                              style: TextStyles.getTextStyle(
                                                  fontSize: 24,
                                                  color: Constants
                                                      .hexStringToColor(
                                                          "#757575"))),
                                        ]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ConditionalSwitch.single<String>(
                                  context: context,
                                  valueBuilder: (BuildContext context) =>
                                      order.orderStatus.value,
                                  caseBuilders: {
                                    '0': (BuildContext context) => Text('等待支付',
                                        style: TextStyles.getTextStyle(
                                            fontSize: 28,
                                            color: Constants.hexStringToColor(
                                                "#757575"))),
                                    '1': (BuildContext context) => Text('已支付',
                                        style: TextStyles.getTextStyle(
                                            fontSize: 28,
                                            color: Constants.hexStringToColor(
                                                "#757575"))),
                                    '2': (BuildContext context) => Text('已退单',
                                        style: TextStyles.getTextStyle(
                                            fontSize: 28,
                                            color: Constants.hexStringToColor(
                                                "#757575"))),
                                    '3': (BuildContext context) => Text('已取消',
                                        style: TextStyles.getTextStyle(
                                            fontSize: 28,
                                            color: Constants.hexStringToColor(
                                                "#757575"))),
                                    '4': (BuildContext context) => Text('已完成',
                                        style: TextStyles.getTextStyle(
                                            fontSize: 28,
                                            color: Constants.hexStringToColor(
                                                "#757575"))),
                                    '5': (BuildContext context) => Text('部分退款',
                                        style: TextStyles.getTextStyle(
                                            fontSize: 28,
                                            color: Constants.hexStringToColor(
                                                "#757575"))),
                                  },
                                  fallbackBuilder: (BuildContext context) =>
                                      Text('None',
                                          style: TextStyles.getTextStyle(
                                              fontSize: 28,
                                              color: Constants.hexStringToColor(
                                                  "#757575"))),
                                ),
                                RichText(
                                  text: TextSpan(
                                      text: "No.",
                                      style: TextStyles.getTextStyle(
                                          fontSize: 28,
                                          color: Constants.hexStringToColor(
                                              "#FF3600")),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: "${order.orderNo}",
                                            style: TextStyles.getTextStyle(
                                                fontSize: 28,
                                                color:
                                                    Constants.hexStringToColor(
                                                        "#FF3600"))),
                                      ]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: Constants.paddingLTRB(25, 5, 25, 5),
                      decoration: BoxDecoration(
                        color: Constants.hexStringToColor("#FFFFFF"),
                        border: Border.symmetric(
                            horizontal: BorderSide(
                                width: 1,
                                color: Constants.hexStringToColor("#D0D0D0"))),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _buildOrderDetail(order.items),
                          ),
                          Container(
                            height: Constants.getAdapterHeight(60),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    child: Text(
                                      "共${order.itemCount}件商品",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.getTextStyle(
                                          color: Constants.hexStringToColor(
                                              "#757575"),
                                          fontSize: 24),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color:
                                          Constants.hexStringToColor("#F7F7F7"),
                                      border: Border(
                                          bottom: BorderSide(
                                              width: 1,
                                              color: Constants.hexStringToColor(
                                                  "#E0E0E0"))),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        ///查看
                                        _showTicketDetail(order);
                                      },
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              "查看详情",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyles.getTextStyle(
                                                  color: Constants
                                                      .hexStringToColor(
                                                          "#757575"),
                                                  fontSize: 24),
                                            ),
                                            Icon(
                                              CommunityMaterialIcons
                                                  .chevron_down,
                                              size:
                                                  Constants.getAdapterWidth(32),
                                              color: Constants.hexStringToColor(
                                                  "#757575"),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: Constants.getAdapterHeight(90),
                      padding: Constants.paddingSymmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Constants.hexStringToColor("#FFFFFF"),
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(8.0)),
                        border: Border.all(
                            width: 1,
                            color: Constants.hexStringToColor("#FFFFFF")),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                    text: "¥",
                                    style: TextStyles.getTextStyle(
                                        fontSize: 32,
                                        color: Constants.hexStringToColor(
                                            "#333333")),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: "${order.paidAmount}",
                                          style: TextStyles.getTextStyle(
                                              fontSize: 46,
                                              color: Constants.hexStringToColor(
                                                  "#333333"))),
                                    ]),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ConditionalSwitch.single<String>(
                              context: context,
                              valueBuilder: (BuildContext context) =>
                                  order.orderStatus.value,
                              caseBuilders: {
                                //已退单
                                '2': (BuildContext context) => Row(
                                      children: [
                                        Container(
                                          width: Constants.getAdapterWidth(120),
                                          height:
                                              Constants.getAdapterHeight(60),
                                          child: FlatButton(
                                            child: Text("补打",
                                                style: TextStyles.getTextStyle(
                                                    fontSize: 28,
                                                    color: Constants
                                                        .hexStringToColor(
                                                            "#333333"))),
                                            color: Constants.hexStringToColor(
                                                "#D0D0D0"),
                                            disabledColor: Colors.grey,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide.none,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(4)),
                                            ),
                                            onPressed: () async {
                                              await PrinterHelper.reprintTicket(
                                                  order);
                                            },
                                            //适配商米L2k 按钮超出屏幕
                                            //2021年5月12日 Zhanghe
                                            padding: EdgeInsets.all(0),
                                          ),
                                        ),
                                        Conditional.single(
                                          context: context,
                                          conditionBuilder:
                                              (BuildContext context) =>
                                                  order.orderStatus ==
                                                      OrderStatus.Completed &&
                                                  order.refundStatus ==
                                                      OrderRefundStatus
                                                          .PartRefund,
                                          widgetBuilder:
                                              (BuildContext context) => Row(
                                            children: [
                                              Space(
                                                width:
                                                    Constants.getAdapterWidth(
                                                        20),
                                              ),
                                              Container(
                                                width:
                                                    Constants.getAdapterWidth(
                                                        120),
                                                height:
                                                    Constants.getAdapterHeight(
                                                        60),
                                                child: FlatButton(
                                                  child: Text("退单",
                                                      style: TextStyles.getTextStyle(
                                                          fontSize: 28,
                                                          color: Constants
                                                              .hexStringToColor(
                                                                  "#FFFFFF"))),
                                                  color: Constants
                                                      .hexStringToColor(
                                                          "#FF3600"),
                                                  disabledColor: Colors.grey,
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide.none,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(4)),
                                                  ),
                                                  onPressed: () {
                                                    var permissionAction =
                                                        (args) {
                                                      showRefund(
                                                          context,
                                                          order,
                                                          ModuleKeyCode.$_122
                                                              .permissionCode,
                                                          this._tradeBloc);
                                                    };
                                                    AuthzUtils.instance
                                                        .checkAuthz(
                                                            this.context,
                                                            ModuleKeyCode.$_122,
                                                            ModuleKeyCode.$_122
                                                                .permissionCode,
                                                            order,
                                                            permissionAction);
                                                  },
                                                  //适配商米L2k 按钮超出屏幕
                                                  //2021年5月12日 Zhanghe
                                                  padding: EdgeInsets.all(0),
                                                ),
                                              ),
                                            ],
                                          ),
                                          fallbackBuilder:
                                              (BuildContext context) =>
                                                  Container(),
                                        ),
                                      ],
                                    ),
                                '4': (BuildContext context) => Row(
                                      children: [
                                        Container(
                                          width: Constants.getAdapterWidth(120),
                                          height:
                                              Constants.getAdapterHeight(60),
                                          child: FlatButton(
                                            child: Text("补打",
                                                style: TextStyles.getTextStyle(
                                                    fontSize: 28,
                                                    color: Constants
                                                        .hexStringToColor(
                                                            "#333333"))),
                                            color: Constants.hexStringToColor(
                                                "#D0D0D0"),
                                            disabledColor: Colors.grey,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide.none,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(4)),
                                            ),
                                            onPressed: () async {
                                              await PrinterHelper.reprintTicket(
                                                  order);
                                            },
                                            //适配商米L2k 按钮超出屏幕
                                            //2021年5月12日 Zhanghe
                                            padding: EdgeInsets.all(0),
                                          ),
                                        ),
                                        Conditional.single(
                                          context: context,
                                          conditionBuilder:
                                              (BuildContext context) =>
                                                  order.refundStatus !=
                                                  OrderRefundStatus.Refund,
                                          widgetBuilder:
                                              (BuildContext context) => Row(
                                            children: [
                                              Space(
                                                width:
                                                    Constants.getAdapterWidth(
                                                        20),
                                              ),
                                              Container(
                                                width:
                                                    Constants.getAdapterWidth(
                                                        120),
                                                height:
                                                    Constants.getAdapterHeight(
                                                        60),
                                                child: FlatButton(
                                                  child: Text("退单",
                                                      style: TextStyles.getTextStyle(
                                                          fontSize: 28,
                                                          color: Constants
                                                              .hexStringToColor(
                                                                  "#FFFFFF"))),
                                                  color: Constants
                                                      .hexStringToColor(
                                                          "#FF3600"),
                                                  disabledColor: Colors.grey,
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide.none,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(4)),
                                                  ),
                                                  onPressed: () {
                                                    var permissionAction =
                                                        (args) {
                                                      showRefund(
                                                          context,
                                                          order,
                                                          "10019",
                                                          this._tradeBloc);
                                                    };
                                                    AuthzUtils.instance
                                                        .checkAuthz(
                                                            this.context,
                                                            ModuleKeyCode.$_122,
                                                            "10019",
                                                            order,
                                                            permissionAction);
                                                  },
                                                  //适配商米L2k 按钮超出屏幕
                                                  //2021年5月12日 Zhanghe
                                                  padding: EdgeInsets.all(0),
                                                ),
                                              ),
                                            ],
                                          ),
                                          fallbackBuilder:
                                              (BuildContext context) =>
                                                  Container(),
                                        ),
                                      ],
                                    ),
                              },
                              fallbackBuilder: (BuildContext context) =>
                                  Text('${order.orderStatus.value}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Visibility(
                  visible: order.orderStatus == OrderStatus.ChargeBack ||
                      (order.orderStatus == OrderStatus.Completed &&
                          (order.refundStatus == OrderRefundStatus.Refund ||
                              order.refundStatus ==
                                  OrderRefundStatus.PartRefund)),
                  child: Positioned(
                    left: Constants.getAdapterWidth(280),
                    bottom: Constants.getAdapterHeight(100),
                    child: Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Transform(
                          alignment: Alignment.bottomRight,
                          transform: Matrix4.skew(0.0, 0.0),
                          child: Container(
                            height: Constants.getAdapterHeight(60),
                            width: Constants.getAdapterWidth(150),
                            decoration: BoxDecoration(
                              color: Constants.hexStringToColor("#F7F7F7"),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4.0)),
                              border: Border.all(
                                  width: Constants.getAdapterWidth(5),
                                  color: Colors.redAccent),
                            ),
                            child: Center(
                              child: Text(
                                "已退单",
                                style: TextStyles.getTextStyle(
                                    color: Colors.redAccent, fontSize: 36),
                              ),
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
      ),
    );
  }

  _showTicketDetail(OrderObject orderObject) {
    showModalBottomSheet(
      context: context,
      enableDrag: false, //设置不能拖拽关闭
      backgroundColor: Colors.transparent, //重点
      isScrollControlled: true,
      builder: (BuildContext context) {
        return GestureDetector(
          child: Container(
              height: Constants.getAdapterHeight(900),
              width: Constants.getAdapterWidth(720),
              padding: Constants.paddingOnly(top: 10, bottom: 20),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#FFFFFF"),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Container(
                            width: Constants.getAdapterWidth(720),
                            height: Constants.getAdapterHeight(204),
                            padding: Constants.paddingOnly(top: 10),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage(ImageUtils.getImgPath(
                                      "home/ticket_header",
                                      format: "png")),
                                  fit: BoxFit.fill),
                            ),
                            //child:
                          ),
                          Expanded(
                            child: Container(
                              padding: Constants.paddingAll(0),
                              width: Constants.getAdapterWidth(720),
                              color: Constants.hexStringToColor("#FFFFFF"),
                            ),
                          ),
                          Container(
                            width: Constants.getAdapterWidth(720),
                            height: Constants.getAdapterHeight(204),
                            padding: Constants.paddingAll(0),
                            decoration: BoxDecoration(
                              //color: Constants.hexStringToColor("#F0F0F0"),
                              image: DecorationImage(
                                  image: AssetImage(ImageUtils.getImgPath(
                                      "home/ticket_footer",
                                      format: "png")),
                                  fit: BoxFit.fill),
                            ),
                            //child:
                          ),
                        ],
                      ),
                      Positioned(
                        top: 20.0,
                        left: 20.0,
                        child: Center(
                          child: Container(
                            padding: Constants.paddingLTRB(10, 5, 10, 20),
                            width: Constants.getAdapterWidth(640),
                            height: Constants.getAdapterHeight(800),
                            child: ListView(
                              children: _buildTicketWidget(orderObject),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
          onTap: () => false,
        );
      },
    );
  }

  //订单详情预览
  List<Widget> _buildTicketWidget(OrderObject currentOrder) {
    List<Widget> lists = new List<Widget>();
    if (currentOrder == null) {
      return lists;
    }

    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "单号:${currentOrder.tradeNo}",
      style: TextStyles.getTextStyle(
          fontSize: 24, color: Constants.hexStringToColor("#333333")),
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Row(
      children: <Widget>[
        Text(
          "收银员:${currentOrder.workerNo}",
          style: TextStyles.getTextStyle(
              fontSize: 24, color: Constants.hexStringToColor("#333333")),
        ),
        Space(width: Constants.getAdapterWidth(25)),
        Text(
          "营业员:${currentOrder.salesCode}",
          style: TextStyles.getTextStyle(
              fontSize: 24, color: Constants.hexStringToColor("#333333")),
        ),
      ],
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "销售时间:${currentOrder.finishDate}",
      style: TextStyles.getTextStyle(
          fontSize: 24, color: Constants.hexStringToColor("#333333")),
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            "品名",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(
                fontSize: 24,
                color: Constants.hexStringToColor("#333333"),
                fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(90),
          child: Text(
            "数量",
            style: TextStyles.getTextStyle(
                fontSize: 24,
                color: Constants.hexStringToColor("#333333"),
                fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(90),
          child: Text(
            "售价",
            style: TextStyles.getTextStyle(
                fontSize: 24,
                color: Constants.hexStringToColor("#333333"),
                fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(90),
          child: Text(
            "小计",
            style: TextStyles.getTextStyle(
                fontSize: 24,
                color: Constants.hexStringToColor("#333333"),
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));

    var items = currentOrder.items.map((item) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  "${item.displayName}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.getTextStyle(
                      fontSize: 24,
                      color: Constants.hexStringToColor("#333333")),
                ),
              ),
              Container(
                width: Constants.getAdapterWidth(90),
                child: Text(
                  "${item.quantity}",
                  style: TextStyles.getTextStyle(
                      fontSize: 24,
                      color: Constants.hexStringToColor("#333333")),
                ),
              ),
              Container(
                width: Constants.getAdapterWidth(90),
                child: Text(
                  "${item.price}",
                  style: TextStyles.getTextStyle(
                      fontSize: 24,
                      color: Constants.hexStringToColor("#333333")),
                ),
              ),
              Container(
                width: Constants.getAdapterWidth(90),
                child: Text(
                  "${item.amount}",
                  style: TextStyles.getTextStyle(
                      fontSize: 24,
                      color: Constants.hexStringToColor("#333333")),
                ),
              ),
            ],
          ),
          Space(height: Constants.getAdapterHeight(10)),
        ],
      );
    }).toList();

    lists.addAll(items);

    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            "共${currentOrder.totalQuantity}件",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(
                fontSize: 24,
                color: Constants.hexStringToColor("#333333"),
                fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(230),
          child: Column(
            children: <Widget>[
              Text(
                "实付金额:${currentOrder.paidAmount}",
                style: TextStyles.getTextStyle(
                    fontSize: 24, color: Constants.hexStringToColor("#333333")),
              ),
              Space(height: Constants.getAdapterHeight(10)),
              Text(
                "原价金额:${currentOrder.amount}",
                style: TextStyles.getTextStyle(
                    fontSize: 24, color: Constants.hexStringToColor("#333333")),
              ),
              Space(height: Constants.getAdapterHeight(10)),
              Text(
                "优惠金额:${currentOrder.discountAmount}",
                style: TextStyles.getTextStyle(
                    fontSize: 24, color: Constants.hexStringToColor("#333333")),
              ),
              Space(height: Constants.getAdapterHeight(10)),
              Text(
                "抹零金额:${currentOrder.malingAmount}",
                style: TextStyles.getTextStyle(
                    fontSize: 24, color: Constants.hexStringToColor("#333333")),
              )
            ],
          ),
        ),
      ],
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            "付款详情",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(
                fontSize: 24,
                color: Constants.hexStringToColor("#333333"),
                fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(230),
          child: Column(
            children: currentOrder.pays.map((item) {
              return Text(
                "${item.name}:${item.amount}",
                style: TextStyles.getTextStyle(
                    fontSize: 24, color: Constants.hexStringToColor("#333333")),
              );
            }).toList(),
          ),
        ),
      ],
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    return lists;
  }

  List<Widget> _buildOrderDetail(List<OrderItem> items) {
    var item = items[0];
    var widgets = [
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: showOrderItemMake(item),
        ),
      ),
      Container(
        padding: Constants.paddingAll(0),
        width: Constants.getAdapterWidth(150),
        alignment: Alignment.centerRight,
        child: Text("${item.quantity}",
            style: TextStyles.getTextStyle(
                color: Constants.hexStringToColor("#7A73C7"),
                fontSize: 28,
                fontWeight: FontWeight.bold)),
      ),
      Container(
        padding: Constants.paddingAll(0),
        width: Constants.getAdapterWidth(150),
        alignment: Alignment.centerRight,
        child: Text("¥${item.totalReceivableAmount}",
            style: TextStyles.getTextStyle(
                color: Constants.hexStringToColor("#7A73C7"),
                fontSize: 28,
                fontWeight: FontWeight.bold)),
      ),
    ];

    return widgets;
  }

  Widget _buildHeader(TradeState tradeState) {
    return Container(
      padding: Constants.paddingAll(0),
      height: Constants.getAdapterHeight(100.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(
            bottom: BorderSide(
                color: Constants.hexStringToColor("#F2F2F2"), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => NavigatorUtils.instance.goBack(context),
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
              width: Constants.getAdapterWidth(500),
              height: Constants.getAdapterHeight(100),
              padding: Constants.paddingLTRB(0, 10, 16, 10),
              child: Container(
                padding: Constants.paddingOnly(left: 12, right: 12),
                decoration: BoxDecoration(
                  color: Constants.hexStringToColor("#FFFFFF"),
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  border: Border.all(
                      width: 1, color: Constants.hexStringToColor("#D0D0D0")),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildSearchBox(tradeState),
                    ),
                    InkWell(
                      onTap: () async {
                        var scanResult =
                            await BarcodeScanner.scan(options: scanOptions);
                      },
                      child: LoadAssetImage(
                        "home/home_scan",
                        height: Constants.getAdapterHeight(64),
                        width: Constants.getAdapterWidth(64),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///构建搜索框
  Widget _buildSearchBox(TradeState tradeState) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(96),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: false,
        focusNode: this._focus,
        controller: this._controller,
        style: TextStyles.getTextStyle(fontSize: 32),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "扫描或者输入单号",
          hintStyle: TextStyles.getTextStyle(
              color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(0)),
              borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(0)),
              borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(0)),
              borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),

        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(24) //限制长度
        ],
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: false, //长按复制 剪切
        autocorrect: false,
      ),
    );
  }
}

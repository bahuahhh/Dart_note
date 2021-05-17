import 'package:community_material_icon/community_material_icon.dart';
import 'package:dart_notification_center/dart_notification_center.dart';
import 'package:estore_app/blocs/assistant_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_store_table.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/order_table_status.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/assistant_utils.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/pages/assistant_open_page.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

//点菜宝
class AssistantPage extends StatefulWidget {
  final Map<String, List<String>> parameters;

  AssistantPage({this.parameters});

  @override
  _AssistantPageState createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> with SingleTickerProviderStateMixin {
  //搜索框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //业务逻辑处理
  AssistantBloc _assistantBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _assistantBloc = BlocProvider.of<AssistantBloc>(context);
    assert(this._assistantBloc != null);
    //加载
    _assistantBloc.add(LoadTable());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //订阅桌台刷新事件
      DartNotificationCenter.subscribe(
        channel: Constants.REFRESH_TABLE_STATUS_CHANNEL,
        observer: this,
        onNotification: (options) {
          _assistantBloc.add(RefreshTable());
        },
      );
    });
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
                    return Container(
                      padding: Constants.paddingAll(0),
                      decoration: BoxDecoration(
                        color: Constants.hexStringToColor("#656472"),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ///顶部操作区
                          this._buildHeader(state),

                          ///中部操作区
                          this._buildContent(state),

                          ///底部操作区
                          this._buildFooter(state),
                        ],
                      ),
                    );
                  }),
            ),
          ),
        ),
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent(AssistantState state) {
    return Expanded(
      child: Container(
        padding: Constants.paddingAll(5),
        color: Constants.hexStringToColor("#656472"),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //构建桌台区域和类型
            _buildTableTypeAndArea(state, this._assistantBloc),
            Space(
              height: Constants.getAdapterHeight(10),
            ),
            //构建桌台操作区域
            Expanded(
              child: Container(
                height: double.infinity,
                padding: Constants.paddingAll(0),
                child: this._buildTable(state, this._assistantBloc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableTypeAndArea(AssistantState state, AssistantBloc assistantBloc, {double fontSize = 32}) {
    return Container(
      padding: Constants.paddingAll(0),
      child: SizedBox(
        width: double.infinity,
        height: Constants.getAdapterHeight(180),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: Constants.getAdapterHeight(90),
              padding: Constants.paddingSymmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#E6E6EB"),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: _buildTableType(state, assistantBloc),
            ),
            Container(
              width: double.infinity,
              height: Constants.getAdapterHeight(90),
              padding: Constants.paddingSymmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#E6E6EB"),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: _buildTableArea(state, assistantBloc),
            ),
          ],
        ),
      ),
    );
  }

  ///构建桌台类型
  Widget _buildTableType(AssistantState state, AssistantBloc assistantBloc, {double fontSize = 32}) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state?.tableTypeList?.length,
      itemBuilder: (context, index) {
        ///当前的分类对象
        var item = state.tableTypeList[index];

        ///是否标注为选中状态
        var selected = (state.tableType != null && state.tableType.id == item.id);
        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: selected ? Border(bottom: BorderSide(width: 4, color: Color(0xff7A73C7))) : Border(bottom: BorderSide(width: 0, color: Colors.transparent)),
            ),
            child: InkWell(
              onTap: () {
                String areaId = state.tableArea != null ? state.tableArea.id : "";
                assistantBloc.add(QueryTable(typeId: "${item.id}", areaId: areaId));
              },
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    padding: Constants.paddingLTRB(6, 0, 6, 0),
                    child: Text(
                      "${item.name}",
                      textAlign: TextAlign.center,
                      style: TextStyles.getTextStyle(color: (selected ? Color(0xff7A73C7) : Constants.hexStringToColor("#333333")), fontSize: fontSize),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ///构建桌台区域
  Widget _buildTableArea(AssistantState state, AssistantBloc assistantBloc) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state.tableAreaList.length,
      itemBuilder: (context, index) {
        var item = state.tableAreaList[index];

        ///是否标注为选中状态
        var selected = (state.tableArea != null && state.tableArea.id == item.id);

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: selected ? Border(bottom: BorderSide(width: 4, color: Color(0xff7A73C7))) : Border(bottom: BorderSide(width: 0, color: Colors.transparent)),
            ),
            child: InkWell(
              onTap: () {
                String typeId = state.tableType != null ? state.tableType.id : "";
                assistantBloc.add(QueryTable(areaId: "${item.id}", typeId: typeId));
              },
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    padding: Constants.paddingLTRB(6, 0, 6, 0),
                    child: Text("${item.name}", textAlign: TextAlign.center, style: TextStyles.getTextStyle(color: (selected ? Color(0xff7A73C7) : Color(0xff333333)), fontSize: 32)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(AssistantState state, AssistantBloc assistantBloc) {
    return GridView.builder(
      padding: Constants.paddingAll(0),
      itemCount: state?.tableList?.length,
      itemBuilder: (BuildContext context, int index) {
        var table = state.tableList[index];

        ///是否标注为选中状态
        var selected = (state.table != null && state.table.id == table.id);

        //是否已经开台或者并台
        bool isOpen = table != null && table.orderTable != null && (table.orderTable.tableAction == 1 || table.orderTable.tableAction == 3);
        //开台并切已经点单
        bool isOpenAndDish = isOpen && table.orderTable.totalQuantity > 0;
        //是否待清台
        bool isWaitClear = table != null && table.orderTable != null && (table.orderTable.tableAction == 4);
        //是否并台
        bool isMerge = isOpen && table.orderTable.tableAction == 3; //并台

        Color backgroundColor = Constants.hexStringToColor("#E6E6EB");
        Color borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#E6E6EB");
        Color titleColor1 = Constants.hexStringToColor("#333333");
        Color titleColor2 = Constants.hexStringToColor("#999999");

        //开台的时长
        int minutes = 1;
        String statusDesc = "未点单";

        if (table.orderTable != null) {
          OrderTableStatus tableStatus = OrderTableStatus.fromValue(table.orderTable.tableStatus);
          switch (tableStatus) {
            case OrderTableStatus.Free: //空闲状态
              {
                //空闲桌台的颜色
                backgroundColor = Constants.hexStringToColor("#E6E6EB");
                titleColor1 = Constants.hexStringToColor("#333333");
                titleColor2 = Constants.hexStringToColor("#999999");
                borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#E6E6EB");
              }
              break;
            case OrderTableStatus.Occupied: //在用状态
              {
                //开台，没有点单的颜色
                backgroundColor = Constants.hexStringToColor("#006633");
                titleColor1 = Constants.hexStringToColor("#FFFFFF");
                titleColor2 = Constants.hexStringToColor("#999999");
                borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#006600");

                //已经点单
                if (isOpenAndDish) {
                  statusDesc = "已下单";
                  backgroundColor = Constants.hexStringToColor("#EEB422");
                  titleColor1 = Constants.hexStringToColor("#FFFFFF");
                  titleColor2 = Constants.hexStringToColor("#FFFFFF");
                  borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#EEB422");

                  // //是否有未下单的菜
                  // if (table.orderTable.totalQuantity - table.orderTable.placeOrders > 0) {
                  //   statusDesc = "未下单";
                  //   backgroundColor = Constants.hexStringToColor("#CD5555");
                  //   titleColor1 = Constants.hexStringToColor("#FFFFFF");
                  //   titleColor2 = Constants.hexStringToColor("#FFFFFF");
                  //   borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#CD5555");
                  // }
                }

                if (isWaitClear) {
                  statusDesc = "待清台";
                  backgroundColor = Constants.hexStringToColor("#36648B");
                  titleColor1 = Constants.hexStringToColor("#FFFFFF");
                  titleColor2 = Constants.hexStringToColor("#FFFFFF");
                  borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#36648B");
                }
                //开台时长，默认单位是分钟
                var openTime = DateTime.tryParse(table.orderTable.openTime);
                minutes = DateTime.now().difference(openTime).inMinutes;
                if (minutes == 0) minutes = 1;
              }
              break;
          }
        }

        return Stack(
          fit: StackFit.passthrough,
          children: [
            Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  border: Border.all(width: 3, color: borderColor),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  onTap: () async {
                    assistantBloc.add(SelectTable(table: table));

                    if (table.orderTable != null) {
                      var orderObjectResult = await AssistantUtils.instance.getOrderObject(table.orderTable.orderId);
                      if (orderObjectResult.item1) {
                        _assistantBloc.add(LoadTableOrderObject(orderObject: orderObjectResult.item3));
                      }
                    }
                  },
                  onDoubleTap: () async {
                    assistantBloc.add(SelectTable(table: table));

                    if (table.orderTable == null) {
                      // 模拟开台操作
                      await _buttonAction("开台", table, state.orderObject);
                    } else {
                      var orderObjectResult = await AssistantUtils.instance.getOrderObject(table.orderTable.orderId);
                      if (orderObjectResult.item1) {
                        _assistantBloc.add(LoadTableOrderObject(orderObject: orderObjectResult.item3));

                        Future.delayed(Duration(milliseconds: 200), () async {
                          if (!isWaitClear) {
                            ///已经点菜了
                            if (isOpenAndDish) {
                              ///模拟购物车操作
                              await _buttonAction("购物车", table, state.orderObject);
                            } else {
                              //模拟点单操作
                              await _buttonAction("点单", table, state.orderObject);
                            }
                          } else {
                            ///模拟清台车操作
                            await _buttonAction("清台", table, state.orderObject);
                          }
                        });
                      }
                    }
                  },
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      Container(
                        padding: Constants.paddingLTRB(5, 10, 5, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Expanded(
                                  child: Visibility(
                                    visible: table.orderTable != null && table.orderTable.tableStatus == 1,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "${table.orderTable != null ? '座${table.orderTable.people}人' : ''}",
                                        style: TextStyles.getTextStyle(color: titleColor2, fontSize: 24),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: table.orderTable != null,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      table.orderTable != null ? "$statusDesc" : "",
                                      style: TextStyles.getTextStyle(color: titleColor1, fontSize: 24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  "${table.name}",
                                  style: TextStyles.getTextStyle(color: titleColor1, fontSize: 32),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Align(
                                    alignment: table.orderTable != null ? Alignment.centerLeft : Alignment.center,
                                    child: Conditional.single(
                                      context: context,
                                      conditionBuilder: (BuildContext context) => table.orderTable != null, //是否已经开台
                                      widgetBuilder: (BuildContext context) => RichText(
                                        text: TextSpan(text: "¥", style: TextStyles.getTextStyle(fontSize: 24, color: titleColor1), children: <TextSpan>[
                                          TextSpan(text: "${table.orderTable.receivableAmount}", style: TextStyles.getTextStyle(fontSize: 28, color: titleColor1)),
                                        ]),
                                      ),
                                      fallbackBuilder: (BuildContext context) => Text(
                                        "${table.number}人台",
                                        style: TextStyles.getTextStyle(color: titleColor2, fontSize: 24),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: table.orderTable != null,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      table.orderTable != null ? "$minutes分钟" : "",
                                      style: TextStyles.getTextStyle(color: titleColor1, fontSize: 24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: table.orderTable != null && table.orderTable.tableAction == 3,
                        child: Positioned.directional(
                          start: Constants.getAdapterWidth(2),
                          top: Constants.getAdapterHeight(2),
                          width: Constants.getAdapterWidth(50),
                          height: Constants.getAdapterHeight(42),
                          textDirection: TextDirection.ltr,
                          child: Container(
                            alignment: Alignment.topCenter,
                            padding: Constants.paddingLTRB(0, 0, 0, 0),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: ImageUtils.getAssetImage("home/home_discount"),
                                fit: BoxFit.fill,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(text: (table.orderTable != null && table.orderTable.tableAction == 3) ? "${(table.orderTable.masterTable == 1) ? '主' : '子'}" : "", style: TextStyles.getTextStyle(fontSize: 20, color: Constants.hexStringToColor("#FFFFFF")), children: <TextSpan>[
                                TextSpan(text: "${(table.orderTable != null && table.orderTable.tableAction == 3) ? '${table.orderTable.serialNo}' : ''}", style: TextStyles.getTextStyle(fontSize: 20, color: Constants.hexStringToColor("#FFFFFF"))),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: Constants.getAdapterWidth(10),
        crossAxisSpacing: Constants.getAdapterHeight(10),
        childAspectRatio: 1.2,
      ),
    );
  }

  Widget _buildHeader(AssistantState state) {
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
                  border: Border.all(width: 1, color: Constants.hexStringToColor("#D0D0D0")),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildSearchBox(state),
                    ),
                    InkWell(
                      onTap: () async {
                        //var scanResult = await BarcodeScanner.scan(options: scanOptions);
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
          InkWell(
            onTap: () async {
              //加载
              _assistantBloc.add(LoadTable());
            },
            child: SizedBox(
              width: Constants.getAdapterWidth(100),
              height: double.infinity,
              child: Icon(
                CommunityMaterialIcons.cloud_refresh,
                size: Constants.getAdapterWidth(64),
                color: Constants.hexStringToColor("#A52A2A"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///构建商品搜索框
  Widget _buildSearchBox(AssistantState state) {
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
          hintText: "扫描或者输入搜索",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
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

  ///构建底部工具栏
  Widget _buildFooter(AssistantState state) {
    //当前的桌台
    var table = state.table;
    //是否已经开台
    bool isOpen = table != null && table.orderTable != null && (table.orderTable.tableAction == 1 || table.orderTable.tableAction == 3);
    //开台并切已经点单
    bool isOpenAndDish = isOpen && table.orderTable.totalQuantity > 0;
    //开台并切未点单
    bool isOpenAndNoDish = isOpen && table.orderTable.totalQuantity <= 0;
    //是否并台
    bool isMerge = isOpen && table.orderTable.tableAction == 3; //并台
    //是否待清台
    bool isWaitClear = table != null && table.orderTable != null && table.orderTable.tableAction == 4;
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(5, 5, 5, 5),
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: isOpen ? _buildButton("预结单", state, enabled: isOpenAndDish) : _buildButton("开台", state, enabled: !isWaitClear),
                      ),
                      Space(
                        width: Constants.getAdapterWidth(5),
                      ),
                      Expanded(
                        child: _buildButton("点单", state, enabled: isOpen),
                      ),
                      Space(
                        width: Constants.getAdapterWidth(5),
                      ),
                      Expanded(
                        child: _buildButton("清台", state, enabled: isOpenAndNoDish || isWaitClear),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Space(width: Constants.getAdapterWidth(5)),
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
            ),
            child: _buildButton("去结算", state, color: "#7A73C7", enabled: isOpenAndDish),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String title, AssistantState state, {bool enabled = false, double fontSize = 32, String color = "#7A73C7"}) {
    //当前选中的桌台
    var selectedTable = state.table;
    return Container(
      height: Constants.getAdapterHeight(90),
      child: RaisedButton(
        padding: Constants.paddingAll(0),
        child: Text(
          "$title",
          style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: fontSize),
        ),
        color: Constants.hexStringToColor(color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        onPressed: enabled
            ? () async {
                await _buttonAction(title, selectedTable, state.orderObject);
              }
            : null,
      ),
    );
  }

  Future<void> _buttonAction(String title, StoreTable selectedTable, OrderObject orderObject) async {
    switch (title) {
      case "开台":
        {
          if (selectedTable.orderTable == null) {
            YYDialog dialog;
            //关闭弹框
            var onClose = () {
              dialog?.dismiss();
            };
            var onAccept = (args) {
              dialog?.dismiss();

              var orderObject = args.orderObject;
              this._assistantBloc.add(LoadTableOrderObject(orderObject: orderObject));

              var tableId = args.tableId;
              var toDish = args.toDish;
              //开台并点单
              if (toDish) {
                ///orderId-主单ID
                ///multipleTable-是否多桌操作(0:单桌，1:多桌)
                ///tableId-当前选择的桌台ID
                NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_ASSISTANT_DISH_PAGE}?orderId=${orderObject.id}&&multipleTable=0&&tableId=$tableId", (val) {
                  this._assistantBloc.add(RefreshTable());
                });
              } else {
                this._assistantBloc.add(RefreshTable());
              }
            };
            var widget = AssistantOpenPage(
              selectedTable,
              onAccept: onAccept,
              onClose: onClose,
            );
            dialog = DialogUtils.showDialog(context, widget, width: 650, height: 1024);
          }
        }
        break;
      case "点单":
        {
          if (selectedTable.orderTable != null) {
            //已经开台
            bool isOpen = (selectedTable.orderTable.tableAction == 1 || selectedTable.orderTable.tableAction == 3);
            //是否并台
            bool isMerge = isOpen && selectedTable.orderTable.tableAction == 3; //并台

            //并台情况下，需要选择单桌点单或多桌点单
            if (isMerge) {
              // YYDialog dialog;
              // //关闭弹框
              // var onClose = () {
              //   dialog?.dismiss();
              // };
              // //确认
              // var onAccept = (args) {
              //   dialog?.dismiss();
              //
              //   //是否选择了单桌点单，否则是多桌点单
              //   var onlySelectedTable = args.onlySelectedTable;
              //
              //   ///orderId-主单ID
              //   ///multipleTable-是否多桌操作(0:单桌，1:多桌)
              //   ///tableId-当前选择的桌台ID
              //   ///
              //   NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_CASHIER_PAGE}?orderId=${selectedTable.orderTable.orderId}&&multipleTable=${onlySelectedTable ? 0 : 1}&&tableId=${selectedTable.orderTable.tableId}", (val) {
              //     this._tableBloc.add(RefreshTable());
              //   });
              // };
              //
              // //加载桌台对应的订单信息
              // OrderObject orderObject = await OrderUtils.instance.builderOrderObject(selectedTable.orderTable.orderId);
              // var widget = MergeCashierDialog(
              //   selectedTable.orderTable.tableName,
              //   orderObject.tableName,
              //   onAccept: onAccept,
              //   onClose: onClose,
              // );
              //
              // dialog = DialogUtils.showDialog(context, widget, width: 650, height: 600);
            } else {
              //不是并台情况下，都视为单桌点单
              ///orderId-主单ID
              ///multipleTable-是否多桌操作(0:单桌，1:多桌)
              ///tableId-当前选择的桌台ID
              NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_ASSISTANT_DISH_PAGE}?orderId=${selectedTable.orderTable.orderId}&&multipleTable=0&&tableId=${selectedTable.orderTable.tableId}", (val) {
                this._assistantBloc.add(RefreshTable());
              });
            }
          }
        }
        break;
      case "购物车":
        {
          if (selectedTable.orderTable != null) {
            //已经开台
            bool isOpen = (selectedTable.orderTable.tableAction == 1 || selectedTable.orderTable.tableAction == 3);
            //是否并台
            bool isMerge = isOpen && selectedTable.orderTable.tableAction == 3; //并台

            //并台情况下，需要选择单桌点单或多桌点单
            if (isMerge) {
              // YYDialog dialog;
              // //关闭弹框
              // var onClose = () {
              //   dialog?.dismiss();
              // };
              // //确认
              // var onAccept = (args) {
              //   //是否选择了单桌点单，否则是多桌点单
              //   var onlySelectedTable = args.onlySelectedTable;
              //   dialog?.dismiss();
              //
              //   NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_CART_PAGE}?orderId=${selectedTable.orderTable.orderId}&&multipleTable=${onlySelectedTable ? 0 : 1}&&tableId=${selectedTable.orderTable.tableId}", (val) {
              //     this._tableBloc.add(RefreshTable());
              //   });
              // };
              //
              // //加载桌台对应的订单信息
              // OrderObject orderObject = await OrderUtils.instance.builderOrderObject(selectedTable.orderTable.orderId);
              //
              // var widget = MergeCashierDialog(
              //   selectedTable.orderTable.tableName,
              //   orderObject.tableName,
              //   onAccept: onAccept,
              //   onClose: onClose,
              // );
              //
              // dialog = DialogUtils.showDialog(context, widget, width: 650, height: 600);
            } else {
              //操作单个桌台
              NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_ASSISTANT_CART_PAGE}?orderId=${selectedTable.orderTable.orderId}&&multipleTable=0&&tableId=${selectedTable.orderTable.tableId}", (val) {
                this._assistantBloc.add(RefreshTable());
              });
            }
          }
        }
        break;
      case "预结单":
        {
          if (selectedTable != null && selectedTable.orderTable != null) {
            //判断桌台上是否已经点单
            OrderTableStatus tableStatus = OrderTableStatus.fromValue(selectedTable.orderTable.tableStatus);

            Map<String, dynamic> map = new Map<String, dynamic>();
            map["orderId"] = selectedTable.orderTable.orderId;
            map["workerNo"] = Global.instance.worker.no;
            map["workerName"] = Global.instance.worker.name;

            Tuple2<bool, String> prePayResult;
            //清单：桌台在用、订单存在
            DialogUtils.confirm(context, "清台提醒", "\n您确定要打印预结账单吗?\n", () async {
              if (tableStatus == OrderTableStatus.Occupied) {
                prePayResult = await AssistantUtils.instance.printPrePay(map);
                if (prePayResult.item1) {
                  //清台成功，刷新列表
                  this._assistantBloc.add(RefreshTable());
                } else {
                  ToastUtils.show(prePayResult.item2);
                }
              }
            }, () {
              FLogger.warn("用户放弃预结单打印操作");
            }, width: 500);
          } else {
            ToastUtils.show("尚未开台，预结单打印操作无效");
          }
        }
        break;
      case "清台":
        {
          if (selectedTable != null && selectedTable.orderTable != null) {
            //判断桌台上是否已经点单
            OrderTableStatus tableStatus = OrderTableStatus.fromValue(selectedTable.orderTable.tableStatus);

            List<String> orderIds = <String>[];
            orderIds.add(selectedTable.orderTable.orderId);

            Tuple2<bool, String> clearTableResult;
            //清单：桌台在用、订单存在
            DialogUtils.confirm(context, "清台提醒", "\n您确定要进行清台操作吗?\n", () async {
              if (tableStatus == OrderTableStatus.Occupied) {
                clearTableResult = await AssistantUtils.instance.clearTable(orderIds);
                if (clearTableResult.item1) {
                  //清台成功，刷新列表
                  this._assistantBloc.add(RefreshTable());
                } else {
                  ToastUtils.show(clearTableResult.item2);
                }
              }
            }, () {
              FLogger.warn("用户放弃清台操作");
            }, width: 500);
          } else {
            ToastUtils.show("尚未开台，清台操作无效");
          }
        }
        break;
      case "去结算":
        {
          if (selectedTable != null && selectedTable.orderTable != null) {
            bool isGo = true;
            if (orderObject == null || orderObject.items.length == 0) {
              isGo = false;
              ToastUtils.show("请先点单");
            }

            if (orderObject.orderStatus == OrderStatus.Completed) {
              isGo = false;
              ToastUtils.show("订单已经结账");
            }

            //结算
            if (isGo) {
              NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_ASSISTANT_PAY_PAGE}?orderId=${orderObject.id}", (val) {
                this._assistantBloc.add(RefreshTable());
              });
            }
          }
        }
        break;
    }
  }
}

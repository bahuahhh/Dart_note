import 'package:barcode_scan/platform_wrapper.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:dart_notification_center/dart_notification_center.dart';
import 'package:estore_app/blocs/table_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_store_table.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/order_table_status.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_table.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/table_utils.dart';
import 'package:estore_app/pages/table_cashier_page.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:estore_app/widgets/common_widget.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class TablePage extends StatefulWidget {
  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> with SingleTickerProviderStateMixin {
  //搜索框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //桌台逻辑处理
  TableBloc _tableBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _tableBloc = BlocProvider.of<TableBloc>(context);
    assert(this._tableBloc != null);
    //加载桌台数据
    _tableBloc.add(LoadTable());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //订阅桌台刷新事件
      DartNotificationCenter.subscribe(
        channel: Constants.REFRESH_TABLE_STATUS_CHANNEL,
        observer: this,
        onNotification: (options) {
          _tableBloc.add(RefreshTable());
        },
      );
    });
  }

  @override
  void dispose() {
    super.dispose();

    DartNotificationCenter.unregisterChannel(channel: Constants.REFRESH_TABLE_STATUS_CHANNEL);
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
        body: SafeArea(
          child: MultiBlocListener(
            listeners: [
              BlocListener<TableBloc, TableState>(
                cubit: this._tableBloc,
                listener: (context, tableState) {},
              ),
            ],
            child: BlocBuilder<TableBloc, TableState>(
              cubit: this._tableBloc,
              buildWhen: (previousState, currentState) {
                return true;
              },
              builder: (context, tableState) {
                return Scaffold(
                  resizeToAvoidBottomPadding: false, //输入框抵住键盘
                  backgroundColor: Constants.hexStringToColor("#656472"),

                  body: SafeArea(
                    left: true,
                    top: false,
                    right: true,
                    bottom: true,
                    child: Container(
                      padding: Constants.paddingAll(0),
                      decoration: BoxDecoration(
                        color: Constants.hexStringToColor("#656472"),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ///顶部操作区
                          this._buildHeader(tableState),

                          ///中部操作区
                          this._buildContent(tableState),

                          ///底部操作区
                          this._buildFooter(tableState),
                        ],
                      ),
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

  ///构建内容区域
  Widget _buildContent(TableState tableState) {
    return Expanded(
      child: Container(
        padding: Constants.paddingAll(5),
        color: Constants.hexStringToColor("#656472"),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //构建桌台区域和类型
            _buildTableTypeAndArea(tableState, _tableBloc),
            Space(
              height: Constants.getAdapterHeight(10),
            ),
            //构建桌台操作区域
            Expanded(
              child: Container(
                height: double.infinity,
                padding: Constants.paddingAll(0),
                child: this._buildTable(tableState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableTypeAndArea(TableState state, TableBloc tableBloc, {double fontSize = 32}) {
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
              child: _buildTableType(state, tableBloc),
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
              child: _buildTableArea(state, tableBloc),
            ),
          ],
        ),
      ),
    );
  }

  ///构建桌台类型
  Widget _buildTableType(TableState state, TableBloc tableBloc, {double fontSize = 32}) {
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
                tableBloc.add(QueryTable(typeId: "${item.id}", areaId: areaId));
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
  Widget _buildTableArea(TableState state, TableBloc tableBloc) {
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
                tableBloc.add(QueryTable(areaId: "${item.id}", typeId: typeId));
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

  Widget _buildTable(TableState tableState) {
    return GridView.builder(
      padding: Constants.paddingAll(0),
      itemCount: tableState?.tableList?.length,
      itemBuilder: (BuildContext context, int index) {
        var table = tableState.tableList[index];

        ///是否标注为选中状态
        var selected = (tableState.table != null && tableState.table.id == table.id);

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

                  //是否有未下单的菜
                  if (table.orderTable.totalQuantity - table.orderTable.placeOrders > 0) {
                    statusDesc = "未下单";
                    backgroundColor = Constants.hexStringToColor("#CD5555");
                    titleColor1 = Constants.hexStringToColor("#FFFFFF");
                    titleColor2 = Constants.hexStringToColor("#FFFFFF");
                    borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#CD5555");
                  }
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
                    if (table.orderTable != null) {
                      print("桌台ID:${table.orderTable.id}");
                      print("桌台编号:${table.orderTable.tableId}");
                      print("订单ID:${table.orderTable.orderId}");
                      print("订单编号:${table.orderTable.tradeNo}");
                      print("订单Action:${table.orderTable.tableAction}");
                      print("并台序号:${table.orderTable.serialNo}");
                    }

                    this._tableBloc.add(SelectTable(table: table));
                  },
                  onDoubleTap: () async {
                    this._tableBloc.add(SelectTable(table: table));
                    if (table.orderTable == null) {
                      //模拟开台操作
                      await _buttonAction("开台", table);
                    } else {
                      if (!isWaitClear) {
                        ///开台没有点菜
                        if (!isOpenAndDish) {
                          //模拟点单操作
                          await _buttonAction("点单", table);
                        }

                        ///已经点菜了
                        if (isOpenAndDish) {
                          ///模拟购物车操作
                          await _buttonAction("购物车", table);
                        }
                      } else {
                        ///模拟清台车操作
                        await _buttonAction("清台", table);
                      }
                    }
                  },
                  onLongPress: () {
                    //
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
                              text: TextSpan(
                                  text: (table.orderTable != null && table.orderTable.tableAction == 3) ? "${(table.orderTable.masterTable == 1) ? '主' : '子'}" : "",
                                  style: TextStyles.getTextStyle(fontSize: 20, color: Constants.hexStringToColor("#FFFFFF")),
                                  children: <TextSpan>[
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

  Widget _buildHeader(TableState tableState) {
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
                      child: _buildSearchBox(tableState),
                    ),
                    InkWell(
                      onTap: () async {
                        var scanResult = await BarcodeScanner.scan(options: scanOptions);
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
              //一键清台,查找等待清台的桌子
              var tables = tableState.tableList.where((x) => x.orderTable != null && x.orderTable.tableAction == 4);
              if (tables != null && tables.length > 0) {
                DialogUtils.confirm(context, "清台提醒", "\n您确定要进行一键清台操作吗?\n", () async {
                  for (var table in tables) {
                    await _buttonAction("一键清台", table);
                  }
                }, () {
                  FLogger.warn("用户放弃一键清台操作");
                }, width: 500);
              }
            },
            child: SizedBox(
              width: Constants.getAdapterWidth(100),
              height: double.infinity,
              child: Icon(
                CommunityMaterialIcons.delete_sweep,
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
  Widget _buildSearchBox(TableState tableState) {
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
  Widget _buildFooter(TableState tableState) {
    //当前的桌台
    var table = tableState.table;
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
      height: Constants.getAdapterHeight(160),
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
                        child: isOpen ? _buildButton("预结单", tableState, enabled: isOpenAndDish) : _buildButton("开台", tableState, enabled: !isWaitClear),
                      ),
                      Space(
                        width: Constants.getAdapterWidth(5),
                      ),
                      Expanded(
                        child: _buildButton("点单", tableState, enabled: isOpen),
                      ),
                      Space(
                        width: Constants.getAdapterWidth(5),
                      ),
                      Expanded(
                        child: _buildButton("清台", tableState, enabled: isOpenAndNoDish || isWaitClear),
                      ),
                    ],
                  ),
                ),
                Space(
                  height: Constants.getAdapterHeight(5),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildButton("转台", tableState, enabled: isOpen),
                      ),
                      Space(
                        width: Constants.getAdapterWidth(5),
                      ),
                      Expanded(
                        child: _buildButton("并台", tableState, enabled: (isOpen && !isMerge) && !isWaitClear),
                      ),
                      Space(
                        width: Constants.getAdapterWidth(5),
                      ),
                      Expanded(
                        child: _buildButton("拆台", tableState, enabled: isMerge && !isWaitClear),
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
            child: _buildButton("去结算", tableState, color: "#7A73C7", enabled: isOpenAndDish),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String title, TableState tableState, {bool enabled = false, double fontSize = 32, String color = "#7A73C7"}) {
    //当前选中的桌台
    var selectedTable = tableState.table;
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
                await _buttonAction(title, selectedTable);
              }
            : null,
      ),
    );
  }

  Future<void> _buttonAction(String title, StoreTable selectedTable) async {
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

              var orderTable = args.orderTable;
              var toDish = args.toDish;
              //开台并点单
              if (toDish) {
                ///orderId-主单ID
                ///multipleTable-是否多桌操作(0:单桌，1:多桌)
                ///tableId-当前选择的桌台ID
                NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_CASHIER_PAGE}?orderId=${orderTable.orderId}&&multipleTable=0&&tableId=${orderTable.tableId}", (val) {
                  this._tableBloc.add(RefreshTable());
                });
              } else {
                this._tableBloc.add(RefreshTable());
              }
            };
            var widget = OpenTablePage(
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
              YYDialog dialog;
              //关闭弹框
              var onClose = () {
                dialog?.dismiss();
              };
              //确认
              var onAccept = (args) {
                dialog?.dismiss();

                //是否选择了单桌点单，否则是多桌点单
                var onlySelectedTable = args.onlySelectedTable;

                ///orderId-主单ID
                ///multipleTable-是否多桌操作(0:单桌，1:多桌)
                ///tableId-当前选择的桌台ID
                ///
                NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_CASHIER_PAGE}?orderId=${selectedTable.orderTable.orderId}&&multipleTable=${onlySelectedTable ? 0 : 1}&&tableId=${selectedTable.orderTable.tableId}", (val) {
                  this._tableBloc.add(RefreshTable());
                });
              };

              //加载桌台对应的订单信息
              OrderObject orderObject = await OrderUtils.instance.builderOrderObject(selectedTable.orderTable.orderId);
              var widget = MergeCashierDialog(
                selectedTable.orderTable.tableName,
                orderObject.tableName,
                onAccept: onAccept,
                onClose: onClose,
              );

              dialog = DialogUtils.showDialog(context, widget, width: 650, height: 600);
            } else {
              //不是并台情况下，都视为单桌点单
              ///orderId-主单ID
              ///multipleTable-是否多桌操作(0:单桌，1:多桌)
              ///tableId-当前选择的桌台ID
              NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_CASHIER_PAGE}?orderId=${selectedTable.orderTable.orderId}&&multipleTable=0&&tableId=${selectedTable.orderTable.tableId}", (val) {
                this._tableBloc.add(RefreshTable());
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
              YYDialog dialog;
              //关闭弹框
              var onClose = () {
                dialog?.dismiss();
              };
              //确认
              var onAccept = (args) {
                //是否选择了单桌点单，否则是多桌点单
                var onlySelectedTable = args.onlySelectedTable;
                dialog?.dismiss();

                NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_CART_PAGE}?orderId=${selectedTable.orderTable.orderId}&&multipleTable=${onlySelectedTable ? 0 : 1}&&tableId=${selectedTable.orderTable.tableId}", (val) {
                  this._tableBloc.add(RefreshTable());
                });
              };

              //加载桌台对应的订单信息
              OrderObject orderObject = await OrderUtils.instance.builderOrderObject(selectedTable.orderTable.orderId);

              var widget = MergeCashierDialog(
                selectedTable.orderTable.tableName,
                orderObject.tableName,
                onAccept: onAccept,
                onClose: onClose,
              );

              dialog = DialogUtils.showDialog(context, widget, width: 650, height: 600);
            } else {
              //操作单个桌台
              NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_CART_PAGE}?orderId=${selectedTable.orderTable.orderId}&&multipleTable=0&&tableId=${selectedTable.orderTable.tableId}", (val) {
                this._tableBloc.add(RefreshTable());
              });
            }
          }
        }
        break;
      case "转台":
        {
          if (selectedTable.orderTable != null) {
            showTransferTable(context, selectedTable, this._tableBloc);
          } else {
            ToastUtils.show("请选择开台桌");
          }
        }
        break;
      case "并台":
        {
          //清理之前选择的并台数据
          _tableBloc.add(SelectMergeTable(mergeList: <StoreTable>[]));

          if (selectedTable.orderTable != null) {
            showMergeTable(context, selectedTable, this._tableBloc);
          } else {
            ToastUtils.show("请选择开台桌");
          }
        }
        break;
      case "拆台":
        {
          if (selectedTable.orderTable != null && selectedTable.orderTable.tableAction == 3) {
            DialogUtils.confirm(context, "拆分桌台", "\n您确定要进行拆分桌台吗?\n", () async {
              //获取当前订单信息
              var orderObject = await OrderUtils.instance.builderOrderObject(selectedTable.orderTable.orderId);

              //拆分桌台
              var splitTableResult = await TableUtils.instance.splitOrderTableFromOrderObject(orderObject);
              if (splitTableResult.item1) {
                //清台成功，刷新列表
                this._tableBloc.add(RefreshTable());
              } else {
                ToastUtils.show(splitTableResult.item2);
              }
            }, () {
              FLogger.warn("用户放弃拆分桌台");
            }, width: 500);
          } else {
            ToastUtils.show("请选择并台桌");
          }
        }
        break;
      case "清台":
        {
          if (selectedTable != null && selectedTable.orderTable != null) {
            //判断桌台上是否已经点单
            OrderTableStatus tableStatus = OrderTableStatus.fromValue(selectedTable.orderTable.tableStatus);
            //获取当前订单信息
            var orderObject = await OrderUtils.instance.builderOrderObject(selectedTable.orderTable.orderId);

            Tuple2<bool, String> clearTableResult;
            //清单：桌台在用、订单存在
            DialogUtils.confirm(context, "清台提醒", "\n您确定要进行清台操作吗?\n", () async {
              if (orderObject != null && tableStatus == OrderTableStatus.Occupied) {
                if ((orderObject.orderStatus == OrderStatus.Completed || orderObject.orderStatus == OrderStatus.ChargeBack) && orderObject.itemCount > 0) {
                  clearTableResult = await TableUtils.instance.clearOrderTable(selectedTable.orderTable);
                } else {
                  clearTableResult = await TableUtils.instance.clearOrderTableFromOrderObject(orderObject);
                }

                if (clearTableResult.item1) {
                  //清台成功，刷新列表
                  this._tableBloc.add(RefreshTable());
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
      case "一键清台":
        {
          if (selectedTable != null && selectedTable.orderTable != null) {
            //判断桌台上是否已经点单
            OrderTableStatus tableStatus = OrderTableStatus.fromValue(selectedTable.orderTable.tableStatus);
            //获取当前订单信息
            var orderObject = await OrderUtils.instance.builderOrderObject(selectedTable.orderTable.orderId);
            if (orderObject != null && tableStatus == OrderTableStatus.Occupied) {
              if ((orderObject.orderStatus == OrderStatus.Completed || orderObject.orderStatus == OrderStatus.ChargeBack) && orderObject.itemCount > 0) {
                //清单：桌台在用、订单存在
                Tuple2<bool, String> clearTableResult = await TableUtils.instance.clearOrderTable(selectedTable.orderTable);
                if (clearTableResult.item1) {
                  //清台成功，刷新列表
                  this._tableBloc.add(RefreshTable());
                } else {
                  ToastUtils.show(clearTableResult.item2);
                }
              }
            }
          } else {
            ToastUtils.show("尚未开台，清台操作无效");
          }
        }
        break;
      case "去结算":
        {
          if (selectedTable != null && selectedTable.orderTable != null) {
            //获取当前订单信息
            var orderObject = await OrderUtils.instance.builderOrderObject(selectedTable.orderTable.orderId);

            bool isGo = true;
            if (orderObject == null || orderObject.itemCount == 0) {
              isGo = false;
              ToastUtils.show("请先点单");
            }

            if (orderObject.orderStatus == OrderStatus.Completed) {
              isGo = false;
              ToastUtils.show("订单已经结账");
            }

            //结算
            if (isGo) {
              //是否并台,并台情况下，桌台判断是否有未下单的商品
              bool isMerge = selectedTable.orderTable != null && selectedTable.orderTable.tableAction == 3;
              var allTotalQuantity = orderObject.tables.map((x) => x.totalQuantity).fold(0, (prev, quantity) => prev + quantity);
              var allPlaceOrders = orderObject.tables.map((x) => x.placeOrders).fold(0, (prev, placeOrders) => prev + placeOrders);

              //是否有未下单的菜
              if (allTotalQuantity - allPlaceOrders > 0) {
                DialogUtils.notify(context, "操作提醒", "${isMerge ? '\n并台' : '桌台'}中未下单的商品,请先下单\n", () {}, buttonText: "我知道了", width: 500);
              } else {
                NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_PAY_PAGE}?orderId=${orderObject.id}", (val) {
                  this._tableBloc.add(RefreshTable());
                });
              }
            }
          }
        }
        break;
    }
  }
}

///开台界面
class OpenTablePage extends StatefulWidget {
  final StoreTable table;
  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  OpenTablePage(this.table, {this.onAccept, this.onClose});

  @override
  _OpenTablePageState createState() => _OpenTablePageState();
}

class _OpenTablePageState extends State<OpenTablePage> with SingleTickerProviderStateMixin {
  //就餐人数输入框
  final FocusNode _focusPeople = FocusNode();
  final TextEditingController _controllerPeople = TextEditingController();

  //备注信息输入框
  final FocusNode _focusMemo = FocusNode();
  final TextEditingController _controllerMemo = TextEditingController();

  TableBloc _tableBloc;

  @override
  void initState() {
    super.initState();

    _tableBloc = BlocProvider.of<TableBloc>(context);
    assert(this._tableBloc != null);

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      ///文本框赋值
      final text = "${widget.table.number}";
      _controllerPeople.value = _controllerPeople.value.copyWith(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();

    this._focusPeople.dispose();
    this._controllerPeople.dispose();
    this._focusMemo.dispose();
    this._controllerMemo.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fullScreenSetting();
    return KeyboardDismissOnTap(
      child: Material(
        color: Colors.transparent,
        child: BlocBuilder<TableBloc, TableState>(
          cubit: this._tableBloc,
          buildWhen: (previousState, currentState) {
            return true;
          },
          builder: (context, state) {
            return Material(
              color: Colors.transparent,
              child: Container(
                padding: Constants.paddingAll(0),
                child: Center(
                  child: Container(
                    padding: Constants.paddingLTRB(5, 5, 5, 5),
                    width: Constants.getAdapterWidth(700),
                    height: Constants.getAdapterHeight(500),
                    decoration: ShapeDecoration(
                      color: Constants.hexStringToColor("#FFFFFF"),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6.0))),
                    ),
                    child: Column(
                      children: <Widget>[
                        ///顶部标题
                        _buildHeader(),

                        ///中部操作区
                        _buildContent(state),

                        ///底部操作区
                        _buildFooter(state),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent(TableState state) {
    return Expanded(
      child: Container(
        padding: Constants.paddingLTRB(25, 15, 25, 28),
        height: Constants.getAdapterHeight(510),
        width: double.infinity,
        color: Constants.hexStringToColor("#FFFFFF"),
        child: Column(
          children: <Widget>[
            Container(
              height: Constants.getAdapterHeight(110),
              padding: Constants.paddingSymmetric(vertical: 20),
              child: Row(
                children: [
                  Text(
                    "就餐人数:",
                    style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
                  ),
                  Space(width: Constants.getAdapterWidth(20)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: Constants.getAdapterHeight(70), maxWidth: Constants.getAdapterWidth(240)),
                    child: _buildPeopleTextField(state),
                  ),
                  Space(width: Constants.getAdapterWidth(20)),
                  RichText(
                    text: TextSpan(text: "座位数:", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                      TextSpan(text: "${widget.table.number}", style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"))),
                    ]),
                  ),
                ],
              ),
            ),
            Space(height: Constants.getAdapterHeight(20)),
            Container(
              height: Constants.getAdapterHeight(110),
              padding: Constants.paddingSymmetric(vertical: 20),
              child: Row(
                children: [
                  Text(
                    "备注信息:",
                    style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
                  ),
                  Space(width: Constants.getAdapterWidth(20)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: Constants.getAdapterHeight(150), maxWidth: Constants.getAdapterWidth(400)),
                    child: _buildMemoTextField(state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///构建就餐人数
  Widget _buildPeopleTextField(TableState state) {
    return TextFormField(
      enabled: true,
      autofocus: true,
      focusNode: this._focusPeople,
      controller: this._controllerPeople,
      style: TextStyles.getTextStyle(fontSize: 32),
      decoration: InputDecoration(
        contentPadding: Constants.paddingSymmetric(horizontal: 15),
        hintText: "请输入就餐人数",
        hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 28),
        filled: true,
        fillColor: Constants.hexStringToColor("#FFFFFF"),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: Constants.hexStringToColor("#D0D0D0"), width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: Constants.hexStringToColor("#D0D0D0"), width: 1.0)),
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3) //限制长度
      ],
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      maxLines: 1,
      enableInteractiveSelection: false, //长按复制 剪切
      autocorrect: false,
    );
  }

  ///构建备注信息
  Widget _buildMemoTextField(TableState state) {
    return TextFormField(
      enabled: true,
      autofocus: false,
      focusNode: this._focusMemo,
      controller: this._controllerMemo,
      style: TextStyles.getTextStyle(fontSize: 32),
      decoration: InputDecoration(
        contentPadding: Constants.paddingSymmetric(horizontal: 15),
        hintText: "",
        hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 28),
        filled: false,
        fillColor: Constants.hexStringToColor("#FFFFFF"),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: Constants.hexStringToColor("#D0D0D0"), width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: Constants.hexStringToColor("#D0D0D0"), width: 1.0)),
      ),

      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(32) //限制长度
      ],
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.done,
      maxLines: 1,
      enableInteractiveSelection: false, //长按复制 剪切
      autocorrect: false,
    );
  }

  ///构建底部工具栏
  Widget _buildFooter(TableState state) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(10, 14, 10, 16),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(top: BorderSide(width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FlatButton(
            child: Container(
              padding: Constants.paddingAll(0),
              width: Constants.getAdapterWidth(140),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("开台并点单", style: TextStyles.getTextStyle(fontSize: 28, color: Color(0xFFFFFFFF))),
            ),
            color: Constants.hexStringToColor("#7A73C7"),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () async {
              //输入的就餐人数
              int inputPeople = Convert.toInt(StringUtils.isNotBlank(_controllerPeople.text) ? _controllerPeople.text : widget.table.number);
              //输入的备注信息
              String inputMemo = _controllerMemo.text ?? "";

              //构建开台对象
              OrderTable orderTable = TableUtils.instance.builderOrderTable(widget.table, inputPeople, memo: inputMemo);
              //通过桌台构建新的订单对象并保存
              var res = await TableUtils.instance.saveOrderObjectFromOrderTable(orderTable);
              if (res.item1) {
                //
                if (widget.onAccept != null) {
                  var args = OpenTableArgs(orderTable: orderTable, toDish: true);
                  widget.onAccept(args);
                }
              } else {
                ToastUtils.show(res.item2);
              }
            },
          ),
          Space(
            width: Constants.getAdapterWidth(20),
          ),
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(70),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("开台", style: TextStyles.getTextStyle(fontSize: 28, color: Color(0xFFFFFFFF))),
            ),
            color: Color(0xFF7A73C7),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () async {
              //输入的就餐人数
              int inputPeople = Convert.toInt(StringUtils.isNotBlank(_controllerPeople.text) ? _controllerPeople.text : widget.table.number);
              //输入的备注信息
              String inputMemo = _controllerMemo.text ?? "";
              //构建开台对象
              OrderTable orderTable = TableUtils.instance.builderOrderTable(widget.table, inputPeople, memo: inputMemo);
              //通过桌台构建新的订单对象并保存
              var res = await TableUtils.instance.saveOrderObjectFromOrderTable(orderTable);
              if (res.item1) {
                //
                if (widget.onAccept != null) {
                  var args = OpenTableArgs(orderTable: orderTable, toDish: false);
                  widget.onAccept(args);
                }
              } else {
                ToastUtils.show(res.item2);
              }
            },
          ),
          Space(
            width: Constants.getAdapterWidth(20),
          ),
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(70),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("关闭", style: TextStyles.getTextStyle(fontSize: 28, color: Color(0xFF333333))),
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
        ],
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: Constants.getAdapterHeight(90.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(bottom: BorderSide(width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: Constants.paddingOnly(left: 15),
              alignment: Alignment.centerLeft,
              child: Text("新开台[${widget.table.name}]", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32, fontWeight: FontWeight.bold)),
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
              child: Icon(CommunityMaterialIcons.close_box, color: Constants.hexStringToColor("#7A73C7"), size: Constants.getAdapterWidth(56)),
            ),
          ),
        ],
      ),
    );
  }
}

///转台界面
class TransferTablePage extends StatefulWidget {
  final StoreTable sourceTable;
  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  TransferTablePage(this.sourceTable, {this.onAccept, this.onClose});

  @override
  _TransferTablePageState createState() => _TransferTablePageState();
}

class _TransferTablePageState extends State<TransferTablePage> with SingleTickerProviderStateMixin {
  //桌台业务逻辑处理
  TableBloc _tableBloc;

  @override
  void initState() {
    super.initState();

    _tableBloc = BlocProvider.of<TableBloc>(context);
    assert(this._tableBloc != null);

    //加载转台数据
    _tableBloc.add(LoadTransferTable());

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fullScreenSetting();
    return KeyboardDismissOnTap(
      child: Material(
        color: Colors.transparent,
        child: BlocBuilder<TableBloc, TableState>(
          cubit: this._tableBloc,
          buildWhen: (previousState, currentState) {
            return true;
          },
          builder: (context, state) {
            return Material(
              color: Colors.transparent,
              child: Container(
                padding: Constants.paddingAll(0),
                child: Center(
                  child: Container(
                    padding: Constants.paddingLTRB(5, 5, 5, 0),
                    width: Constants.getAdapterWidth(720),
                    height: Constants.getAdapterHeight(1280),
                    color: Constants.hexStringToColor("#FFFFFF"),
                    child: Column(
                      children: <Widget>[
                        ///顶部标题
                        _buildHeader(),

                        ///中部操作区
                        _buildContent(state),

                        ///底部操作区
                        _buildFooter(state),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent(TableState tableState) {
    return Expanded(
      child: Container(
        padding: Constants.paddingAll(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //构建桌台区域和类型
            _buildTableTypeAndArea(tableState, _tableBloc, fontSize: 28),
            Space(
              height: Constants.getAdapterHeight(10),
            ),
            //构建桌台操作区域
            Expanded(
              child: Container(
                height: double.infinity,
                padding: Constants.paddingAll(0),
                child: this._buildTable(tableState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableTypeAndArea(TableState state, TableBloc tableBloc, {double fontSize = 32}) {
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
              child: _buildTableType(state, tableBloc),
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
              child: _buildTableArea(state, tableBloc),
            ),
          ],
        ),
      ),
    );
  }

  ///构建桌台类型
  Widget _buildTableType(TableState state, TableBloc tableBloc, {double fontSize = 32}) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state?.tableTypeList?.length,
      itemBuilder: (context, index) {
        ///当前的分类对象
        var item = state.tableTypeList[index];

        ///是否标注为选中状态
        var selected = (state.transferOrMergeType != null && state.transferOrMergeType.id == item.id);
        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: selected ? Border(bottom: BorderSide(width: 4, color: Color(0xff7A73C7))) : Border(bottom: BorderSide(width: 0, color: Colors.transparent)),
            ),
            child: InkWell(
              onTap: () {
                String areaId = state.transferOrMergeArea != null ? state.transferOrMergeArea.id : "";
                tableBloc.add(LoadTransferTable(typeId: "${item.id}", areaId: areaId));
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
  Widget _buildTableArea(TableState state, TableBloc tableBloc) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state.tableAreaList.length,
      itemBuilder: (context, index) {
        var item = state.tableAreaList[index];

        ///是否标注为选中状态
        var selected = (state.transferOrMergeArea != null && state.transferOrMergeArea.id == item.id);

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: selected ? Border(bottom: BorderSide(width: 4, color: Color(0xff7A73C7))) : Border(bottom: BorderSide(width: 0, color: Colors.transparent)),
            ),
            child: InkWell(
              onTap: () {
                String typeId = state.transferOrMergeType != null ? state.transferOrMergeType.id : "";
                tableBloc.add(LoadTransferTable(areaId: "${item.id}", typeId: typeId));
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

  Widget _buildTable(TableState tableState) {
    return GridView.builder(
      padding: Constants.paddingAll(0),
      itemCount: tableState?.transferOrMergeList?.length,
      itemBuilder: (BuildContext context, int index) {
        var table = tableState.transferOrMergeList[index];

        ///是否标注为选中状态
        var selected = (tableState.transferTable != null && tableState.transferTable.id == table.id);

        Color backgroundColor = Constants.hexStringToColor("#E6E6EB");
        Color borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#E6E6EB");
        Color titleColor1 = Constants.hexStringToColor("#333333");
        Color titleColor2 = Constants.hexStringToColor("#999999");

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
                    this._tableBloc.add(SelectTransferTable(transferOrMergeTable: table));
                  },
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      Container(
                        padding: Constants.paddingLTRB(10, 25, 10, 25),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${table.name}",
                                      style: TextStyles.getTextStyle(color: titleColor1, fontSize: 30),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${table.number}人台",
                                      style: TextStyles.getTextStyle(color: titleColor2, fontSize: 24),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: selected,
                        child: Positioned.directional(
                          start: Constants.getAdapterWidth(2),
                          top: Constants.getAdapterHeight(2),
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
                              "转",
                              style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 20),
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

  ///构建底部工具栏
  Widget _buildFooter(TableState state) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingAll(10),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(top: BorderSide(width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(180),
              height: Constants.getAdapterHeight(75),
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
              height: Constants.getAdapterHeight(75),
              alignment: Alignment.center,
              child: Text("确定", style: TextStyles.getTextStyle(fontSize: 32, color: Color(0xFFFFFFFF))),
            ),
            color: Color(0xFF7A73C7),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () async {
              //
              if (state.transferTable == null) {
                ToastUtils.show("请选择桌台");
                return;
              }

              var res = await TableUtils.instance.updateOrderObjectForTransferTable(widget.sourceTable, state.transferTable);
              if (res.item1) {
                if (widget.onAccept != null) {
                  var args = TransferTableArgs(orderObject: res.item3, targetTable: res.item4);
                  widget.onAccept(args);
                }
              } else {
                ToastUtils.show(res.item2);
              }
            },
          ),
        ],
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: Constants.getAdapterHeight(90.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(bottom: BorderSide(width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: Constants.paddingOnly(left: 15),
              alignment: Alignment.centerLeft,
              child: Text("顾客转台", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32, fontWeight: FontWeight.bold)),
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
              child: Icon(CommunityMaterialIcons.close_box, color: Constants.hexStringToColor("#7A73C7"), size: Constants.getAdapterWidth(56)),
            ),
          ),
        ],
      ),
    );
  }
}

///并台界面
class MergeTablePage extends StatefulWidget {
  final StoreTable masterTable;
  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  MergeTablePage(this.masterTable, {this.onAccept, this.onClose});

  @override
  _MergeTablePageState createState() => _MergeTablePageState();
}

class _MergeTablePageState extends State<MergeTablePage> with SingleTickerProviderStateMixin {
  //桌台业务逻辑处理
  TableBloc _tableBloc;

  @override
  void initState() {
    super.initState();

    _tableBloc = BlocProvider.of<TableBloc>(context);
    assert(this._tableBloc != null);

    //加载并台数据
    _tableBloc.add(LoadMergeTable());

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fullScreenSetting();
    return KeyboardDismissOnTap(
      child: Material(
        color: Colors.transparent,
        child: BlocBuilder<TableBloc, TableState>(
          cubit: this._tableBloc,
          buildWhen: (previousState, currentState) {
            return true;
          },
          builder: (context, state) {
            return Material(
              color: Colors.transparent,
              child: Container(
                padding: Constants.paddingAll(0),
                child: Center(
                  child: Container(
                    padding: Constants.paddingLTRB(5, 5, 5, 0),
                    width: Constants.getAdapterWidth(720),
                    height: Constants.getAdapterHeight(1280),
                    color: Constants.hexStringToColor("#FFFFFF"),
                    child: Column(
                      children: <Widget>[
                        ///顶部标题
                        _buildHeader(),

                        ///中部操作区
                        _buildContent(state),

                        ///底部操作区
                        _buildFooter(state),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent(TableState tableState) {
    return Expanded(
      child: Container(
        padding: Constants.paddingAll(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //构建桌台区域和类型
            _buildTableTypeAndArea(tableState, _tableBloc, fontSize: 28),
            Space(
              height: Constants.getAdapterHeight(10),
            ),
            //构建桌台操作区域
            Expanded(
              child: Container(
                height: double.infinity,
                padding: Constants.paddingAll(0),
                child: this._buildTable(tableState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableTypeAndArea(TableState state, TableBloc tableBloc, {double fontSize = 32}) {
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
              child: _buildTableType(state, tableBloc),
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
              child: _buildTableArea(state, tableBloc),
            ),
          ],
        ),
      ),
    );
  }

  ///构建桌台类型
  Widget _buildTableType(TableState state, TableBloc tableBloc, {double fontSize = 32}) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state?.tableTypeList?.length,
      itemBuilder: (context, index) {
        ///当前的分类对象
        var item = state.tableTypeList[index];

        ///是否标注为选中状态
        var selected = (state.transferOrMergeType != null && state.transferOrMergeType.id == item.id);
        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: selected ? Border(bottom: BorderSide(width: 4, color: Color(0xff7A73C7))) : Border(bottom: BorderSide(width: 0, color: Colors.transparent)),
            ),
            child: InkWell(
              onTap: () {
                String areaId = state.transferOrMergeArea != null ? state.transferOrMergeArea.id : "";
                tableBloc.add(LoadMergeTable(typeId: "${item.id}", areaId: areaId));
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
  Widget _buildTableArea(TableState state, TableBloc tableBloc) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state.tableAreaList.length,
      itemBuilder: (context, index) {
        var item = state.tableAreaList[index];

        ///是否标注为选中状态
        var selected = (state.transferOrMergeArea != null && state.transferOrMergeArea.id == item.id);

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: selected ? Border(bottom: BorderSide(width: 4, color: Color(0xff7A73C7))) : Border(bottom: BorderSide(width: 0, color: Colors.transparent)),
            ),
            child: InkWell(
              onTap: () {
                String typeId = state.transferOrMergeType != null ? state.transferOrMergeType.id : "";
                tableBloc.add(LoadMergeTable(areaId: "${item.id}", typeId: typeId));
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

  Widget _buildTable(TableState tableState) {
    return GridView.builder(
      padding: Constants.paddingAll(0),
      itemCount: tableState?.transferOrMergeList?.length,
      itemBuilder: (BuildContext context, int index) {
        var table = tableState.transferOrMergeList[index];

        ///是否标注为选中状态
        var selected = (tableState.mergeList != null && tableState.mergeList.any((x) => x.id == table.id));

        Color backgroundColor = Constants.hexStringToColor("#E6E6EB");
        Color borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#E6E6EB");
        Color titleColor1 = Constants.hexStringToColor("#333333");
        Color titleColor2 = Constants.hexStringToColor("#999999");

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
                    //当前已经选择合并桌台清单
                    List<StoreTable> tables = (tableState.mergeList ?? <StoreTable>[]).map((e) => StoreTable.clone(e)).toList();
                    var exists = tables.any((x) => x.id == table.id);
                    if (exists) {
                      tables.removeWhere((x) => x.id == table.id);
                    } else {
                      tables.add(table);
                    }
                    this._tableBloc.add(SelectMergeTable(mergeList: tables));
                  },
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      Container(
                        padding: Constants.paddingLTRB(10, 25, 10, 25),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${table.name}",
                                      style: TextStyles.getTextStyle(color: titleColor1, fontSize: 30),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${table.number}人台",
                                      style: TextStyles.getTextStyle(color: titleColor2, fontSize: 24),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: selected,
                        child: Positioned.directional(
                          start: Constants.getAdapterWidth(2),
                          top: Constants.getAdapterHeight(2),
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
                              "并",
                              style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 20),
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

  ///构建底部工具栏
  Widget _buildFooter(TableState state) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingAll(10),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(top: BorderSide(width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(180),
              height: Constants.getAdapterHeight(75),
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
              height: Constants.getAdapterHeight(75),
              alignment: Alignment.center,
              child: Text("确定", style: TextStyles.getTextStyle(fontSize: 32, color: Color(0xFFFFFFFF))),
            ),
            color: Color(0xFF7A73C7),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () async {
              //
              if (state.mergeList == null || state.mergeList.length == 0) {
                ToastUtils.show("请选择桌台");
                return;
              }
              var res = await TableUtils.instance.updateOrderObjectForMergeTable(widget.masterTable, state.mergeList);

              if (res.item1) {
                if (widget.onAccept != null) {
                  var args = EmptyArgs();
                  widget.onAccept(args);
                }
              } else {
                ToastUtils.show(res.item2);
              }
            },
          ),
        ],
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: Constants.getAdapterHeight(90.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(bottom: BorderSide(width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: Constants.paddingOnly(left: 15),
              alignment: Alignment.centerLeft,
              child: Text("合并餐台", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32, fontWeight: FontWeight.bold)),
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
              child: Icon(CommunityMaterialIcons.close_box, color: Constants.hexStringToColor("#7A73C7"), size: Constants.getAdapterWidth(56)),
            ),
          ),
        ],
      ),
    );
  }
}

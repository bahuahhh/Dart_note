import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/shift_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_shiftover_ticket_pay.dart';
import 'package:estore_app/enums/print_ticket_enum.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/order/shift_utils.dart';
import 'package:estore_app/printer/printer_helper.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/device_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:estore_app/entity/pos_shiftover_ticket.dart';

class ShiftPage extends StatefulWidget {
  final Map<String, List<String>> parameters;

  ShiftPage({this.parameters});

  @override
  _ShiftPageState createState() => _ShiftPageState();
}

class _ShiftPageState extends State<ShiftPage> with SingleTickerProviderStateMixin {
  //业务逻辑处理
  ShiftBloc _shiftBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _shiftBloc = BlocProvider.of<ShiftBloc>(context);
    assert(this._shiftBloc != null);
    //加载
    _shiftBloc.add(LoadShiftData());

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
            child: BlocListener<ShiftBloc, ShiftState>(
              cubit: this._shiftBloc,
              listener: (context, state) {},
              child: BlocBuilder<ShiftBloc, ShiftState>(
                  cubit: this._shiftBloc,
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
  Widget _buildContent(ShiftState state) {
    return Expanded(
      child: Container(
        padding: Constants.paddingOnly(top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: Constants.hexStringToColor("#FFFFFF"),
          borderRadius: BorderRadius.all(Radius.circular(0.0)),
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
                        image: DecorationImage(image: AssetImage(ImageUtils.getImgPath("home/ticket_header", format: "png")), fit: BoxFit.fill),
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
                        image: DecorationImage(image: AssetImage(ImageUtils.getImgPath("home/ticket_footer", format: "png")), fit: BoxFit.fill),
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
                      height: Constants.getAdapterHeight(1000),
                      child: ListView(
                        children: _buildTicketWidget(state),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTicketWidget(ShiftState state) {
    List<Widget> lists = new List<Widget>();

    lists.add(Container(
      width: Constants.getAdapterWidth(280),
      child: Center(
        child: Text("交班单", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 42)),
      ),
    ));
    lists.add(Space(height: Constants.getAdapterHeight(5)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "门店:${Global.instance.authc.storeName}",
      style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "POS机号:${Global.instance.authc.posNo}",
      style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "收银员:${Global.instance.worker.no} | ${Global.instance.worker.name} ",
      style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "交班日期:${state.shiftDate}",
      style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "交班时间:${state.shiftTime}",
      style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "上机时间:${state.shiftLog?.startTime}",
      style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    // lists.add(Text(
    //   "客单数:",
    //   style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
    // ));
    // lists.add(Space(height: Constants.getAdapterHeight(10)));
    //
    // lists.add(Text(
    //   "单均消费:",
    //   style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")),
    // ));
    // lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Text(
      "收款对账:",
      style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));

    lists.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            "收款方式",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(120),
          alignment: Alignment.center,
          child: Text(
            "笔数",
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(150),
          alignment: Alignment.centerRight,
          child: Text(
            "收款金额",
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));

    var items = state.shiftPayList.map((item) {
      return Column(
        children: [
          Space(height: Constants.getAdapterHeight(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  "${item.payModeName}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
                ),
              ),
              Container(
                width: Constants.getAdapterWidth(120),
                alignment: Alignment.center,
                child: Text(
                  "${item.quantity}",
                  style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
                ),
              ),
              Container(
                width: Constants.getAdapterWidth(150),
                alignment: Alignment.centerRight,
                child: Text(
                  "${OrderUtils.instance.toRound(item.amount)}",
                  style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
                ),
              ),
            ],
          ),
          // Space(height: Constants.getAdapterHeight(10)),
        ],
      );
    }).toList();

    if (items.length > 0) {
      lists.addAll(items);
    } else {
      lists.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              "没有交易流水记录",
              overflow: TextOverflow.ellipsis,
              style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
            ),
          ),
          Container(
            width: Constants.getAdapterWidth(150),
            alignment: Alignment.centerRight,
            child: Text(
              "",
              style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
            ),
          ),
        ],
      ));
    }

    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            "合计",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(150),
          alignment: Alignment.centerRight,
          child: Text(
            "${OrderUtils.instance.toRound(state.shiftAmount)}",
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Text(
      "现金收支明细:",
      style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
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
            "消费现金收入",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(150),
          alignment: Alignment.centerRight,
          child: Text(
            "${OrderUtils.instance.toRound(state.cashPayDetail?.consumeCash ?? 0.00)}",
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
          ),
        ),
      ],
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            "消费现金退款",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(150),
          alignment: Alignment.centerRight,
          child: Text(
            "${OrderUtils.instance.toRound(state.cashPayDetail?.consumeCashRefund ?? 0.00)}",
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
          ),
        ),
      ],
    ));
    lists.add(Space(height: Constants.getAdapterHeight(10)));

    // lists.add(Space(height: Constants.getAdapterHeight(10)));
    // lists.add(Row(
    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   children: <Widget>[
    //     Expanded(
    //       child: Text(
    //         "杂项现金收入",
    //         overflow: TextOverflow.ellipsis,
    //         style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
    //       ),
    //     ),
    //     Container(
    //       width: Constants.getAdapterWidth(150),
    //       alignment: Alignment.centerRight,
    //       child: Text(
    //         "0.00",
    //         style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
    //       ),
    //     ),
    //   ],
    // ));
    // lists.add(Space(height: Constants.getAdapterHeight(10)));
    //
    // lists.add(Space(height: Constants.getAdapterHeight(10)));
    // lists.add(Row(
    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   children: <Widget>[
    //     Expanded(
    //       child: Text(
    //         "杂项现金支出",
    //         overflow: TextOverflow.ellipsis,
    //         style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
    //       ),
    //     ),
    //     Container(
    //       width: Constants.getAdapterWidth(150),
    //       alignment: Alignment.centerRight,
    //       child: Text(
    //         "0.00",
    //         style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
    //       ),
    //     ),
    //   ],
    // ));
    // lists.add(Space(height: Constants.getAdapterHeight(10)));

    lists.add(Divider(height: 1, color: Constants.hexStringToColor("#B8B8B8")));
    lists.add(Space(height: Constants.getAdapterHeight(10)));
    lists.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            "应上缴现金",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: Constants.getAdapterWidth(150),
          alignment: Alignment.centerRight,
          child: Text(
            "${OrderUtils.instance.toRound(state.cashPayDetail?.totalCash ?? 0.00)}",
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
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
        Container(
          width: Constants.getAdapterWidth(150),
          alignment: Alignment.centerLeft,
          child: Text(
            "交班备注:",
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            "",
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333"), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ));

    lists.add(Space(height: Constants.getAdapterHeight(10)));

    return lists;
  }

  ///构建底部工具栏
  Widget _buildFooter(ShiftState state) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(5, 5, 5, 5),
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#9898A1"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: InkWell(
                onTap: () async {
                  ///结账
                },
                child: Container(
                  width: Constants.getAdapterWidth(280),
                  child: Center(
                    child: Text("备注说明", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          ),
          Space(width: Constants.getAdapterWidth(5)),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  color: Constants.hexStringToColor("#7A73C7"),
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
                ),
                child: InkWell(
                  onTap: () async {
                    ///确认交班
                    if (state.shiftLog == null) {
                      ToastUtils.show("没有班次，无法交班");
                      return;
                    }

                    var shiftLog = state.shiftLog;
                    var orderPayList = state.orderPayList;
                    var cashPayDetail = state.cashPayDetail;
                    var shiftAmount = state.shiftAmount;
                    var memo = "";
                    var shiftResult = await ShiftUtils.instance.saveShiftLog(shiftLog, orderPayList, cashPayDetail, shiftAmount, memo);

                    if (shiftResult.item1) {
                      var shiftOrder = shiftResult.item3;
                      ToastUtils.show("打印交班单...");
                      PrinterHelper.printShiftTicket(PrintTicketEnum.ShiftOrder, shiftOrder);

                      Future.delayed(Duration(seconds: 5), () {
                        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                      });
                    } else {
                      ToastUtils.show("${shiftResult.item2}");
                    }
                  },
                  child: Container(
                    width: Constants.getAdapterWidth(280),
                    child: Center(
                      child: Text("确认交班", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ShiftState state) {
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
              height: double.infinity,
              padding: Constants.paddingAll(0),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#FFFFFF"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border.all(width: 0, color: Constants.hexStringToColor("#FFFFFF")),
              ),
              child: Text(
                "交班",
                style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#383838"), fontSize: 36, fontWeight: FontWeight.bold),
              ),
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

import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/printer_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/printer/printer_constant.dart';
import 'package:estore_app/printer/printer_helper.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/checkbox_group.dart';
import 'package:estore_app/widgets/grouped_buttons_orientation.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:estore_app/widgets/toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional_switch.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';

class PrinterPage extends StatefulWidget {
  @override
  _PrinterPageState createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage>
    with SingleTickerProviderStateMixin {
  //抹零业务逻辑处理
  PrinterBloc _printerBloc;

  @override
  void initState() {
    super.initState();

    _printerBloc = BlocProvider.of<PrinterBloc>(context);
    assert(this._printerBloc != null);

    //加载打印机清单
    _printerBloc.add(LoadPrinter());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, //输入框抵住键盘
      backgroundColor: Constants.hexStringToColor("#656472"),
      body: BlocListener<PrinterBloc, PrinterState>(
        cubit: this._printerBloc,
        listener: (context, state) {},
        child: BlocBuilder<PrinterBloc, PrinterState>(
          cubit: this._printerBloc,
          buildWhen: (previousState, currentState) {
            return true;
          },
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _loadPrinter(state),
                ),
                Container(
                  width: double.infinity,
                  height: Constants.getAdapterHeight(100),
                  padding: Constants.paddingAll(10),
                  color: Constants.hexStringToColor("#FFFFFF"),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            FlatButton(
                              child: Container(
                                //适配商米L2k 控件超出屏幕
                                //  Width 180->176
                                //2021年5月12日 Zhanghe
                                padding: EdgeInsets.all(0),
                                width: Constants.getAdapterWidth(176),
                                height: Constants.getAdapterHeight(60),
                                alignment: Alignment.center,
                                child: Text("删除打印机",
                                    style: TextStyles.getTextStyle(
                                        fontSize: 28,
                                        color: Constants.hexStringToColor(
                                            "#FFFFFF"))),
                              ),
                              color: Constants.hexStringToColor("#FF3600"),
                              disabledColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                side: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                              onPressed: () {
                                if (state.currentPrinter == null) {
                                  ToastUtils.show("请选择您要删除的打印机");
                                  return;
                                }

                                this
                                    ._printerBloc
                                    .add(DeletePrinter(state.currentPrinter));
                              },
                            ),
                            Space(
                              width: Constants.getAdapterWidth(20),
                            ),
                            FlatButton(
                              child: Container(
                                //适配商米L2k 控件超出屏幕
                                //  Width 180->176
                                //2021年5月12日 Zhanghe
                                padding: EdgeInsets.all(0),
                                width: Constants.getAdapterWidth(176),
                                height: Constants.getAdapterHeight(60),
                                alignment: Alignment.center,
                                child: Text("编辑打印机",
                                    style: TextStyles.getTextStyle(
                                        fontSize: 28,
                                        color: Constants.hexStringToColor(
                                            "#333333"))),
                              ),
                              color: Constants.hexStringToColor("#D0D0D0"),
                              disabledColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                side: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                              onPressed: () {
                                print("####>>>>>${state.currentPrinter}");

                                if (StringUtils.isBlank(
                                    "${state.currentPrinter?.id}")) {
                                  ToastUtils.show("请选择您要编辑的打印机");
                                  return;
                                }

                                this._printerBloc.add(EditPrinter(
                                    printerId: "${state.currentPrinter.id}"));

                                // 延时执行返回
                                Future.delayed(Duration(milliseconds: 10), () {
                                  //弹出框
                                  YYDialog dialog;
                                  //关闭支付弹窗
                                  var onClose = () {
                                    dialog?.dismiss();

                                    //刷新界面
                                    _printerBloc.add(RefreshPrinter(
                                        printerId:
                                            "${state.currentPrinter?.id}"));
                                  };

                                  //支付金额输入
                                  var widget = PrinterParameterPage(
                                    "${state.currentPrinter.id}",
                                    onClose: onClose,
                                  );

                                  dialog = DialogUtils.showDialog(
                                      context, widget,
                                      width: 720, height: 1280);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  ///添加打印机
  Widget _loadPrinter(PrinterState state) {
    return Container(
      padding: Constants.paddingSymmetric(vertical: 20, horizontal: 40),
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "打印机设置",
            style: TextStyles.getTextStyle(
                color: Constants.hexStringToColor("#444444"),
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          Space(
            height: Constants.getAdapterHeight(30),
          ),
          Row(
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      //通知添加
                      this._printerBloc.add(EditPrinter(printerId: ""));

                      // 延时执行返回
                      Future.delayed(Duration(milliseconds: 10), () {
                        //弹出框
                        YYDialog dialog;
                        //关闭支付弹窗
                        var onClose = () {
                          dialog?.dismiss();

                          //刷新界面
                          _printerBloc.add(RefreshPrinter(
                              printerId: "${state.currentPrinter?.id}"));
                        };

                        //支付金额输入
                        var widget = PrinterParameterPage(
                          "",
                          onClose: onClose,
                        );

                        dialog = DialogUtils.showDialog(context, widget,
                            width: 720, height: 1100);
                      });
                    },
                    child: CircleAvatar(
                      radius: Constants.getAdapterWidth(45),
                      backgroundColor: Constants.hexStringToColor("#7A73C7"),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: Constants.getAdapterWidth(45),
                          color: Constants.hexStringToColor("#FFFFFF"),
                        ),
                      ),
                    ),
                  ),
                  Space(
                    height: Constants.getAdapterHeight(8),
                  ),
                  Text(
                    "添加打印机",
                    overflow: TextOverflow.visible,
                    style: TextStyles.getTextStyle(
                        color: Constants.hexStringToColor("#444444"),
                        fontSize: 32),
                  ),
                ],
              ),

              ///间距
              Space(
                width: Constants.getAdapterWidth(50),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      //刷新打印机
                      this._printerBloc.add(RefreshPrinter(
                          printerId:
                              "${state.currentPrinter != null ? state.currentPrinter.id : ''}"));
                    },
                    child: CircleAvatar(
                      radius: Constants.getAdapterWidth(45),
                      backgroundColor: Constants.hexStringToColor("#7A73C7"),
                      child: Center(
                        child: Icon(
                          Icons.refresh,
                          size: Constants.getAdapterWidth(45),
                          color: Constants.hexStringToColor("#FFFFFF"),
                        ),
                      ),
                    ),
                  ),
                  Space(
                    height: Constants.getAdapterHeight(8),
                  ),
                  Text(
                    "刷新打印机状态",
                    overflow: TextOverflow.visible,
                    style: TextStyles.getTextStyle(
                        color: Constants.hexStringToColor("#444444"),
                        fontSize: 32),
                  ),
                ],
              ),
            ],
          ),
          //垂直间隔
          Space(
            height: Constants.getAdapterHeight(50),
          ),
          Text(
            "正在使用",
            style: TextStyles.getTextStyle(
                color: Constants.hexStringToColor("#444444"),
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          Space(
            height: Constants.getAdapterHeight(30),
          ),
          //正在使用打印机清单
          Expanded(
            child: Container(
              padding: Constants.paddingSymmetric(vertical: 0, horizontal: 0),
              alignment: Alignment.centerLeft,
              child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemCount: state.printers?.length,
                separatorBuilder: (BuildContext context, int index) =>
                    Space(height: Constants.getAdapterHeight(50)),
                itemBuilder: (context, index) {
                  var item = state.printers[index];
                  var selected = (item.id == state.currentPrinter.id);
                  var backgroundColor = selected
                      ? Constants.hexStringToColor("#F8F7FF")
                      : Constants.hexStringToColor("#FFFFFF");
                  var borderColor = selected
                      ? Constants.hexStringToColor("#7A73C7")
                      : Constants.hexStringToColor("#D0D0D0");
                  var textColor = selected
                      ? Constants.hexStringToColor("#7A73C7")
                      : Constants.hexStringToColor("#444444");

                  return InkWell(
                    onTap: () {
                      //选择打印机
                      this
                          ._printerBloc
                          .add(SelectPrinter(printerId: "${item.id}"));
                    },
                    child: Container(
                        padding: Constants.paddingLTRB(10, 20, 10, 10),
                        width: Constants.getAdapterWidth(90),
                        height: Constants.getAdapterHeight(300),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(color: borderColor, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        ),
                        child: Container(
                          padding: Constants.paddingAll(0),
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "${item.brandName}",
                                overflow: TextOverflow.visible,
                                style: TextStyles.getTextStyle(
                                    color: textColor, fontSize: 28),
                              ),
                              Space(
                                height: Constants.getAdapterHeight(20),
                              ),
                              Text(
                                "${item.ticketType}",
                                overflow: TextOverflow.visible,
                                style: TextStyles.getTextStyle(
                                    color: textColor, fontSize: 28),
                              ),
                              Space(
                                height: Constants.getAdapterHeight(20),
                              ),
                              ConditionalSwitch.single<String>(
                                context: context,
                                valueBuilder: (BuildContext context) =>
                                    item.brandName,
                                caseBuilders: {
                                  '外置打印机': (BuildContext context) {
                                    return Text(
                                      "${item.port}",
                                      overflow: TextOverflow.visible,
                                      style: TextStyles.getTextStyle(
                                          color: textColor, fontSize: 28),
                                    );
                                  },
                                  '内置打印机': (BuildContext context) {
                                    return Text(
                                      "${item.driverName}",
                                      overflow: TextOverflow.visible,
                                      style: TextStyles.getTextStyle(
                                          color: textColor, fontSize: 28),
                                    );
                                  },
                                },
                                fallbackBuilder: (BuildContext context) {
                                  return Container();
                                },
                              ),
                              Space(
                                height: Constants.getAdapterHeight(20),
                              ),
                              Text(
                                "正常",
                                overflow: TextOverflow.visible,
                                style: TextStyles.getTextStyle(
                                    color: textColor, fontSize: 28),
                              ),
                            ],
                          ),
                        )),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrinterParameterPage extends StatefulWidget {
  final String printerId;
  final OnCloseCallback onClose;

  PrinterParameterPage(this.printerId, {this.onClose});

  @override
  _PrinterParameterPageState createState() => _PrinterParameterPageState();
}

class _PrinterParameterPageState extends State<PrinterParameterPage>
    with SingleTickerProviderStateMixin {
  PrinterBloc _printerBloc;

  @override
  void initState() {
    super.initState();

    _printerBloc = BlocProvider.of<PrinterBloc>(context);
    assert(this._printerBloc != null);

    this._printerBloc.add(EditPrinter(printerId: widget.printerId));

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      final text = "127.0.0.1";
      _controller.value = _controller.value.copyWith(
        text: text,
        //selection: TextSelection(baseOffset: 0, extentOffset: text.length),
        //composing: TextRange.empty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrinterBloc, PrinterState>(
      cubit: this._printerBloc,
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
                padding: Constants.paddingAll(0),
                decoration: ShapeDecoration(
                  color: Constants.hexStringToColor("#FFFFFF"),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6.0))),
                ),
                child: Column(
                  children: <Widget>[
                    ///顶部标题
                    _buildHeader(state),

                    ///中部操作区
                    _buildContent(state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ///构建内容区域
  Widget _buildContent(PrinterState state) {
    return Container(
      padding: Constants.paddingAll(10),
      height: Constants.getAdapterHeight(1000),
      width: double.infinity,
      color: Constants.hexStringToColor("#FFFFFF"),
      child: Column(
        children: [
          ToggleSwitch(
            minWidth: Constants.getAdapterWidth(690 / 4),
            minHeight: Constants.getAdapterHeight(70),
            initialLabelIndex: PrinterTicketEunm.getIndex(
                "${state.currentPrinter.ticketType}"),
            activeBgColor: Constants.hexStringToColor("#7A73C7"),
            activeFgColor: Constants.hexStringToColor("#FFFFFF"),
            inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
            inactiveFgColor: Constants.hexStringToColor("#333333"),
            fontSize: 28,
            labels: PrinterTicketEunm.getValues()
                .values
                .map((e) => e.name)
                .toList(),
            onToggle: (index) {
              var map = PrinterTicketEunm.getValues();
              var ticketName = map[index].name;
              this._printerBloc.add(PrinterParameter(ticketType: ticketName));
            },
          ),
          Space(height: Constants.getAdapterHeight(15)),
          ToggleSwitch(
            minWidth: Constants.getAdapterWidth(692 / 2),
            minHeight: Constants.getAdapterHeight(70),
            initialLabelIndex:
                PrinterModelEunm.getIndex("${state.currentPrinter.brandName}"),
            activeBgColor: Constants.hexStringToColor("#7A73C7"),
            activeFgColor: Constants.hexStringToColor("#FFFFFF"),
            inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
            inactiveFgColor: Constants.hexStringToColor("#333333"),
            fontSize: 28,
            labels:
                PrinterModelEunm.getValues().values.map((e) => e.name).toList(),
            onToggle: (index) {
              var map = PrinterModelEunm.getValues();
              var brandName = map[index].name;
              this._printerBloc.add(PrinterParameter(brandName: brandName));
            },
          ),
          Space(height: Constants.getAdapterHeight(15)),
          ConditionalSwitch.single<String>(
            context: context,
            valueBuilder: (BuildContext context) =>
                state.currentPrinter.brandName,
            caseBuilders: {
              '外置打印机': (BuildContext context) {
                return Container(
                  padding: Constants.paddingOnly(left: 0),
                  width: double.infinity,
                  child: Column(
                    children: [
                      ToggleSwitch(
                        minWidth: Constants.getAdapterWidth(690 / 2),
                        minHeight: Constants.getAdapterHeight(70),
                        initialLabelIndex: PrinterPortEunm.getIndex(
                            "${state.currentPrinter.brandName}"),
                        activeBgColor: Constants.hexStringToColor("#7A73C7"),
                        activeFgColor: Constants.hexStringToColor("#FFFFFF"),
                        inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
                        inactiveFgColor: Constants.hexStringToColor("#333333"),
                        fontSize: 28,
                        labels: PrinterPortEunm.getValues()
                            .values
                            .map((e) => e.name)
                            .toList(),
                        onToggle: (index) {
                          var map = PrinterPortEunm.getValues();
                          var portName = map[index].name;
                          this
                              ._printerBloc
                              .add(PrinterParameter(port: portName));
                        },
                      ),
                      Space(height: Constants.getAdapterHeight(15)),
                      Container(
                        padding: Constants.paddingOnly(left: 10, right: 10),
                        decoration: BoxDecoration(
                          color: Constants.hexStringToColor("#FFFFFF"),
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                          border: Border.all(
                              width: 1,
                              color: Constants.hexStringToColor("#D0D0D0")),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: _buildInputBox(state),
                            ),
                            InkWell(
                              onTap: () async {
                                //
                              },
                              child: Icon(
                                CommunityMaterialIcons.printer_search,
                                color: Constants.hexStringToColor("#808A87"),
                                size: Constants.getAdapterWidth(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              '内置打印机': (BuildContext context) {
                return Container(
                  padding: Constants.paddingOnly(left: 10, right: 10),
                  width: double.infinity,
                  height: Constants.getAdapterHeight(160),
                  child: GridView.builder(
                    itemCount: PrinterEmbedEunm.getValues().length,
                    shrinkWrap: true,
                    physics: AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: Constants.getAdapterWidth(10),
                      crossAxisSpacing: Constants.getAdapterHeight(10),
                      childAspectRatio: Constants.getAdapterWidth(400) /
                          Constants.getAdapterHeight(132),
                    ),
                    itemBuilder: (context, index) {
                      var map = PrinterEmbedEunm.getValues();

                      var printerName = map[index].name;
                      var driverName = state.currentPrinter.driverName;
                      var selected = (printerName ==
                          (StringUtils.isNotBlank(driverName)
                              ? driverName
                              : map[0].name));

                      return _buildEmbedPrinter(index, printerName, selected);
                    },
                  ),
                );
              },
            },
            fallbackBuilder: (BuildContext context) {
              return Container();
            },
          ),
          Space(height: Constants.getAdapterHeight(15)),
          Container(
            padding: Constants.paddingOnly(left: 10, right: 10),
            width: double.infinity,
            height: Constants.getAdapterHeight(70),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ToggleSwitch(
                    minWidth: Constants.getAdapterWidth(660 / 4),
                    minHeight: Constants.getAdapterHeight(70),
                    initialLabelIndex: PrinterPagerEunm.getIndex(
                        "${state.currentPrinter.pageWidth}"),
                    activeBgColor: Constants.hexStringToColor("#7A73C7"),
                    activeFgColor: Constants.hexStringToColor("#FFFFFF"),
                    inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
                    inactiveFgColor: Constants.hexStringToColor("#333333"),
                    fontSize: 28,
                    labels: PrinterPagerEunm.getValues()
                        .values
                        .map((e) => e.name)
                        .toList(),
                    onToggle: (index) {
                      var map = PrinterPagerEunm.getValues();
                      var pagerWidth = map[index].value;
                      this._printerBloc.add(PrinterParameter(
                          pageWidth: Convert.toInt(pagerWidth)));
                    },
                  ),
                ),
                Space(
                  width: Constants.getAdapterWidth(15),
                ),
                Expanded(
                  child: ToggleSwitch(
                    minWidth: Constants.getAdapterWidth(660 / 6),
                    minHeight: Constants.getAdapterHeight(70),
                    initialLabelIndex: PrinterCutEunm.getIndex(
                        "${state.currentPrinter.brandName}"),
                    activeBgColor: Constants.hexStringToColor("#7A73C7"),
                    activeFgColor: Constants.hexStringToColor("#FFFFFF"),
                    inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
                    inactiveFgColor: Constants.hexStringToColor("#333333"),
                    fontSize: 28,
                    labels: PrinterCutEunm.getValues()
                        .values
                        .map((e) => e.name)
                        .toList(),
                    onToggle: (index) {
                      var map = PrinterCutEunm.getValues();
                      var cutType = map[index].name;
                      this._printerBloc.add(PrinterParameter(cutType: cutType));
                    },
                  ),
                ),
              ],
            ),
          ),
          Space(height: Constants.getAdapterHeight(20)),
          Container(
            padding: Constants.paddingOnly(left: 10, right: 10),
            width: double.infinity,
            height: Constants.getAdapterHeight(70),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ToggleSwitch(
                    minWidth: Constants.getAdapterWidth(660 / 4),
                    minHeight: Constants.getAdapterHeight(70),
                    initialLabelIndex: PrinterBarcodeEunm.getIndex(
                        "${state.currentPrinter.printBarcodeFlag}"),
                    activeBgColor: Constants.hexStringToColor("#7A73C7"),
                    activeFgColor: Constants.hexStringToColor("#FFFFFF"),
                    inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
                    inactiveFgColor: Constants.hexStringToColor("#333333"),
                    fontSize: 28,
                    labels: PrinterBarcodeEunm.getValues()
                        .values
                        .map((e) => e.name)
                        .toList(),
                    onToggle: (index) {
                      var map = PrinterBarcodeEunm.getValues();
                      var barcodeFlag = map[index].value;
                      this._printerBloc.add(PrinterParameter(
                          printBarcodeFlag: Convert.toInt(barcodeFlag)));
                    },
                  ),
                ),
                Space(
                  width: Constants.getAdapterWidth(15),
                ),
                Expanded(
                  child: ToggleSwitch(
                    minWidth: Constants.getAdapterWidth(660 / 4),
                    minHeight: Constants.getAdapterHeight(70),
                    initialLabelIndex: PrinterQRCodeEunm.getIndex(
                        "${state.currentPrinter.printQrcodeFlag}"),
                    activeBgColor: Constants.hexStringToColor("#7A73C7"),
                    activeFgColor: Constants.hexStringToColor("#FFFFFF"),
                    inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
                    inactiveFgColor: Constants.hexStringToColor("#333333"),
                    fontSize: 27,
                    labels: PrinterQRCodeEunm.getValues()
                        .values
                        .map((e) => e.name)
                        .toList(),
                    onToggle: (index) {
                      var map = PrinterQRCodeEunm.getValues();
                      var qrcodeFlag = map[index].value;
                      this._printerBloc.add(PrinterParameter(
                          printQrcodeFlag: Convert.toInt(qrcodeFlag)));
                    },
                  ),
                ),
              ],
            ),
          ),
          Space(height: Constants.getAdapterHeight(20)),
          ToggleSwitch(
            minWidth: Constants.getAdapterWidth(690 / 7),
            minHeight: Constants.getAdapterHeight(70),
            initialLabelIndex: PrinterHeaderLineEunm.getIndex(
                "${state.currentPrinter.headerLines}"),
            activeBgColor: Constants.hexStringToColor("#7A73C7"),
            activeFgColor: Constants.hexStringToColor("#FFFFFF"),
            inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
            inactiveFgColor: Constants.hexStringToColor("#333333"),
            fontSize: 28,
            labels: PrinterHeaderLineEunm.getValues()
                .values
                .map((e) => e.name)
                .toList(),
            onToggle: (index) {
              var map = PrinterHeaderLineEunm.getValues();
              var headerLines = map[index].value;
              this._printerBloc.add(
                  PrinterParameter(headerLines: Convert.toInt(headerLines)));
            },
          ),
          Space(height: Constants.getAdapterHeight(20)),
          ToggleSwitch(
            minWidth: Constants.getAdapterWidth(690 / 7),
            minHeight: Constants.getAdapterHeight(70),
            initialLabelIndex: PrinterFooterLineEunm.getIndex(
                "${state.currentPrinter.footerLines}"),
            activeBgColor: Constants.hexStringToColor("#7A73C7"),
            activeFgColor: Constants.hexStringToColor("#FFFFFF"),
            inactiveBgColor: Constants.hexStringToColor("#F1F0F0"),
            inactiveFgColor: Constants.hexStringToColor("#333333"),
            fontSize: 28,
            labels: PrinterFooterLineEunm.getValues()
                .values
                .map((e) => e.name)
                .toList(),
            onToggle: (index) {
              var map = PrinterFooterLineEunm.getValues();
              var footerLines = map[index].value;
              this._printerBloc.add(
                  PrinterParameter(footerLines: Convert.toInt(footerLines)));
            },
          ),
          Space(height: Constants.getAdapterHeight(20)),
          Expanded(
            child: Container(
              child: ListView(
                //shrinkWrap: true,
                children: <Widget>[
                  Padding(
                    padding: Constants.paddingAll(0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        //行数据
                        CheckboxGroup(
                          labels: <String>[
                            "结账单",
                            "交班单",
                            "寄存单",
                          ],
                          checked: state.tickets,
                          labelStyle: TextStyles.getTextStyle(
                              fontSize: 28,
                              color: Constants.hexStringToColor("#444444")),
                          padding: Constants.paddingOnly(left: 0),
                          margin: Constants.paddingOnly(left: 0),
                          activeColor: Constants.hexStringToColor("#7A73C7"),
                          orientation: GroupedButtonsOrientation.HORIZONTAL,
                          onSelected: (List<String> selected) {},
                          onChange: (isChecked, label, index) {
                            if (isChecked) {
                              state.tickets.add(label);
                            } else {
                              state.tickets.remove(label);
                            }
                            //选择事件
                            this
                                ._printerBloc
                                .add(PrinterParameter(tickets: state.tickets));
                          },
                          itemBuilder: (Checkbox checkbox, Text text, int i) {
                            return Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                //mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  checkbox,
                                  text,
                                ],
                              ),
                            );
                          },
                        ),
                        Space(
                          height: Constants.getAdapterHeight(0),
                        ),

                        //行数据
                        CheckboxGroup(
                          labels: <String>[
                            "营业日报",
                            "会员充值",
                            "会员退卡",
                          ],
                          checked: state.tickets,
                          labelStyle: TextStyles.getTextStyle(
                              fontSize: 28,
                              color: Constants.hexStringToColor("#444444")),
                          padding: Constants.paddingAll(0),
                          margin: Constants.paddingAll(0),
                          activeColor: Constants.hexStringToColor("#7A73C7"),
                          orientation: GroupedButtonsOrientation.HORIZONTAL,
                          onChange: (isChecked, label, index) {
                            if (isChecked) {
                              state.tickets.add(label);
                            } else {
                              state.tickets.remove(label);
                            }
                            //选择事件
                            this
                                ._printerBloc
                                .add(PrinterParameter(tickets: state.tickets));
                          },
                          itemBuilder: (Checkbox checkbox, Text text, int i) {
                            return Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                //mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  checkbox,
                                  text,
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          this._buildFooter(state),
        ],
      ),
    );
  }

  ///构建底部工具栏
  Widget _buildFooter(PrinterState state) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(0, 8, 0, 8),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.0)),
      ),
      child: Row(
        children: <Widget>[
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(120),
              height: Constants.getAdapterHeight(60),
              alignment: Alignment.center,
              child: Text("打印测试",
                  style: TextStyles.getTextStyle(
                      fontSize: 28, color: Color(0xFF333333))),
            ),
            color: Color(0xFFD0D0D0),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () async {
              var printResult =
                  await PrinterHelper.printTest(state.currentPrinter);

              print(">>>>>>>>>>${printResult.msg}");
            },
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  child: Container(
                    width: Constants.getAdapterWidth(160),
                    height: Constants.getAdapterHeight(60),
                    alignment: Alignment.center,
                    child: Text("取消",
                        style: TextStyles.getTextStyle(
                            fontSize: 28, color: Color(0xFF333333))),
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
                    width: Constants.getAdapterWidth(160),
                    height: Constants.getAdapterHeight(60),
                    alignment: Alignment.center,
                    child: Text("保存",
                        style: TextStyles.getTextStyle(
                            fontSize: 28, color: Color(0xFFFFFFFF))),
                  ),
                  color: Color(0xFF7A73C7),
                  disabledColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    side: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  onPressed: () {
                    print("保存校验动作#######################");
                    this
                        ._printerBloc
                        .add(SavePrinter(state.currentPrinter, state.tickets));

                    if (widget.onClose != null) {
                      widget.onClose();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //输入框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  ///构建参数输入框
  Widget _buildInputBox(PrinterState state) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(70),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: false,
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: "${state.currentPrinter.ipAddress}",
            selection: TextSelection.fromPosition(TextPosition(
                affinity: TextAffinity.downstream,
                offset: '${state.currentPrinter.ipAddress}'.length)),
          ),
        ),
        textAlign: TextAlign.start,
        style: TextStyles.getTextStyle(fontSize: 28),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "请输入参数或者点击搜索",
          hintStyle: TextStyles.getTextStyle(
              color: Constants.hexStringToColor("#999999"), fontSize: 28),
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
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: false, //长按复制 剪切
        autocorrect: false,
        onChanged: (value) {
          this._printerBloc.add(PrinterParameter(ipAddress: value));
        },
      ),
    );
  }

  ///构建内置打印机选项
  Widget _buildEmbedPrinter(int index, String printerName, bool selected) {
    var backgroundColor = selected
        ? Constants.hexStringToColor("#F8F7FF")
        : Constants.hexStringToColor("#FFFFFF");
    var borderColor = selected
        ? Constants.hexStringToColor("#7A73C7")
        : Constants.hexStringToColor("#D0D0D0");
    var titleColor = selected
        ? Constants.hexStringToColor("#7A73C7")
        : Constants.hexStringToColor("#333333");

    return InkWell(
      onTap: () {
        this._printerBloc.add(PrinterParameter(driverName: printerName));
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Text(
          "$printerName",
          style: TextStyles.getTextStyle(fontSize: 28, color: titleColor),
        ),
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader(PrinterState state) {
    return Container(
      height: Constants.getAdapterHeight(90.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(
            bottom: BorderSide(
                width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: Constants.paddingOnly(left: 15),
              alignment: Alignment.centerLeft,
              child: Text(
                  "${StringUtils.isBlank(state.currentPrinter.id) ? '添加' : '编辑'}打印机",
                  style: TextStyles.getTextStyle(
                      color: Constants.hexStringToColor("#333333"),
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
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
              child: Icon(CommunityMaterialIcons.close_box,
                  color: Constants.hexStringToColor("#7A73C7"),
                  size: Constants.getAdapterWidth(56)),
            ),
          ),
        ],
      ),
    );
  }

  // ///构建顶部标题栏
  // Widget _buildHeader(PrinterState state) {
  //   return Container(
  //     height: Constants.getAdapterHeight(90.0),
  //     decoration: BoxDecoration(
  //       color: Constants.hexStringToColor("#7A73C7"),
  //       border: Border.all(width: 0, color: Constants.hexStringToColor("#7A73C7")),
  //     ),
  //     child: Row(
  //       children: <Widget>[
  //         Expanded(
  //           child: Container(
  //             padding: Constants.paddingOnly(left: 15),
  //             alignment: Alignment.centerLeft,
  //             child: Text("${StringUtils.isBlank(state.currentPrinter.id) ? '添加' : '编辑'}打印机", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 38)),
  //           ),
  //         ),
  //         InkWell(
  //           onTap: () {
  //             if (widget.onClose != null) {
  //               widget.onClose();
  //             }
  //           },
  //           child: Padding(
  //             padding: Constants.paddingSymmetric(horizontal: 15),
  //             child: Icon(CommunityMaterialIcons.close_box, color: Constants.hexStringToColor("#FFFFFF"), size: Constants.getAdapterWidth(56)),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

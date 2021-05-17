import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/assistant_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_store_table.dart';
import 'package:estore_app/enums/order_source_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/order/assistant_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

///开台界面
class AssistantOpenPage extends StatefulWidget {
  final StoreTable table;
  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  AssistantOpenPage(this.table, {this.onAccept, this.onClose});

  @override
  _AssistantOpenPageState createState() => _AssistantOpenPageState();
}

class _AssistantOpenPageState extends State<AssistantOpenPage> with SingleTickerProviderStateMixin {
  //就餐人数输入框
  final FocusNode _focusPeople = FocusNode();
  final TextEditingController _controllerPeople = TextEditingController();

  //备注信息输入框
  final FocusNode _focusMemo = FocusNode();
  final TextEditingController _controllerMemo = TextEditingController();

  AssistantBloc _assistantBloc;

  @override
  void initState() {
    super.initState();

    _assistantBloc = BlocProvider.of<AssistantBloc>(context);
    assert(this._assistantBloc != null);

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
    return KeyboardDismissOnTap(
      child: Material(
        color: Colors.transparent,
        child: BlocBuilder<AssistantBloc, AssistantState>(
          cubit: this._assistantBloc,
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
  Widget _buildContent(AssistantState state) {
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
  Widget _buildPeopleTextField(AssistantState state) {
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
  Widget _buildMemoTextField(AssistantState state) {
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
  Widget _buildFooter(AssistantState state) {
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
              Map<String, dynamic> map = new Map<String, dynamic>();
              map["tableId"] = widget.table.id;
              map["people"] = inputPeople;
              map["workerNo"] = Global.instance.worker.no;
              map["workerName"] = Global.instance.worker.name;
              map["memo"] = inputMemo;
              map["orderSource"] = OrderSource.AppTouch.value;
              var openTableResult = await AssistantUtils.instance.openTable(map);
              if (openTableResult.item1) {
                var orderObject = openTableResult.item3;

                if (widget.onAccept != null) {
                  var args = AssistantOpenArgs(orderObject: orderObject, tableId: widget.table.id, toDish: true);
                  widget.onAccept(args);
                }
              } else {
                ToastUtils.show(openTableResult.item2);
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
              Map<String, dynamic> map = new Map<String, dynamic>();
              map["tableId"] = widget.table.id;
              map["people"] = inputPeople;
              map["workerNo"] = Global.instance.worker.no;
              map["workerName"] = Global.instance.worker.name;
              map["memo"] = inputMemo;
              map["orderSource"] = OrderSource.CashRegister.value;
              var openTableResult = await AssistantUtils.instance.openTable(map);
              if (openTableResult.item1) {
                var orderObject = openTableResult.item3;
                if (widget.onAccept != null) {
                  var args = AssistantOpenArgs(orderObject: orderObject, tableId: widget.table.id, toDish: false);
                  widget.onAccept(args);
                }
              } else {
                ToastUtils.show(openTableResult.item2);
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

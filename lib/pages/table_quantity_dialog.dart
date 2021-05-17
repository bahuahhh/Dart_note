import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/table_cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/keyboards/keyboard.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';

class TableQuantityDialog extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double step;
  final int fractionDigits;

  final OrderItem currentOrderItem;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  TableQuantityDialog(this.currentOrderItem, {this.minValue, this.maxValue, this.step, this.fractionDigits, this.onAccept, this.onClose});

  @override
  _TableQuantityDialogState createState() => _TableQuantityDialogState();
}

class _TableQuantityDialogState extends State<TableQuantityDialog> with SingleTickerProviderStateMixin {
  //输入
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  //键盘功能的业务逻辑处理
  KeyboardBloc _keyboardBloc;
  //业务逻辑处理
  TableCashierBloc _tableCashierBloc;

  @override
  void initState() {
    super.initState();

    _keyboardBloc = BlocProvider.of<KeyboardBloc>(context);
    assert(this._keyboardBloc != null);

    _tableCashierBloc = BlocProvider.of<TableCashierBloc>(context);
    assert(this._tableCashierBloc != null);

    //1.注册键盘
    NumberKeyboard.register(buttonWidth: 130, buttonHeight: 120, buttonSpace: 10);
    //2.初始化键盘
    KeyboardManager.init(context, this._keyboardBloc);

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      ///文本框赋值
      double quantity = widget.currentOrderItem?.quantity;
      final text = OrderUtils.instance.removeDecimalZeroFormat(quantity);
      _controller.value = _controller.value.copyWith(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _focus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TableCashierBloc, TableCashierState>(
      cubit: this._tableCashierBloc,
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
                padding: Constants.paddingAll(5),
                decoration: ShapeDecoration(
                  color: Constants.hexStringToColor("#FFFFFF"),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6.0))),
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
  Widget _buildContent(TableCashierState state) {
    return Container(
      padding: Constants.paddingLTRB(25, 20, 25, 20),
      height: Constants.getAdapterHeight(700),
      width: double.infinity,
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: Constants.getAdapterWidth(600),
            height: Constants.getAdapterHeight(100),
            padding: Constants.paddingLTRB(0, 10, 0, 10),
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
                    child: this._buildTextField(),
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
          Space(height: Constants.getAdapterHeight(20)),
          Expanded(
            child: Container(
              child: BlocBuilder<KeyboardBloc, KeyboardState>(
                  cubit: this._keyboardBloc,
                  buildWhen: (previousState, currentState) {
                    return true;
                  },
                  builder: (context, state) {
                    return state.keyboard == null ? Container() : state.keyboard.builder(context, state.controller);
                  }),
            ),
          ),
        ],
      ),
    );
  }

  ///构建商品数量输入框
  Widget _buildTextField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(96),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: true,
        textAlign: TextAlign.start,
        controller: this._controller,
        focusNode: this._focus,
        style: TextStyles.getTextStyle(fontSize: 32),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "请输入售卖数量",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),

        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
        keyboardType: NumberKeyboard.inputType,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: true, //长按复制 剪切
        autocorrect: false,
        onFieldSubmitted: (inputValue) async {
          if (StringUtils.isBlank(inputValue)) {
            FocusScope.of(context).requestFocus(_focus);
            ToastUtils.show("请输入数量...", position: ToastPosition.center);
            return;
          }

          double inputQuantity = Convert.toDouble(inputValue);
          if (inputQuantity <= 0) {
            FocusScope.of(context).requestFocus(_focus);
            ToastUtils.show("售卖数量不能为0", position: ToastPosition.center);
            return;
          }

          FocusScope.of(context).requestFocus(_focus);

          if (widget.onAccept != null) {
            var args = TableQuantityArgs(widget.currentOrderItem, inputQuantity);
            widget.onAccept(args);
          }
        },
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader(TableCashierState state) {
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
              child: Text("修改数量", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32, fontWeight: FontWeight.bold)),
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

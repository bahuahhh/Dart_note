import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/keyboards/keyboard.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';

class QuantityPage extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double step;
  final int fractionDigits;

  final OrderItem currentOrderItem;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  QuantityPage(this.currentOrderItem, {this.minValue, this.maxValue, this.step, this.fractionDigits, this.onAccept, this.onClose});

  @override
  _QuantityPageState createState() => _QuantityPageState();
}

class _QuantityPageState extends State<QuantityPage> with SingleTickerProviderStateMixin {
  //输入
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  //键盘功能的业务逻辑处理
  KeyboardBloc _keyboardBloc;
  //业务逻辑处理
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    _keyboardBloc = BlocProvider.of<KeyboardBloc>(context);
    assert(this._keyboardBloc != null);

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);

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
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        padding: Constants.paddingAll(0),
        child: Column(
          children: <Widget>[
            ///顶部标题
            _buildHeader(),

            ///中部操作区
            _buildContent(),
          ],
        ),
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent() {
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
                      // //重新试算找零
                      // if (widget.payMode.no == Constants.PAYMODE_CODE_CASH) {
                      //   this._cashierBloc.add(TryChangeAmount(0));
                      // }
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

  ///构建商品搜索框
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
          hintText: "请输入手机号或会员码",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),

        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(24)],
        keyboardType: NumberKeyboard.inputType,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: true, //长按复制 剪切
        autocorrect: false,
        onFieldSubmitted: (inputValue) async {
          if (StringUtils.isBlank(inputValue)) {
            ToastUtils.show("请输入数量...", position: ToastPosition.center);
            FocusScope.of(context).requestFocus(_focus);
          } else {
            if (widget.onAccept != null) {
              var args = QuantityArgs(widget.currentOrderItem, Convert.toDouble(inputValue));
              widget.onAccept(args);
            }
          }
        },
      ),
    );
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
              child: Text("修改数量", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 32)),
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

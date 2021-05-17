import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/assistant_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_pay_mode.dart';
import 'package:estore_app/enums/order_payment_status_type.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/keyboards/keyboard.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_pay.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///现金支付方式
class AssistantCashPayDialog extends StatefulWidget {
  final String title;
  final OrderObject orderObject;
  final PayMode payMode;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  AssistantCashPayDialog(this.title, this.orderObject, this.payMode, {this.onAccept, this.onClose});

  @override
  _AssistantCashPayDialogState createState() => _AssistantCashPayDialogState();
}

class _AssistantCashPayDialogState extends State<AssistantCashPayDialog> with SingleTickerProviderStateMixin {
  //输入框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //键盘功能的业务逻辑处理
  KeyboardBloc _keyboardBloc;

  //业务逻辑处理
  AssistantBloc _assistantBloc;

  //本次输入金额
  double currentInputAmount = 0;

  @override
  void initState() {
    super.initState();

    _keyboardBloc = BlocProvider.of<KeyboardBloc>(context);
    assert(this._keyboardBloc != null);

    _assistantBloc = BlocProvider.of<AssistantBloc>(context);
    assert(this._assistantBloc != null);

    //1.注册键盘
    NumberKeyboard.register(buttonWidth: 130, buttonHeight: 120, buttonSpace: 10);
    //2.初始化键盘
    KeyboardManager.init(context, this._keyboardBloc);

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      ///文本框赋值
      double unreceivableAmount = widget.orderObject?.unreceivableAmount;
      final text = unreceivableAmount.toString();
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
    return BlocBuilder<AssistantBloc, AssistantState>(
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
  Widget _buildContent(AssistantState state) {
    ///已经录入的金额
    double totalInputAmount = 0;
    state.orderObject.pays.forEach((item) {
      totalInputAmount += item.inputAmount;
    });
    var receivableAmount = state.orderObject.paidAmount.abs();
    double tryChangeAmount = totalInputAmount + currentInputAmount - receivableAmount;
    double changeAmount = OrderUtils.instance.toRound(tryChangeAmount > 0 ? tryChangeAmount : 0);

    return Container(
      padding: Constants.paddingLTRB(25, 5, 25, 20),
      height: Constants.getAdapterHeight(700),
      width: double.infinity,
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: Constants.getAdapterWidth(600),
            height: Constants.getAdapterHeight(70),
            padding: Constants.paddingLTRB(0, 5, 0, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(text: "应付:¥", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                    TextSpan(text: "${state.orderObject.unreceivableAmount}", style: TextStyles.getTextStyle(fontSize: 46, color: Constants.hexStringToColor("#333333"))),
                  ]),
                ),
                RichText(
                  text: TextSpan(text: "找零:¥", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                    TextSpan(text: "$changeAmount", style: TextStyles.getTextStyle(fontSize: 46, color: Constants.hexStringToColor("#333333"))),
                  ]),
                ),
              ],
            ),
          ),
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
                    child: this._buildTextField(state),
                  ),
                  InkWell(
                    onTap: () {
                      //清空内容
                      _controller.clear();
                      setState(() {});
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
          Space(height: Constants.getAdapterHeight(5)),
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
  Widget _buildTextField(AssistantState state) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(96),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: true,
        textAlign: TextAlign.start,
        focusNode: this._focus,
        controller: this._controller,
        style: TextStyles.getTextStyle(fontSize: 32),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "请输入消费金额",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),

        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[0-9\.]')), LengthLimitingTextInputFormatter(24)],
        keyboardType: NumberKeyboard.inputType,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: true, //长按复制 剪切
        autocorrect: false,
        onChanged: (inputValue) {
          currentInputAmount = Convert.toDouble(StringUtils.isNotBlank(inputValue) ? inputValue : "0");
          setState(() {});
        },
        onFieldSubmitted: (inputValue) async {
          if (StringUtils.isBlank(inputValue)) {
            ToastUtils.show("请输入消费金额");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          var orderObject = widget.orderObject;
          var payMode = widget.payMode;

          if (orderObject.orderStatus != OrderStatus.WaitForPayment) {
            ToastUtils.show("订单状态非法，不能进行付款");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          ///已经录入的金额
          double totalInputAmount = 0;
          state.orderObject.pays.forEach((item) {
            totalInputAmount += item.inputAmount;
          });
          //找零金额计算
          var receivableAmount = state.orderObject.paidAmount.abs();
          double tryChangeAmount = totalInputAmount + currentInputAmount - receivableAmount;
          double changeAmount = OrderUtils.instance.toRound(tryChangeAmount > 0 ? tryChangeAmount : 0);

          if (changeAmount > 100) {
            ToastUtils.show("找零金额不能超过100元");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          FocusScope.of(context).requestFocus(_focus);

          ///构建支付方式
          var orderPay = OrderPay.fromPayMode(orderObject, payMode);
          orderPay.orderId = orderObject.id;
          orderPay.tradeNo = orderObject.tradeNo;
          double inputAmount = Convert.toDouble(StringUtils.isNotBlank(_controller.text) ? _controller.text : 0);
          orderPay.inputAmount = inputAmount;
          orderPay.amount = changeAmount > 0 ? orderObject.unreceivableAmount : orderPay.inputAmount;
          orderPay.paidAmount = changeAmount > 0 ? orderObject.unreceivableAmount : orderPay.inputAmount;
          orderPay.overAmount = 0;
          orderPay.changeAmount = changeAmount;
          orderPay.platformDiscount = 0;
          orderPay.platformPaid = 0;
          orderPay.payNo = "";
          orderPay.status = OrderPaymentStatus.Paid;
          if (orderPay.no == Constants.PAYMODE_CODE_MALING) {
            orderPay.statusDesc = Constants.PAYMODE_MALING_HAND;
          }
          orderPay.payTime = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");

          if (widget.onAccept != null) {
            var args = TableOrderPayArgs(orderPay);
            widget.onAccept(args);
          }
        },
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader(AssistantState state) {
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
              child: Text("${widget.title}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32, fontWeight: FontWeight.bold)),
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

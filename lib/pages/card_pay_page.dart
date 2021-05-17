import 'package:community_material_icon/community_material_icon.dart';
import 'package:encrypt/encrypt.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_pay_mode.dart';
import 'package:estore_app/enums/order_payment_status_type.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/pay_channel_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/keyboards/keyboard.dart';
import 'package:estore_app/member/member_card_pay_entity.dart';
import 'package:estore_app/member/member_utils.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_pay.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/utils/common_plugin.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional.dart';

///会员支付方式
class CardPayPage extends StatefulWidget {
  final String title;
  final OrderObject orderObject;
  final PayMode payMode;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  CardPayPage(this.title, this.orderObject, this.payMode, {this.onAccept, this.onClose});

  @override
  _CardPayPageState createState() => _CardPayPageState();
}

class _CardPayPageState extends State<CardPayPage> with SingleTickerProviderStateMixin {
  //输入框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

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
      ///文本框赋值,卡余额不足情况下，默认采用卡余额赋值，否则按照未收金额赋值
      double cardTotalAmount = widget.orderObject.member.defaultCard.totalAmount;
      double unreceivableAmount = widget.orderObject?.unreceivableAmount;
      final text = cardTotalAmount >= unreceivableAmount ? "$unreceivableAmount" : "$cardTotalAmount";
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
    return BlocBuilder<CashierBloc, CashierState>(
      cubit: this._cashierBloc,
      buildWhen: (previousState, currentState) {
        return true;
      },
      builder: (context, cashierState) {
        return Material(
          child: Container(
            padding: Constants.paddingAll(0),
            child: Column(
              children: <Widget>[
                ///顶部标题
                _buildHeader(cashierState),

                ///中部操作区
                _buildContent(cashierState),
              ],
            ),
          ),
        );
      },
    );
  }

  ///构建内容区域
  Widget _buildContent(CashierState cashierState) {
    return Container(
      padding: Constants.paddingLTRB(25, 5, 25, 20),
      height: Constants.getAdapterHeight(700),
      width: double.infinity,
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: Constants.getAdapterWidth(600),
            height: Constants.getAdapterHeight(70),
            padding: Constants.paddingLTRB(0, 5, 0, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //卡号显示逻辑：1-卡面号，2-手机号，3、卡号
                Conditional.single(
                  context: context,
                  conditionBuilder: (BuildContext context) => StringUtils.isNotBlank(cashierState.orderObject.member.defaultCard.cardFaceNo),
                  widgetBuilder: (BuildContext context) => RichText(
                    text: TextSpan(text: "卡号:", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                      TextSpan(text: "${cashierState.orderObject.member.defaultCard.cardFaceNo}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333"))),
                    ]),
                  ),
                  fallbackBuilder: (BuildContext context) => Conditional.single(
                    context: context,
                    conditionBuilder: (BuildContext context) => StringUtils.isNotBlank(cashierState.orderObject.member.defaultCard.mobile),
                    widgetBuilder: (BuildContext context) => RichText(
                      text: TextSpan(text: "卡号:", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                        TextSpan(text: "${cashierState.orderObject.member.defaultCard.mobile}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333"))),
                      ]),
                    ),
                    fallbackBuilder: (BuildContext context) => RichText(
                      text: TextSpan(text: "卡号:", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                        TextSpan(text: "${cashierState.orderObject.member.defaultCard.cardNo}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333"))),
                      ]),
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(text: "卡余额:¥", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                    TextSpan(text: "${cashierState.orderObject.member.defaultCard.totalAmount}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333"))),
                  ]),
                ),
              ],
            ),
          ),
          Container(
            width: Constants.getAdapterWidth(600),
            height: Constants.getAdapterHeight(70),
            padding: Constants.paddingLTRB(0, 5, 0, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(text: "应付:¥", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                    TextSpan(text: "${cashierState.orderObject.unreceivableAmount}", style: TextStyles.getTextStyle(fontSize: 46, color: Constants.hexStringToColor("#333333"))),
                  ]),
                ),
                // RichText(
                //   text: TextSpan(text: "卡内余额:¥", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                //     TextSpan(text: "${cashierState.orderObject.member.defaultCard.totalAmount}", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333"))),
                //   ]),
                // ),
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
                    child: this._buildTextField(cashierState),
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
  Widget _buildTextField(CashierState cashierState) {
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
        onFieldSubmitted: (inputValue) async {
          //录入的金额
          var inputAmount = Convert.toDouble(StringUtils.isNotBlank(inputValue) ? inputValue : "0");
          var orderObject = cashierState.orderObject;
          var payMode = widget.payMode;

          if (StringUtils.isBlank(inputValue)) {
            ToastUtils.show("请输入消费金额");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          if (inputAmount <= 0) {
            ToastUtils.show("消费金额不能为0");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          if (orderObject.orderStatus != OrderStatus.WaitForPayment) {
            ToastUtils.show("订单状态非法，不能进行付款");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          //卡总余额
          var cardTotalAmount = orderObject.member.defaultCard.totalAmount;
          if (inputAmount > cardTotalAmount) {
            ToastUtils.show("消费金额不能超过卡余额");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          //应付金额
          double unreceivableAmount = cashierState.orderObject.unreceivableAmount;
          if (inputAmount > unreceivableAmount) {
            ToastUtils.show("消费金额不能超过应付金额");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          FocusScope.of(context).requestFocus(_focus);

          String pwd = "";

          print("@@@@@@>>>>是否免密:${orderObject.member.defaultCard.isNoPwd}");
          if (orderObject.member.defaultCard.isNoPwd == 1) {
            //免密支付，金额加密
            var publicKey = await rootBundle.loadString("assets/card_public_key.pem");
            final parser = RSAKeyParser();
            final encrypter = Encrypter(RSA(publicKey: parser.parse(publicKey)));
            final encrypted = encrypter.encrypt("${(inputAmount * 100).toInt()}"); //转为分
            pwd = "${encrypted.base64}";
          } else {
            pwd = await CommonPlugin.transferEncryptString("123456");
          }
          //只校验
          MemberCardPayEntity entity = new MemberCardPayEntity();
          entity.tradeNo = OrderUtils.instance.generatePayNo(orderObject.tradeNo);
          entity.memberId = orderObject.member.id;
          entity.memberName = orderObject.member.name;
          entity.mobile = orderObject.member.mobile;
          entity.cardNo = orderObject.member.defaultCard.cardNo;
          entity.cardFaceNo = orderObject.member.defaultCard.cardFaceNo;
          entity.isNoPwd = orderObject.member.defaultCard.isNoPwd;
          entity.passwd = pwd;
          entity.totalAmount = (inputAmount * 100).toInt(); //转为分
          entity.pointValue = 0;

          var res = await MemberUtils.instance.httpMemberConsumeCheck(entity);
          if (res.item1) {
            ///构建支付方式
            var orderPay = OrderPay.fromPayMode(orderObject, payMode);
            orderPay.orderId = orderObject.id;
            orderPay.tradeNo = orderObject.tradeNo;
            orderPay.inputAmount = inputAmount;
            orderPay.amount = inputAmount;
            orderPay.paidAmount = inputAmount;
            orderPay.overAmount = 0;
            orderPay.changeAmount = 0;
            orderPay.platformDiscount = 0;
            orderPay.platformPaid = inputAmount;
            orderPay.payNo = orderObject.tradeNo;
            orderPay.status = OrderPaymentStatus.NonPayment; //未付款
            orderPay.payChannel = PayChannelEnum.None;
            orderPay.accountName = orderObject.member.name;
            orderPay.memberId = orderObject.member.id;
            orderPay.cardNo = orderObject.member.defaultCard.cardNo;
            orderPay.cardFaceNo = orderObject.member.defaultCard.cardFaceNo;
            orderPay.memberMobileNo = orderObject.member.mobile;
            orderPay.cardChangeAmount = inputAmount;
            orderPay.cardChangePoint = 0;
            orderPay.password = pwd;
            orderPay.useConfirmed = orderObject.member.defaultCard.isNoPwd;
            orderPay.payTime = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
            orderPay.memo = "移动POS消费";
            if (widget.onAccept != null) {
              var args = OrderPayArgs(orderPay);
              widget.onAccept(args);
            }
          } else {
            ToastUtils.show(res.item2);
          }
        },
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader(CashierState cashierState) {
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
              child: Text("${widget.title}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 38)),
            ),
          ),
          InkWell(
            onTap: () {
              this._cashierBloc.add(TryChangeAmount(0));

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

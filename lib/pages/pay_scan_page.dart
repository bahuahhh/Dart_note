import 'dart:async';

import 'package:barcode_scan/gen/protos/protos.pbenum.dart';
import 'package:barcode_scan/platform_wrapper.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/enums/online_pay_bus_type_enum.dart';
import 'package:estore_app/enums/pay_parameter_sign_enum.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/keyboards/keyboard.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/payment/leshua_pay_utils.dart';
import 'package:estore_app/payment/saobei_pay_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PayScanPage extends StatefulWidget {
  final String title;
  final OrderObject orderObject;

  final OnPaymentCallback onPayment;
  final OnCloseCallback onClose;

  PayScanPage(this.title, this.orderObject, {this.onPayment, this.onClose});

  @override
  _PayScanPageState createState() => _PayScanPageState();
}

class _PayScanPageState extends State<PayScanPage> with SingleTickerProviderStateMixin {
  //输入框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //键盘功能的业务逻辑处理
  KeyboardBloc _keyboardBloc;
  //业务逻辑处理
  CashierBloc _cashierBloc;

  //支付结果查询的时间片
  Timer _timer;

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

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
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
                  text: TextSpan(text: "应付:", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#333333")), children: <TextSpan>[
                    TextSpan(text: "¥${widget.orderObject.unreceivableAmount}", style: TextStyles.getTextStyle(fontSize: 46, color: Constants.hexStringToColor("#333333"))),
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
                    child: this._buildTextField(),
                  ),
                  InkWell(
                    onTap: () async {
                      var scanResult = await BarcodeScanner.scan(options: scanOptions);
                      if (scanResult.type == ResultType.Barcode) {
                        //扫码成功
                        var format = scanResult.format;
                        var payCode = scanResult.rawContent;
                        FLogger.info("识别到${format.name}码,内容:$payCode");

                        _controller.value = _controller.value.copyWith(
                          text: payCode,
                          selection: TextSelection(baseOffset: 0, extentOffset: payCode.length),
                          composing: TextRange.empty,
                        );
                        FocusScope.of(context).requestFocus(_focus);

                        _scanPay(payCode);
                      } else if (scanResult.type == ResultType.Cancelled) {
                        FLogger.warn("收银员放弃扫码");
                      } else {
                        FLogger.warn("无法识别的条码,收银员扫码发生未知错误<${scanResult.formatNote}>");
                        ToastUtils.show("无法识别的条码");
                      }
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

  void _scanPay(String payCode) async {
    try {
      //获取当前支付方式
      var currentPayMode = await OrderUtils.instance.getPayModeByPayCode(payCode);
      //支付参数
      var payParameterResult = await OrderUtils.instance.getPayParameterByPayMode(currentPayMode, OnLinePayBusTypeEnum.Sale);
      //获取支付参数失败
      if (!payParameterResult.item1) {
        ToastUtils.show(payParameterResult.item2);
        return;
      }

      var payParameter = payParameterResult.item3;
      var paySign = PayParameterSignEnum.fromName(payParameter.sign);
      switch (paySign) {
        case PayParameterSignEnum.SubWxpay:
          {
            ToastUtils.show("暂不支持微信子商户");
          }
          break;
        case PayParameterSignEnum.SubAlipay:
          {
            ToastUtils.show("暂不支持支付宝子商户");
          }
          break;
        case PayParameterSignEnum.LeshuaPay:
          {
            FLogger.info("适配到乐刷支付通道");
            var payResult = await LeshuaPayUtils.paymentResult(currentPayMode, payParameter, payCode, widget.orderObject.tradeNo, widget.orderObject.unreceivableAmount);
            //支付不成功
            if (!payResult.item1) {
              ToastUtils.show(payResult.item2);
            } else {
              //查询状态
              if (payResult.item3) {
                //
                var payNo = payResult.item4.payNo;
                _timer = Timer.periodic(const Duration(milliseconds: 3000), (timer) async {
                  var queryResult = await LeshuaPayUtils.queryPayment(currentPayMode, payParameter, widget.orderObject.tradeNo, payNo);

                  if (!queryResult.item1) {
                    ToastUtils.show(queryResult.item2);
                  } else {
                    ToastUtils.show(queryResult.item2);

                    timer.cancel();
                    timer = null;

                    if (widget.onPayment != null) {
                      widget.onPayment(widget.orderObject, payResult.item4);
                    }
                  }
                });
              } else {
                //支付成功
                ToastUtils.show(payResult.item2);

                if (widget.onPayment != null) {
                  widget.onPayment(widget.orderObject, payResult.item4);
                }
              }
            }
          }
          break;
        case PayParameterSignEnum.SaobeiPay:
          {
            var payResult = await SaobeiPayUtils.paymentResult(currentPayMode, payParameter, payCode, widget.orderObject.tradeNo, widget.orderObject.receivableAmount);
            //支付不成功
            if (!payResult.item1) {
              ToastUtils.show(payResult.item2);
            } else {
              //查询状态
              if (payResult.item3) {
                var payNo = payResult.item4.payNo;
                String voucherNo = payResult.item4.voucherNo;
                String payTime = payResult.item4.payTime;
                _timer = Timer.periodic(const Duration(milliseconds: 3000), (timer) async {
                  var queryResult = await SaobeiPayUtils.queryPayment(currentPayMode, payParameter, widget.orderObject.tradeNo, payNo, voucherNo, payTime);

                  if (!queryResult.item1) {
                    ToastUtils.show(queryResult.item2);
                  } else {
                    ToastUtils.show(queryResult.item2);

                    timer.cancel();
                    timer = null;

                    if (widget.onPayment != null) {
                      widget.onPayment(widget.orderObject, payResult.item4);
                    }
                  }
                });
              } else {
                //支付成功
                ToastUtils.show(payResult.item2);

                if (widget.onPayment != null) {
                  widget.onPayment(widget.orderObject, payResult.item4);
                }
              }
            }
          }
          break;
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("扫码支付发生异常:" + e.toString());
    } finally {}
  }

  ///构建支付码输入框
  Widget _buildTextField() {
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
          hintText: "请提示顾客出示付款码",
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
            ToastUtils.show("请输入消费金额");
            FocusScope.of(context).requestFocus(_focus);
            return;
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
              child: Text("${widget.title}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 38)),
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

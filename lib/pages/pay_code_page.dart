import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_pay_mode.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:flutter/material.dart';

class PayCodePage extends StatefulWidget {
  final String title;
  final OrderObject orderObject;
  final PayMode payMode;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  PayCodePage(this.title, this.orderObject, this.payMode, {this.onAccept, this.onClose});

  @override
  _PayCodePageState createState() => _PayCodePageState();
}

class _PayCodePageState extends State<PayCodePage> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, //输入框抵住键盘
      backgroundColor: Color(0xFF656472),
      body: Container(
        padding: Constants.paddingAll(0),
        decoration: BoxDecoration(
          color: Constants.hexStringToColor("#656472"),
        ),
      ),
    );
  }
}

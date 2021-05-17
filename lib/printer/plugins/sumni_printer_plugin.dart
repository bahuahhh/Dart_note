import 'dart:convert';

import 'package:flutter/services.dart';

class SunmiPrinterPlugin {
  static String CHANNEL_NAME = "io.juwei.app/sunmi_printer_plugin";

  // 工厂模式
  factory SunmiPrinterPlugin() => _getInstance();
  static SunmiPrinterPlugin get instance => _getInstance();
  static SunmiPrinterPlugin _instance;

  static SunmiPrinterPlugin _getInstance() {
    if (_instance == null) {
      _instance = new SunmiPrinterPlugin._internal();
    }

    return _instance;
  }

  BasicMessageChannel _messageChannel;

  SunmiPrinterPlugin._internal() {
    // 初始化
    _messageChannel = BasicMessageChannel(CHANNEL_NAME, JSONMessageCodec());
  }

  ///初始化打印机
  Future<Map<String, dynamic>> init() async {
    Map<String, dynamic> request = {
      "action": "init",
      "args": {},
    };
    print(">>>>请求:$request");
    Map<String, dynamic> response = await _messageChannel.send(request);
    print(">>>>应答:$response");
    return response;
  }

  ///初始化打印机
  Future<Map<String, dynamic>> reinit() async {
    Map<String, dynamic> request = {
      "action": "reinit",
      "args": {},
    };
    print(">>>>请求:$request");
    Map<String, dynamic> response = await _messageChannel.send(request);
    print(">>>>应答:$response");
    return response;
  }

  ///打印
  Future<Map<String, dynamic>> printRawData(List<int> data) async {
    String encodedStr = base64Encode(data);
    Map<String, dynamic> request = {
      "action": "printRawData",
      "args": {
        "data": "$encodedStr",
      },
    };

    Map<String, dynamic> reply = await _messageChannel.send(request);

    return reply;
  }
}

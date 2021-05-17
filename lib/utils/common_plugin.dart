import 'package:flutter/services.dart';

class CommonPlugin {
  static const MethodChannel _channel = const MethodChannel("io.juwei.app/common_plugin");

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod("getPlatformVersion");
    return version;
  }

  static Future<String> transferEncryptString(String data) async {
    return await _channel.invokeMethod("getTransferEncryptString", <String, dynamic>{'data': data});
  }

  static Future<String> transferDecryptString(String data) async {
    return await _channel.invokeMethod("getTransferDecryptString", <String, dynamic>{'data': data});
  }
}

import 'dart:convert';
import 'package:estore_app/utils/converts.dart';

class MqttNofity {
  ///字段名称
  String type;

  ///消息子类型
  String subType;

  ///响应主题
  String resTopic;

  ///消息发送时间 yyyy-MM-dd HH:mm:ss
  String sendDate;

  ///发送人标识
  String senderIdentity;

  ///内容
  String data;

  MqttNofity();

  factory MqttNofity.fromJson(Map<String, dynamic> map) {
    return MqttNofity()
      ..type = Convert.toStr(map["type"], "")
      ..subType = Convert.toStr(map["subType"], "")
      ..resTopic = Convert.toStr(map["resTopic"], "")
      ..sendDate = Convert.toStr(map["sendDate"], "")
      ..senderIdentity = Convert.toStr(map["senderIdentity"], "")
      ..data = Convert.toStr(map["resTopic"], "");
  }

  Map<String, dynamic> toJson() {
    var map = {
      "type": this.type,
      "subType": this.subType,
      "resTopic": this.resTopic,
      "sendDate": this.sendDate,
      "senderIdentity": this.senderIdentity,
      "data": this.data,
    };

    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

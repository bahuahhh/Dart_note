import 'dart:convert';

import 'package:estore_app/printer/designer/print_enums.dart';
import 'package:estore_app/utils/converts.dart';

class PrintVariableValue {
  String key = "";

  DataType type = DataType.Simple;

  dynamic data;

  PrintVariableValue();

  factory PrintVariableValue.fromJson(Map<String, dynamic> map) {
    return PrintVariableValue()
      ..type = DataType.fromValue(Convert.toStr(map["type"]))
      ..key = Convert.toStr(map["key"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "key": this.key,
      "type": type.value,
      "data": this.data,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

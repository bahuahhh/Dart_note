import 'package:estore_app/utils/converts.dart';

class PrintVariableItem {
  String key;
  String value;

  PrintVariableItem() {
    this.key = "不绑定变量";
    this.value = "";
  }

  factory PrintVariableItem.fromJson(Map<String, dynamic> map) {
    return PrintVariableItem()
      ..key = Convert.toStr(map["key"])
      ..value = Convert.toStr(map["value"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "key": this.key,
      "value": this.value,
    };
    return map;
  }

  @override
  String toString() {
    return this.key;
  }
}

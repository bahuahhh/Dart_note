import 'dart:convert';

import 'print_enums.dart';

class PrintContent {
  //行打印格式
  RowFormat format = RowFormat.None;

  //打印行内容
  StringBuffer content;

  //打印的图片路径
  String bitmapFile = "";

  //对齐方式
  AlignStyle alignStyle = AlignStyle.Left;

  //字体大小
  FontStyle fontStyle = FontStyle.Normal;

  PrintContent();

  // factory PrintContent.fromJson(Map<String, dynamic> map) {
  //   return PrintVariableValue()
  //     ..type = DataType.fromValue(Convert.toStr(map["type"]))
  //     ..key = Convert.toStr(map["key"]);
  // }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

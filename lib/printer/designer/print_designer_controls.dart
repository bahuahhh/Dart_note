import 'dart:convert';

import 'package:estore_app/utils/converts.dart';

import 'print_enums.dart';

class PrintDesignerControls {
  //控件类型
  ControlType type = ControlType.None;

  //模版名称
  String text = "None";

  //布局X坐标
  int x = 0;

  //布局Y坐标
  int y = 0;

  //宽度
  int width = 0;

  //高度
  int height = 0;

  //背景颜色
  String color = "";

  //模版
  String template = "";

  PrintDesignerControls();

  factory PrintDesignerControls.fromJson(Map<String, dynamic> map) {
    return PrintDesignerControls()
      ..type = ControlType.fromValue(Convert.toStr(map["type"]))
      ..text = Convert.toStr(map["text"])
      ..x = Convert.toInt(map["x"])
      ..y = Convert.toInt(map["y"])
      ..width = Convert.toInt(map["width"])
      ..height = Convert.toInt(map["height"])
      ..color = Convert.toStr(map["color"])
      ..template = Convert.toStr(map["template"]);
  }

  factory PrintDesignerControls.clone(PrintDesignerControls obj) {
    return PrintDesignerControls()
      ..type = obj.type
      ..text = obj.text
      ..x = obj.x
      ..y = obj.y
      ..width = obj.width
      ..height = obj.height
      ..color = obj.color
      ..template = obj.template;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "type": this.type.value,
      "text": this.text,
      "x": this.x,
      "y": this.y,
      "width": this.width,
      "height": this.height,
      "color": this.color,
      "template": this.template,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

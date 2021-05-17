import 'dart:convert';

import 'package:estore_app/utils/converts.dart';

import 'print_enums.dart';
import 'print_variable_item.dart';

class R1Parameter {
  //模版变量
  R1Template template;
  //字体
  FontStyle font;
  //对齐方式
  AlignStyle align;
  //背景颜色
  String color = "";
  //填充线条
  LineStyle line;

  R1Parameter();

  factory R1Parameter.fromJson(Map<String, dynamic> map) {
    return R1Parameter()
      ..template = R1Template.fromJson(Map<String, dynamic>.from(map["template"]['item1']))
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
      ..line = LineStyle.fromValue(Convert.toStr(map["line"]))
      ..color = Convert.toStr(map["color"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "template": this.template.toJson(),
      "font": font.value,
      "align": align.value,
      "line": line.value,
      "color": color,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class R1Template {
  //绑定的数据源Key
  String dataSourceKey;

  //行的打印条件变量
  PrintVariableItem condition;

  //打印内容前缀
  String prefix;

  //打印变量1
  PrintVariableItem var1;

  //变量中缀
  String middle;

  //打印变量2
  PrintVariableItem var2;

  //变量后缀
  String suffix;

  //打印字体
  FontStyle font;

  //对齐方式
  AlignStyle align;

  //宽度百分比
  double percent;

  R1Template() {
    this.dataSourceKey = "默认数据源";
    this.prefix = "";
    this.middle = "";
    this.suffix = "";
    this.var1 = new PrintVariableItem();
    this.var2 = new PrintVariableItem();
    this.condition = new PrintVariableItem();
    this.percent = 100;
  }

  factory R1Template.fromJson(Map<String, dynamic> map) {
    return R1Template()
      ..dataSourceKey = Convert.toStr(map["data"])
      ..prefix = Convert.toStr(map["prefix"])
      ..middle = Convert.toStr(map["middle"])
      ..suffix = Convert.toStr(map["suffix"])
      ..var1 = PrintVariableItem.fromJson(Map<String, dynamic>.from(map["var1"]))
      ..var2 = PrintVariableItem.fromJson(Map<String, dynamic>.from(map["var2"]))
      ..condition = PrintVariableItem.fromJson(Map<String, dynamic>.from(map["condition"]))
      ..percent = Convert.toDouble(map["percent"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "data": this.dataSourceKey,
      "prefix": this.prefix,
      "middle": this.middle,
      "suffix": this.suffix,
      "percent": this.percent,
      "var1": this.var1.toJson(),
      "var2": this.var2.toJson(),
      "condition": this.condition.toJson(),
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

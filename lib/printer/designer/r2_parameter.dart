import 'dart:convert';

import 'package:estore_app/printer/designer/print_enums.dart';
import 'package:estore_app/printer/designer/print_variable_item.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/tuple.dart';

class R2Parameter {
  //模版变量
  Tuple2<R2Template, R2Template> template;
  //字体
  FontStyle font;
  //背景颜色
  String color = "";
  //填充线条
  LineStyle line;

  R2Parameter();

  factory R2Parameter.fromJson(Map<String, dynamic> map) {
    return R2Parameter()
      ..template = Tuple2(R2Template.fromJson(Map<String, dynamic>.from(map["template"]['item1'])), R2Template.fromJson(Map<String, dynamic>.from(map["template"]['item2'])))
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..line = LineStyle.fromValue(Convert.toStr(map["line"]))
      ..color = Convert.toStr(map["color"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "template": {"item1": this.template.item1, "item2": this.template.item2},
      "font": font.value,
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

class R2Template {
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

  R2Template() {
    this.dataSourceKey = "默认数据源";
    this.prefix = "";
    this.middle = "";
    this.suffix = "";
    this.var1 = new PrintVariableItem();
    this.var2 = new PrintVariableItem();
    this.condition = new PrintVariableItem();
    this.percent = 100;
    this.font = FontStyle.Normal;
    this.align = AlignStyle.Left;
  }

  factory R2Template.fromJson(Map<String, dynamic> map) {
    return R2Template()
      ..dataSourceKey = Convert.toStr(map["data"])
      ..prefix = Convert.toStr(map["prefix"])
      ..middle = Convert.toStr(map["middle"])
      ..suffix = Convert.toStr(map["suffix"])
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
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
      "font": this.font.value,
      "align": this.align.value,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

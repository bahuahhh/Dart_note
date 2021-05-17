import 'dart:convert';

import 'package:estore_app/utils/converts.dart';

import 'print_enums.dart';
import 'print_variable_item.dart';

class BarCodeXParameter {
  //模版变量
  BarCodeXTemplate template;
  //字体
  FontStyle font;
  //对齐方式
  AlignStyle align;

  BarCodeXParameter();

  factory BarCodeXParameter.fromJson(Map<String, dynamic> map) {
    return BarCodeXParameter()
      ..template = BarCodeXTemplate.fromJson(map["template"]['item1'])
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "template": this.template.toJson(),
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

class BarCodeXTemplate {
  //绑定的数据源Key
  String dataSourceKey;

  //行的打印条件变量
  PrintVariableItem condition;

  //打印变量1
  PrintVariableItem var1;

  //打印变量2
  PrintVariableItem var2;

  //是否显示标签
  bool showLabel;

  BarCodeXTemplate() {
    this.dataSourceKey = "默认数据源";
    this.var1 = new PrintVariableItem();
    this.var2 = new PrintVariableItem();
    this.condition = new PrintVariableItem();
    showLabel = false;
  }

  factory BarCodeXTemplate.fromJson(Map<String, dynamic> map) {
    return BarCodeXTemplate()
      ..dataSourceKey = Convert.toStr(map["data"])
      ..var1 = PrintVariableItem.fromJson(Map<String, dynamic>.from(map["var1"]))
      ..var2 = PrintVariableItem.fromJson(Map<String, dynamic>.from(map["var2"]))
      ..showLabel = Convert.toBool(map["label"])
      ..condition = PrintVariableItem.fromJson(Map<String, dynamic>.from(map["condition"]));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "data": this.dataSourceKey,
      "var1": this.var1.toJson(),
      "var2": this.var2.toJson(),
      "label": this.showLabel.toString(),
      "condition": this.condition.toJson(),
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

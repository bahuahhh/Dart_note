import 'dart:convert';

import 'package:estore_app/utils/converts.dart';

import 'print_enums.dart';
import 'print_variable_item.dart';

class BitmapXParameter {
  //模版变量
  BitmapXTemplate template;
  //字体
  FontStyle font;
  //对齐方式
  AlignStyle align;

  BitmapXParameter();

  factory BitmapXParameter.fromJson(Map<String, dynamic> map) {
    return BitmapXParameter()
      ..template = BitmapXTemplate.fromJson(map["template"]['item1'])
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

class BitmapXTemplate {
  //绑定的数据源Key
  String dataSourceKey;

  //行的打印条件变量
  PrintVariableItem condition;

  //打印变量1
  PrintVariableItem var1;

  BitmapXTemplate() {
    this.dataSourceKey = "默认数据源";
    this.var1 = new PrintVariableItem();
    this.condition = new PrintVariableItem();
  }

  factory BitmapXTemplate.fromJson(Map<String, dynamic> map) {
    return BitmapXTemplate()
      ..dataSourceKey = Convert.toStr(map["data"])
      ..var1 = PrintVariableItem.fromJson(Map<String, dynamic>.from(map["var1"]))
      ..condition = PrintVariableItem.fromJson(Map<String, dynamic>.from(map["condition"]));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "data": this.dataSourceKey,
      "var1": this.var1.toJson(),
      "condition": this.condition.toJson(),
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

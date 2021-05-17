import 'dart:convert';

import 'package:estore_app/utils/converts.dart';

import 'print_enums.dart';
import 'print_variable_item.dart';

class QRCodeXParameter {
  //模版变量
  QRCodeXTemplate template;
  //字体
  FontStyle font;
  //对齐方式
  AlignStyle align;
  //二维码大小
  QRCodeSizeMode sizeMode;

  QRCodeXParameter();

  factory QRCodeXParameter.fromJson(Map<String, dynamic> map) {
    return QRCodeXParameter()
      ..template = QRCodeXTemplate.fromJson(map["template"]['item1'])
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..sizeMode = QRCodeSizeMode.fromValue(Convert.toStr(map["size"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "template": this.template.toJson(),
      "font": this.font.value,
      "align": this.align.value,
      "size": this.sizeMode.value,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class QRCodeXTemplate {
  //绑定的数据源Key
  String dataSourceKey;

  //行的打印条件变量
  PrintVariableItem condition;

  //打印变量1
  PrintVariableItem var1;

  QRCodeXTemplate() {
    this.dataSourceKey = "默认数据源";
    this.var1 = new PrintVariableItem();
    this.condition = new PrintVariableItem();
  }

  factory QRCodeXTemplate.fromJson(Map<String, dynamic> map) {
    return QRCodeXTemplate()
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

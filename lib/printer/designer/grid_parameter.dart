import 'dart:convert';

import 'package:estore_app/utils/converts.dart';

import 'print_enums.dart';
import 'print_variable_item.dart';

class GridXParameter {
  //打印字体
  FontStyle font;

  //对齐方式
  AlignStyle align;

  //填充线条
  LineStyle line;

  //数据模版
  GridXTemplate template;

  GridXParameter();

  factory GridXParameter.fromJson(Map<String, dynamic> map) {
    return GridXParameter()
      ..template = GridXTemplate.fromJson(map["template"])
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
      ..line = LineStyle.fromValue(Convert.toStr(map["line"]));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "template": this.template.toString(),
      "font": this.font.value,
      "align": this.align.value,
      "line": this.line.value,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class GridXTemplate {
  String dataSourceKey;

  List<GridColumn> _columns;

  Map<String, GridRowTemplate> _rows;

  Map<String, List<PrintVariableItem>> dataSource;

  //字体格式
  FontStyle font;

  //填充线条，主要解决划线
  LineStyle line;

  //是否包含合计行
  bool containsTotalRow;

  //是否输出打印合计行
  bool outputTotalRow;

  //超出打印字符长度,独占一行
  bool allowNewLine;

  //如果记录集为空不打印
  bool notAllowEmpty;

  //禁止打印表头
  bool notAllowHeader = false;

  //表头采用正常字体打印
  bool headerFontStyle = false;

  //表头只打印一行
  bool headerOneRow = false;

  GridXTemplate() {
    this.dataSourceKey = "默认数据源";
    this._columns = new List<GridColumn>();
    this._rows = new Map<String, GridRowTemplate>();
  }

  List<GridColumn> get columns {
    return this._columns;
  }

  Map<String, GridRowTemplate> get rows {
    return this._rows;
  }

  factory GridXTemplate.fromJson(Map<String, dynamic> map) {
    return GridXTemplate()
      ..dataSourceKey = Convert.toStr(map["data"])
      .._columns = map["columns"] != null ? List<GridColumn>.from(List<Map<String, dynamic>>.from(map["columns"]).map((x) => GridColumn.fromJson(x))) : <GridColumn>[]
      .._rows = map["rows"] != null ? GridRowTemplate.toMap(map["rows"]) : new Map<String, GridRowTemplate>()
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..line = LineStyle.fromValue(Convert.toStr(map["line"]))
      ..containsTotalRow = Convert.toBool(map["contains"])
      ..outputTotalRow = Convert.toBool(map["output"])
      ..allowNewLine = Convert.toBool(map["newline"])
      ..notAllowEmpty = Convert.toBool(map["empty"])
      ..notAllowHeader = Convert.toBool(map["header"])
      ..headerFontStyle = Convert.toBool(map["headerFont"])
      ..headerOneRow = Convert.toBool(map["headerOneRow"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "data": this.dataSourceKey,
      "columns": this.columns,
      "font": this.font.value,
      "line": this.line.value,
      "contains": this.containsTotalRow.toString(),
      "output": this.outputTotalRow.toString(),
      "newline": this.allowNewLine.toString(),
      "empty": this.notAllowEmpty.toString(),
      "header": this.notAllowHeader.toString(),
      "headerFont": this.headerFontStyle.toString(),
      "headerOneRow": this.headerOneRow.toString(),
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class GridRowTemplate {
  String name;
  String content;
  int width;

  GridRowTemplate();

  factory GridRowTemplate.fromJson(Map<String, dynamic> map) {
    return GridRowTemplate()
      ..name = Convert.toStr(map["name"])
      ..content = Convert.toStr(map["content"])
      ..width = Convert.toInt(map["width"]);
  }

  ///转Map集合
  static Map<String, GridRowTemplate> toMap(Map<String, dynamic> map) {
    var result = new Map<String, GridRowTemplate>();

    map.forEach((key, value) {
      result[key] = GridRowTemplate.fromJson(value);
    });

    return result;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "name": this.name,
      "content": this.content,
      "width": this.width,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class GridColumn {
  int index;
  String name;
  AlignStyle align;
  int length;
  int width;
  int rowSeq;

  GridColumn();

  factory GridColumn.fromJson(Map<String, dynamic> map) {
    return GridColumn()
      ..index = Convert.toInt(map["index"])
      ..name = Convert.toStr(map["name"])
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
      ..width = Convert.toInt(map["width"])
      ..length = Convert.toInt(map["length"])
      ..rowSeq = Convert.toInt(map["rowSeq"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "index": this.index,
      "name": this.name,
      "align": this.align.value,
      "width": this.width,
      "length": this.length,
      "rowSeq": this.rowSeq,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

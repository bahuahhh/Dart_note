import 'dart:convert';

import 'package:estore_app/utils/converts.dart';

import 'barcode_parameter.dart';
import 'bitmap_parameter.dart';
import 'grid_parameter.dart';
import 'print_designer_controls.dart';
import 'print_enums.dart';
import 'print_template.dart';
import 'print_variable_item.dart';
import 'print_variable_value.dart';
import 'qrcode_parameter.dart';
import 'r1_parameter.dart';
import 'r2_parameter.dart';

class PrintDesignerSurface {
  //纸张类型
  PagerType pager = PagerType.Line_80MM_48;
  //纸张宽度
  int width = 80;
  //小票版本
  int version = 1;
  //数据源
  Map<String, dynamic> dataSource = {};
  //当前控件列表
  List<PrintDesignerControls> controls = <PrintDesignerControls>[];

  PrintDesignerSurface();

  factory PrintDesignerSurface.fromJson(Map<String, dynamic> map) {
    return PrintDesignerSurface()
      ..pager = PagerType.fromValue(Convert.toInt(map["pager"]))
      ..width = Convert.toInt(map["width"])
      ..version = Convert.toInt(map["version"])
      ..dataSource = new Map<String, dynamic>.from(map["dataSource"])
      ..controls = map["controls"] != null ? List<PrintDesignerControls>.from(List<Map<String, dynamic>>.from(map["controls"]).map((x) => PrintDesignerControls.fromJson(x))) : <PrintDesignerControls>[];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "pager ": this.pager.value,
      "width": this.width,
      "version": this.version,
      "dataSource": json.encode(this.dataSource),
      "controls": json.encode(this.controls),
    };
    return map;
  }

  PrintTemplate parse(List<PrintVariableValue> args) {
    PrintTemplate printer = new PrintTemplate();
    printer.pager = this.pager;
    printer.maxLength = Convert.toInt(this.pager.value);

    for (PrintDesignerControls ctrls in this.controls) {
      switch (ctrls.type) {
        case ControlType.SingleRowTemplate: //单行模版

          Map<String, dynamic> map = json.decode(ctrls.template);

          var parameter = R1Parameter.fromJson(map);

          R1Template template = parameter.template;
          //判断是否符合打印条件
          var condition = parseCondition(template.condition, template.dataSourceKey, args);
          if (!condition) {
            continue;
          }

          RowTemplate row = new RowTemplate();
          row.format = RowFormat.Line;

          LineTemplate line = new LineTemplate();
          line.dataSourceKey = template.dataSourceKey;
          line.font = parameter.font;
          line.align = parameter.align;
          line.line = parameter.line;

          line.length = this.pager.value;

          var content = "${template.prefix}${template.var1.value}${template.middle}${template.var2.value}${template.suffix}";
          line.content = content;

          row.template = json.encode(line);

          printer.addRow(row);

          break;
        case ControlType.TwoColumnTemplate: //两列模版

          Map<String, dynamic> map = json.decode(ctrls.template);

          var parameter = R2Parameter.fromJson(map);

          R2Template left = parameter.template.item1;
          //判断是否符合打印条件
          var leftCondition = parseCondition(left.condition, left.dataSourceKey, args);
          R2Template right = parameter.template.item2;
          //判断是否符合打印条件
          var rightCondition = parseCondition(right.condition, left.dataSourceKey, args);

          if (!leftCondition && !rightCondition) {
            continue;
          }

          RowTemplate row = new RowTemplate();
          row.format = RowFormat.Column;

          List<LineTemplate> lines = new List<LineTemplate>();

          LineTemplate line = new LineTemplate();
          line.dataSourceKey = left.dataSourceKey;
          line.font = parameter.font;
          line.align = left.align;
          line.line = parameter.line;
          //列打印字符数，根据每行字符数*列的宽度百分比
          int leftStringLength = (this.pager.value * left.percent / 100).floor();

          //将宽度都重置为偶数，防止比例算出来为奇数，导致两列模板换行失控
          switch (line.font) {
            case FontStyle.DoubleWidth:
            case FontStyle.DoubleWidthHeight:
              {
                line.length = (leftStringLength / 4 * 4).floor();
              }
              break;
            default:
              {
                line.length = (leftStringLength / 2 * 2).floor();
              }
              break;
          }
          leftStringLength = line.length;

          var content = "${left.prefix}${left.var1.value}${left.middle}${left.var2.value}${left.suffix}";
          line.content = leftCondition ? content : "";
          lines.add(line);

          line = new LineTemplate();
          line.dataSourceKey = right.dataSourceKey;
          line.font = parameter.font;
          line.align = right.align;
          line.line = parameter.line;
          //左标签长度确定后，右标签采用减的方式
          line.length = this.pager.value - leftStringLength;
          content = "${right.prefix}${right.var1.value}${right.middle}${right.var2.value}${right.suffix}";
          line.content = rightCondition ? content : "";
          lines.add(line);

          row.template = json.encode(lines);

          printer.addRow(row);

          break;
        case ControlType.GridTemplate: //表格模版
          Map<String, dynamic> map = json.decode(ctrls.template);
          var parameter = GridXParameter.fromJson(map);

          RowTemplate row = new RowTemplate();
          row.format = RowFormat.Grid;

          GridTemplate grid = new GridTemplate();

          grid.dataSourceKey = parameter.template.dataSourceKey;
          //包含合计行
          grid.containsTotalRow = parameter.template.containsTotalRow;
          //自动换新行
          grid.allowNewLine = parameter.template.allowNewLine;
          //打印合计行
          grid.outputTotalRow = parameter.template.outputTotalRow;
          //字体
          grid.font = parameter.font;
          //表头下划线格式
          grid.line = parameter.line;
          //空记录集是否打印表头
          grid.notAllowEmpty = parameter.template.notAllowEmpty;
          //禁止打印表头
          grid.notAllowHeader = parameter.template.notAllowHeader;
          //表头采用正常字体打印
          grid.headerFontStyle = parameter.template.headerFontStyle;
          //表头只打印一行
          grid.headerOneRow = parameter.template.headerOneRow;

          for (var cols in parameter.template.columns) {
            var r = parameter.template.rows["${cols.index}"];

            var column = new ColumnTemplate();
            column.index = cols.index;
            column.name = cols.name;
            column.align = cols.align;
            column.vars = r.content;
            column.length = cols.length;
            column.rowSeq = cols.rowSeq;
            column.width = r.width;

            grid.addColumn(column);
          }

          row.template = json.encode(grid);

          printer.addRow(row);

          break;
        case ControlType.BarcodeTemplate: //条码模版
          Map<String, dynamic> map = json.decode(ctrls.template);
          var parameter = BarCodeXParameter.fromJson(map);
          BarCodeXTemplate template = parameter.template;

          //判断是否符合打印条件
          var condition = parseCondition(template.condition, template.dataSourceKey, args);
          if (!condition) {
            continue;
          }

          RowTemplate row = new RowTemplate();
          row.format = RowFormat.Barcode;

          BarcodeTemplate barcode = new BarcodeTemplate();
          barcode.dataSourceKey = template.dataSourceKey;
          barcode.font = parameter.font;
          barcode.align = parameter.align;
          barcode.length = this.pager.value;

          barcode.showLable = template.showLabel;
          barcode.content = template.var1.value;
          barcode.lableContent = template.var2.value;

          row.template = json.encode(barcode);

          printer.addRow(row);

          break;
        case ControlType.QrcodeTemplate: //二维码模版

          Map<String, dynamic> map = json.decode(ctrls.template);
          var parameter = QRCodeXParameter.fromJson(map);
          QRCodeXTemplate template = parameter.template;

          //判断是否符合打印条件
          var condition = parseCondition(template.condition, template.dataSourceKey, args);
          if (!condition) {
            continue;
          }

          RowTemplate row = new RowTemplate();
          row.format = RowFormat.QRCode;

          QRCodeTemplate qrcode = new QRCodeTemplate();
          qrcode.dataSourceKey = template.dataSourceKey;
          qrcode.font = parameter.font;
          qrcode.align = parameter.align;
          qrcode.sizeMode = parameter.sizeMode;

          qrcode.length = this.pager.value;
          qrcode.content = template.var1.value;

          row.template = json.encode(qrcode);

          printer.addRow(row);
          break;
        case ControlType.BitmapTemplate: //位图模版

          Map<String, dynamic> map = json.decode(ctrls.template);
          var parameter = BitmapXParameter.fromJson(map);
          BitmapXTemplate template = parameter.template;

          //判断是否符合打印条件
          var condition = parseCondition(template.condition, template.dataSourceKey, args);
          if (!condition) {
            continue;
          }

          RowTemplate row = new RowTemplate();
          row.format = RowFormat.Bitmap;

          BitmapTemplate bitmap = new BitmapTemplate();
          bitmap.dataSourceKey = template.dataSourceKey;
          bitmap.font = parameter.font;
          bitmap.align = parameter.align;
          bitmap.length = this.pager.value;

          bitmap.content = template.var1.value;

          row.template = json.encode(bitmap);

          printer.addRow(row);
          break;
      }
    }
    return printer;
  }

  bool parseCondition(PrintVariableItem variableItem, String dataSourceKey, List<PrintVariableValue> args) {
    bool result = true;

    //数据源参数,无论单行还是列表，数据源采用List方式，兼容单行选择集合数据源，重复行打印
    var data = new List<Map<String, dynamic>>();
    //包含数据源参数,重置
    if (args.any((x) => x.key == dataSourceKey)) {
      //当前数据源
      var vars = args.lastWhere((x) => x.key == dataSourceKey);
      //List集合数据
      if (vars.type == DataType.List) {
        var jsonObj = List<Map<String, dynamic>>.from(json.decode("${vars.data}"));
        data.addAll(jsonObj);
      } else {
        var row = json.decode("${vars.data}");
        data.add(row);
      }
    }
    //参数中是否包含条件参数，如果包含，取值，如果不包含，忽略，继续打印
    if (variableItem != null && data.any((x) => x.containsKey(variableItem.value))) {
      //取第一个值
      var _value = data[0][variableItem.value];
      if ("false" == _value.toLowerCase()) {
        result = false;
      }
    }
    return result;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

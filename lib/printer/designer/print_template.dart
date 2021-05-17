import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:ui';

import 'package:barcode/barcode.dart';
import 'package:barcode_image/barcode_image.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/printer/designer/print_content.dart';
import 'package:estore_app/printer/printer_object.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/objectid_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:image/image.dart';

import 'print_enums.dart';
import 'print_variable_value.dart';

class PrintTemplate {
  //纸张类型
  PagerType pager = PagerType.Line_80MM_48;

  //单行最大打印半角字符数量
  int maxLength = 80;

  List<RowTemplate> _rows = <RowTemplate>[];
  List<RowTemplate> get rows {
    return _rows;
  }

  void addRow(RowTemplate row) {
    this._rows.add(row);
  }

  List<PrintContent> parseEx(PrinterObject pobject, List<PrintVariableValue> args) {
    return parse(pobject, args, headerLine: pobject.headerLines, footerLine: pobject.footerLines);
  }

  List<PrintContent> parse(PrinterObject pobject, List<PrintVariableValue> args, {int headerLine = 0, int footerLine = 0}) {
    if (pobject == null) {
      pobject = new PrinterObject();
    }

    if (args == null) {
      args = new List<PrintVariableValue>();
    }

    var result = new List<PrintContent>();

    EscPosCommand command = pobject.escPosCommand;

    //初始化指令
    var init = new PrintContent();
    init.format = RowFormat.Line;
    init.content = new StringBuffer()..write(parseEscPosCommand(command.initCommand));
    result.add(init);

    //钱箱指令
    if (pobject.openCashbox) {
      var content = new PrintContent();
      content.format = RowFormat.Line;
      content.content = new StringBuffer()..write(parseEscPosCommand(command.cashboxCommand));
      result.add(content);
    }
    //退纸指令
    if (pobject.feedBackRow > 0) {
      var content = new PrintContent();
      content.format = RowFormat.Line;
      var sb = new StringBuffer();
      var rows = pobject.feedBackRow;
      while (rows > 0) {
        //反向走纸
        sb.write(parseEscPosCommand(command.feedBackCommand.replaceAll('n', '1')));
        rows--;
      }
      content.content = sb;
      result.add(content);
    }

    //空白表头
    for (int i = 0; i < headerLine; i++) {
      var header = new PrintContent();

      header.format = RowFormat.Line;
      header.content = new StringBuffer()..write("\n");
      header.alignStyle = AlignStyle.Left;
      header.fontStyle = FontStyle.Normal;
      header.bitmapFile = "";

      result.add(header);
    }

    for (var row in this.rows) {
      switch (row.format) {
        case RowFormat.Line:
          {
            //行数据模版
            var template = LineTemplate.fromJson(json.decode(row.template));
            //数据源参数,无论单行还是列表，数据源采用List方式，兼容单行选择集合数据源，重复行打印
            var data = new List<Map<String, dynamic>>();
            //包含数据源参数,重置
            if (args.any((x) => x.key == template.dataSourceKey)) {
              //当前数据源
              var vars = args.lastWhere((x) => x.key == template.dataSourceKey);
              //List集合数据
              if (vars.type == DataType.List) {
                var jsonObj = List<Map<String, dynamic>>.from(json.decode("${vars.data}"));
                data.addAll(jsonObj);
              } else {
                var row = json.decode("${vars.data}");
                data.add(row);
              }
            }

            //如果没有数据源,模拟一个避免不打印
            if (data.length == 0) {
              data.add(new Map<String, dynamic>());
            }

            var content = new PrintContent();
            content.format = RowFormat.Line;

            var sb = new StringBuffer();

            //替换变量
            for (var row in data) {
              //字体指令
              sb.write(parseFontStyle(template.font, command));
              //打印内容
              sb.write(replaceArgs(template.content, row, this.maxLength, template.align, template.font, template.line));
            }

            content.content = sb;
            result.add(content);
          }
          break;
        case RowFormat.Column:
          {
            //行数据模版
            var template = List<LineTemplate>.from(json.decode(row.template).map((x) => LineTemplate.fromJson(x)));
            //合并行数据
            var lists = mergeLineTemplate(template[0], template[1], args, command);

            var content = new PrintContent();
            content.format = RowFormat.Column;
            var sb = new StringBuffer();

            for (var str in lists) {
              sb.write(str);
            }

            content.content = sb;
            result.add(content);
          }
          break;
        case RowFormat.Grid:
          {
            //行数据模版
            var template = GridTemplate.fromJson(json.decode(row.template));

            //数据源参数，必须为列表
            var data = new List<Map<String, dynamic>>();
            //包含数据源参数,重置
            if (args.any((x) => x.key == template.dataSourceKey)) {
              //当前数据源
              var vars = args.lastWhere((x) => x.key == template.dataSourceKey);
              //List集合数据
              if (vars.type == DataType.List) {
                var jsonObj = List<Map<String, dynamic>>.from(json.decode("${vars.data}"));
                data.addAll(jsonObj);
              } else {
                var row = json.decode("${vars.data}");
                data.add(row);
              }
            }

            //判断是否符合打印条件
            var notAllowEmpty = template.notAllowEmpty;
            if (notAllowEmpty && data.length == 0) {
              continue;
            }

            var content = new PrintContent();
            content.format = RowFormat.Grid;
            var sb = new StringBuffer();

            //标题行添加下划线
            String paddingChar = this.parseLineType(template.line);
            var _allColumnWidth = new Map<int, Map<int, int>>();
            var _columnWidth = new Map<int, int>();
            int _column = 0;
            int _sum = 0;

            //判断是否打印表头
            var notAllowHeader = template.notAllowHeader;

            var fontStyle = FontStyle.Normal;
            if (!notAllowHeader) {
              //表头采用正常字体打印
              var notAllowHeaderFontStyle = template.headerFontStyle;
              if (!notAllowHeaderFontStyle) {
                fontStyle = template.font;
              }
              //字体指令
              sb.write(parseFontStyle(fontStyle, command));
            }
            //标题
            var templateColumns = template.columns;
            templateColumns.sort((left, right) => left.rowSeq.compareTo(right.rowSeq));
            var tempRow = -1;
            var secondRow = false;
            for (ColumnTemplate col in templateColumns) {
              if (tempRow != -1 && tempRow != col.rowSeq) {
                //重置宽度归零
                _sum = 0;
                //加入行集合
                _allColumnWidth[tempRow] = _columnWidth;
                //重置
                _columnWidth = new Map<int, int>();

                secondRow = true;
              }

              tempRow = col.rowSeq;

              _sum += col.length;

              _columnWidth[_column++] = _sum;

              var title = replaceArgs(col.name, null, col.length, col.align, fontStyle, LineStyle.NoPadding);
              int titleLength = getPrintStringLength(title, fontStyle);
              int titleDiff = col.length - titleLength;

              if (!notAllowHeader) {
                if (secondRow && template.headerOneRow) {
                  continue;
                }
                sb.write(title + ("".padRight(titleDiff < 0 ? 0 : titleDiff, " ")));
              }
            }
            //最后一行加入集合
            _allColumnWidth[tempRow] = _columnWidth;

            //提交标题行打印
            if (!notAllowHeader) {
              sb.write("\n");
            }

            //提交下划线打印
            if (StringUtils.isNotBlank(paddingChar.trim())) {
              //字体指令
              sb.write(parseFontStyle(FontStyle.Normal, command));
              sb.write("".padRight(this.maxLength, paddingChar));
              sb.write("\n");
            }

            //模版数据
            for (int row = 0; row < data.length; row++) {
              //判断是否允许输出合计行,并且是最后一行
              if (template.containsTotalRow && row + 1 == data.length) {
                //不允许打印，结束本次循环
                if (!template.outputTotalRow) {
                  continue;
                }
                //字体指令
                sb.write(parseFontStyle(FontStyle.Normal, command));
                //下划线,隔离合计行和明细
                sb.write("".padRight(this.maxLength, paddingChar));
                sb.write("\n");
              }

              int cols = 0;
              var _offset = new Map<int, int>();
              var lastRowSeq = -1;
              for (ColumnTemplate col in templateColumns) {
                var columnWidth = _allColumnWidth[col.rowSeq];

                if (lastRowSeq != -1 && lastRowSeq != col.rowSeq) {
                  //新的一行
                  sb.write("\n");
                }
                lastRowSeq = col.rowSeq;

                if (template.allowNewLine) {
                  var _content = replaceArgsByGrid(col.vars, template.allowNewLine, data[row], col.length, col.align, template.font, LineStyle.NoPadding);
                  int len = getPrintStringLength(_content, template.font);

                  //长度超出，允许独占一行
                  if (len > col.length) {
                    _offset[cols] = columnWidth[cols];
                  } else {
                    _offset[cols] = 0;
                  }
                  //独占一行的内容
                  if (_offset[cols] > 0) {
                    int width = (cols == 0 ? 0 : _offset[cols - 1]);

                    //字体指令
                    sb.write(parseFontStyle(template.font, command));
                    sb.write("".padLeft(width, ' ') + _content);
                    sb.write("\n");
                  } else {
                    int width = (cols == 0 ? 0 : _offset[cols - 1]);

                    //字体指令
                    sb.write(parseFontStyle(FontStyle.Normal, command));
                    sb.write("".padLeft(width, ' '));
                    int diff = col.length - len;
                    //字体指令
                    sb.write(parseFontStyle(template.font, command));
                    sb.write(_content);
                    //字体指令
                    //不足部分按照正常字体补充空格
                    if (diff > 0) {
                      sb.write(parseFontStyle(FontStyle.Normal, command));
                      sb.write("".padRight(diff < 0 ? 0 : diff, ' '));
                    }
                  }
                } else {
                  var _content = replaceArgsByGrid(col.vars, template.allowNewLine, data[row], col.length, col.align, template.font, LineStyle.NoPadding);
                  int len = getPrintStringLength(_content, template.font);

                  int diff = col.length - len;
                  //指定字体输出打印内容
                  sb.write(parseFontStyle(template.font, command));
                  sb.write(_content);

                  //不足部分按照正常字体补充空格
                  if (diff > 0) {
                    sb.write(parseFontStyle(FontStyle.Normal, command));
                    sb.write("".padRight(diff < 0 ? 0 : diff, ' '));
                  }
                }
                cols++;
              }
              //满足整行提交
              sb.write("\n");
            }

            content.content = sb;

            result.add(content);
          }
          break;
        case RowFormat.Barcode:
          {
            //是否支持打印条码
            if (pobject.printBarcodeFlag != 1) {
              break;
            }

            //行数据模版
            var template = BarcodeTemplate.fromJson(json.decode(row.template));

            //数据源参数，必须为列表
            var data = new List<Map<String, dynamic>>();
            //包含数据源参数,重置
            if (args.any((x) => x.key == template.dataSourceKey)) {
              //当前数据源
              var vars = args.lastWhere((x) => x.key == template.dataSourceKey);
              //List集合数据
              if (vars.type == DataType.List) {
                var jsonObj = List<Map<String, dynamic>>.from(json.decode("${vars.data}"));
                data.addAll(jsonObj);
              } else {
                var row = json.decode("${vars.data}");
                data.add(row);
              }
            }

            //替换变量
            for (var row in data) {
              //是否显示标签
              var _barcodeShowLabel = template.showLable;
              //标签的内容
              var _barcodeLabelontent = replaceArgs(template.lableContent, row, this.maxLength, template.align, template.font, LineStyle.NoPadding);
              //条码内容
              var _barcodeContent = replaceArgs(template.content, row, this.maxLength, template.align, template.font, LineStyle.NoPadding);

              //如果标签内容为空，视为不显示标签
              if (StringUtils.isBlank(_barcodeLabelontent.trim())) {
                _barcodeLabelontent = _barcodeContent.trim();
              }

              //内容为空或者非数字
              if (StringUtils.isBlank(_barcodeContent.trim()) || !StringUtils.isNumeric(_barcodeContent.trim())) {
                continue;
              }

              var content = new PrintContent();
              content.format = RowFormat.Barcode;

              var sb = new StringBuffer();
              //字体指令
              sb.write(parseFontStyle(template.font, command));
              switch (template.align) {
                case AlignStyle.Left:
                  {
                    sb.write(parseEscPosCommand(command.alignLeftCommand));
                  }
                  break;
                case AlignStyle.Center:
                  {
                    sb.write(parseEscPosCommand(command.alignCenterCommand));
                  }
                  break;
                case AlignStyle.Right:
                  {
                    sb.write(parseEscPosCommand(command.alignRightCommand));
                  }
                  break;
              }

              print(">>>图片方式打印>${pobject.printBarcodeByImage}");
              //图片方式打印
              if (pobject.printBarcodeByImage == 1) {
                //sb.AppendLine("");
                //content.BitmapFile = BuilderBarcode(_barcodeContent.Trim(), _barcodeShowLabel, _barcodeLabelontent.Trim(), template.AlignStyle);
              } else {
                // Create an image
                final image = Image(45 * 8, 200);
                fill(image, getColor(255, 255, 255));
                drawBarcode(image, Barcode.qrCode(), 'No.${_barcodeContent.trim()}', font: arial_24);

                // Save the image
                String bitmapFile = '${Constants.PRINTER_IMAGE_PATH}/${ObjectIdUtils.getInstance().generate()}.png';
                File(bitmapFile).writeAsBytesSync(encodePng(image));

                content.bitmapFile = bitmapFile;
              }

              content.content = sb;

              result.add(content);
            }
          }
          break;
        case RowFormat.QRCode:
          {
            //是否支持打印二维码
            if (pobject.printQrcodeFlag != 1) {
              break;
            }
          }
          break;
        case RowFormat.Bitmap:
          {
            //行数据模版
            var template = BitmapTemplate.fromJson(json.decode(row.template));
            //数据源参数,无论单行还是列表，数据源采用List方式，兼容单行选择集合数据源，重复行打印
            var data = new List<Map<String, dynamic>>();
            //包含数据源参数,重置
            if (args.any((x) => x.key == template.dataSourceKey)) {
              //当前数据源
              var vars = args.lastWhere((x) => x.key == template.dataSourceKey);
              //List集合数据
              if (vars.type == DataType.List) {
                var jsonObj = List<Map<String, dynamic>>.from(json.decode("${vars.data}"));
                data.addAll(jsonObj);
              } else {
                var row = json.decode("${vars.data}");
                data.add(row);
              }
            }

            //替换变量
            for (var row in data) {
              print("@@@@@@@@@@@@@>>>>>>>>>>>>>位图路径：${template.content}");

              //位图路径
              String _bitmapFile = "";
              if (row.containsKey(template.content)) {
                _bitmapFile = row[template.content];
              }
              //文件不存在
              if (StringUtils.isBlank(_bitmapFile)) {
                continue;
              }
              //文件不存在
              File file = File("${_bitmapFile.trim()}");
              bool fileExist = file.existsSync();
              if (!fileExist) {
                continue;
              }

              var content = new PrintContent();
              content.format = RowFormat.Bitmap;

              var sb = new StringBuffer();
              //字体指令
              sb.write(parseFontStyle(template.font, command));
              switch (template.align) {
                case AlignStyle.Left:
                  {
                    sb.write(parseEscPosCommand(command.alignLeftCommand));
                  }
                  break;
                case AlignStyle.Center:
                  {
                    sb.write(parseEscPosCommand(command.alignCenterCommand));
                  }
                  break;
                case AlignStyle.Right:
                  {
                    sb.write(parseEscPosCommand(command.alignRightCommand));
                  }
                  break;
              }

              sb.write("\n");

              content.content = sb;

              //var bitmap = new Bitmap(Bitmap.FromFile(_bitmapFile.Trim()));

              print("@@@@@@@@@@@@@>>>>>>>>>>>>>位图路径：${_bitmapFile.trim()}");
              content.bitmapFile = _bitmapFile.trim();

              result.add(content);
            }
          }
          break;
      }
    }
    for (int i = 0; i < footerLine; i++) {
      var footer = new PrintContent();

      footer.format = RowFormat.Line;
      footer.content = new StringBuffer()..write("\n");
      footer.alignStyle = AlignStyle.Left;
      footer.fontStyle = FontStyle.Normal;
      footer.bitmapFile = "";

      result.add(footer);
    }

    //切纸指令
    if (pobject.cutPager) {
      //切纸
      var content = new PrintContent();
      content.format = RowFormat.Line;
      content.content = new StringBuffer()..write(parseEscPosCommand(command.cutPageCommand));

      result.add(content);
    }

    if (result.length > 0) {
      //打印机归位
      var submit = new PrintContent();
      submit.format = RowFormat.Line;
      submit.content = new StringBuffer()..write("\n");

      result.add(submit);
    }

    //蜂鸣
    if (pobject.beep) {
      var content = new PrintContent();
      content.format = RowFormat.Line;
      content.content = new StringBuffer()..write(parseEscPosCommand(command.beepCommand));

      result.add(content);
    }

    return result;
  }

  //合并两列布局的数据为行数据
  List<String> mergeLineTemplate(LineTemplate left, LineTemplate right, List<PrintVariableValue> args, EscPosCommand command) {
    //数据源参数
    var data = new List<Map<String, dynamic>>();
    //包含数据源参数,重置
    if (args.any((x) => x.key == left.dataSourceKey)) {
      //当前数据源
      var vars = args.lastWhere((x) => x.key == left.dataSourceKey);

      //List集合数据
      if (vars.type == DataType.List) {
        var jsonObj = List<Map<String, dynamic>>.from(json.decode("${vars.data}"));
        data.addAll(jsonObj);
      } else {
        var row = json.decode("${vars.data}");
        data.add(row);
      }
    }

    //左标签的换行后字符串列表
    List<String> leftList = replaceArgsEx(left.content, data, left.length, left.align, left.font, left.line);
    var leftDictionary = new Map<int, String>();
    for (int i = 0; i < leftList.length; i++) {
      leftDictionary[i] = leftList[i];
    }

    //重置
    data = new List<Map<String, dynamic>>();
    //包含数据源参数,重置
    if (args.any((x) => x.key == right.dataSourceKey)) {
      //当前数据源
      var vars = args.lastWhere((x) => x.key == right.dataSourceKey);

      //List集合数据
      if (vars.type == DataType.List) {
        var jsonObj = List<Map<String, dynamic>>.from(json.decode("${vars.data}"));
        data.addAll(jsonObj);
      } else {
        var row = json.decode("${vars.data}");
        data.add(row);
      }
    }

    //右标签的换行后字符串列表
    List<String> rightList = replaceArgsEx(right.content, data, right.length, right.align, right.font, right.line);
    var rightDictionary = new Map<int, String>();
    for (int i = 0; i < rightList.length; i++) {
      rightDictionary[i] = rightList[i];
    }

    var result = new List<String>();

    var diff = leftList.length - rightList.length;
    if (diff > 0) {
      for (int i = 0; i < diff; i++) {
        rightList.insert(0, "");
      }
    } else {
      for (int i = 0; i < diff.abs(); i++) {
        leftList.insert(0, "");
      }
    }

    for (int i = 0; i < leftList.length; i++) {
      StringBuffer sb = new StringBuffer();

      //字体指令
      sb.write(parseFontStyle(left.font, command));
      sb.write(leftList[i]);
      sb.write(rightList[i]);
      result.add(sb.toString());
    }

    return result;
  }

  List<String> replaceArgsEx(String content, List<Map<String, dynamic>> args, int maxLength, AlignStyle alignStyle, FontStyle fontStyle, LineStyle lineStyle) {
    List<String> result = new List<String>();

    //如果不包含任何数据源变量,模拟一个避免不打印
    if (args.length == 0) {
      args.add(new Map<String, dynamic>());
    }

    for (var data in args) {
      String str = replaceArgs(content, data, maxLength, alignStyle, fontStyle, lineStyle);

      //if (str.contains(Environment.NewLine))
      if (str.contains("\n")) {
        var array = str.split("\n");
        result.addAll(array);
      } else {
        String paddingChar = this.parseLineType(lineStyle);

        if (StringUtils.isBlank(str)) {
          str = "".padLeft(maxLength, paddingChar);
        }

        result.add(str);
      }
    }

    return result;
  }

  String replaceArgs(String content, Map<String, dynamic> args, int maxLength, AlignStyle alignStyle, FontStyle fontStyle, LineStyle lineStyle) {
    if (args == null) {
      args = new Map<String, dynamic>();
    }

    args.forEach((key, value) {
      content = content.replaceAll(key, value);
    });

    Tuple2<int, List<String>> res = getPrintStringLengthByMaxLength(content, maxLength, fontStyle);
    int length = res.item1;
    List<String> str = res.item2;
    String result = "";
    for (int i = 0; i < str.length; i++) {
      var s = str[i];

      int len = getPrintStringLength(s, fontStyle);

      int fix = 0;
      switch (fontStyle) {
        case FontStyle.Normal:
        case FontStyle.DoubleHeight:
          fix = 2;
          break;
        case FontStyle.DoubleWidth:
        case FontStyle.DoubleWidthHeight:
          fix = 4;
          break;
        default:
          fix = 2;
          break;
      }
      int diff = 0;
      String paddingChar = this.parseLineType(lineStyle);
      switch (alignStyle) {
        case AlignStyle.Left:
          diff = ((maxLength - len) * 2 / fix).floor();
          result += s + "".padRight(diff < 0 ? 0 : diff, paddingChar);
          break;

        case AlignStyle.Center:
          diff = ((maxLength - len) / fix).floor();
          result += "".padLeft(diff < 0 ? 0 : diff, paddingChar) + s + "".padRight(diff < 0 ? 0 : diff, paddingChar);
          break;
        case AlignStyle.Right:
          diff = ((maxLength - len) * 2 / fix).floor();
          result += "".padLeft(diff < 0 ? 0 : diff, paddingChar) + s;
          break;
      }

      if (i + 1 != str.length) {
        result += "\n";
      }
    }

    //处理单独划线
    if (StringUtils.isBlank(result)) {
      int fix = 0;
      switch (fontStyle) {
        case FontStyle.Normal:
        case FontStyle.DoubleHeight:
          fix = 2;
          break;
        case FontStyle.DoubleWidth:
        case FontStyle.DoubleWidthHeight:
          fix = 4;
          break;
        default:
          fix = 2;
          break;
      }

      String paddingChar = this.parseLineType(lineStyle);
      result = "".padRight((maxLength * 2 / fix).floor(), paddingChar);
    }

    return result;
  }

  String replaceArgsByGrid(String content, bool fullLine, Map<String, dynamic> args, int maxLength, AlignStyle alignStyle, FontStyle fontStyle, LineStyle lineStyle) {
    if (args == null) {
      args = new Map<String, dynamic>();
    }

    args.forEach((key, value) {
      content = content.replaceAll(key, value);
    });

    Tuple2<int, List<String>> res = getPrintStringLengthByGrid(content, fullLine, maxLength, fontStyle);

    int length = res.item1;
    List<String> str = res.item2;
    String result = "";
    for (int i = 0; i < str.length; i++) {
      var s = str[i];

      int len = getPrintStringLength(s, fontStyle);

      int fix = 0;
      switch (fontStyle) {
        case FontStyle.Normal:
        case FontStyle.DoubleHeight:
          fix = 2;
          break;
        case FontStyle.DoubleWidth:
        case FontStyle.DoubleWidthHeight:
          fix = 4;
          break;
        default:
          fix = 2;
          break;
      }
      int diff = 0;
      String paddingChar = this.parseLineType(lineStyle);
      switch (alignStyle) {
        case AlignStyle.Left:
          diff = ((maxLength - len) / fix * 2).floor();
          result += s + "".padRight(diff < 0 ? 0 : diff, paddingChar);
          break;

        case AlignStyle.Center:
          diff = ((maxLength - len) / fix).floor();
          result += "".padLeft(diff < 0 ? 0 : diff, paddingChar) + s + "".padRight(diff < 0 ? 0 : diff, paddingChar);
          break;
        case AlignStyle.Right:
          diff = ((maxLength - len) / fix * 2).floor();
          result += "".padLeft(diff < 0 ? 0 : diff, paddingChar) + s;
          break;
      }

      if (i + 1 != str.length) {
        result += "\n";
      }
    }

    //处理单独划线
    if (StringUtils.isBlank(result)) {
      int fix = 0;
      switch (fontStyle) {
        case FontStyle.Normal:
        case FontStyle.DoubleHeight:
          fix = 2;
          break;
        case FontStyle.DoubleWidth:
        case FontStyle.DoubleWidthHeight:
          fix = 4;
          break;
        default:
          fix = 2;
          break;
      }

      String paddingChar = this.parseLineType(lineStyle);
      result = "".padRight((maxLength / fix * 2).floor(), paddingChar);
    }

    return result;
  }

  Tuple2<int, List<String>> getPrintStringLengthByGrid(String str, bool fullLine, int maxLength, FontStyle fontStyle) {
    int valueLength = 0;
    List<String> list = new List<String>();

    String tmpString = "";

    RegExp chinese = new RegExp(r"^[\u0391-\uFFE5]+$");
    // 获取字段值的长度，如果含中文字符，则每个中文字符长度为2，否则为1
    for (int i = 0; i < str.length; i++) {
      // 获取一个字符
      String temp = str[i].toString();
      // 判断是否为中文字符
      if (chinese.hasMatch(temp)) {
        switch (fontStyle) {
          case FontStyle.Normal:
          case FontStyle.DoubleHeight:
            valueLength += 2;
            break;
          case FontStyle.DoubleWidth:
          case FontStyle.DoubleWidthHeight:
            valueLength += 4;
            break;
          default:
            valueLength += 2;
            break;
        }
      } else {
        switch (fontStyle) {
          case FontStyle.Normal:
          case FontStyle.DoubleHeight:
            valueLength += 1;
            break;
          case FontStyle.DoubleWidth:
          case FontStyle.DoubleWidthHeight:
            valueLength += 2;
            break;
          default:
            valueLength += 1;
            break;
        }
      }

      tmpString += temp;

      if (!fullLine) {
        if (valueLength % maxLength == 0) {
          list.add(tmpString);
          tmpString = "";
        }
      }
    }

    if (StringUtils.isNotBlank(tmpString)) {
      list.add(tmpString);
    }

    // 进位取整
    return Tuple2(valueLength, list);
  }

  Tuple2<int, List<String>> getPrintStringLengthByMaxLength(String str, int maxLength, FontStyle fontStyle) {
    int valueLength = 0;
    List<String> list = new List<String>();

    String tmpString = "";
    RegExp chinese = new RegExp(r"^[\u0391-\uFFE5]+$");
    // 获取字段值的长度，如果含中文字符，则每个中文字符长度为2，否则为1
    for (int i = 0; i < str.length; i++) {
      // 获取一个字符
      String temp = str[i].toString();
      // 判断是否为中文字符
      if (chinese.hasMatch(temp)) {
        switch (fontStyle) {
          case FontStyle.Normal:
          case FontStyle.DoubleHeight:
            valueLength += 2;
            break;
          case FontStyle.DoubleWidth:
          case FontStyle.DoubleWidthHeight:
            valueLength += 4;
            break;
          default:
            valueLength += 2;
            break;
        }
      } else {
        switch (fontStyle) {
          case FontStyle.Normal:
          case FontStyle.DoubleHeight:
            valueLength += 1;
            break;
          case FontStyle.DoubleWidth:
          case FontStyle.DoubleWidthHeight:
            valueLength += 2;
            break;
          default:
            valueLength += 1;
            break;
        }
      }

      tmpString += temp;

      if (valueLength >= maxLength) {
        list.add(tmpString);

        tmpString = "";

        valueLength = 0;
      }
    }

    if (StringUtils.isNotBlank(tmpString)) {
      list.add(tmpString);
    }

    // 进位取整
    return Tuple2(valueLength, list);
  }

  int getPrintStringLength(String str, FontStyle fontStyle) {
    int valueLength = 0;

    RegExp chinese = new RegExp(r"^[\u0391-\uFFE5]+$");
    // 获取字段值的长度，如果含中文字符，则每个中文字符长度为2，否则为1
    for (int i = 0; i < str.length; i++) {
      // 获取一个字符
      String temp = str[i].toString();
      // 判断是否为中文字符
      if (chinese.hasMatch(temp)) {
        switch (fontStyle) {
          case FontStyle.Normal:
          case FontStyle.DoubleHeight:
            valueLength += 2;
            break;
          case FontStyle.DoubleWidth:
          case FontStyle.DoubleWidthHeight:
            valueLength += 4;
            break;
          default:
            valueLength += 2;
            break;
        }
      } else {
        switch (fontStyle) {
          case FontStyle.Normal:
          case FontStyle.DoubleHeight:
            valueLength += 1;
            break;
          case FontStyle.DoubleWidth:
          case FontStyle.DoubleWidthHeight:
            valueLength += 2;
            break;
          default:
            valueLength += 1;
            break;
        }
      }
    }
    // 进位取整
    return valueLength;
  }

  String parseEscPosCommand(String command) {
    List<String> array = command.split(',');
    List<int> bytList = <int>[];
    for (var s in array) {
      if (StringUtils.isNotEmpty(s.trim())) {
        bytList.add(Convert.toInt(s.trim()));
      }
    }
    return gbk_bytes.decode(bytList);
  }

  String parseLineType(LineStyle lineStyle) {
    String line = " ";
    switch (lineStyle) {
      case LineStyle.NoPadding:
        {
          line = " ";
        }
        break;
      case LineStyle.StrikeThrough:
        {
          line = "-";
        }
        break;
      case LineStyle.DoubleLine:
        {
          line = "=";
        }
        break;
      case LineStyle.PunchLine:
        {
          line = "#";
        }
        break;
      case LineStyle.PlusLine:
        {
          line = "+";
        }
        break;
      case LineStyle.AsteriskLine:
        {
          line = "*";
        }
        break;
      case LineStyle.Underline:
        {
          line = "_";
        }
        break;
    }

    return line;
  }

  String parseFontStyle(FontStyle fontStyle, EscPosCommand command) {
    String result = parseEscPosCommand(command.normalCommand);
    switch (fontStyle) {
      case FontStyle.Normal:
        result = parseEscPosCommand(command.normalCommand);
        break;
      case FontStyle.DoubleWidth:
        result = parseEscPosCommand(command.doubleWidthCommand);
        break;
      case FontStyle.DoubleHeight:
        result = parseEscPosCommand(command.doubleHeightCommand);
        break;
      case FontStyle.DoubleWidthHeight:
        result = parseEscPosCommand(command.doubleWidthHeightCommand);
        break;
    }

    print("解析字体：${fontStyle.name},指令：");

    return result;
  }
}

class RowTemplate {
  //行数据格式
  RowFormat format;
  //数据模版
  dynamic template;

  RowTemplate();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "format": format.value,
      "template": this.template,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

//行打印模版，单行和两列控件依赖
class LineTemplate {
  //数据源
  String dataSourceKey;

  //字体格式
  FontStyle font;

  //填充线条，主要解决划线
  LineStyle line;

  //对齐格式
  AlignStyle align;

  //包含变量格式的内容
  String content;

  //字符串长度
  int length;

  LineTemplate();

  factory LineTemplate.fromJson(Map<String, dynamic> map) {
    return LineTemplate()
      ..dataSourceKey = Convert.toStr(map["data"])
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..line = LineStyle.fromValue(Convert.toStr(map["line"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
      ..content = Convert.toStr(map["content"])
      ..length = Convert.toInt(map["length"]);
  }

  ///转List集合
  static List<LineTemplate> toList(List<Map<String, dynamic>> lists) {
    var result = new List<LineTemplate>();
    lists.forEach((map) => result.add(LineTemplate.fromJson(map)));
    return result;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "data": this.dataSourceKey,
      "font": this.font.value,
      "line": this.line.value,
      "align": this.align.value,
      "content": this.content,
      "length": this.length,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class GridTemplate {
  //数据源
  String dataSourceKey;

  //表格包含的列
  List<ColumnTemplate> _columns = <ColumnTemplate>[];

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

  List<ColumnTemplate> get columns {
    return _columns;
  }

  GridTemplate();

  void addColumn(ColumnTemplate column) {
    this._columns.add(column);
  }

  factory GridTemplate.fromJson(Map<String, dynamic> map) {
    return GridTemplate()
      ..dataSourceKey = Convert.toStr(map["data"])
      .._columns = map["columns"] != null ? List<ColumnTemplate>.from(List<Map<String, dynamic>>.from(map["columns"]).map((x) => ColumnTemplate.fromJson(x))) : <ColumnTemplate>[]
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

class ColumnTemplate {
  int index;
  String name;
  AlignStyle align;
  String vars;
  int length;
  int width;
  int rowSeq;

  ColumnTemplate();

  factory ColumnTemplate.fromJson(Map<String, dynamic> map) {
    return ColumnTemplate()
      ..index = Convert.toInt(map["index"])
      ..name = Convert.toStr(map["name"])
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
      ..vars = Convert.toStr(map["vars"])
      ..width = Convert.toInt(map["width"])
      ..length = Convert.toInt(map["length"])
      ..rowSeq = Convert.toInt(map["rowSeq"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "index": this.index,
      "name": this.name,
      "align": this.align.value,
      "vars": this.vars,
      "length": this.length,
      "width": this.width,
      "rowSeq": rowSeq,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class BitmapTemplate {
  //数据源
  String dataSourceKey;

  //字体格式
  FontStyle font;

  //对齐格式
  AlignStyle align;

  //包含变量格式的内容
  String content;

  //字符串长度
  int length;

  BitmapTemplate();

  factory BitmapTemplate.fromJson(Map<String, dynamic> map) {
    return BitmapTemplate()
      ..dataSourceKey = Convert.toStr(map["data"])
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
      ..content = Convert.toStr(map["content"])
      ..length = Convert.toInt(map["length"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "data": this.dataSourceKey,
      "font": this.font.value,
      "align": this.align.value,
      "content": this.content,
      "length": this.length,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class BarcodeTemplate {
  //数据源
  String dataSourceKey;

  //字体格式
  FontStyle font;

  //对齐格式
  AlignStyle align;

  //包含变量格式的内容
  String content;

  //字符串长度
  int length;

  //是否显示条码标签
  bool showLable = false;

  //条码标签生成内容
  String lableContent;

  BarcodeTemplate();

  factory BarcodeTemplate.fromJson(Map<String, dynamic> map) {
    return BarcodeTemplate()
      ..dataSourceKey = Convert.toStr(map["data"])
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
      ..content = Convert.toStr(map["content"])
      ..showLable = Convert.toBool(map["showLable"])
      ..lableContent = Convert.toStr(map["lableContent"])
      ..length = Convert.toInt(map["length"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "data": this.dataSourceKey,
      "font": this.font.value,
      "align": this.align.value,
      "content": this.content,
      "length": this.length,
      "showLable": this.showLable.toString(),
      "lableContent": this.lableContent,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class QRCodeTemplate {
  //数据源
  String dataSourceKey;

  //字体格式
  FontStyle font;

  //对齐格式
  AlignStyle align;

  //包含变量格式的内容
  String content;

  //字符串长度
  int length;

  //二维码大小
  QRCodeSizeMode sizeMode;

  QRCodeTemplate();

  factory QRCodeTemplate.fromJson(Map<String, dynamic> map) {
    return QRCodeTemplate()
      ..dataSourceKey = Convert.toStr(map["data"])
      ..font = FontStyle.fromValue(Convert.toStr(map["font"]))
      ..align = AlignStyle.fromValue(Convert.toStr(map["align"]))
      ..content = Convert.toStr(map["content"])
      ..sizeMode = QRCodeSizeMode.fromValue(Convert.toStr(map["size"]))
      ..length = Convert.toInt(map["length"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "data": this.dataSourceKey,
      "font": this.font.value,
      "align": this.align.value,
      "content": this.content,
      "length": this.length,
      "sizeMode": this.sizeMode.value,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

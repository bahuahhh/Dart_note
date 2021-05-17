import 'package:qr_flutter/qr_flutter.dart';

///小票模版控件类型
class ControlType {
  final String name;
  final String value;

  const ControlType._(this.name, this.value);

  static const None = ControlType._("None", "0");
  static const SingleRowTemplate = ControlType._("单行模版", "1");
  static const GridTemplate = ControlType._("表格模版", "2");
  static const TwoColumnTemplate = ControlType._("两列模版", "3");
  static const BarcodeTemplate = ControlType._("条码模版", "4");
  static const QrcodeTemplate = ControlType._("二维码模版", "5");
  static const BitmapTemplate = ControlType._("位图模版", "6");

  factory ControlType.fromValue(String value) {
    switch (value) {
      case "1":
        {
          return ControlType.SingleRowTemplate;
        }
      case "2":
        {
          return ControlType.GridTemplate;
        }
      case "3":
        {
          return ControlType.TwoColumnTemplate;
        }
      case "4":
        {
          return ControlType.BarcodeTemplate;
        }
      case "5":
        {
          return ControlType.QrcodeTemplate;
        }
      case "6":
        {
          return ControlType.BitmapTemplate;
        }
      default:
        {
          return ControlType.None;
        }
    }
  }

  factory ControlType.fromName(String name) {
    switch (name) {
      case "单行模版":
        {
          return ControlType.SingleRowTemplate;
        }
      case "表格模版":
        {
          return ControlType.GridTemplate;
        }
      case "两列模版":
        {
          return ControlType.TwoColumnTemplate;
        }
      case "条码模版":
        {
          return ControlType.BarcodeTemplate;
        }
      case "二维码模版":
        {
          return ControlType.QrcodeTemplate;
        }
      case "位图模版":
        {
          return ControlType.BitmapTemplate;
        }
      default:
        {
          return ControlType.None;
        }
    }
  }
}

class LineStyle {
  final String name;
  final String value;

  const LineStyle._(this.name, this.value);

  static const NoPadding = LineStyle._("不填充", "0");
  static const StrikeThrough = LineStyle._("中划线", "1");
  static const DoubleLine = LineStyle._("双划线", "2");
  static const AsteriskLine = LineStyle._("星号线", "3");
  static const PunchLine = LineStyle._("井号线", "4");
  static const PlusLine = LineStyle._("加号线", "5");
  static const Underline = LineStyle._("下划线", "6");

  factory LineStyle.fromValue(String value) {
    switch (value) {
      case "1":
        {
          return LineStyle.StrikeThrough;
        }
      case "2":
        {
          return LineStyle.DoubleLine;
        }
      case "3":
        {
          return LineStyle.AsteriskLine;
        }
      case "4":
        {
          return LineStyle.PunchLine;
        }
      case "5":
        {
          return LineStyle.PlusLine;
        }
      case "6":
        {
          return LineStyle.Underline;
        }
      default:
        {
          return LineStyle.NoPadding;
        }
    }
  }

  factory LineStyle.fromName(String name) {
    switch (name) {
      case "中划线":
        {
          return LineStyle.StrikeThrough;
        }
      case "双划线":
        {
          return LineStyle.DoubleLine;
        }
      case "星号线":
        {
          return LineStyle.AsteriskLine;
        }
      case "井号线":
        {
          return LineStyle.PunchLine;
        }
      case "加号线":
        {
          return LineStyle.PlusLine;
        }
      case "下划线":
        {
          return LineStyle.Underline;
        }
      default:
        {
          return LineStyle.NoPadding;
        }
    }
  }
}

class RowFormat {
  final String name;
  final String value;

  const RowFormat._(this.name, this.value);

  static const None = RowFormat._("None", "0");
  static const Line = RowFormat._("Line", "1");
  static const Column = RowFormat._("Column", "2");
  static const Grid = RowFormat._("Grid", "3");
  static const Barcode = RowFormat._("Barcode", "4");
  static const QRCode = RowFormat._("QRCode", "5");
  static const Bitmap = RowFormat._("Bitmap", "6");

  factory RowFormat.fromValue(String value) {
    switch (value) {
      case "1":
        {
          return RowFormat.Line;
        }
      case "2":
        {
          return RowFormat.Column;
        }
      case "3":
        {
          return RowFormat.Grid;
        }
      case "4":
        {
          return RowFormat.Barcode;
        }
      case "5":
        {
          return RowFormat.QRCode;
        }
      case "6":
        {
          return RowFormat.Bitmap;
        }
      default:
        {
          return RowFormat.None;
        }
    }
  }

  factory RowFormat.fromName(String name) {
    switch (name) {
      case "Line":
        {
          return RowFormat.Line;
        }
      case "Column":
        {
          return RowFormat.Column;
        }
      case "Grid":
        {
          return RowFormat.Grid;
        }
      case "Barcode":
        {
          return RowFormat.Barcode;
        }
      case "QRCode":
        {
          return RowFormat.QRCode;
        }
      case "Bitmap":
        {
          return RowFormat.Bitmap;
        }
      default:
        {
          return RowFormat.None;
        }
    }
  }
}

class PagerType {
  final String name;
  final int value;

  const PagerType._(this.name, this.value);

  static const Line_58MM_32 = PagerType._("每行32个字符_58纸", 32);
  static const Line_76MM_40 = PagerType._("每行40个字符_76纸", 40);
  static const Line_80MM_42 = PagerType._("每行42个字符_80纸", 42);
  static const Line_80MM_44 = PagerType._("每行44个字符_80纸", 44);
  static const Line_80MM_48 = PagerType._("每行48个字符_80纸", 48);

  factory PagerType.fromValue(int value) {
    switch (value) {
      case 32:
        {
          return PagerType.Line_58MM_32;
        }
      case 40:
        {
          return PagerType.Line_76MM_40;
        }
      case 42:
        {
          return PagerType.Line_80MM_42;
        }
      case 44:
        {
          return PagerType.Line_80MM_44;
        }
      case 48:
        {
          return PagerType.Line_80MM_48;
        }
      default:
        {
          return PagerType.Line_80MM_48;
        }
    }
  }

  factory PagerType.fromName(String name) {
    switch (name) {
      case "每行32个字符_58纸":
        {
          return PagerType.Line_58MM_32;
        }
      case "每行40个字符_76纸":
        {
          return PagerType.Line_76MM_40;
        }
      case "每行42个字符_80纸":
        {
          return PagerType.Line_80MM_42;
        }
      case "每行44个字符_80纸":
        {
          return PagerType.Line_80MM_44;
        }
      case "每行48个字符_80纸":
        {
          return PagerType.Line_80MM_48;
        }
      default:
        {
          return PagerType.Line_80MM_48;
        }
    }
  }
}

class DataType {
  final String name;
  final String value;

  const DataType._(this.name, this.value);

  static const Simple = DataType._("Simple", "1");
  static const List = DataType._("List", "2");

  factory DataType.fromValue(String value) {
    switch (value) {
      case "1":
        {
          return DataType.Simple;
        }
      case "2":
        {
          return DataType.List;
        }
      default:
        {
          return DataType.Simple;
        }
    }
  }

  factory DataType.fromName(String name) {
    switch (name) {
      case "Simple":
        {
          return DataType.Simple;
        }
      case "List":
        {
          return DataType.List;
        }
      default:
        {
          return DataType.Simple;
        }
    }
  }
}

class FontStyle {
  final String name;
  final String value;

  const FontStyle._(this.name, this.value);

  static const Normal = FontStyle._("正常字体", "0");
  static const DoubleWidth = FontStyle._("倍宽字体", "1");
  static const DoubleHeight = FontStyle._("倍高字体", "2");
  static const DoubleWidthHeight = FontStyle._("倍宽倍高", "3");

  factory FontStyle.fromValue(String value) {
    switch (value) {
      case "0":
        {
          return FontStyle.Normal;
        }
      case "1":
        {
          return FontStyle.DoubleWidth;
        }
      case "2":
        {
          return FontStyle.DoubleHeight;
        }
      case "3":
        {
          return FontStyle.DoubleWidthHeight;
        }
      default:
        {
          return FontStyle.Normal;
        }
    }
  }

  factory FontStyle.fromName(String name) {
    switch (name) {
      case "正常字体":
        {
          return FontStyle.Normal;
        }
      case "倍宽字体":
        {
          return FontStyle.DoubleWidth;
        }
      case "倍高字体":
        {
          return FontStyle.DoubleHeight;
        }
      case "倍宽倍高":
        {
          return FontStyle.DoubleWidthHeight;
        }
      default:
        {
          return FontStyle.Normal;
        }
    }
  }
}

class AlignStyle {
  final String name;
  final String value;

  const AlignStyle._(this.name, this.value);

  static const Left = AlignStyle._("居左", "0");
  static const Center = AlignStyle._("居中", "1");
  static const Right = AlignStyle._("居右", "2");

  factory AlignStyle.fromValue(String value) {
    switch (value) {
      case "0":
        {
          return AlignStyle.Left;
        }
      case "1":
        {
          return AlignStyle.Center;
        }
      case "2":
        {
          return AlignStyle.Right;
        }
      default:
        {
          return AlignStyle.Left;
        }
    }
  }

  factory AlignStyle.fromName(String name) {
    switch (name) {
      case "居左":
        {
          return AlignStyle.Left;
        }
      case "居中":
        {
          return AlignStyle.Center;
        }
      case "居右":
        {
          return AlignStyle.Right;
        }
      default:
        {
          return AlignStyle.Left;
        }
    }
  }
}

class QRCodeSizeMode {
  final String name;
  final String value;

  const QRCodeSizeMode._(this.name, this.value);

  static const Default = QRCodeSizeMode._("默认", "1");
  static const Small = QRCodeSizeMode._("小图", "2");
  static const Bigger = QRCodeSizeMode._("大图", "3");

  factory QRCodeSizeMode.fromValue(String value) {
    switch (value) {
      case "1":
        {
          return QRCodeSizeMode.Default;
        }
      case "2":
        {
          return QRCodeSizeMode.Small;
        }
      case "3":
        {
          return QRCodeSizeMode.Bigger;
        }
      default:
        {
          return QRCodeSizeMode.Default;
        }
    }
  }

  factory QRCodeSizeMode.fromName(String name) {
    switch (name) {
      case "默认":
        {
          return QRCodeSizeMode.Default;
        }
      case "小图":
        {
          return QRCodeSizeMode.Small;
        }
      case "大图":
        {
          return QRCodeSizeMode.Bigger;
        }
      default:
        {
          return QRCodeSizeMode.Default;
        }
    }
  }
}

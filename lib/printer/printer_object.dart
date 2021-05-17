import 'package:estore_app/entity/pos_printer_item.dart';
import 'package:estore_app/enums/dynamic_library_enum.dart';
import 'package:estore_app/enums/print_port_enum.dart';
import 'package:estore_app/utils/converts.dart';

class PrinterObject {
  //串口
  static final String COM_PORT_NAME = "port";
  //串口波特率
  static final String COM_PORT_BAUD = "baud";
  //并口
  static final String LPT_NAME = "lpt";
  //USB口
  static final String USB_PID = "pid";
  static final String USB_VID = "vid";
  //网口的IP
  static final String NET_IP_ADDRESS = "ip";
  //驱动名称
  static final String DRIVE_NAME = "drive";

  PrinterObject() {
    this.id = "";
    this.name = "";
    this.dynamicLibrary = DynamicLibraryEnum.Common;
    this.portType = PortTypeEnum.None;

    this.pageWidth = 80;
    this.dpi = 203;

    var data = new Map<String, String>();

    data[COM_PORT_NAME] = "COM1";
    data[COM_PORT_BAUD] = "19200";
    data[LPT_NAME] = "LPT1";
    data[USB_PID] = "0";
    data[USB_VID] = "0";
    data[NET_IP_ADDRESS] = "127.0.0.1";
    data[DRIVE_NAME] = "None";

    this.data = data;

    this.escPosCommand = new EscPosCommand();
  }

  factory PrinterObject.fromPrinterItem(PrinterItem printer, {bool openCashbox = false}) {
    String vid = "0";
    String pid = "0";
    if (printer.port == "USB") {
      List<String> vidpid = printer.vidpid.split(",");
      vid = vidpid[0];
      pid = vidpid[1];
    }

    // if (printer.portOrDriver == 0)
    // {
    //   //端口
    //   pobject.PortType = (PortType)Enum.Parse(typeof(PortType), printer.Port);
    // }
    // else
    // {
    //   pobject.PortType = PortType.驱动;
    // }

    return PrinterObject()
      ..id = printer.id
      ..name = printer.name
      ..brandName = printer.brandName
      ..driverName = printer.driverName
      ..portType = PortTypeEnum.fromName(printer.port)
      ..dynamicLibrary = DynamicLibraryEnum.fromName(printer.dynamicLib)
      ..pageWidth = printer.pageWidth
      ..data[PrinterObject.COM_PORT_NAME] = printer.serialPort
      ..data[PrinterObject.COM_PORT_BAUD] = Convert.toStr(printer.baudRate)
      ..data[PrinterObject.LPT_NAME] = printer.parallelPort
      ..data[PrinterObject.DRIVE_NAME] = printer.driverName
      ..data[PrinterObject.NET_IP_ADDRESS] = printer.ipAddress
      ..data[PrinterObject.USB_VID] = vid
      ..data[PrinterObject.USB_PID] = pid
      ..escPosCommand.initCommand = printer.init
      ..escPosCommand.normalCommand = printer.normal
      ..escPosCommand.doubleHeightCommand = printer.doubleHeight
      ..escPosCommand.doubleWidthCommand = printer.doubleWidth
      ..escPosCommand.doubleWidthHeightCommand = printer.doubleWidthHeight
      ..escPosCommand.cutPageCommand = printer.cutPage
      ..escPosCommand.cashboxCommand = printer.cashbox
      ..escPosCommand.alignCenterCommand = printer.alignCenter
      ..escPosCommand.alignLeftCommand = printer.alignLeft
      ..escPosCommand.alignRightCommand = printer.alignLeft
      ..escPosCommand.beepCommand = printer.beep

      //回退行数
      ..escPosCommand.feedBackCommand = printer.feed
      ..feedBackRow = printer.backLines

      //条码、二维码、以图片打印条码二维码
      ..printBarcodeFlag = printer.printBarcodeFlag
      ..printBarcodeByImage = printer.printBarcodeByImage
      ..printQrcodeFlag = printer.printQrcodeFlag
      ..cutPager = (printer.cutType == "不切" ? false : true)
      ..beep = (printer.beepType == "不蜂鸣" ? false : true)
      ..openCashbox = openCashbox
      ..headerLines = printer.headerLines
      ..footerLines = printer.footerLines
      ..rotation = printer.rotation;
  }

  /// 打印机ID
  String id;

  /// 打印机名称
  String name;

  /// 打印机品牌型号
  String brandName;

  ///内置打印机，Android添加
  String driverName;

  /// 打印机接口类型
  PortTypeEnum portType;

  /// 打印机动态库支持
  DynamicLibraryEnum dynamicLibrary;

  /// 页宽
  int pageWidth;

  /// 打印机分辨率
  int dpi;

  /// 打印机参数配置
  Map<String, String> data;

  /// 打印机ESC/POS指令
  EscPosCommand escPosCommand;

  /// 自动切纸
  bool cutPager = false;

  /// 蜂鸣
  bool beep = false;

  /// 自动开钱箱
  bool openCashbox = false;

  /// 回退纸张行数
  int feedBackRow = 0;

  /// 顶部空白行
  int headerLines = 0;

  /// 底部空白行
  int footerLines = 0;

  /// 旋转角度
  int rotation = 0;

  /// 是否支持打印条码
  int printBarcodeFlag = 0;

  /// 是否支持打印二维码
  int printQrcodeFlag = 0;

  /// 使用图片方式打印条码
  int printBarcodeByImage = 0;
}

class EscPosCommand {
  EscPosCommand() {
    this.initCommand = "27,64";
    this.normalCommand = "27,33,2,28,33,2";
    this.doubleWidthCommand = "27,33,32,28,33,4";
    this.doubleHeightCommand = "27,33,16,28,33,8";
    this.doubleWidthHeightCommand = "27,33,48,28,33,12";

    this.cutPageCommand = "29,86,66";
    this.cashboxCommand = "27,112,0,48,192";

    this.alignLeftCommand = "27,97,48";
    this.alignCenterCommand = "27,97,49";
    this.alignRightCommand = "27,97,50";

    this.feedBackCommand = "27,101,n";

    this.beepCommand = "27,66";

    this.barcodeCommand = "29,107,m,n";
    this.barcodeHeightCommand = "29,104,n";
    this.barcodeLabelLocation = "29,72,n";

    this.qrcodeStoreData = "29,40,107,n,0,49,80,48";
    this.qrcodeSize = "29,40,107,3,0,49,67,n";
    this.qrcodeErrorCorrectionLevel = "29,40,107,3,0,49,69,n";
    this.qrcodePrint = "29,40,107,3,0,49,81,48";
  }

  /// 二维码打印
  String qrcodePrint;

  /// 二维码纠错等级  Set error correction level to M, (L, M, Q, H), default=L  n:L=48  M=49 Q=50 H=51
  String qrcodeErrorCorrectionLevel;

  /// 二维码size  (default n=3)
  String qrcodeSize;

  /// 二维码初始化Store the data in symbol storage area
  String qrcodeStoreData;

  /// 打印条码数字位置//n  0 不打印  1 条码上方  2 条码下方  3 上下都打印
  String barcodeLabelLocation;

  /// 打印条码指令
  String barcodeCommand;

  /// 条码高度 默认值 162
  String barcodeHeightCommand;

  /// 回退行数
  String feedBackCommand;

  /// 蜂鸣
  String beepCommand = "27,66";

  /// 左对齐
  String alignLeftCommand;

  /// 右对齐
  String alignCenterCommand;

  /// 右对齐
  String alignRightCommand;

  /// 初始化指令
  String initCommand;

  /// 倍宽字体指令
  String doubleWidthCommand;

  /// 切纸指令
  String cutPageCommand;

  /// 字体倍高指令
  String doubleHeightCommand;

  /// 普通字体指令
  String normalCommand;

  ///倍宽倍高指令
  String doubleWidthHeightCommand;

  ///钱箱指令
  String cashboxCommand;
}

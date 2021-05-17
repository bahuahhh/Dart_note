import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_printer_brand.dart';
import 'package:estore_app/entity/pos_printer_item.dart';
import 'package:estore_app/entity/pos_printer_ticket.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/printer/printer_constant.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:sprintf/sprintf.dart';

class PrinterBloc extends Bloc<PrinterEvent, PrinterState> {
  //打印机参数逻辑处理
  PrinterRepository _printerRepository;
  PrinterBloc() : super(PrinterState.init()) {
    this._printerRepository = new PrinterRepository();
  }

  @override
  Stream<PrinterState> mapEventToState(PrinterEvent event) async* {
    if (event is LoadPrinter) {
      yield* _mapLoadPrinterState(event);
    } else if (event is RefreshPrinter) {
      yield* _mapRefreshPrinterToState(event);
    } else if (event is SelectPrinter) {
      yield* _mapSelectPrinterToState(event);
    } else if (event is EditPrinter) {
      yield* _mapEditPrinterToState(event);
    } else if (event is SavePrinter) {
      yield* _mapSavePrinterToState(event);
    } else if (event is DeletePrinter) {
      yield* _mapDeletePrinterToState(event);
    } else if (event is PrinterParameter) {
      yield* _mapPrinterParameterToState(event);
    }
  }

  //添加或者编辑打印机
  Stream<PrinterState> _mapEditPrinterToState(EditPrinter event) async* {
    try {
      var printerId = event.printerId ?? "";
      //当前打印机
      PrinterItem currentPrinter;
      //支持的打印票据清单
      List<PrinterTicket> tickets = <PrinterTicket>[];
      //已选择的打印清单
      List<String> currentTicket = <String>[];
      //打印设备清单
      Map<String, dynamic> newDevices = {};

      //添加操作
      if (StringUtils.isBlank(printerId)) {
        currentPrinter = PrinterItem.newPrinterItem();
      } else {
        //编辑
        currentPrinter = PrinterItem.clone(state.currentPrinter);

        //支持的打印票据清单
        if (StringUtils.isNotBlank(currentPrinter.id)) {
          tickets = await this._printerRepository.getPrinterTicketList(currentPrinter.id);
        }

        tickets.forEach((item) {
          if (!currentTicket.contains(item.printTicket)) {
            currentTicket.add(item.printTicket);
          }
        });
      }

      yield state.copyWith(
        currentPrinter: currentPrinter,
        tickets: currentTicket,
        devices: newDevices,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("刷新打印机清单异常:" + e.toString());
    }
  }

  //刷新打印机状态数据
  Stream<PrinterState> _mapSelectPrinterToState(SelectPrinter event) async* {
    try {
      //加载打印机品牌清单
      var printers = await this._printerRepository.getPrinterItemList();
      //当前打印机
      PrinterItem currentPrinter = printers.firstWhere((item) => item.id == event.printerId);

      yield state.copyWith(
        currentPrinter: currentPrinter,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("选择打印机异常:" + e.toString());
    }
  }

  //刷新打印机状态数据
  Stream<PrinterState> _mapRefreshPrinterToState(RefreshPrinter event) async* {
    try {
      var printers = await this._printerRepository.getPrinterItemList();
      //当前打印机
      PrinterItem currentPrinter;
      if (printers != null && printers.length > 0) {
        if (StringUtils.isNotBlank(event.printerId)) {
          currentPrinter = printers.firstWhere((item) => item.id == event.printerId, orElse: null);
        }

        if (currentPrinter == null && printers != null && printers.length > 0) {
          //正在使用的打印机，选择第一个
          currentPrinter = PrinterItem.clone(printers[0]);
        }
      }

      yield state.copyWith(
        printers: printers,
        currentPrinter: currentPrinter,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("刷新打印机清单异常:" + e.toString());
    }
  }

  //加载数据
  Stream<PrinterState> _mapLoadPrinterState(LoadPrinter event) async* {
    try {
      //当前打印机
      PrinterItem currentPrinter;

      //加载打印机品牌清单
      var brands = await this._printerRepository.getPrinterBrandList();
      var printers = await this._printerRepository.getPrinterItemList();

      //是否有正在使用的打印机
      if (printers != null && printers.length > 0) {
        //正在使用的打印机，选择第一个
        currentPrinter = PrinterItem.clone(printers[0]);
      }

      yield state.copyWith(
        brands: brands,
        printers: printers,
        currentPrinter: currentPrinter,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载打印机清单异常:" + e.toString());
    }
  }

  Stream<PrinterState> _mapDeletePrinterToState(DeletePrinter event) async* {
    try {
      PrinterItem printer = event.printer;

      ///保存抹零参数配置
      var saveResult = await this._printerRepository.deletePrinterConfig(printer);
      if (saveResult.item1) {
        this.add(RefreshPrinter());
      }
    } catch (e, stack) {
      FLogger.error("加载抹零参数清单异常:" + e.toString());
    }
  }

  Stream<PrinterState> _mapSavePrinterToState(event) async* {
    try {
      PrinterItem printer = event.printer;

      List<String> tickets = event.tickets;

      ///保存抹零参数配置
      var saveResult = await this._printerRepository.savePrinterConfig(printer, tickets);
      if (saveResult.item1) {
        this.add(RefreshPrinter());
      }
    } catch (e, stack) {
      FLogger.error("加载抹零参数清单异常:" + e.toString());
    }
  }

  //选择打印机用途
  Stream<PrinterState> _mapPrinterParameterToState(PrinterParameter event) async* {
    try {
      //当前打印机
      PrinterItem newPrinterItem = PrinterItem.clone(state.currentPrinter);

      //打印机用途
      newPrinterItem.ticketType = event.ticketType ?? newPrinterItem.ticketType;
      newPrinterItem.name = "${newPrinterItem.ticketType}打印机";
      //打印机端口
      newPrinterItem.port = event.port ?? newPrinterItem.port;
      //打印机型号
      newPrinterItem.brandName = event.brandName ?? newPrinterItem.brandName;
      //USB口参数
      newPrinterItem.vidpid = event.vidpid ?? newPrinterItem.vidpid;
      //网口参数
      newPrinterItem.ipAddress = event.ipAddress ?? newPrinterItem.ipAddress;
      //打印纸宽度
      newPrinterItem.pageWidth = event.pageWidth ?? newPrinterItem.pageWidth;
      //切纸方式
      newPrinterItem.cutType = event.cutType ?? newPrinterItem.cutType;
      //顶部空白行
      newPrinterItem.headerLines = event.headerLines ?? newPrinterItem.headerLines;
      //底部空白行
      newPrinterItem.footerLines = event.footerLines ?? newPrinterItem.footerLines;
      //打印延迟
      newPrinterItem.delay = event.delay ?? newPrinterItem.delay;
      //打印机蜂鸣
      newPrinterItem.beepType = event.beepType ?? newPrinterItem.beepType;
      //支持条形码
      newPrinterItem.printBarcodeFlag = event.printBarcodeFlag ?? newPrinterItem.printBarcodeFlag;
      //支持二维码
      newPrinterItem.printQrcodeFlag = event.printQrcodeFlag ?? newPrinterItem.printQrcodeFlag;
      //内置打印机参数
      newPrinterItem.driverName = event.driverName ?? newPrinterItem.driverName;

      //当前打印机型号的默认参数
      if (StringUtils.isNotBlank(event.brandName)) {
        //加载打印机品牌清单
        var brands = await this._printerRepository.getPrinterBrandList();
        var newCurrentBrand = brands.firstWhere((item) => item.brandName == newPrinterItem.brandName, orElse: null);

        if (newCurrentBrand != null) {
          newPrinterItem.dynamicLib = newCurrentBrand.dynamicLib;
          newPrinterItem.type = newCurrentBrand.type;
          newPrinterItem.dpi = newCurrentBrand.dpi;
          newPrinterItem.baudRate = newCurrentBrand.baudRate;
          newPrinterItem.dataBit = newCurrentBrand.dataBit;
          newPrinterItem.init = newCurrentBrand.init;
          newPrinterItem.doubleWidth = newCurrentBrand.doubleWidth;
          newPrinterItem.cutPage = newCurrentBrand.cutPage;
          newPrinterItem.doubleHeight = newCurrentBrand.doubleHeight;
          newPrinterItem.normal = newCurrentBrand.normal;
          newPrinterItem.doubleWidthHeight = newCurrentBrand.doubleWidthHeight;
          newPrinterItem.cashbox = newCurrentBrand.cashbox;
          newPrinterItem.alignLeft = newCurrentBrand.alignLeft;
          newPrinterItem.alignCenter = newCurrentBrand.alignCenter;
          newPrinterItem.alignRight = newCurrentBrand.alignRight;
          newPrinterItem.feed = newCurrentBrand.feed;
          newPrinterItem.beep = newCurrentBrand.beep;
          newPrinterItem.backLines = newCurrentBrand.backLines;
          newPrinterItem.userDefined = newCurrentBrand.userDefined;
        }
      }

      print("参数修改，当前打印机:${newPrinterItem.toString()}");

      //打印的小票清单
      List<String> newTickets = (event.tickets != null && event.tickets.length > 0) ? List.from(event.tickets) : state.tickets;

      print("参数修改，小票清单:${newTickets.toString()}");

      //打印设备清单,主要是外置打印机使用，解决检索网口或者蓝牙打印机过程中，保留之前的参数
      Map<String, dynamic> newDevices = (event.devices != null) ? Map.from(event.devices) : state.devices;
      if (newPrinterItem.brandName == PrinterModelEunm.Normal.name) {
        switch (newPrinterItem.port) {
          case "蓝牙":
            {}
            break;
          case "网口":
            {
              var key = newPrinterItem.ipAddress;
              newDevices[key] = newPrinterItem.ipAddress;
            }
            break;
        }
      }
      yield state.copyWith(
        currentPrinter: newPrinterItem,
        tickets: newTickets,
        devices: newDevices,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("打印机参数更改发生异常:" + e.toString());
    }
  }
}

abstract class PrinterEvent extends Equatable {
  const PrinterEvent();
}

///加载正在使用的打印机数据
class LoadPrinter extends PrinterEvent {
  @override
  List<Object> get props => [];
}

///刷新打印机清单
class RefreshPrinter extends PrinterEvent {
  //切换正在使用的打印机
  final String printerId;

  RefreshPrinter({this.printerId});

  @override
  List<Object> get props => [this.printerId];
}

///选择打印机
class SelectPrinter extends PrinterEvent {
  //切换正在使用的打印机
  final String printerId;

  SelectPrinter({this.printerId});

  @override
  List<Object> get props => [this.printerId];
}

///选添加/编辑打印机
class EditPrinter extends PrinterEvent {
  //切换正在使用的打印机
  final String printerId;

  EditPrinter({this.printerId});

  @override
  List<Object> get props => [this.printerId];
}

///用户更改选择参数
class PrinterParameter extends PrinterEvent {
  final String brandName;
  final String ticketType;
  final String port;
  final int pageWidth;
  final String cutType;

  final int headerLines;
  final int footerLines;
  final int delay;

  final String beepType;
  final int printBarcodeFlag;
  final int printQrcodeFlag;
  final int printBarcodeByImage;

  //USB三个参数:vid,pid,deviceId,productName
  final String vidpid;

  final String ipAddress;

  //内置打印机型号
  final String driverName;

  //关联的单据
  final List<String> tickets;

  //打印设备
  final Map<String, dynamic> devices;

  PrinterParameter({
    this.brandName,
    this.ticketType,
    this.port,
    this.pageWidth,
    this.cutType,
    this.headerLines,
    this.footerLines,
    this.delay,
    this.beepType,
    this.printBarcodeFlag,
    this.printQrcodeFlag,
    this.printBarcodeByImage,
    this.vidpid,
    this.ipAddress,
    this.driverName,
    this.tickets,
    this.devices,
  });

  @override
  List<Object> get props => [
        this.brandName,
        this.ticketType,
        this.port,
        this.pageWidth,
        this.cutType,
        this.headerLines,
        this.footerLines,
        this.delay,
        this.beepType,
        this.printBarcodeFlag,
        this.printQrcodeFlag,
        this.printBarcodeByImage,
        this.vidpid,
        this.tickets,
        this.devices,
        this.ipAddress,
        this.driverName,
      ];
}

///加载设备数据
class SavePrinter extends PrinterEvent {
  final PrinterItem printer;
  final List<String> tickets;

  SavePrinter(this.printer, this.tickets);

  @override
  List<Object> get props => [this.printer, this.tickets];
}

///加载设备数据
class DeletePrinter extends PrinterEvent {
  final PrinterItem printer;

  DeletePrinter(this.printer);

  @override
  List<Object> get props => [this.printer];
}

class PrinterState extends Equatable {
  //打印机品牌清单
  final List<PrinterBrand> brands;
  //当前打印机型号
  final PrinterBrand currentBrand;
  //已经定义的打印机清单
  final List<PrinterItem> printers;
  //当前打印机
  final PrinterItem currentPrinter;
  //打印机关联的小票
  final List<String> tickets;
  //USB端口的打印机列表
  final Map<String, dynamic> devices;

  const PrinterState({
    this.brands,
    this.currentBrand,
    this.printers,
    this.currentPrinter,
    this.tickets,
    this.devices,
  });

  ///初始化
  factory PrinterState.init() {
    return PrinterState(
      brands: <PrinterBrand>[],
      currentBrand: null,
      printers: <PrinterItem>[],
      currentPrinter: PrinterItem.newPrinterItem(),
      tickets: <String>[],
      devices: {},
    );
  }

  PrinterState copyWith({
    List<PrinterBrand> brands,
    PrinterBrand currentBrand,
    List<PrinterItem> printers,
    PrinterItem currentPrinter,
    List<String> tickets,
    Map<String, dynamic> devices,
  }) {
    return PrinterState(
      brands: brands ?? this.brands,
      currentBrand: currentBrand ?? this.currentBrand,
      printers: printers ?? this.printers,
      currentPrinter: currentPrinter ?? this.currentPrinter,
      tickets: tickets ?? this.tickets,
      devices: devices ?? this.devices,
    );
  }

  @override
  List<Object> get props => [this.brands, this.currentBrand, this.printers, this.currentPrinter, this.tickets, this.devices];
}

class PrinterRepository {
  ///获取打印机品牌列表
  Future<List<PrinterBrand>> getPrinterBrandList() async {
    List<PrinterBrand> result = <PrinterBrand>[];
    try {
      String sql = sprintf("select * from pos_printer_brand;", []);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      if (lists != null) {
        result = PrinterBrand.toList(lists);
      }
    } catch (e, stack) {
      FLogger.error("获取打印机品牌发生异常:" + e.toString());
    }
    return result;
  }

  ///获取正在使用的打印机列表
  Future<List<PrinterItem>> getPrinterItemList() async {
    List<PrinterItem> result = <PrinterItem>[];
    try {
      String sql = sprintf("select * from pos_printer_item order by createDate desc;", []);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      if (lists != null && lists.length > 0) {
        result = PrinterItem.toList(lists);
      }
    } catch (e, stack) {
      FLogger.error("获取正在使用打印机清单发生异常:" + e.toString());
    }
    return result;
  }

  ///获取正在使用的打印机列表
  Future<List<PrinterTicket>> getPrinterTicketList(String printerId) async {
    List<PrinterTicket> result = <PrinterTicket>[];
    try {
      String sql = "select * from pos_printer_ticket where printerId = '$printerId';";
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      if (lists != null) {
        result = PrinterTicket.toList(lists);
      }
    } catch (e, stack) {
      FLogger.error("获取正在使用打印机清单发生异常:" + e.toString());
    }
    return result;
  }

  ///获取系统抹零设置配置参数
  Future<Tuple2<bool, String>> deletePrinterConfig(PrinterItem printer) async {
    bool result = true;
    String message = "参数删除成功";
    try {
      var queues = new Queue<String>();
      queues.add("delete from pos_printer_item where id = '${printer.id}'");
      queues.add("delete from pos_printer_ticket where printerId = '${printer.id}'");
      var database = await SqlUtils.instance.open();
      await database.transaction((txn) async {
        try {
          var batch = txn.batch();
          queues.forEach((obj) {
            batch.rawInsert(obj);
          });
          await batch.commit(noResult: false);
        } catch (e) {
          FLogger.error("删除打印机参数异常:" + e.toString());
        }
      });
    } catch (e, stack) {
      result = false;
      message = "参数更新异常";
      FLogger.error("获取POS功能模块发生异常:" + e.toString());
    }
    return Tuple2<bool, String>(result, message);
  }

  ///获取系统抹零设置配置参数
  Future<Tuple2<bool, String>> savePrinterConfig(PrinterItem printer, List<String> tickets) async {
    bool result = true;
    String message = "参数更新成功";
    try {
      var queues = new Queue<String>();
      if (StringUtils.isNotEmpty(printer.id)) {
        queues.add("delete from pos_printer_item where id = '${printer.id}'");
        queues.add("delete from pos_printer_ticket where printerId = '${printer.id}'");
      }

      String printerId = IdWorkerUtils.getInstance().generate().toString();
      //是否启用抹零的SQL
      String printerItemTemplate =
          "insert into pos_printer_item (id, tenantId, brandId, brandName, ticketType, name, dynamic, type, port, portOrDriver, pageWidth, cutType, beepType, dpi, serialPort, baudRate, dataBit, parallelPort, ipAddress,vidpid, driverName, init, doubleWidth, cutPage, doubleHeight, normal, doubleWidthHeight, cashbox, alignLeft, alignCenter, alignRight, feed, beep, headerLines, footerLines, backLines, delay, rotation, userDefined, status, statusDesc, memo, ext1, ext2, ext3, createDate, createUser, printBarcodeFlag, printQrcodeFlag, printBarcodeByImage, posNo) values ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s',  '%s',  '%s', '%s', '%s', '%s');";
      var printerItemSql = sprintf(printerItemTemplate, [
        printerId,
        Global.instance.authc.tenantId,
        printer.brandId,
        printer.brandName,
        printer.ticketType,
        printer.name,
        printer.dynamicLib,
        printer.type,
        printer.port,
        printer.portOrDriver,
        printer.pageWidth,
        printer.cutType,
        printer.beepType,
        printer.dpi,
        printer.serialPort,
        printer.baudRate,
        printer.dataBit,
        printer.parallelPort,
        printer.ipAddress,
        printer.vidpid,
        printer.driverName,
        printer.init,
        printer.doubleWidth,
        printer.cutPage,
        printer.doubleHeight,
        printer.normal,
        printer.doubleWidthHeight,
        printer.cashbox,
        printer.alignLeft,
        printer.alignCenter,
        printer.alignRight,
        printer.feed,
        printer.beep,
        printer.headerLines,
        printer.footerLines,
        printer.backLines,
        printer.delay,
        printer.rotation,
        printer.userDefined,
        printer.status,
        printer.statusDesc,
        printer.memo,
        printer.ext1,
        printer.ext2,
        printer.ext3,
        DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
        Constants.DEFAULT_CREATE_USER,
        printer.printBarcodeFlag,
        printer.printBarcodeFlag,
        printer.printBarcodeByImage,
        printer.posNo,
      ]);
      queues.add(printerItemSql);

      if (tickets.length > 0) {
        String prefixSql = "insert into pos_printer_ticket (id, tenantId, printTicket, copies, printerId, printerName, printerType, orderType, memo, ext1, ext2, ext3, createDate, createUser, planId) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        tickets.forEach((ticket) {
          var sql = sprintf(template, [
            IdWorkerUtils.getInstance().generate().toString(),
            Global.instance.authc.tenantId,
            ticket,
            1,
            printerId,
            printer.name,
            "",
            "",
            "",
            "",
            "",
            "",
            DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
            Constants.DEFAULT_CREATE_USER,
            "",
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        queues.add(sqlString);
      }

      var database = await SqlUtils.instance.open();
      await database.transaction((txn) async {
        try {
          var batch = txn.batch();
          queues.forEach((obj) {
            batch.rawInsert(obj);
          });
          await batch.commit(noResult: false);
        } catch (e) {
          FLogger.error("保存打印机参数异常:" + e.toString());
        }
      });
    } catch (e, stack) {
      result = false;
      message = "参数更新异常";
      FLogger.error("获取POS功能模块发生异常:" + e.toString());
    }
    return Tuple2<bool, String>(result, message);
  }
}

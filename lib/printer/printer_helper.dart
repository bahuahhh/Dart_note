import 'dart:async';
import 'dart:convert';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_extensions/dart_extensions.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_print_img.dart';
import 'package:estore_app/entity/pos_printer_item.dart';
import 'package:estore_app/entity/pos_printer_ticket.dart';
import 'package:estore_app/entity/pos_shiftover_ticket.dart';
import 'package:estore_app/enums/order_item_row_type.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/enums/print_ticket_enum.dart';
import 'package:estore_app/enums/promotion_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/member/member.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/printer/plugins/sumni_printer_plugin.dart';
import 'package:estore_app/printer/printer_constant.dart';
import 'package:estore_app/printer/printer_network_manager.dart';
import 'package:estore_app/printer/printer_object.dart';
import 'package:estore_app/printer/printer_result.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/file_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:gbk_codec/gbk_codec.dart';
import 'package:image/image.dart';
import 'package:sprintf/sprintf.dart';

import 'designer/print_content.dart';
import 'designer/print_designer_surface.dart';
import 'designer/print_enums.dart';
import 'designer/print_template.dart';
import 'designer/print_variable_value.dart';

class PrinterHelper {
  PrinterHelper._();

  static Future<PrinterResult> printTest(PrinterItem printerItem) async {
    PrinterResult result = PrinterResult.success;

    //以结账单为测试目标
    PrintTicketEnum ticket = PrintTicketEnum.Statement;
    //获取打印机对象
    PrinterObject pobject = PrinterObject.fromPrinterItem(printerItem);
    //获取打印小票模版
    var templateContent = await getTemplateContent(ticket, pobject);
    if (templateContent.item1) {
      String content = templateContent.item2;
      //小票模版有效
      if (StringUtils.isNotEmpty(content)) {
        var json = convert.jsonDecode(content);
        PrintDesignerSurface surface = PrintDesignerSurface.fromJson(json);
        //构建小票变量
        List<PrintVariableValue> args = await _builderTicketVariable(OrderObject.newOrderObject());
        result = await doPrint(pobject, args, surface);
      } else {
        result = PrinterResult.ticketEmpty;
      }
    } else {
      result = PrinterResult.ticketEmpty;
    }

    return Future.value(result);
  }

  //获取下票模版内容
  static Future<Tuple2<bool, String>> getTemplateContent(PrintTicketEnum ticket, PrinterObject pobject) async {
    bool success = false;
    String content = "";
    try {
      String basePath = "${Constants.TEMPLATE_PRINTER_PATH}";
      bool directoryExist = await FileUtils.isDirectoryExist(basePath);
      if (!directoryExist) {
        await FileUtils.createDirectory(basePath);
      }
      String fullPath = "$basePath/${ticket.name}_${Global.instance.authc.tenantId ?? ""}_${pobject.pageWidth}.designer";
      File template = File("$fullPath");
      bool fileExist = await template.exists();

      if (fileExist) {
        //获取自定义小票的内容
        content = await template.readAsString();
      } else {
        //获取内置默认小票内容
        content = await rootBundle.loadString("assets/template/printer/${ticket.name}_通用模版_${pobject.pageWidth}.designer");
      }

      success = true;
    } catch (e, stack) {
      success = false;
      FlutterChain.printError(e, stack);
      FLogger.error("加载小票模版异常:" + e.toString());
    }

    return Tuple2(success, content);
  }

  ///重打印小票
  static Future<void> reprintTicket(OrderObject orderObject) async {
    if (orderObject == null) return;

    switch (orderObject.orderSource) {
      default:
        {
          //补打收银/微店订单小票
          orderObject.reprint = true;

          var printerTicketList = await getPrinterTicketType();
          // if (printerTicketList != null) {
          //   printTicket(printerTicketList[0], orderObject);
          // } else {
          //   printCheckoutTicket(PrintTicketEnum.Statement, orderObject);
          // }

          printCheckoutTicket(PrintTicketEnum.Statement, orderObject);

          // if (printerTicketList != null && printerTicketList.length > 1)
          // {
          //   //选择打印类型
          //   //OpenSelectPrintType(orderObject, printerTicketList);
          // }

        }
        break;
    }
  }

  /// 获取打印类型,比较小票、厨打、标签
  static Future<List<PrinterTicket>> getPrinterTicketType() async {
    List<PrinterTicket> result = <PrinterTicket>[];
    try {
      String sql = "SELECT ppt.*,ppi.* FROM `pos_printer_ticket` ppt  LEFT JOIN `pos_printer_item` ppi ON ppt.`printerId` = ppi.`id` WHERE ppi.id != '' and ppi.posNo = '${Global.instance.authc.posNo}'";
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);
      var printerTicketList = PrinterTicket.toList(lists);

      //过滤收银小票、厨打单、出品单.....
      List<PrinterTicket> newPrinterTicketList = printerTicketList.where((x) => x.printTicket == PrintTicketEnum.Statement.name).toList();
      //
      result.addAll(newPrinterTicketList);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取可打印类型发生异常:" + e.toString());
    }

    return result;
  }

  static Future<PrinterResult> printTicket(PrintTicketEnum ticket, PrinterObject pobject, List<PrintVariableValue> args, String busNo) async {
    PrinterResult result = PrinterResult.success;
    try {
      //获取打印小票模版
      var templateContent = await getTemplateContent(ticket, pobject);

      if (templateContent.item1) {
        String content = templateContent.item2;
        //小票模版有效
        if (StringUtils.isNotEmpty(content)) {
          var json = convert.jsonDecode(content);
          PrintDesignerSurface surface = PrintDesignerSurface.fromJson(json);

          result = await doPrint(pobject, args, surface);
        } else {
          result = PrinterResult.ticketEmpty;
        }
      } else {
        result = PrinterResult.ticketEmpty;
      }
    } catch (e, stack) {
      result = PrinterResult.ticketEmpty;
      FlutterChain.printError(e, stack);
      FLogger.error("打印单据$busNo信息异常:" + e.toString());
    }

    return Future.value(result);
  }

  static Future<PrinterResult> doPrint(PrinterObject pobject, List<PrintVariableValue> args, PrintDesignerSurface surface) async {
    PrinterResult result = PrinterResult.success;
    try {
      //解析打印内容
      PrintTemplate printer = surface.parse(args);
      List<PrintContent> pcontent = printer.parseEx(pobject, args);

      //打印机型号
      var printerModel = PrinterModelEunm.fromName("${pobject.brandName}");
      switch (printerModel) {
        case PrinterModelEunm.Normal:
          {
            var port = PrinterPortEunm.fromName("${pobject.portType}");
            switch (port) {
              case PrinterPortEunm.Network:
                {
                  List<int> bytes = [];
                  for (var p in pcontent) {
                    switch (p.format) {
                      case RowFormat.Barcode:
                      case RowFormat.Bitmap:
                        {
                          if (p.content != null && StringUtils.isNotBlank(p.content.toString())) {
                            String content = "${p.content.toString()}\n";
                            bytes += gbk_bytes.encode(content);
                          }

                          File template = File("${p.bitmapFile}");
                          bool fileExist = await template.exists();
                          if (fileExist) {
                            final Uint8List _bytes = template.readAsBytesSync();
                            final Image img = decodeImage(_bytes);

                            bytes += _image(img);
                          }
                        }
                        break;
                      default:
                        {
                          String content = "${p.content.toString()}\n";
                          bytes += gbk_bytes.encode(content);
                        }
                        break;
                    }
                  }
                  var ipAddress = "${pobject.data[PrinterObject.NET_IP_ADDRESS]}";
                  print("连接网络打印机:$ipAddress:9100");
                  final PrinterNetworkManager printerManager = PrinterNetworkManager();
                  printerManager.selectPrinter("$ipAddress", port: 9100);

                  result = await printerManager.printTicket(bytes);
                }
                break;
              case PrinterPortEunm.Bluetooth:
                {}
                break;
            }
          }
          break;
        case PrinterModelEunm.Embed:
          {
            var driverName = PrinterEmbedEunm.fromName("${pobject.driverName}");

            switch (driverName) {
              case PrinterEmbedEunm.SunmiV1:
              case PrinterEmbedEunm.SunmiV2:
                {
                  SunmiPrinterPlugin.instance.init();
                  List<int> bytes = [];
                  for (var p in pcontent) {
                    switch (p.format) {
                      case RowFormat.Barcode:
                      case RowFormat.QRCode:
                      case RowFormat.Bitmap:
                        {
                          File template = File("${p.bitmapFile}");
                          bool fileExist = await template.exists();
                          if (fileExist) {
                            final Uint8List _bytes = template.readAsBytesSync();
                            final Image img = decodeImage(_bytes);

                            bytes += _image(img);
                          }

                          if (p.content != null && StringUtils.isNotBlank(p.content.toString())) {
                            String content = "${p.content.toString()}\n";
                            bytes += gbk_bytes.encode(content);
                          }
                        }
                        break;
                      default:
                        {
                          String content = "${p.content.toString()}\n";
                          bytes += gbk_bytes.encode(content);
                        }
                        break;
                    }
                  }
                  SunmiPrinterPlugin.instance.printRawData(bytes);
                }
                break;
            }
          }
          break;
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("打印发生异常:" + e.toString());
    }

    return Future.value(result);
  }

  // static Future<Tuple2<bool, String>> printContent(PrinterObject pobject, List<PrintContent> content) async {
  //   bool result = true;
  //   String message = "打印成功";
  //   try {
  //     print(">>>>>>>>${pobject.data}");
  //
  //     switch (pobject.brandName) {
  //       case "内置打印机":
  //         {
  //           //内置打印机型号
  //           var driverName = pobject.data[PrinterObject.DRIVE_NAME];
  //         }
  //         break;
  //       default:
  //         {
  //           switch (pobject.portType.name) {
  //             case "网口":
  //               {
  //                 final PrinterNetworkManager printerManager = PrinterNetworkManager();
  //                 printerManager.selectPrinter("${pobject.data[PrinterObject.NET_IP_ADDRESS]}", port: 9100);
  //
  //                 List<int> bytes = [];
  //                 for (var p in content) {
  //                   switch (p.format) {
  //                     case RowFormat.Barcode:
  //                     case RowFormat.Bitmap:
  //                       {
  //                         if (p.content != null && StringUtils.isNotBlank(p.content.toString())) {
  //                           String content = "${p.content.toString()}\n";
  //                           bytes += gbk_bytes.encode(content);
  //                         }
  //
  //                         File template = File("${p.bitmapFile}");
  //                         bool fileExist = await template.exists();
  //                         if (fileExist) {
  //                           final Uint8List _bytes = template.readAsBytesSync();
  //                           final Image img = decodeImage(_bytes);
  //
  //                           bytes += _image(img);
  //                         }
  //                       }
  //                       break;
  //                     default:
  //                       {
  //                         String content = "${p.content.toString()}\n";
  //                         bytes += gbk_bytes.encode(content);
  //                       }
  //                       break;
  //                   }
  //                 }
  //
  //                 await printerManager.printTicket(bytes);
  //               }
  //               break;
  //           }
  //         }
  //         break;
  //     }
  //   } catch (e, stack) {
  //     result = false;
  //     message = "打印出错";
  //
  //     FlutterChain.printError(e, stack);
  //     FLogger.error("打印发生异常:" + e.toString());
  //   }
  //
  //   return Future.value(Tuple2(result, message));
  // }

  static List<int> _image(Image imgSrc) {
    final Image image = Image.from(imgSrc); // make a copy
    const bool highDensityHorizontal = true;
    const bool highDensityVertical = true;

    invert(image);
    flip(image, Flip.horizontal);
    final Image imageRotated = copyRotate(image, 270);

    const int lineHeight = highDensityVertical ? 3 : 1;
    final List<List<int>> blobs = _toColumnFormat(imageRotated, lineHeight * 8);

    // Compress according to line density
    // Line height contains 8 or 24 pixels of src image
    // Each blobs[i] contains greyscale bytes [0-255]
    // const int pxPerLine = 24 ~/ lineHeight;
    for (int blobInd = 0; blobInd < blobs.length; blobInd++) {
      blobs[blobInd] = _packBitsIntoBytes(blobs[blobInd]);
    }

    final int heightPx = imageRotated.height;
    const int densityByte = (highDensityHorizontal ? 1 : 0) + (highDensityVertical ? 32 : 0);

    final List<int> header = List.from("\x1B*".codeUnits);
    header.add(densityByte);
    header.addAll(_intLowHigh(heightPx, 2));

    List<int> bytes = [];

    // Adjust line spacing (for 16-unit line feeds): ESC 3 0x10 (HEX: 0x1b 0x33 0x10)
    bytes += [27, 51, 16];
    for (int i = 0; i < blobs.length; ++i) {
      bytes += List.from(header)..addAll(blobs[i])..addAll('\n'.codeUnits);
    }
    // Reset line spacing: ESC 2 (HEX: 0x1b 0x32)
    bytes += [27, 50];

    return bytes;
  }

  /// Merges each 8 values (bits) into one byte
  static List<int> _packBitsIntoBytes(List<int> bytes) {
    const pxPerLine = 8;
    final List<int> res = <int>[];
    const threshold = 127; // set the greyscale -> b/w threshold here
    for (int i = 0; i < bytes.length; i += pxPerLine) {
      int newVal = 0;
      for (int j = 0; j < pxPerLine; j++) {
        newVal = _transformUint32Bool(
          newVal,
          pxPerLine - j,
          bytes[i + j] > threshold,
        );
      }
      res.add(newVal ~/ 2);
    }
    return res;
  }

  /// Replaces a single bit in a 32-bit unsigned integer.
  static int _transformUint32Bool(int uint32, int shift, bool newValue) {
    return ((0xFFFFFFFF ^ (0x1 << shift)) & uint32) | ((newValue ? 1 : 0) << shift);
  }

  /// Generate multiple bytes for a number: In lower and higher parts, or more parts as needed.
  ///
  /// [value] Input number
  /// [bytesNb] The number of bytes to output (1 - 4)
  static List<int> _intLowHigh(int value, int bytesNb) {
    final dynamic maxInput = 256 << (bytesNb * 8) - 1;

    if (bytesNb < 1 || bytesNb > 4) {
      throw Exception('Can only output 1-4 bytes');
    }
    if (value < 0 || value > maxInput) {
      throw Exception('Number too large. Can only output up to $maxInput in $bytesNb bytes');
    }

    final List<int> res = <int>[];
    int buf = value;
    for (int i = 0; i < bytesNb; ++i) {
      res.add(buf % 256);
      buf = buf ~/ 256;
    }
    return res;
  }

  /// Extract slices of an image as equal-sized blobs of column-format data.
  ///
  /// [image] Image to extract from
  /// [lineHeight] Printed line height in dots
  static List<List<int>> _toColumnFormat(Image imgSrc, int lineHeight) {
    final Image image = Image.from(imgSrc); // make a copy

    // Determine new width: closest integer that is divisible by lineHeight
    final int widthPx = (image.width + lineHeight) - (image.width % lineHeight);
    final int heightPx = image.height;

    // Create a black bottom layer
    final biggerImage = copyResize(image, width: widthPx, height: heightPx);
    fill(biggerImage, 0);
    // Insert source image into bigger one
    drawImage(biggerImage, image, dstX: 0, dstY: 0);

    int left = 0;
    final List<List<int>> blobs = [];

    while (left < widthPx) {
      final Image slice = copyCrop(biggerImage, left, 0, lineHeight, heightPx);
      final Uint8List bytes = slice.getBytes(format: Format.luminance);
      blobs.add(bytes);
      left += lineHeight;
    }

    return blobs;
  }

  static Future<void> printCheckoutTicket(PrintTicketEnum ticket, OrderObject orderObject) async {
    try {
      //加载当前结账单的打印列表
      var tickets = await getPrinterTicket(ticket);

      if (tickets != null && tickets.length > 0) {
        //不允许现金和银行卡以外方式打开钱箱
        // if (orderObject.pays.Exists(x => x.No == "01" || x.No == "03") && !orderObject.rep)
        // {
        //   OpenCashBox();
        // }
        // //判断是否打印销售单开关
        // var enableTicketPrint = Global.Instance.GlobalConfigBoolValue(ConfigConstant.TICKETPRINT_ENABLE, true);
        // if (!enableTicketPrint)
        // {
        //   logger.Info("打印销售单开关关闭，忽略本次打印");
        //   return;
        // }

        for (var p in tickets) {
          if (p.copies == 0) {
            FLogger.warn("结账单打印份数设置为[0]，忽略本次打印");
            continue;
          }

          var pobject = await convertPrinterObject(p, openCashbox: false);
          if (pobject != null) {
            //打印份数
            for (int i = 0; i < p.copies; i++) {
              var args = await _builderTicketVariable(orderObject);
              await printTicket(ticket, pobject, args, orderObject.tradeNo);
            }
          } else {
            FLogger.warn("打印机转换失败，忽略本次打印");
          }
        }
      } else {
        FLogger.warn("结账单打印机没有配置，忽略本次打印");
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("打印结账单发生异常:" + e.toString());
    }
  }

  //构建结账单打印变量
  static Future<List<PrintVariableValue>> _builderTicketVariable(OrderObject orderObject) async {
    var result = new List<PrintVariableValue>();
    try {
      var v = new PrintVariableValue();
      v.key = "默认数据源";
      v.type = DataType.Simple;

      var data = new Map<String, String>();

      var ticketsNumberEnable = false; //Global.Instance.GlobalConfigBoolValue(ConfigConstant.TICKETS_NUMBER_ENABLE, false);
      if (ticketsNumberEnable) {
        data["@序号@"] = orderObject.orderNo;
        data["@是否打印序号@"] = "true";
      } else {
        data["@是否打印序号@"] = "false";
      }
      var tradeNo = orderObject.tradeNo;
      data["@票号@"] = tradeNo;

      //获取小票图片的路径
      List<PrintImg> printImg = await getPrintImg();
      if (printImg != null && printImg.length > 0) {
        var firstPrintImg = printImg.firstWhere((x) => x.type == 1, orElse: () => null);
        if (firstPrintImg != null && StringUtils.isNotBlank(firstPrintImg.storageAddress) && firstPrintImg.storageAddress.contains("/")) {
          String pictureName = firstPrintImg.storageAddress.substring(firstPrintImg.storageAddress.lastIndexOf('/') + 1);
          var picturePath = "${Constants.PRINTER_IMAGE_PATH}/$pictureName";
          bool exists = File("$picturePath").existsSync();
          if (exists) {
            data["@票头图片@"] = picturePath;
            data["@票头图片说明@"] = firstPrintImg.description;
            data["@是否打印票头图片@"] = "true";
          } else {
            data["@是否打印票头图片@"] = "false";
          }
        } else {
          data["@是否打印票头图片@"] = "false";
        }
        var endPrintImg = printImg.firstWhere((x) => x.type == 2, orElse: () => null);
        if (endPrintImg != null && StringUtils.isNotBlank(endPrintImg.storageAddress) && endPrintImg.storageAddress.contains("/")) {
          String pictureName = endPrintImg.storageAddress.substring(endPrintImg.storageAddress.lastIndexOf('/') + 1);
          var picturePath = "${Constants.PRINTER_IMAGE_PATH}/$pictureName";
          bool exists = File("$picturePath").existsSync();
          if (exists) {
            data["@票尾图片@"] = picturePath;
            data["@票尾图片说明@"] = endPrintImg.description;
            data["@是否打印票尾图片@"] = "true";
          } else {
            data["@是否打印票尾图片@"] = "false";
          }
        } else {
          data["@是否打印票尾图片@"] = "false";
        }
      } else {
        data["@是否打印票头图片@"] = "false";
        data["@是否打印票尾图片@"] = "false";
      }

      var storeInfo = await Global.instance.getStoreInfo();
      data["@门店编码@"] = storeInfo.code;
      data["@门店名称@"] = storeInfo.printName;
      data["@门店地址@"] = storeInfo.address;
      data["@门店电话@"] = storeInfo.orderTel;

      if (orderObject.orderStatus == OrderStatus.ChargeBack) {
        data["@单据类型@"] = "退款单";
      } else {
        // if (Global.instance.cashierMenuItemMode == CashierMenuItemModeEnum.练习模式)
        // {
        //   data.Add("@单据类型@", "结账单(练习模式)");
        // }
        // else
        // {
        //   data.Add("@单据类型@", "结账单");
        // }
        data["@单据类型@"] = "结账单";
      }

      data["@重打标识@"] = orderObject.reprint ? "true" : "false";

      var salesName = "";
      if (StringUtils.isNotBlank(orderObject.salesCode)) {
        salesName = orderObject.salesCode + "-" + orderObject.salesName;
      }

      data["@营业员@"] = salesName;
      data["@收银员编码@"] = orderObject.workerNo;
      data["@收银员名称@"] = orderObject.workerName;
      data["@POS编码@"] = orderObject.posNo;

      String info = orderObject.tradeNo;
      data["@二维码信息@"] = info;
      data["@是否打印票号条码@"] = "true";
      data["@是否打印票号二维码@"] = "true";

      data["@桌号@"] = orderObject.tableName;
      if (StringUtils.isBlank(orderObject.tableName)) {
        data["@是否打印桌号@"] = "false";
      }

      data["@商品总数@"] = OrderUtils.instance.toRound(orderObject.totalQuantity, precision: 2).toString();
      data["@销售时间@"] = orderObject.finishDate;

      data["@消费金额@"] = OrderUtils.instance.toRound(orderObject.amount, precision: 2).toString();
      data["@优惠金额@"] = OrderUtils.instance.toRound(orderObject.discountAmount, precision: 2).toString();
      data["@应收金额@"] = OrderUtils.instance.toRound(orderObject.receivableAmount, precision: 2).toString();
      data["@实收金额@"] = OrderUtils.instance.toRound(orderObject.paidAmount, precision: 2).toString();
      data["@找零金额@"] = OrderUtils.instance.toRound(orderObject.changeAmount, precision: 2).toString();
      data["@抹零金额@"] = OrderUtils.instance.toRound(orderObject.malingAmount, precision: 2).toString();

      data["@打印时间@"] = orderObject.finishDate;

      data["@备注@"] = orderObject.remark;
      if (StringUtils.isBlank(orderObject.remark)) {
        data["@是否打印备注@"] = "false";
      }

      data["@plus优惠金额@"] = orderObject.plusDiscountAmount.toString();
      if (orderObject.plusDiscountAmount <= 0) {
        data["@是否打印plus优惠@"] = "false";
      }

      Member member = orderObject.member;

      if (member != null && member.couponList != null && member.couponList.length > 0) {
        var couponList = member.couponList.where((x) => x.selected == false);
        if (couponList != null && couponList.length > 0) {
          data["@是否打印优惠券@"] = "true";
        } else {
          data["@是否打印优惠券@"] = "false";
        }
      } else {
        data["@是否打印优惠券@"] = "false";
      }

      if (orderObject.promotions.length > 0 || orderObject.items.where((x) => x.promotions.length > 0).length > 0) {
        data["@是否打印优惠信息@"] = "true";
      } else {
        data["@是否打印优惠信息@"] = "false";
      }

      if (orderObject.pays.any((x) => x.no == Constants.PAYMODE_CODE_GIFTCARD)) {
        data["@是否打印礼品卡@"] = "true";
      } else {
        data["@是否打印礼品卡@"] = "false";
      }

      //主单变量压入
      v.data = json.encode(data);
      result.add(v);

      //会员信息压入
      v = new PrintVariableValue();
      v.key = "会员卡信息";
      v.type = DataType.Simple;
      data = new Map<String, String>();

      if (orderObject.isMember == 1) {
        data["@会员号@"] = orderObject.memberMobileNo; // MemberUtils.Instance.GetMemberCardNoShow(orderObject.CardFaceNo, orderObject.MemberNo, orderObject.MemberMobileNo));
        data["@会员姓名@"] = orderObject.memberName == null ? "" : orderObject.memberName;
        data["@消费前积分@"] = "${OrderUtils.instance.toRound(orderObject.prePoint)}";
        data["@本次积分@"] = "${OrderUtils.instance.toRound(orderObject.addPoint)}";
        data["@当前积分@"] = "${OrderUtils.instance.toRound(orderObject.aftPoint)}";
        double cardBalance = 0.0;
        if (orderObject.pays.any((x) => x.no == Constants.PAYMODE_CODE_CARD)) {
          cardBalance = orderObject.pays.where((x) => x.no == Constants.PAYMODE_CODE_CARD && x.cardNo == orderObject.memberNo).map((e) => e.cardAftAmount).fold(0, (prev, cardAftAmount) => prev + cardAftAmount);
          var cardChangeAmount = orderObject.pays.where((x) => x.no == Constants.PAYMODE_CODE_CARD && x.cardNo == orderObject.memberNo).map((e) => e.cardChangeAmount).fold(0, (prev, cardChangeAmount) => prev + cardChangeAmount);

          data["@扣款金额@"] = "${OrderUtils.instance.toRound(cardChangeAmount)}";
          data["@会员余额@"] = "${OrderUtils.instance.toRound(cardBalance)}";
        } else {
          data["@扣款金额@"] = "${OrderUtils.instance.toRound(0)}";
          data["@会员余额@"] = "${OrderUtils.instance.toRound(orderObject.aftAmount)}";
        }
        data["@是否打印会员@"] = "true";
      } else {
        data["@是否打印会员@"] = "false";
      }
      //会员变量压入
      v.data = json.encode(data);
      result.add(v);

      //礼品卡信息压入
      v = new PrintVariableValue();
      v.key = "礼品卡信息";
      v.type = DataType.List;

      var giftCardList = new List<Map<String, String>>();
      if (orderObject.pays.any((x) => x.no == Constants.PAYMODE_CODE_GIFTCARD)) {
        var giftCards = orderObject.pays.where((x) => x.no == Constants.PAYMODE_CODE_GIFTCARD);
        for (var gift in giftCards) {
          String cardNo = gift.cardNo;
          //加密
          String _mask = cardNo.length == 16 ? cardNo.substring(0, 14) : "";

          if (StringUtils.isNotBlank(_mask)) {
            cardNo = cardNo.replaceAll(_mask, "***");
          }
          var giftCard = new Map<String, String>();
          giftCard["@礼品卡号@"] = cardNo;
          giftCard["@礼品卡余额@"] = "${OrderUtils.instance.toRound(gift.cardAftAmount)}";
          giftCard["@是否打印礼品卡@"] = "true";
          giftCardList.add(giftCard);
        }
      } else {
        var giftCard = new Map<String, String>();
        giftCard["@是否打印礼品卡@"] = "false";
        giftCardList.add(giftCard);
      }
      //礼品卡变量压入
      v.data = json.encode(giftCardList);
      result.add(v);

      v = new PrintVariableValue();
      v.key = "剩余优惠券";
      v.type = DataType.List;
      var giftCouponList = new List<Map<String, dynamic>>();

      if (member != null && member.couponList != null && member.couponList.length > 0) {
        var couponList = member.couponList.where((x) => x.selected == false).toList();
        if (couponList != null && couponList.length > 0) {
          //根据优惠券名字分组显示
          var groupCoupons = couponList.groupBy((x) => x.name);

          groupCoupons.forEach((key, value) {
            var couponName = key;
            var couponQuantity = value.length;
            var couponData = new Map<String, String>();
            couponData["@优惠券类型@"] = couponName;
            couponData["@优惠券数量@"] = "$couponQuantity";
            couponData["@是否打印优惠券@"] = "true";
            giftCouponList.add(couponData);
          });
        } else {
          var couponData = new Map<String, String>();
          couponData["@是否打印优惠券@"] = "false";
          giftCouponList.add(couponData);
        }
      } else {
        var couponData = new Map<String, String>();
        couponData["@是否打印优惠券@"] = "false";
        giftCouponList.add(couponData);
      }
      //剩余优惠券变量压入
      v.data = json.encode(giftCouponList);
      result.add(v);

      v = new PrintVariableValue();
      v.key = "优惠信息";
      v.type = DataType.List;

      var promotionList = new List<Map<String, String>>();
      if (orderObject.promotions != null && orderObject.promotions.length > 0) {
        //整单优惠还存在商品单个优惠的情况
        for (var promotion in orderObject.promotions) {
          var promotionData = new Map<String, String>();
          promotionData["@优惠名称@"] = promotion.promotionType.name;
          promotionData["@优惠金额@"] = "${promotion.discountAmount}";
          promotionData["@是否打印优惠信息@"] = "true";
          promotionList.add(promotionData);
        }
        if (orderObject.items.length > 0 &&
            orderObject.items.any((x) =>
                x.promotions != null && x.promotions.length > 0 && x.promotions.where((y) => y.promotionType != PromotionType.OrderDiscount && y.promotionType != PromotionType.OrderBargain && y.promotionType != PromotionType.OrderReduction).length > 0)) {
          for (var item in orderObject.items) {
            for (var pro in item.promotions.where((x) => x.promotionType != PromotionType.OrderDiscount && x.promotionType != PromotionType.OrderBargain && x.promotionType != PromotionType.OrderReduction)) {
              var promotionData = new Map<String, String>();
              promotionData["@优惠名称@"] = pro.promotionType.name;
              promotionData["@优惠金额@"] = "${pro.discountAmount}";
              promotionData["@是否打印优惠信息@"] = "true";
              promotionList.add(promotionData);
            }
          }
        }
      } else if (orderObject.items.length > 0 && orderObject.items.any((x) => x.promotions != null && x.promotions.length > 0)) {
        for (var item in orderObject.items) {
          for (var pro in item.promotions) {
            var promotionData = new Map<String, String>();
            promotionData["@优惠名称@"] = pro.promotionType.name;
            promotionData["@优惠金额@"] = "${pro.discountAmount}";
            promotionData["@是否打印优惠信息@"] = "true";
            promotionList.add(promotionData);
          }
        }
      } else {
        var promotionData = new Map<String, String>();
        promotionData["@是否打印优惠信息@"] = "false";
        promotionList.add(promotionData);
      }
      //优惠信息变量压入
      v.data = json.encode(promotionList);
      result.add(v);

      v = new PrintVariableValue();
      v.key = "点单列表";
      v.type = DataType.List;

      var list = new List<Map<String, dynamic>>();

      double totalQuantity = 0;
      double totalAmount = 0;
      double totalDiscountAmount = 0;

      //排序，避免显示列表和打印列表不一致
      orderObject.items.sort((left, right) => left.orderNo.compareTo(right.orderNo));

      var items = orderObject.items;
      for (var item in items) {
        if (item.rowType == OrderItemRowType.Detail) {
          //捆绑商品明细不打印
          continue;
        }

        var row = new Map<String, dynamic>();

        //判断参数配置中是否定义显示简称
        //var isShowShortName = Global.Instance.GlobalConfigBoolValue(ConfigConstant.CASHIER_SHOW_SHORTNAME, false);
        var isShowShortName = false;
        //销售界面名称的显示
        String showName = (isShowShortName && StringUtils.isNotBlank(item.shortName)) ? item.shortName : item.productName;
        //是否打印规格
        //var notAllowSepc = Global.Instance.GlobalConfigBoolValue(ConfigConstant.PERIPHERAL_CASHIER_NOT_ALLOW_SPEC , false);

        var notAllowSepc = false;

        //规格名称
        String specName = (notAllowSepc || StringUtils.isNotBlank(item.specName)) ? "" : item.specName;
        //附加规格到名称中
        String displayName = showName + specName;

        if (item.productExt != null && item.productExt.specList != null && item.productExt.specList.length == 1) {
          // //前台显示商品规格名称 0-否，1-是
          // var posShowProductSpec = DataCacheManager.GetLineSalesSetting("pos_show_product_spec");
          // if (!string.IsNullOrEmpty(posShowProductSpec) && posShowProductSpec.Equals("0")) {
          //   displayName = showName;
          // }
        }

        if (item.rowType == OrderItemRowType.Detail) {
          displayName = "[捆]$displayName";
        }

        if (item.rowType == OrderItemRowType.SuitDetail) {
          displayName = "[套]$displayName";
        }

        //判断称重商品是否显示单位kg
        String weightUnit = ""; // (Global.Instance.ShowKg() && item.WeightFlag == 1) ? "kg" : "";
        row["@条码@"] = "${item.barCode}";
        row["@品名@"] = "$displayName"; // + showDiscount);
        row["@数量@"] = "${OrderUtils.instance.toRound(item.quantity, precision: 2)}$weightUnit";
        row["@单位@"] = "${item.productUnitName}";

        double _salePrice = item.price;
        double _amount = item.receivableAmount;
        if (item.rowType == OrderItemRowType.Detail || item.rowType == OrderItemRowType.SuitDetail) {
          row["@原价@"] = "";
          row["@单价@"] = "";
          row["@小计@"] = "";
          row["@优惠@"] = "";
        } else {
          double salePrice = OrderUtils.instance.toRound(item.salePrice);
          double price = OrderUtils.instance.toRound(_salePrice);

          row["@原价@"] = "${OrderUtils.instance.toRound(salePrice)}";
          row["@单价@"] = "${OrderUtils.instance.toRound(price)}";
          row["@小计@"] = "${OrderUtils.instance.toRound(_amount)}";
          row["@优惠@"] = "${OrderUtils.instance.toRound(item.discountAmount)}";
        }
        list.add(row);

        //禁止打印做法
        var notAllowFlavor = false; // Global.Instance.GlobalConfigBoolValue(ConfigConstant.PERIPHERAL_CASHIER_NOT_ALLOW_FLAVOR , false);
        //允许打印做法或者做法包含加价
        bool existAddPriceFlavor = item.flavors.any((x) => x.price != 0);
        if (!notAllowFlavor || existAddPriceFlavor) {
          for (var flavor in item.flavors) {
            row = new Map<String, String>();

            row["@条码@"] = "${flavor.code}";
            row["@品名@"] = "  ${flavor.name}";
            row["@数量@"] = "${OrderUtils.instance.toRound(flavor.quantity)}";
            row["@单位@"] = "";

            if (flavor.price != 0) {
              double salePrice = OrderUtils.instance.toRound(flavor.salePrice);
              double price = OrderUtils.instance.toRound(flavor.price);

              row["@原价@"] = "${OrderUtils.instance.toRound(salePrice)}";
              row["@单价@"] = "${OrderUtils.instance.toRound(price)}";
              row["@小计@"] = "${OrderUtils.instance.toRound(flavor.amount)}";
              row["@优惠@"] = "${OrderUtils.instance.toRound(flavor.discountAmount)}";
            } else {
              row["@原价@"] = "";
              row["@单价@"] = "";
              row["@小计@"] = "";
              row["@优惠@"] = "";
            }
            list.add(row);

            //做法的合计的数据
            totalQuantity += (flavor.quantity);
            totalAmount += flavor.amount;
            totalDiscountAmount += flavor.discountAmount;
          }
        }

        //单品的合计的数据
        if (item.rowType != OrderItemRowType.Detail && item.rowType != OrderItemRowType.SuitDetail) {
          totalQuantity += (item.quantity - item.refundQuantity);
          totalAmount += item.totalReceivableAmount;
          totalDiscountAmount += item.totalDiscountAmount;
        }
      }

      var total = new Map<String, String>();
      total["@条码@"] = "";
      total["@品名@"] = "合计";
      total["@数量@"] = "${OrderUtils.instance.toRound(totalQuantity, precision: 2)}";
      total["@原价@"] = "";
      total["@单价@"] = "";
      total["@小计@"] = "${OrderUtils.instance.toRound(totalAmount, precision: 2)}";
      total["@优惠@"] = "${OrderUtils.instance.toRound(totalDiscountAmount, precision: 2)}";

      list.add(total);

      //将菜品和做法压入变量
      v.data = json.encode(list);
      result.add(v);

      v = new PrintVariableValue();
      v.key = "支付方式列表";
      v.type = DataType.List;

      list = new List<Map<String, String>>();

      var malingPayMode = await OrderUtils.instance.getPayMode(Constants.PAYMODE_CODE_MALING);
      //禁止抹零打印支付列表
      var notAllowMaling = true; // Global.Instance.GlobalConfigBoolValue(ConfigConstant.PERIPHERAL_CASHIER_NOT_ALLOW_MALING , true);

      if (orderObject.pays != null && orderObject.pays.length > 0) {
        for (var item in orderObject.pays) {
          //增加了打印手工抹零
          if (notAllowMaling && malingPayMode != null && malingPayMode.no == item.no && item.statusDesc != Constants.PAYMODE_MALING_HAND) {
            continue;
          }

          var row = new Map<String, String>();

          row["@支付名称@"] = item.name;
          row["@支付金额@"] = "${OrderUtils.instance.toRound(item.paidAmount)}";
          row["@支付凭证@"] = item.voucherNo;

          list.add(row);
        }

        if (list.length == 0) {
          var row = new Map<String, String>();

          row["@支付名称@"] = "";
          row["@支付金额@"] = "";
          row["@支付凭证@"] = "";

          list.add(row);
        }

        if (orderObject.changeAmount != 0) {
          var row = new Map<String, String>();

          row["@支付名称@"] = "找零";
          row["@支付金额@"] = "${OrderUtils.instance.toRound(orderObject.changeAmount)}";
          row["@支付凭证@"] = "";

          list.add(row);
        }
      } else {
        var row = new Map<String, String>();

        row["@支付名称@"] = "未支付";
        row["@支付金额@"] = "";
        row["@支付凭证@"] = "";

        list.add(row);
      }

      //支付明细压入
      v.data = json.encode(list);
      result.add(v);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("构建结账单小票变量发生异常:" + e.toString());
    }
    return result;
  }

  //打印交班单
  static Future<void> printShiftTicket(PrintTicketEnum ticket, ShiftoverTicket shiftOrder) async {
    try {
      //加载当前结账单的打印列表
      var tickets = await getPrinterTicket(ticket);

      if (tickets != null && tickets.length > 0) {
        for (var p in tickets) {
          if (p.copies == 0) {
            FLogger.warn("结账单打印份数设置为[0]，忽略本次打印");
            continue;
          }

          var pobject = await convertPrinterObject(p, openCashbox: false);
          if (pobject != null) {
            //打印份数
            for (int i = 0; i < p.copies; i++) {
              var args = await _builderShiftTicketVariable(shiftOrder, "");
              await printTicket(ticket, pobject, args, shiftOrder.no);
            }
          } else {
            FLogger.warn("打印机转换失败，忽略本次打印");
          }
        }
      } else {
        FLogger.warn("交班单打印机没有配置，忽略本次打印");
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("打印交班单发生异常:" + e.toString());
    }
  }

  //构建结账单打印变量
  static Future<List<PrintVariableValue>> _builderShiftTicketVariable(ShiftoverTicket shiftOrder, String title) async {
    var result = new List<PrintVariableValue>();
    try {
      var v = new PrintVariableValue();
      v.key = "默认数据源";
      v.type = DataType.Simple;
      var data = new Map<String, String>();

      data["@单据类型@"] = title;
      data["@门店@"] = "${Global.instance.authc.storeNo}-${Global.instance.authc.storeName}";
      data["@上机时间@"] = shiftOrder.datetimeBegin;
      data["@交班时间@"] = shiftOrder.datetimeShift;
      data["@交班日期@"] = shiftOrder.datetimeShift;
      data["@pos编号@"] = shiftOrder.posNo;
      data["@重打标识@"] = "false";
      data["@收银员@"] = "${shiftOrder.workNo}-${shiftOrder.workName}";
      data["@备注@"] = shiftOrder.memo;
      data["@打印时间@"] = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
      data["@盲交标识@"] = "false";
      String shiftFlag = "";
      if (shiftOrder.diffMoney > 0) {
        shiftFlag = "(长款)";
      } else if (shiftOrder.diffMoney < 0) {
        shiftFlag = "(短款)";
      }
      data["@差异金额@"] = "${OrderUtils.instance.toRound(shiftOrder.diffMoney)}$shiftFlag";
      data["@手工缴款金额@"] = "${OrderUtils.instance.toRound(shiftOrder.handsMoney)}";

      var totalCash = "0.00";
      if (shiftOrder.ticketCash != null) {
        totalCash = "${OrderUtils.instance.toRound(shiftOrder.ticketCash.totalCash)}";
      }
      data["@应上交现金@"] = totalCash;
      data["@是否打印销售分析@"] = "false";
      data["@是否打印商品销售方式对账@"] = "false";
      data["@是否打印线上-线下对账@"] = "false";
      data["@是否打印充值收款对账@"] = "false";
      data["@是否打印优惠汇总@"] = "false";

      //主单变量压入
      v.data = json.encode(data);
      result.add(v);

      v = new PrintVariableValue();
      v.key = "收款对账";
      v.type = DataType.List;

      var list = new List<Map<String, dynamic>>();
      double totalAmount = 0;
      if (shiftOrder.pays != null && shiftOrder.pays.length > 0) {
        for (var pay in shiftOrder.pays) {
          var row = new Map<String, dynamic>();

          row["@收款方式@"] = "${pay.payModeName}";
          row["@笔数@"] = "${pay.quantity}";
          row["@收款金额@"] = "${OrderUtils.instance.toRound(pay.amount)}";
          list.add(row);

          totalAmount += pay.amount;
        }
      }
      var total = new Map<String, dynamic>();
      total["@收款方式@"] = "合计：";
      total["@笔数@"] = "";
      total["@收款金额@"] = "${OrderUtils.instance.toRound(totalAmount)}";
      list.add(total);

      //压入变量
      v.data = json.encode(list);
      result.add(v);

      v = new PrintVariableValue();
      v.key = "现金明细";
      v.type = DataType.List;

      list = new List<Map<String, dynamic>>();
      var cash = shiftOrder.ticketCash;
      if (cash != null) {
        var row = new Map<String, dynamic>();
        row["@名称@"] = "消费现金收入";
        row["@金额@"] = "${OrderUtils.instance.toRound(cash.consumeCash)}";
        list.add(row);

        row = new Map<String, dynamic>();
        row["@名称@"] = "消费现金退款";
        row["@金额@"] = "${OrderUtils.instance.toRound(cash.consumeCashRefund)}";
        list.add(row);
      }

      //压入变量
      v.data = json.encode(list);
      result.add(v);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("构建结账单小票变量发生异常:" + e.toString());
    }
    return result;
  }

  //转换业务系统的PrinterItem对象到打印模块的PrinterObject对象
  static Future<PrinterObject> convertPrinterObject(PrinterTicket ticket, {bool openCashbox = false}) async {
    PrinterItem printer = await getPrinterItem(ticket);
    if (printer != null) {
      var printerObject = PrinterObject.fromPrinterItem(printer);
      if (printer.brandName == "内置打印机") {
        //内置打印机型号
        var driverName = printerObject.data[PrinterObject.DRIVE_NAME];
        switch (driverName) {
          case "TPS650T":
            {
              printerObject.escPosCommand.initCommand = "27,64,27,77,0,27,50,30"; //27,64,

              printerObject.escPosCommand.alignLeftCommand = "27,97,0";
              printerObject.escPosCommand.alignCenterCommand = "27,97,1";
              printerObject.escPosCommand.alignRightCommand = "27,97,2";

              printerObject.escPosCommand.normalCommand = "27,87,0";
              printerObject.escPosCommand.doubleWidthCommand = "27,87,1";
              printerObject.escPosCommand.doubleHeightCommand = "27,87,16";
              printerObject.escPosCommand.doubleWidthHeightCommand = "27,87,17";
            }
            break;
        }

        // this.initCommand = "27,64";
        // this.normalCommand = "27,33,2,28,33,2";
        // this.doubleWidthCommand = "27,33,32,28,33,4";
        // this.doubleHeightCommand = "27,33,16,28,33,8";
        // this.doubleWidthHeightCommand = "27,33,48,28,33,12";        //
        // this.cutPageCommand = "29,86,66";
        // this.cashboxCommand = "27,112,0,48,192";        //
        // this.alignLeftCommand = "27,97,48";
        // this.alignCenterCommand = "27,97,49";
        // this.alignRightCommand = "27,97,50";        //
        // this.feedBackCommand = "27,101,n";        //
        // this.beepCommand = "27,66";        //
        // this.barcodeCommand = "29,107,m,n";
        // this.barcodeHeightCommand = "29,104,n";
        // this.barcodeLabelLocation = "29,72,n";
        //
        // this.qrcodeStoreData = "29,40,107,n,0,49,80,48";
        // this.qrcodeSize = "29,40,107,3,0,49,67,n";
        // this.qrcodeErrorCorrectionLevel = "29,40,107,3,0,49,69,n";
        // this.qrcodePrint = "29,40,107,3,0,49,81,48";

      }
      return printerObject;
    }
    return null;
  }

  static Future<PrinterItem> getPrinterItem(PrinterTicket ticket) async {
    PrinterItem result;
    try {
      String sql = sprintf("SELECT * FROM `pos_printer_item` where id = '%s' ; ", [ticket.printerId]);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);
      if (lists != null && lists.length > 0) {
        result = PrinterItem.fromMap(lists[0]);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取打印机对象发生异常:" + e.toString());
    }

    return result;
  }

  static Future<List<PrinterTicket>> getPrinterTicket(PrintTicketEnum ticket) async {
    var result = new List<PrinterTicket>();
    try {
      String sql = sprintf("SELECT ppt.* FROM `pos_printer_ticket` ppt  LEFT JOIN `pos_printer_item` ppi ON ppt.`printerId` = ppi.`id` where ppt.printTicket = '%s' ; ", [ticket.name]);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);
      result = PrinterTicket.toList(lists);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取可打印的单据发生异常:" + e.toString());
    }
    return result;
  }

  static Future<List<PrintImg>> getPrintImg() async {
    var result = new List<PrintImg>();
    try {
      String sql = sprintf("select * from pos_print_img where isEnable = 1 and isDelete = 0; ", []);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);
      result = PrintImg.toList(lists);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取小票打印图片发生异常:" + e.toString());
    }
    return result;
  }
}

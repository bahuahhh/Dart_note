import 'dart:io';

import 'package:estore_app/printer/printer_result.dart';

class PrinterNetworkManager {
  String _host;
  int _port;
  Duration _timeout;

  /// Select a network printer
  ///
  /// [timeout] is used to specify the maximum allowed time to wait
  /// for a connection to be established.
  void selectPrinter(
    String host, {
    int port = 9100,
    Duration timeout = const Duration(seconds: 5),
  }) {
    _host = host;
    _port = port;
    _timeout = timeout;
  }

  Future<PrinterResult> printTicket(List<int> ticket) {
    if (_host == null || _port == null) {
      return Future<PrinterResult>.value(PrinterResult.printerNotSelected);
    } else if (ticket == null || ticket.isEmpty) {
      return Future<PrinterResult>.value(PrinterResult.ticketEmpty);
    }

    return Socket.connect(_host, _port, timeout: _timeout).then((Socket socket) {
      socket.add(ticket);
      socket.destroy();
      return Future<PrinterResult>.value(PrinterResult.success);
    }).catchError((dynamic e) {
      return Future<PrinterResult>.value(PrinterResult.timeout);
    });
  }
}

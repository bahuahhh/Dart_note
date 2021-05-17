class PrinterResult {
  const PrinterResult._internal(this.value);
  final int value;
  static const success = PrinterResult._internal(1);
  static const timeout = PrinterResult._internal(2);
  static const printerNotSelected = PrinterResult._internal(3);
  static const ticketEmpty = PrinterResult._internal(4);
  static const printInProgress = PrinterResult._internal(5);
  static const scanInProgress = PrinterResult._internal(6);

  String get msg {
    if (value == PrinterResult.success.value) {
      return 'Success';
    } else if (value == PrinterResult.timeout.value) {
      return 'Error. Printer connection timeout';
    } else if (value == PrinterResult.printerNotSelected.value) {
      return 'Error. Printer not selected';
    } else if (value == PrinterResult.ticketEmpty.value) {
      return 'Error. Ticket is empty';
    } else if (value == PrinterResult.printInProgress.value) {
      return 'Error. Another print in progress';
    } else if (value == PrinterResult.scanInProgress.value) {
      return 'Error. Printer scanning in progress';
    } else {
      return 'Unknown error';
    }
  }
}

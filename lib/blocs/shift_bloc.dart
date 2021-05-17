import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:estore_app/entity/pos_shift_log.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/entity/pos_shiftover_ticket.dart';
import 'package:estore_app/entity/pos_shiftover_ticket_cash.dart';
import 'package:estore_app/entity/pos_shiftover_ticket_pay.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/utils/tuple.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  ShiftRepository _shiftRepository;

  ShiftBloc() : super(ShiftState.init()) {
    this._shiftRepository = new ShiftRepository();
  }

  @override
  Stream<ShiftState> mapEventToState(ShiftEvent event) async* {
    if (event is LoadShiftData) {
      yield* _mapLoadShiftDataToState(event);
    }
  }

  ///加载交班数据
  Stream<ShiftState> _mapLoadShiftDataToState(LoadShiftData event) async* {
    try {
      var cashPayDetail = new ShiftoverTicketCash();
      //交班信息
      var shiftLog = await _shiftRepository.getShiftLog();

      print("@@@@@@@@@@@@@@@@@@##########>>>>>$shiftLog");

      // 现金-备用金
      cashPayDetail.imprest = shiftLog.imprest ?? 0;
      cashPayDetail.consumeCash = cashPayDetail.consumeCash ?? 0 + shiftLog.imprest ?? 0;
      cashPayDetail.totalCash = cashPayDetail.totalCash ?? 0 + shiftLog.imprest ?? 0;

      // 交班支付方式汇总 = 销售支付方式汇总 + 充值支付方式汇总 + 计次充值方式汇总 + plus会员购买支付汇总
      var shiftPayList = new List<ShiftoverTicketPay>();
      //销售支付方式汇总
      var orderPayList = await _shiftRepository.getOrderPayList(shiftLog.id);

      double shiftAmount = 0.00;

      if (orderPayList != null && orderPayList.length > 0) {
        var totalAmount = orderPayList.map((p) => p.amount).fold(0, (prev, amount) => prev + amount); //this._orderPayList.Sum(x => x.Amount);
        shiftAmount += totalAmount;

        shiftPayList.addAll(orderPayList);
      }

      var cashPayResult = await _shiftRepository.getCashPayList(shiftLog.id);
      // 销售现金
      cashPayDetail.consumeCash = cashPayResult.item1;
      // 销售现金退款
      cashPayDetail.consumeCashRefund = cashPayResult.item2;
      // 交班现金汇总
      double sumAmount = cashPayDetail.consumeCash + cashPayDetail.consumeCashRefund;
      cashPayDetail.totalCash += sumAmount;

      yield state.copyWith(
        shiftDate: DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd"),
        shiftTime: DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
        shiftLog: shiftLog,
        shiftPayList: shiftPayList,
        orderPayList: orderPayList,
        cashPayDetail: cashPayDetail,
        shiftAmount: shiftAmount,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载交班异常:" + e.toString());
    }
  }
}

abstract class ShiftEvent extends Equatable {
  const ShiftEvent();
}

class LoadShiftData extends ShiftEvent {
  LoadShiftData();

  @override
  List<Object> get props => [];
}

class ShiftState extends Equatable {
  final String shiftDate;
  final String shiftTime;
  final ShiftLog shiftLog;
  final List<ShiftoverTicketPay> shiftPayList;
  final List<ShiftoverTicketPay> orderPayList;
  final ShiftoverTicketCash cashPayDetail;
  final double shiftAmount;
  const ShiftState({
    this.shiftDate,
    this.shiftTime,
    this.shiftLog,
    this.shiftPayList,
    this.orderPayList,
    this.cashPayDetail,
    this.shiftAmount,
  });

  factory ShiftState.init() {
    return ShiftState(
      shiftDate: DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd"),
      shiftTime: DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
      shiftLog: null,
      shiftPayList: <ShiftoverTicketPay>[],
      orderPayList: <ShiftoverTicketPay>[],
      cashPayDetail: null,
      shiftAmount: 0.00,
    );
  }

  ShiftState copyWith({
    String shiftDate,
    String shiftTime,
    ShiftLog shiftLog,
    List<ShiftoverTicketPay> shiftPayList,
    List<ShiftoverTicketPay> orderPayList,
    ShiftoverTicketCash cashPayDetail,
    double shiftAmount,
  }) {
    return ShiftState(
      shiftDate: shiftDate ?? this.shiftDate,
      shiftTime: shiftTime ?? this.shiftTime,
      shiftLog: shiftLog ?? this.shiftLog,
      shiftPayList: shiftPayList ?? this.shiftPayList,
      orderPayList: orderPayList ?? this.orderPayList,
      cashPayDetail: cashPayDetail ?? this.cashPayDetail,
      shiftAmount: shiftAmount ?? this.shiftAmount,
    );
  }

  @override
  List<Object> get props => [shiftDate, shiftTime, shiftLog, shiftPayList, orderPayList, cashPayDetail, shiftAmount];
}

class ShiftRepository {
  ///加载交班信息
  Future<ShiftLog> getShiftLog() async {
    ShiftLog result;
    try {
      String sql = "select * from pos_shift_log where status = 0 and storeId = '${Global.instance.authc.storeId}' and workerId = '${Global.instance.worker.id}' and posNo = '${Global.instance.authc.posNo}';";
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      if (lists != null && lists.length > 0) {
        result = ShiftLog.fromMap(lists[0]);

        sql = "select finishDate from pos_order where shiftId = '${result.id}' order by finishDate;";
        var firstOrder = await database.rawQuery(sql);
        if (firstOrder != null && firstOrder.length > 0) {
          result.firstDealTime = Convert.toStr(firstOrder[0]["finishDate"]);
        }

        sql = "select finishDate from pos_order where shiftId = '${result.id}' order by finishDate desc;";
        var endOrder = await database.rawQuery(sql);
        if (endOrder != null && endOrder.length > 0) {
          result.endDealTime = Convert.toStr(endOrder[0]["finishDate"]);
        }
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);

      FLogger.error("加载交班信息异常:" + e.toString());
    }
    return result;
  }

  ///加载收银交易汇总
  Future<List<ShiftoverTicketPay>> getOrderPayList(String shiftId) async {
    List<ShiftoverTicketPay> result = <ShiftoverTicketPay>[];
    try {
      String sql = """
      select p.no as payModeNo, p.name as payModeName, sum(p.paidAmount) as amount, count(1) as quantity 
      from pos_order_pay p
      left join pos_order r on p.orderId = r.id
      where r.orderStatus in (2, 4) and r.shiftId = '$shiftId' and r.orderSource != 20 and r.posNo = '${Global.instance.authc.posNo}' group by p.no;
      """;
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      if (lists != null && lists.length > 0) {
        result = ShiftoverTicketPay.toList(lists);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);

      FLogger.error("加载收银交易汇总异常:" + e.toString());
    }
    return result;
  }

  ///加载收银交易汇总
  Future<Tuple2<double, double>> getCashPayList(String shiftId) async {
    double consumeCash = 0.00;
    double consumeCashRefund = 0.00;
    try {
      String sql = """
      select r.orderStatus, sum(p.paidAmount) as paidAmount 
      from pos_order_pay p 
      left join pos_order r on p.orderId = r.id
      where r.orderStatus in (2, 4) and r.shiftId = '$shiftId' and r.orderSource != 20  and p.no = '01' and r.posNo = '${Global.instance.authc.posNo}' group by r.orderStatus;
      """;
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      if (lists != null && lists.length > 0) {
        for (var order in lists) {
          if (order["orderStatus"] == 4) {
            consumeCash = Convert.toDouble(order["paidAmount"]);
          } else if (order["orderStatus"] == 2) {
            consumeCashRefund = Convert.toDouble(order["paidAmount"]);
          }
        }
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);

      FLogger.error("加载收银交易汇总异常:" + e.toString());
    }
    return Tuple2(consumeCash, consumeCashRefund);
  }
}

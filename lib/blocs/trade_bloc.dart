import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:estore_app/entity/pos_base_parameter.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_refund.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:jiffy/jiffy.dart';

class TradeBloc extends Bloc<TradeEvent, TradeState> {
  TradeRepository _tradeRepository;

  TradeBloc() : super(TradeState.init()) {
    this._tradeRepository = new TradeRepository();
  }

  @override
  Stream<TradeState> mapEventToState(TradeEvent event) async* {
    if (event is PagerDataEvent) {
      yield* _mapPagerDataToState(event);
    } else if (event is LoadRefundData) {
      yield* _mapLoadRefundDataToState(event);
    } else if (event is SelectRefundReason) {
      yield* _mapSelectReasonToState(event);
    } else if (event is SelectRefundItem) {
      yield* _mapSelectRefundItemToState(event);
    } else if (event is RefundQuantityChanged) {
      yield* _mapRefundQuantityChangedToState(event);
    } else if (event is ClearRefundItem) {
      yield* _mapClearRefundItemToState(event);
    }
  }

  ///清除全待退货的记录
  Stream<TradeState> _mapClearRefundItemToState(ClearRefundItem event) async* {
    try {
      var orderObject = state.orderObject;

      var orderItem = orderObject.items.firstWhere((item) {
        return event.orderItem.id == item.id;
      });

      //默认全部退货
      List<OrderRefund> refundList = state.refundList.map((e) => OrderRefund.clone(e)).toList();
      if (refundList.any((x) => x.itemId == orderItem.id)) {
        var obj = refundList.firstWhere((x) => x.itemId == orderItem.id);
        obj.selected = false;
      }

      double totalRefundQuantity = refundList.where((x) => x.selected).map((e) => e.refundQuantity).fold(0, (prev, quantity) => prev + quantity);
      double totalRefundAmount = refundList.where((x) => x.selected).map((e) => e.refundAmount).fold(0, (prev, amount) => prev + amount);

      yield state.copyWith(
        orderItem: OrderItem.clone(orderItem),
        refundList: refundList,
        totalRefundQuantity: totalRefundQuantity,
        totalRefundAmount: totalRefundAmount,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载本地支付方式数据异常:" + e.toString());
    }
  }

  ///数量加操作
  Stream<TradeState> _mapRefundQuantityChangedToState(RefundQuantityChanged event) async* {
    var orderObject = state.orderObject;

    var orderItem = event.orderItem;
    var newValue = event.newValue;

    //默认全部退货
    List<OrderRefund> refundList = state.refundList.map((e) => OrderRefund.clone(e)).toList();
    if (refundList.any((x) => x.itemId == orderItem.id)) {
      var obj = refundList.firstWhere((x) => x.itemId == orderItem.id);
      obj.refundQuantity = newValue;
      obj.refundAmount = newValue * orderItem.price;
    }

    double totalRefundQuantity = refundList.map((e) => e.refundQuantity).fold(0, (prev, quantity) => prev + quantity);
    double totalRefundAmount = refundList.map((e) => e.refundAmount).fold(0, (prev, amount) => prev + amount);

    yield state.copyWith(
      orderObject: orderObject,
      orderItem: orderItem,
      refundList: refundList,
      totalRefundQuantity: totalRefundQuantity,
      totalRefundAmount: totalRefundAmount,
    );
  }

  //加载数据
  Stream<TradeState> _mapPagerDataToState(PagerDataEvent event) async* {
    try {
      //订单列表清单，增量添加，当pagerNumber=0的时候，清空
      var orderList = state.orderList ?? <OrderObject>[];

      //日期标签
      String labelDate = event.labelDate;
      String startDate = event.startDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd 00:00:00");
      String endDate = event.endDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd 23:59:59");
      int pagerNumber = event.pagerNumber ?? 0;
      int pagerSize = event.pagerSize ?? 1;

      //是否操作日期标签
      if (StringUtils.isNotEmpty(labelDate)) {
        switch (labelDate) {
          case "今日":
            {
              startDate = DateTimeUtils.formatDate(Jiffy().startOf(Units.DAY), format: "yyyy-MM-dd 00:00:00");
              endDate = DateTimeUtils.formatDate(Jiffy().startOf(Units.DAY), format: "yyyy-MM-dd 23:59:59");
            }
            break;
          case "昨天":
            {
              startDate = DateTimeUtils.formatDate(Jiffy().subtract(days: 1), format: "yyyy-MM-dd 00:00:00");
              endDate = DateTimeUtils.formatDate(Jiffy().subtract(days: 1), format: "yyyy-MM-dd 23:59:59");
            }
            break;
          case "前天":
            {
              startDate = DateTimeUtils.formatDate(Jiffy().subtract(days: 2), format: "yyyy-MM-dd 00:00:00");
              endDate = DateTimeUtils.formatDate(Jiffy().subtract(days: 2), format: "yyyy-MM-dd 23:59:59");
            }
            break;
          case "近7天":
            {
              startDate = DateTimeUtils.formatDate(Jiffy().subtract(days: 6), format: "yyyy-MM-dd 00:00:00");
              endDate = DateTimeUtils.formatDate(Jiffy().startOf(Units.DAY), format: "yyyy-MM-dd 23:59:59");
            }
            break;
          case "近30天":
            {
              startDate = DateTimeUtils.formatDate(Jiffy().subtract(days: 29), format: "yyyy-MM-dd 00:00:00");
              endDate = DateTimeUtils.formatDate(Jiffy().startOf(Units.DAY), format: "yyyy-MM-dd 23:59:59");
            }
            break;
          case "本周":
            {
              startDate = DateTimeUtils.formatDate(Jiffy().startOf(Units.WEEK), format: "yyyy-MM-dd 00:00:00");
              endDate = DateTimeUtils.formatDate(Jiffy().endOf(Units.WEEK), format: "yyyy-MM-dd 23:59:59");
            }
            break;
          case "本月":
            {
              startDate = DateTimeUtils.formatDate(Jiffy().startOf(Units.MONTH), format: "yyyy-MM-dd 00:00:00");
              endDate = DateTimeUtils.formatDate(Jiffy().endOf(Units.MONTH), format: "yyyy-MM-dd 23:59:59");
            }
            break;
          case "上月":
            {
              startDate = DateTimeUtils.formatDate(Jiffy(Jiffy().subtract(months: 1)).startOf(Units.MONTH), format: "yyyy-MM-01 00:00:00");
              endDate = DateTimeUtils.formatDate(Jiffy(Jiffy().subtract(months: 1)).endOf(Units.MONTH), format: "yyyy-MM-dd 23:59:59");
            }
            break;
        }
      }

      if (pagerNumber == 0) {
        orderList.clear();
      }

      int totalCount = 0;
      double totalAmount = 0.00;
      var listResult = await this._tradeRepository.getOrderObjectList(startDate, endDate, pagerNumber: pagerNumber, pagerSize: pagerSize);
      if (listResult.item1) {
        totalCount = listResult.item3;
        totalAmount = listResult.item4;
        var lists = listResult.item5;
        orderList.addAll(lists);
      }

      yield state.copyWith(
        labelDate: labelDate,
        startDate: startDate,
        endDate: endDate,
        pagerNumber: pagerNumber,
        pagerSize: pagerSize,
        orderList: orderList,
        totalCount: totalCount,
        totalAmount: totalAmount,
      );
    } catch (e, stack) {
      FLogger.error("加载销售流水异常:" + e.toString());
    }
  }

  ///选择退单原因
  Stream<TradeState> _mapSelectReasonToState(SelectRefundReason event) async* {
    var reasons = state.reasonsList;
    var reason = reasons.firstWhere((item) => (item.id == event.reason.id));

    var selected = BaseParameter.clone(reason);

    yield state.copyWith(
      reasonSelected: selected,
    );
  }

  ///单行选择操作
  Stream<TradeState> _mapSelectRefundItemToState(SelectRefundItem event) async* {
    var orderObject = state.orderObject;

    var orderItem = orderObject.items.firstWhere((item) {
      return event.orderItem.id == item.id;
    });

    //默认全部退货
    List<OrderRefund> refundList = state.refundList.map((e) => OrderRefund.clone(e)).toList();
    if (refundList.any((x) => x.itemId == orderItem.id)) {
      var obj = refundList.firstWhere((x) => x.itemId == orderItem.id);
      obj.selected = true;
    }

    double totalRefundQuantity = refundList.where((x) => x.selected).map((e) => e.refundQuantity).fold(0, (prev, quantity) => prev + quantity);
    double totalRefundAmount = refundList.where((x) => x.selected).map((e) => e.refundAmount).fold(0, (prev, amount) => prev + amount);

    yield state.copyWith(
      orderItem: OrderItem.clone(orderItem),
      refundList: refundList,
      totalRefundQuantity: totalRefundQuantity,
      totalRefundAmount: totalRefundAmount,
    );
  }

  ///加载退货原因
  Stream<TradeState> _mapLoadRefundDataToState(LoadRefundData event) async* {
    try {
      //整单信息
      OrderObject orderObject = OrderObject.clone(event.orderObject);
      //默认选中第一个
      OrderItem orderItem = orderObject.items.first;

      ///加载退货
      List<BaseParameter> reasons = await OrderUtils.instance.getReason("refundReason");
      BaseParameter selected;
      if (reasons != null && reasons.length > 0) {
        selected = reasons[0];
      }

      //默认全部退货
      List<OrderRefund> refundList = <OrderRefund>[];

      orderObject.items.forEach((x) {
        OrderRefund obj = new OrderRefund();
        //不选中
        obj.selected = true;
        //行ID
        obj.itemId = x.id;
        //最大可退数量
        obj.maxRefundQuantity = x.quantity - x.refundQuantity;
        //默认全退
        obj.refundQuantity = obj.maxRefundQuantity;
        //退单价
        obj.refundPrice = x.price;
        //退货金额
        obj.refundAmount = obj.refundQuantity * obj.refundPrice + x.flavorAmount;

        refundList.add(obj);
      });

      double totalRefundQuantity = refundList.where((x) => x.selected).map((e) => e.refundQuantity).fold(0, (prev, quantity) => prev + quantity);
      double totalRefundAmount = refundList.where((x) => x.selected).map((e) => e.refundAmount).fold(0, (prev, amount) => prev + amount);

      yield state.copyWith(
        orderObject: orderObject,
        orderItem: orderItem,
        reasonsList: reasons ?? <BaseParameter>[],
        reasonSelected: selected ?? null,
        refundList: refundList,
        totalRefundQuantity: totalRefundQuantity,
        totalRefundAmount: totalRefundAmount,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载退货原因异常:" + e.toString());
    }
  }
}

abstract class TradeEvent extends Equatable {
  const TradeEvent();
}

///加载退单数据
class LoadRefundData extends TradeEvent {
  final OrderObject orderObject;

  LoadRefundData(this.orderObject);

  @override
  List<Object> get props => [this.orderObject];
}

///选择折扣原因
class SelectRefundReason extends TradeEvent {
  final BaseParameter reason;

  SelectRefundReason({this.reason});

  @override
  List<Object> get props => [reason];
}

///选中单行
class SelectRefundItem extends TradeEvent {
  final OrderItem orderItem;

  SelectRefundItem({this.orderItem});

  @override
  List<Object> get props => [orderItem];
}

///数量加减
class RefundQuantityChanged extends TradeEvent {
  final OrderItem orderItem;
  final double newValue;

  RefundQuantityChanged(this.orderItem, this.newValue);

  @override
  List<Object> get props => [orderItem, newValue];
}

///清除退货选择项
class ClearRefundItem extends TradeEvent {
  final OrderItem orderItem;

  ClearRefundItem({this.orderItem});

  @override
  List<Object> get props => [orderItem];
}

///加载分页数据
class PagerDataEvent extends TradeEvent {
  //日期标签：今天、昨天、前天....
  final String labelDate;
  //开始日期
  final String startDate;
  //开始日期
  final String endDate;
  //当前页码
  final int pagerNumber;
  //每页大小
  final int pagerSize;

  PagerDataEvent({
    this.labelDate,
    this.startDate,
    this.endDate,
    this.pagerNumber,
    this.pagerSize,
  });

  @override
  List<Object> get props => [this.labelDate, this.startDate, this.endDate, this.pagerNumber, this.pagerSize];
}

//更改查询参数
class ChangeQueryParameterEvent extends TradeEvent {
  //日期标签：今天、昨天、前天....
  final String labelDate;
  //开始日期
  final String startDate;
  //开始日期
  final String endDate;
  //当前页码
  final int pagerNumber;
  //每页大小
  final int pagerSize;

  ChangeQueryParameterEvent({
    this.labelDate,
    this.startDate,
    this.endDate,
    this.pagerNumber,
    this.pagerSize,
  });

  @override
  List<Object> get props => [this.labelDate, this.startDate, this.endDate, this.pagerNumber, this.pagerSize];
}

class TradeState extends Equatable {
  //日期标签：今天、昨天、前天....
  final String labelDate;
  //开始日期
  final String startDate;
  //开始日期
  final String endDate;
  //当前页码
  final int pagerNumber;
  //每页大小
  final int pagerSize;
  //总单数
  final int totalCount;
  //总营业额
  final double totalAmount;

  //订单列表
  final List<OrderObject> orderList;

  //当前选择的订单
  final OrderObject orderObject;

  //当前订单选择的行
  final OrderItem orderItem;

  ///退货原因列表
  final List<BaseParameter> reasonsList;

  ///当前选择原因
  final BaseParameter reasonSelected;

  //退货清单
  final List<OrderRefund> refundList;

  //退总数量
  final double totalRefundQuantity;

  //退总金额
  final double totalRefundAmount;

  const TradeState({
    this.labelDate,
    this.startDate,
    this.endDate,
    this.orderList,
    this.pagerSize,
    this.pagerNumber,
    this.totalCount,
    this.totalAmount,
    this.reasonsList,
    this.reasonSelected,
    this.orderObject,
    this.orderItem,
    this.refundList,
    this.totalRefundAmount,
    this.totalRefundQuantity,
  });

  ///初始化
  factory TradeState.init() {
    return TradeState(
      labelDate: "今日",
      startDate: DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd 00:00:00"),
      endDate: DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd 23:59:59"),
      orderList: <OrderObject>[],
      pagerNumber: 0,
      pagerSize: 1,
      totalCount: 0,
      totalAmount: 0,
      reasonsList: [],
      reasonSelected: null,
      orderObject: null,
      orderItem: null,
      totalRefundQuantity: 0,
      totalRefundAmount: 0,
    );
  }

  TradeState copyWith({
    String labelDate,
    String startDate,
    String endDate,
    List<OrderObject> orderList,
    int pagerNumber,
    int pagerSize,
    int totalCount,
    double totalAmount,
    List<BaseParameter> reasonsList,
    BaseParameter reasonSelected,
    OrderObject orderObject,
    OrderItem orderItem,
    List<OrderRefund> refundList,
    double totalRefundQuantity,
    double totalRefundAmount,
  }) {
    return TradeState(
      labelDate: labelDate ?? this.labelDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      orderList: orderList ?? this.orderList,
      pagerSize: pagerSize ?? this.pagerSize,
      pagerNumber: pagerNumber ?? this.pagerNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCount: totalCount ?? this.totalCount,
      reasonsList: reasonsList ?? this.reasonsList,
      reasonSelected: reasonSelected ?? this.reasonSelected,
      orderObject: orderObject ?? this.orderObject,
      orderItem: orderItem ?? this.orderItem,
      refundList: refundList ?? this.refundList,
      totalRefundQuantity: totalRefundQuantity ?? this.totalRefundQuantity,
      totalRefundAmount: totalRefundAmount ?? this.totalRefundAmount,
    );
  }

  @override
  List<Object> get props => [
        this.labelDate,
        this.startDate,
        this.endDate,
        this.orderList,
        this.pagerNumber,
        this.pagerSize,
        this.totalAmount,
        this.totalCount,
        this.reasonsList,
        this.reasonSelected,
        this.orderObject,
        this.orderItem,
        this.refundList,
        this.totalRefundQuantity,
        this.totalRefundAmount,
      ];
}

class TradeRepository {
  ///分页获取订单信息
  Future<Tuple5<bool, String, int, double, List<OrderObject>>> getOrderObjectList(String startDate, String endDate, {String orderId, int pagerNumber = 1, int pagerSize = 1}) async {
    bool success = false;
    String message = "加载订单信息错误";
    int totalCount = 0;
    double totalAmount = 0;
    List<OrderObject> result = <OrderObject>[];
    try {
      String sql = "select * from pos_order where orderStatus in(2, 4) and finishDate between '$startDate' and '$endDate' ";
      var where = new StringBuffer();
      //订单ID
      if (StringUtils.isNotBlank(orderId)) {
        where.write(" and id = '$orderId' ");
      }
      where.write(" order by finishDate desc ");
      where.write(" limit $pagerSize offset ${pagerNumber * pagerSize} ;");
      //查询分页列表数据
      var pagerSsql = "$sql ${where.toString()}";
      //查询总记录数、总营业额
      var countSql = "select count(1) as totalCount ,sum(receivableAmount) as totalAmount from pos_order where orderStatus in(2, 4) and finishDate between '$startDate' and '$endDate';";

      var database = await SqlUtils.instance.open();
      //总记录数、总营业额
      List<Map<String, dynamic>> countResult = await database.rawQuery(countSql);
      if (countResult != null) {
        Map<String, dynamic> _data = countResult.first;
        totalCount = _data["totalCount"] != null ? Convert.toInt(_data["totalCount"]) : 0;
        totalAmount = _data["totalAmount"] != null ? OrderUtils.instance.toRound(Convert.toDouble(_data["totalAmount"])) : 0.0;
      }
      //分页列表数据
      List<Map<String, dynamic>> listResult = await database.rawQuery(pagerSsql);
      if (listResult != null) {
        var orderList = OrderObject.toList(listResult);
        for (var o in orderList) {
          var order = await OrderUtils.instance.additionalOrderObject(o);

          result.add(order);
        }
      }

      success = true;
      message = "加载订单信息成功";
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取订单列表发生异常:" + e.toString());
    }
    return Tuple5(success, message, totalCount, totalAmount, result);
  }
}

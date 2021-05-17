import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_store_table.dart';
import 'package:estore_app/entity/pos_store_table_area.dart';
import 'package:estore_app/entity/pos_store_table_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/order_table.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  TableRepository _tableRepository;

  TableBloc() : super(TableState.init()) {
    this._tableRepository = new TableRepository();
  }

  @override
  Stream<TableState> mapEventToState(TableEvent event) async* {
    if (event is LoadTable) {
      yield* _mapLoadTableToState(event);
    } else if (event is QueryTable) {
      yield* _mapQueryTableToState(event);
    } else if (event is SelectTable) {
      yield* _mapSelectTableToState(event);
    } else if (event is RefreshTable) {
      yield* _mapRefreshTableToState(event);
    } else if (event is LoadTransferTable) {
      yield* _mapLoadTransferTableToState(event);
    } else if (event is SelectTransferTable) {
      yield* _mapSelectTransferTableToState(event);
    } else if (event is LoadMergeTable) {
      yield* _mapLoadMergeTableToState(event);
    } else if (event is SelectMergeTable) {
      yield* _mapSelectMergeTableToState(event);
    }
  }

  ///并台区域和类型选择操作
  Stream<TableState> _mapSelectMergeTableToState(SelectMergeTable event) async* {
    try {
      //当前规格列表
      List<StoreTable> mergeList = event.mergeList ?? <StoreTable>[];

      yield state.copyWith(
        mergeList: mergeList,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("并台选择异常:" + e.toString());
    }
  }

  ///初始化并台数据
  Stream<TableState> _mapLoadMergeTableToState(LoadMergeTable event) async* {
    try {
      String typeId = event.typeId ?? "";
      String areaId = event.areaId ?? "";

      //加载桌台类型
      List<StoreTableType> tableTypeList = state.tableTypeList ?? <StoreTableType>[];

      ///当前选中的类型
      StoreTableType transferOrMergeType;
      if (tableTypeList != null && tableTypeList.length > 0) {
        transferOrMergeType = tableTypeList.firstWhere((e) => e.id == typeId, orElse: () => null);
        if (transferOrMergeType == null) {
          transferOrMergeType = tableTypeList[0];
        }
      }
      if (transferOrMergeType != null) {
        transferOrMergeType = StoreTableType.clone(transferOrMergeType);
      }

      //加载桌台区域
      List<StoreTableArea> tableAreaList = state.tableAreaList ?? <StoreTableArea>[];

      ///当前选中的区域
      StoreTableArea transferOrMergeArea;
      if (tableAreaList != null && tableAreaList.length > 0) {
        transferOrMergeArea = tableAreaList.firstWhere((e) => e.id == areaId, orElse: () => null);
        if (transferOrMergeArea == null) {
          transferOrMergeArea = tableAreaList[0];
        }
      }

      if (transferOrMergeArea != null) {
        transferOrMergeArea = StoreTableArea.clone(transferOrMergeArea);
      }

      //加载未开台的桌台
      List<StoreTable> transferOrMergeList = (state.tableList ?? <StoreTable>[]).map((e) => StoreTable.clone(e)).toList();
      //清理掉未开台、已选桌台本身的数据、已经参与并台的
      transferOrMergeList.removeWhere((x) => x.orderTable == null || (x.orderTable != null && (x.orderTable.tableId == state.table.id || x.orderTable.tableAction == 3)));

      if (StringUtils.isNotBlank(typeId)) {
        transferOrMergeList = transferOrMergeList.where((x) => x.typeId == typeId).toList();
      }

      if (StringUtils.isNotBlank(areaId)) {
        transferOrMergeList = transferOrMergeList.where((x) => x.areaId == areaId).toList();
      }

      ///当前选中的桌台
      StoreTable transferTable;
      if (transferOrMergeList != null && transferOrMergeList.length > 0) {
        transferTable = transferOrMergeList[0];
      }

      if (transferTable != null) {
        transferTable = StoreTable.clone(transferTable);
      }

      yield state.copyWith(
        transferOrMergeType: transferOrMergeType,
        transferOrMergeArea: transferOrMergeArea,
        transferOrMergeList: transferOrMergeList,
        transferTable: transferTable,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载并台数据异常:" + e.toString());
    }
  }

  ///转台区域和类型选择操作
  Stream<TableState> _mapSelectTransferTableToState(SelectTransferTable event) async* {
    try {
      StoreTable transferOrMergeTable = event.transferOrMergeTable ?? null;
      //转台
      List<StoreTable> transferOrMergeList = state.transferOrMergeList;
      if (transferOrMergeTable != null && transferOrMergeList.any((x) => x.id == transferOrMergeTable.id)) {
        transferOrMergeTable = transferOrMergeList.lastWhere((x) => x.id == transferOrMergeTable.id);
      }

      if (transferOrMergeTable != null) {
        transferOrMergeTable = StoreTable.clone(transferOrMergeTable);
      }
      yield state.copyWith(
        transferTable: transferOrMergeTable,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("转台选择异常:" + e.toString());
    }
  }

  ///初始化转台数据
  Stream<TableState> _mapLoadTransferTableToState(LoadTransferTable event) async* {
    try {
      String typeId = event.typeId ?? "";
      String areaId = event.areaId ?? "";

      //加载桌台类型
      List<StoreTableType> tableTypeList = state.tableTypeList ?? <StoreTableType>[];

      ///当前选中的类型
      StoreTableType transferOrMergeType;
      if (tableTypeList != null && tableTypeList.length > 0) {
        transferOrMergeType = tableTypeList.firstWhere((e) => e.id == typeId, orElse: () => null);
        if (transferOrMergeType == null) {
          transferOrMergeType = tableTypeList[0];
        }
      }
      if (transferOrMergeType != null) {
        transferOrMergeType = StoreTableType.clone(transferOrMergeType);
      }

      //加载桌台区域
      List<StoreTableArea> tableAreaList = state.tableAreaList ?? <StoreTableArea>[];

      ///当前选中的区域
      StoreTableArea transferOrMergeArea;
      if (tableAreaList != null && tableAreaList.length > 0) {
        transferOrMergeArea = tableAreaList.firstWhere((e) => e.id == areaId, orElse: () => null);
        if (transferOrMergeArea == null) {
          transferOrMergeArea = tableAreaList[0];
        }
      }

      if (transferOrMergeArea != null) {
        transferOrMergeArea = StoreTableArea.clone(transferOrMergeArea);
      }

      //加载未开台的桌台
      List<StoreTable> transferOrMergeList = (state.tableList ?? <StoreTable>[]).map((e) => StoreTable.clone(e)).toList();
      //清理掉已经开台的数据
      transferOrMergeList.removeWhere((x) => x.orderTable != null);

      if (StringUtils.isNotBlank(typeId)) {
        transferOrMergeList = transferOrMergeList.where((x) => x.typeId == typeId).toList();
      }

      if (StringUtils.isNotBlank(areaId)) {
        transferOrMergeList = transferOrMergeList.where((x) => x.areaId == areaId).toList();
      }

      ///当前选中的桌台
      StoreTable transferTable;
      if (transferOrMergeList != null && transferOrMergeList.length > 0) {
        transferTable = transferOrMergeList[0];
      }

      if (transferTable != null) {
        transferTable = StoreTable.clone(transferTable);
      }

      yield state.copyWith(
        transferOrMergeType: transferOrMergeType,
        transferOrMergeArea: transferOrMergeArea,
        transferOrMergeList: transferOrMergeList,
        transferTable: transferTable,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载转台数据异常:" + e.toString());
    }
  }

  ///刷新桌台主界面，全部获取数据表数据
  Stream<TableState> _mapRefreshTableToState(RefreshTable event) async* {
    try {
      String typeId = state.tableType.id;
      String areaId = state.tableArea.id;
      String tableId = state.table.id;

      //加载桌台
      List<StoreTable> tableList = await this._tableRepository.getTableList(typeId: typeId, areaId: areaId);

      //加载正在使用的桌台
      List<OrderTable> orderTableList = await this._tableRepository.getOrderTableList();
      for (var t in tableList) {
        t.tableType = StoreTableType.clone(state.tableType);
        t.tableArea = StoreTableArea.clone(state.tableArea);

        if (orderTableList.any((x) => x.tableId == t.id)) {
          t.orderTable = OrderTable.clone(orderTableList.lastWhere((x) => x.tableId == t.id));
        }
      }

      ///当前选中的桌台
      StoreTable table;
      if (tableList != null && tableList.length > 0) {
        if (tableList.any((x) => x.id == tableId)) {
          table = tableList.lastWhere((x) => x.id == tableId);
        } else {
          table = tableList[0];
        }
      }

      if (table != null) {
        table = StoreTable.clone(table);
        table.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
      }

      yield state.copyWith(
        tableList: tableList ?? <StoreTable>[],
        table: table,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("查询桌台数据异常:" + e.toString());
    }
  }

  ///桌台区域和类型选择操作
  Stream<TableState> _mapSelectTableToState(SelectTable event) async* {
    try {
      StoreTable table = event.table ?? null;
      //桌台
      List<StoreTable> tableList = state.tableList;
      if (table != null && tableList.any((x) => x.id == table.id)) {
        table = tableList.lastWhere((x) => x.id == table.id);
      }

      if (table != null) {
        table = StoreTable.clone(table);
      }
      yield state.copyWith(
        table: table,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("查询桌台数据异常:" + e.toString());
    }
  }

  ///桌台区域和类型选择操作
  Stream<TableState> _mapQueryTableToState(QueryTable event) async* {
    try {
      String typeId = event.typeId ?? "";
      String areaId = event.areaId ?? "";

      //加载桌台类型
      List<StoreTableType> tableTypeList = state.tableTypeList ?? <StoreTableType>[];

      ///当前选中的类型
      StoreTableType tableType;
      if (tableTypeList != null && tableTypeList.length > 0) {
        tableType = tableTypeList.firstWhere((e) => e.id == typeId, orElse: () => null);
        if (tableType == null) {
          tableType = tableTypeList[0];
        }
      }

      if (tableType != null) {
        tableType = StoreTableType.clone(tableType);
      }

      //加载桌台区域
      List<StoreTableArea> tableAreaList = state.tableAreaList ?? <StoreTableArea>[];

      ///当前选中的区域
      StoreTableArea tableArea;
      if (tableAreaList != null && tableAreaList.length > 0) {
        tableArea = tableAreaList.firstWhere((e) => e.id == areaId, orElse: () => null);
        if (tableArea == null) {
          tableArea = tableAreaList[0];
        }
      }

      if (tableArea != null) {
        tableArea = StoreTableArea.clone(tableArea);
      }

      //加载桌台
      List<StoreTable> tableList = await this._tableRepository.getTableList(typeId: typeId, areaId: areaId);

      //加载正在使用的桌台
      List<OrderTable> orderTableList = await this._tableRepository.getOrderTableList();

      for (var t in tableList) {
        t.tableType = tableTypeList.lastWhere((x) => x.id == t.typeId);
        t.tableArea = tableAreaList.lastWhere((x) => x.id == t.areaId);

        if (orderTableList.any((x) => x.tableId == t.id)) {
          t.orderTable = orderTableList.lastWhere((x) => x.tableId == t.id);
        }
      }

      ///当前选中的桌台
      StoreTable table;
      if (tableList != null && tableList.length > 0) {
        ///默认选中第一个桌台
        table = tableList[0];
      }

      yield state.copyWith(
        tableList: tableList,
        tableType: tableType,
        tableArea: tableArea,
        table: table,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("查询桌台数据异常:" + e.toString());
    }
  }

  ///初始化界面数据
  Stream<TableState> _mapLoadTableToState(LoadTable event) async* {
    try {
      //加载桌台
      List<StoreTable> tableList = await this._tableRepository.getTableList();

      ///当前选中的桌台
      StoreTable table;
      if (tableList != null && tableList.length > 0) {
        ///默认选中第一个桌台
        table = tableList[0];
      }

      //加载桌台类型
      List<StoreTableType> tableTypeList = await this._tableRepository.getTableTypeList();

      ///当前选中的类型
      StoreTableType tableType;
      if (tableTypeList != null && tableTypeList.length > 0) {
        ///默认选中第一个大类
        tableType = tableTypeList[0];
      }
      //加载桌台区域
      List<StoreTableArea> tableAreaList = await this._tableRepository.getTableAreaList();

      ///当前选中的区域
      StoreTableArea tableArea;
      if (tableAreaList != null && tableAreaList.length > 0) {
        ///默认选中第一个大类
        tableArea = tableAreaList[0];
      }

      //加载正在使用的桌台
      List<OrderTable> orderTableList = await this._tableRepository.getOrderTableList();

      for (var t in tableList) {
        t.tableType = tableTypeList.lastWhere((x) => x.id == t.typeId);
        t.tableArea = tableAreaList.lastWhere((x) => x.id == t.areaId);

        if (orderTableList.any((x) => x.tableId == t.id)) {
          t.orderTable = orderTableList.lastWhere((x) => x.tableId == t.id);
        }
      }
      yield state.copyWith(
        tableTypeList: tableTypeList ?? <StoreTableType>[],
        tableAreaList: tableAreaList ?? <StoreTableArea>[],
        tableList: tableList ?? <StoreTable>[],
        tableType: tableType,
        tableArea: tableArea,
        table: table,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载桌台数据异常:" + e.toString());
    }
  }
}

abstract class TableEvent extends Equatable {
  const TableEvent();
}

///加载本地数据
class LoadTable extends TableEvent {
  @override
  List<Object> get props => [];
}

///选择桌台
class SelectTable extends TableEvent {
  final StoreTable table;
  SelectTable({this.table});

  @override
  List<Object> get props => [this.table];
}

///查询桌台
class QueryTable extends TableEvent {
  final String typeId;
  final String areaId;
  QueryTable({this.typeId, this.areaId});

  @override
  List<Object> get props => [this.typeId, this.areaId];
}

///消台事件
class ClearTable extends TableEvent {
  final String tableId;
  ClearTable({this.tableId});
  @override
  List<Object> get props => [tableId];
}

///刷新事件
class RefreshTable extends TableEvent {
  @override
  List<Object> get props => [];
}

///转台事件
class LoadTransferTable extends TableEvent {
  final String typeId;
  final String areaId;
  LoadTransferTable({this.typeId, this.areaId});

  @override
  List<Object> get props => [this.typeId, this.areaId];
}

///转台选择
class SelectTransferTable extends TableEvent {
  final StoreTable transferOrMergeTable;
  SelectTransferTable({this.transferOrMergeTable});

  @override
  List<Object> get props => [this.transferOrMergeTable];
}

///并台事件
class LoadMergeTable extends TableEvent {
  final String typeId;
  final String areaId;
  LoadMergeTable({this.typeId, this.areaId});

  @override
  List<Object> get props => [this.typeId, this.areaId];
}

///转台选择
class SelectMergeTable extends TableEvent {
  final List<StoreTable> mergeList;
  SelectMergeTable({this.mergeList});

  @override
  List<Object> get props => [this.mergeList];
}

class TableState extends Equatable {
  ///桌台类型列表
  final List<StoreTableType> tableTypeList;

  ///桌台区域列表
  final List<StoreTableArea> tableAreaList;

  ///默认选择的类型
  final StoreTableType tableType;

  ///默认选择的类区域
  final StoreTableArea tableArea;

  ///餐桌清单
  final List<StoreTable> tableList;

  ///默认选择的餐桌
  final StoreTable table;

  ///已经开台的桌台清单
  final List<OrderTable> orderTableList;

  ///转台或并台业务-可用桌台清单
  final List<StoreTable> transferOrMergeList;

  ///转台或并台业务-默认选择的类型
  final StoreTableType transferOrMergeType;

  ///转台或并台业务-默认选择的类区域
  final StoreTableArea transferOrMergeArea;

  ///转台业务-选择的桌台
  final StoreTable transferTable;

  ///并台业务-选择的桌台
  final List<StoreTable> mergeList;

  const TableState({
    this.tableTypeList,
    this.tableAreaList,
    this.tableType,
    this.tableArea,
    this.tableList,
    this.table,
    this.orderTableList,
    this.transferOrMergeList,
    this.transferOrMergeType,
    this.transferOrMergeArea,
    this.transferTable,
    this.mergeList,
  });

  factory TableState.init() {
    return TableState(
      tableTypeList: <StoreTableType>[],
      tableAreaList: <StoreTableArea>[],
      tableType: null,
      tableArea: null,
      tableList: <StoreTable>[],
      table: null,
      orderTableList: <OrderTable>[],
      transferOrMergeList: <StoreTable>[],
      transferOrMergeType: null,
      transferOrMergeArea: null,
      transferTable: null,
      mergeList: <StoreTable>[],
    );
  }

  TableState copyWith({
    List<StoreTableType> tableTypeList,
    List<StoreTableArea> tableAreaList,
    StoreTableType tableType,
    StoreTableArea tableArea,
    List<StoreTable> tableList,
    StoreTable table,
    List<OrderTable> orderTableList,
    List<StoreTable> transferOrMergeList,
    StoreTableType transferOrMergeType,
    StoreTableArea transferOrMergeArea,
    StoreTable transferTable,
    List<StoreTable> mergeList,
  }) {
    return TableState(
      tableTypeList: tableTypeList ?? this.tableTypeList,
      tableAreaList: tableAreaList ?? this.tableAreaList,
      tableType: tableType ?? this.tableType,
      tableArea: tableArea ?? this.tableArea,
      tableList: tableList ?? this.tableList,
      table: table ?? this.table,
      orderTableList: orderTableList ?? this.orderTableList,
      transferOrMergeList: transferOrMergeList ?? this.transferOrMergeList,
      transferOrMergeType: transferOrMergeType ?? this.transferOrMergeType,
      transferOrMergeArea: transferOrMergeArea ?? this.transferOrMergeArea,
      transferTable: transferTable ?? this.transferTable,
      mergeList: mergeList ?? this.mergeList,
    );
  }

  @override
  List<Object> get props => [
        this.tableTypeList,
        this.tableAreaList,
        this.tableType,
        this.tableArea,
        this.tableList,
        this.table,
        this.orderTableList,
        this.transferOrMergeList,
        this.transferOrMergeType,
        this.transferOrMergeArea,
        this.transferTable,
        this.mergeList,
      ];
}

class TableRepository {
  ///获取桌台类型列表
  Future<List<StoreTableType>> getTableTypeList() async {
    List<StoreTableType> result = new List<StoreTableType>();
    try {
      String sql = "select * from `pos_store_table_type` where deleteFlag = 0 and id in ( select distinct typeId from pos_store_table where  deleteFlag = 0) order by no;";

      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      result = StoreTableType.toList(lists);

      //默认第一个添加全部按钮
      if (result != null && result.length > 0) {
        StoreTableType all = new StoreTableType();
        all.id = "";
        all.tenantId = Global.instance.authc.tenantId;
        all.no = "";
        all.name = "全部";
        all.color = "";
        all.deleteFlag = 0;
        all.ext1 = "";
        all.ext2 = "";
        all.ext3 = "";
        all.createUser = Constants.DEFAULT_CREATE_USER;
        all.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
        result.insert(0, all);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取桌台类型发生异常:" + e.toString());
    }
    return result;
  }

  ///获取桌台区域列表
  Future<List<StoreTableArea>> getTableAreaList() async {
    List<StoreTableArea> result = new List<StoreTableArea>();
    try {
      String sql = "select * from pos_store_table_area where deleteFlag = 0 and id in ( select distinct areaId from pos_store_table where deleteFlag = 0) order by no;";

      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      result = StoreTableArea.toList(lists);

      //默认第一个添加全部按钮
      if (result != null && result.length > 0) {
        StoreTableArea all = new StoreTableArea();
        all.id = "";
        all.tenantId = Global.instance.authc.tenantId;
        all.no = "";
        all.name = "全部";
        all.deleteFlag = 0;
        all.ext1 = "";
        all.ext2 = "";
        all.ext3 = "";
        all.createUser = Constants.DEFAULT_CREATE_USER;
        all.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
        result.insert(0, all);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取桌台区域发生异常:" + e.toString());
    }
    return result;
  }

  ///获取桌台列表
  Future<List<StoreTable>> getTableList({String typeId = "", String areaId = ""}) async {
    List<StoreTable> result = new List<StoreTable>();
    try {
      String sql = "select * from pos_store_table where deleteFlag = 0 ";

      if (StringUtils.isNotBlank(typeId)) {
        sql = "$sql and typeId = '$typeId'";
      }

      if (StringUtils.isNotBlank(areaId)) {
        sql = "$sql and areaId = '$areaId'";
      }

      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      result.addAll(StoreTable.toList(lists));
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取桌台列表发生异常:" + e.toString());
    }
    return result;
  }

  ///获取已开台或已经预订的桌台列表
  Future<List<OrderTable>> getOrderTableList() async {
    List<OrderTable> result = new List<OrderTable>();
    try {
      String sql = "select * from pos_order_table where tableStatus = 1 or tableStatus = 2 ";

      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      result.addAll(OrderTable.toList(lists));
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取开台列表发生异常:" + e.toString());
    }
    return result;
  }
}

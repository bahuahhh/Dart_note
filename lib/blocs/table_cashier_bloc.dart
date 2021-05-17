import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_base_parameter.dart';
import 'package:estore_app/entity/pos_make_info.dart';
import 'package:estore_app/entity/pos_module.dart';
import 'package:estore_app/entity/pos_pay_mode.dart';
import 'package:estore_app/entity/pos_product_category.dart';
import 'package:estore_app/entity/pos_product_spec.dart';
import 'package:estore_app/enums/order_item_join_type.dart';
import 'package:estore_app/enums/order_row_status.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/member/member.dart';
import 'package:estore_app/member/member_elec_coupon.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_item_make.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_table.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/product_ext.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/tuple.dart';

class TableCashierBloc extends Bloc<TableCashierEvent, TableCashierState> {
  //逻辑处理
  TableCashierRepository _tableCashierRepository;

  TableCashierBloc() : super(TableCashierState.init()) {
    this._tableCashierRepository = new TableCashierRepository();
  }

  @override
  Stream<TableCashierState> mapEventToState(TableCashierEvent event) async* {
    if (event is InitTableCashierData) {
      yield* _mapInitTableCashierDataToState(event);
    } else if (event is SelectMainCategory) {
      yield* _mapSelectMainCategoryToState(event);
    } else if (event is SelectSubCategory) {
      yield* _mapSelectSubCategoryToState(event);
    } else if (event is TouchProduct) {
      yield* _mapTouchProductToState(event);
    } else if (event is SelectProductSpecAndMake) {
      yield* _mapSelectProductSpecAndMakeToState(event);
    } else if (event is SelectOrderItem) {
      yield* _mapSelectOrderItemToState(event);
    } else if (event is LoadPayment) {
      yield* _mapLoadPaymentToState(event);
    } else if (event is AddPayment) {
      yield* _mapAddPaymentToState(event);
    } else if (event is ClearPayment) {
      yield* _mapClearPaymentToState(event);
    } else if (event is RefreshUi) {
      yield* _mapRefreshUiToState(event);
    } else if (event is LoadReason) {
      yield* _mapLoadReasonToState(event);
    } else if (event is SelectReason) {
      yield* _mapSelectReasonToState(event);
    } else if (event is SelectCoupon) {
      yield* _mapSelectCouponToState(event);
    }
  }

  ///加载会员优惠券列表
  Stream<TableCashierState> _mapSelectCouponToState(SelectCoupon event) async* {
    try {
      var newOrderObject = state.orderObject;

      //当前优惠券列表
      List<MemberElecCoupon> couponList = state.member.couponList ?? [];
      //已经选择的优惠券列表
      List<MemberElecCoupon> couponSelected = event.couponSelected ?? [];

      yield state.copyWith(
        orderObject: newOrderObject,
        couponSelected: couponSelected,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载会员优惠券异常:" + e.toString());
    }
  }

  ///选择折扣原因
  Stream<TableCashierState> _mapSelectReasonToState(SelectReason event) async* {
    var reasons = state.reasonsList;
    var reason = reasons.firstWhere((item) => (item.id == event.reason.id));

    var selected = BaseParameter.clone(reason);

    yield state.copyWith(
      reasonSelected: selected,
    );
  }

  ///加载折扣原因
  Stream<TableCashierState> _mapLoadReasonToState(LoadReason event) async* {
    try {
      ///加载快捷菜单
      List<BaseParameter> reasons = await OrderUtils.instance.getReason("giftReason");

      BaseParameter selected;
      if (reasons != null && reasons.length > 0) {
        selected = reasons[0];
      }
      yield state.copyWith(
        reasonsList: reasons ?? <BaseParameter>[],
        reasonSelected: selected ?? null,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载折扣原因异常:" + e.toString());
    }
  }

  ///刷新订单
  Stream<TableCashierState> _mapRefreshUiToState(RefreshUi event) async* {
    var orderId = event.orderId ?? "";
    var tradeNo = event.tradeNo ?? "";
    var member = event.member;

    var orderObject = await OrderUtils.instance.builderOrderObject(orderId, tradeNo: tradeNo);
    orderObject.member = member;

    OrderUtils.instance.calculateOrderObject(orderObject);

    OrderItem orderItem = state.orderItem;
    if (orderItem == null && orderObject.items != null && orderObject.items.length > 0) {
      orderItem = orderObject.items.last;
    }
    yield state.copyWith(
      orderObject: orderObject,
      orderItem: orderItem,
      member: member,
    );
  }

  ///清除全部已选择的支付方式清单
  Stream<TableCashierState> _mapClearPaymentToState(ClearPayment event) async* {
    try {
      var newOrderObject = OrderObject.clone(event.orderObject);
      newOrderObject.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
      newOrderObject.member = state.member;

      yield state.copyWith(
        orderObject: newOrderObject,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载本地支付方式数据异常:" + e.toString());
    }
  }

  ///添加支付方式
  Stream<TableCashierState> _mapAddPaymentToState(AddPayment event) async* {
    try {
      var newOrderObject = OrderObject.clone(event.orderObject);
      newOrderObject.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
      newOrderObject.member = state.member;

      yield state.copyWith(
        orderObject: newOrderObject,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("订单添加支付方式异常:" + e.toString());
    }
  }

  ///初始化支付方式数据,默认采用垂直滚动方式显示
  Stream<TableCashierState> _mapLoadPaymentToState(LoadPayment event) async* {
    try {
      ///加载本地支付方式
      List<PayMode> payModeAll = await OrderUtils.instance.getPayModeAll();

      ///是否合码
      bool isMergeCode = false;

      ///合码的索引
      int mergeCodeIndex = -1;

      ///当前的索引
      int currIndex = -1;

      ///整理后的支付方式集合
      var sortMap = new SplayTreeMap<int, Tuple2<PayMode, List<PayMode>>>();

      Map<int, PayMode> map = payModeAll.asMap();
      map.keys.forEach((inx) {
        ///当前实体对象
        var entity = map[inx];

        ///支付宝、微信、云闪付，合并为扫码支付
        isMergeCode = (entity.no == "04" || entity.no == "05" || entity.no == "09");
        if (isMergeCode) {
          ///首次出现合码索引
          if (mergeCodeIndex == -1) {
            mergeCodeIndex = sortMap.length + 1;
          }
          currIndex = mergeCodeIndex;
        } else {
          currIndex = sortMap.length + 1;
        }

        ///初始化
        if (!sortMap.containsKey(currIndex)) {
          if (isMergeCode) {
            sortMap[currIndex] = Tuple2(this._buildVirtualPayMode(Constants.PAYMODE_CODE_SCANPAY, "扫码支付"), <PayMode>[]);
          } else {
            sortMap[currIndex] = Tuple2(entity, <PayMode>[]);
          }
        }

        sortMap[currIndex].item2.add(entity);
      });

      var newOrderObject = state.orderObject;
      //新进入结算界面，清理会员数据，需要重新认证一次会员
      Member member = Member.cancel();
      //整单重算
      OrderUtils.instance.calculateOrderObject(newOrderObject);

      yield state.copyWith(
        orderObject: newOrderObject,
        payModeAll: payModeAll ?? <PayMode>[],
        showPayModeList: sortMap,
        member: member,
        couponSelected: <MemberElecCoupon>[],
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载本地支付方式数据异常:" + e.toString());
    }
  }

  ///构建虚拟支付对象
  PayMode _buildVirtualPayMode(String no, String name) {
    return PayMode()
      ..id = IdWorkerUtils.getInstance().generate().toString()
      ..tenantId = Global.instance.authc?.tenantId
      ..no = no
      ..name = name
      ..shortcut = ""
      ..pointFlag = 0
      ..frontFlag = 1
      ..backFlag = 0
      ..rechargeFlag = 0
      ..faceMoney = 0
      ..paidMoney = 0
      ..incomeFlag = 0
      ..orderNo = 0
      ..ext1 = ""
      ..ext2 = ""
      ..ext3 = ""
      ..deleteFlag = 0
      ..plusFlag = 0
      ..createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
      ..createUser = Constants.DEFAULT_CREATE_USER
      ..modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
      ..modifyUser = Constants.DEFAULT_MODIFY_USER;
  }

  ///单行选择操作
  Stream<TableCashierState> _mapSelectOrderItemToState(SelectOrderItem event) async* {
    var orderObject = state.orderObject;

    var orderItem = orderObject.items.firstWhere((item) {
      return event.orderItem.id == item.id;
    });

    yield state.copyWith(
      orderItem: OrderItem.clone(orderItem),
    );
  }

  ///加载商品规格列表
  Stream<TableCashierState> _mapSelectProductSpecAndMakeToState(SelectProductSpecAndMake event) async* {
    try {
      //当前规格列表
      List<ProductSpec> sepcList = event.specList ?? [];
      //已经选择的规格列表
      ProductSpec sepcSelected = event.specSelected ?? null;

      if (sepcSelected == null && sepcList.length > 0) {
        var _default = sepcList.lastWhere((item) => item.isDefault == 1, orElse: () => null);
        sepcSelected = _default ?? sepcList[0];
      } else {
        sepcSelected = ProductSpec.clone(sepcSelected);
      }

      //当前规格列表
      List<MakeInfo> makeList = await OrderUtils.instance.getProductMakeList(sepcSelected.productId);
      //已经选择的规格列表
      List<OrderItemMake> makeSelected = event.makeSelected ?? [];

      //输入的数量
      double inputQuantity = event.inputQuantity ?? 1;

      makeSelected.forEach((x) {
        x.itemQuantity = inputQuantity;

        //做法数量的变更，需要:1、区别是否控制数量；2、主单数量变更对做法数量的影响
        x.quantity = x.baseQuantity * x.itemQuantity;
        switch (x.qtyFlag) {
          case 1:
            {
              //不加价
              x.amount = 0;
            }
            break;
          case 2:
            {
              //固定加价
              x.amount = OrderUtils.instance.toRound(x.itemQuantity * x.price, precision: 2);
            }
            break;
          case 3:
            {
              //按数量加价
              x.amount = OrderUtils.instance.toRound(x.quantity * x.price, precision: 2);
            }
            break;
          default:
            {
              //不加价
              x.amount = 0;
            }
            break;
        }
      });
      yield state.copyWith(
        specList: sepcList,
        specSelected: sepcSelected,
        makeList: makeList,
        makeSelected: makeSelected,
        inputQuantity: inputQuantity,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载商品规格异常:" + e.toString());
    }
  }

  ///商品选择操作
  Stream<TableCashierState> _mapTouchProductToState(TouchProduct event) async* {
    try {
      ///获取对当前点击商品的详细信息
      var product = event.product;
      var joinType = event.joinType;
      var quantity = event.quantity;
      var labelAmount = event.labelAmount;
      var weightContinue = event.weightContinue;
      var makeList = event.makeList;

      var orderTable = event.orderTable;

      var newOrderObject = state.orderObject;

      FLogger.info("订单<${newOrderObject.tradeNo}>,选择商品<${product.barCode},${product.name},${product.salePrice}>");

      //生成行记录
      var orderItem = OrderItem.newOrderItem(newOrderObject, product, joinType, orderRowStatus: OrderRowStatus.New);

      orderItem.tableId = "";
      orderItem.tableNo = "";
      orderItem.tableName = "";
      if (orderTable != null) {
        orderItem.tableId = orderTable.tableId;
        orderItem.tableNo = orderTable.tableNo;
        orderItem.tableName = orderTable.tableName;
      }
      //连续取重标识
      //orderItem.weightContinue = weightContinue;
      //数量赋值
      if (quantity > 0) {
        orderItem.quantity = quantity;
      }

      //扫描金额码，为条码金额赋值
      if (joinType == OrderItemJoinType.ScanAmountCode) {
        orderItem.labelAmount = labelAmount;
      }

      if (makeList != null) {
        orderItem.flavors.addAll(makeList);
        orderItem.flavors.forEach((x) {
          x.orderId = newOrderObject.id;
          x.tradeNo = newOrderObject.tradeNo;
          x.itemId = orderItem.id;
        });
      }
      //压入整单行记录中
      newOrderObject.items = List.from(newOrderObject.items)..add(orderItem);
      //重算行金额
      OrderUtils.instance.calculateOrderItem(orderItem);
      //重算桌台
      if (orderTable != null) {
        OrderUtils.instance.calculateTable(newOrderObject, orderTable);
      }
      //刷新序号
      OrderUtils.instance.refreshOrderNo(newOrderObject);
      //整单重算
      OrderUtils.instance.calculateOrderObject(newOrderObject);

      yield state.copyWith(
        orderObject: newOrderObject,
        orderItem: orderItem,
      );

      if (event.callback != null) {
        event.callback();
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("商品加入购物车发生异常:" + e.toString());
    }
  }

  ///大类选择操作
  Stream<TableCashierState> _mapSelectMainCategoryToState(SelectMainCategory event) async* {
    try {
      ///分类列表
      List<ProductCategory> allCategoryList = state.allCategoryList ?? <ProductCategory>[]; //await OrderUtils.instance.getCategoryList();

      ///大类列表
      List<ProductCategory> mainCategoryList = allCategoryList.where((item) {
        return (StringUtils.isEmpty(item.parentId) || StringUtils.equalsIgnoreCase(item.parentId, "null"));
      }).toList();

      ///当前选中的大类
      ProductCategory mainCategory;

      ///选中大类对应的小类列表
      List<ProductCategory> subCategoryList;

      ///当前选中的小类
      ProductCategory subCategory;
      if (mainCategoryList != null && mainCategoryList.length > 0) {
        ///默认选中第一个大类
        mainCategory = allCategoryList.firstWhere((e) => e.id == event.categoryId);

        subCategoryList = allCategoryList.where((item) {
          return item.path.startsWith(event.categoryId + ",");
        }).toList();

        ///默认选中一个小类
        if (subCategoryList != null && subCategoryList.length > 0) {
          subCategory = subCategoryList[0];
        }
      }

      var cacheProductExtList = await OrderUtils.instance.getProductExtList();
      List<ProductExt> productList;
      if (subCategory != null) {
        productList = cacheProductExtList.where((item) => item.categoryPath.contains(subCategory.path)).toList();
      } else if (mainCategory != null) {
        productList = cacheProductExtList.where((item) => item.categoryPath.contains(mainCategory.path)).toList();
      } else {
        productList = <ProductExt>[];
      }

      yield state.copyWith(
        mainCategory: mainCategory,
        subCategoryList: subCategoryList ?? <ProductCategory>[],
        subCategory: subCategory,
        productList: productList,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载本地模块数据异常:" + e.toString());
    }
  }

  ///小类选择操作
  Stream<TableCashierState> _mapSelectSubCategoryToState(SelectSubCategory event) async* {
    try {
      ///分类列表
      List<ProductCategory> allCategoryList = state.allCategoryList ?? <ProductCategory>[]; //await OrderUtils.instance.getCategoryList();

      ///当前选中的小类
      ProductCategory subCategory = allCategoryList.firstWhere((e) => e.id == event.categoryId);

      var cacheProductExtList = await OrderUtils.instance.getProductExtList();
      List<ProductExt> productList;
      if (subCategory != null) {
        productList = cacheProductExtList.where((item) => item.categoryPath.contains(subCategory.path)).toList();
      } else {
        productList = <ProductExt>[];
      }

      yield state.copyWith(
        subCategory: subCategory,
        productList: productList,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载本地模块数据异常:" + e.toString());
    }
  }

  ///初始化界面数据，加载大类、小类、商品数据
  Stream<TableCashierState> _mapInitTableCashierDataToState(InitTableCashierData event) async* {
    try {
      OrderObject orderObject = OrderObject.clone(event.orderObject);
      OrderItem orderItem = event.orderItem;

      ///加载快捷菜单
      List<Module> shortcuts = await OrderUtils.instance.getModule(moduleNames: ["数量", "做法", "删除", "赠送", "退货"]);

      ///分类列表
      List<ProductCategory> allCategoryList = await OrderUtils.instance.getCategoryList();

      ///大类列表
      List<ProductCategory> mainCategoryList = allCategoryList.where((item) {
        return (StringUtils.isEmpty(item.parentId) || StringUtils.equalsIgnoreCase(item.parentId, "null"));
      }).toList();

      ///当前选中的大类
      ProductCategory mainCategory;

      ///选中大类对应的小类列表
      List<ProductCategory> subCategoryList;

      ///当前选中的小类
      ProductCategory subCategory;
      if (mainCategoryList != null && mainCategoryList.length > 0) {
        ///默认选中第一个大类
        mainCategory = mainCategoryList[0];

        mainCategory.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
        subCategoryList = allCategoryList.where((item) {
          return item.path.startsWith(mainCategory.id + ",");
        }).toList();

        ///默认选中一个小类
        if (subCategoryList != null && subCategoryList.length > 0) {
          subCategory = subCategoryList[0];
          subCategory.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
        }
      }

      var cacheProductExtList = await OrderUtils.instance.getProductExtList();
      List<ProductExt> productList;
      if (subCategory != null) {
        productList = cacheProductExtList.where((item) => item.categoryPath.contains(subCategory.path)).toList();
      } else if (mainCategory != null) {
        productList = cacheProductExtList.where((item) => item.categoryPath.contains(mainCategory.path)).toList();
      } else {
        productList = <ProductExt>[];
      }

      yield state.copyWith(
        shortcuts: shortcuts ?? <Module>[],
        allCategoryList: allCategoryList ?? <ProductCategory>[],
        mainCategoryList: mainCategoryList ?? <ProductCategory>[],
        mainCategory: mainCategory,
        subCategoryList: subCategoryList ?? <ProductCategory>[],
        subCategory: subCategory,
        orderObject: orderObject,
        orderItem: orderItem,
        productList: productList,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("桌台初始化数据异常:" + e.toString());
    }
  }
}

abstract class TableCashierEvent extends Equatable {
  const TableCashierEvent();

  @override
  List<Object> get props => [];
}

///加载桌台点单的默认数据
class InitTableCashierData extends TableCashierEvent {
  final OrderObject orderObject;
  final OrderItem orderItem;
  const InitTableCashierData({this.orderObject, this.orderItem});

  @override
  List<Object> get props => [this.orderObject, this.orderItem];
}

///选择商品大类
class SelectMainCategory extends TableCashierEvent {
  final String categoryId;

  SelectMainCategory({this.categoryId});

  @override
  List<Object> get props => [this.categoryId];
}

///选择商品小类
class SelectSubCategory extends TableCashierEvent {
  final String categoryId;

  SelectSubCategory({this.categoryId});

  @override
  List<Object> get props => [categoryId];
}

///用户点击商品块
class TouchProduct extends TableCashierEvent {
  final ProductExt product;
  final OrderItemJoinType joinType;
  final double quantity;
  final double labelAmount;
  final bool weightContinue;
  final List<OrderItemMake> makeList;
  final OrderTable orderTable;
  final VoidCallback callback;

  TouchProduct(this.product, {this.orderTable, this.makeList, this.quantity = 1, this.labelAmount = 0, this.joinType = OrderItemJoinType.Touch, this.weightContinue, this.callback});

  @override
  List<Object> get props => [product, orderTable, joinType, callback, quantity, labelAmount, weightContinue, makeList];
}

///选择商品规格和做法
class SelectProductSpecAndMake extends TableCashierEvent {
  final List<ProductSpec> specList;
  final ProductSpec specSelected;
  final List<MakeInfo> makeList;
  final List<OrderItemMake> makeSelected;
  final double inputQuantity;
  SelectProductSpecAndMake({this.specList, this.specSelected, this.makeList, this.makeSelected, this.inputQuantity});
  @override
  List<Object> get props => [specList, specSelected, this.makeList, this.makeSelected, this.inputQuantity];
}

///选中单行
class SelectOrderItem extends TableCashierEvent {
  final OrderItem orderItem;

  SelectOrderItem({this.orderItem});

  @override
  List<Object> get props => [orderItem];
}

///加载支付方式
class LoadPayment extends TableCashierEvent {}

///添加支付方式
class AddPayment extends TableCashierEvent {
  final OrderObject orderObject;

  AddPayment(this.orderObject);

  @override
  List<Object> get props => [orderObject];
}

///清除支付方式清单
class ClearPayment extends TableCashierEvent {
  final OrderObject orderObject;
  ClearPayment(this.orderObject);

  @override
  List<Object> get props => [this.orderObject];
}

///试算找零金额
class TryChangeAmount extends TableCashierEvent {
  final double inputAmount;

  TryChangeAmount(this.inputAmount);

  @override
  List<Object> get props => [inputAmount];
}

///刷新界面
class RefreshUi extends TableCashierEvent {
  final String orderId;
  final String tradeNo;
  final Member member;
  RefreshUi(this.orderId, {this.tradeNo = "", this.member});

  @override
  List<Object> get props => [orderId, tradeNo, member];
}

///加载折扣原因数据
class LoadReason extends TableCashierEvent {
  @override
  List<Object> get props => [];
}

///选择折扣原因
class SelectReason extends TableCashierEvent {
  final BaseParameter reason;

  SelectReason({this.reason});

  @override
  List<Object> get props => [reason];
}

///选择会员优惠券
class SelectCoupon extends TableCashierEvent {
  final OrderObject orderObject;
  final List<MemberElecCoupon> couponSelected;
  SelectCoupon(this.orderObject, {this.couponSelected});
  @override
  List<Object> get props => [this.orderObject, couponSelected];
}

class TableCashierState extends Equatable {
  ///快捷菜单模块列表
  final List<Module> shortcuts;

  ///商品分类列表
  final List<ProductCategory> allCategoryList;

  ///商品大类列表
  final List<ProductCategory> mainCategoryList;

  ///当前选中的商品大类
  final ProductCategory mainCategory;

  ///商品小类列表
  final List<ProductCategory> subCategoryList;

  ///当前选中的商品小类
  final ProductCategory subCategory;

  ///当前的商品清单
  final List<ProductExt> productList;

  ///当前的桌台订单
  final OrderObject orderObject;

  ///当前订单选择的行
  final OrderItem orderItem;

  ///商品的规格列表
  final List<ProductSpec> specList;

  ///当前选择的规格
  final ProductSpec specSelected;

  ///当前商品的可用做法列表
  final List<MakeInfo> makeList;

  ///当前选择的做法
  final List<OrderItemMake> makeSelected;

  ///输入的数量
  final double inputQuantity;

  ///全部支付方式
  final List<PayMode> payModeAll;

  ///结账界面显示的全部支付方式
  final SplayTreeMap<int, Tuple2<PayMode, List<PayMode>>> showPayModeList;

  ///会员
  final Member member;

  ///会员已选电子券清单
  final List<MemberElecCoupon> couponSelected;

  ///折扣原因列表
  final List<BaseParameter> reasonsList;

  ///当前选择原因
  final BaseParameter reasonSelected;

  const TableCashierState({
    this.shortcuts,
    this.allCategoryList,
    this.mainCategoryList,
    this.mainCategory,
    this.subCategoryList,
    this.subCategory,
    this.productList,
    this.orderObject,
    this.orderItem,
    this.specList,
    this.specSelected,
    this.makeList,
    this.makeSelected,
    this.inputQuantity,
    this.payModeAll,
    this.showPayModeList,
    this.member,
    this.reasonsList,
    this.reasonSelected,
    this.couponSelected,
  });

  ///初始化
  factory TableCashierState.init() {
    return TableCashierState(
      shortcuts: <Module>[],
      allCategoryList: <ProductCategory>[],
      mainCategoryList: <ProductCategory>[],
      mainCategory: null,
      subCategoryList: <ProductCategory>[],
      subCategory: null,
      productList: <ProductExt>[],
      orderObject: null,
      orderItem: null,
      specList: [],
      specSelected: null,
      makeList: [],
      makeSelected: [],
      inputQuantity: 1,
      payModeAll: <PayMode>[],
      showPayModeList: SplayTreeMap<int, Tuple2<PayMode, List<PayMode>>>(),
      member: null,
      reasonsList: [],
      reasonSelected: null,
      couponSelected: <MemberElecCoupon>[],
    );
  }

  TableCashierState copyWith({
    List<Module> shortcuts,
    List<ProductCategory> allCategoryList,
    List<ProductCategory> mainCategoryList,
    ProductCategory mainCategory,
    List<ProductCategory> subCategoryList,
    ProductCategory subCategory,
    List<ProductExt> productList,
    OrderObject orderObject,
    OrderItem orderItem,
    List<ProductSpec> specList,
    ProductSpec specSelected,
    List<MakeInfo> makeList,
    List<OrderItemMake> makeSelected,
    double inputQuantity,
    List<PayMode> payModeAll,
    SplayTreeMap<int, Tuple2<PayMode, List<PayMode>>> showPayModeList,
    List<BaseParameter> reasonsList,
    Member member,
    BaseParameter reasonSelected,
    List<MemberElecCoupon> couponSelected,
  }) {
    Member newMember = (member != null ? (member.id == null ? null : member) : this.member);
    return TableCashierState(
      shortcuts: shortcuts ?? this.shortcuts,
      allCategoryList: allCategoryList ?? this.allCategoryList,
      mainCategoryList: mainCategoryList ?? this.mainCategoryList,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategoryList: subCategoryList ?? this.subCategoryList,
      subCategory: subCategory ?? this.subCategory,
      productList: productList ?? this.productList,
      orderObject: orderObject ?? this.orderObject,
      orderItem: orderItem ?? this.orderItem,
      specList: specList ?? this.specList,
      specSelected: specSelected ?? this.specSelected,
      makeList: makeList ?? this.makeList,
      makeSelected: makeSelected ?? this.makeSelected,
      inputQuantity: inputQuantity ?? this.inputQuantity,
      payModeAll: payModeAll ?? this.payModeAll,
      showPayModeList: showPayModeList ?? this.showPayModeList,
      member: newMember,
      reasonsList: reasonsList ?? this.reasonsList,
      reasonSelected: reasonSelected ?? this.reasonSelected,
      couponSelected: couponSelected ?? this.couponSelected,
    );
  }

  @override
  List<Object> get props => [
        shortcuts,
        allCategoryList,
        mainCategoryList,
        mainCategory,
        subCategoryList,
        subCategory,
        productList,
        orderObject,
        orderItem,
        specList,
        specSelected,
        makeList,
        makeSelected,
        inputQuantity,
        payModeAll,
        showPayModeList,
        member,
        reasonsList,
        reasonSelected,
        couponSelected,
      ];
}

class TableCashierRepository {}

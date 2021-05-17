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
import 'package:estore_app/enums/bargain_source_enum.dart';
import 'package:estore_app/enums/order_item_join_type.dart';
import 'package:estore_app/enums/promotion_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/member/member_card_recharge_scheme.dart';
import 'package:estore_app/member/member_elec_coupon.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_item_make.dart';
import 'package:estore_app/order/order_item_promotion.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/product_ext.dart';
import 'package:estore_app/order/promotion_utils.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:sprintf/sprintf.dart';

class CashierBloc extends Bloc<CashierEvent, CashierState> {
  //逻辑处理
  CashierRepository _cashierRepository;

  CashierBloc() : super(CashierState.init()) {
    this._cashierRepository = new CashierRepository();
  }

  @override
  Stream<CashierState> mapEventToState(CashierEvent event) async* {
    if (event is Load) {
      yield* _mapLoadToState(event);
    } else if (event is SelectMainCategory) {
      yield* _mapSelectMainCategoryToState(event);
    } else if (event is SelectSubCategory) {
      yield* _mapSelectSubCategoryToState(event);
    } else if (event is NewOrderObject) {
      yield* _mapNewOrderObjectToState(event);
    } else if (event is TouchProduct) {
      yield* _mapTouchProductToState(event);
    } else if (event is SelectOrderItem) {
      yield* _mapSelectOrderItemToState(event);
    } else if (event is QuantityChanged) {
      yield* _mapQuantityChangedToState(event);
    } else if (event is DeleteOrderItem) {
      yield* _mapDeleteOrderItemToState(event);
    } else if (event is RefreshUi) {
      yield* _mapRefreshUiToState(event);
    } else if (event is LoadPayment) {
      yield* _mapLoadPaymentToState(event);
    } else if (event is TryChangeAmount) {
      yield* _mapTryChangeAmountToState(event);
    } else if (event is AddPayment) {
      yield* _mapAddPaymentToState(event);
    } else if (event is ClearPayment) {
      yield* _mapClearPaymentToState(event);
    } else if (event is LoadReason) {
      yield* _mapLoadReasonToState(event);
    } else if (event is SelectReason) {
      yield* _mapSelectReasonToState(event);
    } else if (event is BargainChanged) {
      yield* _mapBargainChangedToState(event);
    } else if (event is GiftChanged) {
      yield* _mapGiftChangedToState(event);
    } else if (event is DiscountChanged) {
      yield* _mapDiscountChangedToState(event);
    } else if (event is BargainTypeChanged) {
      yield* _mapBargainTypeChangedToState(event);
    } else if (event is SelectProductSpec) {
      yield* _mapSelectProductSpecToState(event);
    } else if (event is SelectCoupon) {
      yield* _mapSelectCouponToState(event);
    } else if (event is OrderObjectFinished) {
      yield* _mapOrderObjectFinishedToState(event);
    }
  }

  ///结账功能
  Stream<CashierState> _mapOrderObjectFinishedToState(OrderObjectFinished event) async* {
    try {
      var orderObject = event.orderObject;

      var newOrderObject = OrderObject.clone(orderObject);

      newOrderObject.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");

      print(">>>>点击结账按钮>>>>${newOrderObject.pays.toString()}");

      yield state.copyWith(
        orderObject: newOrderObject,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载本地支付方式数据异常:" + e.toString());
    }
  }

  ///加载商品规格列表
  Stream<CashierState> _mapSelectProductSpecToState(SelectProductSpec event) async* {
    try {
      //当前规格列表
      List<ProductSpec> sepcList = event.specList ?? [];
      //已经选择的规格列表
      ProductSpec sepcSelected = event.specSelected ?? null;

      print("@@@@@@@@@@@@@@@@>>>>${sepcList.toString()}");

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

  ///加载会员优惠券列表
  Stream<CashierState> _mapSelectCouponToState(SelectCoupon event) async* {
    try {
      var newOrderObject = OrderObject.clone(event.orderObject);

      //当前优惠券列表
      List<MemberElecCoupon> couponList = event.couponList ?? [];
      //已经选择的优惠券列表
      List<MemberElecCoupon> couponSelected = event.couponSelected ?? [];

      yield state.copyWith(
        orderObject: newOrderObject,
        couponList: couponList,
        couponSelected: couponSelected,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载会员优惠券异常:" + e.toString());
    }
  }

  ///修改议价参数
  Stream<CashierState> _mapBargainTypeChangedToState(BargainTypeChanged event) async* {
    //议价方式
    BargainSourceEnum newBargainType = event.bargainType ?? state.bargainType;
    yield state.copyWith(
      bargainType: newBargainType,
    );
  }

  ///折扣操作
  Stream<CashierState> _mapDiscountChangedToState(DiscountChanged event) async* {
    var orderItem = event.orderItem;
    var discountRate = OrderUtils.instance.toRound(event.discountValue / 100, precision: 4);
    var reason = event.discountReason;
    //回复原价操作
    var restoreOriginalPrice = event.restoreOriginalPrice;

    var newOrderItem = OrderItem.clone(orderItem);

    //恢复原价
    if (restoreOriginalPrice) {
      if (newOrderItem.promotions != null && newOrderItem.promotions.any((item) => item.promotionType == PromotionType.ProductDiscount)) {
        newOrderItem.promotions.removeWhere((item) => item.promotionType == PromotionType.ProductDiscount);
      }
    } else {
      //此处将SalePrice改为Price
      var discountPrice = OrderUtils.instance.toRound(newOrderItem.price * discountRate, precision: 2);
      if (orderItem.price <= discountPrice) {
        //优惠价格不及当前价格，不做处理
        return;
      }
      OrderItemPromotion promotion;
      if (newOrderItem.promotions != null && newOrderItem.promotions.any((item) => item.promotionType == PromotionType.ProductDiscount)) {
        promotion = newOrderItem.promotions.firstWhere((item) => item.promotionType == PromotionType.ProductDiscount);
        promotion.createUser = Global.instance.worker.no;
        promotion.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
      } else {
        promotion = PromotionUtils.instance.newOrderItemPromotion(newOrderItem, PromotionType.ProductDiscount);
        newOrderItem.promotions.add(promotion);
      }

      promotion.onlineFlag = 0;
      promotion.bargainPrice = discountPrice;
      promotion.reason = reason;
      promotion.discountRate = discountRate;
      promotion.enabled = 0;
    }

    //重新计算行小计
    OrderUtils.instance.calculateOrderItem(newOrderItem);

    var newOrderObject = OrderObject.clone(state.orderObject);
    var orderItemIndex = newOrderObject.items.indexWhere((item) => item.id == newOrderItem.id);
    newOrderObject.items[orderItemIndex] = newOrderItem;

    //重新计算整单金额
    OrderUtils.instance.calculateOrderObject(newOrderObject);

    yield state.copyWith(
      orderObject: newOrderObject,
      orderItem: newOrderItem,
    );
  }

  ///赠送操作
  Stream<CashierState> _mapGiftChangedToState(GiftChanged event) async* {
    var orderItem = event.orderItem;
    var giftReason = event.giftReason;

    var newOrderItem = OrderItem.clone(orderItem);
    // //赠送的优先级最高，刪除除赠送外的全部优惠列表
    // if (newOrderItem.promotions != null) {
    //   newOrderItem.promotions.removeWhere((item) => item.promotionType != PromotionType.Gift);
    // }
    // //赠送计入优惠清单
    // OrderItemPromotion promotion;
    // //优惠清单中如果包含赠送优惠，直接修改值，否则新增赠送优惠
    // if (newOrderItem.promotions != null && newOrderItem.promotions.any((item) => item.promotionType == PromotionType.Gift)) {
    //   promotion = newOrderItem.promotions.firstWhere((item) => item.promotionType == PromotionType.Gift);
    //   promotion.createUser = Global.instance.worker.no;
    //   promotion.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
    // } else {
    //   promotion = PromotionUtils.instance.newOrderItemPromotion(newOrderItem, PromotionType.Gift);
    //   newOrderItem.promotions.add(promotion);
    // }
    // //优惠前价格
    // promotion.price = 0;
    // //将议价金额重置为0，避免先议价再赠送
    // promotion.bargainPrice = 0;
    // //优惠前的金额
    // promotion.amount = newOrderItem.amount;
    // //优惠金额
    // promotion.discountAmount = newOrderItem.amount;
    // //优惠率
    // promotion.discountRate = 100;
    // //优惠后的金额
    // promotion.receivableAmount = 0;
    // //赠送原因
    // promotion.reason = reason;
    // //是否启用该优惠
    // promotion.enabled = 1;

    newOrderItem.giftQuantity = newOrderItem.quantity - newOrderItem.refundQuantity;
    //赠菜原因
    newOrderItem.giftReason = giftReason;
    //重新计算行小计
    OrderUtils.instance.calculateOrderItem(newOrderItem);

    var newOrderObject = OrderObject.clone(state.orderObject);
    var orderItemIndex = newOrderObject.items.indexWhere((item) => item.id == newOrderItem.id);
    newOrderObject.items[orderItemIndex] = newOrderItem;

    ///重新计算整单金额
    OrderUtils.instance.calculateOrderObject(newOrderObject);

    yield state.copyWith(
      orderObject: newOrderObject,
      orderItem: newOrderItem,
    );
  }

  ///议价操作
  Stream<CashierState> _mapBargainChangedToState(BargainChanged event) async* {
    var orderItem = event.orderItem;
    var price = event.bargainValue;
    var reason = event.bargainReason;
    //回复原价操作
    var restoreOriginalPrice = event.restoreOriginalPrice;

    var newOrderItem = OrderItem.clone(orderItem);

    //恢复原价
    if (restoreOriginalPrice) {
      if (newOrderItem.promotions != null && newOrderItem.promotions.any((item) => item.promotionType == PromotionType.ProductBargain)) {
        newOrderItem.promotions.removeWhere((item) => item.promotionType == PromotionType.ProductBargain);
      }
    } else {
      if (price != newOrderItem.price) {
        //零价商品特殊处理，直接修改原售价、会员价
        if (newOrderItem.salePrice == 0) {
          newOrderItem.salePrice = price;
          newOrderItem.vipPrice = price;
        } else {
          OrderItemPromotion promotion;
          //
          if (newOrderItem.promotions != null && newOrderItem.promotions.any((item) => item.promotionType == PromotionType.ProductBargain)) {
            promotion = newOrderItem.promotions.firstWhere((item) => item.promotionType == PromotionType.ProductBargain);
            promotion.createUser = Global.instance.worker.no;
            promotion.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
          } else {
            promotion = PromotionUtils.instance.newOrderItemPromotion(newOrderItem, PromotionType.ProductBargain);
            newOrderItem.promotions.add(promotion);
          }

          promotion.onlineFlag = 0;
          promotion.bargainPrice = price;
          promotion.reason = reason;
          promotion.enabled = 0;
        }
      }
    }

    //重新计算行小计
    OrderUtils.instance.calculateOrderItem(newOrderItem);

    var newOrderObject = OrderObject.clone(state.orderObject);
    var orderItemIndex = newOrderObject.items.indexWhere((item) => item.id == newOrderItem.id);
    newOrderObject.items[orderItemIndex] = newOrderItem;

    //重新计算整单金额
    OrderUtils.instance.calculateOrderObject(newOrderObject);

    yield state.copyWith(
      orderObject: newOrderObject,
      orderItem: newOrderItem,
    );
  }

  ///选择折扣原因
  Stream<CashierState> _mapSelectReasonToState(SelectReason event) async* {
    var reasons = state.reasonsList;
    var reason = reasons.firstWhere((item) => (item.id == event.reason.id));

    var selected = BaseParameter.clone(reason);

    yield state.copyWith(
      reasonSelected: selected,
    );
  }

  ///加载折扣原因
  Stream<CashierState> _mapLoadReasonToState(LoadReason event) async* {
    try {
      ///加载快捷菜单
      List<BaseParameter> reasons = await OrderUtils.instance.getReason("bargainDiscountReason");

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

  ///清除全部已选择的支付方式清单
  Stream<CashierState> _mapClearPaymentToState(ClearPayment event) async* {
    try {
      var newOrderObject = OrderObject.clone(event.orderObject);
      newOrderObject.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");

      yield state.copyWith(
        orderObject: newOrderObject,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加载本地支付方式数据异常:" + e.toString());
    }
  }

  ///添加支付方式
  Stream<CashierState> _mapAddPaymentToState(AddPayment event) async* {
    try {
      var newOrderObject = OrderObject.clone(event.orderObject);
      newOrderObject.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");

      yield state.copyWith(
        orderObject: newOrderObject,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("订单添加支付方式异常:" + e.toString());
    }
  }

  ///试算找零金额
  Stream<CashierState> _mapTryChangeAmountToState(TryChangeAmount event) async* {
    try {
      var orderObject = state.orderObject;
      var inputAmount = event.inputAmount;

      var newOrderObject = OrderObject.clone(orderObject);

      ///录入金额
      double totalInputAmount = 0;
      newOrderObject.pays.forEach((item) {
        totalInputAmount += item.inputAmount;
      });

      ///计算找零金额
      var receivableAmount = newOrderObject.paidAmount.abs();
      var changeAmount = totalInputAmount + inputAmount - receivableAmount;

      newOrderObject.changeAmount = OrderUtils.instance.toRound((changeAmount <= 0 ? 0 : changeAmount), precision: 2);

      yield state.copyWith(
        orderObject: newOrderObject,
      );
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("试算找零数据异常:" + e.toString());
    }
  }

  ///初始化支付方式数据,默认采用垂直滚动方式显示
  Stream<CashierState> _mapLoadPaymentToState(LoadPayment event) async* {
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

      MemberCardRechargeScheme rechargeScheme = state.rechargeScheme;
      List<MemberElecCoupon> newCouponList = state.couponList ?? <MemberElecCoupon>[];
      List<MemberElecCoupon> couponSelected = state.couponSelected ?? <MemberElecCoupon>[];

      //整单重算
      OrderUtils.instance.calculateOrderObject(newOrderObject);

      yield state.copyWith(
        orderObject: newOrderObject,
        payModeAll: payModeAll ?? <PayMode>[],
        showPayModeList: sortMap,
        couponList: newCouponList,
        couponSelected: couponSelected,
        rechargeScheme: rechargeScheme,
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

  ///刷新订单
  Stream<CashierState> _mapRefreshUiToState(RefreshUi event) async* {
    //取消会员或者更换会员情况下，优惠券清单和选择清单需要清空
    var couponList = event.couponList ?? <MemberElecCoupon>[];
    var couponSelected = event.couponSelected ?? <MemberElecCoupon>[];
    yield state.copyWith(
      orderObject: event.orderObject,
      couponList: couponList,
      couponSelected: couponSelected,
    );
  }

  ///单行删除操作
  Stream<CashierState> _mapDeleteOrderItemToState(DeleteOrderItem event) async* {
    var orderObject = state.orderObject;

    ///等待删除的行
    var waitDeleteOrderItem = event.orderItem;
    var lastIndex = orderObject.items.lastIndexOf(waitDeleteOrderItem);
    var nextOderItem;

    ///下一行存在，优先默认选中下一行
    if (lastIndex + 1 < orderObject.items.length) {
      nextOderItem = orderObject.items[lastIndex + 1];
    } else if (lastIndex - 1 >= 0) {
      ///下一行不存在，优先优先选择上一行
      nextOderItem = orderObject.items[lastIndex - 1];
    } else {
      nextOderItem = OrderItem.empty();
    }

    orderObject.items = List.from(orderObject.items)..removeWhere((item) => item.id == waitDeleteOrderItem.id);

    ///刷新序号
    OrderUtils.instance.refreshOrderNo(orderObject);

    OrderUtils.instance.calculateOrderObject(orderObject);

    yield state.copyWith(
      orderObject: orderObject,
      orderItem: nextOderItem,
    );
  }

  ///数量加操作
  Stream<CashierState> _mapQuantityChangedToState(QuantityChanged event) async* {
    final currentState = state;
    if (currentState is CashierState) {
      var orderObject = currentState.orderObject;

      var orderItem = OrderItem.clone(event.orderItem);

      orderItem.quantity = event.newValue;

      ///重新计算行小计
      OrderUtils.instance.calculateOrderItem(orderItem);

      orderObject.items[orderItem.orderNo - 1] = orderItem;

      ///重新计算整单金额
      OrderUtils.instance.calculateOrderObject(orderObject);

      yield state.copyWith(
        orderObject: orderObject,
        orderItem: orderItem,
      );
    }
  }

  ///单行选择操作
  Stream<CashierState> _mapSelectOrderItemToState(SelectOrderItem event) async* {
    var orderObject = state.orderObject;

    var orderItem = orderObject.items.firstWhere((item) {
      return event.orderItem.id == item.id;
    });

    yield state.copyWith(
      orderItem: OrderItem.clone(orderItem),
    );
  }

  ///商品选择操作
  Stream<CashierState> _mapTouchProductToState(TouchProduct event) async* {
    try {
      ///获取对当前点击商品的详细信息
      var product = event.product;
      var joinType = event.joinType;
      var quantity = event.quantity;
      var labelAmount = event.labelAmount;
      var weightContinue = event.weightContinue;
      var makeList = event.makeList;

      var newOrderObject = OrderObject.clone(state.orderObject);
      //如果没有生成订单号，系统主动生成
      if (StringUtils.isEmpty(newOrderObject.tradeNo)) {
        var ticketNoResult = await OrderUtils.instance.generateTicketNo();
        if (ticketNoResult.item1) {
          newOrderObject.tradeNo = ticketNoResult.item3;
        } else {
          FLogger.error("生成订单编号出错了");
        }
      }
      FLogger.info("订单<${newOrderObject.tradeNo}>,选择商品<${product.barCode},${product.name},${product.salePrice}>");
      //生成行记录
      var orderItem = OrderItem.newOrderItem(newOrderObject, product, joinType);

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
      //刷新序号
      OrderUtils.instance.refreshOrderNo(newOrderObject);
      //整单重算
      OrderUtils.instance.calculateOrderObject(newOrderObject);

      yield state.copyWith(
        orderObject: newOrderObject,
        orderItem: orderItem,
        specList: [],
        specSelected: null,
      );

      if (event.callback != null) {
        event.callback();
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("商品加入购物车发生异常:" + e.toString());
    }
  }

  ///生成新订单编号
  Stream<CashierState> _mapNewOrderObjectToState(NewOrderObject event) async* {
    //生成新订单,该操作并没有生成tradeNo
    var newOrderObject = OrderObject.newOrderObject();

    var ticketNoResult = await OrderUtils.instance.generateTicketNo();
    if (ticketNoResult.item1) {
      newOrderObject.tradeNo = ticketNoResult.item3;
    }

    yield state.copyWith(
      orderObject: newOrderObject,
      specList: <ProductSpec>[],
      specSelected: null,
      makeList: <MakeInfo>[],
      makeSelected: <OrderItemMake>[],
      inputQuantity: 0,
      couponList: <MemberElecCoupon>[],
      couponSelected: <MemberElecCoupon>[],
    );
  }

  ///大类选择操作
  Stream<CashierState> _mapSelectMainCategoryToState(SelectMainCategory event) async* {
    try {
      ///分类列表
      List<ProductCategory> allCategoryList = await this._cashierRepository.getCategoryList();

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

      var cacheData = await OrderUtils.instance.getProductExtList();
      List<ProductExt> productList;
      if (subCategory != null) {
        productList = cacheData.where((item) => item.categoryPath.contains(subCategory.path)).toList();
      } else if (mainCategory != null) {
        productList = cacheData.where((item) => item.categoryPath.contains(mainCategory.path)).toList();
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
  Stream<CashierState> _mapSelectSubCategoryToState(SelectSubCategory event) async* {
    try {
      ///分类列表
      List<ProductCategory> allCategoryList = await this._cashierRepository.getCategoryList();

      ///当前选中的小类
      ProductCategory subCategory = allCategoryList.firstWhere((e) => e.id == event.categoryId);

      var cacheData = await OrderUtils.instance.getProductExtList();
      List<ProductExt> productList;
      if (subCategory != null) {
        productList = cacheData.where((item) => item.categoryPath.contains(subCategory.path)).toList();
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
  Stream<CashierState> _mapLoadToState(event) async* {
    try {
      ///加载快捷菜单
      List<Module> shortcuts = await this._cashierRepository.getShortcutModule();

      ///加载更多功能
      List<Module> mores = await this._cashierRepository.getMoreModule();

      ///分类列表
      List<ProductCategory> allCategoryList = await this._cashierRepository.getCategoryList();

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

        subCategoryList = allCategoryList.where((item) {
          return item.path.startsWith(mainCategory.id + ",");
        }).toList();

        ///默认选中一个小类
        if (subCategoryList != null && subCategoryList.length > 0) {
          subCategory = subCategoryList[0];
        }
      }

      var cacheData = await OrderUtils.instance.getProductExtList();
      List<ProductExt> productList;
      if (subCategory != null) {
        productList = cacheData.where((item) => item.categoryPath.contains(subCategory.path)).toList();
      } else if (mainCategory != null) {
        productList = cacheData.where((item) => item.categoryPath.contains(mainCategory.path)).toList();
      } else {
        productList = <ProductExt>[];
      }

      yield state.copyWith(
        shortcuts: shortcuts ?? <Module>[],
        mores: mores ?? <Module>[],
        allCategoryList: allCategoryList ?? <ProductCategory>[],
        mainCategoryList: mainCategoryList ?? <ProductCategory>[],
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
}

abstract class CashierEvent extends Equatable {
  const CashierEvent();

  @override
  List<Object> get props => [];
}

///加载本地数据
class Load extends CashierEvent {}

///生成新订单
class NewOrderObject extends CashierEvent {}

///用户点击商品块
class TouchProduct extends CashierEvent {
  final ProductExt product;
  final OrderItemJoinType joinType;
  final double quantity;
  final double labelAmount;
  final bool weightContinue;
  final List<OrderItemMake> makeList;
  final VoidCallback callback;

  TouchProduct(this.product, {this.makeList, this.quantity = 1, this.labelAmount = 0, this.joinType = OrderItemJoinType.Touch, this.weightContinue, this.callback});

  @override
  List<Object> get props => [product, joinType, callback, quantity, labelAmount, weightContinue, makeList];
}

///选中单行
class SelectOrderItem extends CashierEvent {
  final OrderItem orderItem;

  SelectOrderItem({this.orderItem});

  @override
  List<Object> get props => [orderItem];
}

///数量加减
class QuantityChanged extends CashierEvent {
  final OrderItem orderItem;
  final double newValue;

  QuantityChanged(this.orderItem, this.newValue);

  @override
  List<Object> get props => [orderItem, newValue];
}

///删除单行
class DeleteOrderItem extends CashierEvent {
  final OrderItem orderItem;

  DeleteOrderItem(this.orderItem);

  @override
  List<Object> get props => [orderItem];
}

///刷新界面
class RefreshUi extends CashierEvent {
  final OrderObject orderObject;
  final List<MemberElecCoupon> couponList;
  final List<MemberElecCoupon> couponSelected;

  RefreshUi(this.orderObject, {this.couponList, this.couponSelected});

  @override
  List<Object> get props => [orderObject, couponList, couponSelected];
}

///选择商品大类
class SelectMainCategory extends CashierEvent {
  final String categoryId;

  SelectMainCategory({this.categoryId});

  @override
  List<Object> get props => [this.categoryId];
}

///选择商品小类
class SelectSubCategory extends CashierEvent {
  final String categoryId;

  SelectSubCategory({this.categoryId});

  @override
  List<Object> get props => [categoryId];
}

///加载支付方式
class LoadPayment extends CashierEvent {}

///添加支付方式
class AddPayment extends CashierEvent {
  final OrderObject orderObject;

  AddPayment(this.orderObject);

  @override
  List<Object> get props => [orderObject];
}

///清除支付方式清单
class ClearPayment extends CashierEvent {
  final OrderObject orderObject;
  ClearPayment(this.orderObject);

  @override
  List<Object> get props => [this.orderObject];
}

///试算找零金额
class TryChangeAmount extends CashierEvent {
  final double inputAmount;

  TryChangeAmount(this.inputAmount);

  @override
  List<Object> get props => [inputAmount];
}

///加载折扣原因数据
class LoadReason extends CashierEvent {
  @override
  List<Object> get props => [];
}

///选择折扣原因
class SelectReason extends CashierEvent {
  final BaseParameter reason;

  SelectReason({this.reason});

  @override
  List<Object> get props => [reason];
}

///选择商品规格
class SelectProductSpec extends CashierEvent {
  final List<ProductSpec> specList;
  final ProductSpec specSelected;
  final List<MakeInfo> makeList;
  final List<OrderItemMake> makeSelected;
  final double inputQuantity;
  SelectProductSpec({this.specList, this.specSelected, this.makeList, this.makeSelected, this.inputQuantity});
  @override
  List<Object> get props => [specList, specSelected, this.makeList, this.makeSelected, this.inputQuantity];
}

///折扣
class DiscountChanged extends CashierEvent {
  final OrderItem orderItem;
  final double discountValue;
  final String discountReason;
  final bool restoreOriginalPrice;
  DiscountChanged(this.orderItem, this.discountValue, this.discountReason, {this.restoreOriginalPrice = false});

  @override
  List<Object> get props => [orderItem, discountValue, discountReason, restoreOriginalPrice];
}

///修改议价方式参数
class BargainTypeChanged extends CashierEvent {
  //改价方式
  final BargainSourceEnum bargainType;

  BargainTypeChanged({this.bargainType});

  @override
  List<Object> get props => [bargainType];
}

///改价
class BargainChanged extends CashierEvent {
  final OrderItem orderItem;
  final double bargainValue;
  final String bargainReason;
  final bool restoreOriginalPrice;

  BargainChanged(this.orderItem, this.bargainValue, this.bargainReason, {this.restoreOriginalPrice = false});

  @override
  List<Object> get props => [orderItem, bargainValue, bargainReason, restoreOriginalPrice];
}

///赠送
class GiftChanged extends CashierEvent {
  final OrderItem orderItem;
  final String giftReason;
  GiftChanged(this.orderItem, this.giftReason);

  @override
  List<Object> get props => [orderItem, giftReason];
}

///选择会员优惠券
class SelectCoupon extends CashierEvent {
  final OrderObject orderObject;
  final List<MemberElecCoupon> couponList;
  final List<MemberElecCoupon> couponSelected;
  SelectCoupon(this.orderObject, {this.couponList, this.couponSelected});
  @override
  List<Object> get props => [this.orderObject, couponList, couponSelected];
}

///订单结账操作
class OrderObjectFinished extends CashierEvent {
  final OrderObject orderObject;
  OrderObjectFinished(this.orderObject);

  @override
  List<Object> get props => [this.orderObject];
}

class CashierState extends Equatable {
  ///快捷菜单模块列表
  final List<Module> shortcuts;

  ///更多菜单模块列表
  final List<Module> mores;

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

  ///当前选中的商品小类
  final List<ProductExt> productList;

  final OrderObject orderObject;

  final OrderItem orderItem;

  ///折扣原因列表
  final List<BaseParameter> reasonsList;

  ///当前选择原因
  final BaseParameter reasonSelected;

  ///议价类型
  final BargainSourceEnum bargainType;

  ///全部支付方式
  final List<PayMode> payModeAll;

  ///结账界面显示的全部支付方式
  final SplayTreeMap<int, Tuple2<PayMode, List<PayMode>>> showPayModeList;

  ///商品的规格列表
  final List<ProductSpec> specList;

  ///当前选择的规格
  final ProductSpec specSelected;

  ///当前商品的可用做法
  final List<MakeInfo> makeList;

  ///当前选择的做法
  final List<OrderItemMake> makeSelected;

  ///输入的数量
  final double inputQuantity;

  ///会员充值方案
  final MemberCardRechargeScheme rechargeScheme;

  ///会员电子券清单
  final List<MemberElecCoupon> couponList;

  ///会员已选电子券清单
  final List<MemberElecCoupon> couponSelected;

  const CashierState({
    this.shortcuts,
    this.mores,
    this.allCategoryList,
    this.mainCategoryList,
    this.mainCategory,
    this.subCategoryList,
    this.subCategory,
    this.productList,
    this.orderObject,
    this.orderItem,
    this.reasonsList,
    this.reasonSelected,
    this.payModeAll,
    this.showPayModeList,
    this.bargainType,
    this.specList,
    this.specSelected,
    this.makeList,
    this.makeSelected,
    this.inputQuantity,
    this.couponList,
    this.couponSelected,
    this.rechargeScheme,
  });

  ///初始化
  factory CashierState.init() {
    return CashierState(
      shortcuts: <Module>[],
      mores: <Module>[],
      allCategoryList: <ProductCategory>[],
      mainCategoryList: <ProductCategory>[],
      mainCategory: null,
      subCategoryList: <ProductCategory>[],
      subCategory: null,
      productList: <ProductExt>[],
      orderObject: OrderObject.newOrderObject(),
      orderItem: null,
      reasonsList: [],
      reasonSelected: null,
      payModeAll: <PayMode>[],
      showPayModeList: SplayTreeMap<int, Tuple2<PayMode, List<PayMode>>>(),
      bargainType: BargainSourceEnum.Price,
      specList: [],
      specSelected: null,
      makeList: [],
      makeSelected: [],
      inputQuantity: 1,
      couponList: [],
      couponSelected: [],
      rechargeScheme: null,
    );
  }

  CashierState copyWith({
    List<Module> shortcuts,
    List<Module> mores,
    List<ProductCategory> allCategoryList,
    List<ProductCategory> mainCategoryList,
    ProductCategory mainCategory,
    List<ProductCategory> subCategoryList,
    ProductCategory subCategory,
    List<ProductExt> productList,
    OrderObject orderObject,
    OrderItem orderItem,
    bool showKeyboard,
    List<PayMode> payModeAll,
    SplayTreeMap<int, Tuple2<PayMode, List<PayMode>>> showPayModeList,
    SplayTreeMap<int, Tuple2<PayMode, List<PayMode>>> customPayModeList,
    List<BaseParameter> reasonsList,
    BaseParameter reasonSelected,
    BargainSourceEnum bargainType,
    List<ProductSpec> specList,
    ProductSpec specSelected,
    List<MakeInfo> makeList,
    List<OrderItemMake> makeSelected,
    double inputQuantity,
    MemberCardRechargeScheme rechargeScheme,
    List<MemberElecCoupon> couponList,
    List<MemberElecCoupon> couponSelected,
  }) {
    return CashierState(
      shortcuts: shortcuts ?? this.shortcuts,
      mores: mores ?? this.mores,
      allCategoryList: allCategoryList ?? this.allCategoryList,
      mainCategoryList: mainCategoryList ?? this.mainCategoryList,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategoryList: subCategoryList ?? this.subCategoryList,
      subCategory: subCategory ?? this.subCategory,
      productList: productList ?? this.productList,
      orderObject: orderObject ?? this.orderObject,
      orderItem: orderItem ?? this.orderItem,
      reasonsList: reasonsList ?? this.reasonsList,
      reasonSelected: reasonSelected ?? this.reasonSelected,
      payModeAll: payModeAll ?? this.payModeAll,
      showPayModeList: showPayModeList ?? this.showPayModeList,
      bargainType: bargainType ?? this.bargainType,
      specList: specList ?? this.specList,
      specSelected: specSelected ?? this.specSelected,
      makeList: makeList ?? this.makeList,
      makeSelected: makeSelected ?? this.makeSelected,
      inputQuantity: inputQuantity ?? this.inputQuantity,
      rechargeScheme: rechargeScheme ?? this.rechargeScheme,
      couponList: couponList ?? this.couponList,
      couponSelected: couponSelected ?? this.couponSelected,
    );
  }

  @override
  List<Object> get props => [
        shortcuts,
        mores,
        allCategoryList,
        mainCategoryList,
        mainCategory,
        subCategoryList,
        subCategory,
        productList,
        orderObject,
        orderItem,
        reasonsList,
        reasonSelected,
        payModeAll,
        showPayModeList,
        bargainType,
        specList,
        specSelected,
        makeList,
        makeSelected,
        inputQuantity,
        couponList,
        rechargeScheme,
        couponSelected,
      ];
}

class CashierRepository {
  ///获取快捷菜单数据
  Future<List<Module>> getShortcutModule() async {
    List<Module> result = new List<Module>();
    try {
      String sql = sprintf(
          "select id,tenantId,area,name,alias,keycode,keydata,color1,color2,color3,color4,fontSize,shortcut,orderNo,icon,enable,permission,createUser,createDate,modifyUser,modifyDate from pos_module where area = '%s' order by orderNo asc;", ["快捷"]);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      result = Module.toList(lists);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取POS功能模块发生异常:" + e.toString());
    }
    return result;
  }

  ///获取更多功能数据
  Future<List<Module>> getMoreModule() async {
    List<Module> result = new List<Module>();
    try {
      String sql = sprintf(
          "select id,tenantId,area,name,alias,keycode,keydata,color1,color2,color3,color4,fontSize,shortcut,orderNo,icon,enable,permission,createUser,createDate,modifyUser,modifyDate from pos_module where area = '%s' order by orderNo asc;", ["更多"]);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      result = Module.toList(lists);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取POS功能模块发生异常:" + e.toString());
    }
    return result;
  }

  ///获取商品分类列表
  Future<List<ProductCategory>> getCategoryList() async {
    List<ProductCategory> result = new List<ProductCategory>();
    try {
      String sql = sprintf(
          "select id,tenantId,parentId,name,code,path,categoryType,english,returnRate,description,orderNo,deleteFlag,products,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate from pos_product_category where deleteFlag = 0  and products > 0 order by orderNo asc;",
          []);

      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      result = ProductCategory.toList(lists);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取POS功能模块发生异常:" + e.toString());
    }
    return result;
  }

  ///获取选择品类对应的商品列表
  Future<List<ProductExt>> getProductList(String categoryPath) async {
    List<ProductExt> result = new List<ProductExt>();
    try {
      String sql = sprintf("""
        select p.`id`, p.`tenantId`, p.`categoryId`, p.`categoryPath`, p.`type`, p.`no`, p.`barCode`, p.`subNo`, p.`otherNo`, p.`name`, p.`english`, p.`rem`, p.`shortName`, p.`unitId`, p.`brandId`, p.`storageType`, p.`storageAddress`, sp.`supplierId`, sp.`managerType`, p.`purchaseControl`, p.`purchaserCycle`, p.`validDays`, p.`productArea`, p.`status`, p.`spNum`, sp.`stockFlag`, p.`quickInventoryFlag`,p.`posSellFlag`, p.`batchStockFlag`, p.`weightFlag`, p.`weightWay`, p.`steelyardCode`, p.`labelPrintFlag`, sp.`foreDiscount`, sp.`foreGift`, p.`promotionFlag`, sp.`branchPrice`, sp.`foreBargain`, p.`returnType`, p.`returnRate`, sp.`pointFlag`, p.`pointValue`, p.`introduction`, p.`purchaseTax`, p.`saleTax`, p.`lyRate`, p.`allCode`, p.`deleteFlag`, p.`allowEditSup`, p.`ext1`, p.`ext2`, p.`ext3`, p.`createUser`, p.`createDate`, p.`modifyUser`, p.`modifyDate`, ps.specification as specName, ps.id as specId,
        pc.name as categoryName, pc.code as categoryNo, pu.name as unitName, pb.name as brandName, sp.batchPrice, sp.batchPrice2, sp.batchPrice3, sp.batchPrice4, sp.batchPrice5, sp.batchPrice6, sp.batchPrice7, sp.batchPrice8, sp.minPrice, sp.otherPrice, sp.postPrice, sp.purPrice, sp.salePrice, sp.vipPrice, sp.vipPrice2, sp.vipPrice3, sp.vipPrice4, sp.vipPrice5, ps.isDefault, ps.purchaseSpec,
        su.name as supplierName, kp.chudaFlag, kp.chuda,kp.chupinFlag, kp.chupin, kp.labelFlag as chudaLabelFlag, kp.labelValue as chudaLabel
	      from pos_product p 
	      inner join pos_product_spec ps on p.id = ps.productId
	      inner join pos_store_product sp on ps.id = sp.specId
	      left join pos_product_unit pu on p.unitId = pu.id
	      left join pos_product_category pc on p.categoryId = pc.id
	      left join pos_product_brand pb on p.brandId = pb.id
	      left join pos_supplier su on sp.supplierId = su.id
	      left join pos_kit_plan_product kp on p.id = kp.productId
	      where sp.status in (1, 2) and ps.deleteFlag = 0 and p.posSellFlag = 1 and p.categoryPath like '%s%'
	      order by p.categoryId, p.barCode; 
        """, [categoryPath]);

      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      result = ProductExt.toList(lists);

      // if (productExtList != null) {
      //   //
      //
      //   for (var ex in productExtList) {
      //     String productId = ex.id;
      //     String specId = ex.specId;
      //     //多规格商品，进行规格合并
      //     if (ex.spNum > 0) {
      //       ProductExt masterProduct;
      //       List<ProductExt> moreSpecs = productExtList.where((x) => x.id == productId);
      //       if (moreSpecs != null && moreSpecs.length > 0) {
      //         //多规格合并
      //       } else {
      //         //
      //       }
      //     } else {
      //       //单规格商品，直接组装
      //       List<ProductSpec> newMoreSpecList = new List<ProductSpec>();
      //     }
      //   }
      // }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("获取POS功能模块发生异常:" + e.toString());
    }
    return result;
  }

  // ///获取选择品类对应的商品列表
  // Future<ProductExt> getProduct(String productId) async {
  //   ProductExt result;
  //   try {
  //     String sql = sprintf("""
  //       select p.`id`, p.`tenantId`, p.`categoryId`, p.`categoryPath`, p.`type`, p.`no`, p.`barCode`, p.`subNo`, p.`otherNo`, p.`name`, p.`english`, p.`rem`, p.`shortName`, p.`unitId`, p.`brandId`, p.`storageType`, p.`storageAddress`, sp.`supplierId`, sp.`managerType`, p.`purchaseControl`, p.`purchaserCycle`, p.`validDays`, p.`productArea`, p.`status`, p.`spNum`, sp.`stockFlag`, p.`quickInventoryFlag`,p.`posSellFlag`, p.`batchStockFlag`, p.`weightFlag`, p.`weightWay`, p.`steelyardCode`, p.`labelPrintFlag`, sp.`foreDiscount`, sp.`foreGift`, p.`promotionFlag`, sp.`branchPrice`, sp.`foreBargain`, p.`returnType`, p.`returnRate`, sp.`pointFlag`, p.`pointValue`, p.`introduction`, p.`purchaseTax`, p.`saleTax`, p.`lyRate`, p.`allCode`, p.`deleteFlag`, p.`allowEditSup`, p.`ext1`, p.`ext2`, p.`ext3`, p.`createUser`, p.`createDate`, p.`modifyUser`, p.`modifyDate`, ps.specification as specName, ps.id as specId,
  //       pc.name as categoryName, pc.code as categoryNo, pu.name as unitName, pb.name as brandName, sp.batchPrice, sp.batchPrice2, sp.batchPrice3, sp.batchPrice4, sp.batchPrice5, sp.batchPrice6, sp.batchPrice7, sp.batchPrice8, sp.minPrice, sp.otherPrice, sp.postPrice, sp.purPrice, sp.salePrice, sp.vipPrice, sp.vipPrice2, sp.vipPrice3, sp.vipPrice4, sp.vipPrice5, ps.isDefault, ps.purchaseSpec,
  //       su.name as supplierName, kp.chudaFlag, kp.chuda,kp.chupinFlag, kp.chupin, kp.labelFlag as chudaLabelFlag, kp.labelValue as chudaLabel
  //       from pos_product p
  //       inner join pos_product_spec ps on p.id = ps.productId
  //       inner join pos_store_product sp on ps.id = sp.specId
  //       left join pos_product_unit pu on p.unitId = pu.id
  //       left join pos_product_category pc on p.categoryId = pc.id
  //       left join pos_product_brand pb on p.brandId = pb.id
  //       left join pos_supplier su on sp.supplierId = su.id
  //       left join pos_kit_plan_product kp on p.id = kp.productId
  //       where sp.status in (1, 2) and ps.deleteFlag = 0 and p.posSellFlag = 1 and p.id = '%s'
  //       order by p.categoryId, p.barCode;
  //       """, [productId]);
  //
  //     var database = await SqlUtils.instance.open();
  //     var lists = await database.rawQuery(sql);
  //
  //     if (lists != null && lists.length > 0) {
  //       result = ProductExt.fromMap(lists[0]);
  //     }
  //   } catch (e, stack) {
  //     FlutterChain.printError(e, stack);
  //     FLogger.error("获取POS功能模块发生异常:" + e.toString());
  //   }
  //   return result;
  // }
}

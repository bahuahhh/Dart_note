import 'package:dart_extensions/dart_extensions.dart';
import 'package:estore_app/blocs/assistant_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_make_info.dart';
import 'package:estore_app/entity/pos_product_spec.dart';
import 'package:estore_app/enums/module_key_code.dart';
import 'package:estore_app/enums/order_item_join_type.dart';
import 'package:estore_app/enums/order_row_status.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/assistant_utils.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_table.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/product_ext.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:getwidget/components/button/gf_icon_button.dart';
import 'package:getwidget/shape/gf_icon_button_shape.dart';
import 'package:getwidget/size/gf_size.dart';

class AssistantDishPage extends StatefulWidget {
  final Map<String, List<String>> parameters;

  AssistantDishPage({this.parameters});

  @override
  _AssistantDishPageState createState() => _AssistantDishPageState();
}

class _AssistantDishPageState extends State<AssistantDishPage> with SingleTickerProviderStateMixin {
  //搜索框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //业务逻辑处理
  AssistantBloc _assistantBloc;

  ///是否多桌同时点单，默认都是单桌
  bool isMultiple = false;

  ///本次操作影响的桌台清单
  List<OrderTable> tables = <OrderTable>[];

  OrderTable selectedTable;

  @override
  void initState() {
    super.initState();

    _assistantBloc = BlocProvider.of<AssistantBloc>(context);
    assert(this._assistantBloc != null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {});
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    await initPlatformState();
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    String orderId = widget.parameters["orderId"].first;
    String tableId = widget.parameters["tableId"].first;
    String multipleTable = widget.parameters["multipleTable"].first;

    //multipleTable=0单桌点单，multipleTable=1多桌点单
    isMultiple = ("1" == multipleTable);

    var orderObjectResult = await AssistantUtils.instance.getOrderObject(orderId);
    if (orderObjectResult.item1) {
      var orderObject = orderObjectResult.item3;
      //当前选择的桌台
      selectedTable = orderObject.tables.lastWhere((x) => x.tableId == tableId);

      print("当前的桌台:${selectedTable.tableName}");

      if (isMultiple) {
        tables.addAll(orderObject.tables);
      } else {
        tables.add(orderObject.tables.lastWhere((x) => x.tableId == tableId));
      }

      print("受影响的桌台:${tables.length}");

      //加载
      _assistantBloc.add(LoadTableOrderObject(orderObject: orderObject));
    }
  }

  @override
  void dispose() {
    super.dispose();

    _focus.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        resizeToAvoidBottomPadding: false, //输入框抵住键盘
        backgroundColor: Constants.hexStringToColor("#656472"),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Constants.hexStringToColor("#4AB3FD"), Constants.hexStringToColor("#F7F7F7")],
              tileMode: TileMode.repeated,
            ),
          ),
          child: SafeArea(
            top: true,
            child: BlocListener<AssistantBloc, AssistantState>(
              cubit: this._assistantBloc,
              listener: (context, state) {},
              child: BlocBuilder<AssistantBloc, AssistantState>(
                  cubit: this._assistantBloc,
                  buildWhen: (previousState, currentState) {
                    return true;
                  },
                  builder: (context, state) {
                    return Stack(
                      fit: StackFit.passthrough,
                      children: [
                        Container(
                          padding: Constants.paddingAll(0),
                          decoration: BoxDecoration(
                            color: Constants.hexStringToColor("#656472"),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              this._buildHeader(state),
                              this._buildContent(state),
                              this._buildFooter(state),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: selectedTable != null,
                          child: Positioned.directional(
                            start: Constants.getAdapterWidth(45),
                            bottom: Constants.getAdapterHeight(75),
                            width: Constants.getAdapterWidth(80),
                            height: Constants.getAdapterHeight(30),
                            textDirection: TextDirection.ltr,
                            child: Container(
                              alignment: Alignment.center,
                              padding: Constants.paddingAll(0),
                              decoration: BoxDecoration(
                                color: Constants.hexStringToColor("#A52A2A"),
                                border: Border.all(color: Constants.hexStringToColor("#A52A2A"), width: 1),
                                borderRadius: BorderRadius.all(Radius.circular(2)),
                              ),
                              child: Text(
                                "共${selectedTable?.totalQuantity}件",
                                style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
            ),
          ),
        ),
      ),
    );
  }

  ///构建大类
  Widget _buildMainCategory(AssistantState state) {
    if (this.selectedTable == null || state.orderObject == null || state.orderObject.items == null) {
      FLogger.debug("构建桌台点单页面大类失败，原因:主单数据不存在");
      return Container();
    }

    var selectedItems = state.orderObject.items.where((x) => x.tableId == this.selectedTable.tableId).toList();
    var categoryPaths = _selectedCategoryPath(selectedItems);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state?.mainCategoryList?.length,
      itemBuilder: (context, index) {
        ///当前的分类对象
        var item = state.mainCategoryList[index];

        ///是否在品类上显示已经选购商品
        bool showCategoryFlag = state.mainCategoryList.count((x) => categoryPaths.length > 0 && categoryPaths.contains(item.id)) > 0;

        ///是否标注为选中状态
        var selected = (state.mainCategory != null && state.mainCategory.id == item.id);
        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: selected ? Border(bottom: BorderSide(width: 4, color: Color(0xff7A73C7))) : Border(bottom: BorderSide(width: 0, color: Colors.transparent)),
            ),
            child: InkWell(
              onTap: () {
                _assistantBloc.add(SelectMainCategory(categoryId: "${item.id}"));
              },
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    padding: Constants.paddingLTRB(6, 0, 6, 0),
                    child: Text(
                      "${item.name}",
                      textAlign: TextAlign.center,
                      style: TextStyles.getTextStyle(color: (selected ? Color(0xff7A73C7) : Constants.hexStringToColor("#333333")), fontSize: 28),
                    ),
                  ),
                  Visibility(
                    visible: showCategoryFlag,
                    child: Positioned.directional(
                      top: Constants.getAdapterHeight(-4),
                      end: Constants.getAdapterWidth(2),
                      width: Constants.getAdapterWidth(30),
                      height: Constants.getAdapterHeight(40),
                      textDirection: TextDirection.ltr,
                      child: Container(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          backgroundColor: Constants.hexStringToColor("#FF3600"),
                          radius: Constants.getAdapterWidth(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ///构建小类
  Widget _buildSubCategory(AssistantState state) {
    if (this.selectedTable == null || state.orderObject == null || state.orderObject.items == null) {
      FLogger.debug("构建桌台点单页面小类失败，原因:主单数据不存在");
      return Container();
    }

    var selectedItems = state.orderObject.items.where((x) => x.tableId == this.selectedTable.tableId).toList();
    var categoryPaths = _selectedCategoryPath(selectedItems);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state?.subCategoryList?.length,
      itemBuilder: (context, index) {
        //小类对象
        var item = state.subCategoryList[index];
        //是否在品类上显示已经选购商品
        bool showCategoryFlag = state.subCategoryList.count((x) => categoryPaths.length > 0 && categoryPaths.contains(item.id)) > 0;

        ///是否标注为选中状态
        var selected = (state.subCategory != null && state.subCategory.id == item.id);
        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: selected ? Border(bottom: BorderSide(width: 4, color: Color(0xff7A73C7))) : Border(bottom: BorderSide(width: 0, color: Colors.transparent)),
            ),
            child: InkWell(
              onTap: () {
                ///切换商品
                _assistantBloc.add(SelectSubCategory(categoryId: "${item.id}"));
              },
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    padding: Constants.paddingLTRB(6, 0, 6, 0),
                    child: Text("${item.name}", textAlign: TextAlign.center, style: TextStyles.getTextStyle(color: (selected ? Color(0xff7A73C7) : Color(0xff333333)), fontSize: 28)),
                  ),
                  Visibility(
                    visible: showCategoryFlag,
                    child: Positioned.directional(
                      top: Constants.getAdapterHeight(-4),
                      end: Constants.getAdapterWidth(2),
                      width: Constants.getAdapterWidth(30),
                      height: Constants.getAdapterHeight(40),
                      textDirection: TextDirection.ltr,
                      child: Container(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          backgroundColor: Constants.hexStringToColor("#FF3600"),
                          radius: Constants.getAdapterWidth(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ///已选择单品对应的分类全路径
  List<String> _selectedCategoryPath(List<OrderItem> items) {
    var categoryPaths = <String>[];
    if (items != null) {
      items.forEach((x) {
        categoryPaths.addAll(x.productExt.categoryPath.split(","));
      });
      //去重处理
      categoryPaths = categoryPaths.distinctBy((x) => x);
    }
    return categoryPaths;
  }

  ///构建商品区
  Widget _buildProduct(AssistantState state) {
    if (selectedTable == null || state.orderObject == null || state.orderObject.items == null) {
      return Container();
    }
    var selectedItems = state.orderObject.items.where((x) => x.tableId == selectedTable.tableId).toList();
    return GridView.builder(
      padding: Constants.paddingAll(0),
      itemCount: state?.productList?.length,
      itemBuilder: (BuildContext context, int index) {
        //当前商品数据
        var product = state.productList[index];
        //是否新品
        bool showNew = false;
        //是否在商品上显示购买数量
        bool showProductCount = selectedItems.any((x) => x.productId == product.id);
        //单品放入购物车的数量
        int productCount = selectedItems.where((x) => x.productId == product.id).length;

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#E6E6EB"),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              border: Border.all(width: 0, color: Constants.hexStringToColor("#9898A1")),
            ),
            child: InkWell(
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              onTap: () async {
                await this.touchProduct(state.orderObject, product, orderTable: selectedTable);
              },
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Container(
                    padding: Constants.paddingAll(0),
                    child: Row(
                      children: <Widget>[
                        Space(
                          width: Constants.getAdapterWidth(3),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LoadImage(
                            "${product.storageAddress}",
                            holderImg: "home/product_noimg",
                            width: Constants.getAdapterWidth(120),
                            height: Constants.getAdapterHeight(120),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: Constants.paddingLTRB(10, 3, 3, 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "${product.name}",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 28),
                                ),
                                Space(
                                  height: Constants.getAdapterHeight(3),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      "¥${product.salePrice}",
                                      style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#7A73C7"), fontSize: 28),
                                    ),
                                    Space(width: Constants.getAdapterWidth(9)),
                                    product.plusPrice != null ? LoadAssetImage("home/member_plus") : Container(),
                                    Space(width: Constants.getAdapterWidth(6)),
                                    Text(
                                      "${product.plusPrice != null ? product.plusPrice : ''}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#795E50"), fontSize: 28),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: showNew,
                    child: Positioned.directional(
                      start: Constants.getAdapterWidth(3),
                      top: Constants.getAdapterHeight(-4),
                      width: Constants.getAdapterWidth(30),
                      height: Constants.getAdapterHeight(40),
                      textDirection: TextDirection.ltr,
                      child: Container(
                        alignment: Alignment.topCenter,
                        padding: Constants.paddingLTRB(0, 3, 0, 0),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: ImageUtils.getAssetImage("home/home_discount"),
                          ),
                        ),
                        child: Text(
                          "新",
                          style: TextStyles.getTextStyle(color: Colors.white, fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: showProductCount,
                    child: Positioned.directional(
                      top: Constants.getAdapterHeight(-4),
                      end: Constants.getAdapterWidth(2),
                      width: Constants.getAdapterWidth(30),
                      height: Constants.getAdapterHeight(40),
                      textDirection: TextDirection.ltr,
                      child: Container(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          backgroundColor: Constants.hexStringToColor("#FF3600"),
                          radius: Constants.getAdapterWidth(15),
                          child: Text("$productCount", style: TextStyles.getTextStyle(fontSize: 18, color: Constants.hexStringToColor("#FFFFFF"))),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Constants.getAdapterWidth(10),
        crossAxisSpacing: Constants.getAdapterHeight(10),
        childAspectRatio: 2.75,
      ),
    );
  }

  //点击商品
  Future<void> touchProduct(OrderObject orderObject, ProductExt product, {OrderTable orderTable, OrderItemJoinType joinType = OrderItemJoinType.Touch}) async {
    //如果订单已完成状态，自动新增订单
    if (orderObject.orderStatus == OrderStatus.Completed) {
      ToastUtils.show("订单已经完成，本次操作无效!");
      return;
    }
    //需要复制一个新对象，避免数据污染
    var newProduct = ProductExt.clone(product);
    await addRowWithQuantity(orderObject, newProduct, 0, joinType, orderTable: orderTable);
  }

  //开始点单操作
  Future<void> addRowWithQuantity(OrderObject orderObject, ProductExt newProduct, double quantity, OrderItemJoinType joinType, {OrderTable orderTable, double labelAmount = 0}) async {
    this.addRowByWeight(newProduct, quantity, joinType, orderTable: orderTable, labelAmount: labelAmount);
  }

  ///兼容称重模式
  Future<void> addRowByWeight(ProductExt product, double quantity, OrderItemJoinType joinType, {OrderTable orderTable, double labelAmount = 0}) async {
    //
    double weightOrQuantity = quantity;
    if (product.weightFlag == 1 && weightOrQuantity == 0) {
      //计重商品
      if (product.weightWay == 1) {
        ToastUtils.show("计重商品暂不支持");
      } else {
        //计数商品
        ToastUtils.show("计数商品暂不支持");
      }
    } else {
      //非承重商品（含扫条码秤条码商品）,数量为 1
      this.addRow4Spec(product, 1, joinType, orderTable: orderTable, weightContinue: false, labelAmount: labelAmount);
    }
  }

  //处理多规格商品
  Future<void> addRow4Spec(ProductExt product, double quantity, OrderItemJoinType joinType, {OrderTable orderTable, bool weightContinue = false, double labelAmount = 0}) async {
    //获取商品的做法清单
    List<MakeInfo> makeList = await OrderUtils.instance.getProductMakeList(product.id);
    List<ProductSpec> specList = product.specList;

    FLogger.debug("商品的做法数量:${makeList.length},规格数量:${product.spNum}");
    //多规格弹框
    if (product.spNum > 1) {
      //多规格选择
      // showProductSpecAndMake(context, product, specList, makeList, this._tableCashierBloc);
    } else {
      //售价为零
      if (product.salePrice <= 0) {
        FLogger.info("售价为零,暂不支持");
        //showInputPrice(context, product, this._cashierBloc);
      } else {
        this._assistantBloc.add(TouchProduct(
              product,
              orderTable: orderTable,
              quantity: quantity,
              joinType: joinType,
              labelAmount: labelAmount,
              weightContinue: weightContinue,
              callback: () {/**设计上保留，暂时没有用*/},
            ));
      }
    }
  }

  ///构建内容区域
  Widget _buildContent(AssistantState state) {
    return Expanded(
      child: Container(
        padding: Constants.paddingAll(5),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: Constants.getAdapterHeight(90),
              padding: Constants.paddingSymmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#E6E6EB"),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: _buildMainCategory(state),
            ),
            Container(
              width: double.infinity,
              height: Constants.getAdapterHeight(90),
              padding: Constants.paddingSymmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#E6E6EB"),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: _buildSubCategory(state),
            ),
            Space(
              height: Constants.getAdapterHeight(10),
            ),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: Constants.paddingAll(0),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    this._buildProduct(state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AssistantState state) {
    return Container(
      padding: Constants.paddingAll(0),
      height: Constants.getAdapterHeight(100.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(bottom: BorderSide(color: Constants.hexStringToColor("#F2F2F2"), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              NavigatorUtils.instance.goBackWithParams(context, "返回");

              // //查找当前订单中是否新增单品
              // var newItems = state.orderObject.items.where((x) => x.orderRowStatus == OrderRowStatus.New).toList();
              // //有新增单品,进行保存动作
              // if (newItems.length > 0) {
              //   //提交下单数据
              //   var tryOrderResult = await TableUtils.instance.tryOrder(state.orderObject, this.tables, goBack: true);
              //   if (tryOrderResult.item1) {
              //     //返回桌台界面
              //     NavigatorUtils.instance.goBackWithParams(context, "返回");
              //   } else {
              //     DialogUtils.notify(context, "错误提示", "保存点单数据失败,本次点单无效", () {});
              //   }
              // } else {
              //   //返回桌台界面
              //   NavigatorUtils.instance.goBackWithParams(context, "返回");
              // }
            },
            child: Container(
              width: Constants.getAdapterWidth(90),
              height: double.infinity,
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios,
                size: Constants.getAdapterWidth(48),
                color: Constants.hexStringToColor("#2B2B2B"),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: Constants.getAdapterWidth(500),
              height: Constants.getAdapterHeight(100),
              padding: Constants.paddingLTRB(0, 10, 16, 10),
              child: Container(
                padding: Constants.paddingOnly(left: 12, right: 12),
                decoration: BoxDecoration(
                  color: Constants.hexStringToColor("#FFFFFF"),
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  border: Border.all(width: 1, color: Constants.hexStringToColor("#D0D0D0")),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildSearchBox(state),
                    ),
                    // InkWell(
                    //   onTap: () async {
                    //     var scanResult = await BarcodeScanner.scan(options: scanOptions);
                    //   },
                    //   child: LoadAssetImage(
                    //     "home/home_scan",
                    //     height: Constants.getAdapterHeight(64),
                    //     width: Constants.getAdapterWidth(64),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///构建商品搜索框
  Widget _buildSearchBox(AssistantState state) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(96),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: false,
        focusNode: this._focus,
        controller: this._controller,
        style: TextStyles.getTextStyle(fontSize: 32),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "扫描或者输入搜索",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),

        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(24) //限制长度
        ],
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: false, //长按复制 剪切
        autocorrect: false,
      ),
    );
  }

  ///构建结算区
  Widget _buildFooter(AssistantState state) {
    if (selectedTable == null || state.orderObject == null || state.orderObject.items == null) {
      return Container();
    }
    var selectedItems = state.orderObject.items.where((x) => x.tableId == selectedTable.tableId).toList();

    return Container(
      height: Constants.getAdapterHeight(100.0),
      padding: Constants.paddingLTRB(10, 5, 0, 5),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#F7F7F7"),
        border: new Border.all(width: 1, color: Constants.hexStringToColor("#D2D2D2")),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Ink(
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#7A73C7"),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              border: Border.all(width: 0.0, style: BorderStyle.none),
            ),
            child: InkWell(
              onTap: () {
                //查找当前订单中是否新增单品
                var newItems = selectedItems.where((x) => x.orderRowStatus == OrderRowStatus.New).toList();

                NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_ASSISTANT_CART_PAGE}?orderId=${selectedTable.orderId}&&multipleTable=${this.tables.length > 1 ? 1 : 0}&&tableId=${selectedTable.tableId}", (val) {
                  this._assistantBloc.add(RefreshTable());
                });
              },
              child: Container(
                width: Constants.getAdapterWidth(100),
                height: Constants.getAdapterHeight(100),
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: Constants.paddingAll(0),
                  child: GFIconButton(
                    color: Constants.hexStringToColor("#EEC900"),
                    shape: GFIconButtonShape.circle,
                    borderSide: BorderSide(style: BorderStyle.none),
                    size: GFSize.LARGE,
                    iconSize: Constants.getAdapterWidth(48),
                    icon: Icon(
                      Icons.shopping_cart_sharp,
                      color: Constants.hexStringToColor("#FFFFFF"),
                      size: Constants.getAdapterWidth(64),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Space(width: Constants.getAdapterWidth(20)),
          Expanded(
            child: Container(
              padding: Constants.paddingAll(0),
              width: Constants.getAdapterWidth(170),
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(text: "¥", style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold), children: <TextSpan>[
                  TextSpan(text: "${selectedTable.receivableAmount}", style: TextStyles.getTextStyle(fontSize: 38, color: Constants.hexStringToColor("#7A73C7"), fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
          Space(width: Constants.getAdapterWidth(10)),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#7A73C7"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: InkWell(
                onTap: () async {
                  ///下单
                  bool isGo = true;
                  if (isGo && state.orderObject.orderStatus == OrderStatus.Completed || state.orderObject.orderStatus == OrderStatus.ChargeBack) {
                    isGo = false;
                    ToastUtils.show("订单已经完成");
                  }

                  if (isGo && state.orderObject.items.length == 0) {
                    isGo = false;
                    ToastUtils.show("请选择商品");
                  }

                  //查找当前订单中是否新增单品
                  var newItems = state.orderObject.items.where((x) => x.orderRowStatus == OrderRowStatus.New || x.orderRowStatus == OrderRowStatus.Save).toList();
                  //1、没有新增单品
                  if (isGo && newItems.length == 0) {
                    isGo = false;
                    ToastUtils.show("商品已全部下单");
                  }

                  if (isGo) {
                    var permissionAction = (args) async {
                      //提交下单数据
                      var tryOrderResult = await AssistantUtils.instance.tryOrder(newItems);
                      if (tryOrderResult.item1) {
                        //下单成功后更新订单信息
                        var orderObjectResult = await AssistantUtils.instance.getOrderObject(state.orderObject.id);
                        if (orderObjectResult.item1) {
                          var orderObject = orderObjectResult.item3;
                          //加载
                          _assistantBloc.add(LoadTableOrderObject(orderObject: orderObject));
                        }

                        //返回桌台界面
                        NavigatorUtils.instance.goBackWithParams(context, "返回");
                      } else {
                        DialogUtils.notify(context, "错误提示", "${tryOrderResult.item2}", () {});
                      }
                    };
                    AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_706, ModuleKeyCode.$_706.permissionCode, state.orderObject, permissionAction);
                  }
                },
                child: Container(
                  width: Constants.getAdapterWidth(150),
                  child: Center(
                    child: Text("下单", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          ),
          Space(width: Constants.getAdapterWidth(5)),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#7A73C7"),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: InkWell(
                onTap: () async {
                  ///结算
                  if (state.orderObject.orderStatus == OrderStatus.Completed || state.orderObject.orderStatus == OrderStatus.ChargeBack) {
                    ToastUtils.show("订单已经完成");
                    return;
                  }

                  //查找当前订单中是否新增单品
                  var newItems = state.orderObject.items.where((x) => x.orderRowStatus == OrderRowStatus.New || x.orderRowStatus == OrderRowStatus.Save).toList();
                  //没有新增的单品,直接去结账界面
                  if (newItems.length == 0) {
                    NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_ASSISTANT_PAY_PAGE}?orderId=${state.orderObject.id}", (val) {
                      NavigatorUtils.instance.goBackWithParams(context, "交易成功");
                    });
                  } else {
                    var permissionAction = (args) async {
                      DialogUtils.confirm(context, "操作提醒", "\n有未下单的商品,是否下单并结账?\n", () async {
                        //提交下单数据
                        var tryOrderResult = await AssistantUtils.instance.tryOrder(newItems);
                        if (tryOrderResult.item1) {
                          NavigatorUtils.instance.pushResult(context, "${RouterManager.TABLE_ASSISTANT_PAY_PAGE}?orderId=${state.orderObject.id}", (val) {
                            NavigatorUtils.instance.goBackWithParams(context, "交易成功");
                          });
                        } else {
                          DialogUtils.notify(context, "错误提示", "${tryOrderResult.item2}", () {});
                        }
                      }, () {
                        FLogger.warn("用户放弃下单并结账操作");
                      }, width: 550);
                    };
                    AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_706, ModuleKeyCode.$_706.permissionCode, state.orderObject, permissionAction);
                  }
                },
                child: Container(
                  width: Constants.getAdapterWidth(160),
                  child: Center(
                    child: Text("去结算", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

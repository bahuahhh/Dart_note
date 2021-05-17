import 'package:barcode_scan/gen/protos/protos.pbenum.dart';
import 'package:barcode_scan/platform_wrapper.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:dart_extensions/dart_extensions.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/enums/module_key_code.dart';
import 'package:estore_app/enums/order_item_join_type.dart';
import 'package:estore_app/enums/order_status_type.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/product_ext.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/common_widget.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class CashierPage extends StatefulWidget {
  final Map<String, List<String>> parameters;

  CashierPage({this.parameters});

  @override
  _CashierPageState createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> with SingleTickerProviderStateMixin {
  //搜索框
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //业务逻辑处理
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);
    //加载
    _cashierBloc.add(Load());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("接收到参数:${widget.parameters}");
    });
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    //fullScreenSetting();

    return KeyboardDismissOnTap(
      child: Scaffold(
        resizeToAvoidBottomPadding: false, //输入框抵住键盘
        backgroundColor: Constants.hexStringToColor("#656472"),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter, // 10% of the width, so there are ten blinds.
              colors: [Constants.hexStringToColor("#4AB3FD"), Constants.hexStringToColor("#F7F7F7")], // whitish to gray
              tileMode: TileMode.repeated, // repeats the gradient over the canvas
            ),
          ),
          child: SafeArea(
            top: true,
            child: BlocListener<CashierBloc, CashierState>(
              cubit: this._cashierBloc,
              listener: (context, state) {},
              child: BlocBuilder<CashierBloc, CashierState>(
                cubit: this._cashierBloc,
                buildWhen: (previousState, currentState) {
                  return true;
                },
                builder: (context, state) {
                  return Container(
                    padding: Constants.paddingAll(0),
                    decoration: BoxDecoration(
                      color: Constants.hexStringToColor("#656472"),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        this._buildHeader(state),
                        Expanded(
                          child: Container(
                            padding: Constants.paddingAll(5),
                            child: SizedBox(
                              width: double.infinity,
                              height: Constants.getAdapterHeight(200),
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
                          ),
                        ),
                        // Visibility(
                        //   visible: state.orderObject.member != null,
                        //   child: Column(
                        //     children: [
                        //       Space(
                        //         height: Constants.getAdapterHeight(5),
                        //       ),
                        //       Container(
                        //         height: Constants.getAdapterHeight(100),
                        //         color: Colors.cyan,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        _buildSettlement(state),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  //已选择单品对应的分类全路径
  List<String> _selectedCategoryPath(CashierState cashierState) {
    var categoryPaths = <String>[];
    cashierState.orderObject.items.forEach((x) {
      categoryPaths.addAll(x.productExt.categoryPath.split(","));
    });
    //去重处理
    categoryPaths = categoryPaths.distinctBy((x) => x);

    return categoryPaths;
  }

  Widget _buildHeader(CashierState cashierState) {
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
            onTap: () => NavigatorUtils.instance.goBack(context),
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
                      child: RawKeyboardListener(
                        focusNode: this._focus,
                        child: _buildSearchBox(cashierState),
                        onKey: (RawKeyEvent event) {
                          if (event is RawKeyDownEvent && event.data is RawKeyEventDataAndroid) {
                            RawKeyDownEvent rawKeyDownEvent = event;
                            RawKeyEventDataAndroid rawKeyEventDataAndroid = rawKeyDownEvent.data;
                            switch (rawKeyEventDataAndroid.keyCode) {
                              case 66: //KEY_ENTER
                                final inputValue = _controller.text;
                                if (StringUtils.isEmpty(inputValue)) {
                                  ToastUtils.show("请重新扫描...");
                                } else {
                                  String code = inputValue;
                                  //this._onScanCode(code);
                                }
                                _controller.clear();
                                break;
                              default:
                                _controller.text += rawKeyEventDataAndroid.keyLabel.toString();
                                break;
                            }
                          }
                        },
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        var scanResult = await BarcodeScanner.scan(options: scanOptions);
                        if (scanResult.type == ResultType.Barcode) {
                          //扫码成功
                          var format = scanResult.format;
                          var scanCode = scanResult.rawContent;
                          FLogger.info("快速收银识别到${format.name}码,内容:$scanCode");

                          _controller.value = _controller.value.copyWith(
                            text: scanCode,
                            selection: TextSelection(baseOffset: 0, extentOffset: scanCode.length),
                            composing: TextRange.empty,
                          );
                          FocusScope.of(context).requestFocus(_focus);

                          var productList = await OrderUtils.instance.getProductExtList();

                          var selectProductList = productList.where((x) => x.subNo.contains(scanCode) || x.allCode.contains(scanCode) || x.rem.contains(scanCode.toUpperCase())).toList();
                          if (selectProductList != null && selectProductList.length > 0) {
                            //检索到多个商品
                            if (selectProductList.length > 1) {
                            } else {
                              await this.touchProduct(cashierState.orderObject, selectProductList[0], OrderItemJoinType.ScanBarCode);
                            }
                          } else {
                            ToastUtils.show("商品[$scanCode]不存在");
                          }
                        } else if (scanResult.type == ResultType.Cancelled) {
                          FLogger.warn("收银员放弃扫码");
                        } else {
                          FLogger.warn("无法识别的条码,收银员扫码发生未知错误<${scanResult.formatNote}>");
                          ToastUtils.show("无法识别的条码");
                        }
                      },
                      child: LoadAssetImage(
                        "home/home_scan",
                        height: Constants.getAdapterHeight(64),
                        width: Constants.getAdapterWidth(64),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          //
          InkWell(
            onTap: () async {
              //会员认证
              var orderObject = cashierState.orderObject;
              if (orderObject != null && orderObject.orderStatus != OrderStatus.Completed && orderObject.orderStatus != OrderStatus.ChargeBack && orderObject.member != null) {
                //如果会员存在，显示会员详细信息
                showVipInfo(this.context, orderObject, this._cashierBloc);
              } else {
                var permissionAction = (args) {
                  loadVip(this.context, orderObject, this._cashierBloc);
                };
                AuthzUtils.instance.checkAuthz(this.context, ModuleKeyCode.$_115, "10009", orderObject, permissionAction);
              }
            },
            child: SizedBox(
              width: Constants.getAdapterWidth(100),
              height: double.infinity,
              child: Icon(
                CommunityMaterialIcons.card_account_details_star_outline,
                size: Constants.getAdapterWidth(64),
                color: Constants.hexStringToColor("#7A73C7"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///构建商品搜索框
  Widget _buildSearchBox(CashierState state) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(96),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: false,
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
  Widget _buildSettlement(CashierState state) {
    return Container(
      height: Constants.getAdapterHeight(120.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#F7F7F7"),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#F7F7F7")),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              ///结算
              bool isGo = true;
              if (state.orderObject == null || state.orderObject.itemCount == 0) {
                isGo = false;
                ToastUtils.show("请先点单");
              }

              if (isGo) {
                //购物车清单
                NavigatorUtils.instance.push(context, RouterManager.CART_PAGE);
              }
            },
            child: Stack(
              fit: StackFit.passthrough,
              children: <Widget>[
                Container(
                  width: Constants.getAdapterWidth(120),
                  height: double.infinity,
                  color: Constants.hexStringToColor("#F7F7F7"),
                  child: Icon(
                    Icons.shopping_cart_sharp,
                    size: Constants.getAdapterWidth(84),
                    color: Constants.hexStringToColor("#333333"),
                  ),
                ),
                Visibility(
                  visible: state.orderObject.itemCount > 0,
                  child: Positioned.directional(
                    top: Constants.getAdapterHeight(-4),
                    end: Constants.getAdapterWidth(2),
                    width: Constants.getAdapterWidth(20),
                    height: Constants.getAdapterHeight(40),
                    textDirection: TextDirection.ltr,
                    child: CircleAvatar(
                      backgroundColor: Constants.hexStringToColor("#FF3600"),
                      radius: Constants.getAdapterWidth(6),
                      //child: Text("${state.orderObject.itemCount}", style: TextStyles.getTextStyle(fontSize: 18, color: Constants.hexStringToColor("#FFFFFF"))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: Constants.paddingLTRB(25, 0, 0, 0),
              child: Text("共${state.orderObject.totalQuantity.toInt()}件", style: TextStyles.getTextStyle(color: Color(0xff333333), fontSize: 36, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: Constants.paddingLTRB(0, 0, 20, 0),
                child: Text("¥${state.orderObject.receivableAmount}", style: TextStyles.getTextStyle(color: Color(0xff7A73C7), fontSize: 36, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Constants.hexStringToColor("#7A73C7"),
                borderRadius: BorderRadius.horizontal(left: Radius.circular(0.0), right: Radius.circular(0.0)),
                border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
              ),
              child: InkWell(
                onTap: () async {
                  ///结算
                  bool isGo = true;
                  if (state.orderObject == null || state.orderObject.itemCount == 0) {
                    isGo = false;
                    ToastUtils.show("请先点单");
                  }

                  if (state.orderObject.orderStatus == OrderStatus.Completed) {
                    isGo = false;
                    ToastUtils.show("订单已经结账");
                  }

                  FLogger.info(state.orderObject.toString());

                  if (isGo) {
                    //结算
                    NavigatorUtils.instance.push(context, RouterManager.PAY_PAGE);
                  }
                },
                child: Container(
                  width: Constants.getAdapterWidth(180),
                  child: Center(
                    child: Text("去结算", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 36)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  ///构建商品区
  Widget _buildProduct(CashierState state) {
    return GridView.builder(
      padding: Constants.paddingAll(0),
      itemCount: state?.productList?.length,
      itemBuilder: (BuildContext context, int index) {
        var item = state.productList[index];

        //是否新品
        bool showNew = false;
        //是否在商品上显示购买数量
        bool showProductCount = state.orderObject.items.any((x) => x.productId == item.id);
        //单品放入购物车的数量
        int productCount = state.orderObject.items.where((x) => x.productId == item.id).length;

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
                await this.touchProduct(state.orderObject, item, OrderItemJoinType.Touch);
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
                            "${item.storageAddress}",
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
                                  "${item.name}",
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
                                      "¥${item.salePrice}",
                                      style: TextStyles.getTextStyle(color: Color(0xFF7A73C7), fontSize: 28),
                                    ),
                                    Space(width: Constants.getAdapterWidth(9)),
                                    item.plusPrice != null ? LoadAssetImage("home/member_plus") : Container(),
                                    Space(width: Constants.getAdapterWidth(6)),
                                    Text(
                                      "${item.plusPrice != null ? item.plusPrice : ''}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: TextStyles.getTextStyle(color: Color(0xFF795E50), fontSize: 28),
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

  ///构建大类
  Widget _buildMainCategory(CashierState state) {
    var categoryPaths = _selectedCategoryPath(state);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state?.mainCategoryList?.length,
      itemBuilder: (context, index) {
        ///当前的分类对象
        var item = state.mainCategoryList[index];

        //是否在品类上显示已经选购商品
        bool showCategoryFlag = state.mainCategoryList.count((x) => categoryPaths.contains(item.id)) > 0;

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
                _cashierBloc.add(SelectMainCategory(categoryId: "${item.id}"));
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

  //点击商品
  Future<void> touchProduct(OrderObject orderObject, ProductExt product, OrderItemJoinType joinType) async {
    //需要复制一个新对象，避免数据污染
    var newProduct = ProductExt.clone(product);
    await addRowWithQuantity(orderObject, newProduct, 0, joinType);
  }

  //开始点单操作
  Future<void> addRowWithQuantity(OrderObject orderObject, ProductExt newProduct, double quantity, OrderItemJoinType joinType, {double labelAmount = 0}) async {
    //如果订单已完成状态，自动新增订单
    if (orderObject.orderStatus == OrderStatus.Completed) {
      this._cashierBloc.add(NewOrderObject());
    }

    FLogger.info("选择商品<${newProduct.name},${newProduct.salePrice}>");

    this.addGridRowGetWeight(newProduct, quantity, joinType, labelAmount: labelAmount);

    // //售价为零
    // if (newProduct.salePrice <= 0) {
    //   showInputPrice(context, newProduct, this._cashierBloc);
    // } else {
    //
    //
    //   //加入购物车
    //   this._cashierBloc.add(TouchProduct(newProduct, callback: () {/**设计上保留，暂时没有用*/}));
    // }
  }

  void addGridRowGetWeight(ProductExt product, double quantity, OrderItemJoinType joinType, {double labelAmount = 0}) {
    double weightOrQuantity = quantity;
    //称重商品，且重量为零，需要取重
    if (product.weightFlag == 1 && weightOrQuantity == 0) {
      //计重商品
      if (product.weightWay == 1) {
        FLogger.info("计重商品暂不支持");

        ToastUtils.show("计重商品暂不支持");
      } else {
        //计数商品
        FLogger.info("计数商品暂不支持");

        ToastUtils.show("计数商品暂不支持");

        //this.addGridRow4Spec(product, weightOrQuantity, joinType);
      }
    } else {
      //非承重商品（含扫条码秤条码商品）,数量为 1
      this.addGridRow4Spec(product, 1, joinType, weightContinue: false, labelAmount: labelAmount);
    }
  }

  //处理多规格商品
  void addGridRow4Spec(ProductExt product, double quantity, OrderItemJoinType joinType, {bool weightContinue = false, double labelAmount = 0}) {
    print("###############>>>>${product.specList}");
    //多规格弹框
    if (product.spNum > 1) {
      //多规格选择
      showSelectProductSpec(context, product, this._cashierBloc);
    } else {
      //售价为零
      if (product.salePrice <= 0) {
        showInputPrice(context, product, this._cashierBloc);
      } else {
        this._cashierBloc.add(TouchProduct(
              product,
              quantity: quantity,
              joinType: joinType,
              labelAmount: labelAmount,
              weightContinue: weightContinue,
              callback: () {/**设计上保留，暂时没有用*/},
            ));
      }
    }
  }

  // void addGridRow4ZeroPrice(ProductExt product, double quantity, OrderItemJoinType joinType, {bool weightContinue = false, double labelAmount = 0}) {
  //   //售价为零
  //   if (product.salePrice <= 0) {
  //     showInputPrice(context, product, this._cashierBloc);
  //   } else {
  //     this._cashierBloc.add(TouchProduct(
  //       product,
  //       quantity: quantity,
  //       joinType: joinType,
  //       labelAmount: labelAmount,
  //       weightContinue: weightContinue,
  //       callback: () {/**设计上保留，暂时没有用*/},
  //     ));
  //   }
  // }

  ///构建小类
  Widget _buildSubCategory(CashierState state) {
    var categoryPaths = _selectedCategoryPath(state);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemExtent: Constants.getAdapterWidth(140),
      itemCount: state?.subCategoryList?.length,
      itemBuilder: (context, index) {
        var item = state.subCategoryList[index];

        //是否在品类上显示已经选购商品
        bool showCategoryFlag = state.subCategoryList.count((x) => categoryPaths.contains(item.id)) > 0;

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
                _cashierBloc.add(SelectSubCategory(categoryId: "${item.id}"));
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
}

import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_make_info.dart';
import 'package:estore_app/entity/pos_product_spec.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/order/order_item_make.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/order/product_ext.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/line_separator.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:estore_app/widgets/spinner_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectSpecPage extends StatefulWidget {
  final ProductExt product;
  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  SelectSpecPage(this.product, {this.onAccept, this.onClose});

  @override
  _SelectSpecPageState createState() => _SelectSpecPageState();
}

class _SelectSpecPageState extends State<SelectSpecPage> with SingleTickerProviderStateMixin {
  //业务逻辑处理
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);

    //加载折扣原因
    _cashierBloc.add(SelectProductSpec(specList: widget.product.specList));

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashierBloc, CashierState>(
      cubit: this._cashierBloc,
      buildWhen: (previousState, currentState) {
        return true;
      },
      builder: (context, cashierState) {
        return Material(
          child: Container(
            padding: Constants.paddingAll(0),
            child: Column(
              children: <Widget>[
                ///顶部标题
                _buildHeader(),

                ///中部操作区
                _buildContent(cashierState),

                ///底部操作按钮
                _buildFooter(cashierState),
              ],
            ),
          ),
        );
      },
    );
  }

  ///构建内容区域
  Widget _buildContent(CashierState cashierState) {
    return Container(
      padding: Constants.paddingAll(20),
      height: Constants.getAdapterHeight(810),
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: Constants.getAdapterHeight(100),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: Constants.paddingAll(0),
              itemCount: cashierState?.specList?.length,
              separatorBuilder: (BuildContext context, int index) {
                return Space(width: Constants.getAdapterWidth(10));
              },
              physics: AlwaysScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                var item = cashierState.specList[index];
                var selected = (item.id == cashierState.specSelected.id);

                return _buildProductSpec(cashierState, item, selected);
              },
            ),
          ),
          Space(height: Constants.getAdapterHeight(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: Constants.getAdapterHeight(40),
                  alignment: Alignment.centerLeft,
                  child: Text("可选做法", style: TextStyles.getTextStyle(fontSize: 28)),
                ),
                Space(height: Constants.getAdapterHeight(15)),
                Expanded(
                  child: GridView.builder(
                    itemCount: cashierState.makeList.length,
                    shrinkWrap: true,
                    physics: AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: Constants.getAdapterWidth(10),
                      crossAxisSpacing: Constants.getAdapterHeight(10),
                      childAspectRatio: Constants.getAdapterWidth(650) / Constants.getAdapterHeight(340),
                    ),
                    itemBuilder: (context, index) {
                      var item = cashierState.makeList[index];
                      var selected = cashierState.makeSelected.any((x) => x.makeId == item.id);

                      return _buildProductMake(cashierState, item, selected);
                    },
                  ),
                ),
              ],
            ),
          ),
          Space(height: Constants.getAdapterHeight(15)),
          this._calculateAmount(cashierState),
        ],
      ),
    );
  }

  Widget _calculateAmount(CashierState cashierState) {
    var salePrice = cashierState.specSelected != null ? cashierState.specSelected.salePrice : 0;
    var amount = cashierState.inputQuantity * salePrice;
    //做法金额
    var flavorAmount = cashierState.makeSelected.map((e) => e.amount).fold(0, (prev, amount) => prev + amount);
    var totalAmount = amount + flavorAmount;

    return Container(
      height: Constants.getAdapterHeight(145),
      padding: Constants.paddingLTRB(15, 15, 0, 10),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#F7F7F7"),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#D2D2D2")),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildOrderItemRow(cashierState),
            ),
          ),
          Container(
            padding: Constants.paddingAll(0),
            width: Constants.getAdapterWidth(120),
            alignment: Alignment.center,
            child: Text("¥$totalAmount", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#7A73C7"), fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: Constants.paddingAll(0),
            width: Constants.getAdapterWidth(180),
            alignment: Alignment.center,
            child: SpinnerInput(
              spinnerValue: cashierState.inputQuantity,
              minValue: 1,
              maxValue: 999,
              disabledLongPress: false,
              middleNumberWidth: Constants.getAdapterWidth(64),
              middleNumberStyle: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#444444")),
              middleNumberBackground: Colors.transparent,
              plusButton: SpinnerButtonStyle(
                elevation: 0,
                width: Constants.getAdapterWidth(45),
                height: Constants.getAdapterHeight(45),
                color: Colors.transparent,
                child: LoadAssetImage("home/home_plus", format: "png", width: Constants.getAdapterWidth(56), height: Constants.getAdapterHeight(56)),
              ),
              minusButton: SpinnerButtonStyle(
                elevation: 0,
                width: Constants.getAdapterWidth(45),
                height: Constants.getAdapterHeight(45),
                color: Colors.transparent,
                child: LoadAssetImage("home/home_minus", format: "png", width: Constants.getAdapterWidth(56), height: Constants.getAdapterHeight(56)),
              ),
              onChange: (newValue) {
                this._cashierBloc.add(SelectProductSpec(
                      specList: cashierState.specList,
                      specSelected: cashierState.specSelected,
                      makeList: cashierState.makeList,
                      makeSelected: cashierState.makeSelected,
                      inputQuantity: newValue,
                    ));
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderItemRow(CashierState cashierState) {
    var lists = new List<Widget>();
    lists.add(Text(
      "${widget.product.name}[${cashierState.specSelected?.specification}]",
      style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#010101"), fontSize: 32),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ));
    //做法
    StringBuffer sb = new StringBuffer();
    cashierState.makeSelected.forEach((item) {
      if (sb.length > 0) {
        sb.write(",");
      }
      sb.write("${item.name}");
      if (item.salePrice > 0) {
        sb.write("*¥${OrderUtils.instance.removeDecimalZeroFormat(item.salePrice, precision: 2)}");
      }
      if (cashierState.inputQuantity > 1) {
        sb.write("*${OrderUtils.instance.removeDecimalZeroFormat(cashierState.inputQuantity)}");
      }
    });

    if (sb.length > 0) {
      lists.add(Text(
        "${sb.toString()}",
        style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#666666"), fontSize: 24),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ));
    }

    return lists;
  }

  ///构建商品做法
  Widget _buildProductMake(CashierState cashierState, MakeInfo make, bool selected) {
    var backgroundColor = selected ? Constants.hexStringToColor("#F8F7FF") : Constants.hexStringToColor("#FFFFFF");
    var borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#D0D0D0");
    var titleColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#333333");

    return InkWell(
      onTap: () {
        //当行商品做法清单
        List<OrderItemMake> flavors = (cashierState.makeSelected ?? <OrderItemMake>[]).map((e) => OrderItemMake.clone(e)).toList();
        //分组内单选
        if (make.isRadio == 1) {
          flavors.removeWhere((x) => x.group == make.categoryId && x.makeId != make.id);
        }

        var exMake = flavors.firstWhere((x) => x.makeId == make.id, orElse: () => null);
        if (exMake == null) {
          OrderItemMake itemMake = new OrderItemMake();
          itemMake.id = "${IdWorkerUtils.getInstance().generate()}";
          itemMake.tenantId = Global.instance.authc?.tenantId;
          itemMake.orderId = "";
          itemMake.tradeNo = "";
          itemMake.itemId = "";
          itemMake.makeId = make.id;
          itemMake.quantity = cashierState.inputQuantity;
          itemMake.salePrice = make.addPrice;
          itemMake.price = itemMake.salePrice;
          itemMake.name = make.description;
          itemMake.hand = 0;
          itemMake.qtyFlag = make.qtyFlag; //1-不加价，2-固定加价，3-按数量加价
          itemMake.isRadio = make.isRadio;
          itemMake.type = make.categoryType;
          itemMake.baseQuantity = 1;
          if (make.isRadio == 0) {
            //多选
            itemMake.group = itemMake.id;
          } else {
            itemMake.group = make.categoryId;
          }

          itemMake.createUser = Constants.DEFAULT_CREATE_USER;
          itemMake.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");

          flavors.add(itemMake);
        } else {
          //口味类基准数量只能为1
          if (make.categoryType == 1) {
            //类型 0口味、1做法
            exMake.baseQuantity += 1;
            exMake.quantity = exMake.baseQuantity * cashierState.inputQuantity;
            exMake.modifyUser = Constants.DEFAULT_MODIFY_USER;
            exMake.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
          }
        }

        this._cashierBloc.add(SelectProductSpec(
              specList: cashierState.specList,
              specSelected: cashierState.specSelected,
              makeList: cashierState.makeList,
              inputQuantity: cashierState.inputQuantity,
              makeSelected: flavors.map((e) => OrderItemMake.clone(e)).toList(),
            ));

        // Future.delayed(Duration(milliseconds: 30)).whenComplete(() {
        //   if (widget.onAccept != null) {
        //     var args = ProductSpecArgs(item);
        //     widget.onAccept(args);
        //   }
        // });
      },
      onLongPress: () {
        var selected = cashierState.makeSelected.any((x) => x.makeId == make.id);
        if (selected) {
          //当行商品做法清单
          List<OrderItemMake> flavors = List.from(cashierState.makeSelected ?? <OrderItemMake>[]);
          //移除做法
          flavors.removeWhere((x) => x.makeId == make.id);
          this._cashierBloc.add(
                SelectProductSpec(
                  specList: cashierState.specList,
                  specSelected: cashierState.specSelected,
                  makeList: cashierState.makeList,
                  inputQuantity: cashierState.inputQuantity,
                  makeSelected: flavors,
                ),
              );
        }
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          Container(
            padding: Constants.paddingAll(10),
            width: Constants.getAdapterWidth(176),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 1.0),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${make.description}",
                  style: TextStyles.getTextStyle(fontSize: 28, color: titleColor),
                ),
                Visibility(
                  visible: make.addPrice > 0,
                  child: Text(
                    "${make.addPrice}",
                    style: TextStyles.getTextStyle(fontSize: 28, color: titleColor),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: cashierState.makeSelected.any((x) => x.makeId == make.id),
            child: Positioned.directional(
              start: Constants.getAdapterWidth(2),
              top: Constants.getAdapterHeight(2),
              width: Constants.getAdapterWidth(30),
              height: Constants.getAdapterHeight(40),
              textDirection: TextDirection.ltr,
              child: Container(
                alignment: Alignment.topCenter,
                padding: Constants.paddingLTRB(0, 0, 0, 0),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: ImageUtils.getAssetImage("home/home_discount"),
                  ),
                ),
                child: Text(
                  "${cashierState.makeSelected.any((x) => x.makeId == make.id) ? OrderUtils.instance.removeDecimalZeroFormat(cashierState.makeSelected.lastWhere((x) => x.makeId == make.id).quantity) : '0'}",
                  style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///构建商品规格
  Widget _buildProductSpec(CashierState cashierState, ProductSpec item, bool selected) {
    var backgroundColor = selected ? Constants.hexStringToColor("#F8F7FF") : Constants.hexStringToColor("#FFFFFF");
    var borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#D0D0D0");
    var titleColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#333333");

    return InkWell(
      onTap: () {
        this._cashierBloc.add(
              SelectProductSpec(
                specList: cashierState.specList,
                specSelected: item,
                makeList: cashierState.makeList,
                makeSelected: cashierState.makeSelected,
                inputQuantity: cashierState.inputQuantity,
              ),
            );

        // Future.delayed(Duration(milliseconds: 30)).whenComplete(() {
        //   if (widget.onAccept != null) {
        //     var args = ProductSpecArgs(item);
        //     widget.onAccept(args);
        //   }
        // });
      },
      child: Container(
        padding: Constants.paddingAll(10),
        width: Constants.getAdapterWidth(193),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "${item.specification}",
              style: TextStyles.getTextStyle(fontSize: 28, color: titleColor),
            ),
            Text(
              "${item.salePrice}",
              style: TextStyles.getTextStyle(fontSize: 28, color: titleColor),
            ),
          ],
        ),
      ),
    );
  }

  ///构建底部工具栏
  Widget _buildFooter(CashierState cashierState) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(20, 5, 20, 5),
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          MaterialButton(
            child: Text("清空做法", style: TextStyles.getTextStyle(fontSize: 24, color: Constants.hexStringToColor("#FFFFFF"))),
            minWidth: Constants.getAdapterWidth(90),
            height: Constants.getAdapterHeight(60),
            color: Constants.hexStringToColor("#FF3600"),
            textColor: Constants.hexStringToColor("#FFFFFF"),
            shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
            onPressed: () async {
              //当行商品做法清单
              List<OrderItemMake> flavors = (cashierState.makeSelected ?? <OrderItemMake>[]).map((e) => OrderItemMake.clone(e)).toList();
              flavors.clear();

              this._cashierBloc.add(
                    SelectProductSpec(
                      specList: cashierState.specList,
                      specSelected: cashierState.specSelected,
                      makeList: cashierState.makeList,
                      makeSelected: flavors,
                      inputQuantity: cashierState.inputQuantity,
                    ),
                  );
            },
          ),
          Space(
            width: Constants.getAdapterWidth(20),
          ),
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(100),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("确定", style: TextStyles.getTextStyle(fontSize: 32, color: Color(0xFFFFFFFF))),
            ),
            color: Color(0xFF7A73C7),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () {
              var args = new ProductSpecArgs(cashierState.specSelected, cashierState.makeSelected, cashierState.inputQuantity);
              if (widget.onAccept != null) {
                widget.onAccept(args);
              }
            },
          ),
        ],
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: Constants.getAdapterHeight(90.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#7A73C7"),
        border: Border.all(width: 0, color: Constants.hexStringToColor("#7A73C7")),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: Constants.paddingOnly(left: 15),
              alignment: Alignment.centerLeft,
              child: Text("选择规格:${widget.product.name}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 32)),
            ),
          ),
          InkWell(
            onTap: () {
              if (widget.onClose != null) {
                widget.onClose();
              }
            },
            child: Padding(
              padding: Constants.paddingSymmetric(horizontal: 15),
              child: Icon(CommunityMaterialIcons.close_box, color: Constants.hexStringToColor("#FFFFFF"), size: Constants.getAdapterWidth(56)),
            ),
          ),
        ],
      ),
    );
  }
}

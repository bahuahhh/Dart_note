import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_base_parameter.dart';
import 'package:estore_app/enums/module_key_code.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/keyboards/keyboard.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GiftPage extends StatefulWidget {
  // 订单对象
  final OrderObject orderObject;

  //标识是否需要校验
  final String permissionCode;

  //当前行
  final OrderItem orderItem;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  GiftPage(this.orderObject, this.orderItem, this.permissionCode, {this.onAccept, this.onClose});

  @override
  _GiftPageState createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> with SingleTickerProviderStateMixin {
  //业务逻辑处理
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);

    //加载折扣原因
    _cashierBloc.add(LoadReason());

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
      padding: Constants.paddingLTRB(25, 28, 25, 28),
      height: Constants.getAdapterHeight(610),
      width: double.infinity,
      color: Constants.hexStringToColor("#F0F0F0"),
      child: GridView.builder(
        itemCount: cashierState?.reasonsList?.length,
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: Constants.getAdapterWidth(10),
          crossAxisSpacing: Constants.getAdapterHeight(10),
          childAspectRatio: Constants.getAdapterWidth(400) / Constants.getAdapterHeight(200),
        ),
        itemBuilder: (context, index) {
          var item = cashierState.reasonsList[index];
          var selected = (item.id == cashierState.reasonSelected.id);
          return _buildReason(item, selected);
        },
      ),
    );
  }

  ///构建折扣原因
  Widget _buildReason(BaseParameter item, bool selected) {
    var backgroundColor = selected ? Constants.hexStringToColor("#F8F7FF") : Constants.hexStringToColor("#FFFFFF");
    var borderColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#D0D0D0");
    var titleColor = selected ? Constants.hexStringToColor("#7A73C7") : Constants.hexStringToColor("#333333");

    return InkWell(
      onTap: () {
        this._cashierBloc.add(SelectReason(reason: item));
      },
      child: Container(
        padding: Constants.paddingAll(0),
        width: Constants.getAdapterWidth(155),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Text(
          "${item.name}",
          style: TextStyles.getTextStyle(fontSize: 28, color: titleColor),
        ),
      ),
    );
  }

  ///构建底部工具栏
  Widget _buildFooter(CashierState cashierState) {
    return Container(
      height: Constants.getAdapterHeight(100),
      padding: Constants.paddingLTRB(0, 14, 0, 16),
      decoration: BoxDecoration(
        color: Color(0xFFF0F0F0),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(140),
              height: Constants.getAdapterHeight(50),
              alignment: Alignment.center,
              child: Text("取消", style: TextStyles.getTextStyle(fontSize: 32, color: Color(0xFF333333))),
            ),
            color: Color(0xFFD0D0D0),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose();
              }
            },
          ),
          Space(
            width: Constants.getAdapterWidth(20),
          ),
          FlatButton(
            child: Container(
              width: Constants.getAdapterWidth(140),
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
              //赠送
              var orderItem = widget.orderItem;

              if (orderItem == null) {
                ToastUtils.show("改价当前不可用");
                return;
              }

              var args = new GiftArgs(orderItem, "${cashierState.reasonSelected.name}");
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
              child: Text("赠送原因", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 32)),
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

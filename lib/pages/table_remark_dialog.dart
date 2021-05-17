import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/table_cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TableRemarkDialog extends StatefulWidget {
  // 订单对象
  final OrderObject orderObject;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  TableRemarkDialog(this.orderObject, {this.onAccept, this.onClose});

  @override
  _TableRemarkDialogState createState() => _TableRemarkDialogState();
}

class _TableRemarkDialogState extends State<TableRemarkDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  //业务逻辑处理
  TableCashierBloc _tableCashierBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _tableCashierBloc = BlocProvider.of<TableCashierBloc>(context);
    assert(this._tableCashierBloc != null);

    //加载折扣原因
    //_tableCashierBloc.add(LoadReason());

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TableCashierBloc, TableCashierState>(
      cubit: this._tableCashierBloc,
      buildWhen: (previousState, currentState) {
        return true;
      },
      builder: (context, state) {
        return Material(
          color: Colors.transparent,
          child: Container(
            padding: Constants.paddingAll(0),
            child: Center(
              child: Container(
                padding: Constants.paddingAll(5),
                decoration: ShapeDecoration(
                  color: Constants.hexStringToColor("#FFFFFF"),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6.0))),
                ),
                child: Column(
                  children: <Widget>[
                    ///顶部标题
                    _buildHeader(state),

                    ///中部操作区
                    _buildContent(state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ///构建内容区域
  Widget _buildContent(TableCashierState state) {
    return Container(
      padding: Constants.paddingLTRB(25, 10, 25, 20),
      height: Constants.getAdapterHeight(400),
      width: double.infinity,
      color: Constants.hexStringToColor("#FFFFFF"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Space(height: Constants.getAdapterHeight(10)),
          Expanded(
            child: Container(
              child: AutoSizeTextField(
                controller: this._controller,
                style: TextStyles.getTextStyle(fontSize: 32),
                maxLines: 7,
                decoration: InputDecoration(
                  contentPadding: Constants.paddingOnly(top: 20, left: 20, bottom: 20),
                  hintText: "请输入单注...",
                  hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
                  filled: true,
                  fillColor: Constants.hexStringToColor("#FFFFFF"),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Constants.hexStringToColor("#E0E0E0"), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Constants.hexStringToColor("#7A73C7"), width: 1),
                  ),
                ),
              ),
            ),
          ),
          Space(height: Constants.getAdapterHeight(10)),
          FlatButton(
            child: Container(
              height: Constants.getAdapterHeight(80),
              alignment: Alignment.center,
              child: Text(
                '确定',
                style: TextStyles.getTextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            padding: Constants.paddingAll(0),
            color: Constants.hexStringToColor("#7A73C7"),
            shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
            onPressed: () {
              // OrderObject orderObject = widget.orderObject;
              // var args = new TableBargainArgs(orderObject, 0, "", restoreOriginalPrice: true);
              // if (widget.onAccept != null) {
              //   widget.onAccept(args);
              // }
            },
          ),
        ],
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader(TableCashierState state) {
    return Container(
      height: Constants.getAdapterHeight(90.0),
      decoration: BoxDecoration(
        color: Constants.hexStringToColor("#FFFFFF"),
        border: Border(bottom: BorderSide(width: 0, color: Constants.hexStringToColor("#999999"))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: Constants.paddingOnly(left: 15),
              alignment: Alignment.centerLeft,
              child: Text("整单备注", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32, fontWeight: FontWeight.bold)),
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
              child: Icon(CommunityMaterialIcons.close_box, color: Constants.hexStringToColor("#7A73C7"), size: Constants.getAdapterWidth(56)),
            ),
          ),
        ],
      ),
    );
  }
}

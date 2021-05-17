import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/assistant_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_base_parameter.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/keyboards/keyboard.dart';
import 'package:estore_app/order/order_item.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssistantRefundQuantityDialog extends StatefulWidget {
  // 订单对象
  final OrderObject orderObject;

  //标识是否需要校验
  final String permissionCode;

  //当前行
  final OrderItem orderItem;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;

  AssistantRefundQuantityDialog(this.orderObject, this.orderItem, this.permissionCode, {this.onAccept, this.onClose});

  @override
  _AssistantRefundQuantityDialogState createState() => _AssistantRefundQuantityDialogState();
}

class _AssistantRefundQuantityDialogState extends State<AssistantRefundQuantityDialog> with SingleTickerProviderStateMixin {
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  ///键盘功能的业务逻辑处理
  KeyboardBloc _keyboardBloc;

  //业务逻辑处理
  AssistantBloc _assistantBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _keyboardBloc = BlocProvider.of<KeyboardBloc>(context);
    assert(this._keyboardBloc != null);

    _assistantBloc = BlocProvider.of<AssistantBloc>(context);
    assert(this._assistantBloc != null);

    //加载折扣原因
    _assistantBloc.add(LoadReason());

    //1.注册键盘
    NumberKeyboard.register(buttonWidth: 130, buttonHeight: 120, buttonSpace: 10);
    //2.初始化键盘
    KeyboardManager.init(context, this._keyboardBloc);

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      ///可退货数量
      double refundQuantity = widget.orderItem.quantity;
      final text = refundQuantity.toString();
      _controller.value = _controller.value.copyWith(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantBloc, AssistantState>(
      cubit: this._assistantBloc,
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
  Widget _buildContent(AssistantState state) {
    return Container(
      padding: Constants.paddingLTRB(25, 10, 25, 20),
      height: Constants.getAdapterHeight(750),
      width: double.infinity,
      color: Constants.hexStringToColor("#FFFFFF"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            height: Constants.getAdapterHeight(100),
            padding: Constants.paddingLTRB(0, 10, 0, 10),
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
                    child: this._buildTextField(state),
                  ),
                  InkWell(
                    onTap: () {
                      //清空内容
                      _controller.clear();
                    },
                    child: Icon(
                      CommunityMaterialIcons.close_circle_outline,
                      color: Constants.hexStringToColor("#D0D0D0"),
                      size: Constants.getAdapterWidth(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Space(height: Constants.getAdapterHeight(10)),
          Expanded(
            child: Container(
              child: BlocBuilder<KeyboardBloc, KeyboardState>(
                  cubit: this._keyboardBloc,
                  buildWhen: (previousState, currentState) {
                    return true;
                  },
                  builder: (context, state) {
                    return state.keyboard == null ? Container() : state.keyboard.builder(context, state.controller);
                  }),
            ),
          ),
          Space(height: Constants.getAdapterHeight(20)),
          Container(
            width: double.infinity,
            height: Constants.getAdapterHeight(180),
            padding: Constants.paddingLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#F8F8F8"),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              border: Border.all(width: 1, color: Constants.hexStringToColor("#D0D0D0")),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text("退货原因", style: TextStyles.getTextStyle(fontSize: 32)),
                Space(height: Constants.getAdapterHeight(20)),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: Constants.paddingAll(0),
                    itemCount: state?.reasonsList?.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return Space(width: Constants.getAdapterWidth(20));
                    },
                    physics: AlwaysScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      var item = state.reasonsList[index];
                      var selected = (item.id == state.reasonSelected.id);
                      return _buildReason(item, selected);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
        this._assistantBloc.add(SelectReason(reason: item));
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

  ///构建商品搜索框
  Widget _buildTextField(AssistantState state) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(96),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: true,
        textAlign: TextAlign.start,
        controller: this._controller,
        focusNode: this._focus,
        style: TextStyles.getTextStyle(fontSize: 32),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "请输入退货数量",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),

        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
        keyboardType: NumberKeyboard.inputType,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: true, //长按复制 剪切
        autocorrect: false,
        onFieldSubmitted: (inputValue) async {
          var orderItem = widget.orderItem;

          if (orderItem == null) {
            ToastUtils.show("退货当前不可用");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          if (StringUtils.isBlank(inputValue)) {
            ToastUtils.show("请输入退货数量");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          double refundQuantity = Convert.toDouble(inputValue);
          String refundReason = refundQuantity == 0 ? "" : "${state.reasonSelected.name}";
          if (refundQuantity > orderItem.quantity) {
            ToastUtils.show("输错了，最多可退${orderItem.quantity}份");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }

          FocusScope.of(context).requestFocus(_focus);
          var args = new TableRefundQuantityArgs(orderItem, refundQuantity, refundReason);
          if (widget.onAccept != null) {
            widget.onAccept(args);
          }
        },
      ),
    );
  }

  ///构建顶部标题栏
  Widget _buildHeader(AssistantState state) {
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
              child: Text("退货", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32, fontWeight: FontWeight.bold)),
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

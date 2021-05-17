import 'package:barcode_scan/gen/protos/protos.pbenum.dart';
import 'package:barcode_scan/platform_wrapper.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/cashier_bloc.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/keyboards/keyboard.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/member/member.dart';
import 'package:estore_app/member/member_utils.dart';
import 'package:estore_app/order/order_object.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MemberPage extends StatefulWidget {
  final OrderObject orderObject;

  final OnAcceptCallback onAccept;
  final OnCloseCallback onClose;
  final VoidCallback onCallback;

  MemberPage(this.orderObject, {this.onAccept, this.onClose, this.onCallback});

  @override
  _MemberPageState createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> with SingleTickerProviderStateMixin {
  //会员识别输入
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //键盘功能的业务逻辑处理
  KeyboardBloc _keyboardBloc;
  //业务逻辑处理
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    _keyboardBloc = BlocProvider.of<KeyboardBloc>(context);
    assert(this._keyboardBloc != null);

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);

    //1.注册键盘
    NumberKeyboard.register(buttonWidth: 130, buttonHeight: 120, buttonSpace: 10);
    //2.初始化键盘
    KeyboardManager.init(context, this._keyboardBloc);

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        padding: Constants.paddingAll(0),
        child: Column(
          children: <Widget>[
            ///顶部标题
            _buildHeader(),

            ///中部操作区
            _buildContent(),
          ],
        ),
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent() {
    return Container(
      padding: Constants.paddingLTRB(25, 20, 25, 20),
      height: Constants.getAdapterHeight(700),
      width: double.infinity,
      color: Constants.hexStringToColor("#F0F0F0"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: Constants.getAdapterWidth(600),
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
                    child: this._buildTextField(),
                  ),
                  InkWell(
                    onTap: () async {
                      var scanResult = await BarcodeScanner.scan(options: scanOptions);
                      if (scanResult.type == ResultType.Barcode) {
                        //扫码成功
                        var format = scanResult.format;
                        var memberCode = scanResult.rawContent;
                        FLogger.info("会员认证识别到${format.name}码,内容:$memberCode");

                        _controller.value = _controller.value.copyWith(
                          text: memberCode,
                          selection: TextSelection(baseOffset: 0, extentOffset: memberCode.length),
                          composing: TextRange.empty,
                        );
                        FocusScope.of(context).requestFocus(_focus);

                        _getMemberInfo(memberCode);
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
          Space(height: Constants.getAdapterHeight(20)),
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
        ],
      ),
    );
  }

  ///构建商品搜索框
  Widget _buildTextField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Constants.getAdapterHeight(96),
      ),
      child: TextFormField(
        enabled: true,
        autofocus: true,
        textAlign: TextAlign.start,
        focusNode: this._focus,
        controller: this._controller,
        style: TextStyles.getTextStyle(fontSize: 32),
        decoration: InputDecoration(
          contentPadding: Constants.paddingSymmetric(horizontal: 15),
          hintText: "请输入手机号或会员码",
          hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
          filled: true,
          fillColor: Constants.hexStringToColor("#FFFFFF"),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0)), borderSide: BorderSide(color: Colors.transparent, width: 0.0)),
        ),

        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(24)],
        keyboardType: NumberKeyboard.inputType,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        enableInteractiveSelection: true, //长按复制 剪切
        autocorrect: false,
        onFieldSubmitted: (inputValue) async {
          if (StringUtils.isBlank(inputValue)) {
            ToastUtils.show("请输入手机号或会员码");
            FocusScope.of(context).requestFocus(_focus);
            return;
          }
          _getMemberInfo(inputValue);
        },
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
              child: Text("会员认证", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 32)),
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

  void _getMemberInfo(String code) async {
    //查询服务端会员信息
    var queryResult = await MemberUtils.instance.httpQueryMemberInfo(code);

    //查询失败
    if (queryResult.item1) {
      Member member = queryResult.item4;
      member.judgeCardType = Convert.toInt(queryResult.item3.value);
      //是否有会员卡
      if (member.cardList != null && member.cardList.length > 0) {
        //仅仅有1张会员卡
        if (member.cardList.length == 1) {
          member.defaultCard = member.cardList[0];
        } else {
          //提示收银员选择会员卡
          print(">>>>>会员卡数量:${member.cardList.length}");

          member.defaultCard = member.cardList[0];
        }
      } else {
        //没有会员卡
        member.defaultCard = null;
      }

      var newOrderObject = OrderObject.clone(widget.orderObject);
      newOrderObject.member = member;
      if (widget.onAccept != null) {
        var args = MemberArgs(newOrderObject);
        widget.onAccept(args);
      }
    } else {
      ToastUtils.show("${queryResult.item2}");
    }
  }
}

class MemberViewPage extends StatefulWidget {
  final OrderObject orderObject;

  final OnChangedCallback onChanged;
  final OnCancelCallback onCancel;
  final OnCloseCallback onClose;

  MemberViewPage(this.orderObject, {this.onChanged, this.onCancel, this.onClose});

  @override
  _MemberViewPageState createState() => _MemberViewPageState();
}

class _MemberViewPageState extends State<MemberViewPage> with SingleTickerProviderStateMixin {
  CashierBloc _cashierBloc;

  @override
  void initState() {
    super.initState();

    _cashierBloc = BlocProvider.of<CashierBloc>(context);
    assert(this._cashierBloc != null);

    WidgetsBinding.instance.addPostFrameCallback((callback) {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        padding: Constants.paddingAll(0),
        child: Column(
          children: <Widget>[
            ///顶部标题
            _buildHeader(),

            ///中部操作区
            _buildContent(),
          ],
        ),
      ),
    );
  }

  ///构建内容区域
  Widget _buildContent() {
    return Container(
      padding: Constants.paddingLTRB(30, 30, 30, 30),
      height: Constants.getAdapterHeight(510),
      width: double.infinity,
      color: Constants.hexStringToColor("#FFFFFF"),
      child: Column(
        children: <Widget>[
          Container(
            height: Constants.getAdapterHeight(350),
            padding: Constants.paddingLTRB(15, 15, 15, 10),
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#F8F7FF"),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              border: Border.all(width: 1, color: Constants.hexStringToColor("#7A73C7")),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topCenter,
                          child: (widget.orderObject.member == null || StringUtils.isBlank(widget.orderObject.member.headImgUrl))
                              ? CircleAvatar(
                                  radius: Constants.getAdapterHeight(48),
                                  backgroundColor: Colors.white,
                                  backgroundImage: ImageUtils.getAssetImage("home/member_header"),
                                )
                              : ClipOval(
                                  child: Image.network(
                                    "${widget.orderObject.member.headImgUrl}",
                                    width: Constants.getAdapterWidth(96),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        Space(width: Constants.getAdapterWidth(20)),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text("${widget.orderObject.member == null ? "--" : widget.orderObject.member.name}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32)),
                              Space(height: Constants.getAdapterHeight(10)),
                              Text("电话：${widget.orderObject.member == null ? "--" : widget.orderObject.member.mobile}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 28)),
                              Space(height: Constants.getAdapterHeight(10)),
                              Text("卡号：${widget.orderObject.member == null ? "--" : widget.orderObject.member.defaultCard.cardNo}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 28)),
                              Space(height: Constants.getAdapterHeight(10)),
                              Text("生日：${widget.orderObject.member == null ? "--" : widget.orderObject.member.birthday}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 28)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: Constants.getAdapterHeight(90),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Center(
                                  child: Text("会员余额", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 24)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text("${widget.orderObject.member == null ? "--" : widget.orderObject.member.totalAmount}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Center(
                                  child: Text("会员积分", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 24)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text("${widget.orderObject.member == null ? "--" : widget.orderObject.member.totalPoint}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Center(
                                  child: Text("会员等级", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 24)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text("${widget.orderObject.member == null ? "--" : widget.orderObject.member.memberLevelName}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Space(height: Constants.getAdapterHeight(20)),
          Container(
            height: Constants.getAdapterHeight(80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  child: Text(
                    "更换会员",
                    style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#FFFFFF")),
                  ),
                  minWidth: Constants.getAdapterWidth(240),
                  height: Constants.getAdapterHeight(80),
                  color: Constants.hexStringToColor("#7A73C7"),
                  textColor: Constants.hexStringToColor("#FFFFFF"),
                  shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
                  onPressed: () {
                    if (widget.onChanged != null) {
                      var newOrderObject = OrderObject.clone(widget.orderObject);
                      newOrderObject.member = null;
                      var args = new MemberArgs(newOrderObject);

                      widget.onChanged(args);
                    }
                  },
                ),
                Space(width: Constants.getAdapterWidth(50)),
                MaterialButton(
                  child: Text(
                    "取消会员",
                    style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#C773A8")),
                  ),
                  minWidth: Constants.getAdapterWidth(240),
                  height: Constants.getAdapterHeight(80),
                  color: Constants.hexStringToColor("#FFF4FB"),
                  textColor: Constants.hexStringToColor("#C773A8"),
                  shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
                  onPressed: () {
                    if (widget.onCancel != null) {
                      var newOrderObject = OrderObject.clone(widget.orderObject);
                      newOrderObject.member = null;

                      var args = new MemberArgs(newOrderObject);

                      widget.onCancel(args);
                    }
                  },
                ),
              ],
            ),
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
              child: Text("会员信息", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 32)),
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

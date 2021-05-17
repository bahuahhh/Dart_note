import 'dart:io';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/blocs/login_bloc.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_worker.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/i18n/i18n.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/upgrade/upgrade_utils.dart';
import 'package:estore_app/utils/active_code_utils.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/devopt_utils.dart';
import 'package:estore_app/utils/mqtt_utils.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/toast_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/progress_button.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //操作员工号
  final FocusNode _workerNoFocus = FocusNode();
  final TextEditingController _workerNoController = TextEditingController();

  //操作员密码
  final FocusNode _passwordFocus = FocusNode();
  final TextEditingController _passwordController = TextEditingController();

  //登录业务逻辑处理
  LoginBloc _loginBloc;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _loginBloc = BlocProvider.of<LoginBloc>(context);
    assert(_loginBloc != null);

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FocusScope.of(context).requestFocus(this._workerNoFocus);
      _workerNoFocus.addListener(() {
        if (_workerNoFocus.hasFocus) {}
      });
    });
  }

  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;

    await DevOptUtils.instance.startup();

    await MqttUtils.instance.startup();

    await checkActiveCode();

    //Andorid平台升级提示
    if (Platform.isAndroid) {
      await autoUpdate();
    }
  }

  Future<void> autoUpdate() async {
    //版本检测
    await UpgradeUtils.instance.updateDatabase();
    var versionObjectResult = await UpgradeUtils.instance.checkNewVersion();
    //有新版本
    if (versionObjectResult.item1) {
      var versionObject = versionObjectResult.item2;

      YYDialog dialog;
      var onClose = () {
        dialog?.dismiss();
      };
      var widget = UpgradeDialogPage(
        versionObject,
        onClose: onClose,
      );
      dialog = DialogUtils.showDialog(context, widget, width: 600, height: 600);
    }
  }

  Future<void> checkActiveCode() async {
    print("checkActiveCode:${Global.instance.online}");
    //联机状态获取激活码运行信息
    var activeCodeInfo = await ActiveCodeUtils.instance.getActiveInfo(Global.instance.authc);
    if (activeCodeInfo.item1) {
      Global.instance.authc.activeCode = activeCodeInfo.item4;
      await ActiveCodeUtils.instance.updateActiveCode(Global.instance.authc);

      print("认证信息:${Global.instance.authc.activeCode}");
    } else {
      FLogger.error("获取认证失败:<${activeCodeInfo.item2}><${activeCodeInfo.item3}>");
    }
  }

  @override
  void dispose() {
    super.dispose();

    //释放工号资源
    this._workerNoController.dispose();
    this._workerNoFocus.dispose();
    //释放密码资源
    this._passwordController.dispose();
    this._passwordFocus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //fullScreenSetting();

    final local = AppLocalizations.of(context);
    assert(local != null);

    return KeyboardDismissOnTap(
      child: Container(
        decoration: BoxDecoration(
          color: Constants.hexStringToColor("#FFFFFF"),
          image: DecorationImage(image: AssetImage(ImageUtils.getImgPath("login/background", format: "jpg")), fit: BoxFit.cover),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomPadding: false,
          body: SafeArea(
            child: BlocListener<LoginBloc, LoginState>(
              cubit: this._loginBloc,
              listener: (context, state) {
                if (state.status == LoginStatus.Loading) {
                  EasyLoading.show(status: "登录验证中...");
                } else if (state.status == LoginStatus.Failure) {
                  ///显示错误提示，1秒后自动关闭
                  EasyLoading.showError("${state.message}", duration: Duration(seconds: 3));
                } else if (state.status == LoginStatus.Success) {
                  ///关闭提示框
                  EasyLoading.dismiss();
                  Future.delayed(Duration(milliseconds: 50)).then((e) {
                    if (Global.instance.online) {
                      NavigatorUtils.instance.push(context, RouterManager.DOWNLOAD_PAGE, replace: true);
                    } else {
                      NavigatorUtils.instance.push(context, RouterManager.HOME_PAGE, replace: true);
                    }
                  });
                }
              },
              child: BlocBuilder<LoginBloc, LoginState>(
                cubit: _loginBloc,
                buildWhen: (previousState, currentState) {
                  return true;
                },
                builder: (context, state) {
                  return Container(
                    padding: Constants.paddingAll(0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: Constants.paddingLTRB(10, 5, 10, 5),
                          height: Constants.getAdapterHeight(60),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Text(
                                        "SN:${Global.instance.authc?.tenantId}${Global.instance.authc?.storeNo}${Global.instance.authc?.posNo}",
                                        style: TextStyles.getTextStyle(color: Colors.grey[500], fontSize: 24),
                                      ),
                                      Space(width: Constants.getAdapterWidth(20)),
                                      Container(
                                        padding: Constants.paddingAll(0),
                                        width: Constants.getAdapterWidth(90),
                                        height: Constants.getAdapterHeight(30),
                                        alignment: Alignment.center,
                                        color: Colors.transparent,
                                        child: Text(
                                          Global.instance.authc?.activeCode?.trialFlag == 1 ? "试用版" : "v${Global.instance.appVersion}",
                                          style: TextStyles.getTextStyle(color: Colors.grey[500], fontSize: 24),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Space(
                                height: Constants.getAdapterHeight(5),
                              ),
                              Expanded(
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.horizontal(left: Radius.circular(0.0), right: Radius.circular(0.0)),
                                    border: Border(bottom: BorderSide(width: 0.0, style: BorderStyle.none)),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      NavigatorUtils.instance.push(context, RouterManager.SYS_INIT_PAGE);
                                    },
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        CommunityMaterialIcons.cog_outline,
                                        size: Constants.getAdapterWidth(48),
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: Constants.paddingLTRB(80, 10, 80, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Center(
                                child: LoadAssetImage("brand_logo", format: "png", height: Constants.getAdapterHeight(58), width: Constants.getAdapterWidth(200), fit: BoxFit.fill),
                              ),
                              Space(height: Constants.getAdapterHeight(20)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: Constants.getAdapterHeight(80), maxWidth: Constants.getAdapterWidth(720)),
                                child: _buildStoreNoTextField(state),
                              ),
                              Space(height: Constants.getAdapterHeight(20)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: Constants.getAdapterHeight(80), maxWidth: Constants.getAdapterWidth(720)),
                                child: _buildStoreNameTextField(state),
                              ),
                              Space(height: Constants.getAdapterHeight(20)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: Constants.getAdapterHeight(80), maxWidth: Constants.getAdapterWidth(720)),
                                child: _buildWorkerNoTextField(state),
                              ),
                              Space(height: Constants.getAdapterHeight(20)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: Constants.getAdapterHeight(80), maxWidth: Constants.getAdapterWidth(720)),
                                child: _buildPasswordTextField(state),
                              ),
                              Space(height: Constants.getAdapterHeight(30)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: Constants.getAdapterHeight(80), maxWidth: Constants.getAdapterWidth(720)),
                                child: ProgressButton(
                                  defaultWidget: Text(
                                    "登录",
                                    style: TextStyles.getTextStyle(fontSize: 32, color: Constants.hexStringToColor("#FFFFFF")),
                                  ),
                                  color: Constants.hexStringToColor("#7A73C7"),
                                  width: double.infinity,
                                  height: Constants.getAdapterHeight(80),
                                  borderRadius: Constants.getAdapterHeight(40),
                                  animate: true,
                                  onPressed: state.isValid
                                      ? () async {
                                          //校验激活码是否可用
                                          var validResult = ActiveCodeUtils.instance.validActiveCode(DateTime.now());

                                          var enableFlag = validResult.item1;
                                          var noticeFlag = validResult.item2;
                                          var msg = validResult.item3;
                                          if (enableFlag) {
                                            //可用,需要提醒信息
                                            if (noticeFlag) {
                                              DialogUtils.notify(context, "续费通知", "$msg", () {
                                                Future.delayed(Duration(milliseconds: 500), () {
                                                  _login(state);
                                                });
                                              }, width: 495, buttonText: "我知道了");
                                            } else {
                                              _login(state);
                                            }
                                          } else {
                                            DialogUtils.notify(context, "缴费提醒", "$msg", () {}, width: 495);
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  void _login(LoginState state) {
    if (Global.instance.online) {
      _loginBloc.add(WorkerLogin(offline: false));
    } else {
      var title = "脱机登录";
      var info = "操作员[${state.workerNo}]于${DateTimeUtils.formatDate(DateTime.now(), format: "MM-dd HH:mm:ss")}\n进行脱机登录,确认吗?";
      DialogUtils.confirm(context, title, info, () {
        _loginBloc.add(WorkerLogin(offline: true));
      }, () {
        FLogger.warn("用户放弃脱机登录");
      }, width: 500);
    }
  }

  Widget _buildWorkerNoTextField(LoginState state) {
    return TextField(
      enabled: true,
      autofocus: false,
      focusNode: this._workerNoFocus,
      controller: this._workerNoController,
      style: TextStyle(fontSize: Constants.getAdapterFontSize(32)),
      decoration: InputDecoration(
        contentPadding: Constants.paddingOnly(top: 20, left: 20, bottom: 20),
        hintText: "输入操作员工号",
        hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
        filled: true,
        fillColor: Constants.hexStringToColor("#FFFFFF"),
        prefixIcon: LoadAssetImage("login/icon3", format: "png", width: Constants.getAdapterWidth(30), height: Constants.getAdapterHeight(30)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          borderSide: BorderSide(color: Constants.hexStringToColor("#E0E0E0"), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          borderSide: BorderSide(color: Constants.hexStringToColor("#7A73C7"), width: 1),
        ),
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12) //限制长度
      ],
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      maxLines: 1,
      enableInteractiveSelection: true, //长按复制 剪切
      autocorrect: false,
      onChanged: (inputValue) async {
        this._loginBloc.add(WorkerNoChanged(workerNo: inputValue));
      },
    );
  }

  Widget _buildPasswordTextField(LoginState state) {
    return TextFormField(
      enabled: true,
      autofocus: false,
      obscureText: true,
      focusNode: this._passwordFocus,
      controller: this._passwordController,
      style: TextStyles.getTextStyle(fontSize: 32),
      decoration: InputDecoration(
        contentPadding: Constants.paddingOnly(top: 20, left: 20, bottom: 20),
        hintText: "输入操作员密码",
        hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 32),
        filled: true,
        fillColor: Constants.hexStringToColor("#FFFFFF"),
        prefixIcon: LoadAssetImage("login/icon4", format: "png", width: Constants.getAdapterWidth(34), height: Constants.getAdapterHeight(34)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          borderSide: BorderSide(color: Constants.hexStringToColor("#E0E0E0"), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          borderSide: BorderSide(color: Constants.hexStringToColor("#7A73C7"), width: 1),
        ),
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12) //限制长度
      ],
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      maxLines: 1,
      enableInteractiveSelection: true, //长按复制 剪切
      autocorrect: false,
      onChanged: (inputValue) async {
        this._loginBloc.add(PasswordChanged(password: inputValue));
      },
    );
  }

  Widget _buildStoreNoTextField(LoginState state) {
    return TextFormField(
      enabled: false,
      autofocus: false,
      style: TextStyles.getTextStyle(fontSize: 32),
      initialValue: Global.instance.authc?.storeNo,
      decoration: InputDecoration(
        contentPadding: Constants.paddingOnly(top: 20, left: 20, bottom: 20),
        hintText: "",
        hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 24),
        filled: true,
        fillColor: Constants.hexStringToColor("#FFFFFF"),
        prefixIcon: LoadAssetImage("login/icon2", format: "png", width: Constants.getAdapterWidth(34), height: Constants.getAdapterHeight(34), fit: BoxFit.none),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          borderSide: BorderSide(color: Constants.hexStringToColor("#E0E0E0"), width: 1),
        ),
      ),
    );
  }

  Widget _buildStoreNameTextField(LoginState state) {
    return TextFormField(
      enabled: false,
      autofocus: false,
      style: TextStyles.getTextStyle(fontSize: 32),
      initialValue: Global.instance.authc?.storeName,
      decoration: InputDecoration(
        contentPadding: Constants.paddingOnly(top: 20, left: 20, bottom: 20),
        hintText: "",
        hintStyle: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 24),
        filled: true,
        fillColor: Constants.hexStringToColor("#FFFFFF"),
        prefixIcon: LoadAssetImage("login/icon1", format: "png", width: Constants.getAdapterWidth(30), height: Constants.getAdapterHeight(30)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          borderSide: BorderSide(color: Constants.hexStringToColor("#E0E0E0"), width: 1),
        ),
      ),
    );
  }
}

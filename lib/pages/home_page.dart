import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:dart_notification_center/dart_notification_center.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/order/order_utils.dart';
import 'package:estore_app/routers/navigator_utils.dart';
import 'package:estore_app/routers/router_manager.dart';
import 'package:estore_app/utils/authz_utils.dart';
import 'package:estore_app/utils/devopt_utils.dart';
import 'package:estore_app/utils/dialog_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/widgets/load_image.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:getwidget/components/button/gf_icon_button.dart';
import 'package:getwidget/getwidget.dart';
import 'package:getwidget/shape/gf_icon_button_shape.dart';

import 'fast_download.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  //菜单
  final List menus = [

    {'icon': CommunityMaterialIcons.cash_register, 'color': '#00ACEE', 'title': '快速收银', 'route': RouterManager.CASHIER_PAGE},
    // {'icon': CommunityMaterialIcons.table_large, 'color': '#C4302B', 'title': '桌台开单', 'route': RouterManager.TABLE_PAGE},
    {'icon': CommunityMaterialIcons.food_fork_drink, 'color': '#C4302B', 'title': '点单助手', 'route': RouterManager.TABLE_ASSISTANT_PAGE},
    {'icon': CommunityMaterialIcons.ticket_confirmation_outline, 'color': '#25D366', 'title': '销售流水', 'route': RouterManager.TRADE_PAGE},
    {'icon': CommunityMaterialIcons.download, 'color': '#EA4C89', 'title': '下载数据', 'route': RouterManager.DOWNLOAD_PAGE},
    {'icon': CommunityMaterialIcons.cog_outline, 'color': '#0E76A8', 'title': '参数设置', 'route': RouterManager.SETTING_PAGE},
    {'icon': CommunityMaterialIcons.table_large, 'color': '#C4302B', 'title': '交班', 'route': RouterManager.SHIFT_PAGE},
    {'icon': CommunityMaterialIcons.logout_variant, 'color': '#C4302B', 'title': '注销', 'route': RouterManager.EMPTY_PAGE},
    {'icon': CommunityMaterialIcons.logout_variant, 'color': '#FFD700', 'title': '盘点', 'route': RouterManager.INVENTORY_PAGE},
    // {'icon': 'home/avatar', 'title': '会员', 'route': null},
    // {'icon': 'home/avatar', 'title': '沽清', 'route': null},
    // {'icon': 'home/avatar', 'title': '上班', 'route': null},
  ];

  @override
    void initState() {
    super.initState();

    initPlatformState();

    DartNotificationCenter.subscribe(
      channel: 'examples',
      observer: this,
      onNotification: (options) {
        print('Notified: $options');
      },
    );

    BackButtonInterceptor.add(backButtonInterceptor,
        zIndex: 2, name: "home_page_interceptor");
  }
  /// Initialize platform state.
  Future<void> initPlatformState() async {
    if (!mounted) return;

    //初始化操作员权限
    var permission = await AuthzUtils.instance.getPermission(Global.instance.worker);
    Global.instance.worker.permission.addAll(permission.item3);
    Global.instance.worker.maxDiscountRate = permission.item1;
    Global.instance.worker.maxFreeAmount = permission.item2;

    //缓存商品信息
    await OrderUtils.instance.getProductExtList();

    await DevOptUtils.instance.startup();

    await OrderUtils.instance.downloadProductImage();

    await OrderUtils.instance.downloadViceImage();

    await OrderUtils.instance.downloadPrinterImage();
  }

  bool backButtonInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    var currentRoute = info.currentRoute(context);
    if (currentRoute == RouterManager.HOME_PAGE) {
      exitApp(context);
    }
    return false;
  }

  void exitApp(BuildContext context) {
    DialogUtils.confirm(context, "退出系统", "\n您确定要退出系统吗?\n", () {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }, () {
      FLogger.warn("用户放弃退出系统");
    }, width: 500);
  }

  @override
  void dispose() {
    super.dispose();
    BackButtonInterceptor.removeByName("home_page_interceptor");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomPadding: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter, // 10% of the width, so there are ten blinds.
            colors: [Constants.hexStringToColor("#4AB3FD"), Constants.hexStringToColor("#FFFFFF")], // whitish to gray
            tileMode: TileMode.repeated, // repeats the gradient over the canvas
          ),
        ),
        child: SafeArea(
          child: Container(
            padding: Constants.paddingLTRB(0, 0, 0, 10),
            decoration: BoxDecoration(
              color: Constants.hexStringToColor("#FFFFFF"),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Center(
                  child: LoadAssetImage("home/splash", format: "png", height: Constants.getAdapterHeight(320), width: Constants.getAdapterWidth(720), fit: BoxFit.fill),
                ),
                Expanded(
                  child: Container(
                    padding: Constants.paddingAll(20),
                    child: GridView.builder(
                      padding: Constants.paddingAll(0),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      physics: const ScrollPhysics(),
                      itemCount: this.menus.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Constants.hexStringToColor("#FFFFFF"),
                              borderRadius: BorderRadius.all(Radius.circular(4.0)),
                              border: Border.all(width: 1, color: Constants.hexStringToColor("#FFFFFF")),
                            ),
                            child: buildMenus(menus[index]['title'], menus[index]['icon'], menus[index]['color'], menus[index]['route']),
                          ),
                        );
                      },
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: Constants.getAdapterWidth(16),
                        crossAxisSpacing: Constants.getAdapterHeight(16),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "v${Global.instance.appVersion}",
                    style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#999999"), fontSize: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMenus(String title, IconData icon, String color, String route) => InkWell(
        onTap: () {
          if (StringUtils.isNotBlank(title) && StringUtils.isNotBlank(route)) {
            switch (title) {
              case "注销":
                {
                  exitApp(context);
                }
                break;
              case "下载数据":
                {
                  YYDialog dialog;

                  //关闭弹框
                  var onClose = () {
                    dialog?.dismiss();
                  };

                  var onAccept = (args) {
                    dialog?.dismiss();
                  };

                  var widget = FastDownloadPage(
                    onAccept: onAccept,
                    onClose: onClose,
                  );

                  dialog = DialogUtils.showDialog(context, widget, width: 700, height: 500, barrierDismissible: false);
                }
                break;
              default:
                {
                  NavigatorUtils.instance.push(context, route);
                }
                break;
            }
          }
        },
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GFIconButton(
                color: Constants.hexStringToColor(color),
                shape: GFIconButtonShape.circle,
                borderSide: BorderSide(style: BorderStyle.none),
                size: GFSize.LARGE,
                iconSize: Constants.getAdapterWidth(48),
                icon: Icon(
                  icon,
                  color: Constants.hexStringToColor("#FFFFFF"),
                ),
              ),
              Space(
                height: Constants.getAdapterHeight(16),
              ),
              Text(
                title,
                style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#333333"), fontSize: 32),
              )
            ],
          ),
        ),
      );
}

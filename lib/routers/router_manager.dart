import 'package:estore_app/pages/assistant_cart_page.dart';
import 'package:estore_app/pages/assistant_dish_page.dart';
import 'package:estore_app/pages/assistant_page.dart';
import 'package:estore_app/pages/assistant_pay_page.dart';
import 'package:estore_app/pages/cart_page.dart';
import 'package:estore_app/pages/cashier_page.dart';
import 'package:estore_app/pages/download_page.dart';
import 'package:estore_app/pages/empty_page.dart';
import 'package:estore_app/pages/home_page.dart';
import 'package:estore_app/pages/login_page.dart';
import 'package:estore_app/pages/pay_page.dart';
import 'package:estore_app/pages/register_page.dart';
import 'package:estore_app/pages/setting_page.dart';
import 'package:estore_app/pages/shift_page.dart';
import 'package:estore_app/pages/sys_init_page.dart';
import 'package:estore_app/pages/table_cart_page.dart';
import 'package:estore_app/pages/table_cashier_page.dart';
import 'package:estore_app/pages/table_page.dart';
import 'package:estore_app/pages/table_pay_page.dart';
import 'package:estore_app/pages/trade_page.dart';
import 'package:estore_app/routers/router_config.dart';
import 'package:fluro/fluro.dart';

class RouterManager implements RouterProvider {
  static const String REGISTER_PAGE = "/register";
  static const String LOGIN_PAGE = "/login";
  static const String DOWNLOAD_PAGE = "/download";
  static const String HOME_PAGE = "/home";
  static const String CASHIER_PAGE = "/cashier";
  static const String CART_PAGE = "/cart";
  static const String PAY_PAGE = "/pay";
  static const String SETTING_PAGE = "/setting";
  static const String TRADE_PAGE = "/trade";
  static const String SYS_INIT_PAGE = "/sysinit";
  static const String TABLE_PAGE = "/table";
  static const String TABLE_CASHIER_PAGE = "/table/cashier";
  static const String TABLE_CART_PAGE = "/table/cart";
  static const String TABLE_PAY_PAGE = "/table/pay";

  static const String TABLE_ASSISTANT_PAGE = "/table/assistant";
  static const String TABLE_ASSISTANT_DISH_PAGE = "/table/assistant/dish";
  static const String TABLE_ASSISTANT_CART_PAGE = "/table/assistant/cart";
  static const String TABLE_ASSISTANT_PAY_PAGE = "/table/assistant/pay";

  static const String SHIFT_PAGE = "/shift";

  static const String EMPTY_PAGE = "/empty";
  @override
  void initRouter(FluroRouter router) {
    router.define(REGISTER_PAGE, handler: Handler(handlerFunc: (_, params) => RegisterPage()));
    router.define(LOGIN_PAGE, handler: Handler(handlerFunc: (_, params) => LoginPage()));
    router.define(DOWNLOAD_PAGE, handler: Handler(handlerFunc: (_, params) => DownloadPage()));
    router.define(HOME_PAGE, handler: Handler(handlerFunc: (_, params) => HomePage()));
    router.define(CASHIER_PAGE, handler: Handler(handlerFunc: (_, params) => CashierPage(parameters: params)));
    router.define(CART_PAGE, handler: Handler(handlerFunc: (_, params) => CartPage()));
    router.define(PAY_PAGE, handler: Handler(handlerFunc: (_, params) => PayPage()));
    router.define(SETTING_PAGE, handler: Handler(handlerFunc: (_, params) => SettingPage()));
    router.define(TRADE_PAGE, handler: Handler(handlerFunc: (_, params) => TradePage()));
    router.define(SYS_INIT_PAGE, handler: Handler(handlerFunc: (_, params) => SysInitPage()));
    router.define(TABLE_PAGE, handler: Handler(handlerFunc: (_, params) => TablePage()));
    router.define(TABLE_CASHIER_PAGE, handler: Handler(handlerFunc: (_, params) => TableCashierPage(parameters: params)));
    router.define(TABLE_CART_PAGE, handler: Handler(handlerFunc: (_, params) => TableCartPage(parameters: params)));
    router.define(TABLE_PAY_PAGE, handler: Handler(handlerFunc: (_, params) => TablePayPage(parameters: params)));

    router.define(TABLE_ASSISTANT_PAGE, handler: Handler(handlerFunc: (_, params) => AssistantPage(parameters: params)));
    router.define(TABLE_ASSISTANT_DISH_PAGE, handler: Handler(handlerFunc: (_, params) => AssistantDishPage(parameters: params)));
    router.define(TABLE_ASSISTANT_CART_PAGE, handler: Handler(handlerFunc: (_, params) => AssistantCartPage(parameters: params)));
    router.define(TABLE_ASSISTANT_PAY_PAGE, handler: Handler(handlerFunc: (_, params) => AssistantPayPage(parameters: params)));

    router.define(SHIFT_PAGE, handler: Handler(handlerFunc: (_, params) => ShiftPage(parameters: params)));

    router.define(EMPTY_PAGE, handler: Handler(handlerFunc: (_, params) => EmptyPage()));
  }
}

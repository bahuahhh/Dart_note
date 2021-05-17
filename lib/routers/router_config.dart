import 'package:fluro/fluro.dart';

import 'router_manager.dart';

abstract class RouterProvider {
  void initRouter(FluroRouter router);
}

class RouterConfig {
  static List<RouterProvider> _listRouter = [];

  static void configureRouter(FluroRouter router) {
    _listRouter.clear();

    /// 各自路由由各自模块管理，统一在此添加初始化
    _listRouter.add(RouterManager());

    /// 初始化路由
    _listRouter.forEach((routerProvider) {
      routerProvider.initRouter(router);
    });
  }
}

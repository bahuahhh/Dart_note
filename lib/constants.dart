import 'dart:ui';

import 'package:estore_app/utils/screen_utils.dart';
import 'package:flutter/material.dart';

class Constants {
  ///应用标识
  static const String APP_SIGN = "estore";

  ///终端类型
  static const String TERMINAL_TYPE = "FOOD_VPOS_ANDROID";

  ///底稿设计模版的宽度
  static const double SCREEN_WIDTH = 720;

  ///底稿设计模版的高度
  static const double SCREEN_HEIGHT = 1280;

  ///Android系统默认的数据和日志路径
  static const String ANDROID_BASE_PATH = "/sdcard/estore/food";

  ///模版的基础路径
  static const String TEMPLATE_PATH = "$ANDROID_BASE_PATH/template";

  ///小票打印模版路径
  static const String TEMPLATE_PRINTER_PATH = "$TEMPLATE_PATH/printer";

  ///日志存储路径
  static const String LOGS_PATH = "$ANDROID_BASE_PATH/logs";

  ///数据库存储路径
  static const String DATABASE_PATH = "$ANDROID_BASE_PATH/data";

  ///数据库名称
  static const String DATABASE_NAME = "estore.db";

  ///图片下载基础路径
  static const String IMAGE_PATH = "$ANDROID_BASE_PATH/images";

  ///商品图片下载路径
  static const String PRODUCT_IMAGE_PATH = "$IMAGE_PATH/product";

  ///打印图片下载路径
  static const String PRINTER_IMAGE_PATH = "$IMAGE_PATH/printer";

  ///副屏图片下载路径
  static const String VICE_IMAGE_PATH = "$IMAGE_PATH/vice";

  ///临时目录
  static const String TEMP_PATH = "$ANDROID_BASE_PATH/temp";

  ///缓存目录
  static const String CACHE_PATH = "$ANDROID_BASE_PATH/cache";

  /// 分页下载数据默认每页大小
  static const int DEFAULT_PAGESIZE = 500;

  ///数据库新建用户默认值
  static const String DEFAULT_CREATE_USER = "openApi";

  ///数据库修改用户默认值
  static const String DEFAULT_MODIFY_USER = "openApi";

  ///虚拟MAC地址，对于无法获取MAC硬件地址的设备，都走虚拟地址
  static const String VIRTUAL_MAC_ADDRESS = "4C-CC-6A-5B-5B-10";

  /// 标识不需要需要校验权限
  static const String PERMISSION_CODE = "__PC__";

  /// 现金支付
  static const String PAYMODE_CODE_CASH = "01";

  /// 储值卡支付
  static const String PAYMODE_CODE_CARD = "02";

  /// 银行卡支付
  static const String PAYMODE_CODE_BANK = "03";

  /// 支付宝支付
  static const String PAYMODE_CODE_ALIPAY = "04";

  /// 微信支付
  static const String PAYMODE_CODE_WEIXIN = "05";

  /// 抹零
  static const String PAYMODE_CODE_MALING = "06";

  /// 手工抹零标识，用于区分系统抹零和手工添加抹零支付方式
  static const String PAYMODE_MALING_HAND = "手工抹零";

  /// 代金券支付
  static const String PAYMODE_CODE_COUPON = "07";

  /// 积分支付
  static const String PAYMODE_CODE_POINTPAY = "08";

  /// 银联云闪付支付
  static const String PAYMODE_CODE_YUNSHANFU = "09";

  /// <summary>
  /// 礼品卡支付
  /// </summary>
  static const String PAYMODE_CODE_GIFTCARD = "10";

  /// 微信支付宝合并扫码支付标识
  static const String PAYMODE_CODE_SCANPAY = "00";

  /// 会员卡支付RSA加密公钥
  static const String CARD_PAY_RSA_PUBLICKKEY =
      "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdzdT7P7FxC3nujLDIuIcLZ3XN09XrBQyITaTZzidGaTpanNjAS4RqEEpaEdF5g1KOq/88QaMwKFmQ1sg2DTlAzuBBsKr5QBEREJsLZZUvs92C36jUgjX2TATBSMJ5ZVAvjpxPml76/JSSLqdBU5lM+Z4hK5VNERBW+3+fIMZNkQIDAQAB";

  ///桌台状态刷新通知
  static const String REFRESH_TABLE_STATUS_CHANNEL = "refresh_table_status";

  ///控件边框适配
  static EdgeInsets paddingLTRB(double left, double top, double right, double bottom) {
    double l = ScreenUtils().setWidth(left);
    double r = ScreenUtils().setWidth(right);
    double t = ScreenUtils().setHeight(top);
    double b = ScreenUtils().setHeight(bottom);
    return EdgeInsets.fromLTRB(l, t, r, b);
  }

  ///控件边框适配
  static EdgeInsets paddingAll(double value) {
    return paddingLTRB(value, value, value, value);
  }

  ///控件边框适配
  static EdgeInsets paddingOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) {
    return paddingLTRB(left, top, right, bottom);
  }

  ///控件边框适配
  static EdgeInsets paddingSymmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  }) {
    return paddingLTRB(horizontal, vertical, horizontal, vertical);
  }

  ///控件宽度适配
  static double getAdapterWidth(double width) {
    return ScreenUtils().setWidth(width);
  }

  ///控件高度适配
  static double getAdapterHeight(double height) {
    return ScreenUtils().setHeight(height);
  }

  ///控件字体大小适配
  static double getAdapterFontSize(double fontSize) {
    return ScreenUtils().setSp(fontSize);
  }

  ///控件颜色适配
  static Color hexStringToColor(String hex) => Color(int.parse("FF${hex.substring(1)}", radix: 16));
}

class ConfigConstant {
  /// <summary>
  /// 业务分组
  /// </summary>
  static const String GROUP_BUSINESS = "business";

  /// <summary>
  /// 租户状态
  /// </summary>
  static const String TENANT_STATUS = "tenant_status";

  /// <summary>
  /// 订单序号
  /// </summary>
  static const String ORDER_NO = "order_no";

  /// <summary>
  /// 订单流水号
  /// </summary>
  static const String TRADE_NO = "trade_no";

  /// <summary>
  /// 桌台并台序号
  /// </summary>
  static const TABLE_MERGE_NO = "merge_no";

  /// <summary>
  /// 班次编号
  /// </summary>
  static const String BATCH_NO = "batch_no";

  /// <summary>
  /// 交班单号
  /// </summary>
  static const String SHIFT_NO = "shift_no";

  /// <summary>
  /// 抹零分组
  /// </summary>
  static const String MALING_GROUP = "maling";

  /// <summary>
  /// 是否抹零
  /// </summary>
  static const String MALING_ENABLE = "malingEnable";

  /// <summary>
  /// 抹零规则
  /// </summary>
  static const String MALING_RULE = "malingRule";

  /// <summary>
  /// 点菜宝-业务分组
  /// </summary>
  static const String ASSISTANT_GROUP = "assistant";

  /// <summary>
  /// 点菜宝-主机IP和端口
  /// </summary>
  static const String ASSISTANT_PARAMETER = "assistantParameter";

  /// <summary>
  /// 支付时，储值卡和扫码支付为实款实收
  /// </summary>
  static const String PAY_REAL_AMOUNT_EXCEPT_CASH = "pay_real_amount_except_cash";
}

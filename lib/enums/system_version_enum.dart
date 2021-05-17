import 'dart:convert';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/converts.dart';

class SystemVersionEnum {
  final String name;
  final String value;

  const SystemVersionEnum._(this.name, this.value);

  ///公共开发版本
  static const None = SystemVersionEnum._("未知", "None");

  ///巨为生产环境发布版
  static const JuWei = SystemVersionEnum._("通用版", "JuWei");

  factory SystemVersionEnum.fromValue(String value) {
    switch (value) {
      case "JuWei":
        {
          return SystemVersionEnum.JuWei;
        }

      default:
        {
          return SystemVersionEnum.None;
        }
    }
  }

  factory SystemVersionEnum.fromName(String name) {
    switch (name) {
      case "通用版":
        {
          return SystemVersionEnum.JuWei;
        }
      default:
        {
          return SystemVersionEnum.None;
        }
    }
  }
}

class GlobalVersion {
  ///当前的系统级的版本,默认通用版本
  String systemVersion = "JuWei";

  ///系统运行环境(dev-开发，test-测试，release-正式),默认release环境
  String activeByDefault = "release";

  ///关键信息加密方式
  String encryptionMode = "";

  ///激活码认证机制(0-巨为通用认证，1-租户+门店编码)
  String verificationMode = "0";

  ///主要业态(1-零售，2-餐饮)
  String businessType = "1";

  ///版本的描述说明
  String description = "巨为通用版本";

  ///版本名称
  String versionName = "正式版";

  ///网络请求URLS
  List<String> urls = [];

  ///版本的扩展属性
  Map<String, dynamic> extend = {};

  GlobalVersion(String jsonVersion) {
    Map<String, dynamic> map = json.decode(jsonVersion);

    if (map.containsKey("systemVersion")) {
      this.systemVersion = Convert.toStr(map["systemVersion"], "JuWei");
    }

    if (map.containsKey("activeByDefault")) {
      this.activeByDefault = Convert.toStr(map["activeByDefault"], "release");
    }

    if (map.containsKey("encryptionMode")) {
      this.encryptionMode = Convert.toStr(map["encryptionMode"], "");
    }

    ///根据系统版本获取版本详细信息
    if (map.containsKey(this.systemVersion)) {
      //获取系统版本信息
      Map<String, dynamic> versionMap = map[this.systemVersion] == null ? {} : map[this.systemVersion];
      if (versionMap.containsKey("verificationMode")) {
        this.verificationMode = Convert.toStr(versionMap["verificationMode"], "0");
      }

      if (versionMap.containsKey("businessType")) {
        this.businessType = Convert.toStr(versionMap["businessType"], "1");
      }

      if (versionMap.containsKey("description")) {
        this.description = Convert.toStr(versionMap["description"], "巨为通用版本");
      }

      //获取当前运行环境信息
      Map<String, dynamic> profilesMap = versionMap["profiles"] == null ? {} : versionMap["profiles"];
      if (profilesMap.containsKey(this.activeByDefault)) {
        Map<String, dynamic> profile = profilesMap[this.activeByDefault];

        if (profile.containsKey("description")) {
          this.versionName = Convert.toStr(profile["description"], "正式版");
        }

        if (profile.containsKey("urls")) {
          this.urls = profile["urls"] == null ? [] : List.from(profile["urls"]);
        }

        if (profile.containsKey("extend")) {
          this.extend = profile["extend"] == null ? [] : Map.from(profile["extend"]);
        }
      }

      ///
    }
  }
}

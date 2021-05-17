import 'dart:collection';
import 'dart:convert';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:estore_app/callbacks.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/open_api.dart';
import 'package:estore_app/entity/pos_version.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/upgrade/upgrade.dart';
import 'package:estore_app/utils/api_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/http_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:estore_app/widgets/space.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:r_upgrade/r_upgrade.dart';

class UpgradeDialogPage extends StatefulWidget {
  // 升级对象
  final VersionObject versionObject;

  //授权
  final OnAcceptCallback onAccept;

  //关闭
  final OnCloseCallback onClose;

  UpgradeDialogPage(this.versionObject, {this.onAccept, this.onClose});

  @override
  State<StatefulWidget> createState() => _UpgradeDialogPageState();
}

class _UpgradeDialogPageState extends State<UpgradeDialogPage> with SingleTickerProviderStateMixin {
  int upgradeId;

  //是否点击更新按钮
  bool isClickUpgrade = false;

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
      padding: Constants.paddingLTRB(20, 20, 20, 20),
      height: Constants.getAdapterHeight(500),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                child: Text(
                  "${widget.versionObject.uploadLog}",
                  style: TextStyles.getTextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
          Space(height: Constants.getAdapterHeight(10)),
          StreamBuilder(
            stream: RUpgrade.stream,
            builder: (BuildContext context, AsyncSnapshot<DownloadInfo> snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: <Widget>[
                    SizedBox(
                      child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(Constants.getAdapterWidth(20))),
                          child: Stack(
                            children: <Widget>[
                              Container(
                                width: Constants.getAdapterWidth(600),
                                height: Constants.getAdapterHeight(20),
                                decoration: BoxDecoration(color: Constants.hexStringToColor("#F0F0F0")),
                              ),
                              Positioned(
                                left: 0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(Constants.getAdapterWidth(10))),
                                  child: Container(
                                    width: snapshot.data.status == DownloadStatus.STATUS_SUCCESSFUL ? Constants.getAdapterWidth(600) : (snapshot.data.percent / 100) * Constants.getAdapterWidth(600),
                                    height: Constants.getAdapterHeight(20),
                                    decoration: BoxDecoration(color: Constants.hexStringToColor("#3385FF")),
                                  ),
                                ),
                              )
                            ],
                          )),
                    ),
                    //Space(height: Global.getAdapterHeight(10)),
                  ],
                );
              } else {
                return SizedBox(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(Constants.getAdapterWidth(10))),
                    child: Container(
                      width: Constants.getAdapterWidth(600),
                      height: Constants.getAdapterHeight(20),
                      decoration: BoxDecoration(color: Constants.hexStringToColor("#F0F0F0")),
                    ),
                  ),
                );
              }
            },
          ),
          Space(height: Constants.getAdapterHeight(20)),
          SizedBox(
            height: Constants.getAdapterHeight(80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Visibility(
                  visible: widget.versionObject != null && widget.versionObject.forceUpload == 0,
                  child: MaterialButton(
                    child: Text(
                      "忽略",
                      style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#333333")),
                    ),
                    minWidth: Constants.getAdapterWidth(160),
                    height: Constants.getAdapterHeight(70),
                    color: Constants.hexStringToColor("#CFCFCF"),
                    textColor: Constants.hexStringToColor("#FFFFFF"),
                    shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose();
                      }
                    },
                  ),
                ),
                Space(width: Constants.getAdapterWidth(20)),
                MaterialButton(
                  child: Text(
                    "立即更新",
                    style: TextStyles.getTextStyle(fontSize: 28, color: Constants.hexStringToColor("#FFFFFF")),
                  ),
                  minWidth: Constants.getAdapterWidth(180),
                  height: Constants.getAdapterHeight(70),
                  color: Constants.hexStringToColor("#7A73C7"),
                  textColor: Constants.hexStringToColor("#FFFFFF"),
                  shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(4))),
                  onPressed: () async {
                    if (!isClickUpgrade) {
                      isClickUpgrade = true;

                      this.upgradeId = await RUpgrade.upgrade(
                        "${widget.versionObject.uploadFile}",
                        fileName: "${widget.versionObject.fileName}",
                        isAutoRequestInstall: true,
                        notificationStyle: NotificationStyle.speechAndPlanTime,
                        useDownloadManager: false,
                        upgradeFlavor: RUpgradeFlavor.normal,
                      );
                    }

                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getDownloadStatus(DownloadStatus status) {
    if (status == DownloadStatus.STATUS_FAILED) {
      upgradeId = null;
      isClickUpgrade = false;
      return "下载失败";
    } else if (status == DownloadStatus.STATUS_PAUSED) {
      return "暂停下载";
    } else if (status == DownloadStatus.STATUS_PENDING) {
      return "继续下载";
    } else if (status == DownloadStatus.STATUS_RUNNING) {
      return "下载中...";
    } else if (status == DownloadStatus.STATUS_SUCCESSFUL) {
      return "下载成功";
    } else {
      upgradeId = null;
      isClickUpgrade = false;
      return "未知错误";
    }
  }

  ///构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: Constants.getAdapterHeight(100.0),
      color: Color(0xFF7A73C7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: Constants.paddingOnly(left: 15),
              alignment: Alignment.centerLeft,
              child: Text("发现新版本 V${widget.versionObject.newVersionNum}", style: TextStyles.getTextStyle(color: Constants.hexStringToColor("#FFFFFF"), fontSize: 32)),
            ),
          ),
          Visibility(
            visible: widget.versionObject != null && widget.versionObject.forceUpload == 0,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  color: Constants.hexStringToColor("#7A73C7"),
                ),
                child: InkWell(
                  onTap: () {
                    if (widget.onClose != null) {
                      widget.onClose();
                    }
                  },
                  child: Center(
                    child: Padding(
                      padding: Constants.paddingSymmetric(horizontal: 15),
                      child: Icon(CommunityMaterialIcons.close_box, color: Constants.hexStringToColor("#FFFFFF"), size: Constants.getAdapterWidth(56)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum UpgradeMethod {
  all,
  hot,
  increment,
}

class UpgradeUtils {
  // 工厂模式
  factory UpgradeUtils() => _getInstance();
  static UpgradeUtils get instance => _getInstance();
  static UpgradeUtils _instance;

  static UpgradeUtils _getInstance() {
    if (_instance == null) {
      _instance = new UpgradeUtils._internal();
    }
    return _instance;
  }

  UpgradeUtils._internal() {
    //检测新版本
    RUpgrade.setDebug(false);
  }

  Future<Tuple2<bool, VersionObject>> checkNewVersion() async {
    bool result = false;
    VersionObject versionObject;

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      String appName = packageInfo.appName;
      String packageName = packageInfo.packageName;
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;

      FLogger.info("检测新版本:$appName,$packageName,$version,$buildNumber");

      var versionObjectResult = await _getVersionObject(Constants.TERMINAL_TYPE, Constants.APP_SIGN, "1", version);
      //有新版本
      if (versionObjectResult.item1) {
        result = true;
        versionObject = versionObjectResult.item3;
      } else {
        result = false;
        versionObject = null;
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("检测新版本发生异常:" + e.toString());

      result = false;
      versionObject = null;
    }

    return Tuple2<bool, VersionObject>(result, versionObject);
  }

  Future<Tuple3<bool, String, VersionObject>> _getVersionObject(String terminalType, String appSign, String versionType, String versionNum) async {
    bool result = false;
    String msg = "";
    VersionObject versionObject;
    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "server.version.get";

      var data = {
        "tenantId": Global.instance.authc?.tenantId,
        "terminalType": terminalType,
        "posNo": Global.instance.authc?.posNo,
        "storeNo": Global.instance.authc?.storeNo,
        "appSign": appSign,
        "versionType": versionType,
        "versionNum": versionNum,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var response = await HttpUtils.instance.post(api, api.url, params: parameters);
      result = response.success;
      msg = response.msg;
      if (result) {
        var resultMap = new Map<String, dynamic>.from(response.data);

        int hasNew = 0;
        if (resultMap.containsKey("hasNew")) {
          hasNew = Convert.toInt(resultMap["hasNew"]);
        }

        if (hasNew == 1) {
          versionObject = VersionObject.fromMap(resultMap);

          result = true;
          msg = "系统发布了新版本";
        } else {
          result = false;
          msg = "目前已经是最新版本";
          versionObject = null;
        }
      } else {
        result = false;
        msg = "检测新版本失败";
        versionObject = null;
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("检测新版本异常:" + e.toString());

      result = false;
      msg = "检测新版本出错";
      versionObject = null;
    }

    FLogger.info("$result,$msg");

    return Tuple3<bool, String, VersionObject>(result, msg, versionObject);
  }

  //升级数据
  Future<bool> updateDatabase() async {
    bool isException = false;

    //应用版本
    String appVersion = "1.0.0";
    //数据库的版本
    int dbVersion = 100;
    //当前程序嵌入的数据库版本
    int currVersion = 1;
    //POS版本对象
    Version entity;
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      //应用的版本
      appVersion = packageInfo.version;
      var _array = appVersion.split(".");
      int major = Convert.toInt(_array[0]);
      int minor = Convert.toInt(_array[1]);
      int build = Convert.toInt(_array[2]);

      //当前程序嵌入的数据库版本
      currVersion = major * 100 + minor * 10 + build;

      //判断pos_version表是否存在
      String sql = "select * from sqlite_master where type='table' and name = 'pos_version';";
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);
      //pos_version表不存在
      if (lists == null || lists.length <= 0) {
        FLogger.warn("pos_version表不存在,开始创建....");

        await database.transaction((txn) async {
          var batch = txn.batch();
          batch.execute("create table pos_version(id varchar(24) primary key unique not null,appVersion varchar(16)not null,dbVersion varchar(16) not null,createUser varchar(16),createDate varchar(32),modifyUser varchar(16),modifyDate varchar(32));");
          batch.execute("insert into pos_version (id, appVersion, dbVersion, createUser, createDate, modifyUser, modifyDate) values ('1', '$major.$minor.$build', '$currVersion', 'admin', '2020-07-31 22:25:00', 'sync', '2020-07-31 22:25:00');");
          await batch.commit(noResult: false);
        });

        FLogger.warn("pos_version表创建成功....");
      }

      sql = "select * from pos_version order by modifyDate desc;";
      lists = await database.rawQuery(sql);
      if (lists != null && lists.length > 0) {
        entity = Version.fromMap(lists[0]);
      }

      if (entity == null) {
        entity = new Version();
        entity.id = IdWorkerUtils.getInstance().generate().toString();
        entity.appVersion = "1.0.0";
        entity.dbVersion = "100";
        entity.createUser = Constants.DEFAULT_CREATE_USER;
        entity.createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
        entity.modifyUser = Constants.DEFAULT_MODIFY_USER;
        entity.modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
      }

      //数据库登记的版本
      dbVersion = Convert.toInt(entity.dbVersion);

      //数据库需要升级
      if (currVersion > dbVersion) {
        //缓存升级脚本文件
        Queue<String> upgradeSqls = new Queue<String>();
        for (int i = dbVersion + 1; i <= currVersion; i++) {
          if (SqlUpgrade.upgrade.containsKey(i)) {
            FLogger.info("检测到数据库升级脚本<$i>....");
            SqlUpgrade.upgrade[i].forEach((sql) {
              if (StringUtils.isNotBlank(sql)) {
                upgradeSqls.add(sql);
              }
            });
          }
        }
        //执行升级脚本
        if (upgradeSqls.length > 0) {
          try {
            for (var sql in upgradeSqls) {
              await database.execute(sql);
            }
          } catch (e, stack) {
            FlutterChain.printError(e, stack);
            FLogger.error("数据库升级脚本执行异常:$e");
          }
        }

        //执行数据版本和应用版本更新
        if (!isException) {
          entity.id = IdWorkerUtils.getInstance().generate().toString();
          entity.appVersion = appVersion;
          entity.dbVersion = "$currVersion";

          FLogger.info("升级后版本数据:${entity.toString()}");

          await database.transaction((txn) async {
            var batch = txn.batch();

            batch.execute("delete from pos_version;");
            batch.execute(
                "insert into pos_version (id, appVersion, dbVersion, createUser, createDate, modifyUser, modifyDate) values ('${entity.id}', '${entity.appVersion}', '${entity.dbVersion}', '${entity.createUser}', '${entity.createDate}', '${entity.modifyUser}', '${entity.modifyDate}');");

            await batch.commit(noResult: false);
          });
        }
      }
    } catch (e, stack) {
      isException = true;
      FlutterChain.printError(e, stack);
      FLogger.error("升级数据库异常:" + e.toString());
    } finally {}

    return isException;
  }
}

class VersionObject {
  /// 应用标识
  String appSign = "";

  /// 应用名称
  String appName = "";

  /// 终端类型
  String terminalType = "";

  /// 版本类型
  int versionType = 1;

  /// 当前程序版本号
  String versionNum = "";

  /// 当前最新程序版本号
  String newVersionNum = "";

  /// 升级最低版本
  String minVersionNum = "";

  /// 是否有新版本(1-是,0-否)
  int hasNew = 0;

  /// <summary>
  /// 自动更新后启动的主程序文件
  String startApplication = "";

  /// <summary>
  /// 文件名
  String fileName = "";

  /// 文件大小(单位:字节)
  double length = 0;

  /// MD5校验值
  String checkNum = "";

  /// <summary>
  /// 更新日志
  String uploadLog = "";

  /// 是否强制升级(1-是,0-否)
  int forceUpload = 0;

  /// 备注说明
  String description = "";

  /// 下载地址
  String url = "";

  /// 文件路径
  String uploadFile = "";

  ///默认构造
  VersionObject();

  ///Map转实体对象
  factory VersionObject.fromMap(Map<String, dynamic> map) {
    return VersionObject()
      ..appSign = Convert.toStr(map["appSign"])
      ..appName = Convert.toStr(map["appName"])
      ..terminalType = Convert.toStr(map["terminalType"])
      ..versionType = Convert.toInt(map["versionType"])
      ..versionNum = Convert.toStr(map["versionNum"])
      ..newVersionNum = Convert.toStr(map["newVersionNum"])
      ..minVersionNum = Convert.toStr(map["minVersionNum"])
      ..hasNew = Convert.toInt(map["hasNew"])
      ..startApplication = Convert.toStr(map["startApplication"])
      ..fileName = Convert.toStr(map["fileName"])
      ..length = Convert.toDouble(map["length"])
      ..checkNum = Convert.toStr(map["checkNum"])
      ..uploadLog = Convert.toStr(map["uploadLog"])
      ..forceUpload = Convert.toInt(map["forceUpload"])
      ..description = Convert.toStr(map["description"])
      ..url = Convert.toStr(map["url"])
      ..uploadFile = Convert.toStr(map["uploadFile"]);
  }

  ///实体对象转Map
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "appSign": this.appSign,
      "appName": this.appName,
      "terminalType": this.terminalType,
      "versionType": this.versionType,
      "versionNum": this.versionNum,
      "newVersionNum": this.newVersionNum,
      "minVersionNum": this.minVersionNum,
      "hasNew": this.hasNew,
      "startApplication": this.startApplication,
      "fileName": this.fileName,
      "length": this.length,
      "checkNum": this.checkNum,
      "uploadLog": this.uploadLog,
      "forceUpload": this.forceUpload,
      "description": this.description,
      "url": this.url,
      "uploadFile": this.uploadFile,
    };
    return map;
  }

  @override
  String toString() {
    return json.encode(this.toMap());
  }
}

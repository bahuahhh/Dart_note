import 'dart:convert';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'base_entity.dart';

///Generate By ZhangYing
///CreateTime:2020-12-22 12:23:01
class LineConfig extends BaseEntity {
  ///表名称
  static final String tableName = "pos_line_config";

  ///列名称定义
  static final String columnId = "id";
  static final String columnTenantId = "tenantId";
  static final String columnPosNo = "posNo";
  static final String columnGroup = "group";
  static final String columnKeys = "keys";
  static final String columnInitValue = "initValue";
  static final String columnValues = "values";
  static final String columnDataVer = "dataVer";
  static final String columnCreateUser = "createUser";
  static final String columnCreateDate = "createDate";
  static final String columnModifyUser = "modifyUser";
  static final String columnModifyDate = "modifyDate";

  ///字段名称
  String posNo;
  String group;
  String keys;
  String initValue;
  String values;
  int dataVer;

  ///默认构造
  LineConfig();

  ///Map转实体对象
  factory LineConfig.fromMap(Map<String, dynamic> map) {
    return LineConfig()
      ..id = Convert.toStr(map[columnId], "${IdWorkerUtils.getInstance().generate()}")
      ..tenantId = Convert.toStr(map[columnTenantId], "${Global.instance.authc?.tenantId}")
      ..posNo = Convert.toStr(map[columnPosNo], "${Global.instance.authc?.posNo}")
      ..group = Convert.toStr(map[columnGroup])
      ..keys = Convert.toStr(map[columnKeys])
      ..initValue = Convert.toStr(map[columnInitValue])
      ..values = Convert.toStr(map[columnValues])
      ..dataVer = Convert.toInt(map[columnDataVer] ?? 0)
      ..createUser = Convert.toStr(map[columnCreateUser], Constants.DEFAULT_CREATE_USER)
      ..createDate = Convert.toStr(map[columnCreateDate], DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"))
      ..modifyUser = Convert.toStr(map[columnModifyUser], Constants.DEFAULT_MODIFY_USER)
      ..modifyDate = Convert.toStr(map[columnModifyDate], DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"));
  }

  ///构建空对象
  factory LineConfig.newLineConfig() {
    return LineConfig()
      ..id = "${IdWorkerUtils.getInstance().generate()}"
      ..tenantId = "${Global.instance.authc?.tenantId}"
      ..posNo = ""
      ..group = ""
      ..keys = ""
      ..initValue = ""
      ..values = ""
      ..dataVer = 0
      ..createUser = Constants.DEFAULT_CREATE_USER
      ..createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
      ..modifyUser = Constants.DEFAULT_MODIFY_USER
      ..modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
  }

  ///复制新对象
  factory LineConfig.clone(LineConfig obj) {
    return LineConfig()
      ..id = obj.id
      ..tenantId = obj.tenantId
      ..posNo = obj.posNo
      ..group = obj.group
      ..keys = obj.keys
      ..initValue = obj.initValue
      ..values = obj.values
      ..dataVer = obj.dataVer
      ..createUser = obj.createUser
      ..createDate = obj.createDate
      ..modifyUser = obj.modifyUser
      ..modifyDate = obj.modifyDate;
  }

  ///实体对象转Map
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      columnId: this.id,
      columnTenantId: this.tenantId,
      columnPosNo: this.posNo,
      columnGroup: this.group,
      columnKeys: this.keys,
      columnInitValue: this.initValue,
      columnValues: this.values,
      columnDataVer: this.dataVer,
      columnCreateUser: this.createUser,
      columnCreateDate: this.createDate,
      columnModifyUser: this.modifyUser,
      columnModifyDate: this.modifyDate,
    };
    return map;
  }

  ///Map转List对象
  static List<LineConfig> toList(List<Map<String, dynamic>> lists) {
    var result = new List<LineConfig>();
    lists.forEach((map) => result.add(LineConfig.fromMap(map)));
    return result;
  }

  @override
  String toString() {
    return json.encode(this.toMap());
  }
}

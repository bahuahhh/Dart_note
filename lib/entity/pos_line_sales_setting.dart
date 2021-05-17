import 'dart:convert';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'base_entity.dart';

///Generate By ZhangYing
///CreateTime:2020-12-22 12:23:07
class LineSalesSetting extends BaseEntity {
  ///表名称
  static final String tableName = "pos_line_sales_setting";

  ///列名称定义
  static final String columnId = "id";
  static final String columnTenantId = "tenantId";
  static final String columnSetKey = "setKey";
  static final String columnSetValue = "setValue";
  static final String columnTemplateId = "templateId";
  static final String columnTemplateNo = "templateNo";
  static final String columnCreateUser = "createUser";
  static final String columnCreateDate = "createDate";
  static final String columnModifyUser = "modifyUser";
  static final String columnModifyDate = "modifyDate";

  ///字段名称
  String setKey;
  String setValue;
  String templateId;
  String templateNo;

  ///默认构造
  LineSalesSetting();

  ///Map转实体对象
  factory LineSalesSetting.fromMap(Map<String, dynamic> map) {
    return LineSalesSetting()
      ..id = Convert.toStr(map[columnId], "${IdWorkerUtils.getInstance().generate()}")
      ..tenantId = Convert.toStr(map[columnTenantId], "${Global.instance.authc?.tenantId}")
      ..setKey = Convert.toStr(map[columnSetKey])
      ..setValue = Convert.toStr(map[columnSetValue])
      ..templateId = Convert.toStr(map[columnTemplateId])
      ..templateNo = Convert.toStr(map[columnTemplateNo])
      ..createUser = Convert.toStr(map[columnCreateUser], Constants.DEFAULT_CREATE_USER)
      ..createDate = Convert.toStr(map[columnCreateDate], DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"))
      ..modifyUser = Convert.toStr(map[columnModifyUser], Constants.DEFAULT_MODIFY_USER)
      ..modifyDate = Convert.toStr(map[columnModifyDate], DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"));
  }

  ///构建空对象
  factory LineSalesSetting.newLineSalesSetting() {
    return LineSalesSetting()
      ..id = "${IdWorkerUtils.getInstance().generate()}"
      ..tenantId = "${Global.instance.authc?.tenantId}"
      ..setKey = ""
      ..setValue = ""
      ..templateId = ""
      ..templateNo = ""
      ..createUser = Constants.DEFAULT_CREATE_USER
      ..createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
      ..modifyUser = Constants.DEFAULT_MODIFY_USER
      ..modifyDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
  }

  ///复制新对象
  factory LineSalesSetting.clone(LineSalesSetting obj) {
    return LineSalesSetting()
      ..id = obj.id
      ..tenantId = obj.tenantId
      ..setKey = obj.setKey
      ..setValue = obj.setValue
      ..templateId = obj.templateId
      ..templateNo = obj.templateNo
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
      columnSetKey: this.setKey,
      columnSetValue: this.setValue,
      columnTemplateId: this.templateId,
      columnTemplateNo: this.templateNo,
      columnCreateUser: this.createUser,
      columnCreateDate: this.createDate,
      columnModifyUser: this.modifyUser,
      columnModifyDate: this.modifyDate,
    };
    return map;
  }

  ///Map转List对象
  static List<LineSalesSetting> toList(List<Map<String, dynamic>> lists) {
    var result = new List<LineSalesSetting>();
    lists.forEach((map) => result.add(LineSalesSetting.fromMap(map)));
    return result;
  }

  @override
  String toString() {
    return json.encode(this.toMap());
  }
}

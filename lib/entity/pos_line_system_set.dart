import 'dart:convert';

import 'package:estore_app/constants.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';

import 'base_entity.dart';

///Generate By ZhangYing
///CreateTime:2020-10-18 00:18:53
class LineSystemSet extends BaseEntity {
  ///表名称
  static final String tableName = "pos_line_system_set";

  ///列名称定义
  static final String columnId = "id";
  static final String columnTenantId = "tenantId";
  static final String columnGroupName = "groupName";
  static final String columnName = "name";
  static final String columnSetKey = "setKey";
  static final String columnSetValue = "setValue";
  static final String columnMemo = "memo";
  static final String columnExt1 = "ext1";
  static final String columnExt2 = "ext2";
  static final String columnExt3 = "ext3";
  static final String columnCreateUser = "createUser";
  static final String columnCreateDate = "createDate";
  static final String columnModifyUser = "modifyUser";
  static final String columnModifyDate = "modifyDate";

  ///字段名称
  String groupName;
  String name;
  String setKey;
  String setValue;
  String memo;

  ///默认构造
  LineSystemSet();

  ///Map转实体对象
  factory LineSystemSet.fromMap(Map<String, dynamic> map) {
    return LineSystemSet()
      ..id = Convert.toStr(map[columnId], "${IdWorkerUtils.getInstance().generate()}")
      ..tenantId = Convert.toStr(map[columnTenantId], "${Global.instance.authc?.id}")
      ..groupName = Convert.toStr(map[columnGroupName])
      ..name = Convert.toStr(map[columnName])
      ..setKey = Convert.toStr(map[columnSetKey])
      ..setValue = Convert.toStr(map[columnSetValue])
      ..memo = Convert.toStr(map[columnMemo])
      ..ext1 = Convert.toStr(map[columnExt1], "")
      ..ext2 = Convert.toStr(map[columnExt2], "")
      ..ext3 = Convert.toStr(map[columnExt3], "")
      ..createUser = Convert.toStr(map[columnCreateUser], Constants.DEFAULT_CREATE_USER)
      ..createDate = Convert.toStr(map[columnCreateDate], DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"))
      ..modifyUser = Convert.toStr(map[columnModifyUser], Constants.DEFAULT_MODIFY_USER)
      ..modifyDate = Convert.toStr(map[columnModifyDate], DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"));
  }

  ///实体对象转Map
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      columnId: this.id,
      columnTenantId: this.tenantId,
      columnGroupName: this.groupName,
      columnName: this.name,
      columnSetKey: this.setKey,
      columnSetValue: this.setValue,
      columnMemo: this.memo,
      columnExt1: this.ext1,
      columnExt2: this.ext2,
      columnExt3: this.ext3,
      columnCreateUser: this.createUser,
      columnCreateDate: this.createDate,
      columnModifyUser: this.modifyUser,
      columnModifyDate: this.modifyDate,
    };
    return map;
  }

  static List<LineSystemSet> toList(List<Map<String, dynamic>> lists) {
    var result = new List<LineSystemSet>();
    lists.forEach((map) => result.add(LineSystemSet.fromMap(map)));
    return result;
  }

  @override
  String toString() {
    return json.encode(this.toMap());
  }
}

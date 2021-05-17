import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_config.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:sprintf/sprintf.dart';

class MalingBloc extends Bloc<MalingEvent, MalingState> {
  ///抹零参数逻辑处理
  MalingRepository _malingRepository;

  MalingBloc() : super(MalingState.init()) {
    this._malingRepository = new MalingRepository();
  }

  @override
  Stream<MalingState> mapEventToState(MalingEvent event) async* {
    if (event is LoadDataEvent) {
      yield* _mapLoadDataToState(event);
    } else if (event is SelectMalingConfig) {
      yield* _mapSelectMalingConfigToState(event);
    } else if (event is SaveMalingConfig) {
      yield* _mapSaveMalingConfigToState(event);
    }
  }

  //保存抹零参数
  Stream<MalingState> _mapSaveMalingConfigToState(event) async* {
    try {
      int malingEnable = event.malingRule > 0 ? 1 : 0;
      int malingRule = event.malingRule;

      ///保存抹零参数配置
      var saveResult = await this._malingRepository.saveMalingConfig(malingEnable: malingEnable, malingRule: malingRule);
      if (saveResult.item1) {
        print("参数修改成功");

        Global.instance.reloadConfig();
      }

      yield state.copyWith(
        malingEnable: malingEnable,
        malingRule: malingRule,
      );
    } catch (e, stack) {
      FLogger.error("加载抹零参数清单异常:" + e.toString());
    }
  }

  //用户选择抹零参数
  Stream<MalingState> _mapSelectMalingConfigToState(event) async* {
    try {
      int malingEnable = event.malingRule;
      int malingRule = event.malingRule;

      yield state.copyWith(
        malingEnable: malingEnable,
        malingRule: malingRule,
      );
    } catch (e, stack) {
      FLogger.error("加载抹零参数清单异常:" + e.toString());
    }
  }

  //加载抹零参数
  Stream<MalingState> _mapLoadDataToState(event) async* {
    try {
      int malingEnable = 0;
      int malingRule = 0;

      ///加载抹零参数配置
      var configs = await this._malingRepository.getMalingGroupConfig();
      if (configs != null && configs.length > 0) {
        //是否启用抹零
        Config malingEnableObj = configs.lastWhere((item) => (item.group == ConfigConstant.MALING_GROUP && item.keys == ConfigConstant.MALING_ENABLE), orElse: null);
        if (malingEnableObj != null) {
          malingEnable = Convert.toInt(malingEnableObj.values);
        }
        //抹零规则
        Config malingRuleObj = configs.lastWhere((item) => (item.group == ConfigConstant.MALING_GROUP && item.keys == ConfigConstant.MALING_RULE), orElse: null);
        if (malingRuleObj != null) {
          malingRule = Convert.toInt(malingRuleObj.values);
        }
      }

      yield state.copyWith(
        malingEnable: malingEnable,
        malingRule: malingRule,
      );
    } catch (e, stack) {
      FLogger.error("加载抹零参数清单异常:" + e.toString());
    }
  }
}

abstract class MalingEvent extends Equatable {
  const MalingEvent();
}

///加载数据
class LoadDataEvent extends MalingEvent {
  @override
  List<Object> get props => [];
}

class SelectMalingConfig extends MalingEvent {
  final int malingRule;

  SelectMalingConfig(this.malingRule);

  @override
  List<Object> get props => [malingRule];
}

class SaveMalingConfig extends MalingEvent {
  final int malingRule;

  SaveMalingConfig(this.malingRule);

  @override
  List<Object> get props => [malingRule];
}

class MalingState extends Equatable {
  //是否启用抹零功能
  final int malingEnable;
  //抹零规则
  final int malingRule;

  const MalingState({
    this.malingEnable,
    this.malingRule,
  });

  ///初始化
  factory MalingState.init() {
    return MalingState(
      malingEnable: 0,
      malingRule: 0,
    );
  }

  MalingState copyWith({
    int malingEnable,
    int malingRule,
  }) {
    return MalingState(
      malingEnable: malingEnable ?? this.malingEnable,
      malingRule: malingRule ?? this.malingRule,
    );
  }

  @override
  List<Object> get props => [this.malingEnable, this.malingRule];
}

class MalingRepository {
  ///获取系统抹零设置配置参数
  Future<List<Config>> getMalingGroupConfig() async {
    List<Config> result = <Config>[];
    try {
      String sql = sprintf("select * from pos_config where `group` = '%s';", [ConfigConstant.MALING_GROUP]);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      if (lists != null) {
        result = Config.toList(lists);
      }
    } catch (e, stack) {
      FLogger.error("获取POS功能模块发生异常:" + e.toString());
    }
    return result;
  }

  ///获取系统抹零设置配置参数
  Future<Tuple2<bool, String>> saveMalingConfig({int malingEnable = 0, int malingRule = 0}) async {
    bool result = true;
    String message = "参数更新成功";
    try {
      var queues = new Queue<String>();

      //是否启用抹零的SQL
      String template = "REPLACE INTO pos_config(id,tenantId,`group`,keys,initValue,`values`,createUser,createDate,modifyUser,modifyDate)VALUES('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s');";
      var malingEnableSql = sprintf(template, [
        IdWorkerUtils.getInstance().generate().toString(),
        Global.instance.authc.tenantId,
        ConfigConstant.MALING_GROUP,
        ConfigConstant.MALING_ENABLE,
        "0",
        malingEnable,
        Constants.DEFAULT_CREATE_USER,
        DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
        Constants.DEFAULT_MODIFY_USER,
        DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
      ]);
      queues.add(malingEnableSql);

      //启用抹零方式的SQL
      template = "REPLACE INTO pos_config(id,tenantId,`group`,keys,initValue,`values`,createUser,createDate,modifyUser,modifyDate)VALUES('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s');";
      var malingRuleSql = sprintf(template, [
        IdWorkerUtils.getInstance().generate().toString(),
        Global.instance.authc.tenantId,
        ConfigConstant.MALING_GROUP,
        ConfigConstant.MALING_RULE,
        "0",
        malingRule,
        Constants.DEFAULT_CREATE_USER,
        DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
        Constants.DEFAULT_MODIFY_USER,
        DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
      ]);
      queues.add(malingRuleSql);

      var database = await SqlUtils.instance.open();
      await database.transaction((txn) async {
        try {
          var batch = txn.batch();
          queues.forEach((obj) {
            batch.rawInsert(obj);
          });
          await batch.commit(noResult: false);
        } catch (e) {
          FLogger.error("保存抹零参数异常:" + e.toString());
        }
      });
    } catch (e, stack) {
      result = false;
      message = "参数更新异常";
      FLogger.error("获取POS功能模块发生异常:" + e.toString());
    }
    return Tuple2<bool, String>(result, message);
  }
}

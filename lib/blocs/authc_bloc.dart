import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/pos_authc.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/utils/api_utils.dart';
import 'package:estore_app/utils/device_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';

class AuthcBloc extends Bloc<AuthcEvent, AuthcState> {
  AuthcRepository _authcRepository;

  AuthcBloc() : super(AuthcState.init()) {
    this._authcRepository = new AuthcRepository();
  }

  @override
  Stream<AuthcState> mapEventToState(AuthcEvent event) async* {
    if (event is AuthcStarted) {
      yield* _mapAuthcStartedToState();
    }
  }

  Stream<AuthcState> _mapAuthcStartedToState() async* {
    try {
      //构建系统依赖的目录
      await createLocalStorageDir();

      //加载数据库参数
      await Global.instance.init();
      //初始化系统版本
      Global.instance.appVersion = await DeviceUtils.instance.getAppVersion();
      //初始化HTTP请求参数
      await OpenApiUtils.instance.init();
      //初始化网络连接状态
      Global.instance.online = await OpenApiUtils.instance.isAvailable();

      //判断硬件是否登记
      final bool isRegisted = await _authcRepository.hasRegisted();
      yield state.copyWith(
        status: isRegisted ? AuthcStatus.Registed : AuthcStatus.Unregisted,
      );
    } catch (_) {
      yield state.copyWith(
        status: AuthcStatus.Unregisted,
      );
    }
  }

  Future<void> createLocalStorageDir() async {
    //系统路径
    final appPath = Directory(Constants.ANDROID_BASE_PATH);
    if (!(await appPath.exists())) {
      appPath.create(recursive: true);
    }

    //日志文件路径
    final logPath = Directory(Constants.LOGS_PATH);
    if (!(await logPath.exists())) {
      logPath.create(recursive: true);
    }

    //数据库文件路径
    final databasePath = Directory(Constants.DATABASE_PATH);
    if (!(await databasePath.exists())) {
      databasePath.create(recursive: true);
    }

    //图片基础路径
    final imagePath = Directory(Constants.IMAGE_PATH);
    if (!(await imagePath.exists())) {
      imagePath.create(recursive: true);
    }

    //临时目录
    final tempPath = Directory(Constants.TEMP_PATH);
    if (!(await tempPath.exists())) {
      tempPath.create(recursive: true);
    }

    //缓存目录
    final cachePath = Directory(Constants.CACHE_PATH);
    if (!(await cachePath.exists())) {
      cachePath.create(recursive: true);
    }

    //副屏图片
    final viceImagePath = Directory(Constants.VICE_IMAGE_PATH);
    if (!(await viceImagePath.exists())) {
      viceImagePath.create(recursive: true);
    }

    //商品图片
    final productImagePath = Directory(Constants.PRODUCT_IMAGE_PATH);
    if (!(await productImagePath.exists())) {
      productImagePath.create(recursive: true);
    }

    //打印小票图片
    final printerImagePath = Directory(Constants.PRINTER_IMAGE_PATH);
    if (!(await printerImagePath.exists())) {
      printerImagePath.create(recursive: true);
    }
  }
}

enum AuthcStatus {
  Unknow,
  Registed,
  Unregisted,
}

class AuthcState extends Equatable {
  final AuthcStatus status;
  const AuthcState({
    this.status,
  });

  factory AuthcState.init() {
    return AuthcState(
      status: AuthcStatus.Unknow,
    );
  }

  AuthcState copyWith({
    AuthcStatus status,
  }) {
    return AuthcState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [this.status];
}

abstract class AuthcEvent extends Equatable {}

//提交，开始认证事件
class AuthcStarted extends AuthcEvent {
  @override
  List<Object> get props => [];
}

class AuthcRepository {
  ///验证硬件是否已经注册
  Future<bool> hasRegisted() async {
    bool result = false;
    try {
      //获取系统唯一ID,做为判断依据
      var macAddress = Constants.VIRTUAL_MAC_ADDRESS;
      var diskSerialNumber = await DeviceUtils.instance.getSerialId();
      FLogger.debug("本机硬件特征:MacAddress<$macAddress>,SerialId<$diskSerialNumber>");

      String sql =
          "select id,tenantId,compterName,macAddress,diskSerialNumber,cpuSerialNumber,storeId,storeNo,storeName,posId,posNo,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate,activeCode from pos_authc where diskSerialNumber='$diskSerialNumber' and macAddress = '$macAddress';";
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      if (lists.length > 0) {
        Global.instance.authc = Authc.fromMap(lists.first);
      } else {
        Global.instance.authc = null;
      }
      result = Global.instance.authc != null && (Global.instance.authc.macAddress.contains(macAddress) || Global.instance.authc.diskSerialNumber.contains(diskSerialNumber));
    } catch (e) {
      FLogger.error("检测硬件是否注册发生异常:" + e.toString());

      result = false;
    }

    return result;
  }
}

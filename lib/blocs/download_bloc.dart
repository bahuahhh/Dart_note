import 'dart:collection';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:estore_app/constants.dart';
import 'package:estore_app/entity/open_api.dart';
import 'package:estore_app/entity/open_response.dart';
import 'package:estore_app/entity/pos_advert_caption.dart';
import 'package:estore_app/entity/pos_advert_picture.dart';
import 'package:estore_app/entity/pos_base_parameter.dart';
import 'package:estore_app/entity/pos_data_version.dart';
import 'package:estore_app/entity/pos_kit_plan.dart';
import 'package:estore_app/entity/pos_kit_plan_product.dart';
import 'package:estore_app/entity/pos_make_category.dart';
import 'package:estore_app/entity/pos_make_info.dart';
import 'package:estore_app/entity/pos_pay_mode.dart';
import 'package:estore_app/entity/pos_payment_group_parameter.dart';
import 'package:estore_app/entity/pos_payment_parameter.dart';
import 'package:estore_app/entity/pos_print_img.dart';
import 'package:estore_app/entity/pos_product.dart';
import 'package:estore_app/entity/pos_product_brand.dart';
import 'package:estore_app/entity/pos_product_category.dart';
import 'package:estore_app/entity/pos_product_code.dart';
import 'package:estore_app/entity/pos_product_contact.dart';
import 'package:estore_app/entity/pos_product_make.dart';
import 'package:estore_app/entity/pos_product_plus.dart';
import 'package:estore_app/entity/pos_product_spec.dart';
import 'package:estore_app/entity/pos_product_unit.dart';
import 'package:estore_app/entity/pos_store_info.dart';
import 'package:estore_app/entity/pos_store_make.dart';
import 'package:estore_app/entity/pos_store_product.dart';
import 'package:estore_app/entity/pos_store_table.dart';
import 'package:estore_app/entity/pos_store_table_area.dart';
import 'package:estore_app/entity/pos_store_table_type.dart';
import 'package:estore_app/entity/pos_supplier.dart';
import 'package:estore_app/entity/pos_worker.dart';
import 'package:estore_app/entity/pos_worker_data.dart';
import 'package:estore_app/entity/pos_worker_module.dart';
import 'package:estore_app/entity/pos_worker_role.dart';
import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:estore_app/utils/api_utils.dart';
import 'package:estore_app/utils/converts.dart';
import 'package:estore_app/utils/date_time_utils.dart';
import 'package:estore_app/utils/enum_utils.dart';
import 'package:estore_app/utils/http_utils.dart';
import 'package:estore_app/utils/idworker_utils.dart';
import 'package:estore_app/utils/sql_utils.dart';
import 'package:estore_app/utils/stack_trace.dart';
import 'package:estore_app/utils/tuple.dart';
import 'package:sprintf/sprintf.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  DownloadRepository _downloadRepository;

  DownloadBloc() : super(DownloadState.init()) {
    this._downloadRepository = new DownloadRepository();
  }

  @override
  Stream<DownloadState> mapEventToState(DownloadEvent event) async* {
    if (event is Initial) {
      yield state.copyWith(
        status: DownloadStatus.Initial,
        message: "请选择下载方式...",
        processValue: 0.00,
      );
    } else if (event is Ready) {
      yield* _mapReadyToState(event);
    } else if (event is StartDownloading) {
      yield* _mapStartToState(event);
    }
  }

  ///处理服务端数据版本和本地数据版本，进度占10%
  Stream<DownloadState> _mapReadyToState(Ready event) async* {
    yield state.notify(message: "准备下载数据...", processValue: 0.01);
    try {
      //先清理已经缓存的下载数据
      DownloadCacheManager.instance.clearCache();

      //是否全量下载
      bool fullDownload = event.fullDownload ?? false;

      ///服务端获取的数据版本
      Tuple2<DownloadNotify, List<Map<String, dynamic>>> resp = await this._downloadRepository.httpServerDataVersionApi();
      var notify = resp.item1;

      var newVersionList = <DataVersion>[];

      ///获取服务端版本数据成功
      if (notify.success) {
        ///服务端获取到的下载清单，注意这里是全量数据
        resp.item2.forEach((map) {
          String tenantId = Convert.toStr(map["tenantId"]);
          String dataType = Convert.toStr(map["dataType"]);
          String dataVersion = Convert.toStr(map["dataVersion"]);

          String id = IdWorkerUtils.getInstance().generate().toString();

          var entity = DataVersion()
            ..id = id
            ..name = ConvertDownloadCacheName.covertByString(dataType)
            ..tenantId = tenantId
            ..dataType = dataType
            ..version = dataVersion
            ..downloadFlag = 1
            ..updateCount = 0
            ..finishFlag = 0
            ..ext1 = ""
            ..ext2 = ""
            ..ext3 = ""
            ..createUser = Constants.DEFAULT_CREATE_USER
            ..modifyUser = Constants.DEFAULT_MODIFY_USER;

          newVersionList.add(entity);
        });

        yield state.notify(message: "数据版本获取成功...", processValue: 0.03);
      } else {
        yield state.notify(message: "数据版本获取失败...", processValue: 0.03);
      }

      await Future<void>.delayed(Duration(milliseconds: 100));
      yield state.notify(message: "验证本地数据版本...", processValue: 0.1);

      ///本地存储的数据版本
      List<DataVersion> versionList = await this._downloadRepository.compareDataVersion(newVersionList, fullDownload: fullDownload);

      await Future<void>.delayed(Duration(milliseconds: 100));
      yield state.notify(message: "下载最新数据...", processValue: 0.2);

      await Future<void>.delayed(Duration(milliseconds: 100));

      yield state.start(
        newVersionList: newVersionList,
        downloadData: versionList,
      );

      this.add(StartDownloading());
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("加工下载数据清单异常:" + e.toString());
    }
  }

  ///根据下载清单更新界面
  Stream<DownloadState> _mapStartToState(event) async* {
    try {
      for (int i = 0; i < state.downloadData.length; i++) {
        var item = state.downloadData[i];
        var cacheType = EnumUtils.fromString(DownloadCacheName.values, item.dataType);

        ///获取下载清单的友好名称
        String tips = ConvertDownloadCacheName.covertByEnum(cacheType);

        switch (cacheType) {
          case DownloadCacheName.WORKER:
            {
              await _downloadWorker(tips: tips);
              yield state.notify(message: "下载$tips数据...", processValue: 0.4);

              await _downloadWorkerRole(tips: "员工角色");
              yield state.notify(message: "下载员工角色数据...", processValue: 0.5);

              await _downloadWorkerModule(tips: "员工模块权限");
              yield state.notify(message: "下载员工模块权限...", processValue: 0.5);

              await _downloadWorkerData(tips: "员工数据权限");
              yield state.notify(message: "下载员工数据权限...", processValue: 0.5);
            }
            break;
          case DownloadCacheName.PRODUCT_BRAND:
            {
              await _downloadProductBrand(tips: tips);
              yield state.notify(message: "下载$tips数据...", processValue: 0.55);
            }
            break;
          case DownloadCacheName.PRODUCT_CATEGORY:
            {
              await _downloadProductCategory(tips: tips);
              yield state.notify(message: "下载$tips数据...", processValue: 0.55);
            }
            break;
          case DownloadCacheName.PRODUCT_UNIT:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.55);
              await _downloadProductUnit(tips: tips);
            }
            break;
          case DownloadCacheName.PRODUCT:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.55);
              await _downloadProduct(tips: tips);

              yield state.notify(message: "下载商品附加码...", processValue: 0.55);
              await _downloadProductCode(tips: "商品附加码");

              yield state.notify(message: "下载商品关联信息...", processValue: 0.55);
              await _downloadProductContact(tips: "商品关联信息");

              yield state.notify(message: "下载商品规格信息...", processValue: 0.55);
              await _downloadProductSpec(tips: "商品规格信息");

              yield state.notify(message: "下载门店商品信息...", processValue: 0.55);
              await _downloadStoreProduct(tips: "门店商品信息");
            }
            break;
          case DownloadCacheName.PLUS_PRODUCT:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.55);
              await _downloadProductPlus(tips: tips);
            }
            break;
          case DownloadCacheName.SUPPLIER:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.55);
              await _downloadSupplier(tips: tips);
            }
            break;
          case DownloadCacheName.KIT_PLAN:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.60);
              await _downloadKitPlan(tips: tips);

              yield state.notify(message: "下载$tips数据...", processValue: 0.65);
              await _downloadKitPlanProduct(tips: tips);
            }
            break;
          case DownloadCacheName.BASE_PARAMETER:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.70);
              await _downloadBaseParameter(tips: tips);
            }
            break;
          case DownloadCacheName.PAYMODE:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.75);
              await _downloadPayMode(tips: tips);
            }
            break;
          case DownloadCacheName.PAY_SETTING:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.80);
              await _downloadPaymentParameter(tips: tips);

              yield state.notify(message: "下载$tips数据...", processValue: 0.65);
              await _downloadPaymentGroupParameter(tips: tips);
            }
            break;
          case DownloadCacheName.STORE_INFO:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.75);
              await _downloadStoreInfo(tips: tips);
            }
            break;
          case DownloadCacheName.VICE_SCREEN:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.85);
              await _downloadViceScreen(tips: tips);

              yield state.notify(message: "下载$tips数据...", processValue: 0.65);
              await _downloadViceScreenCaption(tips: tips);
            }
            break;
          case DownloadCacheName.PRINT_IMG:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.88);
              await _downloadPrintImg(tips: tips);
            }
            break;
          case DownloadCacheName.MAKE_INFO:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.90);
              await _downloadMakeInfo(tips: tips);

              yield state.notify(message: "下载$tips数据...", processValue: 0.89);
              await _downloadProductMake(tips: tips);

              yield state.notify(message: "下载$tips数据...", processValue: 0.91);
              await _downloadStoreMake(tips: tips);
            }
            break;
          case DownloadCacheName.MAKE_CATEGORY:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.92);
              await _downloadMakeCategory(tips: tips);
            }
            break;
          case DownloadCacheName.STORE_TABLE:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.92);
              await _downloadStoreTable(tips: tips);
            }
            break;
          case DownloadCacheName.STORE_TABLE_TYPE:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.92);
              await _downloadStoreTableType(tips: tips);
            }
            break;
          case DownloadCacheName.STORE_TABLE_AREA:
            {
              yield state.notify(message: "下载$tips数据...", processValue: 0.92);
              await _downloadStoreTableArea(tips: tips);
            }
            break;
          default:
            print(tips);
            break;
        }
      }

      var cache = DownloadCacheManager.instance.getCache();
      yield state.notify(message: "数据下载完成，共下载<${cache.length}>条...", processValue: 0.8);
      var saveResult = await this._downloadRepository.saveDownload(cache, state.newVersionList);
      if (saveResult.item1) {
        ///处理商品分类对应的商品数量
        await this._downloadRepository.processCategoryProducts();

        // yield state.notify(message: "下载商品图片...", processValue: 0.89);
        // await this._downloadRepository.downloadProductImage();
        //
        // yield state.notify(message: "下载副屏图片...", processValue: 0.91);
        // await this._downloadRepository.downloadViceImage();
        //
        // yield state.notify(message: "下载小票图片...", processValue: 0.93);
        // await this._downloadRepository.downloadPrinterImage();

        yield state.notify(message: saveResult.item2, processValue: 0.95);
        await Future<void>.delayed(Duration(milliseconds: 500));
        yield state.success();
      } else {
        ///保存出错了
        yield state.notify(message: saveResult.item2, processValue: 0.95);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("通知下载数据发生异常:" + e.toString());
    } finally {
      //下载商品图片

    }
  }

  ///下载门店员工数据
  Future<void> _downloadWorker({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadWorker(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadWorker(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载门店员工角色数据
  Future<void> _downloadWorkerRole({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadWorkerRole(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadWorkerRole(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载门店员工模块权限
  Future<void> _downloadWorkerModule({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadWorkerModule(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadWorkerModule(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载门店员工数据权限
  Future<void> _downloadWorkerData({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadWorkerData(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadWorkerData(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载商品品牌
  Future<void> _downloadProductBrand({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProductBrand(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProductBrand(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载商品分类
  Future<void> _downloadProductCategory({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProductCategory(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProductCategory(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载商品单位
  Future<void> _downloadProductUnit({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProductUnit(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProductUnit(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载商品资料
  Future<void> _downloadProduct({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProduct(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProduct(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载商品附加码
  Future<void> _downloadProductCode({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProductCode(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProductCode(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载商品关联信息
  Future<void> _downloadProductContact({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProductContact(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProductContact(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载商品规格信息
  Future<void> _downloadProductSpec({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProductSpec(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProductSpec(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载门店商品
  Future<void> _downloadStoreProduct({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadStoreProduct(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadStoreProduct(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载PLUS商品
  Future<void> _downloadProductPlus({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProductPlus(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProductPlus(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载供应商信息
  Future<void> _downloadSupplier({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadSupplier(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadSupplier(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载厨打方案
  Future<void> _downloadKitPlan({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadKitPlan(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadKitPlan(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载厨打商品
  Future<void> _downloadKitPlanProduct({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadKitPlanProduct(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadKitPlanProduct(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载辅助信息
  Future<void> _downloadBaseParameter({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadBaseParameter(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadBaseParameter(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载支付方式
  Future<void> _downloadPayMode({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadPayMode(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadPayMode(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载支付参数
  Future<void> _downloadPaymentParameter({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadPaymentParameter(tips: tips);
      if (notify.success) {
        state.addDownloadSuccess(notify.cacheName, notify);
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载充值支付参数
  Future<void> _downloadPaymentGroupParameter({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadPaymentGroupParameter(tips: tips);
      if (notify.success) {
        state.addDownloadSuccess(notify.cacheName, notify);
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载门店信息
  Future<void> _downloadStoreInfo({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadStoreInfo(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadStoreInfo(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载副屏图片信息
  Future<void> _downloadViceScreen({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadViceScreen(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadViceScreen(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载副屏字幕信息
  Future<void> _downloadViceScreenCaption({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadViceScreenCaption(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadViceScreenCaption(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载小票图片信息
  Future<void> _downloadPrintImg({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadPrintImg(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadPrintImg(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载做法信息
  Future<void> _downloadMakeInfo({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadMakeInfo(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadMakeInfo(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载做法分类信息
  Future<void> _downloadMakeCategory({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadMakeCategory(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadMakeCategory(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载门店做法信息
  Future<void> _downloadStoreMake({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadStoreMake(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadStoreMake(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载商品私有做法信息
  Future<void> _downloadProductMake({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadProductMake(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadProductMake(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载餐桌信息
  Future<void> _downloadStoreTable({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadStoreTable(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadStoreTable(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载餐桌分类信息
  Future<void> _downloadStoreTableType({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadStoreTableType(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadStoreTableType(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }

  ///下载餐桌区域信息
  Future<void> _downloadStoreTableArea({String tips = "未知"}) async {
    try {
      var notify = await this._downloadRepository.httpDownloadStoreTableArea(1, Constants.DEFAULT_PAGESIZE, tips: tips);
      if (notify.success) {
        bool isAllSuccess = true;
        DownloadNotify lastNotify;

        ///是否有分页数据
        if (notify.isPager) {
          //分页下载
          int pageNum = notify.pageNumber;
          int pageSize = notify.pageSize;
          int pageCount = notify.pageCount;

          for (int page = pageNum + 1; page < pageCount + 1; page++) {
            notify = await this._downloadRepository.httpDownloadStoreTableArea(page, pageSize, tips: tips);

            if (notify.success) {
              print(notify.message);
            } else {
              isAllSuccess = false;
              lastNotify = notify;
              break;
            }
          }
        }

        if (isAllSuccess && lastNotify == null) {
          state.addDownloadSuccess(notify.cacheName, notify);
        } else {
          state.addDownloadError(lastNotify.cacheName, lastNotify);
        }
      } else {
        state.addDownloadError(notify.cacheName, notify);
      }
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("下载$tips发生异常:" + e.toString());
    }
  }
}

abstract class DownloadEvent extends Equatable {
  const DownloadEvent();
}

///初始化
class Ready extends DownloadEvent {
  final bool fullDownload;
  const Ready({this.fullDownload});
  @override
  List<Object> get props => [this.fullDownload];
}

///准备下载数据
class Initial extends DownloadEvent {
  @override
  List<Object> get props => [];
}

///通知下载数据
class StartDownloading extends DownloadEvent {
  @override
  List<Object> get props => [];
}

class Downloading extends DownloadEvent {
  @override
  List<Object> get props => [];
}

enum DownloadStatus { None, Initial, Ready, Start, Downloading, Paused, Finished, Failure }

class DownloadState extends Equatable {
  ///当前页面的状态
  final DownloadStatus status;

  ///进度通知
  final String message;

  ///是否全量下载
  final bool fullDownload;

  ///当前进度
  final double processValue;

  ///服务端数据清单
  final List<DataVersion> newVersionList;

  ///待下载数据清单
  final List<DataVersion> downloadData;

  ///下载成功的清单
  final Map<String, DownloadNotify> downloadSuccess;

  ///下载失败的清单
  final Map<String, DownloadNotify> downloadError;

  ///默认构造
  const DownloadState({
    this.status,
    this.message,
    this.fullDownload,
    this.processValue,
    this.downloadData,
    this.newVersionList,
    this.downloadSuccess,
    this.downloadError,
  });

  ///初始化
  factory DownloadState.init() {
    return DownloadState(
      status: DownloadStatus.Initial,
      message: "",
      fullDownload: false,
      processValue: 0.0,
      newVersionList: <DataVersion>[],
      downloadData: <DataVersion>[],
      downloadSuccess: new Map<String, DownloadNotify>(),
      downloadError: new Map<String, DownloadNotify>(),
    );
  }

  DownloadState start({
    List<DataVersion> newVersionList,
    List<DataVersion> downloadData,
  }) {
    return copyWith(
      status: DownloadStatus.Start,
      newVersionList: newVersionList,
      downloadData: downloadData,
    );
  }

  DownloadState notify({
    String message,
    double processValue,
  }) {
    return copyWith(
      message: message,
      processValue: processValue,
    );
  }

  DownloadState success() {
    return copyWith(
      status: DownloadStatus.Finished,
    );
  }

  DownloadState downloading({List<DataVersion> downloadData}) {
    return copyWith(
      status: DownloadStatus.Downloading,
      downloadData: downloadData,
    );
  }

  void addDownloadError(String key, DownloadNotify notify) {
    this.downloadError[key] = notify;
  }

  void addDownloadSuccess(String key, DownloadNotify notify) {
    this.downloadSuccess[key] = notify;
  }

  DownloadState copyWith({
    DownloadStatus status,
    String message,
    bool fullDownload,
    double processValue,
    List<DataVersion> newVersionList,
    List<DataVersion> downloadData,
  }) {
    return DownloadState(
      status: status ?? this.status,
      message: message ?? this.message,
      fullDownload: fullDownload ?? this.fullDownload,
      processValue: processValue ?? this.processValue,
      newVersionList: newVersionList ?? this.newVersionList,
      downloadData: downloadData ?? this.downloadData,
      downloadSuccess: this.downloadSuccess,
      downloadError: this.downloadError,
    );
  }

  @override
  List<Object> get props => [status, message, fullDownload, processValue, newVersionList, downloadData, downloadSuccess, downloadError];
}

class DownloadNotify {
  /// 是否下载成功
  bool success;

  /// 同步操作
  DownloadCacheName operate;

  ///缓存名称
  String cacheName;

  ///同步信息
  String message;

  ///是否分页
  bool isPager;

  ///总页数
  int pageCount;

  ///当前页码
  int pageNumber;

  ///每页数量
  int pageSize;

  ///总条数
  int totalCount;

  @override
  String toString() {
    return '''DownloadNotify {
      success: $success,
      operate: $operate,
      cacheName: $cacheName,
      message: $message,
      isPager: $isPager,
      pageCount: $pageCount,
      pageNumber: $pageNumber,
      pageSize: $pageSize,
      totalCount: $totalCount,
    }''';
  }
}

enum DownloadCacheName {
  NONE,

  ///服务端数据版本
  SERVER_DATA_VERSION,

  ///操作员数据
  WORKER,
  WORKER_ERROR,
  WORKER_EXCEPTION,

  ///操作员角色
  WORKER_ROLE,
  WORKER_ROLE_ERROR,
  WORKER_ROLE_EXCEPTION,

  ///员工POS模块权限
  WORKER_POS_MODULE,
  WORKER_POS_MODULE_ERROR,
  WORKER_POS_MODULE_EXCEPTION,

  WORKER_DATA,
  WORKER_DATA_ERROR,
  WORKER_DATA_EXCEPTION,

  ///商品品牌
  PRODUCT_BRAND,
  PRODUCT_BRAND_ERROR,
  PRODUCT_BRAND_EXCEPTION,

  ///商品品类
  PRODUCT_CATEGORY,
  PRODUCT_CATEGORY_ERROR,
  PRODUCT_CATEGORY_EXCEPTION,

  ///商品单位
  PRODUCT_UNIT,
  PRODUCT_UNIT_ERROR,
  PRODUCT_UNIT_EXCEPTION,

  ///商品资料
  PRODUCT,
  PRODUCT_ERROR,
  PRODUCT_EXCEPTION,

  ///商品附加码
  PRODUCT_CODE,
  PRODUCT_CODE_ERROR,
  PRODUCT_CODE_EXCEPTION,

  ///商品关联信息表
  PRODUCT_CONTACT,
  PRODUCT_CONTACT_ERROR,
  PRODUCT_CONTACT_EXCEPTION,

  ///商品规格
  PRODUCT_SPEC,
  PRODUCT_SPEC_ERROR,
  PRODUCT_SPEC_EXCEPTION,

  ///门店商品关联
  STORE_PRODUCT,
  STORE_PRODUCT_ERROR,
  STORE_PRODUCT_EXCEPTION,

  ///PLUS商品
  PLUS_PRODUCT,
  PLUS_PRODUCT_ERROR,
  PLUS_PRODUCT_EXCEPTION,

  ///厨打方案
  KIT_PLAN,
  KIT_PLAN_ERROR,
  KIT_PLAN_EXCEPTION,

  ///厨打商品
  KIT_PLAN_PRODUCT,
  KIT_PLAN_PRODUCT_ERROR,
  KIT_PLAN_PRODUCT_EXCEPTION,

  ///供应商
  SUPPLIER,
  SUPPLIER_ERROR,
  SUPPLIER_EXCEPTION,

  ///辅助信息
  BASE_PARAMETER,
  BASE_PARAMETER_ERROR,
  BASE_PARAMETER_EXCEPTION,

  ///付款方式
  PAYMODE,
  PAYMODE_ERROR,
  PAYMODE_EXCEPTION,

  ///移动支付信息
  PAY_SETTING,
  PAY_SETTING_ERROR,
  PAY_SETTING_EXCEPTION,

  ///充值支付信息
  PAY_GROUP_SETTING,
  PAY_GROUP_SETTING_ERROR,
  PAY_GROUP_SETTING_EXCEPTION,

  ///门店信息
  STORE_INFO,
  STORE_INFO_ERROR,
  STORE_INFO_EXCEPTION,

  ///副屏图片信息
  VICE_SCREEN,
  VICE_SCREEN_ERROR,
  VICE_SCREEN_EXCEPTION,

  ///副屏字幕信息
  VICE_SCREEN_CAPTION,
  VICE_SCREEN_CAPTION_ERROR,
  VICE_SCREEN_CAPTION_EXCEPTION,

  ///小票图片
  PRINT_IMG,
  PRINT_IMG_ERROR,
  PRINT_IMG_EXCEPTION,

  //做法信息
  MAKE_INFO,
  MAKE_INFO_ERROR,
  MAKE_INFO_EXCEPTION,

  //做法分类
  MAKE_CATEGORY,
  MAKE_CATEGORY_ERROR,
  MAKE_CATEGORY_EXCEPTION,

  //门店可用做法
  STORE_MAKE,
  STORE_MAKE_ERROR,
  STORE_MAKE_EXCEPTION,

  //商品私有做法
  PRODUCT_MAKE,
  PRODUCT_MAKE_ERROR,
  PRODUCT_MAKE_EXCEPTION,

  //餐桌类型
  STORE_TABLE_TYPE,
  STORE_TABLE_TYPE_ERROR,
  STORE_TABLE_TYPE_EXCEPTION,

  //餐桌区域
  STORE_TABLE_AREA,
  STORE_TABLE_AREA_ERROR,
  STORE_TABLE_AREA_EXCEPTION,

  //餐桌
  STORE_TABLE,
  STORE_TABLE_ERROR,
  STORE_TABLE_EXCEPTION,
}

class ConvertDownloadCacheName {
  static String covertByEnum(DownloadCacheName cache) {
    return _covert(cache);
  }

  static String covertByString(String cache) {
    return _covert(EnumUtils.fromString(DownloadCacheName.values, cache));
  }

  static String _covert(DownloadCacheName cache) {
    String cacheName = "未知";
    switch (cache) {
      case DownloadCacheName.SERVER_DATA_VERSION:
        cacheName = "服务端数据版本";
        break;
      case DownloadCacheName.WORKER:
        cacheName = "门店员工";
        break;
      case DownloadCacheName.WORKER_ERROR:
        cacheName = "门店员工-错误";
        break;
      case DownloadCacheName.WORKER_EXCEPTION:
        cacheName = "门店员工-异常";
        break;
      case DownloadCacheName.WORKER_ROLE:
        cacheName = "员工角色";
        break;
      case DownloadCacheName.WORKER_ROLE_ERROR:
        cacheName = "员工角色-错误";
        break;
      case DownloadCacheName.WORKER_ROLE_EXCEPTION:
        cacheName = "员工角色-异常";
        break;
      case DownloadCacheName.WORKER_POS_MODULE:
        cacheName = "员工P模块权限";
        break;
      case DownloadCacheName.WORKER_POS_MODULE_ERROR:
        cacheName = "员工模块权限-错误";
        break;
      case DownloadCacheName.WORKER_POS_MODULE_EXCEPTION:
        cacheName = "员工模块权限-异常";
        break;
      case DownloadCacheName.WORKER_DATA:
        cacheName = "员工数据权限";
        break;
      case DownloadCacheName.WORKER_DATA_ERROR:
        cacheName = "员工数据权限-错误";
        break;
      case DownloadCacheName.WORKER_DATA_EXCEPTION:
        cacheName = "员工数据权限-异常";
        break;
      case DownloadCacheName.PRODUCT_BRAND:
        cacheName = "商品品牌";
        break;
      case DownloadCacheName.PRODUCT_BRAND_ERROR:
        cacheName = "商品品牌-错误";
        break;
      case DownloadCacheName.PRODUCT_BRAND_EXCEPTION:
        cacheName = "商品品牌-异常";
        break;
      case DownloadCacheName.PRODUCT_CATEGORY:
        cacheName = "商品分类";
        break;
      case DownloadCacheName.PRODUCT_CATEGORY_ERROR:
        cacheName = "商品分类-错误";
        break;
      case DownloadCacheName.PRODUCT_CATEGORY_EXCEPTION:
        cacheName = "商品分类-异常";
        break;
      case DownloadCacheName.PRODUCT_UNIT:
        cacheName = "商品单位";
        break;
      case DownloadCacheName.PRODUCT_UNIT_ERROR:
        cacheName = "商品单位-错误";
        break;
      case DownloadCacheName.PRODUCT_UNIT_EXCEPTION:
        cacheName = "商品单位-异常";
        break;
      case DownloadCacheName.PRODUCT:
        cacheName = "商品资料";
        break;
      case DownloadCacheName.PRODUCT_ERROR:
        cacheName = "商品资料-错误";
        break;
      case DownloadCacheName.PRODUCT_EXCEPTION:
        cacheName = "商品资料-异常";
        break;
      case DownloadCacheName.PRODUCT_CODE:
        cacheName = "商品附加码";
        break;
      case DownloadCacheName.PRODUCT_CODE_ERROR:
        cacheName = "商品附加码-错误";
        break;
      case DownloadCacheName.PRODUCT_CODE_EXCEPTION:
        cacheName = "商品附加码-异常";
        break;
      case DownloadCacheName.PRODUCT_CONTACT:
        cacheName = "商品关联信息";
        break;
      case DownloadCacheName.PRODUCT_CONTACT_ERROR:
        cacheName = "商品关联信息-错误";
        break;
      case DownloadCacheName.PRODUCT_CONTACT_EXCEPTION:
        cacheName = "商品关联信息-异常";
        break;
      case DownloadCacheName.PRODUCT_SPEC:
        cacheName = "商品规格信息";
        break;
      case DownloadCacheName.PRODUCT_SPEC_ERROR:
        cacheName = "商品规格信息-错误";
        break;
      case DownloadCacheName.PRODUCT_SPEC_EXCEPTION:
        cacheName = "商品规格信息-异常";
        break;
      case DownloadCacheName.STORE_PRODUCT:
        cacheName = "门店关联商品";
        break;
      case DownloadCacheName.STORE_PRODUCT_ERROR:
        cacheName = "门店关联商品-错误";
        break;
      case DownloadCacheName.STORE_PRODUCT_EXCEPTION:
        cacheName = "门店关联商品-异常";
        break;
      case DownloadCacheName.PLUS_PRODUCT:
        cacheName = "PLUS商品";
        break;
      case DownloadCacheName.PLUS_PRODUCT_ERROR:
        cacheName = "PLUS商品-错误";
        break;
      case DownloadCacheName.PLUS_PRODUCT_EXCEPTION:
        cacheName = "PLUS商品-异常";
        break;
      case DownloadCacheName.SUPPLIER:
        cacheName = "门店供应商";
        break;
      case DownloadCacheName.SUPPLIER_ERROR:
        cacheName = "门店供应商-错误";
        break;
      case DownloadCacheName.SUPPLIER_EXCEPTION:
        cacheName = "门店供应商-异常";
        break;
      case DownloadCacheName.KIT_PLAN:
        cacheName = "厨打方案";
        break;
      case DownloadCacheName.KIT_PLAN_ERROR:
        cacheName = "厨打方案-错误";
        break;
      case DownloadCacheName.KIT_PLAN_EXCEPTION:
        cacheName = "厨打方案-异常";
        break;
      case DownloadCacheName.KIT_PLAN_PRODUCT:
        cacheName = "厨打商品";
        break;
      case DownloadCacheName.KIT_PLAN_PRODUCT_ERROR:
        cacheName = "厨打商品-错误";
        break;
      case DownloadCacheName.KIT_PLAN_PRODUCT_EXCEPTION:
        cacheName = "厨打商品-异常";
        break;
      case DownloadCacheName.BASE_PARAMETER:
        cacheName = "辅助信息";
        break;
      case DownloadCacheName.BASE_PARAMETER_ERROR:
        cacheName = "辅助信息-错误";
        break;
      case DownloadCacheName.BASE_PARAMETER_EXCEPTION:
        cacheName = "辅助信息-异常";
        break;
      case DownloadCacheName.PAYMODE:
        cacheName = "支付方式";
        break;
      case DownloadCacheName.PAYMODE_ERROR:
        cacheName = "支付方式-错误";
        break;
      case DownloadCacheName.PAYMODE_EXCEPTION:
        cacheName = "支付方式-异常";
        break;
      case DownloadCacheName.PAY_SETTING:
        cacheName = "支付参数";
        break;
      case DownloadCacheName.PAY_SETTING_ERROR:
        cacheName = "支付参数-错误";
        break;
      case DownloadCacheName.PAY_SETTING_EXCEPTION:
        cacheName = "支付参数-异常";
        break;
      case DownloadCacheName.PAY_GROUP_SETTING:
        cacheName = "充值支付参数";
        break;
      case DownloadCacheName.PAY_GROUP_SETTING_ERROR:
        cacheName = "充值支付参数-错误";
        break;
      case DownloadCacheName.PAY_GROUP_SETTING_EXCEPTION:
        cacheName = "充值支付参数-异常";
        break;
      case DownloadCacheName.STORE_INFO:
        cacheName = "门店信息";
        break;
      case DownloadCacheName.STORE_INFO_ERROR:
        cacheName = "门店信息-错误";
        break;
      case DownloadCacheName.STORE_INFO_EXCEPTION:
        cacheName = "门店信息-异常";
        break;
      case DownloadCacheName.VICE_SCREEN:
        cacheName = "副屏图片";
        break;
      case DownloadCacheName.VICE_SCREEN_ERROR:
        cacheName = "副屏图片-错误";
        break;
      case DownloadCacheName.VICE_SCREEN_EXCEPTION:
        cacheName = "副屏图片-异常";
        break;
      case DownloadCacheName.VICE_SCREEN_CAPTION:
        cacheName = "副屏字幕";
        break;
      case DownloadCacheName.VICE_SCREEN_CAPTION_ERROR:
        cacheName = "副屏字幕-错误";
        break;
      case DownloadCacheName.VICE_SCREEN_CAPTION_EXCEPTION:
        cacheName = "副屏字幕-异常";
        break;
      case DownloadCacheName.PRINT_IMG:
        cacheName = "小票图片";
        break;
      case DownloadCacheName.PRINT_IMG_ERROR:
        cacheName = "小票图片-错误";
        break;
      case DownloadCacheName.PRINT_IMG_EXCEPTION:
        cacheName = "小票图片-异常";
        break;
      case DownloadCacheName.MAKE_INFO:
        cacheName = "做法信息";
        break;
      case DownloadCacheName.MAKE_INFO_ERROR:
        cacheName = "做法信息-错误";
        break;
      case DownloadCacheName.MAKE_INFO_EXCEPTION:
        cacheName = "做法信息-异常";
        break;
      case DownloadCacheName.MAKE_CATEGORY:
        cacheName = "做法分类";
        break;
      case DownloadCacheName.MAKE_CATEGORY_ERROR:
        cacheName = "做法分类-错误";
        break;
      case DownloadCacheName.MAKE_CATEGORY_EXCEPTION:
        cacheName = "做法分类-异常";
        break;
      case DownloadCacheName.STORE_MAKE:
        cacheName = "门店做法";
        break;
      case DownloadCacheName.STORE_MAKE_ERROR:
        cacheName = "门店做法-错误";
        break;
      case DownloadCacheName.STORE_MAKE_EXCEPTION:
        cacheName = "门店做法-异常";
        break;
      case DownloadCacheName.PRODUCT_MAKE:
        cacheName = "商品做法";
        break;
      case DownloadCacheName.PRODUCT_MAKE_ERROR:
        cacheName = "商品做法-错误";
        break;
      case DownloadCacheName.PRODUCT_MAKE_EXCEPTION:
        cacheName = "商品做法-异常";
        break;
      case DownloadCacheName.STORE_TABLE_TYPE:
        cacheName = "餐桌类型";
        break;
      case DownloadCacheName.STORE_TABLE_TYPE_ERROR:
        cacheName = "餐桌类型-错误";
        break;
      case DownloadCacheName.STORE_TABLE_TYPE_EXCEPTION:
        cacheName = "餐桌类型-异常";
        break;
      case DownloadCacheName.STORE_TABLE_AREA:
        cacheName = "餐桌区域";
        break;
      case DownloadCacheName.STORE_TABLE_AREA_ERROR:
        cacheName = "餐桌区域-错误";
        break;
      case DownloadCacheName.STORE_TABLE_AREA_EXCEPTION:
        cacheName = "餐桌区域-异常";
        break;
      case DownloadCacheName.STORE_TABLE:
        cacheName = "餐桌信息";
        break;
      case DownloadCacheName.STORE_TABLE_ERROR:
        cacheName = "餐桌信息-错误";
        break;
      case DownloadCacheName.STORE_TABLE_EXCEPTION:
        cacheName = "餐桌信息-异常";
        break;
      default:
        break;
    }

    return cacheName;
  }
}

class DownloadCacheManager {
  // 工厂模式
  factory DownloadCacheManager() => _getInstance();
  static DownloadCacheManager get instance => _getInstance();
  static DownloadCacheManager _instance;

  static DownloadCacheManager _getInstance() {
    if (_instance == null) {
      _instance = new DownloadCacheManager._internal();
    }
    return _instance;
  }

  Queue<DownloadSqlCache> _cache;

  DownloadCacheManager._internal() {
    FLogger.debug("初始化DownloadCacheManager对象");
    _cache = new Queue<DownloadSqlCache>();
    _cache.clear();
  }

  void addCache(DownloadSqlCache data) {
    this._cache.add(data);
  }

  Queue<DownloadSqlCache> getCache() {
    return _cache;
  }

  void clearCache() {
    this._cache.clear();
  }
}

class DownloadSqlCache {
  String id;

  String cacheName;

  String sql;

  int priority;

  String createDate = DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");

  @override
  String toString() {
    return '''DownloadSqlCache {
      id: $id,
      cacheName: $cacheName,
      priority: $priority,
      createDate: $createDate,
      sql: $sql,
    }''';
  }
}

class DownloadRepository {
  ///加载服务端数据版本
  Future<Tuple2<DownloadNotify, List<Map<String, dynamic>>>> httpServerDataVersionApi() async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.SERVER_DATA_VERSION;

    List<Map<String, dynamic>> lists;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "server.data.version";

      var data = {
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        notify.success = true;
        lists = resp.data;
      } else {
        notify.success = false;
        notify.message = resp.msg;
        lists = null;

        FLogger.warn("下载服务端数据版本出错:<${notify.message}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.message = "下载服务端数据版本出错";
      lists = null;

      FlutterChain.printError(e, stack);
      FLogger.error("下载服务端数据版本异常:" + e.toString());
    }

    return Tuple2<DownloadNotify, List<Map<String, dynamic>>>(notify, lists);
  }

  ///获取待下载数据版本
  Future<List<DataVersion>> compareDataVersion(List<DataVersion> newVersionList, {bool fullDownload = false}) async {
    List<DataVersion> result = new List<DataVersion>();
    try {
      var database = await SqlUtils.instance.open();

      if (fullDownload) {
        await database.execute("delete from pos_data_version;");
      }

      String sql = "select id, tenantId, name, dataType, version, isDownload, updateCount, isFinished, ext1, ext2, ext3, createUser, createDate, modifyUser, modifyDate from pos_data_version;";
      List<Map<String, dynamic>> lists = await database.rawQuery(sql);

      ///本地存储的数据版本
      List<DataVersion> oldVersionList;
      if (lists != null && lists.length > 0) {
        oldVersionList = DataVersion.toList(lists);
      }
      if (oldVersionList == null) {
        oldVersionList = <DataVersion>[];
      }

      ///用来比较服务端数据和本地数据的差集
      var condition = new Map<String, String>();
      oldVersionList.forEach((obj) {
        condition[obj.dataType] = obj.version;
      });

      ///比较本地版本和服务端版本，数据类型和版本号相同，本次不需要下载
      newVersionList.removeWhere((item) => (condition.keys.contains(item.dataType) && condition.values.contains(item.version)));

      result = List<DataVersion>.from(newVersionList);
    } catch (e, stack) {
      FlutterChain.printError(e, stack);
      FLogger.error("比较数据版本发生异常:" + e.toString());
    }
    return result;
  }

  ///下载员工数据
  Future<DownloadNotify> httpDownloadWorker(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.WORKER;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "worker.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheWorker(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.WORKER_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.WORKER_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.WORKER_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存员工数据
  bool _cacheWorker(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_worker;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql =
            "insert into `pos_worker` (`id`, `tenantId`, `no`, `pwdType`, `passwd`, `name`, `mobile`, `sex`, `birthday`, `openId`, `bindingStatus`, `storeId`, `type`, `salesRate`, `job`,  `jobRate`,`giftRate`, `superId`, `discount`, `freeAmount`, `status`, `deleteFlag`, `memo`, `lastTime`, `cloudLoginFlag`, `posLoginFlag`, `dataAuthFlag`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = Worker.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no,
            entity.pwdType,
            entity.passwd,
            entity.name,
            entity.mobile,
            entity.sex,
            entity.birthday ?? "",
            entity.openId ?? "",
            entity.bindingStatus,
            entity.storeId,
            entity.type,
            entity.salesRate,
            entity.job,
            entity.jobRate,
            entity.giftRate,
            entity.superId,
            entity.discount,
            entity.freeAmount,
            entity.status,
            entity.deleteFlag,
            entity.memo ?? "",
            entity.lastTime,
            entity.cloudLoginFlag,
            entity.posLoginFlag,
            entity.dataAuthFlag,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载员工角色
  Future<DownloadNotify> httpDownloadWorkerRole(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.WORKER_ROLE;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "worker.pos.role.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheWorkerRole(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.WORKER_ROLE_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.WORKER_ROLE_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.WORKER_ROLE_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存员工数据
  bool _cacheWorkerRole(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_worker_role;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_worker_role` (`id`, `tenantId`, `userId`, `roleId`, `discount`,`freeAmount`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = WorkerRole.fromMap(map);
          entity.id = IdWorkerUtils.getInstance().generate().toString();

          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.userId,
            entity.roleId,
            entity.discount,
            entity.freeAmount,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载员工模块权限
  Future<DownloadNotify> httpDownloadWorkerModule(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.WORKER_POS_MODULE;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "worker.posmodule.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheWorkerModule(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.WORKER_POS_MODULE_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.WORKER_POS_MODULE_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.WORKER_POS_MODULE_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存员工模块数据
  bool _cacheWorkerModule(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_worker_module;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_worker_module` (`id`, `tenantId`, `userId`, `moduleNo`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = WorkerModule.fromMap(map);
          entity.id = IdWorkerUtils.getInstance().generate().toString();

          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.userId,
            entity.moduleNo,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载员工数据权限
  Future<DownloadNotify> httpDownloadWorkerData(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.WORKER_DATA;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "worker.rule.list";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheWorkerData(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.WORKER_DATA_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.WORKER_DATA_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.WORKER_DATA_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存员工数据权限
  bool _cacheWorkerData(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_worker_data;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_worker_data` (`id`,`tenantId`,`workerId`,`type`,`groupName`,`auth`,`ext1`,`ext2`,`ext3`,`createUser`,`createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = WorkerData.fromMap(map);
          entity.id = IdWorkerUtils.getInstance().generate().toString();

          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.workerId,
            entity.type,
            entity.groupName,
            entity.auth,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品品牌
  Future<DownloadNotify> httpDownloadProductBrand(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRODUCT_BRAND;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.brand.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProductBrand(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRODUCT_BRAND_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRODUCT_BRAND_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRODUCT_BRAND_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存商品品牌
  bool _cacheProductBrand(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product_brand;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_product_brand` (`id`, `tenantId`, `name`, `returnRate`, `storageType`, `storageAddress`, `orderNo`, `deleteFlag`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = ProductBrand.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.name,
            entity.returnRate,
            entity.storageType,
            entity.storageAddress ?? "",
            entity.orderNo,
            entity.deleteFlag,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品分类
  Future<DownloadNotify> httpDownloadProductCategory(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRODUCT_CATEGORY;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.category.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProductCategory(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRODUCT_CATEGORY_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRODUCT_CATEGORY_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRODUCT_CATEGORY_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存商品分类
  bool _cacheProductCategory(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product_category;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql =
            "insert into `pos_product_category` (`id`, `tenantId`, `parentId`, `name`, `code`, `path`, `categoryType`, `english`, `returnRate`, `description`, `orderNo`, `deleteFlag`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = ProductCategory.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.parentId ?? "",
            entity.name,
            entity.code,
            entity.path,
            entity.categoryType,
            entity.english ?? "",
            entity.returnRate,
            entity.description ?? "",
            entity.orderNo,
            entity.deleteFlag,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss"),
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品单位
  Future<DownloadNotify> httpDownloadProductUnit(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRODUCT_UNIT;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.unit.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProductUnit(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRODUCT_UNIT_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRODUCT_UNIT_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRODUCT_UNIT_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存商品分类
  bool _cacheProductUnit(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product_unit;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_product_unit` (`id`, `tenantId`, `no`, `name`, `deleteFlag`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = ProductUnit.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no,
            entity.name,
            entity.deleteFlag,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品资料
  Future<DownloadNotify> httpDownloadProduct(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRODUCT;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProduct(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRODUCT_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRODUCT_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRODUCT_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存商品资料
  bool _cacheProduct(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql =
            "insert into `pos_product` (`id`, `tenantId`, `categoryId`, `categoryPath`, `type`, `no`, `barCode`, `subNo`, `otherNo`, `name`, `english`, `rem`, `shortName`, `unitId`, `brandId`, `storageType`, `storageAddress`, `supplierId`, `managerType`, `purchaseControl`, `purchaserCycle`, `validDays`, `productArea`, `status`, `spNum`, `stockFlag`, `batchStockFlag`, `weightFlag`, `weightWay`, `steelyardCode`, `labelPrintFlag`, `foreDiscount`, `foreGift`, `promotionFlag`, `branchPrice`, `foreBargain`, `returnType`, `returnRate`, `pointFlag`, `pointValue`, `introduction`, `purchaseTax`, `saleTax`, `lyRate`, `allCode`, `deleteFlag`, `allowEditSup`, `quickInventoryFlag`, `posSellFlag`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s','%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s','%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s','%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', "
            "'%s', '%s','%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = Product.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.categoryId,
            entity.categoryPath,
            entity.type,
            entity.no ?? "",
            entity.barCode ?? "",
            entity.subNo ?? "",
            entity.otherNo ?? "",
            entity.name,
            entity.english ?? "",
            entity.rem ?? "",
            entity.shortName ?? "",
            entity.unitId,
            entity.brandId,
            entity.storageType,
            entity.storageAddress,
            entity.supplierId,
            entity.managerType,
            entity.purchaseControl,
            entity.purchaserCycle,
            entity.validDays,
            entity.productArea,
            entity.status,
            entity.spNum,
            entity.stockFlag,
            entity.batchStockFlag,
            entity.weightFlag,
            entity.weightWay,
            entity.steelyardCode,
            entity.labelPrintFlag,
            entity.foreDiscount,
            entity.foreGift,
            entity.promotionFlag,
            entity.branchPrice,
            entity.foreBargain,
            entity.returnType,
            entity.returnRate,
            entity.pointFlag,
            entity.pointValue,
            entity.introduction,
            entity.purchaseTax,
            entity.saleTax,
            entity.lyRate,
            entity.allCode,
            entity.deleteFlag,
            entity.allowEditSup,
            entity.quickInventoryFlag,
            entity.posSellFlag,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品附加码
  Future<DownloadNotify> httpDownloadProductCode(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRODUCT_CODE;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.code.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProductCode(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRODUCT_CODE_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRODUCT_CODE_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRODUCT_CODE_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存商品附加码
  bool _cacheProductCode(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product_code;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_product_code` (`id`, `tenantId`, `productId`, `specId`, `code`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = ProductCode.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.productId,
            entity.specId,
            entity.code,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品附加码
  Future<DownloadNotify> httpDownloadProductContact(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRODUCT_CONTACT;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.contact.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProductContact(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRODUCT_CONTACT_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRODUCT_CONTACT_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRODUCT_CONTACT_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存商品附加码
  bool _cacheProductContact(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product_contact;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_product_contact` (`id`, `tenantId`, `masterId`, `masterSpecId`, `slaveId`, `slaveSpecId`, `slaveNum`, `deleteFlag`, `ext1`, `ext2`, `ext3`, `orderNo`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = ProductContact.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.masterId,
            entity.masterSpecId,
            entity.slaveId,
            entity.slaveSpecId,
            entity.slaveNum,
            entity.deleteFlag,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.orderNo,
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品规格信息
  Future<DownloadNotify> httpDownloadProductSpec(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRODUCT_SPEC;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.spec.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProductSpec(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRODUCT_SPEC_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRODUCT_SPEC_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRODUCT_SPEC_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存商品规格
  bool _cacheProductSpec(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product_spec;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql =
            "insert into `pos_product_spec` (`id`, `tenantId`, `productId`, `specNo`, `specification`, `purPrice`, `salePrice`, `minPrice`, `vipPrice`, `vipPrice2`, `vipPrice3`,`vipPrice4`, `vipPrice5`, `postPrice`, `batchPrice`, `batchPrice2`, `batchPrice3`, `batchPrice4`, `batchPrice5`, `batchPrice6`, `batchPrice7`, `batchPrice8`, `otherPrice`,`purchaseSpec`, `status`, `storageType`, `storageAddress`, `deleteFlag`, `isDefault`, `topLimit`, `lowerLimit`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s','%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = ProductSpec.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.productId,
            entity.specNo,
            entity.specification,
            entity.purPrice,
            entity.salePrice,
            entity.minPrice,
            entity.vipPrice,
            entity.vipPrice2,
            entity.vipPrice3,
            entity.vipPrice4,
            entity.vipPrice5,
            entity.postPrice,
            entity.batchPrice,
            entity.batchPrice2,
            entity.batchPrice3,
            entity.batchPrice4,
            entity.batchPrice5,
            entity.batchPrice6,
            entity.batchPrice7,
            entity.batchPrice8,
            entity.otherPrice,
            entity.purchaseSpec,
            entity.status,
            entity.storageType,
            entity.storageAddress,
            entity.deleteFlag,
            entity.isDefault,
            entity.topLimit,
            entity.lowerLimit,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品规格信息
  Future<DownloadNotify> httpDownloadStoreProduct(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.STORE_PRODUCT;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "store.product.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheStoreProduct(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.STORE_PRODUCT_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.STORE_PRODUCT_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.STORE_PRODUCT_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存商品规格
  bool _cacheStoreProduct(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_store_product;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql =
            "insert into pos_store_product(id,tenantId,storeId,productId,specId,purPrice,salePrice,minPrice,vipPrice,vipPrice2,vipPrice3,vipPrice4,vipPrice5,postPrice,batchPrice,batchPrice2,batchPrice3,batchPrice4,batchPrice5,batchPrice6,batchPrice7,batchPrice8,otherPrice,supplierId,status,topLimit,lowerLimit,purchaseDate,lastDate,pointFlag,foreGift,foreDiscount,stockFlag,foreBargain,branchPrice,managerType,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate,mallFlag) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = StoreProduct.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.storeId,
            entity.productId,
            entity.specId,
            entity.purPrice,
            entity.salePrice,
            entity.minPrice,
            entity.vipPrice,
            entity.vipPrice2,
            entity.vipPrice3,
            entity.vipPrice4,
            entity.vipPrice5,
            entity.postPrice,
            entity.batchPrice,
            entity.batchPrice2,
            entity.batchPrice3,
            entity.batchPrice4,
            entity.batchPrice5,
            entity.batchPrice6,
            entity.batchPrice7,
            entity.batchPrice8,
            entity.otherPrice,
            entity.supplierId,
            entity.status,
            entity.topLimit,
            entity.lowerLimit,
            entity.purchaseDate,
            entity.lastDate,
            entity.pointFlag,
            entity.foreGift,
            entity.foreDiscount,
            entity.stockFlag,
            entity.foreBargain,
            entity.branchPrice,
            entity.managerType,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.modifyUser,
            entity.modifyDate,
            entity.mallFlag,
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载PLUS商品信息
  Future<DownloadNotify> httpDownloadProductPlus(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PLUS_PRODUCT;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.plus.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProductPlus(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PLUS_PRODUCT_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PLUS_PRODUCT_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PLUS_PRODUCT_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存PLUS商品
  bool _cacheProductPlus(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product_plus;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql =
            "insert into `pos_product_plus`(id,tenantId,ticketId,ticketNo,productId,productNo,productName,vipPrice,salePrice,plusDiscount,plusPrice,description,specId,specName,validStartDate,validendDate,subNo,ext1,ext2,ext3,createUser,createDate) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s','%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = ProductPlus.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.ticketId,
            entity.ticketNo,
            entity.productId,
            entity.productNo,
            entity.productName,
            entity.vipPrice,
            entity.salePrice,
            entity.plusDiscount,
            entity.plusPrice,
            entity.description,
            entity.specId,
            entity.specName,
            entity.validStartDate ?? "",
            entity.validendDate ?? "",
            entity.subNo,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载供应商信息
  Future<DownloadNotify> httpDownloadSupplier(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.SUPPLIER;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "supplier.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheSupplier(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.SUPPLIER_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.SUPPLIER_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.SUPPLIER_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存供应商
  bool _cacheSupplier(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_supplier;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql =
            "insert into `pos_supplier`(id,tenantId,`no`,name,rem,purchaseCycle,managerType,dealOrganize,defaultPrice,dealType,dealCycle,dealDate,costRate,minAmount,contacts,tel,address,fax,postcode,email,bankName,bankCardNo,taxId,companyType,frozenMoney,frozenBusiness,busStorageType,businessPic,licStorageType,licensePic,prePayAmount,orderNo,ext1,ext2,ext3,createUser,createDate) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s','%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = Supplier.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no,
            entity.name,
            entity.rem,
            entity.purchaseCycle,
            entity.managerType,
            entity.dealOrganize,
            entity.defaultPrice,
            entity.dealType,
            entity.dealCycle,
            entity.dealDate,
            entity.costRate,
            entity.minAmount,
            entity.contacts,
            entity.tel,
            entity.address,
            entity.fax,
            entity.postcode,
            entity.email,
            entity.bankName,
            entity.bankCardNo,
            entity.taxId,
            entity.companyType,
            entity.frozenMoney,
            entity.frozenBusiness,
            entity.busStorageType,
            entity.businessPic,
            entity.licStorageType,
            entity.licensePic,
            entity.prePayAmount,
            entity.orderNo,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载厨打方案
  Future<DownloadNotify> httpDownloadKitPlan(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.KIT_PLAN;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "kitplan.list";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheKitPlan(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.KIT_PLAN_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.KIT_PLAN_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.KIT_PLAN_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存厨打方案
  bool _cacheKitPlan(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_kit_plan;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_kit_plan`(id,tenantId,`no`,name,type,description,ext1,ext2,ext3,createUser,createDate) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = KitPlan.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no,
            entity.name,
            entity.type,
            entity.description,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载厨打方案商品信息
  Future<DownloadNotify> httpDownloadKitPlanProduct(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.KIT_PLAN_PRODUCT;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "kitplan.product.list";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheKitPlanProduct(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.KIT_PLAN_PRODUCT_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.KIT_PLAN_PRODUCT_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.KIT_PLAN_PRODUCT_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存厨打方案商品信息
  bool _cacheKitPlanProduct(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_kit_plan_product;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_kit_plan_product`(id,tenantId,productId,chudaFlag,chuda,chupinFlag,chupin,labelFlag,labelValue,ext1,ext2,ext3,createUser,createDate) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = KitPlanProduct.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.productId,
            entity.chudaFlag,
            entity.chuda,
            entity.chupinFlag,
            entity.chupin,
            entity.labelFlag,
            entity.labelValue,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载辅助信息
  Future<DownloadNotify> httpDownloadBaseParameter(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.BASE_PARAMETER;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "baseparameter.list";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      print("@@@@@@@@@@@@@@@@@@@@>>>>>>>>>>>>下载辅助信息:$resp");

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheBaseParameter(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.BASE_PARAMETER_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.BASE_PARAMETER_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.BASE_PARAMETER_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存辅助信息
  bool _cacheBaseParameter(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_base_parameter;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_base_parameter`(`id`, `tenantId`, `parentId`, `code`, `name`, `memo`, `orderNo`, `enabled`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = BaseParameter.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.parentId ?? "",
            entity.code,
            entity.name,
            entity.memo,
            entity.orderNo,
            entity.enabled,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载支付方式
  Future<DownloadNotify> httpDownloadPayMode(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PAYMODE;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "payMode.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
        "storeId": Global.instance.authc?.storeId,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cachePayMode(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PAYMODE_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PAYMODE_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PAYMODE_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存支付方式
  bool _cachePayMode(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_pay_mode;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into `pos_pay_mode`(`id`, `tenantId`, `no`, `name`, `shortcut`, `pointFlag`, `frontFlag`, `backFlag`, `rechargeFlag`, `plusFlag`, `faceMoney`, `paidMoney`, `incomeFlag`, `deleteFlag`, `createDate`, `createUser`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = PayMode.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no ?? "",
            entity.name,
            entity.shortcut,
            entity.pointFlag,
            entity.frontFlag,
            entity.backFlag,
            entity.rechargeFlag,
            entity.plusFlag,
            entity.faceMoney,
            entity.paidMoney,
            entity.incomeFlag,
            entity.deleteFlag,
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载支付参数
  Future<DownloadNotify> httpDownloadPaymentParameter({String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PAY_SETTING;
    notify.isPager = false;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "pay.setting.list";

      var data = {
        "storeCode": Global.instance.authc?.storeNo,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parseListResponse(resp.data);

        ///获取列表数据
        var list = respData;

        if (_cachePaymentParameter(notify.cacheName, list, tips: tips)) {
          notify.success = true;
          notify.message = "$tips下载成功...";
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PAY_SETTING_ERROR;
          notify.message = "缓存$tips发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PAY_SETTING_ERROR;
        FLogger.warn("下载<$tips>出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PAY_SETTING_EXCEPTION;
      notify.message = "下载$tips时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存支付方式
  bool _cachePaymentParameter(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知"}) {
    bool result = false;
    try {
      ///自动加入清表语句
      var obj = new DownloadSqlCache()
        ..id = IdWorkerUtils.getInstance().generate().toString()
        ..priority = 0
        ..sql = "delete from pos_payment_parameter;"
        ..cacheName = cacheName;
      DownloadCacheManager.instance.addCache(obj);

      if (list.length > 0) {
        String prefixSql = "insert into `pos_payment_parameter`(`id`, `tenantId`, `no`, `storeId`, `sign`, `pbody`, `enabled`, `certText`, `localFlag`, `createUser`, `createDate`) values ";
        String template = "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = PaymentParameter.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no ?? "",
            entity.storeId,
            entity.sign,
            entity.pbody,
            entity.enabled,
            entity.certText ?? "",
            entity.localFlag ?? 0,
            entity.createUser ?? Constants.DEFAULT_CREATE_USER,
            entity.createDate ?? DateTimeUtils.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss")
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///充值支付参数
  Future<DownloadNotify> httpDownloadPaymentGroupParameter({String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PAY_GROUP_SETTING;
    notify.isPager = false;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "pay.group.setting.list";

      var data = {
        "storeCode": Global.instance.authc?.storeNo,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parseListResponse(resp.data);

        ///获取列表数据
        var list = respData;

        if (_cachePaymentGroupParameter(notify.cacheName, list, tips: tips)) {
          notify.success = true;
          notify.message = "$tips下载成功...";
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PAY_GROUP_SETTING_ERROR;
          notify.message = "缓存$tips发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PAY_GROUP_SETTING_ERROR;
        FLogger.warn("下载<$tips>出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PAY_GROUP_SETTING_EXCEPTION;
      notify.message = "下载$tips时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存充值支付参数
  bool _cachePaymentGroupParameter(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知"}) {
    bool result = false;
    try {
      ///自动加入清表语句
      var obj = new DownloadSqlCache()
        ..id = IdWorkerUtils.getInstance().generate().toString()
        ..priority = 0
        ..sql = "delete from pos_payment_group_parameter;"
        ..cacheName = cacheName;
      DownloadCacheManager.instance.addCache(obj);

      if (list.length > 0) {
        String prefixSql = "insert into pos_payment_group_parameter(id,tenantId,groupId,groupNo,no,storeId,sign,pbody,enabled,certText,localFlag,ext1,ext2,ext3,createUser,createDate) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = PaymentGroupParameter.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.groupId,
            entity.groupNo,
            entity.no,
            entity.storeId,
            entity.sign,
            entity.pbody,
            entity.enabled ?? 1,
            entity.certText ?? "",
            entity.localFlag ?? 0,
            entity.ext1 ?? "",
            entity.ext2 ?? "",
            entity.ext3 ?? "",
            entity.createUser,
            entity.createDate
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载门店信息
  Future<DownloadNotify> httpDownloadStoreInfo(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.STORE_INFO;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "store.list";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheStoreInfo(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.STORE_INFO_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.STORE_INFO_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.STORE_INFO_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存门店信息
  bool _cacheStoreInfo(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_store_info;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql =
            "insert into pos_store_info(id,tenantId,code,name,type,upOrg,upOrgName,askOrg,askOrgName,balanceRate,postPrice,addRate,areaId,areaPath,status,contacts,tel,mobile,orderTel,printName,fax,postcode,address,email,acreage,lng,lat,deleteFlag,width,height,storageType,storageAddress,authFlag,thirdNo,creditAmount,creditAmountUsed,chargeLimit,chargeLimitUsed,defaultFlag,storePaySetting,ext1,ext2,ext3,createUser,createDate,warehouseId,warehouseNo,mallStart,mallEnd,mallBusinessFlag,MallStroeFlag,allowPurchase,groupId,groupNo  ) values ";
        String template =
            "( '%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'  ),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = StoreInfo.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.code,
            entity.name,
            entity.type,
            entity.upOrg,
            entity.upOrgName,
            entity.askOrg,
            entity.askOrgName,
            entity.balanceRate,
            entity.postPrice,
            entity.addRate,
            entity.areaId,
            entity.areaPath,
            entity.status,
            entity.contacts,
            entity.tel,
            entity.mobile,
            entity.orderTel,
            entity.printName,
            entity.fax,
            entity.postcode,
            entity.address,
            entity.email,
            entity.acreage,
            entity.lng,
            entity.lat,
            entity.deleteFlag,
            entity.width,
            entity.height,
            entity.storageType,
            entity.storageAddress,
            entity.authFlag,
            entity.thirdNo,
            entity.creditAmount,
            entity.creditAmountUsed,
            entity.chargeLimit,
            entity.chargeLimitUsed,
            entity.defaultFlag,
            entity.storePaySetting,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.warehouseId,
            entity.warehouseNo,
            entity.mallStart,
            entity.mallEnd,
            entity.mallBusinessFlag,
            entity.MallStroeFlag,
            entity.allowPurchase,
            entity.groupId,
            entity.groupNo
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载副屏图片信息
  Future<DownloadNotify> httpDownloadViceScreen(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.VICE_SCREEN;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "advert.picture.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheViceScreen(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.VICE_SCREEN_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.VICE_SCREEN_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.VICE_SCREEN_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存副屏图片信息
  bool _cacheViceScreen(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_advert_picture;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_advert_picture (id,tenantId,orderNo,width,height,name,storageType,storageAddress,ext1,ext2,ext3,createUser,createDate) values ";
        String template = "( '%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'  ),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = AdvertPicture.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.orderNo,
            entity.width,
            entity.height,
            entity.name,
            entity.storageType,
            entity.storageAddress,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载副屏字幕信息
  Future<DownloadNotify> httpDownloadViceScreenCaption(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.VICE_SCREEN_CAPTION;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "advert.caption.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheViceScreenCaption(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.VICE_SCREEN_CAPTION_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.VICE_SCREEN_CAPTION_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.VICE_SCREEN_CAPTION_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }
    return notify;
  }

  ///缓存副屏字幕信息
  bool _cacheViceScreenCaption(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_advert_caption;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_advert_caption (id,tenantId,storeId,name,content,isEnable,orderNo,isDelete,ext1,ext2,ext3,createUser,createDate) values ";
        String template = "( '%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s' ),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = AdvertCaption.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.storeId,
            entity.name,
            entity.content,
            entity.isEnable,
            entity.orderNo,
            entity.isDelete,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载小票图片信息
  Future<DownloadNotify> httpDownloadPrintImg(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRINT_IMG;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "print.image.list";

      var data = {
        "storeId": Global.instance.authc?.storeId,
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cachePrintImg(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRINT_IMG_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRINT_IMG_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRINT_IMG_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }

    return notify;
  }

  ///缓存小票图片信息
  bool _cachePrintImg(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_print_img;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_print_img(id,tenantId,storeId,storeNo,name,type,width,height,isEnable,storageType,storageAddress,isDelete,description,ext1,ext2,ext3,createUser,createDate) values ";
        String template = "( '%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s' ,'%s','%s','%s','%s','%s' ),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = PrintImg.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.storeId,
            entity.storeNo,
            entity.name,
            entity.type,
            entity.width,
            entity.height,
            entity.isEnable,
            entity.storageType,
            entity.storageAddress,
            entity.isDelete,
            entity.description,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
          ]);
          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载做法信息
  Future<DownloadNotify> httpDownloadMakeInfo(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.MAKE_INFO;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "make.info.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheMakeInfo(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.MAKE_INFO_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.MAKE_INFO_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.MAKE_INFO_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }

    return notify;
  }

  ///缓存做法信息
  bool _cacheMakeInfo(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_make_info;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_make_info(id,tenantId,no,categoryId,description,spell,addPrice,qtyFlag,orderNo,color,deleteFlag,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate,prvFlag) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = MakeInfo.fromMap(map);

          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no,
            entity.categoryId,
            entity.description,
            entity.spell,
            entity.addPrice,
            entity.qtyFlag,
            entity.orderNo,
            entity.color,
            entity.deleteFlag,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.modifyUser,
            entity.modifyDate,
            entity.prvFlag,
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载做法分类信息
  Future<DownloadNotify> httpDownloadMakeCategory(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.MAKE_CATEGORY;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "make.category.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheMakeCategory(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.MAKE_CATEGORY_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.MAKE_CATEGORY_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.MAKE_CATEGORY_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }

    return notify;
  }

  ///缓存做法分类信息
  bool _cacheMakeCategory(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_make_category;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_make_category(id,tenantId,no,name,type,isRadio,orderNo,color,deleteFlag,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = MakeCategory.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no,
            entity.name,
            entity.type,
            entity.isRadio,
            entity.orderNo,
            entity.color,
            entity.deleteFlag,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.modifyUser,
            entity.modifyDate,
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载门店可用做法
  Future<DownloadNotify> httpDownloadStoreMake(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.STORE_MAKE;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "store.make.info.lists";

      var data = {
        "storeId": Global.instance.authc?.storeId,
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;
      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);
      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheStoreMake(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.STORE_MAKE_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.STORE_MAKE_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.STORE_MAKE_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }

    return notify;
  }

  ///缓存门店可用做法
  bool _cacheStoreMake(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_store_make;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_store_make(id,tenantId,storeId,makeId,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = StoreMake.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.storeId,
            entity.makeId,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.modifyUser,
            entity.modifyDate,
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载商品私有做法
  Future<DownloadNotify> httpDownloadProductMake(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.PRODUCT_MAKE;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "product.make.info.lists";

      var data = {
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheProductMake(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.PRODUCT_MAKE_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.PRODUCT_MAKE_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.PRODUCT_MAKE_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }

    return notify;
  }

  ///缓存商品私有做法
  bool _cacheProductMake(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_product_make;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_product_make(id,tenantId,productId,makeId,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = ProductMake.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.productId,
            entity.makeId,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.modifyUser,
            entity.modifyDate,
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载餐桌信息
  Future<DownloadNotify> httpDownloadStoreTable(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.STORE_TABLE;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "storetable.lists";

      var data = {
        "storeId": Global.instance.authc?.storeId,
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheStoreTable(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.STORE_TABLE_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.STORE_TABLE_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.STORE_TABLE_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }

    return notify;
  }

  ///缓存餐桌信息
  bool _cacheStoreTable(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_store_table;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_store_table(id,tenantId,storeId,areaId,typeId,no,name,number,deleteFlag,aliasName,description,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = StoreTable.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.storeId,
            entity.areaId,
            entity.typeId,
            entity.no,
            entity.name,
            entity.number,
            entity.deleteFlag,
            entity.aliasName,
            entity.description,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.modifyUser,
            entity.modifyDate,
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载餐桌类型
  Future<DownloadNotify> httpDownloadStoreTableType(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.STORE_TABLE_TYPE;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "storetable.type.lists";

      var data = {
        "storeId": Global.instance.authc?.storeId,
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheStoreTableType(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.STORE_TABLE_TYPE_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.STORE_TABLE_TYPE_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.STORE_TABLE_TYPE_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }

    return notify;
  }

  ///缓存餐桌类型
  bool _cacheStoreTableType(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_store_table_type;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_store_table_type(id,tenantId,no,name,color,deleteFlag,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = StoreTableType.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no,
            entity.name,
            entity.color,
            entity.deleteFlag,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.modifyUser,
            entity.modifyDate,
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///下载餐桌区域
  Future<DownloadNotify> httpDownloadStoreTableArea(int pageNum, int pageSize, {String tips = "未知"}) async {
    DownloadNotify notify = new DownloadNotify();
    notify.success = false;
    notify.operate = DownloadCacheName.STORE_TABLE_AREA;
    notify.isPager = false;
    notify.pageCount = 1;
    notify.pageNumber = pageNum;

    try {
      OpenApi api = OpenApiUtils.instance.getOpenApi(ApiType.Business);
      var parameters = OpenApiUtils.instance.newParameters(api: api);
      parameters["name"] = "storetable.area.lists";

      var data = {
        "storeId": Global.instance.authc?.storeId,
        "pageNumber": pageNum,
        "pageSize": pageSize,
      };

      parameters["data"] = json.encode(data);
      List<String> ignoreParameters = new List<String>();
      var sign = OpenApiUtils.instance.sign(api, parameters, ignoreParameters);
      parameters["sign"] = sign;

      var resp = await HttpUtils.instance.post(api, api.url, params: parameters);

      if (resp.success) {
        ///缓存名称
        notify.cacheName = EnumUtils.parse(notify.operate);

        ///服务端返回的数据
        var respData = OpenResponse.parsePagerResponse(Map<String, dynamic>.from(resp.data));

        ///获取列表数据
        var list = respData.item1;

        ///pageNum从1开始
        bool isFirstPage = pageNum < 2;
        if (_cacheStoreTableArea(notify.cacheName, list, tips: tips, isFirstPager: isFirstPage)) {
          notify.pageCount = respData.item2;
          notify.pageNumber = respData.item3;
          notify.pageSize = respData.item4;
          notify.totalCount = respData.item5;
          notify.isPager = notify.pageCount > 1;
          notify.success = true;

          if (notify.pageCount > 1) {
            notify.message = "第$pageNum页$tips下载成功...";
          } else {
            notify.message = "$tips下载成功...";
          }
        } else {
          notify.success = false;
          notify.operate = DownloadCacheName.STORE_TABLE_AREA_ERROR;
          notify.message = "缓存$tips第$pageNum页发生错误";
        }
      } else {
        notify.success = false;
        notify.message = "$tips:<${resp.code}>-<{${resp.msg}>";
        notify.operate = DownloadCacheName.STORE_TABLE_AREA_ERROR;
        FLogger.warn("下载<$tips>第<$pageNum>下载出错:<${resp.msg}>");
      }
    } catch (e, stack) {
      notify.success = false;
      notify.operate = DownloadCacheName.STORE_TABLE_AREA_EXCEPTION;
      notify.message = "下载$tips第<$pageNum>页时发生异常";

      FlutterChain.printError(e, stack);
      FLogger.error(notify.message + ":" + e.toString());
    }

    return notify;
  }

  ///缓存餐桌区域
  bool _cacheStoreTableArea(String cacheName, List<Map<String, dynamic>> list, {String tips = "未知", bool isFirstPager = false}) {
    bool result = false;
    try {
      ///首页自动加入清表语句
      if (isFirstPager) {
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = "delete from pos_store_table_area;"
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }

      if (list.length > 0) {
        String prefixSql = "insert into pos_store_table_area(id,tenantId,no,name,deleteFlag,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate) values ";
        String template = "('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s'),";
        var buffer = new StringBuffer();
        buffer.write(prefixSql);
        list.forEach((map) {
          var entity = StoreTableArea.fromMap(map);
          var sql = sprintf(template, [
            entity.id,
            entity.tenantId,
            entity.no,
            entity.name,
            entity.deleteFlag,
            entity.ext1,
            entity.ext2,
            entity.ext3,
            entity.createUser,
            entity.createDate,
            entity.modifyUser,
            entity.modifyDate,
          ]);

          buffer.write(sql);
        });

        ///整理SQL语句，末尾的,修正为;
        String sqlString = buffer.toString();
        sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

        ///构建SQL缓存对象
        var obj = new DownloadSqlCache()
          ..id = IdWorkerUtils.getInstance().generate().toString()
          ..priority = 0
          ..sql = sqlString
          ..cacheName = cacheName;
        DownloadCacheManager.instance.addCache(obj);
      }
      result = true;
    } catch (e, stack) {
      result = false;
      FlutterChain.printError(e, stack);
      FLogger.error("缓存$tips发生异常:" + e.toString());
    }
    return result;
  }

  ///保存已经下载的数据
  Future<Tuple2<bool, String>> saveDownload(Queue<DownloadSqlCache> cache, List<DataVersion> newVersionList) async {
    bool result = false;
    String msg = "";

    try {
      bool hasFailed = true;
      var database = await SqlUtils.instance.open();
      await database.transaction((txn) async {
        try {
          var batch = txn.batch();
          cache.forEach((obj) {
            batch.rawInsert(obj.sql);
          });

          if (newVersionList != null && newVersionList.length > 0) {
            batch.rawDelete("delete from pos_data_version;");

            String prefixSql = "insert into pos_data_version (id,tenantId,name,dataType,`version`,isDownload,updateCount,isFinished,ext1,ext2,ext3,createUser,createDate) values ";
            String template = "( '%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s' ),";
            var buffer = new StringBuffer();
            buffer.write(prefixSql);
            newVersionList.forEach((obj) {
              var sql = sprintf(template, [
                obj.id,
                obj.tenantId,
                obj.name,
                obj.dataType,
                obj.version,
                obj.downloadFlag,
                obj.updateCount,
                obj.finishFlag,
                obj.ext1,
                obj.ext2,
                obj.ext3,
                obj.createUser,
                obj.createDate,
              ]);

              buffer.write(sql);
            });

            ///整理SQL语句，末尾的,修正为;
            String sqlString = buffer.toString();
            sqlString = sqlString.substring(0, sqlString.length - 1) + ";";

            batch.rawInsert(sqlString);
          }
          await batch.commit(noResult: false);
          hasFailed = false;
        } catch (e) {
          FLogger.error("保存下载数据异常:" + e.toString());
        }
      });
      if (hasFailed) {
        result = false;
        msg = "数据保存失败...";
      } else {
        result = true;
        msg = "数据保存成功，共<${cache.length}>条...";
      }
    } catch (e, stack) {
      result = false;
      msg = "下载数据保存出错了";

      FlutterChain.printError(e, stack);
      FLogger.error("下载数据保存异常:" + e.toString());
    } finally {
      //
    }
    return Tuple2<bool, String>(result, msg);
  }

  ///加工处理商品分类中的可销售商品数量
  Future<Tuple2<bool, String>> processCategoryProducts() async {
    bool result = false;
    String msg = "";

    try {
      String productSql = sprintf("select distinct p.* from pos_product p left join pos_store_product sp on p.id = sp.productId where p.deleteFlag = 0 and p.posSellFlag = 1 and sp.status in (1,2)", []);
      var database = await SqlUtils.instance.open();
      List<Map<String, dynamic>> productList = await database.rawQuery(productSql);

      String categorySql = "select id,tenantId,parentId,name,code,path,categoryType,english,returnRate,description,orderNo,deleteFlag,products,ext1,ext2,ext3,createUser,createDate,modifyUser,modifyDate from pos_product_category;";
      List<Map<String, dynamic>> categoryList = await database.rawQuery(categorySql);

      bool hasFailed = true;
      if (productList != null && categoryList != null) {
        await database.transaction((txn) async {
          try {
            var batch = txn.batch();

            var template = "update pos_product_category set products = '%s' where id = '%s';";

            categoryList.forEach((obj) {
              var categoryId = obj["id"].toString();

              var counts = productList
                  .where((item) {
                    var categoryPath = item["categoryPath"].toString();
                    return categoryPath.contains(categoryId);
                  })
                  .toList()
                  .length;

              var sql = sprintf(template, [counts, categoryId]);
              batch.rawInsert(sql);
            });
            await batch.commit(noResult: false);
            hasFailed = false;
          } catch (e) {
            FLogger.error("保存下载数据异常:" + e.toString());
          }
        });
      }

      if (hasFailed) {
        result = false;
        msg = "数据保存失败...";
      } else {
        result = true;
        msg = "数据保存成功...";
      }
    } catch (e, stack) {
      result = false;
      msg = "下载数据保存出错了";

      FlutterChain.printError(e, stack);
      FLogger.error("下载数据保存异常:" + e.toString());
    }
    return Tuple2<bool, String>(result, msg);
  }
}

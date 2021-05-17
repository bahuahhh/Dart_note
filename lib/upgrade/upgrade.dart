class SqlUpgrade {
  static const Map<int, List<String>> upgrade = {
    101: _upgrade_to_1_0_1,
    102: _upgrade_to_1_0_2,
    103: _upgrade_to_1_0_3,
    105: _upgrade_to_1_0_5,
    106: _upgrade_to_1_0_6,
  };

  //升级到1.0.6版本的脚本
  static const List<String> _upgrade_to_1_0_6 = [
    """
    create table if not exists pos_shiftover_ticket(id varchar(24),tenantId varchar(16),`no` varchar(32),storeId varchar(32),storeNo varchar(32),storeName varchar(500),workId varchar(32),workNo varchar(32),workName varchar(64),shiftId varchar(24),shiftNo varchar(16),shiftName varchar(32),datetimeBegin varchar(32),firstDealTime varchar(32),endDealTime varchar(32),datetimeShift varchar(32),acceptWorkerNo varchar(32),posNo varchar(16),memo varchar(128),shiftAmount decimal(24,2)default 0,imprest decimal(24,2)default 0,shiftBlindFlag int default(0),handsMoney decimal(24,4)default(0),diffMoney decimal(24,4)default(0),deviceName varchar(64),deviceMac varchar(1024),deviceIp varchar(256),uploadStatus int default 0,uploadErrors int default 0,uploadCode varchar(32),uploadMessage varchar(128),uploadTime varchar(32),serverId varchar(32),ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createDate varchar(32),createUser varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,
    """
    create table if not exists pos_shiftover_ticket_cash(id varchar(24),tenantId varchar(16),ticketId varchar(24),storeId varchar(32),storeNo varchar(32),storeName varchar(500),shiftId varchar(24),shiftNo varchar(16),shiftName varchar(32),consumeCash decimal(24,4)default 0,consumeCashRefund decimal(24,4)default 0,cardRechargeCash decimal(24,4)default 0,cardCashRefund decimal(24,4)default 0,noTransCashIn decimal(24,4)default 0,noTransCashOut decimal(24,4)default 0,timesCashRecharge decimal(24,4)default 0,imprest decimal(24,4)default 0,totalCash decimal(24,4)default 0,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createDate varchar(32),createUser varchar(32),modifyUser varchar(32),modifyDate varchar(32),plusCashRecharge decimal(24,4));
    """,
    """
    create table if not exists pos_shiftover_ticket_pay(id varchar(24),tenantId varchar(16),ticketId varchar(24),storeId varchar(32),storeNo varchar(32),storeName varchar(500),shiftId varchar(24),shiftNo varchar(16),shiftName varchar(32),businessType varchar(32),payModeNo varchar(32),payModeName varchar(64),quantity int default 0,amount decimal(24,4)default 0,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createDate varchar(32),createUser varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,
  ];

  //升级到1.0.5版本的脚本
  static const List<String> _upgrade_to_1_0_5 = [
    """
    insert into pos_urls (`id`, `tenantId`, `apiType`, `protocol`, `url`, `contextPath`, `userDefined`, `enable`, `memo`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`, `modifyUser`, `modifyDate`) VALUES ('874095336606535688', '373001', 'Meal', 'http', 'api.jwsaas.com', 'meal/api', 0, 1, '新零售', '', '', '', 'sync', '2020-09-12 10:00:00', 'sync', '2020-09-12 10:00:00');
    """,
    """
    insert into pos_urls (`id`, `tenantId`, `apiType`, `protocol`, `url`, `contextPath`, `userDefined`, `enable`, `memo`, `ext1`, `ext2`, `ext3`, `createUser`, `createDate`, `modifyUser`, `modifyDate`) VALUES ('874095336606535686', '373001', 'Transport', 'http', 'api.jwsaas.com', 'transport/api', 0, 1, '新零售', '', '', '', 'sync', '2020-08-01 09:00:00', 'sync', '2020-08-01 09:00:00');
    """,
  ];

  //升级到1.0.3版本的脚本
  static const List<String> _upgrade_to_1_0_3 = [
    ///1.0.3版本新增部分
    """
    create table if not exists pos_order_table(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,orderId varchar(24) ,tradeNo varchar(32) ,tableId varchar(24) ,tableNo varchar(16) ,tableName varchar(32) ,typeId varchar(24) ,typeNo varchar(16) ,typeName varchar(32) ,areaId varchar(24) ,areaNo varchar(16) ,areaName varchar(32) ,tableStatus int ,openTime varchar(24) ,openUser varchar(24) ,tableNumber int ,serialNo varchar(16) ,tableAction int ,people int default 1,excessFlag int ,totalAmount decimal(24,4) default(0),totalQuantity decimal(24,4) default(0),discountAmount decimal(24,4) default(0),totalRefund decimal(24,4) default(0),totalRefundAmount decimal(24,4) default(0),totalGive decimal(24,4) default(0),totalGiveAmount decimal(24,4) default(0),discountRate decimal(24,4) default(0),receivableAmount decimal(24,4) default(0),paidAmount decimal(24,4) default(0),malingAmount decimal(24,4) default(0),placeOrders int default(0),maxOrderNo int ,masterTable int ,perCapitaAmount decimal(24,4) default(0),posNo varchar(24) ,payNo varchar(32) ,finishDate varchar(32) ,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,
    """
    create table if not exists pos_order_temp(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,storeId varchar(32) ,orderId varchar(32) ,tradeNo varchar(32) ,tableNo varchar(32) ,tableName varchar(64) ,paid decimal(24,4) default(0),totalQuantity decimal(24,4) default(0),workerNo varchar(32) ,workerName varchar(64) ,posNo varchar(16) ,saleDate varchar(24) ,orderJson text ,memo varchar(256) ,createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,
    """
    alter table pos_order add column `cashierAction` int default 0;
    """,
    """
    alter table pos_order add column `callNumber` varchar(16);
    """,
    """
    alter table pos_order add column `uploadNo` varchar(32);
    """,
    """
    alter table pos_order add column `makeStatus` int default 0;
    """,
    """
    alter table pos_order add column `makeFinishDate` varchar(32);
    """,
    """
    alter table pos_order add column `takeMealDate` varchar(32);
    """,
    """
    alter table pos_order add column `pointDealStatus` int default 0;
    """,
    """
    alter table pos_order add column `totalRefundQuantity` decimal(24,4) default 0;
    """,
    """
    alter table pos_order add column `totalRefundAmount` decimal(24,4) default 0;
    """,
    """
    alter table pos_order add column `totalGiftQuantity` decimal(24,4) default 0;
    """,
    """
    alter table pos_order add column `totalGiftAmount` decimal(24,4) default 0;
    """,
    """
    alter table pos_order add column `tableId` varchar(24);
    """,
    """
    alter table pos_order_item add column `orderRowStatus` int default 0;
    """,
    """
    alter table pos_order_item add column `tableId` varchar(24);
    """,
    """
    alter table pos_order_item add column `tableNo` varchar(16);
    """,
    """
    alter table pos_order_item add column `tableName` varchar(32);
    """,
    """
    alter table pos_order_item add column `tableBatchTag` varchar(32);
    """,
    """
    alter table pos_order_item add column `rreason` varchar(128);
    """,
    """
    alter table pos_order_item_make add column `tableId` varchar(24);
    """,
    """
    alter table pos_order_item_make add column `tableNo` varchar(16);
    """,
    """
    alter table pos_order_item_make add column `tableName` varchar(32);
    """,
    """
    alter table pos_order_item_promotion add column `tableId` varchar(24);
    """,
    """
    alter table pos_order_item_promotion add column `tableNo` varchar(16);
    """,
    """
    alter table pos_order_item_promotion add column `tableName` varchar(32);
    """,
    """
    alter table pos_order add column `orderUploadSource` int default 0;
    """,
  ];

  //升级到1.0.2版本的脚本
  static const List<String> _upgrade_to_1_0_2 = [
    """
   alter table pos_order_promotion add column adjustAmount decimal(24,4) default 0;
    """,
    """
   alter table pos_order_item_promotion add column adjustAmount decimal(24,4) default 0;
    """,
    """
    alter table pos_order add column refundStatus int default 0;
    """,
  ];

  //升级到1.0.1版本的脚本
  static const List<String> _upgrade_to_1_0_1 = [
    """
    create table if not exists pos_make_category(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,no varchar(16) ,name varchar(32) ,type int default 0,isRadio int default 0,orderNo varchar(16) ,color varchar(64) ,deleteFlag int default 0,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,

    ///做法信息表
    """
    create table if not exists pos_make_info(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,no varchar(16) ,categoryId varchar(24) ,description varchar(64) ,spell varchar(64) ,addPrice decimal(24,4) default(0),qtyFlag int default 0,orderNo varchar(16) ,color varchar(64) ,deleteFlag int default 0,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32),prvFlag int default 0);
    """,

    ///门店做法表
    """
    create table if not exists pos_store_make(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,storeId varchar(24) ,makeId varchar(24) ,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,

    ///商品做法表
    """
    create table if not exists pos_product_make(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,productId varchar(24) ,makeId varchar(24) ,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,

    ///桌台分类表
    """
    create table if not exists pos_store_table_type(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,no varchar(16) ,name varchar(32) ,color varchar(16) ,deleteFlag int ,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,

    ///桌台区域表
    """
    create table if not exists pos_store_table_area(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,no varchar(16) ,name varchar(32) ,deleteFlag int ,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,

    ///桌台信息表
    """
    create table if not exists pos_store_table(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,storeId varchar(32) ,areaId varchar(32) ,typeId varchar(32) ,no varchar(16) ,name varchar(32) ,number int ,deleteFlag int ,aliasName varchar(32) ,description varchar(64) ,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,

    ///厨显方案
    """
    create table if not exists pos_kds_plan(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,no varchar(16) ,name varchar(64) ,type varchar(8) ,description varchar(128) ,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,

    ///厨显商品
    """
    create table if not exists pos_kds_plan_product(id varchar(32)  primary key not null unique,tenantId varchar(16) not null,storeId varchar(24) ,productId varchar(24) ,chuxianFlag int ,chuxian varchar(24) ,chuxianTime int ,chupinFlag int ,chupin varchar(24) ,chupinTime int ,labelFlag int ,labelValue varchar(24) ,ext1 varchar(32),ext2 varchar(32),ext3 varchar(32),createUser varchar(32),createDate varchar(32),modifyUser varchar(32),modifyDate varchar(32));
    """,

    ///门店商品表添加列
    """
    alter table pos_store_product add column mallFlag int default 0;
    """,
  ];
}

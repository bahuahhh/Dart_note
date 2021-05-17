import 'dart:convert';
import 'dart:io';

import 'package:estore_app/global.dart';
import 'package:estore_app/logger/logger.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:estore_app/utils/mqtt_notify.dart';
import 'package:dart_notification_center/dart_notification_center.dart';
import 'package:estore_app/constants.dart';

class MqttUtils {
  // 工厂模式
  factory MqttUtils() => _getInstance();
  static MqttUtils get instance => _getInstance();
  static MqttUtils _instance;

  static MqttUtils _getInstance() {
    if (_instance == null) {
      _instance = new MqttUtils._internal();
    }
    return _instance;
  }

  MqttServerClient _mqttClient;

  MqttUtils._internal() {
    String clientIdentifier = "vpos-${Platform.isAndroid ? 'android' : 'ios'}-${Global.instance.authc.tenantId}-${Global.instance.authc.storeNo}-${Global.instance.authc.posNo}";
    _mqttClient = MqttServerClient.withPort("116.62.57.54", clientIdentifier, 18830);

    _mqttClient.logging(on: false);
    _mqttClient.keepAlivePeriod = 5;
    _mqttClient.onDisconnected = onDisconnected;
    _mqttClient.onConnected = onConnected;
    _mqttClient.onSubscribed = onSubscribed;
    _mqttClient.pongCallback = pong;
    _mqttClient.autoReconnect = true;
    _mqttClient.resubscribeOnAutoReconnect = true;
    _mqttClient.onAutoReconnect = startup;
    _mqttClient.onAutoReconnected = onConnected;
  }

  Future<void> startup() async {
    try {
      await _mqttClient.connect(Global.instance.authc.posNo, Global.instance.authc.posId);
    } on Exception catch (e) {
      _mqttClient.disconnect();
    }
  }

  void onSubscribed(String topic) {
    FLogger.info('Subscription confirmed for topic $topic');
  }

  void onDisconnected() {
    FLogger.info('OnDisconnected client callback - Client disconnection');
  }

  void onConnected() {
    FLogger.info('OnConnected client callback - Client connection was sucessful');

    //POS机通知
    String posNotify = "notify/ls/${Global.instance.authc.tenantId}/${Global.instance.authc.storeNo}/${Global.instance.authc.posNo}";
    _mqttClient.unsubscribe(posNotify);
    _mqttClient.subscribe(posNotify, MqttQos.exactlyOnce);
    //门店通知
    String storeNotify = "notify/ls/${Global.instance.authc.tenantId}/${Global.instance.authc.storeNo}";
    _mqttClient.unsubscribe(storeNotify);
    _mqttClient.subscribe(storeNotify, MqttQos.exactlyOnce);
    //租户通知
    String tenantNotify = "notify/ls/${Global.instance.authc.tenantId}";
    _mqttClient.unsubscribe(tenantNotify);
    _mqttClient.subscribe(tenantNotify, MqttQos.exactlyOnce);

    ///监听服务器发来的信息
    _mqttClient.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final String topic = c[0].topic;
      final MqttPublishMessage message = c[0].payload;
      // 必须如下处理,不然会存在中文乱码
      var payload = json.decode(Utf8Decoder().convert(message.payload.message));
      FLogger.info("接收到主体<$topic>的消息:$payload");

      var mqttNotify = MqttNofity.fromJson(payload);
      String type = Uri.decodeComponent(mqttNotify.type);
      String subType = mqttNotify.subType;
      switch (type) {
        case "中餐多端同步通知":
          {
            //桌台变动通知
            if (subType == "store_table_status_change") {
              DartNotificationCenter.post(channel: Constants.REFRESH_TABLE_STATUS_CHANNEL, options: Constants.REFRESH_TABLE_STATUS_CHANNEL);
            }
          }
          break;
      }
    });

    // //消息发布
    // const pubTopic = 'topic/test';
    // final builder = MqttClientPayloadBuilder();
    // builder.addString('Hello MQTT');
    // _mqttClient.publishMessage(pubTopic, MqttQos.atLeastOnce, builder.payload);

    ///设置public监听，当我们调用 publishMessage 时，会告诉你是都发布成功
    _mqttClient.published.listen((MqttPublishMessage message) {
      print('message-----$message');
    });
  }

  /// Pong callback
  void pong() {
    //print('EXAMPLE::Ping response client callback invoked');
  }
}

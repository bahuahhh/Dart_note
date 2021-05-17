import 'package:estore_app/global.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class DevOptUtils {
  // 工厂模式
  factory DevOptUtils() => _getInstance();
  static DevOptUtils get instance => _getInstance();
  static DevOptUtils _instance;

  static DevOptUtils _getInstance() {
    if (_instance == null) {
      _instance = new DevOptUtils._internal();
    }
    return _instance;
  }

  MqttServerClient _mqttClient;

  DevOptUtils._internal() {
    String clientIdentifier = "vpos_devopt_${Global.instance.authc.tenantId}${Global.instance.authc.storeNo}${Global.instance.authc.posNo}";
    _mqttClient = MqttServerClient.withPort("47.107.170.62", clientIdentifier, 18830);

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
      print('MqttClient Exception: $e');
      _mqttClient.disconnect();
    }
  }

  void onSubscribed(String topic) {
    //print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  void onDisconnected() {
    //print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  }

  void onConnected() {
    //print('EXAMPLE::OnConnected client callback - Client connection was sucessful');
  }

  /// Pong callback
  void pong() {
    //print('EXAMPLE::Ping response client callback invoked');
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:gr2/env/env.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? _client;
  final String mqttServer = Env.mqttBrokerUrl;
  final int mqttPort = Env.mqttBrokerPort;
  static const String _cellInfoTopic = 'cell_info';

  bool _isConnecting = false;

  String _normalizeHost(String host) {
    var h = host.trim();
    if (h.startsWith('mqtt://')) h = h.substring(7);
    if (h.startsWith('mqtts://')) h = h.substring(8);
    if (h.contains('/')) h = h.split('/').first;
    if (h.contains(':')) h = h.split(':').first;
    return h;
  }

  MqttServerClient _createClient(String deviceId) {
    final clientId = 'device_${deviceId}_session';
    final host = _normalizeHost(mqttServer);

    final client = MqttServerClient.withPort(host, clientId, mqttPort);

    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;

    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 10000;
    client.setProtocolV311();

    client.logging(on: true);

    client.resubscribeOnAutoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs('phucanh', 'Pa05022004')
        .startClean();

    client.connectionMessage = connMessage;
    return client;
  }

  Future<bool> _ensureConnected(String userId) async {
    if (_client != null &&
        _client!.connectionStatus?.state == MqttConnectionState.connected) {
      return true;
    }

    if (_isConnecting) {
      print('[MQTT] Đang có tiến trình kết nối, vui lòng đợi...');
      while (_isConnecting) {
        await Future.delayed(Duration(milliseconds: 500));
      }
      return _client?.connectionStatus?.state == MqttConnectionState.connected;
    }

    _isConnecting = true;
    _client = _createClient(userId);

    try {
      print('[MQTT] Đang thiết lập kết nối duy nhất cho User: $userId...');
      await _client!.connect();
    } catch (e) {
      print('[MQTT] Lỗi kết nối: $e');
      _client?.disconnect();
      _client = null;
    } finally {
      _isConnecting = false;
    }

    return _client?.connectionStatus?.state == MqttConnectionState.connected;
  }

  Future<bool> publishCellInfo(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final isConnected = await _ensureConnected(deviceId);

    if (!isConnected) {
      print('[MQTT] Lỗi: Không thể kết nối tới Broker');
      return false;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(data));

    try {
      _client!.publishMessage(
        _cellInfoTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      return true;
    } catch (e) {
      print('[MQTT] Lỗi gửi tin: $e');
      return false;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
    _isConnecting = false;
    print('[MQTT] Đã chủ động đóng session');
  }
}

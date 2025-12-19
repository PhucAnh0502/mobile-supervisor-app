import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Bắt buộc để sử dụng SecurityContext
import 'package:gr2/env/env.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? _client;
  final String mqttServer = Env.mqttBrokerUrl;
  final int mqttPort = Env.mqttBrokerPort;
  static const String _cellInfoTopic = 'cell_info';

  // Hàm chuẩn hóa Host
  String _normalizeHost(String host) {
    var h = host.trim();
    if (h.startsWith('mqtt://')) h = h.substring(7);
    if (h.startsWith('mqtts://')) h = h.substring(8);
    if (h.contains('/')) h = h.split('/').first;
    if (h.contains(':')) h = h.split(':').first;
    return h;
  }

  MqttServerClient _createClient() {
    final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    final host = _normalizeHost(mqttServer);

    final client = MqttServerClient.withPort(host, clientId, mqttPort);

    client.secure = true;
    client.securityContext = SecurityContext.defaultContext; 
    
    client.keepAlivePeriod = 30;
    client.connectTimeoutPeriod = 15000; 
    client.setProtocolV311();
    
    client.logging(on: true); 

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs('phucanh', 'Pa05022004') 
        .startClean();

    client.connectionMessage = connMessage;

    client.onConnected = () => print('[MQTT] Kết nối thành công tới $host');
    client.onDisconnected = () => print('[MQTT] Đã ngắt kết nối');
    client.onSubscribed = (String topic) => print('[MQTT] Đã sub topic: $topic');
    
    return client;
  }

  Future<bool> _ensureConnected() async {
    if (_client != null && _client!.connectionStatus?.state == MqttConnectionState.connected) {
      return true;
    }

    if (_client != null && _client!.connectionStatus?.state == MqttConnectionState.connecting) {
      print('[MQTT] Đang đợi kết nối hiện tại...');
      await Future.delayed(Duration(milliseconds: 500));
      return _client!.connectionStatus?.state == MqttConnectionState.connected;
    }

    _client = _createClient();

    try {
      print('[MQTT] Bắt đầu kết nối tới Broker...');
      await _client!.connect();
      
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        return true;
      } else {
        print('[MQTT] Kết nối thất bại: ${_client!.connectionStatus}');
        _client!.disconnect();
        _client = null;
        return false;
      }
    } catch (e) {
      print('[MQTT] Lỗi Exception khi kết nối: $e');
      _client?.disconnect();
      _client = null;
      return false;
    }
  }

  Future<bool> publishCellInfo(Map<String, dynamic> data) async {
    final isConnected = await _ensureConnected();
    if (!isConnected) {
      print('[MQTT] Lỗi: Không thể gửi dữ liệu vì không có kết nối');
      return false;
    }

    final builder = MqttClientPayloadBuilder();
    final payload = jsonEncode(data);
    builder.addString(payload);

    try {
      _client!.publishMessage(_cellInfoTopic, MqttQos.atLeastOnce, builder.payload!);
      print('[MQTT] Đã bắn CellId: $payload');
      return true;
    } catch (e) {
      print('[MQTT] Lỗi khi bắn dữ liệu: $e');
      return false;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
    print('[MQTT] Chủ động ngắt kết nối');
  }
}
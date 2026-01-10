import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:gr2/services/data_buffer.dart';

Future<void> initializeBackgroundService() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStarted,
      autoStart: true,
      isForegroundMode: true,
      
      foregroundServiceTypes: [
        AndroidForegroundType.dataSync,
        AndroidForegroundType.location,
      ],
      
      notificationChannelId: 'gr2_bg_channel',
      initialNotificationTitle: 'GR2 Service',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onServiceStarted,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onServiceStarted(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final DeviceInfoService deviceService = DeviceInfoService();
  final DataBuffer buffer = DataBuffer();

  // Runtime configurable settings
  // Defaults: collect frequently, send every 10s via API
  int fetchIntervalSeconds = 3;
  int sendIntervalSeconds = 10;
  bool useMqttMode = false; // false => API, true => MQTT

  Timer? fetchTimer;
  Timer? sendTimer;
  bool _isCollecting = false;
  bool _isSending = false;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    fetchTimer?.cancel();
    sendTimer?.cancel();
    service.stopSelf();
  });

  void _startTimers() {
    // Cancel existing timers before restarting
    fetchTimer?.cancel();
    sendTimer?.cancel();

    fetchTimer = Timer.periodic(Duration(seconds: fetchIntervalSeconds), (timer) async {
      if (_isCollecting) return;
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService() == false) {
          timer.cancel();
          return;
        }
      }
      _isCollecting = true;
      try {
        final payload = await deviceService.collectPayload();
        buffer.update(payload);
      } on PlatformException catch (e) {
        print("Lỗi khi thu thập dữ liệu: ${e.message}");
      } catch (e) {
        print("Collect loop error: $e");
      } finally {
        _isCollecting = false;
      }
    });

    sendTimer = Timer.periodic(Duration(seconds: sendIntervalSeconds), (timer) async {
      if (_isSending) return;
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService() == false) {
          timer.cancel();
          return;
        }
      }

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "GR2 đang chạy ngầm",
          content: "Cập nhật lúc: ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
        );
      }

      final snapshot = buffer.latest;
      if (snapshot == null) {
        // Nothing to send yet
        return;
      }

      _isSending = true;
      try {
        print("Background Service: Đang gửi dữ liệu (${useMqttMode ? 'MQTT' : 'API'})...");
        await deviceService.sendPayload(snapshot, useMqtt: useMqttMode);
      } on PlatformException catch (e) {
        print("Lỗi gửi dữ liệu (Platform): ${e.message}");
      } catch (e) {
        print("Send loop error: $e");
      } finally {
        _isSending = false;
      }
    });
  }

  // Allow runtime reconfiguration of mode and intervals
  service.on('updateConfig').listen((event) {
    try {
      if (event != null && event is Map) {
        final config = event as Map<dynamic, dynamic>;
        if (config['mode'] is String) {
          final m = (config['mode'] as String).toLowerCase();
          useMqttMode = m == 'mqtt';
        }
        if (config['sendInterval'] is int) {
          sendIntervalSeconds = (config['sendInterval'] as int).clamp(1, 3600);
        }
        if (config['fetchInterval'] is int) {
          fetchIntervalSeconds = (config['fetchInterval'] as int).clamp(1, 3600);
        }
        _startTimers();
      }
    } catch (e) {
      print('updateConfig parse error: $e');
    }
  });

  // Start the initial timers with defaults
  _startTimers();
}
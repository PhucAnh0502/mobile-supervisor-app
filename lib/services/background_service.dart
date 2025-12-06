import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:gr2/services/device_info_service.dart';

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

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 10), (timer) async {
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

    try {
      print("Background Service: Đang gửi dữ liệu...");
      await deviceService.submitCollectedData();
    } on PlatformException catch (e) {
      print("Lỗi Quyền (Android 14): ${e.message}");
    } catch (e) {
      print("Lỗi không xác định trong background: $e");
    }
  });
}
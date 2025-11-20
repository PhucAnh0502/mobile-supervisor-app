import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gr2/models/device_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:flutter_cell_info/cell_response.dart';
import 'package:flutter_cell_info/flutter_cell_info.dart';
import 'package:flutter_cell_info/models/common/cell_type.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<void> requestPermission() async {
    await [Permission.phone, Permission.location].request();
  }



  Future<DeviceInfo> getDeviceInfo() async {
    String model = 'Unknown';
    String type = 'Unknown';
    String os = 'Unknown';

    try {
      if(Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        model = '${androidInfo.manufacturer} ${androidInfo.model}';
        type = 'Android';
        os = 'Android ${androidInfo.version.release}';
      } else if(Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        model = iosInfo.name;
        type = 'iOS';
        os = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }
    } catch (e) {
      print("Error getting device info: $e");
    }

    return DeviceInfo(
      model: model,
      type: type,
      os: os,
    );
  }

  Future<String> getPhoneNumber() async {
    final hasPermission = await Permission.phone.isGranted;
    if (!hasPermission) {
      return 'Permission not granted';
    }

    try {
      String? phoneNumber = await MobileNumber.mobileNumber;
      return phoneNumber ?? 'Phone number not available';
    } catch (e) {
      return 'Error in getting phone number: $e';
    }
  }

  Future<Map<String, double?>?> getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      } 

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return {'lat': position.latitude, 'lon': position.longitude};
    } catch (e) {
      return null;
    }
  }

  Future<Stream<Position>> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 0,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    LocationSettings settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<String> getCellInfo() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.phone,
    ].request();

    if (!statuses[Permission.location]!.isGranted) {
      return 'Location permission was denied';
    }
    if (!statuses[Permission.phone]!.isGranted) {
      return 'Phone permission was denied';
    }

    try {
      const channel = MethodChannel('cell_info');
      try {
        String? result;
        try {
          result = await channel.invokeMethod<String>('getAllCellInfo');
        } on MissingPluginException catch (_) {
          try {
            result = await channel.invokeMethod<String>('getCellInfo');
          } on MissingPluginException catch (_) {
            result = await channel.invokeMethod<String>('cell_info');
          }
        }
        if (result != null) {
          final body = json.decode(result);

          if (body is List) {
            if (body.isEmpty) {
            } else {
              final first = body[0];
              if (first is Map<String, dynamic>) {
                final type = first['type'] ?? first['cellType'] ?? 'Unknown';
                final signal = first['signalDbm'] ?? first['dbm'] ?? first['signal'] ?? null;
                final sigText = signal != null ? signal.toString() : 'N/A';
                return '$type dbm = $sigText';
              } else {
                return first.toString();
              }
            }
          } else if (body is Map<String, dynamic>) {
            final cellsResponse = CellsResponse.fromJson(body);

            if (cellsResponse.primaryCellList == null ||
                cellsResponse.primaryCellList!.isEmpty) {
            } else {
              final CellType currentCellInFirstChip = cellsResponse.primaryCellList![0];
              String currentDBM;
              if (currentCellInFirstChip.type == "LTE") {
                currentDBM = "LTE dbm = ${currentCellInFirstChip.lte?.signalLTE?.dbm}";
              } else if (currentCellInFirstChip.type == "NR") {
                currentDBM = "NR dbm = ${currentCellInFirstChip.nr?.signalNR?.dbm}";
              } else if (currentCellInFirstChip.type == "WCDMA") {
                currentDBM = "WCDMA dbm = ${currentCellInFirstChip.wcdma?.signalWCDMA?.dbm}";
              } else {
                currentDBM = "Unknown cell type or dbm not available (${currentCellInFirstChip.type})";
              }
              return currentDBM;
            }
          }
        }
      } on PlatformException catch (pe) {
        print('PlatformException when calling getAllCellInfo: ${pe.message}');
        if (pe.message != null &&
            pe.message!.toLowerCase().contains('securityexception')) {
          return 'Platform security exception when getting cell info: ${pe.message}';
        }
      } catch (e) {
        print('Unexpected error when calling getAllCellInfo: $e');
      }

      String? platformVersion = await CellInfo.getCellInfo;
      if (platformVersion == null) {
        return 'Failed to get cell info (response was null)';
      }

      final body = json.decode(platformVersion);
      final cellsResponse = CellsResponse.fromJson(body);

      if (cellsResponse.primaryCellList == null ||
          cellsResponse.primaryCellList!.isEmpty) {
        return 'No primary cell info found';
      }

      final CellType currentCellInFirstChip = cellsResponse.primaryCellList![0];
      String currentDBM;
      if (currentCellInFirstChip.type == "LTE") {
        currentDBM = "LTE dbm = ${currentCellInFirstChip.lte?.signalLTE?.dbm}";
      } else if (currentCellInFirstChip.type == "NR") {
        currentDBM = "NR dbm = ${currentCellInFirstChip.nr?.signalNR?.dbm}";
      } else if (currentCellInFirstChip.type == "WCDMA") {
        currentDBM =
            "WCDMA dbm = ${currentCellInFirstChip.wcdma?.signalWCDMA?.dbm}";
      } else {
        currentDBM =
            "Unknown cell type or dbm not available (${currentCellInFirstChip.type})";
      }

      return currentDBM;
    } catch (e, st) {
      print('Error in getting cell info: $e');
      print(st);
      return 'Error in getting cell info: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getCellInfoList() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.phone,
    ].request();

    if (!statuses[Permission.location]!.isGranted || !statuses[Permission.phone]!.isGranted) {
      throw Exception('Required permissions not granted');
    }

    try {
      const channel = MethodChannel('cell_info');
      String? raw;
      try {
        raw = await channel.invokeMethod<String>('getAllCellInfo');
      } on MissingPluginException {
        try {
          raw = await channel.invokeMethod<String>('getCellInfo');
        } on MissingPluginException {
          raw = await channel.invokeMethod<String>('cell_info');
        }
      }

      if (raw != null) {
        try {
          print('RAW_CELL_JSON (channel): $raw');
        } catch (_) {}
        final decoded = json.decode(raw);
        if (decoded is List) {
          return decoded.map<Map<String, dynamic>>((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return { 'value': e.toString() };
          }).toList();
        }
        if (decoded is Map) {
          if (decoded.containsKey('primaryCellList')) {
            final list = decoded['primaryCellList'];
            if (list is List) {
              return list.map<Map<String,dynamic>>((e) => e is Map ? Map<String,dynamic>.from(e) : {'value': e.toString()}).toList();
            }
          }
          return [Map<String, dynamic>.from(decoded)];
        }
      }

      String? platformVersion = await CellInfo.getCellInfo;
      if (platformVersion != null) {
        try {
          print('RAW_CELL_JSON (fallback CellInfo.getCellInfo): $platformVersion');
        } catch (_) {}
      }
      if (platformVersion == null) return [];
      final body = json.decode(platformVersion);
      if (body is List) {
        return body.map<Map<String,dynamic>>((e) => e is Map ? Map<String,dynamic>.from(e) : {'value': e.toString()}).toList();
      }
      if (body is Map && body.containsKey('primaryCellList')) {
        final list = body['primaryCellList'];
  if (list is List) return list.map<Map<String,dynamic>>((e) => e is Map ? Map<String,dynamic>.from(e) : {'value': e.toString()}).toList();
      }
      if (body is Map) return [Map<String,dynamic>.from(body)];
      return [];
    } catch (e) {
      throw Exception('Error fetching cell info list: $e');
    }
  }
}

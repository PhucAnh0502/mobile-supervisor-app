import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gr2/models/device_info.dart';
import 'package:gr2/utils/token_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:flutter_cell_info/cell_response.dart';
import 'package:flutter_cell_info/flutter_cell_info.dart';
import 'package:flutter_cell_info/models/common/cell_type.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:gr2/services/api_service.dart';
import 'package:gr2/services/mqtt_service.dart';
import 'package:gr2/services/data_buffer.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<void> requestPermission() async {
    await [Permission.phone, Permission.location, Permission.notification].request();
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
    final locationGranted = await Permission.location.isGranted;
    final phoneGranted = await Permission.phone.isGranted;

    if (!locationGranted) {
      return 'Location permission was denied';
    }
    if (!phoneGranted) {
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
    final locationGranted = await Permission.location.isGranted;
    final phoneGranted = await Permission.phone.isGranted;

    if (!locationGranted || !phoneGranted) {
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
          try {
            raw = await channel.invokeMethod<String>('cell_info');
          } on MissingPluginException {
            raw = null;
          }
        }
      } catch (pe) {
        print('Platform channel exception while fetching cell info: $pe');
        raw = null;
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

      // Try plugin API as fallback but specifically handle SecurityException wrapped in PlatformException
      String? platformVersion;
      try {
        platformVersion = await CellInfo.getCellInfo;
      } on PlatformException catch (pe) {
        final msg = pe.toString();
        print('PlatformException while getting cell info (treated as no-data): $msg');
        return [];
      } catch (e) {
        print('Unexpected error when calling CellInfo.getCellInfo: $e');
        platformVersion = null;
      }

      if (platformVersion == null) return [];

      try {
        print('RAW_CELL_JSON (fallback CellInfo.getCellInfo): $platformVersion');
      } catch (_) {}

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
      // Catch-all: return empty list rather than throwing platform-specific security error
      print('Error fetching cell info list (returning empty): $e');
      return [];
    }
  }

  Future<bool> submitCollectedData({bool useMqtt = false}) async {
    try {
      final payload = await collectPayload();
      // Update the shared buffer so other loops can reuse the latest data
      DataBuffer().update(payload);
      final ok = await sendPayload(payload, useMqtt: useMqtt);
      return ok;
    } catch (e) {
      print('Error in submitCollectedData: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> collectPayload() async {
    final loc = await getLocation();
    final cells = await getCellInfoList();
    final deviceId = await TokenManager().getDeviceId();

    Map<String, dynamic>? locationPayload;
    if (loc != null && loc['lat'] != null && loc['lon'] != null) {
      locationPayload = {
        'latitude': loc['lat'],
        'longitude': loc['lon'],
      };
    } else {
      locationPayload = {'latitude': null, 'longitude': null};
    }

    List<Map<String, dynamic>> towers = cells.map<Map<String, dynamic>>(
      (cell) {
        final type = (cell['type'] ?? cell['cellType'] ?? 'Unknown').toString();

        int? mcc = _extractInt(cell['mcc'] ?? cell['MCC']);
        int? mnc = _extractInt(cell['mnc'] ?? cell['MNC']);
        int? lac = _extractInt(cell['lac'] ?? cell['tac'] ?? cell['LAC'] ?? cell['tacId']);
        int? cid = _extractInt(cell['cid'] ?? cell['ci'] ?? cell['CI'] ?? cell['ciId']);
        int? rssi = _extractInt(cell['rssi'] ?? cell['signal'] ?? cell['signalDbm'] ?? cell['dbm']);
        int? signalDbm = _extractInt(cell['signalDbm'] ?? cell['dbm'] ?? cell['signal']);
        int? pci = _extractInt(cell['pci'] ?? cell['PCI']);

        final map = {
          'type': type,
          'mcc': mcc,
          'mnc': mnc,
          'lac': lac,
          'cid': cid,
          'rssi': rssi,
          'signalDbm': signalDbm,
          'pci': pci,
        };

        return map;
      },
    ).toList();

    final payload = {
      'deviceId': deviceId,
      'location': locationPayload,
      'cellTowers': towers,
    };

    return payload;
  }

  Future<bool> sendPayload(Map<String, dynamic> payload, {required bool useMqtt}) async {
    try {
      if (useMqtt) {
        final mqtt = MqttService();
        final deviceId = (payload['deviceId'] ?? '') as String;
        final sent = await mqtt.publishCellInfo(deviceId, payload);
        return sent;
      } else {
        final api = ApiService();
        final ok = await api.submitCellData(payload);
        return ok;
      }
    } catch (e) {
      print('Error in sendPayload: $e');
      return false;
    }
  }

  int? _extractInt(dynamic v) {
    if (v == null) return 0;
    
    int? val;
    if (v is int) val = v;
    else if (v is double) val = v.toInt();
    else if (v is String) {
      final cleaned = v.trim();
      val = int.tryParse(cleaned);
    }
    else if (v is Map) {
      final candidates = ['value', 'val', 'tac', 'LAC', 'lac', 'tacId', 'ci', 'cid', 'CI', 'pci', 'PCI', 'dbm', 'signalDbm'];
      for (final k in candidates) {
        if (v.containsKey(k)) {
          final extracted = _extractInt(v[k]);
          if (extracted != null) {
            val = extracted;
            break; 
          }
        }
      }
      if (val == null) {
        for (final entry in v.entries) {
          final nested = _extractInt(entry.value);
          if (nested != null) {
            val = nested;
            break;
          }
        }
      }
    }
    else if (v is List && v.isNotEmpty) {
      val = _extractInt(v.first);
    }

    if (val == 2147483647 || val == null) return 0; 
    
    return val;
  }
}

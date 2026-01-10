import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'api-key';
  static const _deviceId = 'deviceId';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _deviceId, value: deviceId);
  }

  Future<String> getDeviceId() async {
    return await _storage.read(key: _deviceId) ?? '';
  }

  Future<void> deleteDeviceId() async {
    await _storage.delete(key: _deviceId);
  }
}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'api-key';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }
}
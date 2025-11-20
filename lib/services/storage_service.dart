import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _registrationKey = 'hasRegistered';

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();

    return !(prefs.getBool(_registrationKey) ?? false);
  }

  Future<void> setHasRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_registrationKey, true);
  }
}
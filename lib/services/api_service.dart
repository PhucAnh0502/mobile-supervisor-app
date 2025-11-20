import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:gr2/models/user_info.dart';

class ApiService {
  final String _baseUrl = 'https://mobile-supervisor/api/v1';

  Future<bool> registerUser(UserInfo userInfo) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userInfo.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('User registered successfully: ${response.body}');
        return true;
      } else {
        print("Failed to register user: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to register user');
      }
    } catch (e) {
      print('Error during user registration: $e');
      throw Exception('Failed to register user');
    }
  }
}

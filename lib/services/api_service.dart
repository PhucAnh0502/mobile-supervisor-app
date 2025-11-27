import 'dart:convert';
import 'package:gr2/utils/token_manager.dart';
import 'package:http/http.dart' as http;
import 'package:gr2/env/env.dart';

import 'package:gr2/models/user_info.dart';

class ApiService {
  final String _baseUrl = Env.baseApiUrl;

  Future<bool> registerUser(UserInfo userInfo) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userInfo.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Registration response: ${response.body}');
        try {
          final decoded = jsonDecode(response.body);

          final String? token = decoded['data']?['apiKey'];

          if (token != null && token.isNotEmpty) {
            final TokenManager tokenManager =
                TokenManager();
            await tokenManager.saveToken(token);
            print('Saved Access Token: $token');
          } else {
            print('Token not found or empty in response');
          }

          return true;
        } catch (e) {
          print('Error parsing token: $e');
        }
        print('User registered successfully: ${response.body}');
        return true;
      } else {
        print(
          "Failed to register user: ${response.statusCode} - ${response.body}",
        );
        throw Exception('Failed to register user');
      }
    } catch (e) {
      print('Error during user registration: $e');
      throw Exception('Failed to register user');
    }
  }

  /// Submit cell/location payload to server. If [apiKey] is provided it will be used
  /// as an `x-api-key` header. Otherwise this method will try to use any saved
  /// token from `TokenManager` and send it as `x-api-key` (preferred by the backend).
  Future<bool> submitCellData(
    Map<String, dynamic> payload
    ) async {
    final url = Uri.parse('$_baseUrl/data/submit');
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
        // try to use saved token and send it as x-api-key (backend expects this)
        final tm = TokenManager();
        final tokenToUse = await tm.getToken();
        if (tokenToUse != null && tokenToUse.isNotEmpty) {
          print('Token to use: $tokenToUse');
          headers['x-api-key'] = tokenToUse;
          print(headers);
      }
      print('Submitting payload: $payload');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Cell data submitted successfully: ${response.body}');
        return true;
      } else {
        print(
          'Failed to submit cell data: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error submitting cell data: $e');
      return false;
    }
  }
}

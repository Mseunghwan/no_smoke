import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = "http://10.0.2.2:8080/api";
  final _storage = const FlutterSecureStorage();

  // 회원가입 API
  Future<Map<String, dynamic>> signUp(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? '회원가입에 실패했습니다.');
    }
  }

  // 로그인 API
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      // **로그인 성공 시 토큰과 사용자 ID 저장**
      await _storage.write(key: 'jwt_token', value: responseData['data']['token']);
      await _storage.write(key: 'user_id', value: responseData['data']['id'].toString());
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? '로그인에 실패했습니다.');
    }
  }

  // 로그아웃 (토큰 삭제)
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
  }

  // 저장된 토큰 가져오기
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
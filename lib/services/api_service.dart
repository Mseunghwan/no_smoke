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


  // 인증 헤더 헬퍼 메소드
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> _getUserId() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) {
      throw Exception('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
    }
    return userId;
  }

  // [New] 스털링 챗봇과 대화하기
  Future<String> chatWithSterling(String message) async {
    final userId = await _getUserId();
    final url = Uri.parse('$_baseUrl/monkey/chat/$userId');
    final headers = await _getAuthHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'message': message}),
    );

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      // 백엔드 ApiResponse 구조: { "status": "SUCCESS", "message": "...", "data": "AI 응답 텍스트" }
      return responseData['data'];
    } else {
      throw Exception(responseData['message'] ?? 'AI 응답을 받아오지 못했습니다.');
    }
  }

  // [New] 건강 상태 분석 요청
  Future<String> getHealthAnalysis() async {
    final userId = await _getUserId();
    final url = Uri.parse('$_baseUrl/monkey/analysis/$userId');
    final headers = await _getAuthHeaders();

    final response = await http.post(
      url,
      headers: headers,
    );

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData['data'];
    } else {
      throw Exception(responseData['message'] ?? '건강 분석에 실패했습니다.');
    }
  }

  Future<Map<String, dynamic>> getChatHistory({int page = 0, int size = 20}) async {
    // 쿼리 파라미터로 page, size 전달
    final userId = await _getUserId();
    final url = Uri.parse('$_baseUrl/monkey/messages?page=$page&size=$size');
    final headers = await _getAuthHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      // Spring의 Slice 응답 구조:
      // {
      //   "status": "...",
      //   "data": {
      //      "content": [ ... 메시지 리스트 ... ],
      //      "last": false, // 마지막 페이지 여부
      //      "first": true,
      //      ...
      //   }
      // }
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final data = jsonResponse['data'];

      List<dynamic> content = data['content'];
      bool isLast = data['last'] ?? true;

      return {
        'messages': content, // 아직 DTO 상태 (Map)
        'isLast': isLast,
      };
    } else {
      throw Exception('채팅 내역을 불러오는데 실패했습니다.');
    }
  }

  // 흡연 정보 등록 API
  Future<void> saveSmokingInfo({
    required String cigaretteType,
    required int dailyConsumption,
    required DateTime quitDate,
    required DateTime targetDate,
    required String quitGoal,
  }) async {
    final url = Uri.parse('$_baseUrl/smoking-info');
    final headers = await _getAuthHeaders(); // 인증 헤더 가져오기

    final response = await http.post(
      url,
      headers: headers, // 헤더에 토큰 포함!
      body: jsonEncode({
        'cigaretteType': cigaretteType,
        'dailyConsumption': dailyConsumption,
        // 백엔드는 LocalDateTime을 기대하므로 ISO 8601 형식으로 변환
        'quitStartTime': quitDate.toIso8601String(),
        'targetDate': targetDate.toIso8601String(),
        'quitGoal': quitGoal,
      }),
    );

    if (response.statusCode != 201) { // 201 Created
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(responseData['message'] ?? '흡연 정보 저장에 실패했습니다.');
    }
  }

  // 대시보드 데이터를 백엔드에서 불러와서 적용
  Future<Map<String, dynamic>> getDashboardData() async {
    final url = Uri.parse('$_baseUrl/dashboard');
    final headers = await _getAuthHeaders(); // 인증 헤더 가져오기

    final response = await http.get(
      url,
      headers: headers, // 헤더에 토큰 포함
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return responseData['data']; // 실제 데이터는 'data' 키 안에 있습니다.
    } else {
      throw Exception('대시보드 정보 로딩에 실패했습니다.');
    }
  }

  // 일일 설문 등록 API
  Future<void> saveDailySurvey({
    required bool isSuccess,
    required int stressLevel,
    String? stressCause,
    required int cravingLevel,
    String? additionalNotes,
  }) async {
    final url = Uri.parse('$_baseUrl/surveys');
    final headers = await _getAuthHeaders(); // 인증 헤더 가져오기

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'success': isSuccess,
        'stressLevel': stressLevel,
        'stressCause': stressCause,
        'cravingLevel': cravingLevel,
        'additionalNotes': additionalNotes,
      }),
    );

    if (response.statusCode != 201) { // 201 Created
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(responseData['message'] ?? '설문 저장에 실패했습니다.');
    }
  }
}
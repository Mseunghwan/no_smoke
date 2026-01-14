import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_settings.dart';

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
      await _storage.write(key: 'jwt_token', value: responseData['data']['accessToken']);
      await _storage.write(key: 'refresh_token', value: responseData['data']['refreshToken']);
      await _storage.write(key: 'user_id', value: responseData['data']['id'].toString());
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? '로그인에 실패했습니다.');
    }
  }

  // [추가] 사용자 이름(닉네임) 업데이트
  Future<void> updateUserName(String name) async {
    final userId = await _getUserId();
    final url = Uri.parse('$_baseUrl/auth/profile/$userId');

    final response = await _putWithAuth(url, body: {'name': name});

    if (response.statusCode != 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(responseData['message'] ?? '이름 수정에 실패했습니다.');
    }
  }

  // [추가] 흡연 정보 조회 및 UserSettings 생성
  Future<UserSettings> getSmokingInfoAndCreateSettings(String userName) async {
    final url = Uri.parse('$_baseUrl/smoking-info');
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final data = responseData['data'];

      return UserSettings(
        quitDate: DateTime.parse(data['quitStartDate']),
        nickname: userName,
        cigaretteType: data['cigaretteType'],
        cigarettesPerDay: data['dailyConsumption'],
        cigarettePrice: 4500, // 기본값 설정 (필요시 서버에서 받아오도록 수정 가능)
        goal: data['quitGoal'],
        targetDate: DateTime.parse(data['targetDate']),
      );
    } else {
      throw Exception('흡연 정보를 불러오는데 실패했습니다.');
    }
  }

  // 로그아웃 (서버 통신 + 토큰 삭제)
  Future<void> logout() async {
    try {
      final accessToken = await _storage.read(key: 'jwt_token');
      if (accessToken != null) {
        final url = Uri.parse('$_baseUrl/auth/logout');

        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
      }
    } catch (e) {
      print("로그아웃 서버 통신 실패 (무시하고 로컬 삭제 진행): $e");
    } finally {
      // 로컬 토큰 삭제
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_id');
    }
  }

  // 토큰 재발급 로직 (내부 사용)
  Future<bool> _reissueToken() async {
    try {
      final accessToken = await _storage.read(key: 'jwt_token');
      final refreshToken = await _storage.read(key: 'refresh_token');

      if (accessToken == null || refreshToken == null) return false;

      final url = Uri.parse('$_baseUrl/auth/reissue');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'RefreshToken': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final newAccessToken = responseData['data']['accessToken'];
        final newRefreshToken = responseData['data']['refreshToken'];

        await _storage.write(key: 'jwt_token', value: newAccessToken);
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('토큰 재발급 에러: $e');
      return false;
    }
  }

  // 저장된 액세스 토큰 가져오기
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // 기본 인증 헤더 생성
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

  // HTTP 요청 래퍼 메서드 (자동 토큰 갱신 로직 포함)

  // POST 요청 래퍼
  Future<http.Response> _postWithAuth(Uri url, {Map<String, dynamic>? body}) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      print("401 Unauthorized 감지 - 토큰 재발급 시도");
      final isReissued = await _reissueToken();

      if (isReissued) {
        final newHeaders = await _getAuthHeaders();
        return await http.post(url, headers: newHeaders, body: jsonEncode(body));
      } else {
        throw Exception('세션이 만료되었습니다. 다시 로그인해주세요.');
      }
    }
    return response;
  }

  // GET 요청 래퍼
  Future<http.Response> _getWithAuth(Uri url) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 401) {
      print("401 Unauthorized 감지 - 토큰 재발급 시도");
      final isReissued = await _reissueToken();

      if (isReissued) {
        final newHeaders = await _getAuthHeaders();
        return await http.get(url, headers: newHeaders);
      } else {
        throw Exception('세션이 만료되었습니다. 다시 로그인해주세요.');
      }
    }
    return response;
  }

  // [추가] PUT 요청 래퍼
  Future<http.Response> _putWithAuth(Uri url, {Map<String, dynamic>? body}) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      print("401 Unauthorized 감지 (PUT) - 토큰 재발급 시도");
      final isReissued = await _reissueToken();

      if (isReissued) {
        final newHeaders = await _getAuthHeaders();
        return await http.put(url, headers: newHeaders, body: jsonEncode(body));
      } else {
        throw Exception('세션이 만료되었습니다. 다시 로그인해주세요.');
      }
    }
    return response;
  }

  // 스털링 챗봇과 대화하기
  Future<String> chatWithSterling(String message) async {
    final userId = await _getUserId();
    final url = Uri.parse('$_baseUrl/monkey/chat/$userId');

    final response = await _postWithAuth(url, body: {'message': message});

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData['data'];
    } else {
      throw Exception(responseData['message'] ?? 'AI 응답을 받아오지 못했습니다.');
    }
  }

  // 건강 상태 분석 요청
  Future<String> getHealthAnalysis() async {
    final userId = await _getUserId();
    final url = Uri.parse('$_baseUrl/monkey/analysis/$userId');

    final response = await _postWithAuth(url);

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData['data'];
    } else {
      throw Exception(responseData['message'] ?? '건강 분석에 실패했습니다.');
    }
  }

  Future<Map<String, dynamic>> getChatHistory({int page = 0, int size = 20}) async {
    final userId = await _getUserId();
    final url = Uri.parse('$_baseUrl/monkey/messages?page=$page&size=$size');

    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final data = jsonResponse['data'];

      List<dynamic> content = data['content'];
      bool isLast = data['last'] ?? true;

      return {
        'messages': content,
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

    final response = await _postWithAuth(url, body: {
      'cigaretteType': cigaretteType,
      'dailyConsumption': dailyConsumption,
      'quitStartTime': quitDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'quitGoal': quitGoal,
    });

    if (response.statusCode != 201) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(responseData['message'] ?? '흡연 정보 저장에 실패했습니다.');
    }
  }

  // 대시보드 데이터 불러오기
  Future<Map<String, dynamic>> getDashboardData() async {
    final url = Uri.parse('$_baseUrl/dashboard');

    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return responseData['data'];
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

    final response = await _postWithAuth(url, body: {
      'success': isSuccess,
      'stressLevel': stressLevel,
      'stressCause': stressCause,
      'cravingLevel': cravingLevel,
      'additionalNotes': additionalNotes,
    });

    if (response.statusCode != 201) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(responseData['message'] ?? '설문 저장에 실패했습니다.');
    }
  }
}
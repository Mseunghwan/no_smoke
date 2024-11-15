import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const String apiKey = 'AIzaSyAZl0G5h4D0USdMAS0joRCJ_ef_mRfhTX0'; // Replace with your actual API key

  /// Sends a prompt to the Google Gemini API and receives a response
  static Future<String> getResponse(String prompt) async {
    try {
      print('Starting Gemini API call');
      print('Request URL: $apiUrl');

      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.8,
            'maxOutputTokens': 200,
          },
        }),
      );

      print('Response code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
            return content['parts'][0]['text'] ?? '응답을 처리할 수 없습니다.';
          }
        }
        return '유효한 응답을 받지 못했습니다.';
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Request failed: $e');
    }
  }

  /// Returns smoke-free tips based on the duration
  static String getSmokeFreeTips(int smokeFreeTime) {
    return '''
금연 중이신지 ${smokeFreeTime}시간이 지났습니다. 금연 유지 팁:
- 건강한 식단 유지
- 스트레스 관리 (예: 산책, 취미)
- 가족과 친구의 응원받기
금연을 계속 이어가세요! 🚭
''';
  }
}
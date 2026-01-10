import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SocketService {
  // 안드로이드 에뮬레이터: 10.0.2.2, 실제 기기: PC IP 주소
  static const String _wsUrl = 'ws://10.0.2.2:8080/ws-stomp';
  final _storage = const FlutterSecureStorage();

  StompClient? client;

  void connectAndSubscribe({
    required Function(Map<String, dynamic>) onMessageReceived
  }) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        onConnect: (StompFrame frame) {
          print('>>> [WebSocket] 연결 성공!');

          client?.subscribe(
            destination: '/sub/channel/$userId',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                print('>>> [WebSocket] 메시지 수신: ${frame.body}');
                final Map<String, dynamic> data = jsonDecode(frame.body!);
                onMessageReceived(data);
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => print('>>> [WebSocket] 에러: $error'),
      ),
    );

    client?.activate();
  }

  void disconnect() {
    client?.deactivate();
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final int smokeFreeHours;
  const ChatScreen({Key? key, required this.smokeFreeHours}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService(); // ApiService 인스턴스 생성
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // 더 선명하고 다양한 보라색 테마 색상 정의
  static const Color primaryPurple = Color(0xFF8B5CF6);      // 밝은 보라
  static const Color lightPurple = Color(0xFFEDE9FE);        // 매우 연한 보라
  static const Color darkPurple = Color(0xFF6D28D9);         // 진한 보라
  static const Color accentPurple = Color(0xFFA78BFA);       // 악센트 보라
  static const Color backgroundPurple = Color(0xFFF5F3FF);   // 배경 보라

  @override
  void initState() {
    super.initState();
    _loadChatHistory(); // 이전 대화 불러오기 (선택) 혹은 첫 인사
  }

  // 초기 로딩: 백엔드에서 이전 대화 내역을 가져오거나, 가벼운 첫 인사를 보냄
  void _loadChatHistory() async {
    // 만약 이전 대화를 불러오고 싶다면 ApiService.getChatHistory() 호출 구현
    // 여기서는 심플하게 스털링이 먼저 말을 거는 효과를 위해 빈 메시지 호출 등을 하거나
    // UI상으로만 처리할 수 있습니다.
    // 여기서는 "금연 조언"을 요청하여 첫 말문을 트겠습니다.
    _sendMessage("금연 중인데 힘이 되는 짧은 한마디 해줘", isInitiatedBySystem: true);
  }

  Future<void> _sendMessage(String text, {bool isInitiatedBySystem = false}) async {
    if (text.trim().isEmpty) return;

    setState(() {
      // 시스템이 시작한 대화(첫인사)가 아니면 내 말풍선 추가
      if (!isInitiatedBySystem) {
        _messages.add(ChatMessage(text: text, isUser: true));
      }
      _isTyping = true;
    });

    if (!isInitiatedBySystem) _messageController.clear();
    _scrollToBottom();

    try {
      // [변경] GeminiService 대신 ApiService 사용
      final response = await _apiService.chatWithSterling(text);

      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('스털링과 연결할 수 없습니다.'),
          backgroundColor: Color(0xFF6D28D9), // darkPurple
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple, darkPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              '스털링과 대화하기',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.smokeFreeHours}시간째 금연 중',
              style: const TextStyle(
                fontSize: 14,
                color: lightPurple,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/chat_bg.png'), // 배경 이미지가 있다면 사용
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              backgroundPurple.withOpacity(1),
              BlendMode.overlay,
            ),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundPurple,
              lightPurple,
              Colors.white.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageBubble(message: message);
                },
              ),
            ),
            if (_isTyping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: lightPurple.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [primaryPurple, accentPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/image.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Text(
                      '스털링이 입력 중...',
                      style: TextStyle(
                        color: darkPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    lightPurple.withOpacity(0.9),
                    Colors.white.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            lightPurple.withOpacity(0.5),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: (_) => _sendMessage(_messageController.text),
                        decoration: InputDecoration(
                          hintText: '메시지를 입력하세요...',
                          hintStyle: TextStyle(
                            color: darkPurple.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryPurple, darkPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 35,
              height: 35,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    _ChatScreenState.primaryPurple,
                    _ChatScreenState.accentPurple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/image.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ChatScreenState.primaryPurple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: message.isUser
                      ? [
                    _ChatScreenState.primaryPurple,
                    _ChatScreenState.darkPurple,
                  ]
                      : [
                    Colors.white,
                    _ChatScreenState.lightPurple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                  bottomRight: Radius.circular(message.isUser ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? _ChatScreenState.primaryPurple.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final int smokeFreeHours;
  const ChatScreen({Key? key, required this.smokeFreeHours}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // [Pagination 상태 변수]
  int _currentPage = 0;      // 현재 로딩할 페이지 번호
  bool _isLastPage = false;  // 더 불러올 데이터가 없는지
  bool _isLoading = false;   // 현재 로딩 중인지

  // 색상 정의 (기존 유지)
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color lightPurple = Color(0xFFEDE9FE);
  static const Color darkPurple = Color(0xFF6D28D9);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color backgroundPurple = Color(0xFFF5F3FF);

  @override
  void initState() {
    super.initState();
    _connectWebSocket();

    // 1. 화면 진입 시 첫 페이지(가장 최신 20개) 로딩
    _loadMoreMessages(initialLoad: true);

    // 2. 스크롤 리스너 등록 (무한 스크롤)
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // 스크롤 이벤트 핸들러
  void _onScroll() {
    // 스크롤이 상단(maxScrollExtent)에 거의 도달했을 때 (reverse: true 이므로 max가 상단)
    // 픽셀 여유분을 200정도 둡니다.
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  // 메시지 가져오기
  Future<void> _loadMoreMessages({bool initialLoad = false}) async {
    if (_isLoading || _isLastPage) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.getChatHistory(
        page: _currentPage,
        size: 20,
      );

      List<dynamic> content = result['messages'];
      bool isLast = result['isLast'];

      // DTO Map -> ChatMessage 모델 변환
      List<ChatMessage> newMessages = content.map((json) {
        // 백엔드에서 받은 type 확인
        String type = json['messageType'] ?? 'REACTIVE';

        // [New] type이 'USER'면 내 메시지(isUser: true)로 처리
        bool isUserMsg = (type == 'USER');

        return ChatMessage(
          text: json['content'] ?? '',
          isUser: isUserMsg,
        );
      }).toList();
      setState(() {
        // 기존 리스트 뒤에 추가 (reverse 리스트이므로 뒤에 붙이면 과거 메시지가 됨)
        _messages.addAll(newMessages);

        _currentPage++; // 다음 페이지 준비
        _isLastPage = isLast;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      print("채팅 기록 로딩 에러: $e");
    }
  }

  void _connectWebSocket() {
    _socketService.connectAndSubscribe(
      onMessageReceived: (data) {
        final String aiReply = data['content'] ?? "응답 오류";
        if (mounted) {
          setState(() {
            // 새 메시지는 리스트 맨 앞(화면 최하단)에 추가
            _messages.insert(0, ChatMessage(text: aiReply, isUser: false));
            _isTyping = false;
          });
          // 새 메시지가 오면 스크롤을 맨 아래(0.0)로 이동
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  Future<void> _sendMessage(String text, {bool isInitiatedBySystem = false}) async {
    if (text.trim().isEmpty) return;

    setState(() {
      if (!isInitiatedBySystem) {
        // 내가 보낸 메시지 즉시 추가 (맨 앞)
        _messages.insert(0, ChatMessage(text: text, isUser: true));
      }
      _isTyping = true;
    });

    if (!isInitiatedBySystem) _messageController.clear();

    // 메시지 전송 시 스크롤 맨 아래로
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    try {
      await _apiService.chatWithSterling(text);
    } catch (e) {
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지 전송 실패'), backgroundColor: darkPurple),
      );
    }
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
                reverse: true, // [중요] 채팅은 아래에서 위로 쌓임 (인덱스 0이 최신)
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                // 로딩 중이면 맨 위에 인디케이터 하나 더 보여주기 위해 +1
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // 로딩 표시 렌더링 (리스트의 '끝' 부분 = 스크롤 최상단)
                  if (index == _messages.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

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
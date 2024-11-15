import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
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
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _sendInitialMessage();
  }

  Future<void> _sendInitialMessage() async {
    final prompt = GeminiService.getSmokeFreeTips(widget.smokeFreeHours);
    setState(() => _isTyping = true);

    try {
      final response = await GeminiService.getResponse(prompt);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초기 메시지 로드 중 오류: $e')),
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _messageController.clear();

    try {
      final response = await GeminiService.getResponse(text);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 전송 중 오류: $e')),
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
        title: const Text('AI 챗봇'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

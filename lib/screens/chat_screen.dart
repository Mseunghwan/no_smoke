import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final int smokeFreeHours;

  const ChatScreen({Key? key, required this.smokeFreeHours}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messages.add(ChatMessage(text: _generateAIResponse(text), isUser: false));
    });

    _messageController.clear();
  }

  String _generateAIResponse(String userMessage) {
    // Simple AI response logic for demonstration
    if (userMessage.contains('금연')) {
      return '금연 중이시군요! 응원합니다. 꾸준히 해내시면 더 건강한 삶이 기다리고 있어요!';
    } else if (userMessage.contains('스트레스')) {
      return '스트레스를 줄이는 방법으로 심호흡, 산책, 그리고 음악 감상이 좋아요!';
    } else {
      return '좋은 질문이에요! 금연 중인 지금, 무엇이든 물어보세요.';
    }
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
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
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

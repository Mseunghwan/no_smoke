import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_settings.dart';
import '../screens/chat_screen.dart'; // ChatScreen이 있는 경로로 수정
import '../widgets/stats_card.dart'; // StatsCard 파일 경로 확인

class HomeScreen extends StatelessWidget {
  final UserSettings settings;

  const HomeScreen({Key? key, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysSince = DateTime.now().difference(settings.quitDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text('${settings.nickname}님의 금연 여정'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatsCard(
              daysSince: daysSince,
              savedMoney: _calculateSavedMoney(settings),
              savedCigarettes: _calculateSavedCigarettes(settings),
            ),
            const SizedBox(height: 20),
            Text(
              '금연 시작일: ${DateFormat('yyyy-MM-dd').format(settings.quitDate)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Text(
              '목표: ${settings.goal ?? '목표를 설정해주세요'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(smokeFreeHours: daysSince * 24),
                  ),
                );
              },
              child: const Text('AI 챗봇과 대화하기'),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSavedMoney(UserSettings settings) {
    final daysSinceQuit = DateTime.now().difference(settings.quitDate).inDays;
    final packsPerDay = settings.cigarettesPerDay / 20.0; // 한 갑은 20개비
    return (packsPerDay * settings.cigarettePrice * daysSinceQuit).floor();
  }

  int _calculateSavedCigarettes(UserSettings settings) {
    final daysSinceQuit = DateTime.now().difference(settings.quitDate).inDays;
    return (settings.cigarettesPerDay * daysSinceQuit).floor();
  }
}

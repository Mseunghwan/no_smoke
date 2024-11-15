import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_settings.dart';
import '../widgets/stats_card.dart'; // StatsCard
import '../widgets/daliy_survey_card.dart'; // DailySurveyCard
import 'chat_screen.dart';
import 'daily_survey_screen.dart'; // DailySurveyScreen

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
            DailySurveyCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DailySurveyScreen(
                      onCigarettesUpdate: (cigarettes) {
                        // 설문 완료 후 업데이트할 로직 추가 가능
                      },
                    ),
                  ),
                );
              },
              hasCompleted: false, // 설문 완료 여부에 따라 true/false로 설정
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_settings.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import '../widgets/stats_card.dart';
import '../widgets/daliy_survey_card.dart';
import 'daily_survey_screen.dart';

class HomeScreen extends StatelessWidget {
  final UserSettings settings;

  const HomeScreen({Key? key, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysSince = DateTime.now().difference(settings.quitDate).inDays;
    final points = _calculatePoints(settings);
    final numberFormat = NumberFormat.currency(
      symbol: '₩',
      locale: 'ko_KR',
      decimalDigits: 0,
    );

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
            const SizedBox(height: 16),
            DailySurveyCard(
              hasCompleted: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DailySurveyScreen(
                      onCigarettesUpdate: (newCigarettes) {
                        // 금연 정보 업데이트 처리

                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(currentPoints: points),
                  ),
                );
              },
              child: const Text('프로필 보기'),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSavedMoney(UserSettings settings) {
    final daysSinceQuit = DateTime.now().difference(settings.quitDate).inDays;
    final packsPerDay = settings.cigarettesPerDay / 20.0;
    return (packsPerDay * settings.cigarettePrice * daysSinceQuit).floor();
  }

  int _calculateSavedCigarettes(UserSettings settings) {
    final daysSinceQuit = DateTime.now().difference(settings.quitDate).inDays;
    return (settings.cigarettesPerDay * daysSinceQuit).floor();
  }

  int _calculatePoints(UserSettings settings) {
    final daysSinceQuit = DateTime.now().difference(settings.quitDate).inDays;
    return daysSinceQuit * 10; // 하루에 10 포인트씩 적립
  }
}

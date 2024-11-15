import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_settings.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  final UserSettings settings;

  const HomeScreen({Key? key, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysSince = DateTime.now().difference(settings.quitDate).inDays;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '금연 시작일: ${DateFormat('yyyy-MM-dd').format(settings.quitDate)}',
              style: Theme.of(context).textTheme.bodyLarge, // subtitle1 대신 bodyLarge 사용
            ),
            const SizedBox(height: 10),
            Text(
              '금연 진행일: $daysSince일',
              style: Theme.of(context).textTheme.bodyLarge, // subtitle1 대신 bodyLarge 사용
            ),
            const SizedBox(height: 10),
            Text(
              '절약한 금액: ${numberFormat.format(_calculateSavedMoney(settings))}',
              style: Theme.of(context).textTheme.bodyLarge, // subtitle1 대신 bodyLarge 사용
            ),
            const SizedBox(height: 10),
            Text(
              '피하지 않은 담배: ${_calculateSavedCigarettes(settings)}개비',
              style: Theme.of(context).textTheme.bodyLarge, // subtitle1 대신 bodyLarge 사용
            ),
            const Spacer(),
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

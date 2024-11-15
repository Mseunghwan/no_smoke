import 'package:flutter/material.dart';
import '../models/user_settings.dart';

class HomeScreen extends StatelessWidget {
  final UserSettings settings;

  const HomeScreen({Key? key, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${settings.nickname}님의 금연 도우미'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '닉네임: ${settings.nickname}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '담배 종류: ${settings.cigaretteType}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '하루 흡연량: ${settings.cigarettesPerDay}개비',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '목표: ${settings.goal}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '금연 시작일: ${settings.quitDate.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '목표 달성일: ${settings.targetDate.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

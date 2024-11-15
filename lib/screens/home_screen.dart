// screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // OnboardingScreen에서 전달된 데이터를 받음
    final Map<String, String> arguments =
    ModalRoute.of(context)?.settings.arguments as Map<String, String>;

    final smokingAmount = arguments['smokingAmount'];
    final smokingCost = arguments['smokingCost'];

    return Scaffold(
      appBar: AppBar(
        title: Text('홈 화면'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '하루 흡연량: $smokingAmount 개비',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              '한 갑당 가격: $smokingCost 원',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              '금연을 시작해 보세요!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

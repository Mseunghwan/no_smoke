import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  final TextEditingController smokingAmountController = TextEditingController();
  final TextEditingController smokingCostController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('금연 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '기본 금연 설정을 입력하세요',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            TextField(
              controller: smokingAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '하루 흡연량 (개비)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: smokingCostController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '한 갑당 가격 (원)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                final smokingAmount = smokingAmountController.text;
                final smokingCost = smokingCostController.text;

                Navigator.pushReplacementNamed(context, '/home', arguments: {
                  'smokingAmount': smokingAmount,
                  'smokingCost': smokingCost,
                });
              },
              child: Text('설정 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

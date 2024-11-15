import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_settings.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _smokingAmountController = TextEditingController();
  final _goalController = TextEditingController();
  DateTime? _quitDate;
  DateTime? _targetDate;

  @override
  void dispose() {
    _nicknameController.dispose();
    _smokingAmountController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_quitDate == null || _targetDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 정보를 입력해주세요')),
        );
        print("필수 값 누락: _quitDate 또는 _targetDate가 null");
        return;
      }

      final settings = UserSettings(
        nickname: _nicknameController.text.trim(),
        cigaretteType: "연초", // 고정값
        cigarettesPerDay: int.tryParse(_smokingAmountController.text) ?? 0,
        quitDate: _quitDate!,
        goal: _goalController.text.trim(),
        targetDate: _targetDate!,
        cigarettePrice: 4500, // 고정값
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userSettings', jsonEncode(settings.toJson()));

      if (!mounted) return;

      print("HomeScreen으로 이동: $settings");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(settings: settings),
        ),
      );
    } else {
      print("폼 유효성 검사 실패");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('금연 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '닉네임'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _smokingAmountController,
                decoration: const InputDecoration(
                  labelText: '하루 흡연량',
                  suffixText: '개비',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '흡연량을 입력해주세요';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return '유효한 숫자를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(labelText: '목표'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '목표를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _quitDate = picked;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _quitDate == null
                      ? '금연 시작일 선택'
                      : DateFormat('yyyy-MM-dd').format(_quitDate!),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _targetDate = picked;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _targetDate == null
                      ? '목표일 선택'
                      : DateFormat('yyyy-MM-dd').format(_targetDate!),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('설정 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

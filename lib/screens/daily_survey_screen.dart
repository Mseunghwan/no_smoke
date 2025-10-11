// screens/daily_survey_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_survey.dart';
import 'dart:convert';
import '../services/api_service.dart';

class DailySurveyScreen extends StatefulWidget {
  final Function(int) onCigarettesUpdate;  // 피운 담배 개수 업데이트 콜백

  const DailySurveyScreen({
    Key? key,
    required this.onCigarettesUpdate,
  }) : super(key: key);

  @override
  _DailySurveyScreenState createState() => _DailySurveyScreenState();
}

class _DailySurveyScreenState extends State<DailySurveyScreen> {
  bool? _isSmokeFree;
  int? _cigarettesSmoked;
  int _stressLevel = 3;
  String? _stressReason;
  int _urgencyLevel = 3;
  final _noteController = TextEditingController();
  final ApiService _apiService = ApiService();

  final List<String> _stressReasons = [
    '직장/학교 스트레스',
    '대인관계',
    '피로/수면부족',
    '식사 후 습관',
    '음주/회식',
    '기타',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          '오늘의 금연 체크',
          style: TextStyle(color: Color(0xFF2D3142)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('오늘 금연에 성공하셨나요?'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceButton(
                              title: '네!',
                              isSelected: _isSmokeFree == true,
                              onTap: () => setState(() {
                                _isSmokeFree = true;
                                _cigarettesSmoked = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildChoiceButton(
                              title: '아니요',
                              isSelected: _isSmokeFree == false,
                              onTap: () => setState(() => _isSmokeFree = false),
                            ),
                          ),
                        ],
                      ),
                      if (_isSmokeFree == false) ...[
                        const SizedBox(height: 16),
                        Text(
                          '오늘 피운 담배 개수',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _cigarettesSmoked == null || _cigarettesSmoked! <= 1
                                  ? null
                                  : () => setState(() => _cigarettesSmoked = _cigarettesSmoked! - 1),
                            ),
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_cigarettesSmoked ?? 1}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() =>
                              _cigarettesSmoked = (_cigarettesSmoked ?? 1) + 1),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('스트레스 수준은 어떠신가요?'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('😌'),
                          Expanded(
                            child: Slider(
                              value: _stressLevel.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              onChanged: (value) {
                                setState(() => _stressLevel = value.round());
                              },
                            ),
                          ),
                          const Text('😫'),
                        ],
                      ),
                      Text(
                        '현재 스트레스 레벨: $_stressLevel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('주된 스트레스 원인은 무엇인가요?'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _stressReasons.map((reason) {
                      return ChoiceChip(
                        label: Text(reason),
                        selected: _stressReason == reason,
                        onSelected: (selected) {
                          setState(() => _stressReason = selected ? reason : null);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('흡연 충동은 어느 정도인가요?'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🙂'),
                          Expanded(
                            child: Slider(
                              value: _urgencyLevel.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              onChanged: (value) {
                                setState(() => _urgencyLevel = value.round());
                              },
                            ),
                          ),
                          const Text('🚬'),
                        ],
                      ),
                      Text(
                        '현재 흡연 충동 레벨: $_urgencyLevel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('추가로 기록하고 싶은 내용이 있나요?'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '자유롭게 작성해주세요',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSmokeFree == null ? null : _saveSurvey,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3142),
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _saveSurvey() async {
    if (_isSmokeFree == null) return;

    // 로딩 인디케이터 보여주기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. 백엔드 API 호출
      await _apiService.saveDailySurvey(
        isSuccess: _isSmokeFree!,
        stressLevel: _stressLevel,
        stressCause: _stressReason,
        cravingLevel: _urgencyLevel,
        additionalNotes: _noteController.text.trim(),
      );

      if (!mounted) return;

      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오늘의 설문이 서버에 저장되었습니다.'),
          backgroundColor: Colors.blue,
        ),
      );

      // 홈 화면으로 돌아가면서 true 값을 전달하여 새로고침이 필요함을 알림
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();
      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
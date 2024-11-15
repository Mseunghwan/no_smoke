// widgets/daily_survey_card.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_survey.dart';

class DailySurveyCard extends StatelessWidget {
  final VoidCallback onTap;

  const DailySurveyCard({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  Future<bool> _hasCompletedTodaySurvey() async {
    final prefs = await SharedPreferences.getInstance();
    final surveys = prefs.getStringList('daily_surveys') ?? [];
    if (surveys.isEmpty) return false;

    final today = DateTime.now();
    for (var surveyJson in surveys) {
      final survey = DailySurvey.fromJson(jsonDecode(surveyJson));
      if (survey.date.year == today.year &&
          survey.date.month == today.month &&
          survey.date.day == today.day) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCompletedTodaySurvey(),
      builder: (context, snapshot) {
        final hasCompleted = snapshot.data ?? false;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: hasCompleted
                      ? [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ]
                      : [
                    Theme
                        .of(context)
                        .primaryColor
                        .withOpacity(0.1),
                    Theme
                        .of(context)
                        .primaryColor
                        .withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasCompleted
                              ? Colors.green
                              : Theme
                              .of(context)
                              .primaryColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: (hasCompleted
                                  ? Colors.green
                                  : Theme
                                  .of(context)
                                  .primaryColor)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          hasCompleted
                              ? Icons.check_circle_outline
                              : Icons.assignment_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasCompleted ? '오늘의 설문 완료!' : '오늘의 금연 체크',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasCompleted
                                  ? '💪수고하셨어요 매일 함께해요!'
                                  : '오늘 하루는 어떠셨나요? 📝',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: hasCompleted
                              ? Colors.green
                              : Theme
                              .of(context)
                              .primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (!hasCompleted) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 0.0,
                        backgroundColor: Colors.white.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme
                              .of(context)
                              .primaryColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '오늘의 설문이 아직 진행되지 않았어요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else
                    ...[
                                          ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'daily_survey.dart';

class HealthStatus {
  final int smokeFreeHours;
  final double lungCapacityImprovement;
  final double bloodCirculationImprovement;
  final double nicotineLevel;
  final List<String> improvements;
  final List<DailySurvey> recentSurveys;
  final String aiAnalysis;

  HealthStatus({
    required this.smokeFreeHours,
    required this.lungCapacityImprovement,
    required this.bloodCirculationImprovement,
    required this.nicotineLevel,
    required this.improvements,
    required this.recentSurveys,
    required this.aiAnalysis,
  });

  static double calculateLungCapacity(int hours) {
    // 폐 기능은 2-12주에 걸쳐 점진적으로 개선
    // 첫 72시간: 5%
    // 2주: 30%
    // 12주: 100%
    if (hours <= 72) {
      return 5.0 * (hours / 72);
    } else if (hours <= 336) { // 2주
      return 5.0 + (25.0 * ((hours - 72) / 264));
    } else if (hours <= 2016) { // 12주
      return 30.0 + (70.0 * ((hours - 336) / 1680));
    }
    return 100.0;
  }

  static double calculateBloodCirculation(int hours) {
    // 혈액순환은 2-12주에 걸쳐 개선
    // 첫 24시간: 10%
    // 3일: 30%
    // 2주: 60%
    // 12주: 100%
    if (hours <= 24) {
      return 10.0 * (hours / 24);
    } else if (hours <= 72) {
      return 10.0 + (20.0 * ((hours - 24) / 48));
    } else if (hours <= 336) {
      return 30.0 + (30.0 * ((hours - 72) / 264));
    } else if (hours <= 2016) {
      return 60.0 + (40.0 * ((hours - 336) / 1680));
    }
    return 100.0;
  }

  static double calculateNicotineLevel(int hours) {
    // 니코틴 반감기는 약 2시간
    // 24시간 후: 50% 감소
    // 48시간 후: 75% 감소
    // 72시간 후: 100% 제거
    if (hours >= 72) return 0.0;
    return 100.0 * math.pow(0.5, hours / 24);
  }
}
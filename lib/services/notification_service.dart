import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  /// Initialize the notification system
  static Future<void> initialize() async {
    AwesomeNotifications().initialize(
      'resource://drawable/res_app_icon', // Replace with your app icon
      [
        NotificationChannel(
          channelKey: 'smoking_reminder',
          channelName: 'Smoking Reminder',
          channelDescription: 'Reminders to avoid smoking and go for a walk',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );
  }

  /// Schedule daily notifications at specific times
  static Future<void> scheduleDailyNotifications() async {
    await _scheduleNotification(
      9,
      0,
      1,
      '흡연 대신 산책하세요! 🏃‍♂️',
      '오늘 아침은 산책으로 건강을 챙기세요!',
    );
    await _scheduleNotification(
      13,
      0,
      2,
      '점심 후 산책 타임! 🌞',
      '흡연 대신 산책으로 기분 전환 어떠세요?',
    );
    await _scheduleNotification(
      18,
      0,
      3,
      '저녁 산책! 🌇',
      '흡연 욕구를 이겨내고 건강을 위한 산책을 시작해보세요!',
    );
    await _scheduleNotification(
      22,
      0,
      4,
      '하루의 마무리 산책 🚶‍♂️',
      '흡연 대신 산책하며 하루를 정리하세요.',
    );
  }

  /// Schedule a single notification
  static Future<void> _scheduleNotification(
      int hour, int minute, int id, String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'smoking_reminder',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true, // Repeat daily
      ),
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
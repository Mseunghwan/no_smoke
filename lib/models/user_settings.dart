class UserSettings {
  final String nickname;
  final String cigaretteType;
  final int cigarettesPerDay;
  final DateTime quitDate;
  final String goal;
  final DateTime targetDate;
  final int cigarettePrice;

  UserSettings({
    required this.nickname,
    required this.cigaretteType,
    required this.cigarettesPerDay,
    required this.quitDate,
    required this.goal,
    required this.targetDate,
    required this.cigarettePrice,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      nickname: json['nickname'],
      cigaretteType: json['cigaretteType'],
      cigarettesPerDay: json['cigarettesPerDay'],
      quitDate: DateTime.parse(json['quitDate']),
      goal: json['goal'],
      targetDate: DateTime.parse(json['targetDate']),
      cigarettePrice: json['cigarettePrice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'cigaretteType': cigaretteType,
      'cigarettesPerDay': cigarettesPerDay,
      'quitDate': quitDate.toIso8601String(),
      'goal': goal,
      'targetDate': targetDate.toIso8601String(),
      'cigarettePrice': cigarettePrice,
    };
  }
}

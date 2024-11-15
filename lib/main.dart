import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'models/user_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final userSettingsString = prefs.getString('userSettings');
  final userSettings = userSettingsString != null
      ? UserSettings.fromJson(jsonDecode(userSettingsString))
      : null;

  runApp(MyApp(userSettings: userSettings));
}

class MyApp extends StatelessWidget {
  final UserSettings? userSettings;

  const MyApp({Key? key, this.userSettings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '금연 도우미',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: userSettings == null
          ? OnboardingScreen() // const 제거
          : HomeScreen(settings: userSettings!), // Nullable 처리
    );
  }
}

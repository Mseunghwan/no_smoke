import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'provider/profile_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'models/user_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _determineInitialScreen();
  }

  Future<Widget> _determineInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final userSettingsString = prefs.getString('userSettings');

    if (userSettingsString == null) {
      // Onboarding을 처음 실행
      return const OnboardingScreen();
    } else {
      // HomeScreen으로 바로 이동
      final userSettingsMap = jsonDecode(userSettingsString);
      final userSettings = UserSettings.fromJson(userSettingsMap);
      return HomeScreen(settings: userSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasData) {
          return MaterialApp(
            title: 'LetsGo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: snapshot.data,
          );
        }

        return const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Error loading the app')),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'provider/profile_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'models/user_settings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:letsgo/screens/auth_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/config/.env'); // key 값 가져오기

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
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    // 토큰이 없으면 로그인 화면으로 보냄
    if (token == null) {
      return const AuthScreen();
    }

    // 토큰이 있으면, 기존처럼 온보딩 정보를 확인
    final prefs = await SharedPreferences.getInstance();
    final userSettingsString = prefs.getString('userSettings');

    if (userSettingsString == null) {
      // 로그인은 했지만 흡연정보(온보딩)는 등록 안 한 경우
      return const OnboardingScreen();
    } else {
      // 로그인도, 온보딩도 완료한 경우
      final userSettings = UserSettings.fromJson(jsonDecode(userSettingsString));
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
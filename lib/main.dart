import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '금연 도우미',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => OnboardingScreen(), // 시작 화면
        '/home': (context) => HomeScreen(), // HomeScreen 연결
      },
    );
  }
}

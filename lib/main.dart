import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/profile_provider.dart';
import 'screens/home_screen.dart';
import 'models/user_settings.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LetsGo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(
        settings: UserSettings(
          nickname: '사용자',
          quitDate: DateTime.now().subtract(const Duration(days: 30)),
          cigarettesPerDay: 10,
          cigarettePrice: 4500,
          cigaretteType: '연초',
          goal: '건강한 삶',
          targetDate: DateTime.now().add(const Duration(days: 30)),
        ),
      ),
    );
  }
}

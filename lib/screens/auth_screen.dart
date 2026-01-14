import 'package:flutter/material.dart';
import 'package:letsgo/screens/onboarding_screen.dart';
import 'package:letsgo/screens/home_screen.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  String _email = '';
  String _password = '';
  bool _isLogin = true;

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();

      try {
        // 로딩 인디케이터 보여주기
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => Center(child: CircularProgressIndicator()),
        );

        if (_isLogin) {
          // --- 로그인 로직 ---
          final loginResponse = await _apiService.login(_email, _password);

          // 백엔드에서 받은 hasSmokingInfo와 사용자 이름 확인
          final bool hasSmokingInfo = loginResponse['data']['hasSmokingInfo'] ?? false;
          final String userName = loginResponse['data']['name'] ?? "사용자";

          if (hasSmokingInfo) {
            // 흡연 정보가 있으면 서버에서 가져와서 로컬에 저장 후 홈으로 이동
            final userSettings = await _apiService.getSmokingInfoAndCreateSettings(userName);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userSettings', jsonEncode(userSettings.toJson()));

            // 로딩 닫기
            Navigator.of(context).pop();

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomeScreen(settings: userSettings)),
            );
          } else {
            // 로딩 닫기
            Navigator.of(context).pop();

            // 흡연 정보가 없으면 온보딩 화면으로 이동
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }

        } else {
          // --- 회원가입 로직 ---
          // 이름 입력란이 없어졌으므로 임시 이름 사용 (온보딩에서 실제 닉네임으로 업데이트됨)
          await _apiService.signUp("새로운 사용자", _email, _password);

          if (!mounted) return;

          // 로딩 닫기
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원가입 성공! 자동으로 로그인합니다.'),
              backgroundColor: Colors.blue,
            ),
          );

          // 회원가입 성공 후 바로 로그인 시도
          // 로딩 다시 표시
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => Center(child: CircularProgressIndicator()),
          );

          await _apiService.login(_email, _password);

          // 로딩 닫기
          Navigator.of(context).pop();

          // 회원가입 직후에는 흡연 정보가 없으므로 온보딩으로 이동
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }

      } catch (e) {
        // 로딩 닫기 (다이얼로그가 열려있을 수 있으므로 안전하게 처리)
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isLogin ? '로그인' : '회원가입', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                // 이름 입력 필드 삭제됨
                TextFormField(
                  key: ValueKey('email'),
                  onSaved: (value) => _email = value!,
                  decoration: InputDecoration(labelText: '이메일'),
                  validator: (value) => (value!.isEmpty || !value.contains('@')) ? '올바른 이메일을 입력하세요.' : null,
                ),
                TextFormField(
                  key: ValueKey('password'),
                  onSaved: (value) => _password = value!,
                  decoration: InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                  validator: (value) => (value!.length < 8) ? '8자 이상 입력하세요.' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _trySubmit,
                  child: Text(_isLogin ? '로그인' : '회원가입'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
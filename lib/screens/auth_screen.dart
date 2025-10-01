import 'package:flutter/material.dart';
import 'package:letsgo/screens/onboarding_screen.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  String _name = '';
  String _email = '';
  String _password = '';
  bool _isLogin = true;

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();

      try {
        // 로딩 인디케이터 보여주기 (선택 사항)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => Center(child: CircularProgressIndicator()),
        );

        if (_isLogin) {
          // --- 로그인 로직 ---
          await _apiService.login(_email, _password);

          // 로그인 성공 후, 온보딩(흡연정보) 등록 여부 확인 단계로 이동해야 합니다.
          // 지금은 바로 온보딩 화면으로 이동시키겠습니다.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );

        } else {
          // --- 회원가입 로직 ---
          await _apiService.signUp(_name, _email, _password);

          // 회원가입 성공 메시지 표시
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원가입 성공! 자동으로 로그인합니다.'),
              backgroundColor: Colors.blue,
            ),
          );

          // 회원가입 성공 후, 바로 로그인하여 토큰을 받아옵니다.
          await _apiService.login(_email, _password);

          // 로그인 성공 후 온보딩 화면으로 이동
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }

      } catch (e) {
        // 로딩 인디케이터 닫기
        Navigator.of(context).pop();

        // 백엔드에서 보낸 에러 메시지를 화면에 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')), // "Exception: " 부분 제거
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
                if (!_isLogin)
                  TextFormField(
                    key: ValueKey('name'),
                    onSaved: (value) => _name = value!,
                    decoration: InputDecoration(labelText: '이름'),
                    validator: (value) => (value!.isEmpty) ? '이름을 입력하세요.' : null,
                  ),
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
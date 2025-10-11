import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_settings.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _nicknameController = TextEditingController();
  final _smokingAmountController = TextEditingController();
  final _goalController = TextEditingController();
  final ApiService _apiService = ApiService();

  DateTime? _quitDate;
  DateTime? _targetDate;
  String _nickname = '';
  String _cigaretteType = '연초';
  int _cigarettesPerDay = 0;
  String? _goal;
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<CigaretteType> _cigaretteTypes = [
    CigaretteType(
      name: '연초',
      description: '일반 담배',
      icon: Icons.smoking_rooms,
    ),
    CigaretteType(
      name: '궐련형 전자담배',
      description: '아이코스, 릴 등',
      icon: Icons.battery_charging_full,
    ),
    CigaretteType(
      name: '액상형 전자담배',
      description: '쥴, 릴베이퍼 등',
      icon: Icons.waves,
    ),
    CigaretteType(
      name: '기타',
      description: '파이프 등',
      icon: Icons.more_horiz,
    ),
  ];

  int _currentTypeIndex = 0;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() {
      setState(() {
        _nickname = _nicknameController.text;
      });
    });

    _smokingAmountController.addListener(() {
      if (_smokingAmountController.text.isNotEmpty) {
        setState(() {
          _cigarettesPerDay = int.parse(_smokingAmountController.text);
        });
      }
    });

    _goalController.addListener(() {
      setState(() {
        _goal = _goalController.text;
      });
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nicknameController.dispose();
    _smokingAmountController.dispose();
    _goalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[50]!,
              Colors.purple[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                    children: [
                      _buildNicknamePage(),
                      _buildCigaretteTypePage(),
                      _buildSmokingAmountPage(),
                      _buildQuitDatePage(),
                      _buildGoalPage(),
                    ],
                  ),
                ),
                _buildProgressIndicator(),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == _currentPage ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: index == _currentPage
                  ? Theme.of(context).primaryColor
                  : Colors.purple[200],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNicknamePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.purple,
              ),
              const SizedBox(height: 32),
              Text(
                '반갑습니다!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.purple[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '금연을 결심하신 것을 축하드립니다.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.purple[600],
                ),
              ),
              const SizedBox(height: 32),
              _buildInputField(
                controller: _nicknameController,
                label: '닉네임',
                hint: '사용하실 닉네임을 입력해주세요',
                icon: Icons.edit,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCigaretteTypePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '어떤 담배를 피우시나요?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.purple[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 320,
                child: PageView.builder(
                  itemCount: _cigaretteTypes.length,
                  controller: PageController(viewportFraction: 0.8),
                  onPageChanged: (int index) {
                    setState(() {
                      _currentTypeIndex = index;
                      _cigaretteType = _cigaretteTypes[index].name;
                    });
                  },
                  itemBuilder: (_, i) => _buildCigaretteTypeCard(i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCigaretteTypeCard(int index) {
    final isSelected = index == _currentTypeIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(isSelected ? 0.2 : 0.1),
            blurRadius: isSelected ? 20 : 10,
            offset: Offset(0, isSelected ? 8 : 4),
          ),
        ],
      ),
      child: Transform.scale(
        scale: isSelected ? 1 : 0.9,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _cigaretteTypes[index].icon,
                size: 64,
                color: isSelected ? Colors.purple : Colors.purple[300],
              ),
              const SizedBox(height: 24),
              Text(
                _cigaretteTypes[index].name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.purple[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cigaretteTypes[index].description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.purple[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmokingAmountPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Colors.purple,
              ),
              const SizedBox(height: 32),
              Text(
                '하루에 몇 개비를 피우시나요?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.purple[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildInputField(
                controller: _smokingAmountController,
                label: '하루 흡연량',
                hint: '숫자를 입력해주세요',
                icon: Icons.smoking_rooms,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                suffix: const Text('개비'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '하루 흡연량을 입력해주세요';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0 || number > 99) {
                    return '1~99 사이의 숫자를 입력해주세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuitDatePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 80,
                color: Colors.purple,
              ),
              const SizedBox(height: 32),
              Text(
                '언제부터 시작하시나요?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.purple[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Colors.purple,
                                onPrimary: Colors.white,
                                surface: Colors.purple[50]!,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _quitDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.purple[600],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _quitDate == null
                                ? '날짜 선택하기'
                                : DateFormat('yyyy년 MM월 dd일').format(_quitDate!),
                            style: TextStyle(
                              color: Colors.purple[800],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.flag,
                size: 80,
                color: Colors.purple,
              ),
              const SizedBox(height: 32),
              Text(
                '금연 목표를 설정해주세요',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.purple[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _goalController,
                  minLines: 1,
                  maxLines: 2,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    labelText: '목표',
                    hintText: '예: 가족들과 건강하게 지내기',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Icon(Icons.stars, color: Colors.purple),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.purple[900],
                    fontSize: 16,
                    height: 1.5,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '목표를 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.purple,
                          onPrimary: Colors.white,
                          surface: Colors.purple[50]!,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _targetDate = picked;
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.purple[600],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _targetDate == null
                          ? '목표일자 선택하기'
                          : DateFormat('yyyy년 MM월 dd일').format(_targetDate!),
                      style: TextStyle(
                        color: Colors.purple[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
        ),
        ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.never, // 라벨이 위로 올라가지 않게 함
          prefixIcon: Icon(icon, color: Colors.purple),
          suffix: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: TextStyle(
          color: Colors.purple[900],
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    bool canProceed = true;

    switch (_currentPage) {
      case 0:
        canProceed = _nicknameController.text.isNotEmpty;
        break;
      case 1:
        canProceed = true;
        break;
      case 2:
        canProceed = _smokingAmountController.text.isNotEmpty;
        break;
      case 3:
        canProceed = _quitDate != null;
        break;
      case 4:
        canProceed = _goalController.text.isNotEmpty && _targetDate != null;
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('이전'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )
          else
            const SizedBox(width: 100),
          ElevatedButton(
            onPressed: canProceed
                ? (_currentPage == 4 ? _submitForm : () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            })
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Text(
              _currentPage == 4 ? '시작하기' : '다음',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_quitDate == null || _targetDate == null) {
        return;
      }

      try {
        // 로딩 인디케이터 보여주기
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => Center(child: CircularProgressIndicator()),
        );

        // 1. 백엔드에 흡연 정보 저장 API 호출
        await _apiService.saveSmokingInfo(
          cigaretteType: _cigaretteType,
          dailyConsumption: int.parse(_smokingAmountController.text),
          quitDate: _quitDate!,
          targetDate: _targetDate!,
          quitGoal: _goalController.text.trim(),
        );

        // 2. API 호출 성공 후, 기존처럼 로컬에도 정보 저장
        final settings = UserSettings(
          quitDate: _quitDate!,
          nickname: _nickname, // 닉네임은 이전 화면에서 받아와야 함 (지금은 임시)
          cigaretteType: _cigaretteType,
          cigarettesPerDay: int.parse(_smokingAmountController.text),
          cigarettePrice: 4500,
          goal: _goalController.text.trim(),
          targetDate: _targetDate!,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userSettings', jsonEncode(settings.toJson()));

        if (!mounted) return;

        // 3. 홈 화면으로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(settings: settings)),
              (route) => false, // 이전의 모든 화면을 스택에서 제거
        );

      } catch (e) {
        // 로딩 인디케이터 닫기
        Navigator.of(context).pop();
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
}

class CigaretteType {
  final String name;
  final String description;
  final IconData icon;

  CigaretteType({
    required this.name,
    required this.description,
    required this.icon,
  });
}
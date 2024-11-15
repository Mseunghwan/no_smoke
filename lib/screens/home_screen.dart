import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_settings.dart';
import '../provider/profile_provider.dart';
import '../models/profile_item.dart';
import '../widgets/goal_card.dart' as goals;
import '../widgets/profile_preview.dart';
import '../widgets/stats_card.dart';
import '../widgets/daliy_survey_card.dart';
import 'profile_screen.dart';
import 'challenge_screen.dart';
import 'chat_screen.dart';
import 'daily_survey_screen.dart';
import 'health_status_screen.dart';
import '../models/daily_survey.dart';


class HomeScreen extends StatefulWidget {
  final UserSettings settings;

  const HomeScreen({
    Key? key,
    required this.settings,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _points = 0;
  Timer? _timer;
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Map<String, ProfileItem> _equippedItems = {};

  Future<List<DailySurvey>> _loadSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    final surveys = prefs.getStringList('daily_surveys') ?? [];

    return surveys.map((surveyJson) {
      return DailySurvey.fromJson(jsonDecode(surveyJson));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _calculatePoints();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _calculatePoints();
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    // ProfileProvider의 상태 변경을 구독
    context.read<ProfileProvider>().addListener(_onProfileProviderChanged);
  }

  @override
  void dispose() {
    // ProfileProvider의 상태 변경 구독 해제
    context.read<ProfileProvider>().removeListener(_onProfileProviderChanged);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onProfileProviderChanged() {
    setState(() {
      // ProfileProvider의 equippedItems 상태를 업데이트
      _equippedItems = context.read<ProfileProvider>().equippedItems;
    });
  }

  void _calculatePoints() {
    final Duration smokeFreeTime = DateTime.now().difference(widget.settings.quitDate);
    setState(() {
      _points = smokeFreeTime.inHours;
    });
  }

  int _calculateSavedMoney() {
    final Duration smokeFreeTime = DateTime.now().difference(widget.settings.quitDate);
    final double cigarettePacksPerDay = widget.settings.cigarettesPerDay / 20.0;
    final int totalDays = smokeFreeTime.inDays;
    return (cigarettePacksPerDay * widget.settings.cigarettePrice * totalDays).floor();
  }

  int _calculateSavedCigarettes() {
    final Duration smokeFreeTime = DateTime.now().difference(widget.settings.quitDate);
    return (smokeFreeTime.inDays * widget.settings.cigarettesPerDay).floor();
  }

  Future<void> _navigateWithAnimation(Widget screen) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
    setState(() => _selectedIndex = 0);
  }

  void _onItemTapped(int index) async {  // async 추가
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        _navigateWithAnimation(
          ChatScreen(smokeFreeHours: _points),
        );
        break;
      case 2:
        _navigateWithAnimation(
          ChallengeScreen(
            userSettings: widget.settings, // 추가된 부분
            onPointsEarned: (points) {
              setState(() {
                _points += points;
              });
            },
            savedMoney: _calculateSavedMoney(),
            savedCigarettes: _calculateSavedCigarettes(),
            consecutiveDays: DateTime.now().difference(widget.settings.quitDate).inDays,
          ),
        );
        break;
      case 3:
        final surveys = await _loadSurveys();  // 설문 데이터 로드
        _navigateWithAnimation(
          HealthStatusScreen(
            settings: widget.settings,
            surveys: surveys,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysSince = DateTime.now().difference(widget.settings.quitDate).inDays;
    final numberFormat = NumberFormat.currency(
      symbol: '₩',
      locale: 'ko_KR',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Column(
          children: [
            Text(
              '${widget.settings.nickname}님,',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const Text(
              '금연 여정을 함께해요!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9094A6),
              ),
            ),
          ],
        ),
        actions: [
          // 기존 프로필 버튼
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                _navigateWithAnimation(
                  ProfileScreen(currentPoints: _points),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8F9FE),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              _calculatePoints();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            displacement: 20,
            color: Theme.of(context).primaryColor,
            backgroundColor: Colors.white,
            strokeWidth: 3,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        StatsCard(
                          daysSince: daysSince,
                          savedMoney: _calculateSavedMoney(),
                          savedCigarettes: _calculateSavedCigarettes(),
                        ),
                        const SizedBox(height: 20),
                        ProfilePreview(
                          points: _points,
                          onProfileTap: () {
                            _navigateWithAnimation(
                              ProfileScreen(currentPoints: _points),
                            );
                          },
                          equippedItems: context.watch<ProfileProvider>().equippedItems,
                        ),
                        const SizedBox(height: 20),
                        DailySurveyCard(
                          onTap: () {
                            _navigateWithAnimation(
                              DailySurveyScreen(
                                onCigarettesUpdate: (cigarettes) {
                                  setState(() {
                                    _calculatePoints();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        goals.GoalCard(
                          goal: widget.settings.goal ?? '목표를 설정해주세요',
                          quitDate: widget.settings.quitDate, // quitDate를 추가로 전달
                          targetDate: widget.settings.targetDate, // targetDate도 전달
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: const Color(0xFF9094A6),
            selectedFontSize: 12,
            unselectedFontSize: 12,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: '상담',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_rounded),
                label: '도전',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.health_and_safety_rounded),
                label: '건강',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

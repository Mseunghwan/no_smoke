import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_settings.dart';
import '../provider/profile_provider.dart';
import '../widgets/goal_card.dart' as goals;
import '../widgets/profile_preview.dart';
import '../widgets/stats_card.dart';
import '../widgets/achievement_card.dart' as achievements;
import '../widgets/daliy_survey_card.dart';
import 'profile_screen.dart';
import 'challenge_screen.dart';
import 'chat_screen.dart';
import 'daily_survey_screen.dart';
import 'health_status_screen.dart';
import '../models/daily_survey.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // API 데이터 관리 변수
  final ApiService _apiService = ApiService();
  Future<Map<String, dynamic>>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

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
    context.read<ProfileProvider>().addListener(_onProfileProviderChanged);
  }

  void _loadDashboardData() {
    setState(() {
      _dashboardData = _apiService.getDashboardData();
    });
  }

  // 로컬에 저장된 설문 데이터를 불러오는 임시 함수
  // TODO: 추후 이 부분도 서버 API로 대체해야 합니다.
  Future<List<DailySurvey>> _loadSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    final surveys = prefs.getStringList('daily_surveys') ?? [];

    return surveys.map((surveyJson) {
      return DailySurvey.fromJson(jsonDecode(surveyJson));
    }).toList();
  }


  @override
  void dispose() {
    context.read<ProfileProvider>().removeListener(_onProfileProviderChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onProfileProviderChanged() {
    // Provider 상태가 변경되면 화면을 다시 그리도록 setState 호출
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () async {
                // 데이터를 기다린 후 화면 이동
                final data = await _dashboardData;
                if (data != null && mounted) {
                  _navigateWithAnimation(
                    ProfileScreen(currentPoints: data['points']?.toInt() ?? 0),
                  );
                }
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('데이터 로딩 실패: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    child: const Text('다시 시도'),
                  )
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            final data = snapshot.data!;
            final int daysSince = data['quitDays']?.toInt() ?? 0;
            final int savedMoney = data['moneySaved']?.toInt() ?? 0;
            final int savedCigarettes = data['cigarettesNotSmoked']?.toInt() ?? 0;
            final int points = data['points']?.toInt() ?? 0;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadDashboardData();
                },
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
                              savedMoney: savedMoney,
                              savedCigarettes: savedCigarettes,
                            ),
                            const SizedBox(height: 20),
                            ProfilePreview(
                              points: points,
                              onProfileTap: () {
                                _navigateWithAnimation(
                                  ProfileScreen(currentPoints: points),
                                );
                              },
                              equippedItems: context.watch<ProfileProvider>().equippedItems,
                            ),
                            const SizedBox(height: 20),
                            DailySurveyCard(
                              onTap: () async {
                                final result = await _navigateWithAnimation(
                                  DailySurveyScreen(
                                    onCigarettesUpdate: (cigarettes) {
                                      // 이 콜백은 더 이상 사용하지 않지만, 위젯의 요구사항이므로 비워둡니다.
                                    },
                                  ),
                                );

                                // 만약 DailySurveyScreen에서 true를 반환했다면 (저장 성공 시)
                                if (result == true && mounted) {
                                  // 대시보드 데이터를 새로고침!
                                  _loadDashboardData();
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            goals.GoalCard(
                              goal: widget.settings.goal,
                              quitDate: widget.settings.quitDate,
                              targetDate: widget.settings.targetDate,
                            ),
                            const SizedBox(height: 24),
                            achievements.AchievementCard(
                              points: points,
                              onProfileTap: () {
                                _navigateWithAnimation(
                                  ProfileScreen(currentPoints: points),
                                );
                              },
                              onChallengeTap: () {
                                _navigateWithAnimation(
                                  ChallengeScreen(
                                    userSettings: widget.settings,
                                    onPointsEarned: (points) {
                                      _loadDashboardData();
                                    },
                                    savedMoney: savedMoney,
                                    savedCigarettes: savedCigarettes,
                                    consecutiveDays: data['currentStreak']?.toInt() ?? 0,
                                    currentPoints: points,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('데이터가 없습니다.'));
        },
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
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: '상담'),
              BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: '도전'),
              BottomNavigationBarItem(icon: Icon(Icons.health_and_safety_rounded), label: '건강'),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) async {
    if (_selectedIndex == index) return;

    final data = await _dashboardData;
    if (data == null) return;

    final int points = data['points']?.toInt() ?? 0;
    final int savedMoney = data['moneySaved']?.toInt() ?? 0;
    final int savedCigarettes = data['cigarettesNotSmoked']?.toInt() ?? 0;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        await _navigateWithAnimation(
          ChatScreen(smokeFreeHours: data['quitDays']?.toInt() ?? 0),
        );
        break;
      case 2:
        await _navigateWithAnimation(
          ChallengeScreen(
            userSettings: widget.settings,
            onPointsEarned: (earnedPoints) {
              _loadDashboardData();
            },
            savedMoney: savedMoney,
            savedCigarettes: savedCigarettes,
            consecutiveDays: data['currentStreak']?.toInt() ?? 0,
            currentPoints: points,
          ),
        );
        break;
      case 3:
        final surveys = await _loadSurveys();
        await _navigateWithAnimation(
          HealthStatusScreen(
            settings: widget.settings,
            surveys: surveys,
          ),
        );
        break;
    }
    if (mounted) {
      setState(() => _selectedIndex = 0);
    }
  }

  Future<dynamic> _navigateWithAnimation(Widget screen) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/challenge.dart';
import '../models/user_settings.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import 'dart:math' show min;

class ChallengeScreen extends StatefulWidget {
  final UserSettings userSettings;
  final Function(int) onPointsEarned;
  final int savedMoney;
  final int savedCigarettes;
  final int consecutiveDays;

  ChallengeScreen({
    required this.userSettings,
    required this.onPointsEarned,
    required this.savedMoney,
    required this.savedCigarettes,
    required this.consecutiveDays,
  });

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  List<Challenge> challenges = [];
  late SharedPreferences prefs;
  late TabController _tabController;
  late PageController _pageController;
  late ConfettiController _confettiController;
  int _selectedCategory = 0;

  final categories = [
    {'name': '건강', 'icon': Icons.favorite, 'color': Color(0xFFFF6B6B)},
    {'name': '재정', 'icon': Icons.account_balance_wallet, 'color': Color(0xFF4ECDC4)},
    {'name': '환경', 'icon': Icons.eco, 'color': Color(0xFF45B7D1)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _pageController = PageController(viewportFraction: 0.85);
    _confettiController = ConfettiController(duration: Duration(seconds: 1));
    initPrefs();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();

    // 모든 challenge 상태 초기화
    for (var key in prefs.getKeys()) {
      if (key.startsWith('health_') || key.startsWith('finance_') || key.startsWith('clean_air_')) {
        await prefs.remove(key);
      }
    }

    challenges = getChallenges();
    for (var challenge in challenges) {
      challenge.updateProgress(
        widget.userSettings.cigarettePrice,
        widget.userSettings.cigarettesPerDay,
        widget.userSettings.quitDate,
      );
    }
    loadUnlockedStatus();
    updateChallenges();
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 100,  // 높이 조정
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(  // ListView 대신 Row 사용
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // 균등 분배
        children: List.generate(
          categories.length,
              (index) {
            final category = categories[index];
            final isSelected = _selectedCategory == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = index;
                  _pageController.animateToPage(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: Container(
                width: 90,  // 고정 너비
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? category['color'] as Color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,  // 최소 크기로 설정
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : category['color'] as Color,
                      size: 28,
                    ),
                    SizedBox(height: 6),
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,  // 폰트 크기 조정
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final progress = _calculateProgress(challenge);
    final isUnlocked = challenge.isUnlocked;
    Color categoryColor = _getCategoryColor(challenge.id);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isUnlocked ? categoryColor : Colors.grey[300]!,
                  isUnlocked ? categoryColor.withOpacity(0.8) : Colors.grey[400]!,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: (isUnlocked ? categoryColor : Colors.grey[400]!)
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  // 배경 패턴
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Transform.rotate(
                      angle: 0.4,
                      child: Icon(
                        challenge.icon,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // 메인 컨텐츠
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  challenge.icon,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                if (!isUnlocked)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${challenge.pointsReward}P',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Text(
                              challenge.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              challenge.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.environmentalImpact,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '진행 상황',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${(min(progress, 1.0) * 100).toInt()}%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    height: 8,
                                    width: MediaQuery.of(context).size.width *
                                        0.7 *
                                        min(progress, 1.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                _getProgressText(challenge),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUnlocked)
            Positioned(
              right: 24,
              top: 24,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: categoryColor,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '+${challenge.pointsReward}P',
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String challengeId) {
    if (challengeId.startsWith('health')) {
      return Color(0xFFFF6B6B); // 빨간색 계열
    } else if (challengeId.startsWith('finance')) {
      return Color(0xFF4ECDC4); // 민트색 계열
    } else {
      return Color(0xFF45B7D1); // 파란색 계열
    }
  }

  double _calculateProgress(Challenge challenge) {
    double progress = 0.0;
    if (challenge.requiredDays > 0) {
      progress = challenge.daysSinceQuit / challenge.requiredDays;
    } else if (challenge.requiredCigarettes > 0) {
      progress = challenge.currentCigarettes / challenge.requiredCigarettes;
    } else {
      progress = challenge.currentSavings / challenge.requiredSavings;
    }
    return min(progress, 1.0);  // 최대 1.0(100%)로 제한
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 90,  // 너비 조정
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,  // 한 줄로 제한
            overflow: TextOverflow.ellipsis,  // 넘치는 텍스트 처리
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

// _buildProgressStats 메서드 수정
  Widget _buildProgressStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // 균등 분배
        children: [
          _buildStatCard(
            '절약한 금액',
            '${widget.savedMoney}원',
            Icons.savings,
            Color(0xFF4ECDC4),
          ),
          _buildStatCard(
            '참은 담배',
            '${widget.savedCigarettes}개비',
            Icons.smoke_free,
            Color(0xFFFF6B6B),
          ),
          _buildStatCard(
            '금연 기간',
            '${widget.consecutiveDays}일',
            Icons.calendar_today,
            Color(0xFF45B7D1),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final healthChallenges = challenges.where((c) => c.id.startsWith('health')).toList();
    final financeChallenges = challenges.where((c) => c.id.startsWith('finance')).toList();
    final environmentChallenges = challenges.where((c) => c.id.startsWith('clean_air')).toList();

    final allCategoryChallenges = [
      healthChallenges,
      financeChallenges,
      environmentChallenges,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3436)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              '도전과제',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            Text(
              '금연으로 얻는 작은 성취들',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildProgressStats(),
              _buildCategorySelector(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: allCategoryChallenges[_selectedCategory].length,
                  itemBuilder: (context, index) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: Container(
                            height: constraints.maxHeight * 0.9,
                            child: _buildChallengeCard(
                              allCategoryChallenges[_selectedCategory][index],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -math.pi / 2,
            maxBlastForce: 100,
            minBlastForce: 80,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.3,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void loadUnlockedStatus() {
    for (var challenge in challenges) {
      challenge.isUnlocked = prefs.getBool(challenge.id) ?? false;
      challenge.isNotified = challenge.isUnlocked;
    }
  }

  void updateChallenges() {
    setState(() {
      for (var challenge in challenges) {
        challenge.updateProgress(
          widget.userSettings.cigarettePrice,
          widget.userSettings.cigarettesPerDay,
          widget.userSettings.quitDate,
        );

        if (challenge.isCompleted && !challenge.isUnlocked) {
          challenge.isUnlocked = true;
          prefs.setBool(challenge.id, true);

          if (!challenge.isNotified) {
            challenge.isNotified = true;
            widget.onPointsEarned(challenge.pointsReward);
            _confettiController.play();
          }
        }
      }
    });
  }

  String _getProgressText(Challenge challenge) {
    if (challenge.requiredDays > 0) {
      return '${min(challenge.daysSinceQuit, challenge.requiredDays)} / ${challenge.requiredDays}일';
    } else if (challenge.requiredCigarettes > 0) {
      return '${min(challenge.currentCigarettes, challenge.requiredCigarettes)} / ${challenge.requiredCigarettes}개비';
    } else {
      return '₩${min(challenge.currentSavings, challenge.requiredSavings).toStringAsFixed(0)} / ₩${challenge.requiredSavings.toStringAsFixed(0)}';
    }
  }

  List<Challenge> getChallenges() {
    return [
      Challenge(
        id: 'health_1',
        title: '건강한 첫걸음',
        description: '금연을 시작한지 3일이 지났습니다. 폐가 회복되기 시작했어요!',
        type: ChallengeType.achievement,
        requiredPoints: 0,
        requiredSavings: 0,
        requiredCigarettes: 0,
        requiredDays: 3,
        icon: Icons.favorite,
        environmentalImpact: '담배 연기가 없는 깨끗한 공기로 3일을 보냈습니다.',
        rewardTitle: '건강 수호자',
        pointsReward: 100,
      ),
      Challenge(
        id: 'finance_1',
        title: '현명한 소비',
        description: '금연으로 5만원을 절약했어요!',
        type: ChallengeType.achievement,
        requiredPoints: 0,
        requiredSavings: 50000,
        requiredCigarettes: 0,
        requiredDays: 0,
        icon: Icons.savings,
        environmentalImpact: '담배 구매 대신 더 가치있는 곳에 투자했습니다.',
        rewardTitle: '절약 달인',
        pointsReward: 150,
      ),
      Challenge(
        id: 'clean_air_1',
        title: '맑은 공기',
        description: '100개의 담배를 피우지 않았어요!',
        type: ChallengeType.achievement,
        requiredPoints: 0,
        requiredSavings: 0,
        requiredCigarettes: 100,
        requiredDays: 0,
        icon: Icons.air,
        environmentalImpact: '100개의 담배 연기가 공기를 오염시키지 않았습니다.',
        rewardTitle: '공기 지킴이',
        pointsReward: 150,
      ),
      Challenge(
        id: 'health_2',
        title: '건강 달성',
        description: '금연 2주를 달성했어요! 폐 기능이 크게 개선되었습니다.',
        type: ChallengeType.achievement,
        requiredPoints: 0,
        requiredSavings: 0,
        requiredCigarettes: 0,
        requiredDays: 14,
        icon: Icons.healing,
        environmentalImpact: '2주 동안 담배 연기 없는 깨끗한 환경을 만들었습니다.',
        rewardTitle: '건강 마스터',
        pointsReward: 200,
      ),
      Challenge(
        id: 'finance_2',
        title: '재정 성공',
        description: '금연으로 10만원을 절약했어요!',
        type: ChallengeType.achievement,
        requiredPoints: 0,
        requiredSavings: 100000,
        requiredCigarettes: 0,
        requiredDays: 0,
        icon: Icons.account_balance,
        environmentalImpact: '절약한 비용으로 환경 보호에 기여할 수 있습니다.',
        rewardTitle: '재정 전문가',
        pointsReward: 250,
      ),
      Challenge(
        id: 'clean_air_2',
        title: '환경 보호',
        description: '500개의 담배를 피우지 않았어요!',
        type: ChallengeType.achievement,
        requiredPoints: 0,
        requiredSavings: 0,
        requiredCigarettes: 500,
        requiredDays: 0,
        icon: Icons.eco,
        environmentalImpact: '500개의 담배꽁초가 환경을 오염시키지 않았습니다.',
        rewardTitle: '환경 수호자',
        pointsReward: 250,
      ),
    ];
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/challenge.dart';
import '../models/user_settings.dart';

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

class _ChallengeScreenState extends State<ChallengeScreen> with SingleTickerProviderStateMixin {
  List<Challenge> challenges = [];
  String? unlockedChallengeTitle;
  bool showUnlockedAnimation = false;
  late SharedPreferences prefs;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<List<String>> challengeLevels = [
    ['health_1'],
    ['finance_1', 'clean_air_1'],
    ['health_2'],
    ['finance_2', 'clean_air_2'],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    initPrefs();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    challenges = getChallenges();
    loadUnlockedStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateChallenges();
    });
  }

  void loadUnlockedStatus() {
    for (var challenge in challenges) {
      challenge.isUnlocked = prefs.getBool(challenge.id) ?? false;
      challenge.isNotified = challenge.isUnlocked;
    }
  }

  void updateChallenges() {
    bool newUnlock = false;

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
            newUnlock = true;
            unlockedChallengeTitle = challenge.title;
            challenge.isNotified = true;
            widget.onPointsEarned(challenge.pointsReward);
          }
        }
      }
    });

    if (newUnlock) {
      showUnlockAnimation();
    }
  }

  void showUnlockAnimation() {
    setState(() {
      showUnlockedAnimation = true;
    });
    Timer(Duration(seconds: 3), () {
      setState(() {
        showUnlockedAnimation = false;
        unlockedChallengeTitle = null;
      });
    });
  }

  Widget _buildChallengeBranch(Challenge challenge, bool isLeft) {
    final isUnlocked = challenge.isUnlocked;
    final progress = challenge.isCompleted ? 1.0 : 0.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          CustomPaint(
            size: Size(2, 80),
            painter: BranchPainter(
              progress: progress,
              isLeft: isLeft,
              color: isUnlocked ? Color(0xFF6C63FF) : Colors.grey.shade300,
            ),
          ),
          _buildChallengeCard(challenge),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final isUnlocked = challenge.isUnlocked;

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          _showChallengeDetails(challenge);
        }
      },
      child: Container(
        width: 160,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUnlocked
                ? [Color(0xFF6C63FF), Color(0xFF8A84FF)]
                : [Colors.grey.shade200, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? Color(0xFF6C63FF).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                challenge.icon,
                color: isUnlocked ? Colors.white : Colors.grey.shade600,
                size: 36,
              ),
            ),
            SizedBox(height: 12),
            Text(
              challenge.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white : Colors.grey.shade700,
                shadows: isUnlocked ? [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  )
                ] : [],
              ),
            ),
            if (isUnlocked)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '+${challenge.pointsReward}P',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber.shade300,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showChallengeDetails(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        challenge.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '환경 영향',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            challenge.environmentalImpact,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars,
                            color: Colors.amber.shade300,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '획득 칭호: ${challenge.rewardTitle}',
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontWeight: FontWeight.bold,
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
        actions: [
          TextButton(
            child: Text(
              '닫기',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "도전과제",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.blue,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8F9FF),
                  Colors.white,
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 100, 20, 30),
              child: Column(
                children: challengeLevels.asMap().entries.map((entry) {
                  final levelIndex = entry.key;
                  final levelChallenges = entry.value;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: levelChallenges.length > 1
                            ? MainAxisAlignment.spaceAround
                            : MainAxisAlignment.center,
                        children: levelChallenges.asMap().entries.map((challengeEntry) {
                          final challenge = challenges.firstWhere(
                                (c) => c.id == challengeEntry.value,
                          );
                          return _buildChallengeBranch(
                            challenge,
                            challengeEntry.key.isEven,
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          if (showUnlockedAnimation && unlockedChallengeTitle != null)
            Center(
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars,
                            color: Colors.amber.shade300,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "$unlockedChallengeTitle 해금!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class BranchPainter extends CustomPainter {
  final double progress;
  final bool isLeft;
  final Color color;

  BranchPainter({
    required this.progress,
    required this.isLeft,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isLeft) {
      path.moveTo(size.width / 2, 0);
      path.cubicTo(
        size.width / 2 - 80,
        size.height / 4,
        -60,
        size.height * 3 / 4,
        size.width / 2,
        size.height,
      );
    } else {
      path.moveTo(size.width / 2, 0);
      path.cubicTo(
        size.width / 2 + 80,
        size.height / 4,
        size.width + 60,
        size.height * 3 / 4,
        size.width / 2,
        size.height,
      );
    }

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(
      0.0,
      pathMetrics.length * progress,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 8);

    canvas.drawPath(extractPath, glowPaint);
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(BranchPainter oldDelegate) =>
      progress != oldDelegate.progress ||
          isLeft != oldDelegate.isLeft ||
          color != oldDelegate.color;
}
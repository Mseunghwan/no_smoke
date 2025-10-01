import 'package:flutter/material.dart';
import '../models/health_status.dart';
import '../models/user_settings.dart';
import '../models/daily_survey.dart';
import '../services/gemini_service.dart';

class HealthStatusScreen extends StatefulWidget {
  final UserSettings settings;
  final List<DailySurvey> surveys;

  const HealthStatusScreen({
    Key? key,
    required this.settings,
    required this.surveys,
  }) : super(key: key);

  @override
  _HealthStatusScreenState createState() => _HealthStatusScreenState();
}



class _HealthStatusScreenState extends State<HealthStatusScreen> {
  late HealthStatus _healthStatus;
  bool _isLoading = true;

  int? _heartRate;
  int? _steps;
  double? _oxygenLevel;

  String _createHealthAnalysisPrompt(int hours, List<DailySurvey> surveys) {
    final avgStressLevel = surveys.isEmpty
        ? 0
        : surveys.map((s) => s.stressLevel).reduce((a, b) => a + b) / surveys.length;

    return '''
전문의의 관점에서 사용자의 금연 진행 상태를 분석해주세요:

기본 정보:
- 금연 시간: $hours 시간
- 평균 스트레스 레벨: ${avgStressLevel.toStringAsFixed(1)}/5

신체 상태 데이터:
- 심박수: ${_heartRate ?? '데이터 없음'} bpm
- 일일 걸음 수: ${_steps ?? '데이터 없음'} steps
- 산소포화도: ${_oxygenLevel?.toStringAsFixed(1) ?? '데이터 없음'}%

분석 요청 사항:
1. 현재 신체 기능 개선 상태
2. 심혈관 건강 상태 평가
3. 운동 능력 및 폐 기능 분석
4. 스트레스 관리 전략 제안
5. 앞으로의 건강 개선 전망
''';
  }

  Future<String> _getAIAnalysis(String prompt) async {
    try {
      final response = await GeminiService.getResponse(prompt);
      return response;
    } catch (e) {
      return '건강 분석을 불러오는데 실패했습니다.';
    }
  }

  List<String> _calculateImprovements(int hours) {
    final improvements = <String>[];
    if (hours >= 8) improvements.add('혈중 산소량 정상화');
    if (hours >= 24) improvements.add('심장마비 위험 감소');
    if (hours >= 48) improvements.add('후각과 미각 개선');
    if (hours >= 72) improvements.add('기관지 기능 회복');
    if (hours >= 336) improvements.add('폐 기능 개선');
    if (hours >= 2160) improvements.add('심장질환 위험 절반으로 감소');
    return improvements;
  }

  @override
  void initState() {
    super.initState();
  }


  Future<void> _loadHealthStatus() async {
    final hours = DateTime.now().difference(widget.settings.quitDate).inHours;

    final lungCapacity = HealthStatus.calculateLungCapacity(hours);
    final bloodCirculation = HealthStatus.calculateBloodCirculation(hours);
    final nicotineLevel = HealthStatus.calculateNicotineLevel(hours);

    final prompt = _createHealthAnalysisPrompt(hours, widget.surveys);
    final analysis = await _getAIAnalysis(prompt);

    setState(() {
      _healthStatus = HealthStatus(
        smokeFreeHours: hours,
        lungCapacityImprovement: lungCapacity,
        bloodCirculationImprovement: bloodCirculation,
        nicotineLevel: nicotineLevel,
        improvements: _calculateImprovements(hours),
        recentSurveys: widget.surveys,
        aiAnalysis: analysis,
      );
      _isLoading = false;
    });
  }

  Widget _buildHealthMetricsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '금연 후 건강 개선',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMetricRow(
              icon: Icons.air,
              title: '폐 기능',
              value: _healthStatus.lungCapacityImprovement,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              icon: Icons.favorite,
              title: '혈액순환',
              value: _healthStatus.bloodCirculationImprovement,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              icon: Icons.healing,
              title: '니코틴 수치',
              value: _healthStatus.nicotineLevel,
              color: Colors.orange,
              isReverse: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String title,
    required double value,
    required Color color,
    bool isReverse = false,
  }) {
    final percentage = isReverse ? 100 - value : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '건강 개선 현황',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._healthStatus.improvements.map((improvement) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          improvement,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '전문의 분석 리포트',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                _healthStatus.aiAnalysis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF2D3142),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('건강 분석 리포트',
            style: TextStyle(color: Color(0xFF2D3142))),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVitalSignsCard(),
              const SizedBox(height: 20),
              _buildHealthMetricsCard(),
              const SizedBox(height: 20),
              _buildImprovementsCard(),
              const SizedBox(height: 20),
              _buildAIAnalysisCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalSignsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '실시간 건강 지표',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalSignCard(
                  icon: Icons.favorite,
                  title: '심박수',
                  value: _heartRate?.toString() ?? '-',
                  unit: 'bpm',
                  color: Colors.red,
                ),
                _buildVitalSignCard(
                  icon: Icons.directions_walk,
                  title: '걸음 수',
                  value: _steps?.toString() ?? '-',
                  unit: 'steps',
                  color: Colors.green,
                ),
                _buildVitalSignCard(
                  icon: Icons.air,
                  title: '산소포화도',
                  value: _oxygenLevel?.toStringAsFixed(1) ?? '-',
                  unit: '%',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
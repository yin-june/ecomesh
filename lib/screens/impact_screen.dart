import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../data/mock_data.dart';

class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen>
    with TickerProviderStateMixin {
  late AnimationController _barCtrl;
  late AnimationController _treeCtrl;
  late Animation<double> _barAnim;
  late Animation<double> _treeAnim;
  bool _showManager = false;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _treeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOut);
    _treeAnim = CurvedAnimation(parent: _treeCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 300), () {
      _barCtrl.forward();
      _treeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _treeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildImpactHero(),
            const SizedBox(height: 20),
            _buildTreeProgress(),
            const SizedBox(height: 20),
            _buildWeeklySavings(),
            const SizedBox(height: 20),
            _buildManagerToggle(),
            if (_showManager) ...[
              const SizedBox(height: 16),
              _buildManagerView(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Impact', style: AppTheme.displayLarge.copyWith(fontSize: 26)),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.mintGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: 
            Row(
              children: [
                const Icon(Icons.eco_rounded, color: Colors.white, size: 12),
                const SizedBox(width: 6),
                 Text(
                  'Eco Level 4',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                 ),
              ] 
            ),
        ),
      ],
    );
  }

  Widget _buildImpactHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "This Week's Impact",
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'RM 5.10',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'saved',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '8.7 kWh · 4.35 kg CO₂ prevented',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          // Mini stats row
          Row(
            children: [
              _heroStat('💡', '100h', 'LED powered'),
              _heroDivider(),
              _heroStat('📱', '72×', 'Phone charges'),
              _heroDivider(),
              _heroStat('🌳', '2', 'Trees equiv.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.25),
    );
  }

  Widget _buildTreeProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🌳 Carbon Progress',
                  style: AppTheme.headingMedium.copyWith(fontSize: 16)),
              const Spacer(),
              Text(
                '${mockUser.treesEquivalent} / 5 trees',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.mintGreen, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Save enough energy to offset 5 tree-equivalents of CO₂ this month',
            style: AppTheme.bodyMedium.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Animated progress bar
          AnimatedBuilder(
            animation: _treeAnim,
            builder: (_, __) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.iceBlue,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor:
                            (mockUser.treesEquivalent / 5) * _treeAnim.value,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: AppTheme.mintGradient,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tree emojis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (i) {
                      final filled = i < mockUser.treesEquivalent;
                      return AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: filled
                              ? 28 * _treeAnim.value
                              : 22,
                        ),
                        child: Text(filled ? '🌳' : '🪹'),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.softMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '3 more trees to unlock "EcoMesh Champion" badge!',
                    style: AppTheme.bodyMedium.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF00875A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySavings() {
    final maxKwh = weeklyData.fold(
        0.0, (max, d) => (d['kwh'] as double) > max ? d['kwh'] as double : max);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Savings', style: AppTheme.headingMedium),
          const SizedBox(height: 4),
          Text('kWh saved per day',
              style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weeklyData.map((d) {
                final kwh = d['kwh'] as double;
                final rm = d['rm'] as double;
                final isToday = d['day'] == 'Thu'; // mock
                return AnimatedBuilder(
                  animation: _barAnim,
                  builder: (_, __) {
                    final heightFrac =
                        maxKwh > 0 ? (kwh / maxKwh) * _barAnim.value : 0.0;
                    return _BarItem(
                      day: d['day'] as String,
                      kwh: kwh,
                      rm: rm,
                      heightFrac: heightFrac,
                      isToday: isToday,
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showManager = !_showManager),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.dashboard_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Facility Manager View',
                      style: AppTheme.headingMedium.copyWith(fontSize: 14)),
                  Text('Floor heatmap & predictive analysis',
                      style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _showManager ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Floor Heatmap · Level 2',
              style: AppTheme.headingMedium.copyWith(fontSize: 14)),
          const SizedBox(height: 14),
          _buildHeatmap(),
          const SizedBox(height: 16),
          Text('Predicted vs Actual (Today)',
              style: AppTheme.headingMedium.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          _buildMiniChart(),
          const SizedBox(height: 16),
          // ESG button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.skyBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  content: const Text(
                    '📄 ESG Report generated! Saving 4.35 kg CO₂ this week.',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.mintGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Center(
                child: Text(
                  '📄 Generate ESG Report',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    final cells = [
      {'zone': 'Zone A', 'level': 0.1, 'color': AppTheme.iceBlue},
      {'zone': 'Zone B', 'level': 0.85, 'color': AppTheme.skyBlue},
      {'zone': 'Zone C', 'level': 0.3, 'color': AppTheme.paleSky},
      {'zone': 'Zone D', 'level': 0.7, 'color': const Color(0xFF1A8FD4)},
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: cells.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c['color'] as Color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  c['zone'] as String,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: (c['level'] as double) > 0.5
                        ? Colors.white
                        : AppTheme.textMid,
                  ),
                ),
              ),
              Text(
                '${((c['level'] as double) * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: (c['level'] as double) > 0.5
                      ? Colors.white
                      : AppTheme.skyBlue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniChart() {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: _MiniChartPainter(readings: mockEnergyReadings),
        size: Size.infinite,
      ),
    );
  }
}

// ─── Bar Item ─────────────────────────────────────────────────────────────────
class _BarItem extends StatelessWidget {
  final String day;
  final double kwh, rm, heightFrac;
  final bool isToday;

  const _BarItem({
    required this.day,
    required this.kwh,
    required this.rm,
    required this.heightFrac,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (kwh > 0)
          Text(
            '${kwh}k',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isToday ? AppTheme.skyBlue : AppTheme.textLight,
            ),
          ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: math.max(8, 70 * heightFrac),
          decoration: BoxDecoration(
            gradient: isToday ? AppTheme.heroGradient : null,
            color: isToday ? null : AppTheme.iceBlue,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? AppTheme.skyBlue : AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}

// ─── Mini chart painter ───────────────────────────────────────────────────────
class _MiniChartPainter extends CustomPainter {
  final List<EnergyReading> readings;
  const _MiniChartPainter({required this.readings});

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;
    final maxVal = readings.fold(
        0.0, (m, r) => r.actual > m ? r.actual : m);

    final actualPaint = Paint()
      ..color = AppTheme.skyBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final predictPaint = Paint()
      ..color = AppTheme.amber
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Fill under actual
    final fillPath = Path();
    final actualPath = Path();
    final predictPath = Path();

    for (int i = 0; i < readings.length; i++) {
      final x = i / (readings.length - 1) * size.width;
      final ay = size.height - (readings[i].actual / maxVal) * size.height * 0.85;
      final py = size.height - (readings[i].predicted / maxVal) * size.height * 0.85;

      if (i == 0) {
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, ay);
        actualPath.moveTo(x, ay);
        predictPath.moveTo(x, py);
      } else {
        fillPath.lineTo(x, ay);
        actualPath.lineTo(x, ay);
        predictPath.lineTo(x, py);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.skyBlue.withOpacity(0.2),
          AppTheme.skyBlue.withOpacity(0.02),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(actualPath, actualPaint);
    canvas.drawPath(predictPath, predictPaint);

    // Legend
    final tp1 = TextPainter(
      text: const TextSpan(
        text: '— Actual',
        style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            color: AppTheme.skyBlue,
            fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, const Offset(4, 4));

    final tp2 = TextPainter(
      text: const TextSpan(
        text: '-- Predicted',
        style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            color: AppTheme.amber,
            fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(4 + tp1.width + 12, 4));
  }

  @override
  bool shouldRepaint(_) => false;
}
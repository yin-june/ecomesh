import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/app_state.dart';

// ─── Data models (mirrors backend analytics responses) ────────────────────────
class ImpactData {
  final double kwhSaved;
  final double rmSaved;
  final double co2Kg;
  final double treesEquivalent;

  const ImpactData({
    required this.kwhSaved,
    required this.rmSaved,
    required this.co2Kg,
    required this.treesEquivalent,
  });

  factory ImpactData.fromJson(Map<String, dynamic> json) {
    // Backend calculate_impact() returns: rm_saved, kg_co2_avoided, trees_equivalent
    // The analytics endpoint also adds rm_saved again (overwrite is fine)
    final co2Kg = (json['kg_co2_avoided'] as num?)?.toDouble() ??
        (json['co2_kg'] as num?)?.toDouble() ??
        0.0;
    final rmSaved = (json['rm_saved'] as num?)?.toDouble() ?? 0.0;
    final trees =
        (json['trees_equivalent'] as num?)?.toDouble() ?? 0.0;
    // Derive kWh from RM saved using TNB rate (0.435 RM/kWh)
    final kwh = rmSaved > 0 ? rmSaved / 0.435 : 0.0;
    return ImpactData(
      kwhSaved: (json['kwh_saved'] as num?)?.toDouble() ?? kwh,
      rmSaved: rmSaved,
      co2Kg: co2Kg,
      treesEquivalent: trees,
    );
  }

  // Derived display values
  int get ledHours => (kwhSaved / 0.01).round(); // 10W LED
  int get phoneCharges => (kwhSaved / 0.012).round(); // ~12Wh per charge
  int get ecoLevel {
    if (rmSaved >= 20) return 5;
    if (rmSaved >= 10) return 4;
    if (rmSaved >= 5) return 3;
    if (rmSaved >= 2) return 2;
    return 1;
  }
}

class EnergyReading {
  final DateTime time;
  final double actual;
  final double predicted;

  const EnergyReading({
    required this.time,
    required this.actual,
    required this.predicted,
  });

  factory EnergyReading.fromJson(Map<String, dynamic> json) => EnergyReading(
        time: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        actual: (json['actual_kwh'] as num?)?.toDouble() ?? 0.0,
        predicted: (json['predicted_kwh'] as num?)?.toDouble() ?? 0.0,
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
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

  // Live data
  ImpactData? _impact;
  List<EnergyReading> _energyHistory = [];
  List<Map<String, dynamic>> _zones = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Weekly bar data derived from energy history
  List<_DailyBar> _weeklyBars = [];

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

    // Use postFrameCallback so context.read<AppState>() is safe
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _treeCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser;

      // ── Step 1: Fetch zones list ────────────────────────────────────────
      List<Map<String, dynamic>> zonesRaw = [];
      try {
        zonesRaw = await appState.zoneService.getZones();
      } catch (_) {}
      _zones = zonesRaw;

      // ── Step 2: Sum real kWh from InfluxDB history across all zones ─────
      // This is the ground-truth savings figure for this week.
      double totalKwhSaved = 0.0;
      List<EnergyReading> allReadings = [];

      if (zonesRaw.isNotEmpty) {
        // Load history for the first zone for the chart; sum all zones for total
        final futures = zonesRaw.map((z) =>
          appState.analyticsService
              .getEnergyHistory(zoneId: z['id'] as String, daysBack: 7)
              .catchError((_) => <Map<String, dynamic>>[]),
        );
        final historyResults = await Future.wait(futures);

        for (int i = 0; i < historyResults.length; i++) {
          final readings = historyResults[i]
              .map((r) => EnergyReading.fromJson(r))
              .toList();
          // First zone → use for chart
          if (i == 0) allReadings = readings;
          // Sum actual kWh saved across all zones
          for (final r in readings) {
            totalKwhSaved += r.actual;
          }
        }
        _energyHistory = allReadings;
        _weeklyBars = _buildWeeklyBars(allReadings);
      } else {
        _weeklyBars = _fallbackWeeklyBars();
      }

      // ── Step 3: If no InfluxDB data, fall back to esg_points estimate ───
      if (totalKwhSaved == 0.0) {
        final esgPoints = user?['esg_points'] as int? ?? 0;
        totalKwhSaved = _esgPointsToKwh(esgPoints);
      }

      // ── Step 4: Get ESG impact metrics from backend ─────────────────────
      Map<String, dynamic> impactRaw = {};
      try {
        impactRaw = await appState.analyticsService
            .getUserImpact(totalKwhSaved);
      } catch (_) {}

      _impact = ImpactData.fromJson(impactRaw);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _barCtrl.forward(from: 0);
          _treeCtrl.forward(from: 0);
        }
      });
    } catch (e) {
      _impact = const ImpactData(
          kwhSaved: 0, rmSaved: 0, co2Kg: 0, treesEquivalent: 0);
      _weeklyBars = _fallbackWeeklyBars();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using cached data · $e',
                style: const TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppTheme.amber,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        _barCtrl.forward(from: 0);
        _treeCtrl.forward(from: 0);
      }
    }
  }

  // Convert esg_points to an approximate kWh saved for the API call
  double _esgPointsToKwh(int points) => points * 0.1;

  List<_DailyBar> _buildWeeklyBars(List<EnergyReading> readings) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<int, double> kwhByWeekday = {};
    for (final r in readings) {
      final wd = r.time.weekday; // 1=Mon … 7=Sun
      kwhByWeekday[wd] = (kwhByWeekday[wd] ?? 0) + r.actual;
    }
    final today = DateTime.now().weekday;
    return List.generate(7, (i) {
      final wd = i + 1;
      return _DailyBar(
        day: dayNames[i],
        kwh: kwhByWeekday[wd] ?? 0.0,
        rm: (kwhByWeekday[wd] ?? 0.0) * 0.509,
        isToday: wd == today,
      );
    });
  }

  List<_DailyBar> _fallbackWeeklyBars() => const [
        _DailyBar(day: 'Mon', kwh: 0, rm: 0, isToday: false),
        _DailyBar(day: 'Tue', kwh: 0, rm: 0, isToday: false),
        _DailyBar(day: 'Wed', kwh: 0, rm: 0, isToday: false),
        _DailyBar(day: 'Thu', kwh: 0, rm: 0, isToday: true),
        _DailyBar(day: 'Fri', kwh: 0, rm: 0, isToday: false),
        _DailyBar(day: 'Sat', kwh: 0, rm: 0, isToday: false),
        _DailyBar(day: 'Sun', kwh: 0, rm: 0, isToday: false),
      ];

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppTheme.textLight),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Retry',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final impact = _impact ??
        const ImpactData(
            kwhSaved: 0, rmSaved: 0, co2Kg: 0, treesEquivalent: 0);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(impact),
            const SizedBox(height: 20),
            _buildImpactHero(impact),
            const SizedBox(height: 20),
            _buildTreeProgress(impact),
            const SizedBox(height: 20),
            _buildWeeklySavings(),
            const SizedBox(height: 20),
            _buildManagerToggle(),
            if (_showManager) ...[
              const SizedBox(height: 16),
              _buildManagerView(impact),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(ImpactData impact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Impact', style: AppTheme.displayLarge.copyWith(fontSize: 26)),
        Row(
          children: [
            // Refresh button
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.iceBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded,
                    size: 16, color: AppTheme.skyBlue),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.mintGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Eco Level ${impact.ecoLevel}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────────
  Widget _buildImpactHero(ImpactData impact) {
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
              Text(
                'RM ${impact.rmSaved.toStringAsFixed(2)}',
                style: const TextStyle(
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
          Text(
            '${impact.kwhSaved.toStringAsFixed(1)} kWh · '
            '${impact.co2Kg.toStringAsFixed(2)} kg CO₂ prevented',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroStat('💡', '${impact.ledHours}h', 'LED powered'),
              _heroDivider(),
              _heroStat('📱', '${impact.phoneCharges}×', 'Phone charges'),
              _heroDivider(),
              _heroStat(
                  '🌳',
                  impact.treesEquivalent.toStringAsFixed(1),
                  'Trees equiv.'),
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

  Widget _heroDivider() => Container(
        width: 1,
        height: 40,
        color: Colors.white.withOpacity(0.25),
      );

  // ── Tree progress ─────────────────────────────────────────────────────────
  Widget _buildTreeProgress(ImpactData impact) {
    final trees = impact.treesEquivalent;
    final goalTrees = 5.0;
    final progress = (trees / goalTrees).clamp(0.0, 1.0);
    final treesInt = trees.floor();
    final treesNeeded = (goalTrees - trees).ceil();

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
                '${trees.toStringAsFixed(1)} / 5 trees',
                style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.mintGreen,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Save enough energy to offset 5 tree-equivalents of CO₂ this month',
            style: AppTheme.bodyMedium.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
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
                        widthFactor: progress * _treeAnim.value,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (i) {
                      final filled = i < treesInt;
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
                    treesNeeded > 0
                        ? '$treesNeeded more tree${treesNeeded > 1 ? 's' : ''} to unlock "EcoMesh Champion" badge!'
                        : '🏆 You\'ve unlocked "EcoMesh Champion"!',
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

  // ── Weekly savings bar chart ───────────────────────────────────────────────
  Widget _buildWeeklySavings() {
    final maxKwh = _weeklyBars.fold(0.0, (m, b) => b.kwh > m ? b.kwh : m);

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
            child: maxKwh == 0
                ? Center(
                    child: Text(
                      'No energy data yet for this week',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textLight),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _weeklyBars.map((bar) {
                      return AnimatedBuilder(
                        animation: _barAnim,
                        builder: (_, __) {
                          final heightFrac = maxKwh > 0
                              ? (bar.kwh / maxKwh) * _barAnim.value
                              : 0.0;
                          return _BarItem(
                            day: bar.day,
                            kwh: bar.kwh,
                            rm: bar.rm,
                            heightFrac: heightFrac,
                            isToday: bar.isToday,
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

  // ── Manager toggle ────────────────────────────────────────────────────────
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

  // ── Manager view ──────────────────────────────────────────────────────────
  Widget _buildManagerView(ImpactData impact) {
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
          Text('Zone Occupancy Heatmap',
              style: AppTheme.headingMedium.copyWith(fontSize: 14)),
          const SizedBox(height: 14),
          _buildHeatmap(),
          const SizedBox(height: 16),
          Text('Predicted vs Actual (This Week)',
              style: AppTheme.headingMedium.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          _buildMiniChart(),
          const SizedBox(height: 16),
          // ESG Report button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.skyBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  content: Text(
                    '📄 ESG Report generated! '
                    'Saving ${impact.co2Kg.toStringAsFixed(2)} kg CO₂ this week.',
                    style: const TextStyle(
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
    // Build from live zones; fall back to placeholder cells if none loaded
    final cells = _zones.isNotEmpty
        ? _zones.map((z) {
            final name = z['name'] as String? ?? 'Zone';
            // No telemetry here; use a neutral color — real intensity
            // comes from telemetry which would be fetched per zone
            return _HeatmapCell(zone: name, level: 0.5);
          }).toList()
        : [
            _HeatmapCell(zone: 'Zone A', level: 0.1),
            _HeatmapCell(zone: 'Zone B', level: 0.85),
            _HeatmapCell(zone: 'Zone C', level: 0.3),
            _HeatmapCell(zone: 'Zone D', level: 0.7),
          ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: cells.map((c) {
        final color = Color.lerp(
            AppTheme.iceBlue, AppTheme.skyBlue, c.level)!;
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  c.zone,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.level > 0.5 ? Colors.white : AppTheme.textMid,
                  ),
                ),
              ),
              Text(
                '${(c.level * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.level > 0.5 ? Colors.white : AppTheme.skyBlue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniChart() {
    if (_energyHistory.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.iceBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'No historical data available yet',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
        ),
      );
    }
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: _MiniChartPainter(readings: _energyHistory),
        size: Size.infinite,
      ),
    );
  }
}

// ─── Helper data classes ──────────────────────────────────────────────────────
class _DailyBar {
  final String day;
  final double kwh;
  final double rm;
  final bool isToday;

  const _DailyBar({
    required this.day,
    required this.kwh,
    required this.rm,
    required this.isToday,
  });
}

class _HeatmapCell {
  final String zone;
  final double level; // 0.0–1.0
  const _HeatmapCell({required this.zone, required this.level});
}

// ─── Bar item ─────────────────────────────────────────────────────────────────
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
            '${kwh.toStringAsFixed(1)}k',
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
    final maxVal =
        readings.fold(0.0, (m, r) => r.actual > m ? r.actual : m);
    if (maxVal == 0) return;

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

    final fillPath = Path();
    final actualPath = Path();
    final predictPath = Path();

    for (int i = 0; i < readings.length; i++) {
      final x = i / (readings.length - 1) * size.width;
      final ay = size.height -
          (readings[i].actual / maxVal) * size.height * 0.85;
      final py = size.height -
          (readings[i].predicted / maxVal) * size.height * 0.85;

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
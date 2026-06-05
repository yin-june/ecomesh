import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../screens/ir_pairing_screen.dart';

// ─── Data models (mirroring backend schemas) ──────────────────────────────────
class ZoneModel {
  final String id;
  final String name;
  final int floorLevel;
  final double baseAcTarget;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.floorLevel,
    required this.baseAcTarget,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) => ZoneModel(
        id: json['id'] as String,
        name: json['name'] as String,
        floorLevel: (json['floor_level'] as num).toInt(),
        baseAcTarget: (json['base_ac_target'] as num?)?.toDouble() ?? 24.0,
      );

  String get floorLabel => 'Level $floorLevel';
}

class ZoneTelemetry {
  final String zoneId;
  final int occupancyCount;
  final double temperature;
  final double targetTemp;
  final double energyDrawKwh;
  final String status; // 'active' | 'idle' | 'ghost' | 'off'

  const ZoneTelemetry({
    required this.zoneId,
    required this.occupancyCount,
    required this.temperature,
    required this.targetTemp,
    required this.energyDrawKwh,
    required this.status,
  });

  factory ZoneTelemetry.fromJson(Map<String, dynamic> json) => ZoneTelemetry(
        zoneId: json['zone_id'] as String,
        occupancyCount: (json['occupancy_count'] as num).toInt(),
        temperature: (json['temperature'] as num).toDouble(),
        targetTemp: (json['target_temp'] as num).toDouble(),
        energyDrawKwh: (json['energy_draw_kwh'] as num).toDouble(),
        status: json['status'] as String? ?? 'idle',
      );

  double get energyDrawWatts => energyDrawKwh * 1000;
  bool get isPrecooling => status == 'ghost';
}

class DeskModel {
  final String id;
  final String zoneId;
  final String label;
  final double xPos;
  final double yPos;
  bool isClaimed;
  int? claimedBy; // user id
  bool isPowered;

  DeskModel({
    required this.id,
    required this.zoneId,
    required this.label,
    required this.xPos,
    required this.yPos,
    required this.isClaimed,
    this.claimedBy,
    required this.isPowered,
  });

  factory DeskModel.fromJson(Map<String, dynamic> json) => DeskModel(
        id: json['id'] as String,
        zoneId: json['zone_id'] as String,
        label: json['label'] as String,
        xPos: (json['x_pos'] as num).toDouble(),
        yPos: (json['y_pos'] as num).toDouble(),
        isClaimed: json['is_claimed'] as bool? ?? false,
        claimedBy: json['claimed_by'] as int?,
        isPowered: json['is_powered'] as bool? ?? false,
      );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Live data
  List<ZoneModel> _zones = [];
  int _selectedZoneIdx = 0;
  // Per-zone telemetry & desks cache
  final Map<String, ZoneTelemetry> _telemetryCache = {};
  final Map<String, List<DeskModel>> _deskCache = {};

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // Use postFrameCallback so context.read<AppState>() is safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadZones();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshTelemetry(),
      );
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Fetch zone list + first zone's telemetry & desks ──────────────────────
  Future<void> _loadZones() async {
    if (!mounted) return;
    try {
      setState(() => _isLoading = true);
      final appState = context.read<AppState>();

      List<Map<String, dynamic>> rawZones = [];
      try {
        rawZones = await appState.zoneService.getZones();
      } catch (e) {
        // DB/network unavailable — show empty state rather than stuck spinner
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not reach backend · $e',
                  style: const TextStyle(fontFamily: 'Nunito')),
              backgroundColor: AppTheme.amber,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      final zones = rawZones.map((z) => ZoneModel.fromJson(z)).toList();

      if (!mounted) return;
      setState(() {
        _zones = zones;
        _selectedZoneIdx = 0;
        _isLoading = false;
        _errorMessage = null;
      });

      if (zones.isNotEmpty) {
        await _loadZoneDetails(zones.first.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load zones: $e';
        });
      }
    }
  }

  Future<void> _loadZoneDetails(String zoneId) async {
    if (!mounted) return;
    final appState = context.read<AppState>();
    try {
      final results = await Future.wait([
        appState.zoneService.getZoneTelemetry(zoneId),
        appState.zoneService.getZoneDesks(zoneId),
      ]);
      final telemetry = ZoneTelemetry.fromJson(
          results[0] as Map<String, dynamic>);
      final desks = (results[1] as List<Map<String, dynamic>>)
          .map((d) => DeskModel.fromJson(d))
          .toList();

      if (!mounted) return;
      setState(() {
        _telemetryCache[zoneId] = telemetry;
        _deskCache[zoneId] = desks;
      });
    } catch (e) {
      // Silently fail — show fallback values
    }
  }

  Future<void> _refreshTelemetry() async {
    if (_zones.isEmpty || !mounted) return;
    final zoneId = _selectedZone?.id;
    if (zoneId != null) await _loadZoneDetails(zoneId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  ZoneModel? get _selectedZone =>
      _zones.isNotEmpty ? _zones[_selectedZoneIdx] : null;

  ZoneTelemetry? _telemetryFor(String zoneId) => _telemetryCache[zoneId];
  List<DeskModel> _desksFor(String zoneId) => _deskCache[zoneId] ?? [];

  Future<void> _onZoneSelected(int idx) async {
    setState(() => _selectedZoneIdx = idx);
    final zone = _zones[idx];
    if (!_telemetryCache.containsKey(zone.id)) {
      await _loadZoneDetails(zone.id);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildFloorView(),
                          _buildListView(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center, style: AppTheme.bodyMedium),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadZones,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text('Zones', style: AppTheme.displayLarge.copyWith(fontSize: 26)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.softMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.mintGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mintGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _loadZones,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.iceBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh_rounded,
                  size: 18, color: AppTheme.skyBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.iceBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppTheme.cardShadow,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w500),
          labelColor: AppTheme.skyBlue,
          unselectedLabelColor: AppTheme.textMid,
          tabs: const [
            Tab(text: 'Floor Map'),
            Tab(text: 'Zone List'),
          ],
        ),
      ),
    );
  }

  // ── Floor view ────────────────────────────────────────────────────────────
  Widget _buildFloorView() {
    if (_zones.isEmpty) {
      return Center(
        child: Text('No zones configured',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight)),
      );
    }

    final zone = _selectedZone!;
    final telemetry = _telemetryFor(zone.id);
    final desks = _desksFor(zone.id);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone selector chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _zones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final z = _zones[i];
                final isSelected = i == _selectedZoneIdx;
                return GestureDetector(
                  onTap: () => _onZoneSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppTheme.skyBlue : AppTheme.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.skyBlue
                            : AppTheme.divider,
                      ),
                      boxShadow: isSelected ? AppTheme.cardShadow : [],
                    ),
                    child: Center(
                      child: Text(
                        z.name,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textMid,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Floor plan
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    child: CustomPaint(painter: _FloorPainter()),
                  ),
                ),
                // Zone label
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      zone.name,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
                // Temp badge (live from telemetry)
                Positioned(
                  top: 14,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.iceBlue,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.paleSky),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.thermostat,
                            size: 12, color: AppTheme.skyBlue),
                        const SizedBox(width: 4),
                        Text(
                          telemetry != null
                              ? '${telemetry.temperature.toStringAsFixed(1)}°C'
                              : '${zone.baseAcTarget.toStringAsFixed(0)}°C',
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.skyBlue),
                        ),
                      ],
                    ),
                  ),
                ),
                // Desk markers
                if (desks.isEmpty)
                  const Center(
                    child: Text('Loading desks…',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppTheme.textLight)),
                  )
                else
                  ...desks.map(
                    (desk) => Positioned(
                      left: desk.xPos *
                          (MediaQuery.of(context).size.width - 80),
                      top: 50 + desk.yPos * 160,
                      child: GestureDetector(
                        onTap: () => _showDeskSheet(desk, zone),
                        child: _DeskMarker(desk: desk),
                      ),
                    ),
                  ),
                // Legend
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _legendDot(AppTheme.mintGreen, 'Claimed & On'),
                      const SizedBox(width: 12),
                      _legendDot(AppTheme.amber, 'Unclaimed but On'),
                      const SizedBox(width: 12),
                      _legendDot(AppTheme.divider, 'Off'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Live zone detail card
          _LiveZoneCard(
            zone: zone,
            telemetry: telemetry,
            desks: desks,
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.bodyMedium.copyWith(fontSize: 10)),
      ],
    );
  }

  void _showDeskSheet(DeskModel desk, ZoneModel zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeskSheet(
        desk: desk,
        zone: zone,
        currentUserId: context.read<AppState>().currentUser?['id'] as int?,
        onUpdate: () => _loadZoneDetails(zone.id),
      ),
    );
  }

  // ── List view ─────────────────────────────────────────────────────────────
  Widget _buildListView() {
    if (_zones.isEmpty) {
      return Center(
        child: Text('No zones configured',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight)),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _zones.length,
      itemBuilder: (_, i) {
        final zone = _zones[i];
        final telemetry = _telemetryFor(zone.id);
        final desks = _desksFor(zone.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _LiveZoneCard(
            zone: zone,
            telemetry: telemetry,
            desks: desks,
          ),
        );
      },
    );
  }
}

// ─── Live Zone Card (replaces ZoneStatusCard for this screen) ─────────────────
class _LiveZoneCard extends StatelessWidget {
  final ZoneModel zone;
  final ZoneTelemetry? telemetry;
  final List<DeskModel> desks;

  const _LiveZoneCard({
    required this.zone,
    required this.telemetry,
    required this.desks,
  });

  @override
  Widget build(BuildContext context) {
    final status = telemetry?.status ?? 'idle';
    final Color statusColor;
    final String statusLabel;
    final Color statusBg;

    switch (status) {
      case 'active':
        statusColor = AppTheme.mintGreen;
        statusBg = AppTheme.softMint;
        statusLabel = 'Active';
        break;
      case 'ghost':
        statusColor = AppTheme.amber;
        statusBg = AppTheme.softAmber;
        statusLabel = 'Ghost Power';
        break;
      case 'idle':
        statusColor = AppTheme.textLight;
        statusBg = AppTheme.background;
        statusLabel = 'Idle';
        break;
      default:
        statusColor = AppTheme.coral;
        statusBg = AppTheme.softCoral;
        statusLabel = 'Off';
    }

    final temp = telemetry?.temperature ?? zone.baseAcTarget;
    final targetTemp = telemetry?.targetTemp ?? zone.baseAcTarget;
    final energyW = (telemetry?.energyDrawKwh ?? 0.0) * 1000;
    final occupancy = telemetry?.occupancyCount ?? 0;
    final claimedDesks = desks.where((d) => d.isClaimed).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: status == 'active' ? AppTheme.paleSky : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: AppTheme.headingMedium.copyWith(fontSize: 15)),
                    Text(zone.floorLabel,
                        style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              // Live indicator dot when loading telemetry
              if (telemetry == null)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              _ZoneStat(
                icon: Icons.thermostat_rounded,
                value: '${temp.toStringAsFixed(1)}°C',
                label: 'Temp',
                color: AppTheme.skyBlue,
              ),
              _statDivider(),
              _ZoneStat(
                icon: Icons.bolt_rounded,
                value: energyW > 0
                    ? '${energyW.toStringAsFixed(0)}W'
                    : '—',
                label: 'Draw',
                color: AppTheme.amber,
              ),
              _statDivider(),
              _ZoneStat(
                icon: Icons.people_rounded,
                value: '$occupancy',
                label: 'People',
                color: AppTheme.mintGreen,
              ),
              _statDivider(),
              _ZoneStat(
                icon: Icons.desk_rounded,
                value: desks.isEmpty
                    ? '—'
                    : '$claimedDesks/${desks.length}',
                label: 'Desks',
                color: AppTheme.lightBlue,
              ),
            ],
          ),
          // Pre-cooling banner
          if (telemetry?.isPrecooling == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.iceBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.paleSky),
              ),
              child: Row(
                children: [
                  const Text('❄️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Pre-cooling active · Target ${targetTemp.toStringAsFixed(0)}°C',
                    style: AppTheme.bodyMedium.copyWith(
                        fontSize: 12,
                        color: AppTheme.skyBlue,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // IR Setup button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => IRPairingScreen(zoneId: zone.id)),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_remote, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('IR Remote Setup',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 36,
        color: AppTheme.divider,
        margin: const EdgeInsets.symmetric(horizontal: 10),
      );
}

class _ZoneStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;

  const _ZoneStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: AppTheme.bodyMedium.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Floor painter ────────────────────────────────────────────────────────────
class _FloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF7FBFF);
    canvas.drawRect(Offset.zero & size, bg);
    final gridPaint = Paint()
      ..color = AppTheme.divider
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Desk marker ──────────────────────────────────────────────────────────────
class _DeskMarker extends StatelessWidget {
  final DeskModel desk;
  const _DeskMarker({required this.desk});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final IconData icon;

    if (desk.isClaimed && desk.isPowered) {
      bg = AppTheme.softMint;
      border = AppTheme.mintGreen;
      icon = Icons.computer_rounded;
    } else if (!desk.isClaimed && desk.isPowered) {
      bg = AppTheme.softAmber;
      border = AppTheme.amber;
      icon = Icons.warning_amber_rounded;
    } else {
      bg = AppTheme.background;
      border = AppTheme.divider;
      icon = Icons.desktop_access_disabled_rounded;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: border.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: border),
          Text(
            desk.label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: border,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Desk bottom sheet ────────────────────────────────────────────────────────
class _DeskSheet extends StatefulWidget {
  final DeskModel desk;
  final ZoneModel zone;
  final int? currentUserId;
  final VoidCallback? onUpdate;

  const _DeskSheet({
    required this.desk,
    required this.zone,
    required this.currentUserId,
    this.onUpdate,
  });

  @override
  State<_DeskSheet> createState() => _DeskSheetState();
}

class _DeskSheetState extends State<_DeskSheet> {
  bool _isBusy = false;

  bool get _isMyClaim =>
      widget.desk.isClaimed &&
      widget.desk.claimedBy == widget.currentUserId;

  bool get _canInteract =>
      !widget.desk.isClaimed || _isMyClaim;

  Future<void> _toggleClaim() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final appState = context.read<AppState>();
    final claiming = !widget.desk.isClaimed;

    try {
      await appState.zoneService.updateDeskClaim(
        widget.zone.id,
        widget.desk.id,
        isClaimed: claiming,
        claimedBy: claiming
            ? widget.currentUserId?.toString()
            : null,
      );

      // Optimistically update local object
      widget.desk.isClaimed = claiming;
      widget.desk.claimedBy = claiming ? widget.currentUserId : null;
      if (claiming) widget.desk.isPowered = true;

      widget.onUpdate?.call();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.mintGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              claiming
                  ? '✅ Desk ${widget.desk.label} claimed! Power active.'
                  : '🔌 Desk ${widget.desk.label} released.',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _togglePower() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final appState = context.read<AppState>();
    final newPowerState = !widget.desk.isPowered;

    try {
      await appState.zoneService.toggleDeskPower(
        widget.zone.id,
        widget.desk.id,
        isPowered: newPowerState,
      );
      widget.desk.isPowered = newPowerState;
      widget.onUpdate?.call();
      if (mounted) setState(() => _isBusy = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Power toggle failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final desk = widget.desk;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.iceBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🖥', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Desk ${desk.label}',
                      style: AppTheme.headingMedium),
                  Text(
                    desk.isClaimed
                        ? _isMyClaim
                            ? 'Claimed by you'
                            : 'Claimed'
                        : 'Available',
                    style: AppTheme.bodyMedium.copyWith(
                      color: desk.isClaimed
                          ? AppTheme.mintGreen
                          : AppTheme.textMid,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoChip(Icons.power_rounded,
                  desk.isPowered ? 'Powered On' : 'Off', desk.isPowered),
              const SizedBox(width: 8),
              _infoChip(Icons.usb_rounded, 'Smart Strip', desk.isPowered),
            ],
          ),
          const SizedBox(height: 20),
          // Claim / release
          if (_canInteract)
            _isBusy
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Claim/Release button
                      GestureDetector(
                        onTap: _toggleClaim,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _isMyClaim
                                ? const LinearGradient(colors: [
                                    AppTheme.coral,
                                    Color(0xFFFF8A8A)
                                  ])
                                : AppTheme.heroGradient,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            boxShadow: AppTheme.elevatedShadow,
                          ),
                          child: Center(
                            child: Text(
                              _isMyClaim
                                  ? 'Release Desk'
                                  : 'Claim This Desk',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Power toggle (only when claimed by me)
                      if (_isMyClaim) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _togglePower,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: desk.isPowered
                                  ? AppTheme.softAmber
                                  : AppTheme.iceBlue,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd),
                              border: Border.all(
                                  color: desk.isPowered
                                      ? AppTheme.amber
                                      : AppTheme.paleSky),
                            ),
                            child: Center(
                              child: Text(
                                desk.isPowered
                                    ? '🔌 Cut Power'
                                    : '⚡ Restore Power',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: desk.isPowered
                                      ? AppTheme.amber
                                      : AppTheme.skyBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.iceBlue,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded,
                      size: 16, color: AppTheme.textMid),
                  SizedBox(width: 8),
                  Text('This desk is claimed by another user',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppTheme.textMid)),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppTheme.iceBlue : AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active ? AppTheme.paleSky : AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: active ? AppTheme.skyBlue : AppTheme.textLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppTheme.skyBlue : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
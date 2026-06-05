import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/ir_pairing_screen.dart';

/// A reusable card to display a zone's status.
/// Accepts either:
///   - [zoneData]: a live Map from the API (id, name, floor_level, base_ac_target)
///   - [telemetry]: optional live telemetry Map (occupancy_count, temperature, energy_draw_kwh, status)
///
/// Falls back to sensible defaults if telemetry is null (loading state).
class ZoneStatusCard extends StatelessWidget {
  /// Raw zone map from GET /api/v1/zones/
  final Map<String, dynamic>? zoneData;

  /// Raw telemetry map from GET /api/v1/zones/{id}/telemetry
  final Map<String, dynamic>? telemetry;

  /// Optional override for the displayed name
  final String? zoneName;

  /// Legacy index — kept for backward compat with DashboardScreen until
  /// that screen is fully updated. Pass null when providing [zoneData].
  final int? zoneIndex;

  const ZoneStatusCard({
    super.key,
    this.zoneData,
    this.telemetry,
    this.zoneName,
    this.zoneIndex,
  }) : assert(zoneData != null || zoneIndex != null,
            'Either zoneData or zoneIndex must be provided');

  // ── Resolved accessors ────────────────────────────────────────────────────
  String get _id => zoneData?['id'] as String? ?? 'zone-$zoneIndex';

  String get _name =>
      zoneName ??
      zoneData?['name'] as String? ??
      'Zone ${(zoneIndex ?? 0) + 1}';

  String get _floorLabel {
    final level = zoneData?['floor_level'] as int?;
    return level != null ? 'Level $level' : 'Level 2';
  }

  double get _baseTemp =>
      (zoneData?['base_ac_target'] as num?)?.toDouble() ?? 24.0;

  // From telemetry (live) or fallback
  String get _status => telemetry?['status'] as String? ?? 'idle';
  double get _temperature =>
      (telemetry?['temperature'] as num?)?.toDouble() ?? _baseTemp;
  double get _energyDrawKwh =>
      (telemetry?['energy_draw_kwh'] as num?)?.toDouble() ?? 0.0;
  int get _occupancyCount =>
      (telemetry?['occupancy_count'] as num?)?.toInt() ?? 0;
  double get _targetTemp =>
      (telemetry?['target_temp'] as num?)?.toDouble() ?? _baseTemp;
  bool get _isPrecooling => _status == 'ghost';
  double get _energyDrawW => _energyDrawKwh * 1000;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    Color statusBg;

    switch (_status) {
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color:
              _status == 'active' ? AppTheme.paleSky : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name,
                        style:
                            AppTheme.headingMedium.copyWith(fontSize: 15)),
                    Text(_floorLabel,
                        style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              // Show spinner while telemetry is loading
              telemetry == null
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                value: '${_temperature.toStringAsFixed(1)}°C',
                label: 'Temp',
                color: AppTheme.skyBlue,
              ),
              _divider(),
              _ZoneStat(
                icon: Icons.bolt_rounded,
                value: _energyDrawW > 0
                    ? '${_energyDrawW.toStringAsFixed(0)}W'
                    : '—',
                label: 'Draw',
                color: AppTheme.amber,
              ),
              _divider(),
              _ZoneStat(
                icon: Icons.people_rounded,
                value: '$_occupancyCount',
                label: 'People',
                color: AppTheme.mintGreen,
              ),
              _divider(),
              _ZoneStat(
                icon: Icons.desk_rounded,
                value: '—',
                label: 'Desks',
                color: AppTheme.lightBlue,
              ),
            ],
          ),
          if (_isPrecooling) ...[
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
                    'Pre-cooling active · Target ${_targetTemp.toStringAsFixed(0)}°C',
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
          // IR Remote Setup button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => IRPairingScreen(zoneId: _id)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_remote,
                      color: Colors.white, size: 16),
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

  Widget _divider() => Container(
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
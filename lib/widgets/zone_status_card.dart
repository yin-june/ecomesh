import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';

class ZoneStatusCard extends StatelessWidget {
  final int zoneIndex;
  const ZoneStatusCard({super.key, required this.zoneIndex});

  @override
  Widget build(BuildContext context) {
    final zone = mockZones[zoneIndex];

    Color statusColor;
    String statusLabel;
    Color statusBg;

    switch (zone.status) {
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
          color: zone.status == 'active'
              ? AppTheme.paleSky
              : AppTheme.divider,
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
                    Text(zone.name,
                        style: AppTheme.headingMedium.copyWith(fontSize: 15)),
                    Text(zone.floor,
                        style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Container(
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
                value: '${zone.temperature}°C',
                label: 'Temp',
                color: AppTheme.skyBlue,
              ),
              _divider(),
              _ZoneStat(
                icon: Icons.bolt_rounded,
                value: '${zone.energyDraw.toInt()}W',
                label: 'Draw',
                color: AppTheme.amber,
              ),
              _divider(),
              _ZoneStat(
                icon: Icons.people_rounded,
                value: '${zone.occupancyCount}',
                label: 'People',
                color: AppTheme.mintGreen,
              ),
              _divider(),
              _ZoneStat(
                icon: Icons.desk_rounded,
                value:
                    '${zone.desks.where((d) => d.isClaimed).length}/${zone.desks.length}',
                label: 'Desks',
                color: AppTheme.lightBlue,
              ),
            ],
          ),
          if (zone.isPrecooling) ...[
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
                    'Pre-cooling active · Target ${zone.targetTemp}°C',
                    style: AppTheme.bodyMedium.copyWith(
                        fontSize: 12,
                        color: AppTheme.skyBlue,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1, height: 36, color: AppTheme.divider,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
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
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
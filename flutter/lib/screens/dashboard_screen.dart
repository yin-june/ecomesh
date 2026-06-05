import 'package:flutter/material.dart' hide Notification;
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/zone_status_card.dart';
import '../widgets/sensor_feed_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _awayMode = false;
  bool _showSensorFeed = false;
  Timer? _timer;
  
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic> _telemetries = {};
  Map<String, dynamic> _impact = {};
  double _totalDrawW = 0.0;
  double _avgTemp = 24.0;
  int _activeZoneCount = 0;
  int _unreadCount = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Refresh data every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final appState = context.read<AppState>();
      
      final zonesRaw = await appState.zoneService.getZones() ?? [];
      final notificationsRaw =
          await appState.notificationService.getNotifications(limit: 5) ?? [];
      
      final unreadCount = await appState.notificationService.getUnreadCount();
          
      // Fetch telemetry for all zones
      final telemetryFutures = zonesRaw.map((z) => 
          appState.zoneService.getZoneTelemetry(z['id'] as String)
              .catchError((_) => <String, dynamic>{})
      );
      final telemetriesRaw = await Future.wait(telemetryFutures);

      final Map<String, dynamic> telemetries = {};
      double totalW = 0.0;
      double sumTemp = 0.0;
      int activeCount = 0;

      for (int i = 0; i < zonesRaw.length; i++) {
        final zId = zonesRaw[i]['id'] as String;
        final tData = telemetriesRaw[i];
        telemetries[zId] = tData;

        final kwh = (tData['energy_draw_kwh'] as num?)?.toDouble() ?? 0.0;
        totalW += kwh * 1000;
        final temp = (tData['temperature'] as num?)?.toDouble() ?? 24.0;
        sumTemp += temp;
        
        final status = tData['status'] as String? ?? 'idle';
        if (status == 'active' || status == 'ghost') {
          activeCount++;
        }
      }
      
      double avgTemp = zonesRaw.isNotEmpty ? sumTemp / zonesRaw.length : 24.0;

      // Quick estimate for impact
      final user = appState.currentUser;
      final esgPoints = user?.esgPoints ?? 0;
      final double kwhBasis = esgPoints * 0.1;
      
      Map<String, dynamic> impactRaw = {};
      try {
        impactRaw = await appState.analyticsService.getUserImpact(kwhBasis);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _zones = zonesRaw;
          _notifications = notificationsRaw;
          _telemetries = telemetries;
          _totalDrawW = totalW;
          _avgTemp = avgTemp;
          _activeZoneCount = activeCount;
          _unreadCount = unreadCount;
          _impact = impactRaw;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleAway() {
    setState(() => _awayMode = !_awayMode);
    if (!_awayMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.mintGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: const Text(
            '🌿 Welcome back! Lights restored to 100%.',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, _) {
      final userName = appState.currentUser?.fullName ?? 'User';

      return SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(userName, _unreadCount, appState),
                const SizedBox(height: 20),
                _buildStatusBanner(),
                if (_showSensorFeed) ...[
                  const SizedBox(height: 20),
                  const SensorFeedWidget(),
                ],
                const SizedBox(height: 20),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Error loading data: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else ...[
                  _buildQuickStats(),
                  const SizedBox(height: 20),
                  _buildActiveZonesList(),
                  const SizedBox(height: 20),
                  _buildNotificationsSection(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(String userName, int unreadCount, AppState appState) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: AppTheme.bodyMedium.copyWith(fontSize: 13),
              ),
              Text(
                userName.split(' ').first,
                style: AppTheme.displayLarge.copyWith(fontSize: 26),
              ),
            ],
          ),
        ),
        // Notification bell
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                _showNotificationsSheet(appState);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textMid,
                  size: 22,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _awayMode
            ? const LinearGradient(
                colors: [Color(0xFFFFB84D), Color(0xFFFFD480)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _awayMode
                            ? Colors.white
                            : Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _awayMode ? 'AWAY MODE' : 'ACTIVE',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${_avgTemp.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _awayMode
                ? 'Away Mode Active\nLights dimmed to 30%'
                : _activeZoneCount == 0
                    ? 'No zones active'
                    : 'Zones Active\n$_activeZoneCount zone(s) consuming power',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statChip(
                icon: Icons.bolt_rounded,
                label: _awayMode ? '0.3kWh/h' : '${_totalDrawW.toStringAsFixed(0)}W draw',
              ),
              const SizedBox(width: 8),
              _statChip(
                icon: Icons.place_outlined,
                label: 'Zone Control',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleAway,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _awayMode ? "I'm back!" : 'Activate Away Mode',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          _awayMode ? Color(0xFFFFB84D) : AppTheme.skyBlue,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showSensorFeed = !_showSensorFeed),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Icon(
                    _showSensorFeed
                        ? Icons.expand_less_rounded
                        : Icons.sensors_rounded,
                    color: _showSensorFeed ? AppTheme.skyBlue : AppTheme.textMid,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final double rmSavedWeek = (_impact['rm_saved'] as num?)?.toDouble() ?? 0.0;
    final double treesSaved = (_impact['trees_equivalent'] as num?)?.toDouble() ?? 0.0;
    
    // Approximate daily savings from weekly estimate
    final double rmSavedToday = rmSavedWeek / 7;

    return Row(
      children: [
        _StatCard(
          label: "Avg Daily Saving",
          value: 'RM${rmSavedToday.toStringAsFixed(2)}',
          sub: 'Based on weekly',
          icon: '💰',
          color: AppTheme.textDark,
          bgColor: AppTheme.iceBlue,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Trees Saved',
          value: treesSaved.toStringAsFixed(1),
          sub: 'Equiv. offsets',
          icon: '🌳',
          color: AppTheme.textDark,
          bgColor: AppTheme.iceBlue,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Active Zones',
          value: '$_activeZoneCount',
          sub: 'Running now',
          icon: '📡',
          color: AppTheme.textDark,
          bgColor: AppTheme.iceBlue,
        ),
      ],
    );
  }

  Widget _buildActiveZonesList() {
    if (_zones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.iceBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.paleSky),
        ),
        child: Center(
          child: Text(
            'No zones available',
            style: AppTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Zones', style: AppTheme.headingMedium),
        const SizedBox(height: 12),
        ..._zones.asMap().entries.map((entry) {
          final index = entry.key;
          final zone = entry.value;
          final telemetry = _telemetries[zone['id'] as String];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ZoneStatusCard(
              zoneIndex: index,
              zoneData: zone,
              telemetry: telemetry,
              zoneName: zone['name'] as String?,
            ),
          );
        }),
      ],
    );
  }

  void _showNotificationsSheet(AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.paleSky,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: AppTheme.headingMedium),
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: () async {
                      await appState.notificationService.markAllAsRead();
                      _loadData();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(
                      'Mark all as read',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.skyBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotifItem(_notifications[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTheme.headingMedium),
            Text(
              'See all',
              style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.skyBlue, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_notifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.iceBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No notifications yet',
                style: AppTheme.bodyMedium,
              ),
            ),
          )
        else
          ..._notifications.map((notif) => _buildNotifItem(notif)).toList(),
      ],
    );
  }

  Widget _buildNotifItem(Map<String, dynamic> notif) {
    final icons = {
      'arrival': '🏢',
      'saving': '💡',
      'warning': '⚠️',
      'summary': '📊',
    };
    final colors = {
      'arrival': AppTheme.skyBlue,
      'saving': AppTheme.mintGreen,
      'warning': AppTheme.amber,
      'summary': AppTheme.lightBlue,
    };

    final type = notif['type'] ?? 'summary';
    final title = notif['title'] ?? 'Notification';
    final body = notif['body'] ?? '';
    final isRead = notif['is_read'] ?? false;
    final notifId = notif['id'] as String?;

    return GestureDetector(
      onTap: () async {
        if (!isRead && notifId != null) {
          final appState = context.read<AppState>();
          await appState.notificationService.markAsRead(notifId);
          _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
        color: isRead ? AppTheme.white : AppTheme.iceBlue,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isRead ? AppTheme.divider : AppTheme.paleSky,
        ),
        boxShadow: isRead ? [] : AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (colors[type] ?? AppTheme.skyBlue).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                icons[type] ?? '📢',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
     ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
  final String label, value, sub, icon;
  final Color color, bgColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                  child: Text(icon,
                      style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              sub,
              style: AppTheme.bodyMedium.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color, bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
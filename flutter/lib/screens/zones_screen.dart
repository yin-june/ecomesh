import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/zone_status_card.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen>
    with SingleTickerProviderStateMixin {
  int _selectedZoneIdx = 1;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
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
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w500),
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

  Widget _buildFloorView() {
    final zone = mockZones[_selectedZoneIdx];
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
              itemCount: mockZones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final z = mockZones[i];
                final isSelected = i == _selectedZoneIdx;
                return GestureDetector(
                  onTap: () => setState(() => _selectedZoneIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.skyBlue : AppTheme.white,
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
                // Room background
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    child: CustomPaint(
                      painter: _FloorPainter(),
                    ),
                  ),
                ),
                // Zone label and Calibration Button
                Positioned(
                  top: 14,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          try {
                            // In real deployment, this uses GetIt or Provider to grab ZoneService
                            // final zoneService = locator<ZoneService>();
                            // await zoneService.triggerAutoCalibration(zone.id);
                          } catch (e) {
                            // Ignore error for mock
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.mintGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: const Text(
                                '🎯 Auto-Calibration started! Please leave the room for 15 seconds.',
                                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.amber,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.radar_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Calibrate',
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Temp badge
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
                    child: 
                    Row(
                      children: [
                        Icon(
                          Icons.thermostat,
                          size: 12,
                          color: AppTheme.skyBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${zone.temperature}°C',
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
                ...zone.desks.map(
                  (desk) => Positioned(
                    left: desk.x *
                        (MediaQuery.of(context).size.width - 80),
                    top: 50 + desk.y * 160,
                    child: GestureDetector(
                      onTap: () => _showDeskSheet(desk),
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
                      _legendDot(
                          AppTheme.amber, 'Unclaimed but On'),
                      const SizedBox(width: 12),
                      _legendDot(AppTheme.divider, 'Off'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Zone detail card
          ZoneStatusCard(zoneIndex: _selectedZoneIdx),
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
        Text(label,
            style:
                AppTheme.bodyMedium.copyWith(fontSize: 10)),
      ],
    );
  }

  void _showDeskSheet(Desk desk) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeskSheet(
        desk: desk,
        onUpdate: () => setState(() {}),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: mockZones.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ZoneStatusCard(zoneIndex: i),
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
  final Desk desk;
  const _DeskMarker({required this.desk});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;

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
  final Desk desk;
  final VoidCallback? onUpdate;
  const _DeskSheet({required this.desk, this.onUpdate});

  @override
  State<_DeskSheet> createState() => _DeskSheetState();
}

class _DeskSheetState extends State<_DeskSheet> {
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _claimed = widget.desk.isClaimed &&
        widget.desk.claimedBy == 'Ahmad Fariz';
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
                  Text(
                    'Desk ${desk.label}',
                    style: AppTheme.headingMedium,
                  ),
                  Text(
                    desk.isClaimed
                        ? 'Claimed by ${desk.claimedBy}'
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
              _infoChip(
                  Icons.usb_rounded, 'Smart Strip', desk.isPowered),
            ],
          ),
          const SizedBox(height: 20),
          if (!desk.isClaimed || desk.claimedBy == 'Ahmad Fariz')
            GestureDetector(
              onTap: () {
                setState(() => _claimed = !_claimed);
                
                // Update the actual desk object
                desk.isClaimed = _claimed;
                if (_claimed) {
                  desk.claimedBy = 'Ahmad Fariz';
                  desk.isPowered = true;
                } else {
                  desk.claimedBy = '';
                }
                
                // Trigger parent rebuild
                widget.onUpdate?.call();
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.mintGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    content: Text(
                      _claimed
                          ? '✅ Desk ${desk.label} claimed! Power active.'
                          : '🔌 Desk ${desk.label} released.',
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _claimed
                      ? const LinearGradient(
                          colors: [AppTheme.coral, Color(0xFFFF8A8A)])
                      : AppTheme.heroGradient,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Center(
                  child: Text(
                    _claimed ? 'Release Desk' : 'Claim This Desk',
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool active) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppTheme.iceBlue : AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppTheme.paleSky : AppTheme.divider,
        ),
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
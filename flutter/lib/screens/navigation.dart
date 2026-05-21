import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'zones_screen.dart';
import 'impact_screen.dart';
import 'profile_screen.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _tab = 0;

  final _tabs = const [
    DashboardScreen(),
    ZonesScreen(),
    ImpactScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.skyBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Zones',
                index: 1,
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              _NavItem(
                icon: Icons.eco_rounded,
                label: 'Impact',
                index: 2,
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                selected: _tab == 3,
                onTap: () => setState(() => _tab = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.skyBlue.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppTheme.skyBlue : AppTheme.textLight,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.skyBlue : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _gpsEnabled = true;
  bool _bluetoothEnabled = true;
  bool _pushNotifications = true;
  String _selectedPreset = 'Deep Work';
  double _tempPref = 24.0;

  final presets = ['Deep Work', 'Meeting', 'Study', 'Eco Max'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, _) {
      final user = appState.currentUser;
      final userName = user?['full_name'] ?? 'User';
      final userEmail = user?['email'] ?? 'user@example.com';

      return SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile',
                  style:
                      AppTheme.displayLarge.copyWith(fontSize: 26)),
              const SizedBox(height: 20),
              _buildProfileCard(userName, userEmail),
              const SizedBox(height: 20),
              _buildPresetsSection(),
              const SizedBox(height: 20),
              _buildTempSection(),
              const SizedBox(height: 20),
              _buildPermissionsSection(),
              const SizedBox(height: 20),
              _buildSettingsSection(appState),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProfileCard(String userName, String userEmail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection() {
    return _SectionCard(
      title: 'Energy Presets',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              final isSelected = preset == _selectedPreset;
              return GestureDetector(
                onTap: () => setState(() => _selectedPreset = preset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.heroGradient : null,
                    color: isSelected ? null : AppTheme.iceBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.skyBlue
                          : AppTheme.divider,
                    ),
                    boxShadow: isSelected ? AppTheme.cardShadow : [],
                  ),
                  child: Text(
                    preset,
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTempSection() {
    return _SectionCard(
      title: 'Temperature Preference', 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_tempPref.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.skyBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.iceBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tempPref <= 23
                      ? '❄️ Cool'
                      : _tempPref <= 25
                          ? '✅ Comfort'
                          : '☀️ Warm',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.skyBlue,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.skyBlue,
              inactiveTrackColor: AppTheme.iceBlue,
              thumbColor: AppTheme.skyBlue,
              overlayColor: AppTheme.skyBlue.withOpacity(0.1),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _tempPref,
              min: 20,
              max: 28,
              divisions: 16,
              onChanged: (v) => setState(() => _tempPref = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('20°C',
                  style:
                      AppTheme.bodyMedium.copyWith(fontSize: 11)),
              Text('28°C',
                  style:
                      AppTheme.bodyMedium.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return _SectionCard(
      title: 'Permissions',
      child: Column(
        children: [
          _ToggleRow(
            icon: '📍',
            title: 'GPS Geofencing',
            subtitle: 'Triggers pre-cooling on arrival',
            value: _gpsEnabled,
            onChanged: (v) => setState(() => _gpsEnabled = v),
          ),
          const Divider(color: AppTheme.divider, height: 1),
          _ToggleRow(
            icon: '📡',
            title: 'Bluetooth Mesh',
            subtitle: 'Room-level desk detection',
            value: _bluetoothEnabled,
            onChanged: (v) => setState(() => _bluetoothEnabled = v),
          ),
          const Divider(color: AppTheme.divider, height: 1),
          _ToggleRow(
            icon: '🔔',
            title: 'Push Notifications',
            subtitle: 'Arrival, away, and session alerts',
            value: _pushNotifications,
            onChanged: (v) =>
                setState(() => _pushNotifications = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(AppState appState) {
    return _SectionCard(
      title: 'App Settings',
      child: Column(
        children: [
          _MenuRow(
              icon: '🏢', label: 'My Building', subtitle: 'Tower A, Level 2'),
          const Divider(color: AppTheme.divider, height: 1),
          _MenuRow(
              icon: '📊',
              label: 'Data & Privacy',
              subtitle: 'Manage your sensor data'),
          const Divider(color: AppTheme.divider, height: 1),
          _MenuRow(
              icon: '🆘',
              label: 'Support',
              subtitle: 'Report an issue or get help'),
          const Divider(color: AppTheme.divider, height: 1),
          _MenuRow(
              icon: 'ℹ️',
              label: 'About EcoMesh',
              subtitle: 'v1.0.0 · Hackathon Build'),
          const Divider(color: AppTheme.divider, height: 1),
          GestureDetector(
            onTap: () async {
              await appState.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  const Text('🚪', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sign Out',
                            style:
                                AppTheme.headingMedium.copyWith(fontSize: 13)),
                        Text('Logout from your account',
                            style:
                                AppTheme.bodyMedium.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppTheme.textLight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Text(title, style: AppTheme.headingMedium.copyWith(fontSize: 15)),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String icon, title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.headingMedium.copyWith(fontSize: 13)),
                Text(subtitle,
                    style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.skyBlue,
            activeTrackColor: AppTheme.paleSky,
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String icon, label, subtitle;
  const _MenuRow(
      {required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        AppTheme.headingMedium.copyWith(fontSize: 13)),
                Text(subtitle,
                    style:
                        AppTheme.bodyMedium.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textLight, size: 20),
        ],
      ),
    );
  }
}
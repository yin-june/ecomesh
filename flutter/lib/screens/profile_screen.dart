import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _gpsEnabled = true;
  bool _bluetoothEnabled = true;
  bool _pushNotifications = true;

  // Local mirror of appState values — initialised in didChangeDependencies
  late double _tempPref;
  late String _selectedPreset;
  bool _localInitialized = false;

  final presets = ['Deep Work', 'Meeting', 'Study', 'Eco Max'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialise local copies once from AppState (avoids overwriting mid-drag)
    if (!_localInitialized) {
      final appState = context.read<AppState>();
      _tempPref = appState.tempPref;
      _selectedPreset = appState.selectedPreset;
      _localInitialized = true;
    }
  }

  /// Persist to backend + show feedback snackbar
  Future<void> _saveProfile(AppState appState) async {
    final ok = await appState.saveEnergyProfile(
      profileName: _selectedPreset,
      preferredTemp: _tempPref,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? '✅ Profile saved' : '⚠️ Saved locally (offline)',
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
        ),
        backgroundColor: ok ? AppTheme.skyBlue : Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, _) {
      final user = appState.currentUser;

      return SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile',
                  style: AppTheme.displayLarge.copyWith(fontSize: 26)),
              const SizedBox(height: 20),
              _buildProfileCard(user),
              const SizedBox(height: 20),
              _buildEsgCard(user),
              const SizedBox(height: 20),
              _buildPresetsSection(appState),
              const SizedBox(height: 20),
              _buildTempSection(appState),
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

  // ─── Profile Card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard(UserModel? user) {
    final userName = user?.fullName ?? 'User';
    final userEmail = user?.email ?? 'user@example.com';

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

  // ─── ESG Points Card ───────────────────────────────────────────────────────
  Widget _buildEsgCard(UserModel? user) {
    final points = user?.esgPoints ?? 0;
    final tier = points >= 500
        ? ('🌟 Platinum', AppTheme.skyBlue)
        : points >= 200
            ? ('🥇 Gold', const Color(0xFFDAA520))
            : points >= 50
                ? ('🥈 Silver', const Color(0xFF9E9E9E))
                : ('🌱 Starter', const Color(0xFF66BB6A));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Points circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Text(
                '$points',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESG Impact Points',
                  style: AppTheme.headingMedium.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Earned by saving energy and reducing emissions',
                  style: AppTheme.bodyMedium.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tier.$2.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tier.$2.withOpacity(0.4)),
            ),
            child: Text(
              tier.$1,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tier.$2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Presets Section ───────────────────────────────────────────────────────
  Widget _buildPresetsSection(AppState appState) {
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
                onTap: () {
                  setState(() => _selectedPreset = preset);
                  _saveProfile(appState);
                },
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

  // ─── Temperature Section ───────────────────────────────────────────────────
  Widget _buildTempSection(AppState appState) {
    final isSaving = appState.isSavingProfile;

    return _SectionCard(
      title: 'Temperature Preference',
      trailing: isSaving
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.skyBlue),
            )
          : null,
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
              // Update UI in real time while dragging
              onChanged: (v) => setState(() => _tempPref = v),
              // Save to backend only when the user releases the slider
              onChangeEnd: (v) {
                setState(() => _tempPref = v);
                _saveProfile(appState);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('20°C',
                  style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
              Text('28°C',
                  style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-applied when you claim a desk via Bluetooth.',
            style: AppTheme.bodyMedium.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ─── Permissions Section ───────────────────────────────────────────────────
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

  // ─── App Settings Section ──────────────────────────────────────────────────
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

// ─── Shared Widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
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
              Text(title,
                  style: AppTheme.headingMedium.copyWith(fontSize: 15)),
              const Spacer(),
              if (trailing != null) trailing!,
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
                    style: AppTheme.headingMedium.copyWith(fontSize: 13)),
                Text(subtitle,
                    style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
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
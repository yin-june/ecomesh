import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool _showOnboarding = false;
  int _selectedPersona = 0;

  final personas = [
    {
      'title': 'Deep Worker',
      'icon': Icons.headphones_rounded,
      'desc': '24°C · 2-min standby · Focus lighting',
    },
    {
      'title': 'Eco-Warrior',
      'icon': Icons.eco_rounded,
      'desc': '26°C · 1-min standby · Max savings',
    },
    {
      'title': 'Standard Admin',
      'icon': Icons.work_outline_rounded,
      'desc': '25°C · 5-min standby · Balanced mode',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeCtrl.forward();
      _slideCtrl.forward();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showOnboarding = true);
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const Navigation(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showOnboarding ? _buildOnboarding() : _buildSplash(),
      ),
    );
  }

  Widget _buildSplash() {
    return Container(
      key: const ValueKey('splash'),
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'EcoMesh',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Personal Energy Shadow',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(
                        Colors.white.withOpacity(0.6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboarding() {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'EcoMesh',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Choose your\nenergy persona',
                style: AppTheme.displayLarge.copyWith(
                    fontSize: 24, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'This sets your default comfort & saving preferences.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ...List.generate(
                  personas.length, (i) => _buildPersonaCard(i)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.iceBlue,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.paleSky, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppTheme.skyBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'EcoMesh needs GPS & Bluetooth for seamless zone detection.',
                        style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _continue,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaCard(int index) {
    final p = personas[index];
    final isSelected = _selectedPersona == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPersona = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.iceBlue : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.skyBlue : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.skyBlue.withOpacity(0.12)
                    : AppTheme.surfaceGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                p['icon'] as IconData,
                color: isSelected ? AppTheme.skyBlue : AppTheme.textLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['title'] as String,
                      style: AppTheme.headingMedium.copyWith(fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(p['desc'] as String,
                      style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.skyBlue : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? AppTheme.skyBlue : AppTheme.textLight,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
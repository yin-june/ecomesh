import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';

import 'package:provider/provider.dart';
import '../services/app_state.dart';

class IRPairingScreen extends StatefulWidget {
  final String zoneId;
  const IRPairingScreen({super.key, required this.zoneId});

  @override
  State<IRPairingScreen> createState() => _IRPairingScreenState();
}

class _IRPairingScreenState extends State<IRPairingScreen> {
  int _currentStep = 0;
  bool _isListening = false;
  bool _success = false;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Power ON',
      'desc': 'Point your remote at the hub and press the Power button.',
      'icon': Icons.power_settings_new,
    },
    {
      'title': 'Set to 23°C',
      'desc': 'Adjust your remote to 23°C and press the temperature button.',
      'icon': Icons.thermostat,
    },
    {
      'title': 'Set to 25°C',
      'desc': 'Adjust your remote to 25°C and press the temperature button.',
      'icon': Icons.thermostat,
    },
    {
      'title': 'Power OFF',
      'desc': 'Press the Power button again to turn off.',
      'icon': Icons.power_settings_new,
    },
  ];

  void _startListening() {
    setState(() {
      _isListening = true;
    });
    
    // Simulate API call to backend to enter "Learning Mode"
    // and wait for an IR pulse from the ESP32 Hub.
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _success = true;
        });
        
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _success = false;
              if (_currentStep < _steps.length - 1) {
                _currentStep++;
              } else {
                _showCompletionDialog();
              }
            });
          }
        });
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Setup Complete!', style: AppTheme.headingMedium),
        content: const Text('Zone has successfully learned your AC remote commands.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Done', style: TextStyle(color: AppTheme.skyBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        title: Text(
          'IR Remote Setup',
          style: AppTheme.headingMedium,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            // Main Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _success ? AppTheme.softMint : (_isListening ? AppTheme.iceBlue : AppTheme.white),
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
                border: Border.all(
                  color: _success ? AppTheme.mintGreen : (_isListening ? AppTheme.skyBlue : Colors.transparent),
                  width: 3,
                )
              ),
              child: Center(
                child: Icon(
                  _success ? Icons.check_circle : Icons.settings_remote,
                  size: 50,
                  color: _success ? AppTheme.mintGreen : AppTheme.skyBlue,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Record IR Signal',
              style: AppTheme.displayLarge.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Point your AC remote at the hub and press any button to record the signal.',
              style: AppTheme.bodyMedium.copyWith(fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (_isListening)
              Column(
                children: [
                  CircularProgressIndicator(color: AppTheme.skyBlue),
                  const SizedBox(height: 20),
                  Text("Listening for IR signal...", style: AppTheme.bodyMedium),
                ],
              )
            else
              GestureDetector(
                onTap: _startListening,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: const Center(
                    child: Text(
                      'Start Listening',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

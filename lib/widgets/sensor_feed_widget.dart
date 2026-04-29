import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../theme/app_theme.dart';

class SensorFeedWidget extends StatefulWidget {
  const SensorFeedWidget({super.key});

  @override
  State<SensorFeedWidget> createState() => _SensorFeedWidgetState();
}

class _SensorFeedWidgetState extends State<SensorFeedWidget> {
  final List<double> _breathPeaks = List.generate(30, (i) => 0.0);
  final Random _rand = Random();
  Timer? _timer;
  bool _occupied = true;
  double _lastPeak = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      setState(() {
        final newVal = _occupied
            ? 0.3 + _rand.nextDouble() * 0.7
            : _rand.nextDouble() * 0.08;
        _breathPeaks.removeAt(0);
        _breathPeaks.add(newVal);
        _lastPeak = newVal;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.textDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.mintGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'mmWave Radar · Live Feed',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mintGreen,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _occupied = !_occupied),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _occupied ? 'Simulate Exit' : 'Simulate Entry',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 70,
            child: CustomPaint(
              painter: _WavePainter(peaks: _breathPeaks),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _sensorChip('Occupancy',
                  _occupied ? '✅ Detected' : '❌ Empty',
                  _occupied ? AppTheme.mintGreen : AppTheme.coral),
              const SizedBox(width: 8),
              _sensorChip(
                  'Signal',
                  '${(_lastPeak * 100).toStringAsFixed(1)}%',
                  AppTheme.skyBlue),
              const SizedBox(width: 8),
              _sensorChip('Node', 'B-01 · 5ms', AppTheme.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sensorChip(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              val,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> peaks;
  const _WavePainter({required this.peaks});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Grid
    for (double y = 0; y < size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (peaks.isEmpty) return;

    final linePaint = Paint()
      ..color = AppTheme.mintGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.mintGreen.withOpacity(0.3),
          AppTheme.mintGreen.withOpacity(0.0),
        ],
      ).createShader(Offset.zero & size);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < peaks.length; i++) {
      final x = i / (peaks.length - 1) * size.width;
      final y = size.height - peaks[i] * size.height * 0.85;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Dot at end
    final dotPaint = Paint()..color = AppTheme.mintGreen;
    canvas.drawCircle(
      Offset(
        size.width,
        size.height - peaks.last * size.height * 0.85,
      ),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.peaks != peaks;
}
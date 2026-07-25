import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Soft gradient background with decorative waves and orbit rings.
class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFDFBFF),
                Color(0xFFF5FAF6),
                Color(0xFFF8F4FF),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: _GlowOrb(
            size: 220,
            colors: [
              AppColors.paleLavender.withValues(alpha: 0.85),
              AppColors.softBlue.withValues(alpha: 0.15),
            ],
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: _GlowOrb(
            size: 260,
            colors: [
              AppColors.softMint.withValues(alpha: 0.9),
              AppColors.mintGreen.withValues(alpha: 0.12),
            ],
          ),
        ),
        Positioned(
          bottom: 120,
          right: -40,
          child: _GlowOrb(
            size: 140,
            colors: [
              AppColors.lavender.withValues(alpha: 0.7),
              AppColors.deepPurple.withValues(alpha: 0.08),
            ],
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _WavePatternPainter(),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _OrbitRingsPainter(),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 180,
          child: CustomPaint(
            painter: _BottomWavePainter(),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.deepPurple.withValues(alpha: 0.06);

    final path = Path();
    for (var i = 0; i < 3; i++) {
      path.reset();
      final y = size.height * (0.35 + i * 0.08);
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 8) {
        path.lineTo(
          x,
          y + math.sin((x / size.width) * math.pi * 2 + i) * 12,
        );
      }
      canvas.drawPath(path, paint);
    }

    final dotPaint = Paint()
      ..color = AppColors.deepPurple.withValues(alpha: 0.04);
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 6; col++) {
        canvas.drawCircle(
          Offset(20 + col * 18, 30 + row * 18),
          1.2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrbitRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.28);
    for (var i = 0; i < 3; i++) {
      final radius = 70.0 + i * 28;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.deepPurple.withValues(alpha: 0.05 - i * 0.01);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.15,
        size.width * 0.5,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.55,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepPurple.withValues(alpha: 0.08),
            AppColors.teal.withValues(alpha: 0.12),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ParticlesLayer extends StatelessWidget {
  const ParticlesLayer({
    super.key,
    required this.animation,
  });

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlesPainter(progress: animation.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.phase,
    required this.speed,
    required this.isStar,
  });

  final double baseX;
  final double baseY;
  final double radius;
  final double phase;
  final double speed;
  final bool isStar;
}

const _particles = [
  _Particle(baseX: 0.12, baseY: 0.18, radius: 2.2, phase: 0.0, speed: 1.0, isStar: true),
  _Particle(baseX: 0.78, baseY: 0.12, radius: 1.8, phase: 1.2, speed: 0.8, isStar: true),
  _Particle(baseX: 0.88, baseY: 0.28, radius: 2.5, phase: 2.1, speed: 1.1, isStar: false),
  _Particle(baseX: 0.08, baseY: 0.42, radius: 1.6, phase: 0.7, speed: 0.9, isStar: false),
  _Particle(baseX: 0.92, baseY: 0.52, radius: 2.0, phase: 3.0, speed: 1.2, isStar: true),
  _Particle(baseX: 0.22, baseY: 0.08, radius: 1.4, phase: 1.8, speed: 0.7, isStar: false),
  _Particle(baseX: 0.65, baseY: 0.06, radius: 2.1, phase: 2.5, speed: 1.0, isStar: true),
  _Particle(baseX: 0.35, baseY: 0.22, radius: 1.5, phase: 0.4, speed: 0.85, isStar: false),
  _Particle(baseX: 0.52, baseY: 0.14, radius: 1.9, phase: 1.5, speed: 0.95, isStar: true),
  _Particle(baseX: 0.15, baseY: 0.55, radius: 1.3, phase: 2.8, speed: 0.75, isStar: false),
];

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final t = progress * math.pi * 2 * particle.speed + particle.phase;
      final dx = math.sin(t) * 18 + math.cos(t * 0.7) * 8;
      final dy = math.cos(t * 0.9) * 14 + math.sin(t * 1.1) * 6;
      final opacity = 0.25 + (math.sin(t * 1.3) + 1) * 0.2;

      final center = Offset(
        particle.baseX * size.width + dx,
        particle.baseY * size.height + dy,
      );

      if (particle.isStar) {
        _drawStar(canvas, center, particle.radius, opacity);
      } else {
        final glowPaint = Paint()
          ..color = AppColors.softBlue.withValues(alpha: opacity * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(center, particle.radius * 2.5, glowPaint);

        canvas.drawCircle(
          center,
          particle.radius,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, double opacity) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + math.cos(angle) * radius * 2.2,
        center.dy + math.sin(angle) * radius * 2.2,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.deepPurple.withValues(alpha: opacity * 0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center,
      radius * 0.6,
      Paint()..color = Colors.white.withValues(alpha: opacity * 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Compass logo — uses asset if available, otherwise custom paint fallback.
class CompassLogo extends StatelessWidget {
  const CompassLogo({
    super.key,
    required this.scale,
    required this.rotation,
  });

  final double scale;
  final double rotation;

  static const _assetPath = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: rotation,
        child: SizedBox(
          width: 88,
          height: 88,
          child: Image.asset(
            _assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const CustomPaint(
              painter: _CompassLogoPainter(),
              size: Size(88, 88),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassLogoPainter extends CustomPainter {
  const _CompassLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = SweepGradient(
        colors: const [
          AppColors.vibrantGreen,
          AppColors.softBlue,
          AppColors.deepPurple,
          AppColors.vibrantGreen,
        ],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, ringPaint);

    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final tip = Offset(
        center.dx + math.cos(angle) * (radius + 8),
        center.dy + math.sin(angle) * (radius + 8),
      );
      final base1 = Offset(
        center.dx + math.cos(angle + 0.35) * (radius - 2),
        center.dy + math.sin(angle + 0.35) * (radius - 2),
      );
      final base2 = Offset(
        center.dx + math.cos(angle - 0.35) * (radius - 2),
        center.dy + math.sin(angle - 0.35) * (radius - 2),
      );

      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(base1.dx, base1.dy)
          ..lineTo(base2.dx, base2.dy)
          ..close(),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: i.isEven
                ? [AppColors.vibrantGreen, AppColors.forestGreen]
                : [AppColors.softBlue, AppColors.deepPurple],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final leafCenter = center + const Offset(0, 6);
    _drawLeaf(
      canvas,
      leafCenter + const Offset(-10, 2),
      -0.35,
      AppColors.vibrantGreen,
    );
    _drawLeaf(
      canvas,
      leafCenter + const Offset(10, 2),
      0.35,
      AppColors.deepPurple,
    );

    canvas.drawCircle(
      leafCenter + const Offset(0, -14),
      5,
      Paint()..color = AppColors.vibrantGreen,
    );
  }

  void _drawLeaf(Canvas canvas, Offset origin, double rotation, Color color) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -16)
      ..quadraticBezierTo(14, -4, 0, 18)
      ..quadraticBezierTo(-14, -4, 0, -16)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.75)],
        ).createShader(const Rect.fromLTWH(-16, -16, 32, 36)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

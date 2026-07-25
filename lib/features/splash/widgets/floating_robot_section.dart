import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class FloatingRobotSection extends StatelessWidget {
  const FloatingRobotSection({
    super.key,
    required this.floatOffset,
    required this.orbitAngle,
  });

  final double floatOffset;
  final double orbitAngle;

  static const _robotAsset = 'assets/images/robot.png';

  static const _foodItems = [
    _FoodItem(asset: 'assets/images/food_avocado.png', emoji: '🥑', angle: -2.4),
    _FoodItem(asset: 'assets/images/food_broccoli.png', emoji: '🥦', angle: -0.8),
    _FoodItem(asset: 'assets/images/food_strawberry.png', emoji: '🍓', angle: 0.6),
    _FoodItem(asset: 'assets/images/food_milk.png', emoji: '🥛', angle: 2.0),
    _FoodItem(asset: 'assets/images/food_salad.png', emoji: '🥗', angle: 3.4),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ..._buildOrbitingFoodIcons(),
          Transform.translate(
            offset: Offset(0, floatOffset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 160,
                  height: 170,
                  child: Image.asset(
                    _robotAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const _RobotFallback(),
                  ),
                ),
                const SizedBox(height: 4),
                CustomPaint(
                  size: const Size(120, 36),
                  painter: _HologramRingsPainter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrbitingFoodIcons() {
    const orbitRadius = 118.0;
    return _foodItems.map((item) {
      final angle = item.angle + orbitAngle;
      final x = math.cos(angle) * orbitRadius;
      final y = math.sin(angle) * orbitRadius * 0.72;

      return Transform.translate(
        offset: Offset(x, y - 10),
        child: _GlassFoodBubble(
          asset: item.asset,
          emoji: item.emoji,
        ),
      );
    }).toList();
  }
}

class _FoodItem {
  const _FoodItem({
    required this.asset,
    required this.emoji,
    required this.angle,
  });

  final String asset;
  final String emoji;
  final double angle;
}

class _GlassFoodBubble extends StatelessWidget {
  const _GlassFoodBubble({
    required this.asset,
    required this.emoji,
  });

  final String asset;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.72),
                Colors.white.withValues(alpha: 0.35),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepPurple.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              asset,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RobotFallback extends StatelessWidget {
  const _RobotFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RobotPainter(),
      size: const Size(160, 170),
    );
  }
}

class _RobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.58),
        width: 72,
        height: 78,
      ),
      const Radius.circular(28),
    );

    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF5F5F5),
          ],
        ).createShader(bodyRect.outerRect)
        ..shadowColor = AppColors.deepPurple.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.28),
        width: 68,
        height: 62,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(headRect, Paint()..color = Colors.white);

    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.29),
        width: 52,
        height: 40,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(faceRect, Paint()..color = const Color(0xFF1A1A2E));

    final eyePaint = Paint()..color = AppColors.tealGlow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX - 12, size.height * 0.27),
          width: 14,
          height: 8,
        ),
        const Radius.circular(4),
      ),
      eyePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX + 12, size.height * 0.27),
          width: 14,
          height: 8,
        ),
        const Radius.circular(4),
      ),
      eyePaint,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.33),
        width: 18,
        height: 10,
      ),
      0.1,
      math.pi - 0.2,
      false,
      Paint()
        ..color = AppColors.tealGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final badgeCenter = Offset(centerX, size.height * 0.58);
    canvas.drawCircle(
      badgeCenter,
      16,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.softBlue,
            AppColors.deepPurple,
          ],
        ).createShader(Rect.fromCircle(center: badgeCenter, radius: 16)),
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'AI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      badgeCenter - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    for (final dx in [-48.0, 48.0]) {
      canvas.drawCircle(
        Offset(centerX + dx, size.height * 0.55),
        10,
        Paint()..color = Colors.white,
      );
    }

    canvas.drawCircle(
      Offset(centerX + 10, size.height * 0.22),
      4,
      Paint()..color = AppColors.deepPurple,
    );
    canvas.drawLine(
      Offset(centerX + 10, size.height * 0.22),
      Offset(centerX + 10, size.height * 0.16),
      Paint()
        ..color = AppColors.deepPurple
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(centerX + 10, size.height * 0.14),
      3,
      Paint()..color = AppColors.deepPurple,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HologramRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final rx = 50.0 - i * 10;
      final ry = 14.0 - i * 3;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 - i * 0.3
        ..color = Colors.white.withValues(alpha: 0.55 - i * 0.12);

      canvas.drawOval(
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

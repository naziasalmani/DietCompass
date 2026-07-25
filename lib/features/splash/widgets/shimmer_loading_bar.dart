import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class ShimmerLoadingBar extends StatelessWidget {
  const ShimmerLoadingBar({
    super.key,
    required this.progress,
    required this.shimmerPhase,
    required this.opacity,
  });

  final double progress;
  final double shimmerPhase;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final fillWidth = barWidth * progress.clamp(0.0, 1.0);

                return Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: AppColors.lavender.withValues(alpha: 0.45),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      width: fillWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.loadingGradientStart,
                            AppColors.loadingGradientEnd,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepPurple.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: CustomPaint(
                          painter: _ShimmerPainter(
                            phase: shimmerPhase,
                            barWidth: fillWidth,
                          ),
                          size: Size(fillWidth, 6),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Loading your healthy journey...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.mediumGrey,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.phase,
    required this.barWidth,
  });

  final double phase;
  final double barWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (barWidth <= 0) return;

    final shimmerWidth = size.width * 0.35;
    final startX = (size.width + shimmerWidth) * phase - shimmerWidth;

    final rect = Rect.fromLTWH(startX, 0, shimmerWidth, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.barWidth != barWidth;
  }
}

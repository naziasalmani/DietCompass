import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class GlassInfoCard extends StatelessWidget {
  const GlassInfoCard({
    super.key,
    required this.opacity,
    required this.slideOffset,
  });

  final double opacity;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, slideOffset),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.52),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepPurple.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.deepPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Better Choices, ',
                                  style: TextStyle(color: AppColors.charcoal),
                                ),
                                TextSpan(
                                  text: 'Better You.',
                                  style: TextStyle(color: AppColors.deepPurple),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Make smarter food choices with AI insights tailored just for you.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.45,
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AiBadge extends StatelessWidget {
  const AiBadge({
    super.key,
    required this.opacity,
  });

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppColors.lavender.withValues(alpha: 0.85),
              AppColors.paleLavender.withValues(alpha: 0.65),
            ],
          ),
          border: Border.all(
            color: AppColors.deepPurple.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppColors.deepPurple.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Text(
              'AI-Powered Nutrition Assistant',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.deepPurple.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

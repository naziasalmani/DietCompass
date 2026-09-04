import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';

/// Topic item model for Quick Help Guides
class HelpGuideTopic {
  const HelpGuideTopic({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<HelpGuideSection> sections;
}

class HelpGuideSection {
  const HelpGuideSection({
    required this.heading,
    required this.body,
    this.tips,
  });

  final String heading;
  final String body;
  final List<String>? tips;
}

/// DietCompass — Quick Help Guide Detail Screen
class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({
    super.key,
    required this.topic,
    this.onBack,
  });

  final HelpGuideTopic topic;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final scale = (width / 390.0).clamp(0.85, 1.25);
    final colors = context.dcColors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          // Ambient blurred background orbs
          Positioned(
            top: -50,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: topic.iconColor.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.iconGreen.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onBack ?? () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40 * scale,
                          height: 40 * scale,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(14 * scale),
                            border: Border.all(color: colors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20 * scale,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 14 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.title,
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              topic.subtitle,
                              style: TextStyle(
                                fontSize: 12 * scale,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Topic Hero Banner
                        Container(
                          padding: EdgeInsets.all(18 * scale),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20 * scale),
                            border: Border.all(color: colors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: colors.iconPurple.withValues(alpha: colors.isDark ? 0.12 : 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48 * scale,
                                height: 48 * scale,
                                decoration: BoxDecoration(
                                  color: topic.iconBg,
                                  borderRadius: BorderRadius.circular(16 * scale),
                                ),
                                child: Icon(topic.icon, color: topic.iconColor, size: 24 * scale),
                              ),
                              SizedBox(width: 14 * scale),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.title,
                                      style: TextStyle(
                                        fontSize: 16 * scale,
                                        fontWeight: FontWeight.w800,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2 * scale),
                                    Text(
                                      topic.subtitle,
                                      style: TextStyle(
                                        fontSize: 12 * scale,
                                        color: colors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 18 * scale),

                        // Detail Sections
                        ...topic.sections.map((sec) => Container(
                          margin: EdgeInsets.only(bottom: 14 * scale),
                          padding: EdgeInsets.all(18 * scale),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20 * scale),
                            border: Border.all(color: colors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: colors.iconPurple.withValues(alpha: colors.isDark ? 0.10 : 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sec.heading,
                                style: TextStyle(
                                  fontSize: 14.5 * scale,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              Text(
                                sec.body,
                                style: TextStyle(
                                  fontSize: 13 * scale,
                                  color: colors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              if (sec.tips != null && sec.tips!.isNotEmpty) ...[
                                SizedBox(height: 12 * scale),
                                Container(
                                  padding: EdgeInsets.all(12 * scale),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(12 * scale),
                                    border: Border.all(color: colors.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: sec.tips!.map((tip) => Padding(
                                      padding: EdgeInsets.only(bottom: 4 * scale),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.check_circle_outline_rounded, size: 14 * scale, color: colors.iconGreen),
                                          SizedBox(width: 8 * scale),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: TextStyle(
                                                fontSize: 12 * scale,
                                                color: colors.textSecondary,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )),

                        SizedBox(height: 20 * scale),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

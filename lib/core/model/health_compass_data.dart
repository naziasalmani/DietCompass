import 'package:flutter/material.dart';

/// Data model representing the calculated metrics for "Your Health Compass".
/// All metrics are dynamically computed from the authenticated user's real scan/analysis history.
class HealthCompassData {
  /// Arithmetic mean of compatibility scores across user's product scans (null if no scans)
  final int? averageCompatibility;

  /// Total count of unique products analyzed by the user
  final int productsAnalyzed;

  /// Total count of unique ingredients flagged across the user's analyzed products
  final int ingredientsFlagged;

  /// Total count of real healthier alternatives / recommendations available for analyzed products
  final int betterAlternatives;

  /// Total count of scans performed in the last 7 days
  final int scansThisWeek;

  /// Names of the unique flagged ingredients (for inspection or tooltips)
  final List<String> flaggedIngredientNames;

  /// Names of the unique products analyzed
  final List<String> uniqueProductNames;

  const HealthCompassData({
    this.averageCompatibility,
    required this.productsAnalyzed,
    required this.ingredientsFlagged,
    required this.betterAlternatives,
    required this.scansThisWeek,
    this.flaggedIngredientNames = const [],
    this.uniqueProductNames = const [],
  });

  /// Factory for an empty health compass state (brand-new user with no scans)
  factory HealthCompassData.empty() {
    return const HealthCompassData(
      averageCompatibility: null,
      productsAnalyzed: 0,
      ingredientsFlagged: 0,
      betterAlternatives: 0,
      scansThisWeek: 0,
      flaggedIngredientNames: [],
      uniqueProductNames: [],
    );
  }

  /// Indicates if the user has at least one completed scan
  bool get hasScans => averageCompatibility != null && productsAnalyzed > 0;

  /// Human-readable compatibility rating label
  String get compatibilityLabel {
    if (averageCompatibility == null || productsAnalyzed == 0) {
      return 'No scans yet';
    }
    final score = averageCompatibility!;
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Attention';
  }

  /// Foreground color for the dynamic compatibility status badge
  Color get statusBadgeColor {
    if (averageCompatibility == null || productsAnalyzed == 0) {
      return const Color(0xFF9A96A8);
    }
    final score = averageCompatibility!;
    if (score >= 90) return const Color(0xFF1E8A4C);
    if (score >= 75) return const Color(0xFF1E8A4C);
    if (score >= 60) return const Color(0xFFE0862E);
    return const Color(0xFFE0525C);
  }

  /// Background color for the dynamic compatibility status badge
  Color get statusBadgeBackgroundColor {
    if (averageCompatibility == null || productsAnalyzed == 0) {
      return const Color(0xFFF3F2F8);
    }
    final score = averageCompatibility!;
    if (score >= 90) return const Color(0xFFE4F5E9);
    if (score >= 75) return const Color(0xFFE4F5E9);
    if (score >= 60) return const Color(0xFFFFF3E0);
    return const Color(0xFFFFEBEE);
  }

  /// Icon for the dynamic compatibility status badge
  IconData get statusBadgeIcon {
    if (averageCompatibility == null || productsAnalyzed == 0) {
      return Icons.explore_outlined;
    }
    final score = averageCompatibility!;
    if (score >= 90) return Icons.auto_awesome;
    if (score >= 75) return Icons.thumb_up_alt_rounded;
    if (score >= 60) return Icons.info_outline;
    return Icons.warning_amber_rounded;
  }
}

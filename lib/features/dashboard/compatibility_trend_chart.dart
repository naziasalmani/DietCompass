import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/services/scan_history_service.dart';
import '../../core/model/scan_history_item.dart';

/// A line chart widget that displays the user's real compatibility score trend over time.
/// Shows actual scan history data with dates and compatibility scores.
/// Handles empty states gracefully when no scans are available.
class CompatibilityTrendChart extends StatefulWidget {
  const CompatibilityTrendChart({super.key, required this.uiScale});

  final double uiScale;

  @override
  State<CompatibilityTrendChart> createState() =>
      _CompatibilityTrendChartState();
}

class _CompatibilityTrendChartState extends State<CompatibilityTrendChart> {
  late Future<List<ScanHistoryItem>> _scansFuture;

  @override
  void initState() {
    super.initState();
    _scansFuture = ScanHistoryService.instance.getScanHistory();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compatibility Trend',
          style: TextStyle(
            fontSize: 15.5 * widget.uiScale,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 10 * widget.uiScale),
        FutureBuilder<List<ScanHistoryItem>>(
          future: _scansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _ChartSkeletonLoader(uiScale: widget.uiScale);
            }

            if (snapshot.hasError) {
              return _ChartErrorState(
                uiScale: widget.uiScale,
                message: 'Unable to load compatibility trend data',
              );
            }

            final scans = snapshot.data ?? [];

            // Filter out scans with zero or invalid scores
            final validScans = scans
                .where((s) => s.score > 0 && s.score <= 100)
                .toList();

            // Sort by date (oldest first)
            validScans.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));

            if (validScans.isEmpty) {
              return _EmptyTrendState(uiScale: widget.uiScale);
            }

            // If only 1 scan, show it but don't display as a trend
            if (validScans.length == 1) {
              return _SingleScanState(
                uiScale: widget.uiScale,
                scan: validScans.first,
              );
            }

            // 2+ scans: show the chart
            return _TrendChartDisplay(
              uiScale: widget.uiScale,
              scans: validScans,
            );
          },
        ),
      ],
    );
  }
}

/// The main chart display when there are 2+ scans
class _TrendChartDisplay extends StatelessWidget {
  const _TrendChartDisplay({required this.uiScale, required this.scans});

  final double uiScale;
  final List<ScanHistoryItem> scans;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score history over time',
            style: TextStyle(
              fontSize: 12 * uiScale,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 16 * uiScale),
          SizedBox(
            height: 180 * uiScale,
            child: CustomPaint(
              painter: _CompatibilityChartPainter(
                scans: scans,
                isDark: colors.isDark,
              ),
              size: Size.infinite,
            ),
          ),
          SizedBox(height: 12 * uiScale),
          Text(
            '${scans.length} scans analyzed',
            style: TextStyle(fontSize: 10 * uiScale, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Displays when there's only 1 scan (not enough for a trend)
class _SingleScanState extends StatelessWidget {
  const _SingleScanState({required this.uiScale, required this.scan});

  final double uiScale;
  final ScanHistoryItem scan;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return _GlassCard(
      child: Column(
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 32 * uiScale,
            color: colors.textMuted,
          ),
          SizedBox(height: 12 * uiScale),
          Text(
            'Only one scan so far',
            style: TextStyle(
              fontSize: 12.5 * uiScale,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6 * uiScale),
          Text(
            'Scan more products to see your compatibility trend over time.',
            style: TextStyle(
              fontSize: 10 * uiScale,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10 * uiScale),
          Text(
            'Current score: ${scan.score}/100',
            style: TextStyle(
              fontSize: 13 * uiScale,
              fontWeight: FontWeight.w800,
              color: _getScoreColor(scan.score),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 75) return const Color(0xFF1E8A4C);
    if (score >= 60) return const Color(0xFFE0862E);
    return const Color(0xFFE0525C);
  }
}

/// Displays when there are no scans at all
class _EmptyTrendState extends StatelessWidget {
  const _EmptyTrendState({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return _GlassCard(
      child: Column(
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 36 * uiScale,
            color: colors.textMuted,
          ),
          SizedBox(height: 12 * uiScale),
          Text(
            'Compatibility trend not available yet',
            style: TextStyle(
              fontSize: 12.5 * uiScale,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6 * uiScale),
          Text(
            'Scan and analyze food products to start tracking your compatibility over time.',
            style: TextStyle(
              fontSize: 10 * uiScale,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader while data is loading
class _ChartSkeletonLoader extends StatelessWidget {
  const _ChartSkeletonLoader({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120 * uiScale,
            height: 8 * uiScale,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 16 * uiScale),
          SizedBox(
            height: 180 * uiScale,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 12 * uiScale),
          Container(
            width: 80 * uiScale,
            height: 7 * uiScale,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state display
class _ChartErrorState extends StatelessWidget {
  const _ChartErrorState({required this.uiScale, required this.message});

  final double uiScale;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return _GlassCard(
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 32 * uiScale,
            color: colors.textMuted,
          ),
          SizedBox(height: 12 * uiScale),
          Text(
            'Error loading chart',
            style: TextStyle(
              fontSize: 12.5 * uiScale,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6 * uiScale),
          Text(
            message,
            style: TextStyle(
              fontSize: 10 * uiScale,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the line chart
class _CompatibilityChartPainter extends CustomPainter {
  _CompatibilityChartPainter({required this.scans, required this.isDark});

  final List<ScanHistoryItem> scans;
  final bool isDark;

  static const double leftPadding = 40;
  static const double rightPadding = 12;
  static const double topPadding = 12;
  static const double bottomPadding = 40;

  @override
  void paint(Canvas canvas, Size size) {
    if (scans.isEmpty) return;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Colors based on theme
    final primaryLineColor = isDark
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF7C3AED);
    final gridColor = isDark
        ? const Color(0xFF2D2639)
        : const Color(0xFFF0ECFE);
    final textColor = isDark
        ? const Color(0xFFC4B5FD)
        : const Color(0xFF6B21A8);
    final pointColor = const Color(0xFF1E8A4C);

    // Draw grid lines (horizontal)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, size.height - bottomPadding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, size.height - bottomPadding),
      Offset(size.width - rightPadding, size.height - bottomPadding),
      axisPaint,
    );

    // Draw Y-axis labels (0, 25, 50, 75, 100)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 4; i++) {
      final score = (100 - i * 25).toString();
      textPainter.text = TextSpan(
        text: score,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      final y = topPadding + (chartHeight * i / 4);
      textPainter.paint(
        canvas,
        Offset(leftPadding - 28, y - textPainter.height / 2),
      );
    }

    // Prepare data points
    final dataPoints = <Offset>[];
    final scores = scans.map((s) => s.score.toDouble()).toList();
    final minScore = 0.0;
    final maxScore = 100.0;

    for (int i = 0; i < scans.length; i++) {
      final score = scores[i];
      final normalizedScore = (score - minScore) / (maxScore - minScore);
      final x = leftPadding + (chartWidth * i / math.max(1, scans.length - 1));
      final y = size.height - bottomPadding - (chartHeight * normalizedScore);
      dataPoints.add(Offset(x, y));
    }

    // Draw line
    if (dataPoints.length > 1) {
      final linePaint = Paint()
        ..color = primaryLineColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < dataPoints.length - 1; i++) {
        canvas.drawLine(dataPoints[i], dataPoints[i + 1], linePaint);
      }
    }

    // Draw gradient fill under the line
    if (dataPoints.length > 1) {
      final fillPath = Path()..moveTo(dataPoints.first.dx, dataPoints.first.dy);

      for (int i = 1; i < dataPoints.length; i++) {
        fillPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
      }

      fillPath.lineTo(dataPoints.last.dx, size.height - bottomPadding);
      fillPath.lineTo(dataPoints.first.dx, size.height - bottomPadding);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryLineColor.withValues(alpha: 0.2),
            primaryLineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw data points (circles)
    final pointPaint = Paint()
      ..color = pointColor
      ..strokeWidth = 2;

    final pointFillPaint = Paint()
      ..color = isDark ? const Color(0xFF13111C) : const Color(0xFFFFFFFF)
      ..strokeWidth = 1;

    for (final point in dataPoints) {
      canvas.drawCircle(point, 4.5, pointFillPaint);
      canvas.drawCircle(point, 4.5, pointPaint);
    }

    // Draw X-axis date labels (first, middle, last)
    if (scans.length >= 2) {
      final indices = [0, scans.length ~/ 2, scans.length - 1];
      final dateFormat = (DateTime date) {
        return '${date.month}/${date.day}';
      };

      for (final idx in indices) {
        if (idx < scans.length) {
          final date = scans[idx].scannedAt;
          final dateStr = dateFormat(date);
          textPainter.text = TextSpan(
            text: dateStr,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();

          final x =
              leftPadding + (chartWidth * idx / math.max(1, scans.length - 1));
          textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompatibilityChartPainter oldDelegate) {
    return oldDelegate.scans.length != scans.length ||
        oldDelegate.isDark != isDark;
  }
}

/// Glass card styling helper
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding, this.radius = 20});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface.withValues(
              alpha: colors.isDark ? 0.90 : 0.70,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: colors.isDark ? 0.20 : 0.05,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

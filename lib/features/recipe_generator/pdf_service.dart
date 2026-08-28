import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/model/meal_plan_model.dart';
import '../../core/services/meal_plan_service.dart';

/// DietCompass — Dynamic PDF Export Service for Meal Plans
class PdfService {
  static Future<void> exportMealPlan([MealPlanResponse? plan]) async {
    final effectivePlan = plan ?? MealPlanService.instance.currentPlan;

    if (effectivePlan == null || effectivePlan.days.isEmpty) {
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'DietCompass',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.deepPurple700,
                ),
              ),
              pw.Text(
                '${effectivePlan.durationDays}-Day AI Meal Plan',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            effectivePlan.summary,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),

          // Metadata Grid
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Goal: ${effectivePlan.goal}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Diet: ${effectivePlan.diet}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Target: ~${effectivePlan.targetCalories} kcal/day', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Avg Calories: ${effectivePlan.totals.averageCalories} kcal', style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
          pw.SizedBox(height: 16),

          // Days & Meals Breakdown
          for (final day in effectivePlan.days) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.deepPurple50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${day.dayNumber} (${day.dayLabel}) — ${day.date}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepPurple900,
                    ),
                  ),
                  pw.Text(
                    '${day.dailyCalories} kcal | ${day.dailyProtein}g Protein | ${day.dailyFiber}g Fiber',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            for (final meal in day.meals)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '• [${meal.type}] ${meal.title}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      '${meal.calories} kcal | ${meal.proteinGrams}g Protein',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
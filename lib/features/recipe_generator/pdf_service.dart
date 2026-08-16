import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {

  static Future<void> exportMealPlan() async {

    final pdf = pw.Document();

    pdf.addPage(

      pw.MultiPage(

        pageFormat: PdfPageFormat.a4,

        build: (context) => [

          pw.Text(
            "DietCompass",
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            "AI Weekly Meal Plan",
            style: pw.TextStyle(fontSize: 20),
          ),

          pw.Divider(),

          pw.Text("Goal : Weight Loss"),
          pw.Text("Calories : 1800 kcal"),
          pw.Text("Diet : Vegetarian"),
          pw.Text("Budget : Moderate"),

          pw.SizedBox(height: 20),

          pw.Text(
            "Monday",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.Bullet(text: "Breakfast - Banana Oats Bowl"),
          pw.Bullet(text: "Lunch - Quinoa Veggie Salad"),
          pw.Bullet(text: "Snack - Apple & Almonds"),
          pw.Bullet(text: "Dinner - Paneer Stir Fry"),

          pw.SizedBox(height: 15),

          pw.Text("Calories : 1500 kcal"),
          pw.Text("Protein : 65 g"),
          pw.Text("Fiber : 28 g"),

        ],

      ),

    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );

  }

}
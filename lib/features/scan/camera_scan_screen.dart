import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/food_service.dart';
import '../../core/model/food_product.dart';
import '../../core/services/product_image_analyzer.dart';
import '../../core/services/ai_service.dart';
import 'ai_analysis_screen.dart';
import '../home/home_screen.dart';
import 'scan_screen.dart';

enum CameraSource {
  home,
  scan,
}

/// DietCompass — Scan Product (live camera) screen
/// -----------------------------------------------------------------------
/// A full-screen camera capture UI matching the reference exactly: the
/// rear camera opens automatically behind a glassmorphism scanner frame,
/// with the same header, tip banner, side actions, status bar, capture
/// controls and trust footer.
///
/// This screen replaces the reference's static oats-packet photo with a
/// real, live CameraPreview, and reuses your existing DietCompass robot
/// asset (assets/images/robot_badge.png) in the tip banner instead of the
/// reference's placeholder robot.
///
/// -------------------------------------------------------------------
/// SETUP (only this screen's requirements — nothing else touched):
///
/// 1. Add the camera package to pubspec.yaml:
/// yaml /// dependencies: /// camera: ^0.11.0+2 ///
///
/// 2. Android — add to android/app/src/main/AndroidManifest.xml, inside
/// <manifest>, above <application>:
/// xml /// <uses-permission android:name="android.permission.CAMERA" /> /// <uses-feature android:name="android.hardware.camera" android:required="true" /> ///
/// Also make sure minSdkVersion >= 21 in android/app/build.gradle.
///
/// 3. iOS — add to ios/Runner/Info.plist:
/// xml /// <key>NSCameraUsageDescription</key> /// <string>DietCompass needs camera access to scan product labels.</string> ///
///
/// 4. Push this screen normally, e.g. from your existing Scan tab's
/// "Scan Product" / "Scan Barcode" actions:
/// dart /// Navigator.push(context, MaterialPageRoute( /// builder: (_) => CameraScanScreen( /// onCaptured: (file) { /* send `file.path` off for analysis */ }, /// ), /// )); ///
/// -------------------------------------------------------------------
class CameraScanScreen extends StatefulWidget {
const CameraScanScreen({
  super.key,
  required this.source,
  this.onCaptured,
  this.onGalleryTap,
  this.onHowToScanTap,
  this.onHistoryTap,
  this.onCancel,
  this.onAccuracyInfoTap,
});

  final CameraSource source;

/// Called with the captured photo once the shutter button is pressed
/// and the picture has been taken.
final ValueChanged<XFile>? onCaptured;

final VoidCallback? onGalleryTap;
final VoidCallback? onHowToScanTap;
final VoidCallback? onHistoryTap;
final VoidCallback? onCancel;
final VoidCallback? onAccuracyInfoTap;

@override
State<CameraScanScreen> createState() => _CameraScanScreenState();
}


class _CameraScanScreenState extends State<CameraScanScreen>
    with TickerProviderStateMixin {

  CameraController? _cameraController;

final BarcodeScanner _barcodeScanner = BarcodeScanner();

final TextRecognizer _textRecognizer =
    TextRecognizer(script: TextRecognitionScript.latin);

Future<bool> _checkBarcode(XFile image) async {
  try {
    final inputImage = InputImage.fromFilePath(image.path);

    final barcodes = await _barcodeScanner.processImage(inputImage);

    if (barcodes.isEmpty) {
      return false;
    }

    for (final barcode in barcodes) {
      final code = barcode.rawValue;

      if (code == null || code.isEmpty) {
        continue;
      }

      await _lookupFood(code, image);
      return true;
    }

    return false;
  } catch (e) {
    debugPrint('Barcode detection error: $e');
    return false;
  }
}

Future<String?> _extractProductName(XFile image) async {
  try {
    final inputImage = InputImage.fromFilePath(image.path);

    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    if (recognizedText.text.trim().isEmpty) {
      debugPrint('OCR: No text detected');
      return null;
    }

    debugPrint('========== OCR TEXT ==========');
    debugPrint(recognizedText.text);
    debugPrint('==============================');

    final List<String> candidates = [];

    // Words/phrases that are very unlikely to be the product name.
    final ignoredWords = <String>[
      'nutrition',
      'nutritional',
      'nutrition facts',
      'ingredients',
      'ingredient',
      'energy',
      'calories',
      'protein',
      'carbohydrate',
      'carbohydrates',
      'total fat',
      'saturated fat',
      'trans fat',
      'sugar',
      'sugars',
      'sodium',
      'cholesterol',
      'dietary fibre',
      'dietary fiber',
      'serving',
      'servings',
      'serving size',
      'per 100g',
      'per 100ml',
      'net weight',
      'net wt',
      'net quantity',
      'manufactured',
      'manufactured by',
      'marketed by',
      'packed by',
      'customer care',
      'expiry',
      'expiry date',
      'best before',
      'use by',
      'mrp',
      'm.r.p',
      'batch',
      'batch no',
      'barcode',
      'fssai',
      'license',
      'licence',
      'email',
      'website',
      'www.',
      'http',
      '₹',
      'rs.',
    ];

    // Read OCR lines and also combine consecutive lines.
// This allows products such as:
//
// THUMS
// UP
//
// to become:
//
// THUMS UP

final List<String> ocrLines = [];

for (final block in recognizedText.blocks) {
  for (final line in block.lines) {
    final String text = line.text.trim();

    if (text.isEmpty) continue;

    final String lower = text.toLowerCase();

    // Ignore common packaging / nutrition information.
    if (ignoredWords.any((word) => lower.contains(word))) {
      continue;
    }

    final int letterCount =
        RegExp(r'[A-Za-z]').allMatches(text).length;

    if (letterCount < 2) {
      continue;
    }

    if (letterCount / text.length < 0.45) {
      continue;
    }

    if (text.length > 60) {
      continue;
    }

    if (text.length < 2) {
      continue;
    }

    ocrLines.add(text);
  }
}

// Add individual lines as candidates.
candidates.addAll(ocrLines);

// Also combine consecutive OCR lines.
// Example:
// THUMS
// UP
// → THUMS UP
//
// We try 2-line and 3-line combinations because some
// product names may be split across multiple lines.

for (int i = 0; i < ocrLines.length; i++) {
  // Two consecutive lines
  if (i + 1 < ocrLines.length) {
    final combined = '${ocrLines[i]} ${ocrLines[i + 1]}';

    if (combined.length <= 40) {
      candidates.add(combined);
    }
  }

  // Three consecutive lines
  if (i + 2 < ocrLines.length) {
    final combined =
        '${ocrLines[i]} ${ocrLines[i + 1]} ${ocrLines[i + 2]}';

    if (combined.length <= 50) {
      candidates.add(combined);
    }
  }
}

    if (candidates.isEmpty) {
      debugPrint('OCR: No suitable product-name candidates');
      return null;
    }

    debugPrint('OCR candidates: $candidates');

    // ---------------------------------------------------------
    // SCORE EACH CANDIDATE
    // ---------------------------------------------------------
    //
    // We DO NOT simply choose the longest line.
    //
    // Product/brand names usually:
    // - contain mostly letters
    // - contain relatively few words
    // - are not sentences
    // - do not contain nutrition measurements
    // ---------------------------------------------------------

    String? bestCandidate;
    double bestScore = double.negativeInfinity;

    for (int i = 0; i < candidates.length; i++) {
      final String candidate = candidates[i];
      final String lower = candidate.toLowerCase();

      double score = 0;

      final words = candidate
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList();

      final int letterCount =
          RegExp(r'[A-Za-z]').allMatches(candidate).length;

      final int digitCount =
          RegExp(r'[0-9]').allMatches(candidate).length;

      // ---------------------------------------
      // 1. Prefer text near the beginning.
      // Front-of-pack brand/product names are
      // commonly detected before smaller text.
      // ---------------------------------------

      if (i == 0) {
        score += 8;
      } else if (i == 1) {
        score += 6;
      } else if (i == 2) {
        score += 4;
      } else if (i == 3) {
        score += 2;
      }

      // ---------------------------------------
      // 2. Prefer sensible product-name lengths
      // ---------------------------------------

      if (candidate.length >= 4 && candidate.length <= 30) {
        score += 5;
      }

      if (candidate.length >= 5 && candidate.length <= 20) {
        score += 3;
      }

      // ---------------------------------------
      // 3. Prefer 1-4 word names
      // ---------------------------------------

      if (words.length == 1) {
        score += 5;
      } else if (words.length == 2) {
        score += 7;
      } else if (words.length == 3) {
        score += 6;
      } else if (words.length == 4) {
        score += 3;
      } else if (words.length > 6) {
        score -= 8;
      }

      // ---------------------------------------
      // 4. Prefer mostly alphabetic text
      // ---------------------------------------

      if (letterCount > 0) {
        final letterRatio = letterCount / candidate.length;

        if (letterRatio >= 0.80) {
          score += 5;
        } else if (letterRatio >= 0.65) {
          score += 3;
        }
      }

      // ---------------------------------------
      // 5. Penalize numbers
      // ---------------------------------------

      if (digitCount == 0) {
        score += 3;
      } else {
        score -= digitCount * 2;
      }

      // ---------------------------------------
      // 6. Penalize measurements
      // ---------------------------------------

      if (RegExp(
        r'\b\d+(\.\d+)?\s*(g|kg|mg|ml|l|kcal|cal)\b',
        caseSensitive: false,
      ).hasMatch(candidate)) {
        score -= 12;
      }

      // ---------------------------------------
      // 7. Penalize sentence-like text
      // ---------------------------------------

      if (candidate.contains('.') ||
          candidate.contains(':') ||
          candidate.contains(';')) {
        score -= 4;
      }

      // Common marketing/descriptive wording
      final marketingWords = [
        'with',
        'made with',
        'contains',
        'source of',
        'rich in',
        'goodness',
        'delicious',
        'healthy',
        'natural',
        'new',
      ];

      if (marketingWords.any((word) => lower.contains(word))) {
        score -= 3;
      }

      debugPrint(
        'OCR candidate: "$candidate" | score: $score',
      );

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = candidate;
      }
    }

    if (bestCandidate == null ||
        bestCandidate.trim().isEmpty) {
      return null;
    }

    final String productName = bestCandidate.trim();

    debugPrint(
      '========== OCR RESULT ==========\n'
      'Selected product name: $productName\n'
      'Score: $bestScore\n'
      '================================',
    );

    return productName;
  } catch (e, stackTrace) {
    debugPrint('OCR error: $e');
    debugPrint('$stackTrace');
    return null;
  }
}

// ============================================================
// OCR TEXT PROCESSING & PRODUCT RESOLUTION PIPELINE
// ============================================================

/// Normalize OCR text for better matching
String normalizeOcrText(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\w\s-]'), '');
}

/// Calculate similarity between two strings using a word and character-based approach
/// Returns a value between 0.0 and 1.0
double calculateStringSimilarity(String a, String b) {
  final aLower = a.toLowerCase().trim();
  final bLower = b.toLowerCase().trim();

  if (aLower == bLower) {
    return 1.0;
  }

  if (aLower.isEmpty || bLower.isEmpty) {
    return 0.0;
  }

  final aWords = aLower
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  final bWords = bLower
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (aWords.isEmpty || bWords.isEmpty) {
    return 0.0;
  }

  int matchingWords = 0;

  for (final aWord in aWords) {
    for (final bWord in bWords) {
      // Exact word match
      if (aWord == bWord) {
        matchingWords++;
        break;
      }

      // Fuzzy word match
      if (aWord.length > 3 && bWord.length > 3) {
        final distance = _levenshteinDistance(
          aWord,
          bWord,
        );

        if (distance <= 2) {
          matchingWords++;
          break;
        }
      }
    }
  }

  // IMPORTANT:
  // Score against the COMPLETE database product name.
  //
  // "Dairy" vs "Dairy Milk"
  // = 1 / 2 = 0.5
  //
  // "Dairy Milk" vs "Dairy Milk"
  // = 2 / 2 = 1.0
  final productWordCoverage =
      matchingWords / bWords.length;

  // Also calculate OCR coverage.
  final ocrWordCoverage =
      matchingWords / aWords.length;

  // Use the weaker of the two.
  //
  // This prevents a short OCR fragment such as
  // "Dairy" from becoming a perfect match for
  // "Dairy Milk".
  return math.min(
    productWordCoverage,
    ocrWordCoverage,
  );
}

/// Calculate Levenshtein distance between two words for fuzzy matching
int _levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final List<List<int>> matrix =
      List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));

  for (int i = 0; i <= a.length; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= b.length; j++) {
    matrix[0][j] = j;
  }

  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1, // deletion
        matrix[i][j - 1] + 1, // insertion
        matrix[i - 1][j - 1] + cost, // substitution
      ].reduce((x, y) => x < y ? x : y);
    }
  }

  return matrix[a.length][b.length];
}

/// Extract OCR candidates from recognized text
/// Returns a list of candidate product names with increasing specificity
List<String> extractOcrCandidates(
  RecognizedText recognizedText,
) {
  final candidates = <String>[];

  final ignoredWords = <String>[
    'nutrition',
    'nutritional',
    'nutrition facts',
    'ingredients',
    'ingredient',
    'energy',
    'calories',
    'protein',
    'carbohydrate',
    'carbohydrates',
    'total fat',
    'saturated fat',
    'trans fat',
    'sugar',
    'sugars',
    'sodium',
    'cholesterol',
    'dietary fibre',
    'dietary fiber',
    'serving',
    'servings',
    'serving size',
    'per 100g',
    'per 100ml',
    'net weight',
    'net wt',
    'net quantity',
    'manufactured',
    'manufactured by',
    'marketed by',
    'packed by',
    'customer care',
    'expiry',
    'expiry date',
    'best before',
    'use by',
    'mrp',
    'm.r.p',
    'batch',
    'batch no',
    'barcode',
    'fssai',
    'license',
    'licence',
    'email',
    'website',
    'www.',
    'http',
    '₹',
    'rs.',
  ];

  final List<String> ocrLines = [];

  for (final block in recognizedText.blocks) {
    for (final line in block.lines) {
      final String text = line.text.trim();

      if (text.isEmpty) continue;

      final String lower = text.toLowerCase();

      // Ignore common packaging / nutrition information
      if (ignoredWords.any((word) => lower.contains(word))) {
        continue;
      }

      final int letterCount =
          RegExp(r'[A-Za-z]').allMatches(text).length;

      if (letterCount < 2) {
        continue;
      }

      if (letterCount / text.length < 0.45) {
        continue;
      }

      if (text.length > 60) {
        continue;
      }

      if (text.length < 2) {
        continue;
      }

      ocrLines.add(text);
    }
  }

  // Add individual lines as candidates
  candidates.addAll(ocrLines);

  // Combine consecutive OCR lines for 2-3 line combinations
  for (int i = 0; i < ocrLines.length; i++) {
    if (i + 1 < ocrLines.length) {
      final combined = '${ocrLines[i]} ${ocrLines[i + 1]}';
      if (combined.length <= 40) {
        candidates.add(combined);
      }
    }

    if (i + 2 < ocrLines.length) {
      final combined =
          '${ocrLines[i]} ${ocrLines[i + 1]} ${ocrLines[i + 2]}';
      if (combined.length <= 50) {
        candidates.add(combined);
      }
    }
  }

  return candidates;
}

/// Main OCR-based product resolution pipeline
/// Returns a product with confidence score, or null if no match found
Future<FoodProduct?> resolveProductFromOcr(
  XFile image,
) async {
  try {
    final inputImage =
        InputImage.fromFilePath(image.path);

    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    if (recognizedText.text.trim().isEmpty) {
      debugPrint('OCR: No text detected');
      return null;
    }

    debugPrint(
      '========== OCR RESOLUTION STARTED ==========',
    );

    debugPrint(
      'RAW OCR:\n${recognizedText.text}',
    );

    // ----------------------------------------------------------
    // STEP 1: Extract candidates
    // ----------------------------------------------------------

    final candidates =
        extractOcrCandidates(recognizedText);

    if (candidates.isEmpty) {
      debugPrint('OCR: No candidates found');
      return null;
    }

    debugPrint(
      'OCR candidates: $candidates',
    );

    // ----------------------------------------------------------
    // STEP 2: Normalize + deduplicate
    // ----------------------------------------------------------

    final normalized = <String>{};

    for (final candidate in candidates) {
      final value =
          normalizeOcrText(candidate);

      if (value.isNotEmpty) {
        normalized.add(value);
      }
    }

    // ----------------------------------------------------------
    // STEP 3:
    //
    // PRIORITIZE MULTI-WORD CANDIDATES
    //
    // Example:
    //
    // Dairy
    // Milk
    // Chocolate
    //
    // becomes:
    //
    // Dairy Milk Chocolate
    // Dairy Milk
    // Milk Chocolate
    // Dairy
    // Milk
    // Chocolate
    // ----------------------------------------------------------

    final sortedCandidates =
        normalized.toList()
          ..sort(
            (a, b) {
              final aWords =
                  a.split(RegExp(r'\s+')).length;

              final bWords =
                  b.split(RegExp(r'\s+')).length;

              // More words first
              if (aWords != bWords) {
                return bWords.compareTo(aWords);
              }

              // If same word count, longer text first
              return b.length.compareTo(a.length);
            },
          );

    debugPrint(
      'Prioritized candidates: $sortedCandidates',
    );

    // ----------------------------------------------------------
    // STEP 4: Search all candidates
    // ----------------------------------------------------------

    FoodProduct? bestMatch;
    double bestScore = 0.0;
    String bestQuery = '';

    // Keep track of whether we have meaningful multi-word
    // OCR candidates.
    final hasMultiWordCandidate =
        sortedCandidates.any(
      (candidate) =>
          candidate.split(RegExp(r'\s+')).length >= 2,
    );

    for (final candidate in sortedCandidates) {
      final candidateWords =
          candidate.split(RegExp(r'\s+'));

      final isSingleWord =
          candidateWords.length == 1;

      // --------------------------------------------------------
      // VERY IMPORTANT:
      //
      // If OCR found multiple words, don't allow a random
      // single word like "Dairy" to become the final product.
      //
      // We'll only use single-word candidates if NO
      // multi-word candidate produces a valid match.
      // --------------------------------------------------------

      if (isSingleWord && hasMultiWordCandidate) {
        debugPrint(
          'Skipping single-word candidate for now: '
          '"$candidate"',
        );

        continue;
      }

      debugPrint(
        'Searching: "$candidate"',
      );

      final products =
          await _foodService.getFoodsByName(
        candidate,
      );

      if (products.isEmpty) {
        continue;
      }

      debugPrint(
        'Found ${products.length} products for '
        '"$candidate"',
      );

      // --------------------------------------------------------
      // Compare against every returned product
      // --------------------------------------------------------

      for (final product in products) {
        final productName =
            normalizeOcrText(product.name);

        if (productName.isEmpty) {
          continue;
        }

        final similarity =
            calculateStringSimilarity(
          candidate,
          productName,
        );

        debugPrint(
          '"$candidate" → '
          '"${product.name}" '
          'score=${similarity.toStringAsFixed(2)}',
        );

        if (similarity <= 0.5) {
          continue;
        }

        // ------------------------------------------------------
        // Candidate-length bonus
        //
        // Prefer:
        //
        // Dairy Milk
        //
        // over:
        //
        // Dairy
        //
        // when both are valid.
        // ------------------------------------------------------

        final candidateWordCount =
            candidateWords.length;

        double adjustedScore =
            similarity;

        if (candidateWordCount >= 3) {
          adjustedScore += 0.15;
        } else if (candidateWordCount == 2) {
          adjustedScore += 0.10;
        }

        // Don't allow score above 1.0
        adjustedScore =
            math.min(adjustedScore, 1.0);

        if (adjustedScore > bestScore) {
          bestScore = adjustedScore;
          bestMatch = product;
          bestQuery = candidate;

          debugPrint(
            '⭐ NEW BEST MATCH: '
            '"${product.name}" '
            'from "$candidate" '
            'score=${adjustedScore.toStringAsFixed(2)}',
          );
        }
      }
    }

    // ----------------------------------------------------------
    // STEP 5: If no multi-word result worked,
    // THEN try single-word candidates as fallback.
    // ----------------------------------------------------------

    if (bestMatch == null &&
        hasMultiWordCandidate) {
      debugPrint(
        'No multi-word match found. '
        'Trying single-word fallback...',
      );

      for (final candidate in sortedCandidates) {
        final words =
            candidate.split(RegExp(r'\s+'));

        if (words.length != 1) {
          continue;
        }

        // Generic words that should never identify
        // a packaged food by themselves.
        const genericWords = {
          'dairy',
          'milk',
          'chocolate',
          'drink',
          'juice',
          'food',
          'fresh',
          'natural',
          'original',
          'classic',
          'cream',
          'snack',
        };

        if (genericWords.contains(candidate)) {
          debugPrint(
            'Skipping generic single word: "$candidate"',
          );

          continue;
        }

        final products =
            await _foodService.getFoodsByName(
          candidate,
        );

        for (final product in products) {
          final productName =
              normalizeOcrText(product.name);

          final similarity =
              calculateStringSimilarity(
            candidate,
            productName,
          );

          if (similarity > 0.75 &&
              similarity > bestScore) {
            bestScore = similarity;
            bestMatch = product;
            bestQuery = candidate;
          }
        }
      }
    }

    // ----------------------------------------------------------
    // STEP 6: Final result
    // ----------------------------------------------------------

    if (bestMatch != null) {
      debugPrint(
        '========== OCR SUCCESS ==========\n'
        'Query: "$bestQuery"\n'
        'Product: "${bestMatch.name}"\n'
        'Brand: "${bestMatch.brand}"\n'
        'Score: ${bestScore.toStringAsFixed(2)}\n'
        '=================================',
      );

      return await _foodService.enrichProduct(bestMatch);
    }

    // ----------------------------------------------------------
    // STEP 6: Gemini AI Fallback on raw OCR text
    // ----------------------------------------------------------
    if (recognizedText.text.trim().isNotEmpty) {
      debugPrint('🤖 OCR fallback: Identifying product with Gemini AI...');
      try {
        final geminiProduct = await AiService.instance.lookupProductWithGemini(
          ocrText: recognizedText.text,
        );
        if (geminiProduct != null) {
          debugPrint('✅ OCR Gemini AI resolution success: ${geminiProduct.name}');
          return geminiProduct;
        }
      } catch (e) {
        debugPrint('Gemini OCR resolution error: $e');
      }
    }

    debugPrint(
      '❌ OCR could not confidently identify product.',
    );

    return null;
  } catch (e, stackTrace) {
    debugPrint(
      'OCR resolution error: $e',
    );

    debugPrint(
      '$stackTrace',
    );

    return null;
  }
}

final FoodService _foodService = FoodService();

bool _barcodeDetected = false;

late final AnimationController _scanLineCtrl;
late final AnimationController _entranceCtrl;

bool _flashOn = false;
bool _autoMode = true;
bool _showTip = true;

@override
void initState() {
  super.initState();

  _initializeCamera();

  _scanLineCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  _entranceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
}

Future<void> _capture() async {
  final camera = _cameraController;

  if (camera == null || !camera.value.isInitialized) {
    return;
  }

  // Prevent double tapping the capture button.
  if (_isManualCapturing) {
    return;
  }

  _isManualCapturing = true;

  _setProcessingState(
    true,
    title: '🔍 Analyzing your product…',
    subtitle: 'Checking nutrition, ingredients & personalized compatibility.',
  );

  try {
    // Stop live barcode scanning first.
    if (camera.value.isStreamingImages) {
      await camera.stopImageStream();
    }

    // Wait for any currently-processing camera frame to finish.
    while (_isProcessingImage) {
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;
    }

    debugPrint('Taking manual photo...');

    // NOW take the actual photo.
    final XFile image = await camera.takePicture();

    debugPrint('Manual photo captured: ${image.path}');

    if (!mounted) return;

    // --------------------------------------------------
    // STEP 1: Check for barcode in captured image
    // --------------------------------------------------

    final barcodeFound = await _checkBarcode(image);

    if (!mounted) return;

    if (barcodeFound) {
      return;
    }

    // --------------------------------------------------
    // STEP 2: NO BARCODE → SMART OCR PRODUCT RESOLUTION
    // --------------------------------------------------

    debugPrint(
      'No barcode found. Starting smart OCR resolution...',
    );

    final product = await resolveProductFromOcr(image);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not identify the product. Please take a clearer photo.',
          ),
        ),
      );

      return;
    }

    debugPrint(
      'OCR identified product: ${product.name}',
    );

    debugPrint(
      'OCR identified brand: ${product.brand}',
    );

    // --------------------------------------------------
    // STEP 4: Show AI Analysis
    // --------------------------------------------------

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAnalysisScreen(
          capturedImage: FileImage(
            File(image.path),
          ),
          product: product,
          productName: product.name,
          productSubtitle: product.brand,
          servingInfo: 'Serving information unavailable',
          foodTypeLabel: 'Food Product',
        ),
      ),
    );

    if (!mounted) return;
  } catch (e) {
    if (!mounted) return;

    debugPrint('Manual capture error: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not process image: $e'),
      ),
    );
  } finally {
    _isManualCapturing = false;
    if (mounted) {
      _setProcessingState(false);
    }

    // Restart barcode scanning.
    final currentCamera = _cameraController;

    if (mounted &&
        currentCamera != null &&
        currentCamera.value.isInitialized &&
        !currentCamera.value.isStreamingImages) {
      try {
        _barcodeDetected = false;

        await currentCamera.startImageStream(
          _processCameraImage,
        );
      } catch (e) {
        debugPrint('Could not restart barcode scanning: $e');
      }
    }
  }
}



Future<void> _lookupFood(
  String barcode,
  XFile productImage,
) async {
  _setProcessingState(
    true,
    title: '🔍 Analyzing your product…',
    subtitle: 'Checking nutrition, ingredients & personalized compatibility.',
  );

  try {
    // Step 1: Try barcode lookup
    debugPrint('=== BARCODE LOOKUP STARTED ===');
    debugPrint('Barcode: $barcode');

    _setProcessingState(
      true,
      title: '🔍 Analyzing your product…',
      subtitle: 'Checking nutrition, ingredients & personalized compatibility.',
    );

    final product = await _foodService.getFoodByBarcode(barcode);

    if (!mounted) return;

    // If barcode lookup succeeded, show product and return
    if (product != null) {
      debugPrint('=== BARCODE LOOKUP SUCCESS ===');
      debugPrint('Product: ${product.name}');
      debugPrint('Brand: ${product.brand}');

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiAnalysisScreen(
            capturedImage: FileImage(
              File(productImage.path),
            ),
            product: product,
            productName: product.name,
            productSubtitle: product.brand ?? 'Food Product',
            servingInfo: 'Serving information unavailable',
            foodTypeLabel: 'Food Product',
          ),
        ),
      );

      if (!mounted) return;

      _barcodeDetected = false;
      _isProcessingImage = false;

      final camera = _cameraController;

      if (camera != null &&
          camera.value.isInitialized &&
          !camera.value.isStreamingImages) {
        await camera.startImageStream(_processCameraImage);
      }

      return;
    }

    // Step 2: Barcode lookup failed, try OCR fallback
    debugPrint('=== BARCODE NOT FOUND, STARTING OCR FALLBACK ===');

    _setProcessingState(
      true,
      title: '🔍 Analyzing your product…',
      subtitle: 'Checking nutrition, ingredients & personalized compatibility.',
    );

    final ocrProduct = await resolveProductFromOcr(productImage);

    if (!mounted) return;

    // Step 3: Check OCR result
    if (ocrProduct != null) {
      debugPrint('=== OCR FALLBACK SUCCESS ===');
      debugPrint('Product: ${ocrProduct.name}');

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiAnalysisScreen(
            capturedImage: FileImage(
              File(productImage.path),
            ),
            product: ocrProduct,
            productName: ocrProduct.name,
            productSubtitle: ocrProduct.brand ?? 'Food Product',
            servingInfo: 'Serving information unavailable',
            foodTypeLabel: 'Food Product',
          ),
        ),
      );

      if (!mounted) return;

      _barcodeDetected = false;
      _isProcessingImage = false;

      final camera = _cameraController;

      if (camera != null &&
          camera.value.isInitialized &&
          !camera.value.isStreamingImages) {
        await camera.startImageStream(_processCameraImage);
      }

      return;
    }

    // Step 4: Both barcode and OCR failed, show error
    debugPrint('=== BARCODE AND OCR BOTH FAILED ===');

    _barcodeDetected = false;
    _isProcessingImage = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not identify the product. Please take a clearer photo and try again.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final camera = _cameraController;

    if (camera != null &&
        camera.value.isInitialized &&
        !camera.value.isStreamingImages) {
      await camera.startImageStream(_processCameraImage);
    }
  } catch (e) {
    if (!mounted) return;

    debugPrint('_lookupFood error: $e');

    _barcodeDetected = false;
    _isProcessingImage = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error processing product: $e',
        ),
      ),
    );

    final camera = _cameraController;

    if (camera != null &&
        camera.value.isInitialized &&
        !camera.value.isStreamingImages) {
      try {
        await camera.startImageStream(_processCameraImage);
      } catch (_) {}
    }
  } finally {
    if (mounted) {
      _setProcessingState(false);
    }
  }
}


Future<void> _initializeCamera() async {
  final cameras = await availableCameras();

  if (cameras.isEmpty) return;

  final camera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.back,
    orElse: () => cameras.first,
  );

  final controller = CameraController(
  camera,
  ResolutionPreset.medium,
  enableAudio: false,
  imageFormatGroup: ImageFormatGroup.nv21,
);

  await controller.initialize();

  if (!mounted) {
    await controller.dispose();
    return;
  }

  setState(() {
    _cameraController = controller;
  });

  // Start automatically checking camera frames for barcodes.
  await controller.startImageStream(_processCameraImage);
}

bool _isProcessingImage = false;
bool _isManualCapturing = false;
bool _isScanProcessing = false;
String _processingTitle = '🔍 Analyzing your product…';
String _processingSubtitle = 'Checking nutrition, ingredients & personalized compatibility.';

void _setProcessingState(
  bool isProcessing, {
  String title = '🔍 Analyzing your product…',
  String subtitle = 'Checking nutrition, ingredients & personalized compatibility.',
}) {
  if (!mounted) return;

  setState(() {
    _isScanProcessing = isProcessing;
    _processingTitle = title;
    _processingSubtitle = subtitle;
  });
}

Future<void> _processCameraImage(CameraImage image) async {
  if (_isProcessingImage ||
      _barcodeDetected ||
      _isManualCapturing) {
    return;
  }

  _isProcessingImage = true;

  try {
    final camera = _cameraController;

    if (camera == null ||
        !camera.value.isInitialized ||
        image.planes.isEmpty) {
      return;
    }

    // Combine the image planes into one byte array.
    final bytes = WriteBuffer();

    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }

    final inputImage = InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        rotation: InputImageRotationValue.fromRawValue(
              camera.description.sensorOrientation,
            ) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );

    final barcodes = await _barcodeScanner.processImage(inputImage);

    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      final code = barcode.rawValue;

      if (code == null || code.isEmpty) continue;

      // Barcode found!
      _barcodeDetected = true;

      // Stop processing camera frames.
      await _cameraController?.stopImageStream();

      if (!mounted) return;

      _setProcessingState(
        true,
        title: '🔍 Analyzing your product…',
        subtitle: 'Checking nutrition, ingredients & personalized compatibility.',
      );

      // Capture the product image.
      final XFile productImage = await _cameraController!.takePicture();

      // Look up the barcode and pass the image too.
      await _lookupFood(code, productImage);

      break;
    }
  } catch (e) {
    debugPrint('Barcode detection error: $e');
  } finally {
    _isProcessingImage = false;
  }
}

@override

void dispose() {

  _barcodeScanner.close();

  _cameraController?.dispose();

  _scanLineCtrl.dispose();
  _entranceCtrl.dispose();

  super.dispose();
}

Future<void> _toggleFlash() async {
  if (_cameraController == null ||
      !_cameraController!.value.isInitialized) {
    return;
  }

  try {
    if (_flashOn) {
      await _cameraController!.setFlashMode(FlashMode.off);
    } else {
      await _cameraController!.setFlashMode(FlashMode.torch);
    }

    if (mounted) {
      setState(() {
        _flashOn = !_flashOn;
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash is not available on this camera.'),
        ),
      );
    }
  }
}

void _goBack() {
  switch (widget.source) {
    case CameraSource.home:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
      break;

    case CameraSource.scan:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ScanScreen(),
        ),
      );
      break;
  }
}

@override

Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

  return Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      fit: StackFit.expand,
      children: [
        // Dark scrim so the glass UI stays legible over any scene.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.6),
              ],
              stops: const [0.0, 0.22, 0.68, 1.0],
            ),
          ),
        ),

        SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entranceCtrl,
              curve: Curves.easeOut,
            ),
            child: Column(
              children: [
                SizedBox(height: 6 * scale),

                // TOP BAR
                _TopBar(
                  uiScale: scale,
                  flashOn: _flashOn,
                  onBack: _goBack,
                  onFlashToggle: _toggleFlash,
                ),

                SizedBox(height: 12 * scale),

                // TIP
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: _showTip
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                          ),
                          child: _TipBanner(
                            uiScale: scale,
                            onDismiss: () {
                              setState(() {
                                _showTip = false;
                              });
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // CAMERA AREA
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24 * scale,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 0.78,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // REAL CAMERA PREVIEW
                              if (_cameraController != null &&
                                  _cameraController!.value.isInitialized)
                                CameraPreview(_cameraController!)
                              else
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),

                              // YOUR UI SCANNER FRAME
                              _ScannerFrame(
                                uiScale: scale,
                                scanLineCtrl: _scanLineCtrl,
                              ),

                              if (_isScanProcessing)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    child: Center(
                                      child: Container(
                                        width: 250 * scale,
                                        padding: EdgeInsets.all(18 * scale),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(24 * scale),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.22),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 28 * scale,
                                              height: 28 * scale,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation(
                                                  Color(0xFF8F7BFF),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 16 * scale),
                                            Text(
                                              _processingTitle,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 21 * scale,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(height: 8 * scale),
                                            Text(
                                              _processingSubtitle,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.82),
                                                fontSize: 13 * scale,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // SIDE ACTIONS
                        Positioned(
                          right: 0,
                          child: _SideActions(
                            uiScale: scale,

                            // GALLERY
onGalleryTap: () async {
  final picker = ImagePicker();

  final image = await picker.pickImage(
    source: ImageSource.gallery,
  );

  if (image == null) return;

  if (!mounted) return;

  final analyzer = ProductImageAnalyzer();

  try {
    debugPrint('=== GALLERY IMAGE SELECTED ===');
    debugPrint('Image: ${image.path}');

    // Same barcode → OCR → product lookup pipeline
    // used by the analyzer.
    final product = await analyzer.analyze(image);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not identify the product. '
            'Please select a clearer image.',
          ),
        ),
      );

      return;
    }

    debugPrint('=== GALLERY PRODUCT FOUND ===');
    debugPrint('Product: ${product.name}');
    debugPrint('Brand: ${product.brand}');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAnalysisScreen(
          capturedImage: FileImage(
            File(image.path),
          ),
          product: product,
          productName: product.name,
          productSubtitle:
              product.brand ?? 'Food Product',
          servingInfo:
              'Serving information unavailable',
          foodTypeLabel: 'Food Product',
        ),
      ),
    );
  } catch (e) {
    debugPrint('Gallery analysis error: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not process the image: $e',
        ),
      ),
    );
  } finally {
    await analyzer.dispose();
  }
},

                            onHowToScanTap: widget.onHowToScanTap,

                            // HISTORY
                            onHistoryTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Recent Scans screen coming soon!',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // STATUS BAR
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                  ),
                  child: _StatusBar(
                    uiScale: scale,
                    autoMode: _autoMode,
                    onToggleAuto: () {
                      setState(() {
                        _autoMode = !_autoMode;
                      });
                    },
                  ),
                ),

                SizedBox(height: 14 * scale),

                // CAMERA CAPTURE BUTTON
                GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 72 * scale,
                    height: 72 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white70,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),

                SizedBox(height: 14 * scale),

                // TRUST FOOTER
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                  ),
                  child: _TrustFooter(
                    uiScale: scale,
                    onAccuracyTap: widget.onAccuracyInfoTap,
                  ),
                ),

                SizedBox(height: 10 * scale),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
    }

// ---------------------------------------------------------------------------
// Top bar: back, title, flash
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
const _TopBar({
required this.uiScale,
required this.flashOn,
this.onBack,
this.onFlashToggle,
});

final double uiScale;
final bool flashOn;
final VoidCallback? onBack;
final VoidCallback? onFlashToggle;

@override
Widget build(BuildContext context) {
return Padding(
padding: EdgeInsets.symmetric(horizontal: 16 * uiScale),
child: Row(
children: [
_GlassIconButton(
uiScale: uiScale,
icon: Icons.arrow_back,
onTap: onBack,
),
Expanded(
child: Column(
children: [
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.auto_awesome,
size: 15 * uiScale,
color: const Color(0xFF9B7BFA),
),
SizedBox(width: 5 * uiScale),
Text(
'Scan Product',
style: TextStyle(
color: Colors.white,
fontSize: 15.5 * uiScale,
fontWeight: FontWeight.w800,
),
),
],
),
Text(
'Get AI-powered nutrition insights',
style: TextStyle(
color: Colors.white70,
fontSize: 10.5 * uiScale,
),
),
],
),
),
_FlashPill(
uiScale: uiScale,
active: flashOn,
onTap: onFlashToggle,
),
],
),
);
}
}

class _GlassIconButton extends StatefulWidget {
const _GlassIconButton({
required this.uiScale,
required this.icon,
this.onTap,
this.iconColor = Colors.white,
});

final double uiScale;
final IconData icon;
final VoidCallback? onTap;
final Color iconColor;

@override
State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
double _scale = 1.0;

@override
Widget build(BuildContext context) {
return GestureDetector(
onTapDown: (_) => setState(() => _scale = 0.9),
onTapUp: (_) => setState(() => _scale = 1.0),
onTapCancel: () => setState(() => _scale = 1.0),
onTap: widget.onTap,
child: AnimatedScale(
scale: _scale,
duration: const Duration(milliseconds: 100),
child: Container(
width: 40 * widget.uiScale,
height: 40 * widget.uiScale,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.black.withValues(alpha: 0.35),
border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
),
child: Icon(
widget.icon,
color: widget.iconColor,
size: 18 * widget.uiScale,
),
),
),
);
}
}

class _FlashPill extends StatefulWidget {
const _FlashPill({required this.uiScale, required this.active, this.onTap});
final double uiScale;
final bool active;
final VoidCallback? onTap;

@override
State<_FlashPill> createState() => _FlashPillState();
}

class _FlashPillState extends State<_FlashPill> {
double _scale = 1.0;

@override
Widget build(BuildContext context) {
return GestureDetector(
onTapDown: (_) => setState(() => _scale = 0.94),
onTapUp: (_) => setState(() => _scale = 1.0),
onTapCancel: () => setState(() => _scale = 1.0),
onTap: widget.onTap,
child: AnimatedScale(
scale: _scale,
duration: const Duration(milliseconds: 100),
child: Container(
padding: EdgeInsets.symmetric(
horizontal: 12 * widget.uiScale,
vertical: 9 * widget.uiScale,
),
decoration: BoxDecoration(
color: Colors.black.withValues(alpha: 0.35),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.bolt_rounded,
size: 14 * widget.uiScale,
color: widget.active
? const Color(0xFF5CE0A0)
: Colors.white70,
),
SizedBox(width: 4 * widget.uiScale),
Text(
'Flash',
style: TextStyle(
color: Colors.white,
fontSize: 11.5 * widget.uiScale,
fontWeight: FontWeight.w600,
),
),
],
),
),
),
);
}
}

// ---------------------------------------------------------------------------
// Tip banner (uses the DietCompass robot asset)
// ---------------------------------------------------------------------------
class _TipBanner extends StatelessWidget {
const _TipBanner({required this.uiScale, required this.onDismiss});
final double uiScale;
final VoidCallback onDismiss;

@override
Widget build(BuildContext context) {
return Container(
padding: EdgeInsets.all(10 * uiScale),
decoration: BoxDecoration(
color: Colors.black.withValues(alpha: 0.4),
borderRadius: BorderRadius.circular(18),
border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 36 * uiScale,
height: 36 * uiScale,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.white.withValues(alpha: 0.08),
border: Border.all(
color: const Color(0xFF9B7BFA),
width: 1.2,
),
),
clipBehavior: Clip.antiAlias,
child: Transform.scale(
scale: 1.45, // Try 1.4–1.7
child: Image.asset(
'assets/images/robot_badge.png',
fit: BoxFit.cover,
),
),
),
SizedBox(width: 10 * uiScale),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
RichText(
text: TextSpan(
style: TextStyle(
fontSize: 12.5 * uiScale,
fontWeight: FontWeight.w700,
color: Colors.white,
),
children: const [
TextSpan(text: 'Tip: Center the product label '),
TextSpan(
text: 'in the frame',
style: TextStyle(color: Color(0xFFB39CFB)),
),
],
),
),
SizedBox(height: 2 * uiScale),
Text(
'Make sure the text is clear and well-lit.',
style: TextStyle(
fontSize: 10.5 * uiScale,
color: Colors.white70,
),
),
],
),
),
GestureDetector(
onTap: onDismiss,
child: Icon(
Icons.close,
size: 16 * uiScale,
color: Colors.white54,
),
),
],
),
);
}
}

// ---------------------------------------------------------------------------
// Scanner frame: corner brackets + moving scan line + sparkles
// ---------------------------------------------------------------------------
class _ScannerFrame extends StatelessWidget {
const _ScannerFrame({required this.uiScale, required this.scanLineCtrl});
final double uiScale;
final AnimationController scanLineCtrl;

@override
Widget build(BuildContext context) {
return LayoutBuilder(
builder: (context, constraints) {
return Stack(
children: [
Positioned.fill(
child: CustomPaint(painter: _CornerBracketsPainter()),
),
AnimatedBuilder(
animation: scanLineCtrl,
builder: (context, _) {
final y = 16 + scanLineCtrl.value * (constraints.maxHeight - 32);
return Positioned(
left: 8,
right: 8,
top: y,
child: Container(
height: 2.4,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(4),
gradient: LinearGradient(
colors: [
Colors.transparent,
const Color(0xFF5CE0A0).withValues(alpha: 0.95),
Colors.transparent,
],
),
boxShadow: [
BoxShadow(
color: const Color(0xFF5CE0A0).withValues(alpha: 0.7),
blurRadius: 10,
spreadRadius: 1,
),
],
),
),
);
},
),
_ScannerSparkles(controller: scanLineCtrl),
],
);
},
);
}
}

class _CornerBracketsPainter extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()
..color = const Color(0xFF5CE0A0)
..style = PaintingStyle.stroke
..strokeWidth = 3.5
..strokeCap = StrokeCap.round
..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

const len = 28.0;
const r = 14.0;

void corner(Offset origin, bool right, bool bottom) {
  final dx = right ? -1.0 : 1.0;
  final dy = bottom ? -1.0 : 1.0;
  final path = Path()
    ..moveTo(origin.dx, origin.dy + dy * len)
    ..lineTo(origin.dx, origin.dy + dy * r)
    ..quadraticBezierTo(
      origin.dx,
      origin.dy,
      origin.dx + dx * r,
      origin.dy,
    )
    ..lineTo(origin.dx + dx * len, origin.dy);
  canvas.drawPath(path, paint);
}

corner(const Offset(0, 0), false, false);
corner(Offset(size.width, 0), true, false);
corner(Offset(0, size.height), false, true);
corner(Offset(size.width, size.height), true, true);
}

@override
bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerSparkles extends StatelessWidget {
const _ScannerSparkles({required this.controller});
final AnimationController controller;

static const _positions = [Offset(0.15, 0.2), Offset(0.85, 0.35), Offset(0.75, 0.8)];

@override
Widget build(BuildContext context) {
return LayoutBuilder(
builder: (context, constraints) {
return AnimatedBuilder(
animation: controller,
builder: (context, _) {
return Stack(
children: List.generate(_positions.length, (i) {
final phase = (controller.value + i / _positions.length) % 1;
final opacity = (math.sin(phase * math.pi * 2) + 1) / 2;
final pos = _positions[i];
return Positioned(
left: constraints.maxWidth * pos.dx,
top: constraints.maxHeight * pos.dy,
child: Opacity(
opacity: 0.2 + opacity * 0.5,
child: Icon(
Icons.auto_awesome,
size: 10,
color: const Color(0xFF9B7BFA),
),
),
);
}),
);
},
);
},
);
}
}

// ---------------------------------------------------------------------------
// Side action icons: Gallery / How to scan / History
// ---------------------------------------------------------------------------
class _SideActions extends StatelessWidget {
const _SideActions({
required this.uiScale,
this.onGalleryTap,
this.onHowToScanTap,
this.onHistoryTap,
});

final double uiScale;
final VoidCallback? onGalleryTap;
final VoidCallback? onHowToScanTap;
final VoidCallback? onHistoryTap;

@override
Widget build(BuildContext context) {
return Column(
children: [
_SideAction(
uiScale: uiScale,
icon: Icons.image_outlined,
label: 'Gallery',
onTap: onGalleryTap,
),
SizedBox(height: 18 * uiScale),
_SideAction(
uiScale: uiScale,
icon: Icons.help_outline,
label: 'How to scan',
onTap: onHowToScanTap,
),
SizedBox(height: 18 * uiScale),
_SideAction(
uiScale: uiScale,
icon: Icons.history_rounded,
label: 'History',
onTap: onHistoryTap,
),
],
);
}
}

class _SideAction extends StatefulWidget {
const _SideAction({
required this.uiScale,
required this.icon,
required this.label,
this.onTap,
});

final double uiScale;
final IconData icon;
final String label;
final VoidCallback? onTap;

@override
State<_SideAction> createState() => _SideActionState();
}

class _SideActionState extends State<_SideAction> {
double _scale = 1.0;

@override
Widget build(BuildContext context) {
return GestureDetector(
onTapDown: (_) => setState(() => _scale = 0.9),
onTapUp: (_) => setState(() => _scale = 1.0),
onTapCancel: () => setState(() => _scale = 1.0),
onTap: widget.onTap,
child: AnimatedScale(
scale: _scale,
duration: const Duration(milliseconds: 100),
child: Column(
children: [
Container(
width: 42 * widget.uiScale,
height: 42 * widget.uiScale,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.black.withValues(alpha: 0.4),
border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
),
child: Icon(
widget.icon,
color: Colors.white,
size: 18 * widget.uiScale,
),
),
SizedBox(height: 4 * widget.uiScale),
Text(
widget.label,
style: TextStyle(
color: Colors.white70,
fontSize: 9.5 * widget.uiScale,
fontWeight: FontWeight.w600,
),
),
],
),
),
);
}
}

// ---------------------------------------------------------------------------
// Status bar: "AI is ready to analyze" + Auto/Manual toggle
// ---------------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
const _StatusBar({
required this.uiScale,
required this.autoMode,
required this.onToggleAuto,
});

final double uiScale;
final bool autoMode;
final VoidCallback onToggleAuto;

@override
Widget build(BuildContext context) {
return Column(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
if (autoMode)
Container(
margin: EdgeInsets.only(bottom: 6 * uiScale, right: 4 * uiScale),
padding: EdgeInsets.symmetric(
horizontal: 8 * uiScale,
vertical: 3 * uiScale,
),
decoration: BoxDecoration(
color: const Color(0xFF1E8A4C),
borderRadius: BorderRadius.circular(10),
),
child: Text(
'Best Results',
style: TextStyle(
color: Colors.white,
fontSize: 9.5 * uiScale,
fontWeight: FontWeight.w700,
),
),
),
Container(
padding: EdgeInsets.symmetric(
horizontal: 14 * uiScale,
vertical: 10 * uiScale,
),
decoration: BoxDecoration(
color: Colors.black.withValues(alpha: 0.45),
borderRadius: BorderRadius.circular(18),
border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
),
child: Row(
children: [
Icon(
Icons.center_focus_strong,
color: const Color(0xFF9B7BFA),
size: 20 * uiScale,
),
SizedBox(width: 10 * uiScale),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'AI is ready to analyze',
style: TextStyle(
color: Colors.white,
fontSize: 12.5 * uiScale,
fontWeight: FontWeight.w700,
),
),
Text(
'Place the label inside the frame',
style: TextStyle(
color: Colors.white60,
fontSize: 10.5 * uiScale,
),
),
],
),
),
GestureDetector(
onTap: onToggleAuto,
child: AnimatedContainer(
duration: const Duration(milliseconds: 200),
padding: EdgeInsets.symmetric(
horizontal: 12 * uiScale,
vertical: 8 * uiScale,
),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(14),
gradient: autoMode
? const LinearGradient(
colors: [Color(0xFF6C4EF5), Color(0xFF8A6CF5)],
)
: null,
color: autoMode ? null : Colors.white.withValues(alpha: 0.12),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.auto_awesome,
size: 13 * uiScale,
color: Colors.white,
),
SizedBox(width: 4 * uiScale),
Text(
autoMode ? 'Auto' : 'Manual',
style: TextStyle(
color: Colors.white,
fontSize: 12 * uiScale,
fontWeight: FontWeight.w700,
),
),
],
),
),
),
],
),
),
],
);
}
}

// ---------------------------------------------------------------------------
// Trust footer
// ---------------------------------------------------------------------------
class _TrustFooter extends StatelessWidget {
const _TrustFooter({required this.uiScale, this.onAccuracyTap});
final double uiScale;
final VoidCallback? onAccuracyTap;

@override
Widget build(BuildContext context) {
return Container(
padding: EdgeInsets.symmetric(
horizontal: 12 * uiScale,
vertical: 10 * uiScale,
),
decoration: BoxDecoration(
color: Colors.black.withValues(alpha: 0.4),
borderRadius: BorderRadius.circular(16),
border: Border.all(color: const Color(0xFF5CE0A0).withValues(alpha: 0.3)),
),
child: Row(
children: [
Icon(
Icons.shield_rounded,
color: const Color(0xFF5CE0A0),
size: 18 * uiScale,
),
SizedBox(width: 8 * uiScale),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'100% Private & Secure',
style: TextStyle(
color: Colors.white,
fontSize: 11 * uiScale,
fontWeight: FontWeight.w700,
),
),
Text(
'Your data is only used to improve your health.',
style: TextStyle(
color: Colors.white60,
fontSize: 9 * uiScale,
),
),
],
),
),
Container(
width: 1,
height: 30 * uiScale,
margin: EdgeInsets.symmetric(horizontal: 8 * uiScale),
color: Colors.white.withValues(alpha: 0.15),
),
Icon(
Icons.psychology_alt_rounded,
color: const Color(0xFF9B7BFA),
size: 18 * uiScale,
),
SizedBox(width: 8 * uiScale),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'AI-Powered Accuracy',
style: TextStyle(
color: Colors.white,
fontSize: 11 * uiScale,
fontWeight: FontWeight.w700,
),
),
Text(
'Analyzing 50+ nutrition factors in seconds.',
style: TextStyle(
color: Colors.white60,
fontSize: 9 * uiScale,
),
),
],
),
),
GestureDetector(
onTap: onAccuracyTap,
child: Icon(
Icons.chevron_right,
color: Colors.white54,
size: 16 * uiScale,
),
),
],
),
);
}
}

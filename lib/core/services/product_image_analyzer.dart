import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/services/food_service.dart';
import '../../core/model/food_product.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/food_image_validator.dart';

class ProductImageAnalyzer {
  final FoodService _foodService = FoodService();

  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // ============================================================
  // MAIN PIPELINE
  // ============================================================

  Future<FoodProduct?> analyze(XFile image) async {
    debugPrint('[IMAGE] Image selected: ${image.path}');
    debugPrint('[IMAGE VALIDATION] Starting food-product validation');

    // ----------------------------------------------------------
    // STEP 1: BARCODE
    // ----------------------------------------------------------

    try {
      final inputImage = InputImage.fromFilePath(image.path);

      final barcodes =
          await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        for (final barcode in barcodes) {
          final code = barcode.rawValue;

          if (code == null || code.isEmpty) {
            continue;
          }

          debugPrint('=== BARCODE DETECTED ===');
          debugPrint('Barcode: $code');

          final product =
              await _foodService.getFoodByBarcode(code);

          if (product != null) {
            debugPrint('[IMAGE VALIDATION] isFoodProduct = true');
            debugPrint('[IMAGE VALIDATION] evidence = valid barcode ($code)');
            debugPrint('[IMAGE VALIDATION] Product identity accepted: ${product.name}');
            debugPrint('[PRODUCT] Candidate product: ${product.name}');
            debugPrint('[PRODUCT] Verification result: PASSED');
            return product;
          }
        }
      }

      debugPrint(
        '=== BARCODE NOT FOUND / PRODUCT NOT FOUND ===',
      );
    } catch (e) {
      debugPrint(
        'Barcode detection error: $e',
      );
    }

    // ----------------------------------------------------------
    // STEP 2: OCR FALLBACK WITH EVIDENCE VALIDATION
    // ----------------------------------------------------------

    debugPrint(
      '=== STARTING OCR FALLBACK WITH EVIDENCE VALIDATION ===',
    );

    return await resolveProductFromOcr(image);
  }

  // ============================================================
  // OCR PRODUCT RESOLUTION
  // ============================================================

  Future<FoodProduct?> resolveProductFromOcr(
    XFile image,
  ) async {
    try {
      final inputImage =
          InputImage.fromFilePath(image.path);

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.trim().isEmpty) {
        debugPrint('[IMAGE VALIDATION] isFoodProduct = false');
        debugPrint('[IMAGE VALIDATION] confidence = 0.00');
        debugPrint('[IMAGE VALIDATION] evidence = none');
        debugPrint('[IMAGE VALIDATION] REJECTED: no food evidence in image');
        return null;
      }

      debugPrint(
        '========== OCR RESOLUTION STARTED ==========',
      );

      debugPrint(
        'Raw OCR text:\n${recognizedText.text}',
      );

      // --------------------------------------------------------
      // STEP 1: Extract OCR candidates
      // --------------------------------------------------------

      final candidates =
          extractOcrCandidates(recognizedText);

      if (candidates.isEmpty) {
        debugPrint('[IMAGE VALIDATION] isFoodProduct = false');
        debugPrint('[IMAGE VALIDATION] confidence = 0.00');
        debugPrint('[IMAGE VALIDATION] evidence = none');
        debugPrint('[IMAGE VALIDATION] REJECTED: no food evidence in image');
        return null;
      }

      debugPrint(
        'OCR candidates: $candidates',
      );

      // --------------------------------------------------------
      // STEP 2: Normalize + OCR correction + deduplicate
      // --------------------------------------------------------

      final normalized = <String>{};

      for (final candidate in candidates) {
        final norm =
            normalizeOcrText(candidate);

        if (norm.isNotEmpty) {
          normalized.add(norm);

          // Also add corrected version.
          final corrected =
              correctCommonOcrErrors(norm);

          if (corrected.isNotEmpty) {
            normalized.add(corrected);
          }
        }
      }

      final meaningfulCandidates =
          normalized.where(_isMeaningfulOcrCandidate).toList();

      if (meaningfulCandidates.isEmpty) {
        debugPrint('[IMAGE VALIDATION] isFoodProduct = false');
        debugPrint('[IMAGE VALIDATION] confidence = 0.00');
        debugPrint('[IMAGE VALIDATION] evidence = none');
        debugPrint('[IMAGE VALIDATION] REJECTED: no meaningful food candidates');
        return null;
      }

      // --------------------------------------------------------
      // STEP 3: Prioritize candidates by specificity
      // --------------------------------------------------------

      final orderedCandidates =
          _sortCandidatesBySpecificity(
        meaningfulCandidates,
      ).take(6).toList();

      debugPrint(
        'Ordered search candidates: $orderedCandidates',
      );

      // --------------------------------------------------------
      // STEP 4: Search products
      // --------------------------------------------------------

      FoodProduct? bestMatch;
      double bestScore = 0.0;
      String bestMatchQuery = '';

      for (final candidate in orderedCandidates) {
        final products =
            await _foodService.getFoodsByName(candidate);

        if (products.isEmpty) {
          continue;
        }

        for (final product in products) {
          final score =
              calculateProductScore(
            candidate,
            product,
          );

          if (score <= 0) {
            continue;
          }

          if (score > bestScore) {
            bestScore = score;
            bestMatch = product;
            bestMatchQuery = candidate;
          }
        }
      }

      // --------------------------------------------------------
      // STEP 5: Final evidence-grounded validation
      // --------------------------------------------------------

      const minimumConfidence = 0.62;

      if (bestMatch != null && bestScore >= minimumConfidence) {
        final validationResult = FoodImageValidator.instance.validateCandidateProduct(
          product: bestMatch,
          recognizedText: recognizedText,
          matchConfidence: bestScore,
        );

        if (validationResult.isFoodProduct) {
          debugPrint(
            '========== OCR RESOLUTION SUCCESS ==========\n'
            'Query: "$bestMatchQuery"\n'
            'Product: "${bestMatch.name}"\n'
            'Brand: "${bestMatch.brand}"\n'
            'Confidence: ${bestScore.toStringAsFixed(3)}\n'
            '============================================',
          );
          return await _foodService.enrichProduct(bestMatch);
        }
      }

      // --------------------------------------------------------
      // STEP 6: Gemini AI OCR Vision Fallback (Validate before return)
      // --------------------------------------------------------
      if (recognizedText.text.trim().isNotEmpty) {
        debugPrint('🤖 OCR fallback: Resolving product label with Gemini AI...');
        try {
          final geminiProduct = await AiService.instance.lookupProductWithGemini(
            ocrText: recognizedText.text,
          );
          if (geminiProduct != null) {
            final validationResult = FoodImageValidator.instance.validateCandidateProduct(
              product: geminiProduct,
              recognizedText: recognizedText,
              matchConfidence: 0.85,
            );

            if (validationResult.isFoodProduct) {
              debugPrint('✅ OCR Gemini AI resolution success: ${geminiProduct.name}');
              return geminiProduct;
            }
          }
        } catch (e) {
          debugPrint('Gemini OCR resolution error: $e');
        }
      }

      debugPrint('[IMAGE VALIDATION] isFoodProduct = false');
      debugPrint('[IMAGE VALIDATION] confidence = ${bestScore.toStringAsFixed(2)}');
      debugPrint('[IMAGE VALIDATION] evidence = none');
      debugPrint('[IMAGE VALIDATION] REJECTED: no food evidence in image');
      return null;
    } catch (e, stackTrace) {
      debugPrint('OCR resolution error: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }

  static const Set<String> _noiseKeywords = {
    'buy',
    'visit',
    'save',
    'more',
    'share',
    'online',
    'lowest',
    'price',
    'offer',
    'promo',
    'shop',
    'shopping',
    'click',
    'fresh',
    'today',
    'deal',
    'best',
    'discount',
    'limited',
    'only',
    'new',
    'app',
    'website',
    'www',
    'http',
    'https',
  };

  bool _isMeaningfulOcrCandidate(String candidate) {
    final cleaned = normalizeOcrText(candidate);

    if (cleaned.isEmpty || cleaned.length < 3) {
      return false;
    }

    final words = _getWords(cleaned)
        .where((word) => word.length > 1)
        .where((word) => !_noiseKeywords.contains(word))
        .toList();

    if (words.isEmpty) {
      return false;
    }

    if (words.length < 2) {
      return false;
    }

    final joined = words.join(' ');
    if (joined.contains('save more') || joined.contains('visit save') || joined.contains('share more')) {
      return false;
    }

    return true;
  }

  // ============================================================
  // PRODUCT SCORING
  // ============================================================

  double calculateProductScore(
    String candidate,
    FoodProduct product,
  ) {
    final candidateName =
        correctCommonOcrErrors(
      normalizeOcrText(candidate),
    );

    final productName =
        normalizeOcrText(product.name);

    final brandName =
        normalizeOcrText(product.brand);

    if (candidateName.isEmpty ||
        productName.isEmpty) {
      return 0.0;
    }

    final candidateWords =
        _getWords(candidateName);

    final productWords =
        _getWords(productName);

    final brandWords =
        _getWords(brandName);

    if (candidateWords.isEmpty ||
        productWords.isEmpty) {
      return 0.0;
    }

    if (candidateWords.any(_noiseKeywords.contains)) {
      return 0.0;
    }

    // ----------------------------------------------------------
    // GENERIC PRODUCT DETECTION
    //
    // These words are too generic to identify a packaged product.
    //
    // Example:
    //
    // OCR = "milk"
    // Product = "MILK"
    //
    // This must NOT automatically receive 1.0.
    // ----------------------------------------------------------

    final genericWords = <String>{
      'milk',
      'water',
      'juice',
      'drink',
      'soda',
      'sugar',
      'salt',
      'rice',
      'flour',
      'bread',
      'tea',
      'coffee',
      'oil',
      'butter',
      'cheese',
      'cream',
      'biscuit',
      'biscuits',
      'chocolate',
      'food',
      'snack',
      'noodles',
      'pasta',
    };

    final candidateIsOnlyGenericWords =
        candidateWords.isNotEmpty &&
        candidateWords.every(
          (word) => genericWords.contains(word),
        );

    final productIsOnlyGenericWords =
        productWords.isNotEmpty &&
        productWords.every(
          (word) => genericWords.contains(word),
        );

    // ----------------------------------------------------------
    // WORD MATCHING
    // ----------------------------------------------------------

    int matchingWords = 0;

    double totalWordSimilarity = 0.0;

    final usedProductIndexes = <int>{};

    for (final candidateWord in candidateWords) {
      double bestWordScore = 0.0;

      int bestIndex = -1;

      for (int i = 0;
          i < productWords.length;
          i++) {
        if (usedProductIndexes.contains(i)) {
          continue;
        }

        final productWord =
            productWords[i];

        final similarity =
            _wordSimilarity(
          candidateWord,
          productWord,
        );

        if (similarity > bestWordScore) {
          bestWordScore = similarity;
          bestIndex = i;
        }
      }

      if (bestWordScore >= 0.72 &&
          bestIndex >= 0) {
        matchingWords++;

        totalWordSimilarity +=
            bestWordScore;

        usedProductIndexes.add(
          bestIndex,
        );
      }
    }

    if (matchingWords == 0) {
      return 0.0;
    }

    // ----------------------------------------------------------
    // COVERAGE
    // ----------------------------------------------------------

    final ocrCoverage =
        matchingWords /
            candidateWords.length;

    final productCoverage =
        matchingWords /
            productWords.length;

    // ----------------------------------------------------------
    // BASE SIMILARITY
    // ----------------------------------------------------------

    final averageWordSimilarity =
        totalWordSimilarity /
            matchingWords;

    // ----------------------------------------------------------
    // PHRASE MATCH
    //
    // Very important:
    //
    // "dairy milk"
    //
    // should score much better than:
    //
    // "milk"
    //
    // when product name contains both.
    // ----------------------------------------------------------

    double phraseBonus = 0.0;

    if (candidateWords.length >= 2) {
      final candidatePhrase =
          candidateWords.join(' ');

      if (productName.contains(
        candidatePhrase,
      )) {
        phraseBonus += 0.22;
      }
    }

    // ----------------------------------------------------------
    // BRAND MATCH
    //
    // If OCR contains a brand, strongly reward it.
    // ----------------------------------------------------------

    double brandBonus = 0.0;

    if (brandWords.isNotEmpty) {
      int brandMatches = 0;

      for (final brandWord in brandWords) {
        for (final candidateWord
            in candidateWords) {
          if (_wordSimilarity(
                brandWord,
                candidateWord,
              ) >=
              0.78) {
            brandMatches++;
            break;
          }
        }
      }

      if (brandMatches > 0) {
        brandBonus = 0.20;
      }
    }

    // ----------------------------------------------------------
    // SPECIFICITY BONUS
    //
    // Longer OCR phrases contain more information.
    //
    // 1 word  → no bonus
    // 2 words → small bonus
    // 3+ words → stronger bonus
    // ----------------------------------------------------------

    double specificityBonus = 0.0;

    if (candidateWords.length >= 2) {
      specificityBonus += 0.05;
    }

    if (candidateWords.length >= 3) {
      specificityBonus += 0.08;
    }

    if (candidateWords.length >= 4) {
      specificityBonus += 0.05;
    }

    // ----------------------------------------------------------
    // EXACT MULTI-WORD MATCH
    // ----------------------------------------------------------

    double exactPhraseBonus = 0.0;

    if (candidateWords.length >= 2 &&
        productName == candidateName) {
      exactPhraseBonus = 0.20;
    }

    // ----------------------------------------------------------
    // FINAL SCORE
    // ----------------------------------------------------------

    double score =
        (ocrCoverage * 0.30) +
        (productCoverage * 0.20) +
        (averageWordSimilarity * 0.25) +
        phraseBonus +
        brandBonus +
        specificityBonus +
        exactPhraseBonus;

    // ----------------------------------------------------------
    // CRITICAL GENERIC-WORD PENALTY
    //
    // Example:
    //
    // Candidate = "milk"
    // Product = "MILK"
    //
    // Exact match would normally be very high.
    //
    // But because both are generic, reduce heavily.
    // ----------------------------------------------------------

    if (candidateIsOnlyGenericWords &&
        productIsOnlyGenericWords) {
      score *= 0.48;

      debugPrint(
        '⚠️ Generic-only match penalty: '
        '"$candidate" → "${product.name}"',
      );
    }

    // ----------------------------------------------------------
    // SINGLE GENERIC WORD PENALTY
    //
    // "milk" should not beat "dairy milk chocolate".
    // ----------------------------------------------------------

    if (candidateWords.length == 1 &&
        candidateIsOnlyGenericWords) {
      score *= 0.55;

      debugPrint(
        '⚠️ Generic single-word penalty: '
        '"$candidate" → "${product.name}"',
      );
    }

    // ----------------------------------------------------------
    // PRODUCT NAME IS MUCH LONGER
    //
    // Example:
    //
    // OCR = "milk"
    // Product = "Milk Chocolate Biscuits"
    //
    // Don't accept it as a strong match.
    // ----------------------------------------------------------

    if (candidateWords.length == 1 &&
        productWords.length >= 3) {
      score *= 0.72;
    }

    // ----------------------------------------------------------
    // OCR MATCHED ONLY ONE WORD OUT OF A MULTI-WORD QUERY
    // ----------------------------------------------------------

    if (candidateWords.length >= 2 &&
        matchingWords == 1) {
      score *= 0.65;
    }

    // ----------------------------------------------------------
    // Clamp
    // ----------------------------------------------------------

    score =
        score.clamp(0.0, 1.0);

    return score;
  }

  // ============================================================
  // OCR CANDIDATE EXTRACTION
  // ============================================================

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

    // ----------------------------------------------------------
    // Read OCR blocks and lines
    // ----------------------------------------------------------

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text =
            line.text.trim();

        if (text.isEmpty) {
          continue;
        }

        final lower =
            text.toLowerCase();

        // ------------------------------------------------------
        // Ignore nutrition / packaging information
        // ------------------------------------------------------

        if (ignoredWords.any(
          (word) => lower.contains(word),
        )) {
          continue;
        }

        // ------------------------------------------------------
        // Make sure the line contains enough letters
        // ------------------------------------------------------

        final letterCount =
            RegExp(r'[A-Za-z]')
                .allMatches(text)
                .length;

        if (letterCount < 2) {
          continue;
        }

        // ------------------------------------------------------
        // Ignore mostly numbers/symbols
        // ------------------------------------------------------

        if (letterCount / text.length < 0.45) {
          continue;
        }

        // ------------------------------------------------------
        // Ignore extremely long lines
        // ------------------------------------------------------

        if (text.length > 60) {
          continue;
        }

        if (text.length < 2) {
          continue;
        }

        ocrLines.add(text);
      }
    }

    // ----------------------------------------------------------
    // Individual lines
    // ----------------------------------------------------------

    candidates.addAll(ocrLines);

    // ----------------------------------------------------------
    // Combine consecutive 2-line candidates
    //
    // Dairy
    // Milk
    //
    // becomes:
    //
    // Dairy Milk
    // ----------------------------------------------------------

    for (int i = 0;
        i < ocrLines.length;
        i++) {
      if (i + 1 < ocrLines.length) {
        final combined =
            '${ocrLines[i]} '
            '${ocrLines[i + 1]}';

        if (combined.length <= 40) {
          candidates.add(combined);
        }
      }

      // --------------------------------------------------------
      // Combine consecutive 3-line candidates
      //
      // Dairy
      // Milk
      // Chocolate
      //
      // becomes:
      //
      // Dairy Milk Chocolate
      // --------------------------------------------------------

      if (i + 2 < ocrLines.length) {
        final combined =
            '${ocrLines[i]} '
            '${ocrLines[i + 1]} '
            '${ocrLines[i + 2]}';

        if (combined.length <= 50) {
          candidates.add(combined);
        }
      }

      // --------------------------------------------------------
      // Combine consecutive 4-line candidates
      // --------------------------------------------------------

      if (i + 3 < ocrLines.length) {
        final combined =
            '${ocrLines[i]} '
            '${ocrLines[i + 1]} '
            '${ocrLines[i + 2]} '
            '${ocrLines[i + 3]}';

        if (combined.length <= 60) {
          candidates.add(combined);
        }
      }
    }

    return candidates;
  }

  // ============================================================
  // NORMALIZATION
  // ============================================================

  String normalizeOcrText(
    String text,
  ) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .replaceAll(
          RegExp(r'[^\w\s-]'),
          '',
        );
  }

  // ============================================================
  // COMMON OCR CORRECTIONS
  // ============================================================

  String correctCommonOcrErrors(
    String text,
  ) {
    if (text.trim().isEmpty) {
      return '';
    }

    final corrections = <String, String>{
      // Chocolate
      'chogolate': 'chocolate',
      'choclate': 'chocolate',
      'chocollate': 'chocolate',
      'chocolat': 'chocolate',

      // Dairy
      'dairy': 'dairy',

      // Milk
      'mi1k': 'milk',
      'miik': 'milk',

      // Cadbury
      'cadiby': 'cadbury',
      'cadburry': 'cadbury',
      'cadbry': 'cadbury',

      // Frooti
      'frootl': 'frooti',
      'frootii': 'frooti',
      'fr0oti': 'frooti',

      // Thums Up
      'thumsup': 'thums up',
      'thum sup': 'thums up',
      'thumbs up': 'thums up',

      // Sprite
      'sprlte': 'sprite',
      'spr1te': 'sprite',

      // Coca Cola
      'coca-cola': 'coca cola',
      'cocacola': 'coca cola',
    };

    final words =
        text.split(RegExp(r'\s+'));

    final correctedWords =
        words.map((word) {
      return corrections[word] ?? word;
    }).toList();

    return correctedWords.join(' ');
  }

  // ============================================================
  // SORT CANDIDATES BY SPECIFICITY
  // ============================================================

  List<String> _sortCandidatesBySpecificity(
    List<String> candidates,
  ) {
    final unique =
        candidates
            .map(correctCommonOcrErrors)
            .where(
              (value) => value.isNotEmpty,
            )
            .toSet()
            .toList();

    unique.sort(
      (a, b) {
        final aWords =
            _getWords(a).length;

        final bWords =
            _getWords(b).length;

        // More words first.
        if (aWords != bWords) {
          return bWords.compareTo(
            aWords,
          );
        }

        // Longer phrase first.
        return b.length.compareTo(
          a.length,
        );
      },
    );

    return unique;
  }

  // ============================================================
  // WORD EXTRACTION
  // ============================================================

  List<String> _getWords(
    String text,
  ) {
    return text
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.trim(),
        )
        .where(
          (word) => word.isNotEmpty,
        )
        .toList();
  }

  // ============================================================
  // WORD SIMILARITY
  // ============================================================

  double _wordSimilarity(
    String a,
    String b,
  ) {
    final aLower =
        a.toLowerCase().trim();

    final bLower =
        b.toLowerCase().trim();

    if (aLower.isEmpty ||
        bLower.isEmpty) {
      return 0.0;
    }

    if (aLower == bLower) {
      return 1.0;
    }

    // ----------------------------------------------------------
    // Contains relationship
    // ----------------------------------------------------------

    if (aLower.length >= 5 &&
        bLower.length >= 5) {
      if (aLower.contains(bLower) ||
          bLower.contains(aLower)) {
        return 0.90;
      }
    }

    // ----------------------------------------------------------
    // Levenshtein fuzzy matching
    // ----------------------------------------------------------

    final distance =
        _levenshteinDistance(
      aLower,
      bLower,
    );

    final maxLength =
        math.max(
      aLower.length,
      bLower.length,
    );

    if (maxLength == 0) {
      return 0.0;
    }

    final similarity =
        1.0 -
        (distance / maxLength);

    // ----------------------------------------------------------
    // Prevent tiny words from matching too aggressively.
    // ----------------------------------------------------------

    if (math.min(
          aLower.length,
          bLower.length,
        ) <=
        3) {
      return similarity >= 0.90
          ? similarity
          : 0.0;
    }

    return similarity;
  }

  // ============================================================
  // LEVENSHTEIN DISTANCE
  // ============================================================

  int _levenshteinDistance(
    String a,
    String b,
  ) {
    if (a == b) {
      return 0;
    }

    if (a.isEmpty) {
      return b.length;
    }

    if (b.isEmpty) {
      return a.length;
    }

    final List<List<int>> matrix =
        List.generate(
      a.length + 1,
      (i) => List.filled(
        b.length + 1,
        0,
      ),
    );

    for (int i = 0;
        i <= a.length;
        i++) {
      matrix[i][0] = i;
    }

    for (int j = 0;
        j <= b.length;
        j++) {
      matrix[0][j] = j;
    }

    for (int i = 1;
        i <= a.length;
        i++) {
      for (int j = 1;
          j <= b.length;
          j++) {
        final cost =
            a[i - 1] ==
                    b[j - 1]
                ? 0
                : 1;

        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] +
              cost,
        ].reduce(
          (x, y) =>
              x < y ? x : y,
        );
      }
    }

    return matrix[a.length][b.length];
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  Future<void> dispose() async {
    await _barcodeScanner.close();
    _textRecognizer.close();
  }
}
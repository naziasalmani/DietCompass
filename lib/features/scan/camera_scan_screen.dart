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

    // Read individual OCR lines instead of simply taking the longest text.
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final String text = line.text.trim();

        if (text.isEmpty) continue;

        final String lower = text.toLowerCase();

        // Ignore common packaging / nutrition information.
        if (ignoredWords.any((word) => lower.contains(word))) {
          continue;
        }

        // Product names normally contain actual letters.
        final int letterCount =
            RegExp(r'[A-Za-z]').allMatches(text).length;

        if (letterCount < 3) {
          continue;
        }

        // Ignore text that is mostly numbers/symbols.
        if (letterCount / text.length < 0.45) {
          continue;
        }

        // Avoid extremely long sentences/descriptions.
        if (text.length > 60) {
          continue;
        }

        // Avoid tiny OCR fragments.
        if (text.length < 3) {
          continue;
        }

        candidates.add(text);
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
    // STEP 2: NO BARCODE → OCR
    // --------------------------------------------------

    debugPrint('No barcode found. Starting OCR...');

    final productName = await _extractProductName(image);

    if (!mounted) return;

    if (productName == null || productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not identify the product. Please take a clearer photo.',
          ),
        ),
      );

      return;
    }

    debugPrint('Detected product name: $productName');

    // --------------------------------------------------
    // STEP 3: Search Open Food Facts
    // --------------------------------------------------

    final product = await _foodService.getFoodByName(productName);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not find "$productName" in the food database.',
          ),
        ),
      );

      return;
    }

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
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    final product = await _foodService.getFoodByBarcode(barcode);

    if (!mounted) return;

    Navigator.pop(context);

   if (product == null) {
  _barcodeDetected = false;
  _isProcessingImage = false;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Product not found. Please upload a product image instead.',
      ),
      duration: Duration(seconds: 2),
    ),
  );

  // Restart barcode scanning
  final camera = _cameraController;

  if (camera != null &&
      camera.value.isInitialized &&
      !camera.value.isStreamingImages) {
    await camera.startImageStream(_processCameraImage);
  }

  return;
}

    // Barcode successfully found a product.
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

// User came back from AI Analysis.
// Reset barcode scanning so another product can be scanned.
if (!mounted) return;

_barcodeDetected = false;
_isProcessingImage = false;

final camera = _cameraController;

if (camera != null &&
    camera.value.isInitialized &&
    !camera.value.isStreamingImages) {
  await camera.startImageStream(_processCameraImage);
}
  } catch (e) {
    if (!mounted) return;

    Navigator.pop(context);

    _barcodeDetected = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not get product information: $e',
        ),
      ),
    );
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

// Capture the product image.
final XFile productImage =
    await _cameraController!.takePicture();

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

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AiAnalysisScreen(
                                    capturedImage: FileImage(
                                      File(image.path),
                                    ),
                                  ),
                                ),
                              );
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

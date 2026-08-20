import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/services/voice_assistant_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/model/ai_analysis_model.dart';
import 'ai_coach_screen.dart';

/// Shows the DietCompass Voice Assistant modal matching the dark theme reference UI
Future<void> showVoiceAssistantModal(
  BuildContext context, {
  String userName = 'Nazia',
  Function(String text)? onTextRecognized,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => VoiceAssistantModal(
      userName: userName,
      onTextRecognized: onTextRecognized,
    ),
  );
}

enum VoiceAssistantState {
  idle,
  listening,
  thinking,
  speaking,
  error,
}

class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({
    super.key,
    this.userName = 'Nazia',
    this.onTextRecognized,
  });

  final String userName;
  final Function(String text)? onTextRecognized;

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _dotsCtrl;

  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _spokenText = '';
  String _aiResponse = '';
  String _errorMessage = '';
  final List<AiCoachChatMessage> _history = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Auto-start listening on modal open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceInput();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _dotsCtrl.dispose();
    VoiceAssistantService.instance.stopListening();
    VoiceAssistantService.instance.stopSpeaking();
    super.dispose();
  }

  Future<void> _startVoiceInput() async {
    setState(() {
      _state = VoiceAssistantState.listening;
      _spokenText = '';
      _aiResponse = '';
      _errorMessage = '';
    });

    final success = await VoiceAssistantService.instance.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _spokenText = text;
        });

        if (isFinal && text.trim().isNotEmpty) {
          _sendToCoach(text);
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _state = VoiceAssistantState.error;
          _errorMessage = err;
        });
      },
      onDone: () {
        if (_spokenText.trim().isNotEmpty && _state == VoiceAssistantState.listening) {
          _sendToCoach(_spokenText);
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _state = VoiceAssistantState.error;
        if (_errorMessage.isEmpty) {
          _errorMessage = 'Microphone permission or speech recognition unavailable.';
        }
      });
    }
  }

  Future<void> _sendToCoach(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty) return;

    await VoiceAssistantService.instance.stopListening();

    setState(() {
      _state = VoiceAssistantState.thinking;
    });

    widget.onTextRecognized?.call(text);

    _history.add(AiCoachChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    try {
      final reply = await AiService.instance.chatWithCoach(
        text,
        history: _history,
      );

      if (!mounted) return;

      _history.add(AiCoachChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      setState(() {
        _aiResponse = reply;
        _state = VoiceAssistantState.speaking;
      });

      // Speak AI response aloud
      await VoiceAssistantService.instance.speak(reply);

      if (mounted) {
        setState(() {
          _state = VoiceAssistantState.idle;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final fallback = "I'm here to help with your nutrition! Focus on whole foods and your personalization goals.";
      setState(() {
        _aiResponse = fallback;
        _state = VoiceAssistantState.speaking;
      });
      await VoiceAssistantService.instance.speak(fallback);
      if (mounted) {
        setState(() {
          _state = VoiceAssistantState.idle;
        });
      }
    }
  }

  void _stopSpeaking() {
    VoiceAssistantService.instance.stopSpeaking();
    setState(() {
      _state = VoiceAssistantState.idle;
    });
  }

  void _openFullCoach() {
    VoiceAssistantService.instance.stopSpeaking();
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiCoachScreen(
          userName: widget.userName,
        ),
      ),
    );
  }

  void _handleMicTap() {
    if (_state == VoiceAssistantState.listening) {
      if (_spokenText.trim().isNotEmpty) {
        _sendToCoach(_spokenText);
      } else {
        VoiceAssistantService.instance.stopListening();
        setState(() => _state = VoiceAssistantState.idle);
      }
    } else if (_state == VoiceAssistantState.speaking) {
      _stopSpeaking();
    } else {
      _startVoiceInput();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isListening = _state == VoiceAssistantState.listening;
    final isThinking = _state == VoiceAssistantState.thinking;
    final isSpeaking = _state == VoiceAssistantState.speaking;
    final isError = _state == VoiceAssistantState.error;

    String titleText = "I'm listening...";
    String subtitleText = "Speak now";
    String bottomHint = "Tap the mic again to stop";

    if (isThinking) {
      titleText = "Thinking...";
      subtitleText = "Consulting your AI Nutrition Coach";
      bottomHint = "Analyzing your request...";
    } else if (isSpeaking) {
      titleText = "DietCompass Speaking";
      subtitleText = "Playing audio response";
      bottomHint = "Tap mic or Stop Audio to interrupt";
    } else if (isError) {
      titleText = "Voice Assistant";
      subtitleText = "Unable to process voice";
      bottomHint = "Tap the mic to try again";
    } else if (_state == VoiceAssistantState.idle) {
      if (_aiResponse.isNotEmpty) {
        titleText = "Coach Response";
        subtitleText = "Ready for your next question";
        bottomHint = "Tap mic to speak again";
      } else {
        titleText = "DietCompass Assistant";
        subtitleText = "Ready to listen";
        bottomHint = "Tap mic to speak";
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: EdgeInsets.fromLTRB(22 * scale, 18 * scale, 22 * scale, 26 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF0F101D), // Dark navy / near-black background matching reference
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: const Color(0xFF262640),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 36,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar: Title & Close Button matching reference
            Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    'DietCompass Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5 * scale,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      VoiceAssistantService.instance.stopListening();
                      VoiceAssistantService.instance.stopSpeaking();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 34 * scale,
                      height: 34 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 19 * scale,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24 * scale),

            // Central Animated Voice Visualizer matching reference image
            SizedBox(
              height: 210 * scale,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Horizontal audio waveform dots & bars
                  AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(double.infinity, 210 * scale),
                        painter: _WaveformPainter(
                          scale: scale,
                          isListening: isListening,
                          animValue: _waveCtrl.value,
                          color: isError
                              ? const Color(0xFFE0525C)
                              : isThinking
                                  ? const Color(0xFFE0862E)
                                  : const Color(0xFF8B5CF6),
                        ),
                      );
                    },
                  ),

                  // Concentric Expanding/Pulsing Purple Rings
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(210 * scale, 210 * scale),
                        painter: _ConcentricRingsPainter(
                          scale: scale,
                          isListening: isListening,
                          isThinking: isThinking,
                          animValue: _pulseCtrl.value,
                          primaryColor: isError
                              ? const Color(0xFFE0525C)
                              : isThinking
                                  ? const Color(0xFFE0862E)
                                  : const Color(0xFF7B52F8),
                        ),
                      );
                    },
                  ),

                  // Central Microphone Button
                  GestureDetector(
                    onTap: _handleMicTap,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final pulse = isListening ? (1.0 + _pulseCtrl.value * 0.06) : 1.0;
                        return Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 86 * scale,
                            height: 86 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isError
                                    ? [const Color(0xFFE0525C), const Color(0xFFB52D37)]
                                    : isThinking
                                        ? [const Color(0xFFE0862E), const Color(0xFFF0A04B)]
                                        : isSpeaking
                                            ? [const Color(0xFF3B82F6), const Color(0xFF6C4EF5)]
                                            : [const Color(0xFF8B5CF6), const Color(0xFF6C4EF5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isError
                                          ? const Color(0xFFE0525C)
                                          : isThinking
                                              ? const Color(0xFFE0862E)
                                              : const Color(0xFF7B52F8))
                                      .withValues(alpha: isListening || isSpeaking ? 0.55 : 0.35),
                                  blurRadius: isListening || isSpeaking ? 28 : 18,
                                  spreadRadius: isListening ? 3 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              isThinking
                                  ? Icons.hourglass_top_rounded
                                  : isSpeaking
                                      ? Icons.volume_up_rounded
                                      : Icons.mic_rounded,
                              color: Colors.white,
                              size: 40 * scale,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16 * scale),

            // Main Status Text ("I'm listening...")
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20 * scale,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 6 * scale),

            // Secondary Subtitle ("Speak now")
            Text(
              subtitleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF8E8EA6),
                fontSize: 13.5 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 14 * scale),

            // 3 Animated Purple Wave Dots (• • •) matching reference
            if (isListening || isThinking) ...[
              AnimatedBuilder(
                animation: _dotsCtrl,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final phase = (_dotsCtrl.value + (i * 0.33)) % 1.0;
                      final dy = -math.sin(phase * math.pi) * 5 * scale;
                      final opacity = 0.35 + (math.sin(phase * math.pi) * 0.65).clamp(0.0, 0.65);
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4 * scale),
                          width: 7 * scale,
                          height: 7 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF8B5CF6).withValues(alpha: opacity),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              SizedBox(height: 16 * scale),
            ],

            // Recognized speech / Response transcript card
            if (_spokenText.isNotEmpty || _aiResponse.isNotEmpty || isError) ...[
              Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 60 * scale, maxHeight: 150 * scale),
                padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFF171828),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF2E2F48),
                    width: 1.0,
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    isError
                        ? _errorMessage
                        : _spokenText.isNotEmpty && _aiResponse.isEmpty
                            ? '“$_spokenText”'
                            : _aiResponse,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      height: 1.4,
                      color: isError
                          ? const Color(0xFFFF6B75)
                          : _aiResponse.isNotEmpty
                              ? Colors.white
                              : const Color(0xFFD6D0EC),
                      fontStyle: _spokenText.isNotEmpty && _aiResponse.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14 * scale),
            ],

            // Action Buttons when response is available or speaking
            if (_aiResponse.isNotEmpty || isSpeaking) ...[
              Row(
                children: [
                  if (isSpeaking) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _stopSpeaking,
                        icon: Icon(Icons.stop_rounded, size: 16 * scale, color: const Color(0xFFFF6B75)),
                        label: Text('Stop Audio', style: TextStyle(fontSize: 12 * scale, color: const Color(0xFFFF6B75), fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10 * scale),
                          side: const BorderSide(color: Color(0xFFFF6B75)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openFullCoach,
                      icon: Icon(Icons.chat_bubble_outline_rounded, size: 16 * scale, color: Colors.white),
                      label: Text(
                        'Open AI Coach Chat',
                        style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C4EF5),
                        padding: EdgeInsets.symmetric(vertical: 10 * scale),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14 * scale),
            ],

            // Bottom instruction hint ("Tap the mic again to stop") matching reference
            Text(
              bottomHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF7A7A90),
                fontSize: 13 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for Concentric Purple Rings matching the reference
class _ConcentricRingsPainter extends CustomPainter {
  const _ConcentricRingsPainter({
    required this.scale,
    required this.isListening,
    required this.isThinking,
    required this.animValue,
    required this.primaryColor,
  });

  final double scale;
  final bool isListening;
  final bool isThinking;
  final double animValue;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radii = [58.0 * scale, 78.0 * scale, 98.0 * scale];
    final baseAlphas = [0.22, 0.12, 0.06];

    for (int i = 0; i < radii.length; i++) {
      final pulseFactor = isListening
          ? 1.0 + (animValue * 0.08 * (i + 1))
          : isThinking
              ? 1.0 + (math.sin(animValue * math.pi) * 0.04)
              : 1.0;

      final currentRadius = radii[i] * pulseFactor;
      final alpha = (baseAlphas[i] * (isListening ? (1.0 + animValue * 0.3) : 0.8)).clamp(0.0, 1.0);

      final fillPaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha * 0.4)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale;

      canvas.drawCircle(center, currentRadius, fillPaint);
      canvas.drawCircle(center, currentRadius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) =>
      oldDelegate.animValue != animValue ||
      oldDelegate.isListening != isListening ||
      oldDelegate.primaryColor != primaryColor;
}

/// CustomPainter for Horizontal Audio Waveform Dots & Bars matching the reference
class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.scale,
    required this.isListening,
    required this.animValue,
    required this.color,
  });

  final double scale;
  final bool isListening;
  final double animValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final centerX = size.width / 2;
    final micRadius = 50.0 * scale;

    final paint = Paint()
      ..color = color.withValues(alpha: isListening ? 0.85 : 0.4)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    const dotCount = 9;
    final spacing = 14.0 * scale;

    // Left side waveform
    for (int i = 0; i < dotCount; i++) {
      final x = centerX - micRadius - (i + 1) * spacing;
      if (x < 10) break;

      final phase = (animValue + (i * 0.15)) % 1.0;
      final waveHeight = isListening ? (4.0 + math.sin(phase * math.pi * 2).abs() * 12.0) * scale : (3.0 * scale);
      final isBar = isListening && (i % 2 == 0);

      if (isBar && waveHeight > 5 * scale) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, centerY), width: 3.5 * scale, height: waveHeight),
            Radius.circular(2 * scale),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(x, centerY), 2.2 * scale, paint);
      }
    }

    // Right side waveform
    for (int i = 0; i < dotCount; i++) {
      final x = centerX + micRadius + (i + 1) * spacing;
      if (x > size.width - 10) break;

      final phase = (animValue + (i * 0.15)) % 1.0;
      final waveHeight = isListening ? (4.0 + math.sin(phase * math.pi * 2).abs() * 12.0) * scale : (3.0 * scale);
      final isBar = isListening && (i % 2 == 0);

      if (isBar && waveHeight > 5 * scale) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, centerY), width: 3.5 * scale, height: waveHeight),
            Radius.circular(2 * scale),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(x, centerY), 2.2 * scale, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.animValue != animValue ||
      oldDelegate.isListening != isListening ||
      oldDelegate.color != color;
}

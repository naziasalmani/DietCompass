import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// DietCompass — Voice Assistant Service (Phase 6E)
/// Handles Speech-to-Text (STT) and Text-to-Speech (TTS) for the AI Nutrition Coach
class VoiceAssistantService {
  VoiceAssistantService._();
  static final VoiceAssistantService instance = VoiceAssistantService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isSpeechInitialized;

  /// Initialize Speech-to-Text engine
  Future<bool> initSpeech() async {
    if (_isSpeechInitialized) return true;

    try {
      final status = await Permission.microphone.status;
      if (status.isDenied) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          debugPrint('[VoiceAssistant] Microphone permission denied');
          return false;
        }
      } else if (status.isPermanentlyDenied) {
        debugPrint('[VoiceAssistant] Microphone permission permanently denied');
        return false;
      }

      _isSpeechInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[VoiceAssistant STT status] $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (errorNotification) {
          debugPrint('[VoiceAssistant STT error] ${errorNotification.errorMsg}');
          _isListening = false;
        },
      );

      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('[VoiceAssistant] Error initializing STT: $e');
      _isSpeechInitialized = false;
      return false;
    }
  }

  /// Initialize Text-to-Speech engine
  Future<bool> initTts() async {
    if (_isTtsInitialized) return true;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        debugPrint('[VoiceAssistant TTS error] $msg');
        _isSpeaking = false;
      });

      _isTtsInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[VoiceAssistant] Error initializing TTS: $e');
      _isTtsInitialized = false;
      return false;
    }
  }

  /// Start listening to user voice input
  Future<bool> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    Function(String error)? onError,
    Function()? onDone,
  }) async {
    // Stop any ongoing TTS before listening
    await stopSpeaking();

    final hasPermission = await initSpeech();
    if (!hasPermission) {
      onError?.call('Microphone permission is required to use voice input.');
      return false;
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _isListening = false;
            onDone?.call();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: true,
          partialResults: true,
        ),
      );

      return true;
    } catch (e) {
      _isListening = false;
      onError?.call('Failed to start voice recognition: $e');
      return false;
    }
  }

  /// Stop listening and finalize recognized text
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
      }
    } catch (e) {
      debugPrint('[VoiceAssistant] Error stopping STT: $e');
      _isListening = false;
    }
  }

  /// Cancel listening immediately
  Future<void> cancelListening() async {
    try {
      if (_isListening) {
        await _speech.cancel();
        _isListening = false;
      }
    } catch (e) {
      debugPrint('[VoiceAssistant] Error canceling STT: $e');
      _isListening = false;
    }
  }

  /// Speak text aloud via Text-to-Speech
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await initTts();
      // Clean markdown symbols (e.g. *, #, _) for clean natural speech
      final cleanText = text
          .replaceAll(RegExp(r'\*+'), '')
          .replaceAll(RegExp(r'#+'), '')
          .replaceAll(RegExp(r'[_`~]'), '')
          .replaceAll(RegExp(r'\n+'), '. ')
          .trim();

      if (cleanText.isNotEmpty) {
        _isSpeaking = true;
        await _tts.speak(cleanText);
      }
    } catch (e) {
      debugPrint('[VoiceAssistant] Error speaking text: $e');
      _isSpeaking = false;
    }
  }

  /// Stop ongoing speech playback
  Future<void> stopSpeaking() async {
    try {
      if (_isSpeaking) {
        await _tts.stop();
        _isSpeaking = false;
      }
    } catch (e) {
      debugPrint('[VoiceAssistant] Error stopping TTS: $e');
      _isSpeaking = false;
    }
  }

  /// Dispose/cleanup all resources
  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}

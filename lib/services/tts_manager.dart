import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../domain/models/segment.dart';
import '../domain/services/ssml_builder.dart';

/// Gestionnaire de synthèse vocale avec lecture par phrases complètes.
class TtsManager {
  TtsManager() {
    _tts = FlutterTts();
    _init();
  }

  late final FlutterTts _tts;
  final _completionController = StreamController<void>.broadcast();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _cancelled = false;
  double _speed = AppConstants.defaultSpeed;
  String _language = AppConstants.defaultLanguage;

  Stream<void> get onComplete => _completionController.stream;
  bool get isSpeaking => _isSpeaking;
  double get speed => _speed;
  String get language => _language;

  Future<void> _init() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
      }
      await setLanguage(AppConstants.defaultLanguage);
      await setSpeed(AppConstants.defaultSpeed);
      _isInitialized = true;
    } catch (e) {
      throw TtsException('Impossible d\'initialiser la synthèse vocale', e);
    }
  }

  /// Configure la langue TTS.
  Future<void> setLanguage(String languageCode) async {
    try {
      _language = languageCode;
      await _tts.setLanguage(languageCode);
    } catch (e) {
      await _tts.setLanguage(AppConstants.defaultLanguage);
      _language = AppConstants.defaultLanguage;
    }
  }

  /// Configure la vitesse (0.5x à 2.0x). N'affecte pas les pauses.
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(AppConstants.minSpeed, AppConstants.maxSpeed);
    final rate = _speed * 0.5;
    await _tts.setSpeechRate(rate);
  }

  /// Lit une liste de segments regroupés en phrases complètes.
  Future<void> speakSegments(
    List<Segment> segments, {
    void Function(int endLocalSegmentIndex)? onChunkComplete,
  }) async {
    if (!_isInitialized) await _init();
    _cancelled = false;
    _isSpeaking = true;

    try {
      final chunks = SsmlBuilder.buildSpeechChunks(segments);
      await _speakChunks(chunks, onChunkComplete: onChunkComplete);
    } catch (e) {
      throw TtsException('Erreur lors de la lecture audio', e);
    } finally {
      _isSpeaking = false;
      if (!_cancelled) {
        _completionController.add(null);
      }
    }
  }

  Future<void> _speakChunks(
    List<SpeechChunk> chunks, {
    void Function(int endLocalSegmentIndex)? onChunkComplete,
  }) async {
    for (final chunk in chunks) {
      if (_cancelled) break;

      if (chunk.text.trim().isNotEmpty) {
        await _tts.speak(chunk.text);
        if (!_cancelled) {
          onChunkComplete?.call(chunk.endLocalSegmentIndex);
        }
      }

      if (chunk.pauseAfter.inMilliseconds > 0 && !_cancelled) {
        await Future<void>.delayed(chunk.pauseAfter);
      }
    }
  }

  /// Arrête la lecture en cours.
  Future<void> stop() async {
    _cancelled = true;
    _isSpeaking = false;
    await _tts.stop();
  }

  /// Met en pause (si supporté par la plateforme).
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (_) {
      await stop();
    }
  }

  void dispose() {
    _completionController.close();
    _tts.stop();
  }
}

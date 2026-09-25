import 'dart:developer';

import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';

/// Détection automatique de la langue du texte via ML Kit (100 % local).
class LanguageDetector {
  LanguageDetector._();

  /// Détecte la langue à partir d'un échantillon de [sampleSize] caractères.
  static Future<String> detectLanguage(
    String text, {
    int sampleSize = AppConstants.languageSampleSize,
  }) async {
    try {
      final sample = text.trim();
      if (sample.isEmpty) {
        return AppConstants.defaultLanguage;
      }

      final excerpt = sample.length <= sampleSize
          ? sample
          : sample.substring(0, sampleSize);

      final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
      try {
        final languageCode = await identifier.identifyLanguage(excerpt);
        await identifier.close();

        if (languageCode == 'und' || languageCode.isEmpty) {
          return AppConstants.defaultLanguage;
        }

        return _mapToTtsLanguage(languageCode);
      } catch (e) {
        await identifier.close();
        log('Détection de langue ML Kit indisponible: $e');
        return AppConstants.defaultLanguage;
      }
    } catch (e) {
      throw LanguageDetectionException(
        'Impossible de détecter la langue du document',
        e,
      );
    }
  }

  /// Convertit un code ISO en code BCP-47 compatible TTS.
  static String _mapToTtsLanguage(String code) {
    final normalized = code.toLowerCase();

    const mapping = {
      'fr': 'fr-FR',
      'en': 'en-US',
      'es': 'es-ES',
      'de': 'de-DE',
      'it': 'it-IT',
      'pt': 'pt-PT',
    };

    final mapped = mapping[normalized] ?? code;

    if (AppConstants.supportedTtsLanguages.contains(mapped)) {
      return mapped;
    }

    for (final supported in AppConstants.supportedTtsLanguages) {
      if (supported.toLowerCase().startsWith(normalized)) {
        return supported;
      }
    }

    return AppConstants.defaultLanguage;
  }
}

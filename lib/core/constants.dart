/// Constantes globales de l'application VoxLibri.
class AppConstants {
  AppConstants._();

  // --- Application ---
  static const String appName = 'VoxLibri';

  // --- Pauses pour la synthèse vocale naturelle (en millisecondes) ---
  static const int pauseParagraph = 800;
  static const int pauseSentence = 400;
  static const int pauseSemicolon = 300;
  static const int pauseColon = 250;
  static const int pauseComma = 200;
  static const int pauseEllipsis = 350;

  // --- Vitesse de lecture ---
  static const double defaultSpeed = 1.0;
  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;
  static const double speedStep = 0.25;

  // --- Langue par défaut ---
  static const String defaultLanguage = 'fr-FR';

  /// Langues TTS supportées (code BCP-47).
  static const Set<String> supportedTtsLanguages = {
    'fr-FR',
    'fr',
    'en-US',
    'en-GB',
    'en',
    'es-ES',
    'es',
    'de-DE',
    'de',
    'it-IT',
    'it',
    'pt-PT',
    'pt-BR',
    'pt',
  };

  // --- Base de données ---
  static const String databaseName = 'voxlibri.db';

  // --- Dossiers de stockage ---
  static const String pdfFolder = 'pdf';
  static const String textFolder = 'text';
  static const String cacheFolder = 'cache';
  static const String settingsFileName = 'settings.json';

  // --- Détection de langue ---
  static const int languageSampleSize = 200;

  // --- Progression ---
  static const int progressSaveIntervalSeconds = 30;
  static const int repetitiveLineThreshold = 3;

  // --- Lecture ---
  static const int wordsPerMinute = 150;
  static const int msPerWord = 400;

  // --- Notifications ---
  static const String notificationChannelId = 'voxlibri_playback';
  static const String notificationChannelName = 'Lecture VoxLibri';
}

/// Unité de saut lors de la navigation (suivant / précédent).
enum SkipUnit {
  phrase,
  paragraph,
}

/// Mode de thème de l'application.
enum AppThemeMode {
  system,
  light,
  dark,
}

import '../constants.dart';

class TextUtils {
  TextUtils._();

  /// Formate une durée en millisecondes (MM:SS ou HH:MM:SS).
  static String formatDuration(int durationMs) {
    final totalSeconds = (durationMs / 1000).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final secondsStr = seconds.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutesStr:$secondsStr';
    }
    return '$minutesStr:$secondsStr';
  }

  /// Estime la durée de lecture en millisecondes (150 mots/minute).
  static int estimateReadingDurationMs(String text) {
    if (text.trim().isEmpty) return 0;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return words * AppConstants.msPerWord;
  }

  /// Estime le nombre de segments (phrases).
  static int estimateSegmentsCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.split(RegExp(r'[.!?]\s+')).where((s) => s.isNotEmpty).length;
  }

  /// Calcule le pourcentage de progression.
  static double calculateProgress(int currentIndex, int total) {
    if (total <= 0) return 0.0;
    return (currentIndex / total).clamp(0.0, 1.0);
  }
}

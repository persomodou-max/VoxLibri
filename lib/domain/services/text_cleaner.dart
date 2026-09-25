import '../../core/constants.dart';

/// Nettoyage du texte brut extrait des PDF.
class TextCleaner {
  TextCleaner._();

  /// Numéros de page isolés sur une ligne (ex: "12").
  static final RegExp _pageNumber = RegExp(
    r'^\s*\d{1,4}\s*$',
    multiLine: true,
  );

  /// Marques "Page X" sur une ligne entière.
  static final RegExp _pageLabel = RegExp(
    r'^\s*[-–—]*\s*Page\s+\d+\s*[-–—]*\s*$',
    caseSensitive: false,
    multiLine: true,
  );

  /// Marques "— 12 —" sur une ligne entière.
  static final RegExp _dashPageNumber = RegExp(
    r'^\s*[-–—]+\s*\d{1,4}\s*[-–—]+\s*$',
    multiLine: true,
  );

  /// Fusionne les lignes coupées au milieu d'une phrase.
  static String _mergeBrokenLines(String text) {
    final pattern = RegExp(r'(?<![.!?\n])\n(?!\n)(?!\s*(?:[-*•]|\d+\.))');
    return text.replaceAll(pattern, ' ');
  }

  /// Normalise les espaces multiples.
  static String _normalizeSpaces(String text) {
    return text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  }

  /// Remplace les sauts de page par des paragraphes.
  static String _removeFormFeed(String text) {
    return text.replaceAll('\f', '\n\n');
  }

  /// Supprime les en-têtes et pieds de page répétitifs (> 3 occurrences).
  static String _removeRepetitiveLines(String text) {
    final lines = text.split('\n');
    final counts = <String, int>{};

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.length < 3) continue;
      counts[trimmed] = (counts[trimmed] ?? 0) + 1;
    }

    final repetitive = counts.entries
        .where((e) => e.value > AppConstants.repetitiveLineThreshold)
        .map((e) => e.key)
        .toSet();

    if (repetitive.isEmpty) return text;

    return lines
        .where((line) => !repetitive.contains(line.trim()))
        .join('\n');
  }

  /// Nettoie le texte brut extrait d'un PDF.
  static String clean(String rawText) {
    var text = rawText;
    text = _removeFormFeed(text);
    text = text.replaceAll(_pageLabel, '');
    text = text.replaceAll(_dashPageNumber, '');
    text = text.replaceAll(_pageNumber, '');
    text = _removeRepetitiveLines(text);
    text = _mergeBrokenLines(text);
    text = _normalizeSpaces(text);
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}

import '../models/segment.dart';

/// Paragraphe de lecture avec ses segments TTS.
class ReadingParagraph {
  final String displayText;
  final List<Segment> segments;

  const ReadingParagraph({
    required this.displayText,
    required this.segments,
  });
}

/// Segmente le texte nettoyé en paragraphes et segments avec pauses naturelles.
class TextSegmenter {
  TextSegmenter._();

  static const Set<String> _abbreviations = {
    'm',
    'mme',
    'mlle',
    'dr',
    'pr',
    'me',
    'st',
    'ste',
    'col',
    'sgt',
    'cap',
    'lieut',
    'prof',
    'av',
    'art',
    'no',
    'pp',
    'etc',
    'approx',
    'inc',
    'ltd',
    'vs',
    'eg',
    'ie',
    'ps',
    'min',
    'max',
    'vol',
    'chap',
  };

  /// Découpe le texte en paragraphes prêts pour la lecture.
  static List<ReadingParagraph> segmentIntoParagraphs(String text) {
    if (text.trim().isEmpty) return [];

    return text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map(
          (paragraph) => ReadingParagraph(
            displayText: paragraph,
            segments: _segmentParagraph(paragraph),
          ),
        )
        .toList();
  }

  /// Retourne tous les segments à plat.
  static List<Segment> flattenSegments(List<ReadingParagraph> paragraphs) {
    return paragraphs.expand((p) => p.segments).toList();
  }

  static List<Segment> _segmentParagraph(String paragraph) {
    final segments = <Segment>[];
    final buffer = StringBuffer();
    var i = 0;

    while (i < paragraph.length) {
      if (i + 2 < paragraph.length &&
          paragraph[i] == '.' &&
          paragraph[i + 1] == '.' &&
          paragraph[i + 2] == '.') {
        buffer.write('...');
        segments.add(Segment.ellipsisPause(buffer.toString()));
        buffer.clear();
        i += 3;
        continue;
      }

      final char = paragraph[i];

      if (char == '.' || char == '!' || char == '?') {
        if (_isSentenceTerminator(paragraph, i)) {
          buffer.write(char);
          segments.add(Segment.sentenceEnd(buffer.toString()));
          buffer.clear();
          i++;
          continue;
        }
        buffer.write(char);
        i++;
        continue;
      }

      if (char == ',') {
        // Évite de couper au milieu d'un nombre décimal (ex: 3,5)
        if (i > 0 && i < paragraph.length - 1 &&
            _isDigit(paragraph[i - 1]) && _isDigit(paragraph[i + 1])) {
          buffer.write(char);
          i++;
          continue;
        }
        buffer.write(char);
        segments.add(Segment.commaPause(buffer.toString()));
        buffer.clear();
        i++;
        continue;
      }

      if (char == ':') {
        // Évite de couper au milieu d'une heure ou d'un ratio (ex: 10:30 ou 1:2)
        if (i > 0 && i < paragraph.length - 1 &&
            _isDigit(paragraph[i - 1]) && _isDigit(paragraph[i + 1])) {
          buffer.write(char);
          i++;
          continue;
        }
        buffer.write(char);
        segments.add(Segment.colonPause(buffer.toString()));
        buffer.clear();
        i++;
        continue;
      }

      if (char == ';') {
        buffer.write(char);
        segments.add(Segment.semicolonPause(buffer.toString()));
        buffer.clear();
        i++;
        continue;
      }

      buffer.write(char);
      i++;
    }

    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      segments.add(Segment.text(remaining));
    }

    segments.add(Segment.paragraphBreak(''));
    return segments;
  }

  /// Détecte une vraie fin de phrase (évite décimales, abréviations, listes).
  static bool _isSentenceTerminator(String text, int index) {
    final char = text[index];
    if (char == '!' || char == '?') return true;
    if (char != '.') return false;

    // Un point doit être suivi d'un espace/saut de ligne ou être en fin de texte pour finir la phrase.
    // S'il est suivi d'une lettre ou d'un chiffre sans espace (ex: U.S.A., document.pdf, 3.5), ce n'est pas une fin de phrase.
    if (index < text.length - 1) {
      final nextChar = text[index + 1];
      if (nextChar != ' ' && nextChar != '\n' && nextChar != '\r' && nextChar != '\t') {
        return false;
      }
    }

    if (index > 0 && index < text.length - 1) {
      if (_isDigit(text[index - 1]) && _isDigit(text[index + 1])) {
        return false;
      }
    }

    if (index > 0 && index < text.length - 1 && text[index + 1] == ' ') {
      var j = index - 1;
      while (j >= 0 && _isLetter(text[j])) {
        j--;
      }
      final abbrev = text.substring(j + 1, index);
      if (abbrev.length == 1) return false;
      if (abbrev.length <= 6 &&
          _abbreviations.contains(abbrev.toLowerCase())) {
        return false;
      }
    }

    if (index > 0) {
      var j = index - 1;
      while (j >= 0 && _isDigit(text[j])) {
        j--;
      }
      if (j < index - 1) {
        final atWordStart = j < 0 || text[j] == ' ';
        if (atWordStart &&
            index + 1 < text.length &&
            text[index + 1] == ' ') {
          return false;
        }
      }
    }

    return true;
  }

  static bool _isDigit(String char) => RegExp(r'\d').hasMatch(char);

  static bool _isLetter(String char) =>
      RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(char);

  static int paragraphIndexForSegment(
    List<ReadingParagraph> paragraphs,
    int globalSegmentIndex,
  ) {
    var offset = 0;
    for (var i = 0; i < paragraphs.length; i++) {
      final count = paragraphs[i].segments.length;
      if (globalSegmentIndex < offset + count) return i;
      offset += count;
    }
    return paragraphs.isEmpty ? 0 : paragraphs.length - 1;
  }

  static int globalIndexForParagraph(
    List<ReadingParagraph> paragraphs,
    int paragraphIndex,
  ) {
    var offset = 0;
    for (var i = 0; i < paragraphIndex && i < paragraphs.length; i++) {
      offset += paragraphs[i].segments.length;
    }
    return offset;
  }
}

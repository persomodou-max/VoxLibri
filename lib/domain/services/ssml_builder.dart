import '../../core/constants.dart';
import '../models/segment.dart';

/// Unité de lecture regroupant une phrase complète pour une voix naturelle.
class SpeechChunk {
  final String text;
  final Duration pauseAfter;
  final int endLocalSegmentIndex;

  const SpeechChunk({
    required this.text,
    required this.pauseAfter,
    required this.endLocalSegmentIndex,
  });
}

/// Génère des plans de lecture segmentés pour une synthèse vocale naturelle.
class SsmlBuilder {
  SsmlBuilder._();

  /// Regroupe les segments en phrases complètes pour éviter les coupures.
  static List<SpeechChunk> buildSpeechChunks(List<Segment> segments) {
    if (segments.isEmpty) return [];

    final chunks = <SpeechChunk>[];
    final buffer = StringBuffer();

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      buffer.write(segment.text);

      final isUtteranceEnd = segment.type == SegmentType.sentenceEnd ||
          segment.type == SegmentType.ellipsisPause ||
          segment.type == SegmentType.paragraphBreak;

      if (isUtteranceEnd) {
        final text = buffer.toString().trim();
        if (text.isNotEmpty) {
          chunks.add(
            SpeechChunk(
              text: text,
              pauseAfter: segment.pauseDuration,
              endLocalSegmentIndex: i,
            ),
          );
        }
        buffer.clear();
      }
    }

    final remainder = buffer.toString().trim();
    if (remainder.isNotEmpty) {
      chunks.add(
        SpeechChunk(
          text: remainder,
          pauseAfter: Duration.zero,
          endLocalSegmentIndex: segments.length - 1,
        ),
      );
    }

    return chunks;
  }

  /// Plan de lecture : texte + pause pour chaque segment (fallback).
  static List<IosSpeechUnit> buildIosPlan(List<Segment> segments) {
    return segments
        .map(
          (segment) => IosSpeechUnit(
            text: segment.text,
            pauseMs: segment.pauseDuration.inMilliseconds,
          ),
        )
        .where((unit) => unit.text.isNotEmpty || unit.pauseMs > 0)
        .toList();
  }

  static String _formatRate(double speed) {
    final percent = (speed * 100).round();
    return '$percent%';
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// Unité de lecture pour iOS (segment + pause manuelle).
class IosSpeechUnit {
  final String text;
  final int pauseMs;

  const IosSpeechUnit({
    required this.text,
    required this.pauseMs,
  });
}

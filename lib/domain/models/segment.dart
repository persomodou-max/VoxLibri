import '../../core/constants.dart';

enum SegmentType {
  text,
  commaPause,
  colonPause,
  semicolonPause,
  ellipsisPause,
  sentenceEnd,
  paragraphBreak,
}

class Segment {
  final String text;
  final SegmentType type;
  final Duration pauseDuration;

  const Segment({
    required this.text,
    required this.type,
    required this.pauseDuration,
  });

  factory Segment.text(String text) {
    return Segment(
      text: text,
      type: SegmentType.text,
      pauseDuration: Duration.zero,
    );
  }

  factory Segment.commaPause(String text) {
    return Segment(
      text: text,
      type: SegmentType.commaPause,
      pauseDuration: const Duration(milliseconds: AppConstants.pauseComma),
    );
  }

  factory Segment.colonPause(String text) {
    return Segment(
      text: text,
      type: SegmentType.colonPause,
      pauseDuration: const Duration(milliseconds: AppConstants.pauseColon),
    );
  }

  factory Segment.semicolonPause(String text) {
    return Segment(
      text: text,
      type: SegmentType.semicolonPause,
      pauseDuration: const Duration(milliseconds: AppConstants.pauseSemicolon),
    );
  }

  factory Segment.ellipsisPause(String text) {
    return Segment(
      text: text,
      type: SegmentType.ellipsisPause,
      pauseDuration: const Duration(milliseconds: AppConstants.pauseEllipsis),
    );
  }

  factory Segment.sentenceEnd(String text) {
    return Segment(
      text: text,
      type: SegmentType.sentenceEnd,
      pauseDuration: const Duration(milliseconds: AppConstants.pauseSentence),
    );
  }

  factory Segment.paragraphBreak(String text) {
    return Segment(
      text: text,
      type: SegmentType.paragraphBreak,
      pauseDuration: const Duration(milliseconds: AppConstants.pauseParagraph),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type.name,
      'pauseDurationMs': pauseDuration.inMilliseconds,
    };
  }

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      text: json['text'] as String,
      type: SegmentType.values.byName(json['type'] as String),
      pauseDuration: Duration(milliseconds: json['pauseDurationMs'] as int),
    );
  }

  @override
  String toString() => 'Segment(text: "$text", type: $type, pause: ${pauseDuration.inMilliseconds}ms)';
}

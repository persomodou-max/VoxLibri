class Document {
  final String id;
  final String title;
  final String filePath;
  final String? textPath;
  final String language;
  final double progress;
  final int lastPosition;
  final int totalSegments;
  final int durationMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.title,
    required this.filePath,
    this.textPath,
    this.language = 'fr',
    this.progress = 0.0,
    this.lastPosition = 0,
    this.totalSegments = 0,
    this.durationMs = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Document copyWith({
    String? id,
    String? title,
    String? filePath,
    String? textPath,
    String? language,
    double? progress,
    int? lastPosition,
    int? totalSegments,
    int? durationMs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      textPath: textPath ?? this.textPath,
      language: language ?? this.language,
      progress: progress ?? this.progress,
      lastPosition: lastPosition ?? this.lastPosition,
      totalSegments: totalSegments ?? this.totalSegments,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => toJson();

  factory Document.fromMap(Map<String, dynamic> map) => Document.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'text_path': textPath,
      'language': language,
      'progress': progress,
      'last_position': lastPosition,
      'total_segments': totalSegments,
      'duration_ms': durationMs,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      title: json['title'] as String,
      filePath: json['file_path'] as String,
      textPath: json['text_path'] as String?,
      language: json['language'] as String? ?? 'fr',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      lastPosition: json['last_position'] as int? ?? 0,
      totalSegments: json['total_segments'] as int? ?? 0,
      durationMs: json['duration_ms'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

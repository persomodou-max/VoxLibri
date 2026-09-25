class VoxLibriException implements Exception {
  final String message;
  final dynamic originalError;

  VoxLibriException(this.message, [this.originalError]);

  @override
  String toString() =>
      'VoxLibriException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
}

class PdfExtractionException extends VoxLibriException {
  PdfExtractionException(super.message, [super.originalError]);
}

class DatabaseException extends VoxLibriException {
  DatabaseException(super.message, [super.originalError]);
}

class LanguageDetectionException extends VoxLibriException {
  LanguageDetectionException(super.message, [super.originalError]);
}

class FileImportException extends VoxLibriException {
  FileImportException(super.message, [super.originalError]);
}

class SettingsException extends VoxLibriException {
  SettingsException(super.message, [super.originalError]);
}

class TtsException extends VoxLibriException {
  TtsException(super.message, [super.originalError]);
}

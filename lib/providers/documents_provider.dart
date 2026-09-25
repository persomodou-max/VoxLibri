import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../core/utils/file_utils.dart';
import '../core/utils/text_utils.dart';
import '../domain/models/document.dart';
import '../domain/services/language_detector.dart';
import '../domain/services/pdf_extractor.dart';
import '../domain/services/text_segmenter.dart';
import 'database_provider.dart';

const _uuid = Uuid();

final documentsStreamProvider = StreamProvider<List<Document>>((ref) {
  return ref.watch(documentRepositoryProvider).watchAllDocuments();
});

class DocumentActionNotifier extends StateNotifier<AsyncValue<void>> {
  DocumentActionNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> importPdf(String sourcePdfPath) async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(documentRepositoryProvider);
      final uuid = _uuid.v4();
      final title = p.basenameWithoutExtension(sourcePdfPath);

      final destPdfPath =
          await FileUtils.copyPdfToAppStorage(sourcePdfPath, uuid);
      final textDir =
          await FileUtils.getStorageDirectoryPath(AppConstants.textFolder);
      final finalTextPath = p.join(textDir, '$uuid.txt');

      await PdfExtractor.extractAndClean(
        pdfPath: destPdfPath,
        txtPath: finalTextPath,
      );

      final cleanedText = await File(finalTextPath).readAsString();
      if (cleanedText.trim().isEmpty) {
        throw PdfExtractionException(
          'Ce PDF ne contient pas de texte exploitable après nettoyage.',
        );
      }

      final language = await LanguageDetector.detectLanguage(cleanedText);
      final paragraphs = TextSegmenter.segmentIntoParagraphs(cleanedText);
      final totalSegments = TextSegmenter.flattenSegments(paragraphs).length;
      final now = DateTime.now();

      final doc = Document(
        id: uuid,
        title: title,
        filePath: destPdfPath,
        textPath: finalTextPath,
        language: language,
        progress: 0.0,
        lastPosition: 0,
        totalSegments: totalSegments,
        durationMs: TextUtils.estimateReadingDurationMs(cleanedText),
        createdAt: now,
        updatedAt: now,
      );

      await repository.insertDocument(doc);
      state = const AsyncValue.data(null);
    } on VoxLibriException catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } catch (e, stack) {
      state = AsyncValue.error(
        FileImportException('Erreur lors de l\'importation du PDF', e),
        stack,
      );
    }
  }

  Future<void> deleteDocument(Document doc) async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(documentRepositoryProvider);

      await FileUtils.deleteFile(doc.filePath);
      if (doc.textPath != null) {
        await FileUtils.deleteFile(doc.textPath!);
      }

      await repository.deleteDocument(doc.id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(
        FileImportException('Erreur lors de la suppression', e),
        stack,
      );
    }
  }
}

final documentActionProvider =
    StateNotifierProvider<DocumentActionNotifier, AsyncValue<void>>((ref) {
  return DocumentActionNotifier(ref);
});

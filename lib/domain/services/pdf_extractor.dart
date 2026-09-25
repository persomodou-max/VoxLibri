import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'text_cleaner.dart';
import '../../core/exceptions.dart';

class PdfExtractor {
  /// Extracts text from [pdfPath], cleans it using [TextCleaner],
  /// and writes the output to [txtPath].
  /// Runs inside a background Isolate to prevent blocking the UI thread.
  static Future<void> extractAndClean({
    required String pdfPath,
    required String txtPath,
  }) async {
    try {
      // Use Isolate.run to execute the heavy extraction in a background thread
      await Isolate.run(() async {
        final File pdfFile = File(pdfPath);
        if (!pdfFile.existsSync()) {
          throw PdfExtractionException("Le fichier PDF n'existe pas : $pdfPath");
        }

        List<int> bytes;
        try {
          bytes = pdfFile.readAsBytesSync();
        } catch (e) {
          throw PdfExtractionException("Impossible de lire le fichier PDF", e);
        }

        PdfDocument document;
        try {
          document = PdfDocument(inputBytes: bytes);
        } catch (e) {
          throw PdfExtractionException("Le fichier PDF est protégé par un mot de passe ou est corrompu.", e);
        }

        try {
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          final String rawText = extractor.extractText();

          if (rawText.trim().isEmpty) {
            throw PdfExtractionException("Ce PDF ne contient pas de texte sélectionnable (possible document scanné ou vide).");
          }

          final String cleanedText = TextCleaner.clean(rawText);

          final File txtFile = File(txtPath);
          txtFile.parent.createSync(recursive: true);
          txtFile.writeAsStringSync(cleanedText);
        } finally {
          document.dispose();
        }
      });
    } on PdfExtractionException {
      rethrow;
    } catch (e, stack) {
      log("Error during PDF extraction", error: e, stackTrace: stack);
      throw PdfExtractionException("Erreur inattendue lors de l'extraction du PDF", e);
    }
  }
}

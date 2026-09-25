import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants.dart';

class FileUtils {
  FileUtils._();

  /// Returns the application documents directory path.
  static Future<String> getAppDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Returns the path to the directory for a specific storage folder type (pdf, text, cache).
  static Future<String> getStorageDirectoryPath(String folderName) async {
    final appPath = await getAppDirectoryPath();
    final dirPath = p.join(appPath, folderName);
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return dirPath;
  }

  /// Copies a file to the app's internal PDF directory and returns the destination path.
  static Future<String> copyPdfToAppStorage(String sourcePath, String uuid) async {
    final pdfFolder = await getStorageDirectoryPath(AppConstants.pdfFolder);
    final destinationPath = p.join(pdfFolder, '$uuid.pdf');
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException("Le fichier PDF source n'existe pas", sourcePath);
    }
    final destFile = await sourceFile.copy(destinationPath);
    return destFile.path;
  }

  /// Writes the clean text to the app's internal text directory.
  static Future<String> writeCleanText(String text, String uuid) async {
    final textFolder = await getStorageDirectoryPath(AppConstants.textFolder);
    final destinationPath = p.join(textFolder, '$uuid.txt');
    final file = File(destinationPath);
    await file.writeAsString(text);
    return file.path;
  }

  /// Deletes a file safely if it exists.
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Checks if a file exists.
  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Returns file size in bytes.
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file.length();
    }
    return 0;
  }
}

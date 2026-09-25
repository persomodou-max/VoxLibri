import '../../domain/models/document.dart';
import '../database/database.dart';

extension DocumentMapper on DocumentEntry {
  Document toDomain() {
    return Document(
      id: id,
      title: title,
      filePath: filePath,
      textPath: textPath,
      language: language,
      progress: progress,
      lastPosition: lastPosition,
      totalSegments: totalSegments,
      durationMs: durationMs,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension DomainDocumentMapper on Document {
  DocumentEntry toDatabaseEntry() {
    return DocumentEntry(
      id: id,
      title: title,
      filePath: filePath,
      textPath: textPath,
      language: language,
      progress: progress,
      lastPosition: lastPosition,
      totalSegments: totalSegments,
      durationMs: durationMs,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class DocumentRepository {
  final AppDatabase _db;

  DocumentRepository(this._db);

  Future<List<Document>> getAllDocuments() async {
    final entries = await _db.documentDao.getAllDocuments();
    return entries.map((entry) => entry.toDomain()).toList();
  }

  Stream<List<Document>> watchAllDocuments() {
    return _db.documentDao.watchAllDocuments().map(
      (entries) => entries.map((entry) => entry.toDomain()).toList(),
    );
  }

  Future<Document?> getDocumentById(String id) async {
    final entry = await _db.documentDao.getDocumentById(id);
    return entry?.toDomain();
  }

  Future<void> insertDocument(Document doc) async {
    await _db.documentDao.insertDocument(doc.toDatabaseEntry());
  }

  Future<void> updateDocument(Document doc) async {
    await _db.documentDao.updateDocument(doc.toDatabaseEntry());
  }

  Future<void> deleteDocument(String id) async {
    await _db.documentDao.deleteDocument(id);
  }
}

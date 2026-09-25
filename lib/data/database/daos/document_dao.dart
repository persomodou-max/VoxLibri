import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [Documents])
class DocumentDao extends DatabaseAccessor<AppDatabase> with _$DocumentDaoMixin {
  DocumentDao(super.db);

  Future<List<DocumentEntry>> getAllDocuments() =>
      (select(documents)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();

  Stream<List<DocumentEntry>> watchAllDocuments() =>
      (select(documents)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();

  Future<DocumentEntry?> getDocumentById(String id) =>
      (select(documents)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertDocument(DocumentEntry entry) => into(documents).insert(entry);

  Future<bool> updateDocument(DocumentEntry entry) => update(documents).replace(entry);

  Future<int> deleteDocument(String id) =>
      (delete(documents)..where((t) => t.id.equals(id))).go();
}

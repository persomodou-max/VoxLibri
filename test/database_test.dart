import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlibri/data/database/database.dart';
import 'package:voxlibri/data/repositories/document_repository.dart';
import 'package:voxlibri/domain/models/document.dart';

void main() {
  late AppDatabase db;
  late DocumentRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DocumentRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Database CRUD Operations', () async {
    // 1. Initially empty
    var list = await repository.getAllDocuments();
    expect(list.isEmpty, true);

    final now = DateTime.now();
    final doc = Document(
      id: 'test-uuid-123',
      title: 'Mon Super Document',
      filePath: '/path/to/doc.pdf',
      textPath: '/path/to/text.txt',
      createdAt: now,
      updatedAt: now,
    );

    // 2. Insert
    await repository.insertDocument(doc);

    // 3. Query all
    list = await repository.getAllDocuments();
    expect(list.length, 1);
    expect(list.first.title, 'Mon Super Document');
    expect(list.first.id, 'test-uuid-123');

    // 4. Update
    final updatedDoc = doc.copyWith(title: 'Mon Titre Modifie', progress: 0.5);
    await repository.updateDocument(updatedDoc);

    final fetched = await repository.getDocumentById('test-uuid-123');
    expect(fetched?.title, 'Mon Titre Modifie');
    expect(fetched?.progress, 0.5);

    // 5. Delete
    await repository.deleteDocument('test-uuid-123');
    list = await repository.getAllDocuments();
    expect(list.isEmpty, true);
  });
}

import 'package:drift/drift.dart';

@DataClassName('DocumentEntry')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get filePath => text()();
  TextColumn get textPath => text().nullable()();
  TextColumn get language => text().withDefault(const Constant('fr'))();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  IntColumn get lastPosition => integer().withDefault(const Constant(0))();
  IntColumn get totalSegments => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

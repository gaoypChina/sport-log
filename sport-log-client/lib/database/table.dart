import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sqflite/sqflite.dart';

import 'db_interfaces.dart';

export 'db_interfaces.dart';

abstract class DbAccessor<T extends DbObject> {
  DbSerializer<T> get serde;
  Table get table;

  List<String> get setupSql => [table.setupSql(), updateTrigger];

  String get tableName => table.name;

  Database get database {
    return AppDatabase.database!;
  }

  String get idAndDeletedAndStatus => '''
    id integer primary key,
    deleted integer not null default 0 check (deleted in (0, 1)),
    sync_status integer not null default 2 check (sync_status in (0, 1, 2))
  ''';

  String get updateTrigger => '''
    create trigger ${tableName}_update before update on $tableName
    begin
      update $tableName set sync_status = 1 where id = new.id and sync_status = 0;
    end;
  ''';

  Future<void> deleteSingle(Int64 id, {bool isSynchronized = false}) async {
    await database.update(
        tableName,
        {
          Keys.deleted: 1,
          if (isSynchronized) Keys.syncStatus: SyncStatus.synchronized.index,
        },
        where: '${Keys.deleted} = 0 AND ${Keys.id} = ?',
        whereArgs: [id.toInt()]);
  }

  Future<void> deleteMultiple(List<T> objects,
      {bool isSynchronized = false}) async {
    final batch = database.batch();
    for (final object in objects) {
      batch.update(
          tableName,
          {
            Keys.deleted: 1,
            if (isSynchronized) Keys.syncStatus: SyncStatus.synchronized.index,
          },
          where: '${Keys.deleted} = 0 AND ${Keys.id} = ?',
          whereArgs: [object.id.toInt()]);
    }
    await batch.commit(noResult: true, continueOnError: false);
  }

  Future<void> updateSingle(T object, {bool isSynchronized = false}) async {
    await database.update(
      tableName,
      {
        ...serde.toDbRecord(object),
        if (isSynchronized) Keys.syncStatus: SyncStatus.synchronized.index
      },
      where: '${Keys.deleted} = 0 AND ${Keys.id} = ?',
      whereArgs: [object.id.toInt()],
    );
  }

  Future<void> updateMultiple(List<T> objects,
      {bool isSynchronized = false}) async {
    final batch = database.batch();
    for (final object in objects) {
      batch.update(
        tableName,
        {
          ...serde.toDbRecord(object),
          if (isSynchronized) Keys.syncStatus: SyncStatus.synchronized.index
        },
        where: '${Keys.deleted} = 0 AND ${Keys.id} = ?',
        whereArgs: [object.id.toInt()],
      );
    }
    await batch.commit(noResult: true, continueOnError: false);
  }

  Future<void> createSingle(T object, {bool isSynchronized = false}) async {
    await database.insert(tableName, {
      ...serde.toDbRecord(object),
      if (isSynchronized) Keys.syncStatus: SyncStatus.synchronized.index,
    });
  }

  Future<void> createMultiple(List<T> objects,
      {bool isSynchronized = false}) async {
    final batch = database.batch();
    for (final object in objects) {
      batch.insert(tableName, {
        ...serde.toDbRecord(object),
        if (isSynchronized) Keys.syncStatus: SyncStatus.synchronized.index,
      });
    }
    await batch.commit(noResult: true, continueOnError: false);
  }

  Future<List<T>> getNonDeleted() async {
    final result =
        await database.query(tableName, where: '${Keys.deleted} = 0');
    return result.map(serde.fromDbRecord).toList();
  }

  Future<List<T>> getWithSyncStatus(SyncStatus syncStatus) async {
    final result = await database.query(tableName,
        where: '${Keys.syncStatus} = ?', whereArgs: [syncStatus.index]);
    return result.map(serde.fromDbRecord).toList();
  }

  Future<T?> getSingle(Int64 id) async {
    final result = await database
        .query(tableName, where: "${Keys.id} = ?", whereArgs: [id.toInt()]);
    return result.isEmpty ? null : serde.fromDbRecord(result.first);
  }

  static final synchronized = {Keys.syncStatus: SyncStatus.synchronized.index};

  Future<void> setSynchronized(Int64 id) async {
    await database.update(tableName, synchronized,
        where: '${Keys.id} = ?', whereArgs: [id.toInt()]);
  }

  Future<void> setAllUpdatedSynchronized() async {
    await database.update(tableName, synchronized,
        where: '${Keys.syncStatus} = ${SyncStatus.updated.index}');
  }

  Future<void> setAllCreatedSynchronized() async {
    await database.update(tableName, synchronized,
        where: '${Keys.syncStatus} = ${SyncStatus.created.index}');
  }

  Future<void> upsertMultiple(List<T> objects,
      {required bool synchronized}) async {
    final batch = database.batch();
    for (final object in objects) {
      // TODO: what it sync_status == 1 or sync_status == 2?
      batch.insert(
          tableName,
          {
            ...serde.toDbRecord(object),
            if (synchronized) Keys.syncStatus: SyncStatus.synchronized.index,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true, continueOnError: false);
  }
}

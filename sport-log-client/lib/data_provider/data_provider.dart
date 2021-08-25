import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/logger.dart';

final logger = Logger('DP');

void resultSink(Result<dynamic, dynamic> result) {
  if (result.isFailure) {
    logger.e('Got result with failure.', result.failure, StackTrace.current);
  }
}

abstract class DataProvider<T extends DbObject> {
  ApiAccessor<T> get api;
  Table<T> get db;

  void handleApiError(ApiError error) {}
  void handleDbError(DbError error) {}

  Future<List<T>> getNonDeleted() async {
    final result = await db.getNonDeleted();
    if (result.isFailure) {
      handleDbError(result.failure);
      return [];
    }
    return result.success;
  }

  Future<void> pushToServer() async {
    await Future.wait([
      _pushUpdatedToServer(),
      _pushCreatedToServer(),
    ]);
  }

  Future<void> _pushUpdatedToServer() async {
    final dbResult = await db.getWithSyncStatus(SyncStatus.updated);
    if (dbResult.isFailure) {
      handleDbError(dbResult.failure);
      return;
    }
    final apiResult = await api.putMultiple(dbResult.success);
    if (apiResult.isFailure) {
      handleApiError(apiResult.failure);
      return;
    }
    db.setAllUpdatedSynchronized().then(resultSink);
  }

  Future<void> _pushCreatedToServer() async {
    final dbResult = await db.getWithSyncStatus(SyncStatus.created);
    if (dbResult.isFailure) {
      handleDbError(dbResult.failure);
      return;
    }
    final apiResult = await api.postMultiple(dbResult.success);
    if (apiResult.isFailure) {
      handleApiError(apiResult.failure);
      return;
    }
    db.setAllCreatedSynchronized().then(resultSink);
  }
}

mixin ConnectedMethods<T extends DbObject> on DataProvider<T> {
  Future<bool> createSingle(T object) async {
    assert(object.isValid());
    final result = await api.postSingle(object);
    if (result.isFailure) {
      handleApiError(result.failure);
      return false;
    }
    db.createSingle(object, isSynchronized: true).then(resultSink);
    return true;
  }

  Future<bool> updateSingle(T object) async {
    assert(object.deleted || object.isValid());
    final result = await api.putSingle(object);
    if (result.isFailure) {
      handleApiError(result.failure);
      return false;
    }
    db.updateSingle(object, isSynchronized: true).then(resultSink);
    return true;
  }

  Future<bool> deleteSingle(T object) async {
    return updateSingle(object..deleted = true);
  }
}

mixin UnconnectedMethods<T extends DbObject> on DataProvider<T> {
  Future<bool> createSingle(T object) async {
    assert(object.isValid());
    final result = await db.createSingle(object);
    if (result.isFailure) {
      handleDbError(result.failure);
      return false;
    }
    api.postSingle(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.id).then(resultSink);
      }
    });
    return true;
  }

  Future<bool> updateSingle(T object) async {
    assert(object.deleted || object.isValid());
    final result = await db.updateSingle(object);
    if (result.isFailure) {
      handleDbError(result.failure);
      return false;
    }
    api.putSingle(object).then((result) {
      if (result.isFailure) {
        handleApiError(result.failure);
      } else {
        db.setSynchronized(object.id).then(resultSink);
      }
    });
    return true;
  }

  Future<bool> deleteSingle(T object) async {
    return updateSingle(object..deleted = true);
  }
}

import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/eorm.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';

import 'movement_table.dart';

class StrengthSessionAndMovement {
  StrengthSessionAndMovement({
    required this.session,
    required this.movement,
  });
  StrengthSession session;
  Movement movement;
}

class StrengthSessionTable extends TableAccessor<StrengthSession> {
  final _logger = Logger('StrengthSessionTable');

  @override
  DbSerializer<StrengthSession> get serde => DbStrengthSessionSerializer();

  @override
  List<String> get setupSql => [
        ...super.setupSql,
        '''
        CREATE TABLE $eorm (
          $eormReps INTEGER PRIMARY KEY CHECK ($eormReps >= 1),
          $eormPercentage REAL NOT NULL CHECK ($eormPercentage > 0)
        );
        ''',
        '''
        INSERT INTO $eorm ($eormReps, $eormPercentage) VALUES $eormValuesSql;
        ''',
      ];

  @override
  final Table table = Table(Tables.strengthSession, columns: [
    Column.int(Columns.id).primaryKey(),
    Column.bool(Columns.deleted).withDefault('0'),
    Column.int(Columns.syncStatus).withDefault('2').checkIn(<int>[0, 1, 2]),
    Column.int(Columns.userId),
    Column.text(Columns.datetime).withDefault("DATETIME('now')"),
    Column.int(Columns.movementId)
        .references(Tables.movement, onDelete: OnAction.cascade),
    Column.int(Columns.interval).nullable().checkGt(0),
    Column.text(Columns.comments).nullable(),
  ]);

  static const count = Columns.count;
  static const datetime = Columns.datetime;
  static const deleted = Columns.deleted;
  static const eormPercentage = Columns.eormPercentage;
  static const eormReps = Columns.eormReps;
  static const id = Columns.id;
  static const maxCount = Columns.maxCount;
  static const maxEorm = Columns.maxEorm;
  static const maxWeight = Columns.maxWeight;
  static const minCount = Columns.minCount;
  static const movementId = Columns.movementId;
  static const name = Columns.name;
  static const numSets = Columns.numSets;
  static const setNumber = Columns.setNumber;
  static const strengthSessionId = Columns.strengthSessionId;
  static const sumCount = Columns.sumCount;
  static const sumVolume = Columns.sumVolume;
  static const weight = Columns.weight;

  static const strengthSet = Tables.strengthSet;
  static const movement = Tables.movement;
  static const eorm = Tables.eorm;

  static MovementTable get _movementTable => AppDatabase.movements;
  static StrengthSetTable get _strengthSetTable => AppDatabase.strengthSets;

  Future<StrengthSessionDescription?> getById(Int64 idValue) async {
    final records = await database.rawQuery('''
      SELECT
        ${table.allColumns},
        ${_movementTable.table.allColumns}
      FROM $tableName
        JOIN $movement ON $movement.$id = $tableName.$movementId
      WHERE $tableName.$deleted = 0
        AND $movement.$deleted = 0
        AND $tableName.$id = ?;
    ''', [idValue.toInt()]);
    if (records.isEmpty) {
      return null;
    }
    return StrengthSessionDescription(
      session: serde.fromDbRecord(records.first, prefix: table.prefix),
      movement: _movementTable.serde
          .fromDbRecord(records.first, prefix: _movementTable.table.prefix),
      sets: await _strengthSetTable.getByStrengthSession(idValue),
    );
  }

  Future<List<StrengthSessionDescription>> getByTimerangeAndMovement({
    Int64? movementIdValue,
    DateTime? from,
    DateTime? until,
  }) async {
    final records = await database.rawQuery('''
      SELECT
        ${table.allColumns},
        ${_movementTable.table.allColumns}
      FROM $tableName
      JOIN $movement ON $movement.$id = $tableName.$movementId
      WHERE $movement.$deleted = 0
        AND $tableName.$deleted = 0
        ${fromFilter(from)}
        ${untilFilter(until)}
        ${movementIdFilter(movementIdValue)}
      $groupById
      $orderByDatetime
      ;
    ''', [
      if (from != null) from.toString(),
      if (until != null) until.toString(),
      if (movementIdValue != null) movementIdValue.toInt(),
    ]);
    List<StrengthSessionDescription> strengthSessionDescriptions = [];
    for (Map<String, Object?> record in records) {
      final session = serde.fromDbRecord(record, prefix: table.prefix);
      strengthSessionDescriptions.add(StrengthSessionDescription(
        session: session,
        sets: await _strengthSetTable.getByStrengthSession(session.id),
        movement: _movementTable.serde
            .fromDbRecord(record, prefix: _movementTable.table.prefix),
      ));
    }
    return strengthSessionDescriptions;
  }

  // this is only needed for test data generation
  Future<List<StrengthSessionAndMovement>> getSessionsWithMovements() async {
    // TODO: ignore strength session that have strength sets
    final records = await database.rawQuery('''
      SELECT
        ${table.allColumns},
        ${_movementTable.table.allColumns}
      FROM $tableName
      JOIN $movement ON $movement.id = $tableName.$movementId
      WHERE $tableName.$deleted = 0
        AND $movement.$deleted = 0;
    ''');
    return records.mapToList((r) => StrengthSessionAndMovement(
          session: serde.fromDbRecord(r, prefix: table.prefix),
          movement: _movementTable.serde
              .fromDbRecord(r, prefix: _movementTable.table.prefix),
        ));
  }

  Future<List<StrengthSet>> getSetsOnDay({
    required DateTime date,
    required Int64 movementIdValue,
  }) async {
    final start = date.beginningOfDay();
    final end = date.endOfDay();
    final records = await database.rawQuery('''
      SELECT
        ${_strengthSetTable.table.allColumns}
      FROM $tableName
        JOIN $strengthSet ON $strengthSet.$strengthSessionId = $tableName.$id
      WHERE $strengthSet.$deleted = 0
        AND $tableName.$deleted = 0
        AND $tableName.$datetime >= ?
        AND $tableName.$datetime < ?
        AND $tableName.$movementId = ?
      ORDER BY $tableName.$datetime, $tableName.$id, $strengthSet.$setNumber;
    ''', [start.toString(), end.toString(), movementIdValue.toInt()]);
    return records.mapToList((record) => _strengthSetTable.serde
        .fromDbRecord(record, prefix: _strengthSetTable.table.prefix));
  }

  Future<List<StrengthSessionStats>> getStatsAggregationsByDay({
    required Int64 movementIdValue,
    required DateTime from,
    required DateTime until,
  }) async {
    final records = await database.rawQuery('''
      SELECT
        $tableName.$datetime AS [$datetime],
        date($tableName.$datetime) AS [date],
        COUNT($strengthSet.$id) AS $numSets,
        MIN($strengthSet.$count) AS $minCount,
        MAX($strengthSet.$count) AS $maxCount,
        SUM($strengthSet.$count) AS $sumCount,
        MAX($strengthSet.$weight) AS $maxWeight,
        SUM($strengthSet.$count * $strengthSet.$weight) AS $sumVolume,
        MAX($strengthSet.$weight / $eormPercentage) AS $maxEorm
      FROM $tableName
        JOIN $strengthSet ON $strengthSet.$strengthSessionId = $tableName.$id
        LEFT JOIN $eorm ON $eormReps = $strengthSet.$count
      WHERE $strengthSet.$deleted = 0
        AND $tableName.$deleted = 0
        AND $tableName.$movementId = ?
        AND $tableName.$datetime >= ?
        AND $tableName.$datetime < ?
      GROUP BY [date]
      ORDER BY [date];
     ''', [movementIdValue.toInt(), from.toString(), until.toString()]);
    _logger.d(records);
    return records
        .map((record) => StrengthSessionStats.fromDbRecord(record))
        .toList();
  }

  Future<List<StrengthSessionStats>> getStatsAggregationsByWeek({
    required Int64 movementIdValue,
    required DateTime from,
    required DateTime until,
  }) async {
    assert(
        from.year == until.year || from.beginningOfYear().yearLater() == until);
    final records = await database.rawQuery('''
      SELECT
        $tableName.$datetime AS [$datetime],
        strftime('%W', $tableName.$datetime) AS week,
        COUNT($strengthSet.$id) AS $numSets,
        MIN($strengthSet.$count) AS $minCount,
        MAX($strengthSet.$count) AS $maxCount,
        SUM($strengthSet.$count) AS $sumCount,
        MAX($strengthSet.$weight) AS $maxWeight,
        SUM($strengthSet.$count * $strengthSet.$weight) AS $sumVolume,
        MAX($strengthSet.$weight / $eormPercentage) AS $maxEorm
      FROM $tableName
        JOIN $strengthSet ON $strengthSet.$strengthSessionId = $tableName.$id
        LEFT JOIN $eorm ON $eormReps = $strengthSet.$count
      WHERE $strengthSet.$deleted = 0
        AND $tableName.$deleted = 0
        AND $tableName.$movementId = ?
        AND $tableName.$datetime >= ?
        AND $tableName.$datetime < ?
      GROUP BY week
      ORDER BY week;
    ''', [movementIdValue.toInt(), from.toString(), until.toString()]);
    _logger.d(records);
    return records
        .map((record) => StrengthSessionStats.fromDbRecord(record))
        .toList();
  }

  Future<List<StrengthSessionStats>> getStatsAggregationsByMonth({
    required Int64 movementIdValue,
  }) async {
    final records = await database.rawQuery('''
      SELECT
        $tableName.$datetime AS [$datetime],
        strftime('%Y_%m', $tableName.$datetime) AS month,
        COUNT($strengthSet.$id) AS $numSets,
        MIN($strengthSet.$count) AS $minCount,
        MAX($strengthSet.$count) AS $maxCount,
        SUM($strengthSet.$count) AS $sumCount,
        MAX($strengthSet.$weight) AS $maxWeight,
        SUM($strengthSet.$count * $strengthSet.$weight) AS $sumVolume,
        MAX($strengthSet.$weight / $eormPercentage) AS $maxEorm
      FROM $tableName
        JOIN $strengthSet ON $strengthSet.$strengthSessionId = $tableName.$id
        LEFT JOIN $eorm ON $eormReps = $strengthSet.$count
      WHERE $strengthSet.$deleted = 0
        AND $tableName.$deleted = 0
        AND $tableName.$movementId = ?
      GROUP BY month
      ORDER BY month;
    ''', [movementIdValue.toInt()]);
    _logger.d(records);
    return records
        .map((record) => StrengthSessionStats.fromDbRecord(record))
        .toList();
  }
}

class StrengthSetTable extends TableAccessor<StrengthSet> {
  @override
  DbSerializer<StrengthSet> get serde => DbStrengthSetSerializer();

  @override
  final Table table = Table(
    Tables.strengthSet,
    columns: [
      Column.int(Columns.id).primaryKey(),
      Column.bool(Columns.deleted).withDefault('0'),
      Column.int(Columns.syncStatus).withDefault('2').checkIn(<int>[0, 1, 2]),
      Column.int(Columns.strengthSessionId)
          .references(Tables.strengthSession, onDelete: OnAction.cascade),
      Column.int(Columns.setNumber).checkGe(0),
      Column.int(Columns.count).checkGe(1),
      Column.real(Columns.weight).nullable().checkGt(0),
    ],
  );

  Future<void> setSynchronizedByStrengthSession(Int64 id) async {
    database.update(tableName, TableAccessor.synchronized,
        where: '${Columns.strengthSessionId} = ?', whereArgs: [id.toInt()]);
  }

  Future<List<StrengthSet>> getByStrengthSession(Int64 id) async {
    final result = await database.query(tableName,
        where: '${Columns.strengthSessionId} = ? AND ${Columns.deleted} = 0',
        whereArgs: [id.toInt()],
        orderBy: Columns.setNumber);
    return result.map(serde.fromDbRecord).toList();
  }

  Future<void> deleteByStrengthSession(Int64 id) async {
    await database.update(tableName, {Columns.deleted: 1},
        where: '${Columns.strengthSessionId} = ? AND ${Columns.deleted} = 0',
        whereArgs: [id.toInt()]);
  }
}

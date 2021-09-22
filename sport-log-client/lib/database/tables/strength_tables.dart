import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_creator.dart';
import 'package:sport_log/database/table_names.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sqflite/sqflite.dart';

import 'movement_table.dart';

class StrengthSessionTable extends DbAccessor<StrengthSession>
    with DateTimeMethods {
  final _logger = Logger('StrengthSessionTable');

  @override
  DbSerializer<StrengthSession> get serde => DbStrengthSessionSerializer();

  static const statsViewBySession = 'strength_session_stats_view_by_session';
  static const statsViewByDay = 'strength_session_stats_view_by_day';
  static const strengthSet = Tables.strengthSet;
  static const movement = Tables.movement;
  static const strengthSessionId = Keys.strengthSessionId;
  static const id = Keys.id;
  static const movementId = Keys.movementId;
  static const deleted = Keys.deleted;
  static const datetime = Keys.datetime;
  static const numSets = Keys.numSets;
  static const minCount = Keys.minCount;
  static const maxCount = Keys.maxCount;
  static const sumCount = Keys.sumCount;
  static const sumVolume = Keys.sumVolume;
  static const maxWeight = Keys.maxWeight;
  static const maxEorm = Keys.maxEorm;
  static const count = Keys.count;
  static const weight = Keys.weight;
  static const eorm = Tables.eorm;
  static const eormReps = Keys.eormReps;
  static const eormPercentage = Keys.eormPercentage;

  @override
  Future<List<String>> init() async {
    return [
      _table.setupSql(),
      updateTrigger,
      '''
        CREATE TABLE $eorm (
          $eormReps INTEGER PRIMARY KEY CHECK ($eormReps >= 1),
          $eormPercentage REAL NOT NULL CHECK ($eormPercentage > 0)
        );
      ''',
      '''
        INSERT INTO $eorm ($eormReps, $eormPercentage) VALUES
          (1, 1.0),
          (2, 0.97),
          (3, 0.94),
          (4, 0.92),
          (5, 0.89),
          (6, 0.86),
          (7, 0.83),
          (8, 0.81),
          (9, 0.78),
          (10, 0.75),
          (11, 0.73),
          (12, 0.71),
          (13, 0.70),
          (14, 0.68),
          (15, 0.67),
          (16, 0.65),
          (17, 0.64),
          (18, 0.63),
          (19, 0.61),
          (20, 0.60),
          (21, 0.59),
          (22, 0.58),
          (23, 0.57),
          (24, 0.56),
          (25, 0.55),
          (26, 0.54),
          (27, 0.53),
          (28, 0.52),
          (29, 0.51),
          (30, 0.50);
        ''',
      '''
          CREATE VIEW $statsViewBySession AS
          SELECT
            ${_table.allColumns},
            ${_movementTable.table.allColumns},
            COUNT($strengthSet.$id) AS $numSets,
            MIN($strengthSet.$count) AS $minCount,
            MAX($strengthSet.$count) AS $maxCount,
            SUM($strengthSet.$count) AS $sumCount,
            MAX($strengthSet.$weight) AS $maxWeight,
            SUM($strengthSet.$count * $strengthSet.$weight) AS $sumVolume,
            MAX($strengthSet.$weight / $eormPercentage) AS $maxEorm
          FROM $tableName
            JOIN $movement ON $movement.$id = $tableName.$movementId
            JOIN $strengthSet ON $strengthSet.$strengthSessionId = $tableName.$id
            LEFT JOIN $eorm ON $eormReps = $strengthSet.$count
          WHERE $movement.$deleted = 0
            AND $strengthSet.$deleted = 0
            AND $tableName.$deleted = 0
          GROUP BY $tableName.$id
          HAVING COUNT($strengthSet.$id) > 0
          ORDER BY datetime($tableName.$datetime);
        ''',
      '''
          CREATE VIEW $statsViewByDay AS
          SELECT
            $tableName.$datetime,
            COUNT($strengthSet.$id) AS $numSets,
            MIN($strengthSet.$count) AS $minCount,
            MAX($strengthSet.$count) AS $maxCount,
            SUM($strengthSet.$count) AS $sumCount,
            MAX($strengthSet.$weight) AS $maxWeight,
            SUM($strengthSet.$count * $strengthSet.$weight) AS $sumVolume,
            MAX($strengthSet.$weight / $eormPercentage) AS $maxEorm
          FROM $tableName
            JOIN $movement ON $movement.$id = $tableName.$movementId
            JOIN $strengthSet ON $strengthSet.$strengthSessionId = $tableName.$id
            LEFT JOIN $eorm ON $eormReps = $strengthSet.$count
          WHERE $movement.$deleted = 0
            AND $strengthSet.$deleted = 0
            AND $tableName.$deleted = 0
          GROUP BY date($tableName.$datetime)
          ORDER BY date($tableName.$datetime);
        '''
    ];
  }

  @override
  String get tableName => _table.name;

  final Table _table = Table(Tables.strengthSession, withColumns: [
    Column.int(Keys.id).primaryKey(),
    Column.bool(Keys.deleted).withDefault('0'),
    Column.int(Keys.syncStatus)
        .withDefault('2')
        .check('${Keys.syncStatus} IN (0, 1, 2)'),
    Column.int(Keys.userId),
    Column.text(Keys.datetime).withDefault("DATETIME('now')"),
    Column.int(Keys.movementId)
        .references(Tables.movement, onDelete: OnAction.cascade),
    Column.int(Keys.movementUnit).check('${Keys.movementUnit} BETWEEN 0 AND 6'),
    Column.int(Keys.interval).nullable().check('${Keys.interval} > 0'),
    Column.text(Keys.comments).nullable(),
  ]);

  MovementTable get _movementTable => AppDatabase.instance!.movements;

  String? _whereFilter(
    Int64? movementIdValue,
    DateTime? from,
    DateTime? until,
  ) {
    final filters = [
      if (from != null) '${_table.prefix}$datetime >= ?',
      if (until != null) '${_table.prefix}$datetime < ?',
      if (movementIdValue != null) '${_table.prefix}$movementId = ?',
    ];
    return filters.isEmpty ? null : filters.join(' AND ');
  }

  List<Object> _args(
    Int64? movementIdValue,
    DateTime? from,
    DateTime? until,
  ) =>
      [
        if (from != null) from.toString(),
        if (until != null) until.toString(),
        if (movementIdValue != null) movementIdValue.toInt(),
      ];

  Future<List<StrengthSessionDescription>> getDescriptionsBySession({
    Int64? movementIdValue,
    DateTime? from,
    DateTime? until,
  }) async {
    final records = await database.query(statsViewBySession,
        where: _whereFilter(movementIdValue, from, until),
        whereArgs: _args(movementIdValue, from, until));
    return records
        .map((record) => StrengthSessionDescription(
              strengthSession:
                  serde.fromDbRecord(record, prefix: _table.prefix),
              strengthSets: null,
              movement: _movementTable.serde
                  .fromDbRecord(record, prefix: _movementTable.table.prefix),
              stats: StrengthSessionStats.fromDbRecord(record),
            ))
        .toList();
  }

  Future<List<StrengthSessionStats>> getDescriptionsByDay({
    required Int64 movementIdValue,
    DateTime? from,
    DateTime? until,
  }) async {
    final records = await database.query(statsViewByDay,
        where: _whereFilter(movementIdValue, from, until),
        whereArgs: _args(movementIdValue, from, until));
    return records
        .map((record) => StrengthSessionStats.fromDbRecord(record))
        .toList();
  }

  @override
  String? get setupSql => null;
}

class StrengthSetTable extends DbAccessor<StrengthSet> {
  @override
  DbSerializer<StrengthSet> get serde => DbStrengthSetSerializer();
  @override
  String get setupSql => '''
create table $tableName (
    strength_session_id integer not null references strength_session on delete cascade,
    set_number integer not null check (set_number >= 0),
    count integer not null check (count >= 1), -- number of completed movement_unit
    weight real check (weight > 0),
    $idAndDeletedAndStatus
);

create index ${tableName}_session_index on $tableName (strength_session_id)
  ''';
  @override
  String get tableName => Tables.strengthSet;

  Future<void> setSynchronizedByStrengthSession(Int64 id) async {
    database.update(tableName, DbAccessor.synchronized,
        where: '${Keys.strengthSessionId} = ?', whereArgs: [id.toInt()]);
  }

  Future<List<StrengthSet>> getByStrengthSession(Int64 id) async {
    final result = await database.query(tableName,
        where: '${Keys.strengthSessionId} = ? AND ${Keys.deleted} = 0',
        whereArgs: [id.toInt()],
        orderBy: Keys.setNumber);
    return result.map(serde.fromDbRecord).toList();
  }

  Future<void> deleteByStrengthSession(Int64 id) async {
    await database.update(tableName, {Keys.deleted: 1},
        where: '${Keys.strengthSessionId} = ? AND ${Keys.deleted} = 0',
        whereArgs: [id.toInt()]);
  }
}

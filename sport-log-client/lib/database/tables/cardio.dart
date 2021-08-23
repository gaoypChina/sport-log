
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/cardio/all.dart';

class CardioSessionTable extends Table<CardioSession> {
  @override DbSerializer<CardioSession> get serde => DbCardioSessionSerializer();
  @override String get setupSql => '''
create table cardio_session (
    user_id integer not null,
    movement_id integer not null references movement(id) on delete no action,
    cardio_type integer not null check(cardio_type between 0 and 2),
    datetime text not null default (datetime('now')),
    distance integer check (distance > 0),
    ascent integer check (ascent >= 0),
    descent integer check (descent >= 0),
    time integer check (time > 0), -- seconds
    calories integer check (calories >= 0),
    track blob,
    avg_cadence integer check (avg_cadence > 0), 
    cadence blob, -- = secs since start
    avg_heart_rate integer check (avg_heart_rate > 0),
    heart_rate blob, -- = secs since start
    route_id integer references route(id) on delete set null,
    comments text,
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => 'cardio_session';
}

class RouteTable extends Table<Route> {
  @override DbSerializer<Route> get serde => DbRouteSerializer();
  @override String get setupSql => '''
create table route (
    user_id integer not null,
    name text not null check (length(name) >= 2),
    distance integer not null check (distance > 0),
    ascent integer check (ascent >= 0),
    descent integer check (descent >= 0),
    track blob not null,
    $idAndDeletedAndStatus
);
  ''';
  @override String get tableName => 'route';
}

import 'package:fixnum/fixnum.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_set.dart';

import 'strength_session_stats.dart';

class StrengthSessionWithSets implements Validatable, HasId {
  StrengthSessionWithSets({
    required this.session,
    required this.movement,
    required this.sets,
  });

  StrengthSession session;
  Movement movement;
  List<StrengthSet> sets;

  @override
  bool isValid() {
    return validate(session.isValid(),
            'StrengthSessionDescription: strength session not valid') &&
        validate(sets.isNotEmpty,
            'StrengthSessionDescription: strength sets empty') &&
        validate(sets.every((ss) => ss.strengthSessionId == session.id),
            'StrengthSessionDescription: strengthSessionId != strengthSession.id') &&
        validate(sets.everyIndexed((ss, index) => ss.setNumber == index),
            'StrengthSessionDescription: strengthSets indices wrong') &&
        validate(sets.every((ss) => ss.isValid()),
            'StrengthSessionDescription: strengthSets not valid') &&
        validate(session.movementId == movement.id,
            'StrengthSessionDescription: movement id mismatch') &&
        validate(!movement.deleted,
            'StrengthSessionDescription: movement is deleted');
  }

  @override
  Int64 get id => session.id;

  void setDeleted() {
    session.deleted = true;
    for (final set in sets) {
      set.deleted = true;
    }
  }

  StrengthSessionWithSets.defaultValue(this.movement, Int64 userId)
      : session = StrengthSession(
          id: randomId(),
          userId: userId,
          datetime: DateTime.now(),
          movementId: movement.id,
          interval: null,
          comments: null,
          deleted: false,
        ),
        sets = [];

  StrengthSessionStats? calculateStats() {
    if (sets.isEmpty) {
      return null;
    }
    return StrengthSessionStats.fromStrengthSets(
        sets: sets, dateTime: session.datetime);
  }

  StrengthSessionWithSets copy() {
    return StrengthSessionWithSets(
      session: session.copy(),
      movement: movement.copy(),
      sets: sets.mapToL((set) => set.copy()),
    );
  }
}

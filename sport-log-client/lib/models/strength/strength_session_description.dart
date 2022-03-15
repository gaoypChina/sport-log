import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/models/strength/strength_set.dart';
import 'package:sport_log/settings.dart';

part 'strength_session_description.g.dart';

@JsonSerializable()
class StrengthSessionDescription extends CompoundEntity {
  StrengthSessionDescription({
    required this.session,
    required this.movement,
    required this.sets,
  });

  StrengthSession session;
  Movement movement;
  List<StrengthSet> sets;

  StrengthSessionStats get stats =>
      StrengthSessionStats.fromStrengthSets(session.datetime, sets);

  factory StrengthSessionDescription.fromJson(Map<String, dynamic> json) =>
      _$StrengthSessionDescriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StrengthSessionDescriptionToJson(this);

  @override
  StrengthSessionDescription clone() => StrengthSessionDescription(
        session: session.clone(),
        movement: movement.clone(),
        sets: sets.map((s) => s.clone()).toList(),
      );

  @override
  bool isValidIgnoreEmptyNotNull() {
    return validate(
          session.isValid(),
          'StrengthSessionDescription: strength session not valid',
        ) &&
        validate(
          sets.isNotEmpty,
          'StrengthSessionDescription: strength sets empty',
        ) &&
        validate(
          sets.every((ss) => ss.strengthSessionId == session.id),
          'StrengthSessionDescription: strengthSessionId != strengthSession.id',
        ) &&
        validate(
          sets.everyIndexed((ss, index) => ss.setNumber == index),
          'StrengthSessionDescription: strengthSets indices wrong',
        ) &&
        validate(
          sets.every((ss) => ss.isValid()),
          'StrengthSessionDescription: strengthSets not valid',
        ) &&
        validate(
          session.movementId == movement.id,
          'StrengthSessionDescription: movement id mismatch',
        ) &&
        validate(
          !movement.deleted,
          'StrengthSessionDescription: movement is deleted',
        );
  }

  @override
  bool isValid() {
    return isValidIgnoreEmptyNotNull();
  }

  @override
  void setEmptyToNull() {
    session.setEmptyToNull();
    for (StrengthSet set in sets) {
      set.setEmptyToNull();
    }
  }

  void setDeleted() {
    session.deleted = true;
    for (final set in sets) {
      set.deleted = true;
    }
  }

  void orderSets() {
    sets.forEachIndexed((set, index) => set.setNumber = index);
  }

  static StrengthSessionDescription defaultValue() {
    final movement = Movement.defaultMovement;
    return StrengthSessionDescription(
      session: StrengthSession(
        id: randomId(),
        userId: Settings.userId!,
        datetime: DateTime.now(),
        movementId: movement.id,
        interval: null,
        comments: null,
        deleted: false,
      ),
      movement: movement,
      sets: [],
    );
  }
}

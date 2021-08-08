// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionRule _$ActionRuleFromJson(Map<String, dynamic> json) => ActionRule(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      actionId: json['action_id'] as int,
      weekday: _$enumDecode(_$WeekdayEnumMap, json['weekday']),
      time: const NaiveTimeSerde().fromJson(json['time'] as String),
      enabled: json['enabled'] as bool,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionRuleToJson(ActionRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'action_id': instance.actionId,
      'weekday': _$WeekdayEnumMap[instance.weekday],
      'time': const NaiveTimeSerde().toJson(instance.time),
      'enabled': instance.enabled,
      'deleted': instance.deleted,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$WeekdayEnumMap = {
  Weekday.monday: 'Monday',
  Weekday.tuesday: 'Tuesday',
  Weekday.wednesday: 'Wednesday',
  Weekday.thursday: 'Thursday',
  Weekday.friday: 'Friday',
  Weekday.saturday: 'Saturday',
  Weekday.sunday: 'Sunday',
};

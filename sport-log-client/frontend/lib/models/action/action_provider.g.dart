// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionProvider _$ActionProviderFromJson(Map<String, dynamic> json) =>
    ActionProvider(
      id: json['id'] as int,
      name: json['name'] as String,
      password: json['password'] as String,
      platformId: json['platform_id'] as int,
      description: json['description'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionProviderToJson(ActionProvider instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'password': instance.password,
      'platform_id': instance.platformId,
      'description': instance.description,
      'deleted': instance.deleted,
    };

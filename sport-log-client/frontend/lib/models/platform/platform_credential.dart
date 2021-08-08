
import 'package:json_annotation/json_annotation.dart';

part 'platform_credential.g.dart';

@JsonSerializable()
class PlatformCredential {
  PlatformCredential({
    required this.id,
    required this.userId,
    required this.platformId,
    required this.username,
    required this.password,
    required this.deleted,
  });

  int id;
  int userId;
  int platformId;
  String username;
  String password;
  bool deleted;

  factory PlatformCredential.fromJson(Map<String, dynamic> json) => _$PlatformCredentialFromJson(json);
  Map<String, dynamic> toJson() => _$PlatformCredentialToJson(this);
}
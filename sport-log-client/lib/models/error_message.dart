import 'package:json_annotation/json_annotation.dart';

part 'error_message.g.dart';

enum ErrorMessageType {
  primaryKeyViolation,
  foreignKeyViolation,
  uniqueViolation,
  other;
}

class ErrorMessage extends JsonSerializable {
  ErrorMessage.primaryKeyViolation(this.table)
      : type = ErrorMessageType.primaryKeyViolation,
        column = null,
        columns = null,
        error = null;
  ErrorMessage.foreignKeyViolation(this.table, this.column)
      : type = ErrorMessageType.foreignKeyViolation,
        columns = null,
        error = null;
  ErrorMessage.uniqueViolation(this.table, this.columns)
      : type = ErrorMessageType.uniqueViolation,
        column = null,
        error = null;
  ErrorMessage.other(this.error)
      : type = ErrorMessageType.other,
        table = null,
        column = null,
        columns = null;

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    final type = json.keys.first;
    final body = json[type] as Map<String, dynamic>;
    switch (type) {
      case "primary_key_violation":
        return ErrorMessage.primaryKeyViolation(body["table"] as String);
      case "foreign_key_violation":
        return ErrorMessage.foreignKeyViolation(
          body["table"] as String,
          body["column"] as String,
        );
      case "unique_violation":
        return ErrorMessage.uniqueViolation(
          body["table"] as String,
          (body["columns"] as List<dynamic>).cast<String>(),
        );
      case "other":
        return ErrorMessage.other(body["error"] as String);
      default:
        throw TypeError();
    }
  }

  final ErrorMessageType type;
  final String? table; // not for other
  final String? column; // only foreign key violation
  final List<String>? columns; // only unique violation
  final String? error; // only other

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        '$type': <String, dynamic>{
          'table': table,
          'column': column,
          'columns': columns,
          'error': error,
        }
      };

  @override
  String toString() {
    switch (type) {
      case ErrorMessageType.primaryKeyViolation:
        return "primary key violation in table $table";
      case ErrorMessageType.foreignKeyViolation:
        return "foreign key violation in table $table in column $column";
      case ErrorMessageType.uniqueViolation:
        return "unique violation in table $table in columns $columns";
      case ErrorMessageType.other:
        return "$error";
    }
  }
}

@JsonSerializable()
class HandlerError extends JsonSerializable {
  HandlerError({required this.status, required this.message});

  factory HandlerError.fromJson(Map<String, dynamic> json) =>
      _$HandlerErrorFromJson(json);

  int status;
  ErrorMessage? message;

  @override
  Map<String, dynamic> toJson() => _$HandlerErrorToJson(this);
}

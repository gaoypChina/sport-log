import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart' as l;
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/accessors/account_data_api.dart';
import 'package:sport_log/api/accessors/action_api.dart';
import 'package:sport_log/api/accessors/cardio_api.dart';
import 'package:sport_log/api/accessors/diary_api.dart';
import 'package:sport_log/api/accessors/metcon_api.dart';
import 'package:sport_log/api/accessors/movement_api.dart';
import 'package:sport_log/api/accessors/platform_api.dart';
import 'package:sport_log/api/accessors/strength_api.dart';
import 'package:sport_log/api/accessors/user_api.dart';
import 'package:sport_log/api/accessors/wod_api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/error_message.dart';
import 'package:sport_log/models/server_version/server_version.dart';
import 'package:sport_log/settings.dart';

final _logger = Logger('API');

String _prettyJson(Object json, {int indent = 2}) {
  final spaces = ' ' * indent;
  return JsonEncoder.withIndent(spaces).convert(json);
}

void _logRequest(Request request) {
  final headersStr = Config.instance.outputRequestHeaders
      ? "\n${request.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n')}"
      : "";
  final jsonStr = Config.instance.outputRequestJson && request.body.isNotEmpty
      ? "\n\n${_prettyJson(jsonDecode(request.body) as Object)}"
      : "";
  _logger.d("request: ${request.method} ${request.url}$headersStr$jsonStr");
}

void _logResponse(StreamedResponse response, Object? json) {
  final successful = response.statusCode >= 200 && response.statusCode < 300;
  final headerStr = Config.instance.outputResponseHeaders
      ? "\n${response.headers.entries.map((e) => "${e.key}: ${e.value}").join("\n")}"
      : "";
  final jsonStr = Config.instance.outputResponseJson && json != null
      ? "\n\n${_prettyJson(json)}"
      : "";
  _logger.log(
    successful ? l.Level.debug : l.Level.error,
    "response: ${response.statusCode}$headerStr$jsonStr",
  );
}

enum ApiErrorType {
  // http error
  badRequest("Request is not valid."), // 400
  unauthorized("User unauthorized."), // 401
  forbidden("Access to resource is forbidden."), // 403
  notFound("Resource not found."), // 404
  conflict("Conflict with resource."), // 409
  internalServerError("Internal server error."), // 500
  // unknown status code != 200, 204, 400, 401, 403, 404, 409, 500 request error
  unknownServerError("Unknown server error."),
  serverUnreachable("Unable to establish a connection with the server."),
  badJson("Got bad json from server."),
  unknownRequestError("Unhandled request error."); // unknown request error

  const ApiErrorType(this.description);

  final String description;
}

class ApiError {
  ApiError(this.errorType, this.errorCode, [this.message]);

  final ApiErrorType errorType;
  final int? errorCode;

  final ErrorMessage? message;

  @override
  String toString() {
    final description = errorType.description;
    final errorCodeStr = errorCode != null ? " (status $errorCode)" : "";
    final messageStr = message != null ? "\n$message" : "";
    return "$description$errorCodeStr$messageStr";
  }
}

typedef ApiResult<T> = Result<T, ApiError>;

extension _ToApiResult on StreamedResponse {
  ErrorMessage? _errorMessage(Object? json) => json != null
      ? HandlerError.fromJson(json as Map<String, dynamic>).message
      : null;

  // ignore: long-method
  Future<ApiResult<T?>> _mapToApiResult<T>(T Function(Object)? fromJson) async {
    // steam can be read only once
    final rawBody = utf8.decode(await stream.toBytes());
    final json = rawBody.isEmpty ? null : jsonDecode(rawBody) as Object;
    _logResponse(this, json);

    switch (statusCode) {
      case 200:
        return fromJson != null
            ? json != null
                ? Success(fromJson(json))
                // expected non empty body
                : Failure(ApiError(ApiErrorType.badJson, statusCode))
            : Success(null);
      case 204:
        return fromJson == null
            ? Success(null)
            // expected non empty body and status 200
            : Failure(ApiError(ApiErrorType.badJson, statusCode));
      case 400:
        return Failure(
          ApiError(ApiErrorType.badRequest, statusCode, _errorMessage(json)),
        );
      case 401:
        return Failure(
          ApiError(ApiErrorType.unauthorized, statusCode, _errorMessage(json)),
        );
      case 403:
        return Failure(
          ApiError(ApiErrorType.forbidden, statusCode, _errorMessage(json)),
        );
      case 404:
        return Failure(
          ApiError(ApiErrorType.notFound, statusCode, _errorMessage(json)),
        );
      case 409:
        return Failure(
          ApiError(ApiErrorType.conflict, statusCode, _errorMessage(json)),
        );
      case 500:
        return Failure(
          ApiError(
            ApiErrorType.internalServerError,
            statusCode,
            _errorMessage(json),
          ),
        );
      default:
        return Failure(
          ApiError(
            ApiErrorType.unknownServerError,
            statusCode,
            _errorMessage(json),
          ),
        );
    }
  }

  Future<ApiResult<void>> toApiResult() => _mapToApiResult(null);

  Future<ApiResult<T>> toApiResultWithValue<T>(
    T Function(Object) fromJson,
  ) async {
    final result = await _mapToApiResult(fromJson);
    return result.isSuccess
        ? Success(result.success as T)
        : Failure(result.failure);
  }
}

extension RequestExtension on Request {
  static final _ioClient = HttpClient()..connectionTimeout = Config.httpTimeout;
  static final _client = IOClient(_ioClient);

  static Future<ApiResult<T>> _handleError<T>(
    Future<ApiResult<T>> Function() fn,
  ) async {
    try {
      return await fn();
    } on SocketException {
      return Failure(ApiError(ApiErrorType.serverUnreachable, null));
    } on TypeError {
      return Failure(ApiError(ApiErrorType.badJson, null));
    } catch (e) {
      _logger.e("Unhandled error", e);
      return Failure(ApiError(ApiErrorType.unknownRequestError, null));
    }
  }

  Future<ApiResult<void>> toApiResult() => _handleError(() async {
        _logRequest(this);
        final response = await _client.send(this);
        return response.toApiResult();
      });

  Future<ApiResult<T>> toApiResultWithValue<T>(T Function(Object) fromJson) =>
      _handleError(() async {
        _logRequest(this);
        final response = await _client.send(this);
        return response.toApiResultWithValue(fromJson);
      });
}

abstract class Api<T extends JsonSerializable> {
  static final accountData = AccountDataApi();
  static final user = UserApi();
  static final actions = ActionApi();
  static final actionProviders = ActionProviderApi();
  static final actionRules = ActionRuleApi();
  static final actionEvents = ActionEventApi();
  static final cardioSessions = CardioSessionApi();
  static final routes = RouteApi();
  static final diaries = DiaryApi();
  static final metcons = MetconApi();
  static final metconSessions = MetconSessionApi();
  static final metconMovements = MetconMovementApi();
  static final movements = MovementApi();
  static final platforms = PlatformApi();
  static final platformCredentials = PlatformCredentialApi();
  static final strengthSessions = StrengthSessionApi();
  static final strengthSets = StrengthSetApi();
  static final wods = WodApi();

  static Future<ApiResult<ServerVersion>> getServerVersion() {
    final uri = Uri.parse("${Settings.instance.serverUrl}/version");
    return Request("get", uri).toApiResultWithValue(
      (json) => ServerVersion.fromJson(json as Map<String, dynamic>),
    );
  }

  T fromJson(Map<String, dynamic> json);

  /// everything after version, e. g. '/user'
  String get route;

  Uri get _uri =>
      Uri.parse("${Settings.instance.serverUrl}/v${Config.apiVersion}$route");
  Map<String, dynamic> _toJson(T object) => object.toJson();

  Future<ApiResult<T>> getSingle(Int64 id) =>
      (Request("get", Uri.parse("$_uri?id=$id"))
            ..headers.addAll(ApiHeaders.basicAuth))
          .toApiResultWithValue(
        (json) => fromJson(json as Map<String, dynamic>),
      );

  Future<ApiResult<List<T>>> getMultiple() =>
      (Request("get", _uri)..headers.addAll(ApiHeaders.basicAuth))
          .toApiResultWithValue(
        (json) => ((json as List<dynamic>).cast<Map<String, dynamic>>())
            .map(fromJson)
            .toList(),
      );

  Future<ApiResult<void>> postSingle(T object) => (Request("post", _uri)
        ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
        ..body = jsonEncode(_toJson(object)))
      .toApiResult();

  Future<ApiResult<void>> postMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return (Request("post", _uri)
          ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
          ..body = jsonEncode(objects.map(_toJson).toList()))
        .toApiResult();
  }

  Future<ApiResult<void>> putSingle(T object) => (Request("put", _uri)
        ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
        ..body = jsonEncode(_toJson(object)))
      .toApiResult();

  Future<ApiResult<void>> putMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return (Request("put", _uri)
          ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
          ..body = jsonEncode(objects.map(_toJson).toList()))
        .toApiResult();
  }
}

class ApiHeaders {
  static Map<String, String> basicAuthFromParts(
    String username,
    String password,
  ) =>
      {
        HttpHeaders.authorizationHeader:
            "Basic ${base64Encode(utf8.encode('$username:$password'))}"
      };

  static const Map<String, String> contentTypeJson = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
  };

  static Map<String, String> get basicAuth => basicAuthFromParts(
        Settings.instance.username!,
        Settings.instance.password!,
      );

  static Map<String, String> get basicAuthContentTypeJson => {
        ...basicAuth,
        ...contentTypeJson,
      };
}

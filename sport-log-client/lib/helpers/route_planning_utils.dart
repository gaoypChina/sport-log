import 'dart:convert';
import 'dart:io';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/position.dart';

enum RoutePlanningError {
  noInternet,
  unknown;

  String get message {
    return this == RoutePlanningError.noInternet
        ? 'No Internet connection.'
        : 'An unknown Error occurred.';
  }
}

class RoutePlanningUtils {
  static final _logger = Logger("RoutePlanningUtils");

  static final _ioClient = HttpClient()..connectionTimeout = Config.httpTimeout;
  static final _client = IOClient(_ioClient);

  static Future<Result<List<int>, RoutePlanningError>> getElevations(
    List<LatLng> track,
  ) async {
    // TODO currently the public API is overlaoded and often resuts with timeout
    return Success(track.map((e) => 0).toList());
    // ignore: dead_code
    final trackMap = {
      "locations": [
        for (final pos in track) {"latitude": pos.lat, "longitude": pos.lng}
      ]
    };
    final Response response;
    try {
      response = await _client.post(
        Uri.parse("https://api.open-elevation.com/api/v1/lookup"),
        body: jsonEncode(trackMap),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
    } on SocketException {
      return Failure(RoutePlanningError.noInternet);
    }
    if (response.statusCode == 200) {
      try {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final result = List<Map<String, dynamic>>.from(json["results"] as List);
        final elevations = result.map((e) => e["elevation"]! as int).toList();
        return Success(elevations);
      } on Exception {
        _logger.i("elevation api unknown error");
        return Failure(RoutePlanningError.unknown);
      }
    } else {
      _logger.i("elevation api unknown error");
      return Failure(RoutePlanningError.unknown);
    }
  }

  static Future<Result<List<Position>, RoutePlanningError>> matchLocations(
    List<Position> markedPositions,
  ) async {
    DirectionsApiResponse response;
    try {
      response = await Defaults.mapboxApi.directions.request(
        profile: NavigationProfile.WALKING,
        coordinates:
            markedPositions.map((e) => [e.latitude, e.longitude]).toList(),
      );
    } on SocketException {
      return Failure(RoutePlanningError.noInternet);
    }
    if (response.routes != null && response.routes!.isNotEmpty) {
      final navRoute = response.routes![0];
      final track = <Position>[];
      final latLngs = PolylinePoints()
          .decodePolyline(navRoute.geometry as String)
          .map((p) => LatLng(lat: p.latitude, lng: p.longitude))
          .toList();
      final elevations = await getElevations(latLngs);
      if (elevations.isFailure) {
        return Failure(elevations.failure);
      } else {
        assert(latLngs.length == elevations.success.length);
        for (var i = 0; i < latLngs.length; i++) {
          final latLng = latLngs[i];
          final elevation = elevations.success[i];
          track.add(
            Position(
              latitude: latLng.lat,
              longitude: latLng.lng,
              elevation: elevation.toDouble(),
              distance: track.isEmpty
                  ? 0
                  : track.last.addDistanceTo(latLng),
              time: Duration.zero,
            ),
          );
        }
        _logger
          ..i("mapbox distance ${navRoute.distance}")
          ..i("own distance ${track.last.distance}");
        return Success(track);
      }
    } else {
      _logger.i("mapbox api error ${response.error.runtimeType}");
      return Failure(RoutePlanningError.unknown);
    }
  }
}

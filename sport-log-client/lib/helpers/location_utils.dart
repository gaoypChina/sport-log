import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/request_permission.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class LocationUtils extends ChangeNotifier {
  StreamSubscription<LocationData>? _locationSubscription;
  GpsPosition? _lastLocation;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    final lastGpsPosition = lastLatLng;
    if (lastGpsPosition != null) {
      Settings.instance.setLastGpsLatLng(lastGpsPosition);
    }
    stopLocationStream();
    super.dispose();
  }

  static Future<bool> requestPermissions() async {
    if (!await PermissionRequest.request(Permission.locationWhenInUse)) {
      return false;
    }
    if (!await Permission.locationAlways.isGranted) {
      final context = App.globalContext;
      if (context.mounted) {
        await showMessageDialog(
          context: context,
          title: "Permission Required",
          text: "Location must be always allowed.",
        );
      }
    }
    // opens settings only once
    if (!await PermissionRequest.request(Permission.locationAlways)) {
      return false;
    }
    // request permission but continue even if not granted
    await PermissionRequest.request(Permission.notification);
    return true;
  }

  static Future<void> enableGPS() async {
    await setLocationSettings(useGooglePlayServices: false);
    await getLocation();
  }

  Future<bool> startLocationStream({
    required void Function(GpsPosition) onLocationUpdate,
    required bool inBackground,
    // for location tracking in other isolate which can not request permissions
    bool ignorePermissions = false,
  }) async {
    if (_locationSubscription != null) {
      return false;
    }

    if (!ignorePermissions) {
      if (!await requestPermissions()) {
        return false;
      }
    }

    await setLocationSettings(useGooglePlayServices: false);
    await _updateNotification(null);
    _locationSubscription =
        onLocationChanged(inBackground: inBackground).listen((locationData) {
      _onLocationUpdate(
        GpsPosition.fromLocationData(locationData),
        onLocationUpdate,
      );
    });
    notifyListeners();
    return true;
  }

  Future<void> _updateNotification(GpsPosition? position) {
    return updateBackgroundNotification(
      title: "Tracking",
      subtitle: position == null
          ? "GPS tracking is active"
          : "[${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}] ~ ${position.accuracy.round()} m (${position.satellites} satellites)",
      color: Colors.red,
      iconName: "notification_icon",
      onTapBringToFront: true,
    );
  }

  Future<void> _onLocationUpdate(
    GpsPosition position,
    void Function(GpsPosition) onLocationUpdate,
  ) async {
    await _updateNotification(position);
    _lastLocation = position;
    onLocationUpdate(position);
    notifyListeners();
  }

  Future<void> stopLocationStream() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastLocation = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  GpsPosition? get lastLocation => _lastLocation;
  LatLng? get lastLatLng => _lastLocation?.latLng;
  bool get hasLocation => _lastLocation?.latLng != null;
  bool get hasAccurateLocation =>
      hasLocation && (_lastLocation?.isGps ?? false);

  bool get enabled => _locationSubscription != null;
}

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';

class CurrentLocationButton extends StatefulWidget {
  const CurrentLocationButton({
    required this.mapController,
    required this.circleManager,
    required this.centerLocation,
    super.key,
  });

  final MapboxMap mapController;
  final CircleManager circleManager;
  final bool centerLocation;

  @override
  State<CurrentLocationButton> createState() => _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends State<CurrentLocationButton> {
  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();
  late final LocationUtils _locationUtils = LocationUtils(_onLocationUpdate);

  @override
  void dispose() {
    _locationUtils.stopLocationStream();
    if (_locationUtils.lastLatLng != null) {
      Settings.instance.lastGpsLatLng = _locationUtils.lastLatLng!;
    }
    super.dispose();
  }

  Future<void> _toggleCurrentLocation() async {
    if (_locationUtils.enabled) {
      _locationUtils.stopLocationStream();
      await widget.circleManager.updateCurrentLocationMarker(
        _currentLocationMarker,
        null,
      );
    } else {
      await _locationUtils.startLocationStream();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    if (widget.centerLocation) {
      await widget.mapController.animateCenter(location.latLng);
    }
    await widget.circleManager.updateCurrentLocationMarker(
      _currentLocationMarker,
      location.latLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: _toggleCurrentLocation,
      child: Icon(
        _locationUtils.enabled
            ? AppIcons.myLocation
            : AppIcons.myLocationDisabled,
      ),
    );
  }
}

import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/secrets.dart';
import 'package:sport_log/helpers/theme.dart';

enum TrackingMode { tracking, paused, notStarted }

class CardioTrackingPage extends StatefulWidget {
  const CardioTrackingPage({Key? key}) : super(key: key);

  @override
  State<CardioTrackingPage> createState() => CardioTrackingPageState();
}

class CardioTrackingPageState extends State<CardioTrackingPage> {
  final _logger = Logger('CardioTrackingPage');

  final String token = Secrets.mapboxAccessToken;
  final String style = 'mapbox://styles/mapbox/outdoors-v11';

  List<LatLng> locations = [];
  Line? line;
  List<Circle>? circles;

  TrackingMode trackingMode = TrackingMode.notStarted;

  String locationInfo = "";

  late MapboxMapController mapController;

  Future<LatLng?> startLocationStream() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    location.changeSettings(accuracy: LocationAccuracy.high);

    location.enableBackgroundMode(enable: true);
    location.onLocationChanged.listen(
        (LocationData currentLocation) => locationConsumer(currentLocation));
  }

  void init(MapboxMapController controller) async {
    await startLocationStream();
  }

  void locationConsumer(LocationData location) async {
    setState(() {
      locationInfo = """location provider: ${location.provider}
accuracy: ${location.accuracy}
time: ${location.time}""";
    });

    _logger.i(locationInfo);

    LatLng latLng = LatLng(location.latitude, location.longitude);

    await mapController.animateCamera(
      CameraUpdate.newLatLng(latLng),
    );

    if (circles != null) {
      await mapController.removeCircles(circles);
    }
    circles = await mapController.addCircles([
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#0060a0',
        circleOpacity: 0.5,
        geometry: latLng,
        draggable: false,
      ),
      CircleOptions(
        circleRadius: 20.0,
        circleColor: '#0060a0',
        circleOpacity: 0.3,
        geometry: latLng,
        draggable: false,
      ),
    ]);

    if (trackingMode == TrackingMode.tracking) {
      extendLine(mapController, LatLng(location.latitude, location.longitude));
    }
  }

  void markLatLng(MapboxMapController controller, LatLng location) async {
    await controller.addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#008080',
        circleOpacity: 0.5,
        geometry: location,
        draggable: false,
      ),
    );
  }

  void extendLine(MapboxMapController controller, LatLng location) async {
    locations.add(location);
    line ??= await controller.addLine(
        const LineOptions(lineColor: "red", lineWidth: 3, geometry: []));
    await controller.updateLine(line, LineOptions(geometry: locations));
  }

  Widget _buildCard(String title, String subtitle) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(top: 2),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25),
        ),
        subtitle: Text(
          subtitle,
          textAlign: TextAlign.center,
        ),
        dense: true,
      ),
    );
  }

  List<Widget> _buildButtons() {
    if (trackingMode == TrackingMode.tracking) {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () => setState(() {
                      trackingMode = TrackingMode.paused;
                    }),
                child: const Text("pause"))),
        const SizedBox(
          width: 10,
        ),
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () => setState(() {
                      trackingMode = TrackingMode.notStarted;
                    }),
                child: const Text("stop"))),
      ];
    } else if (trackingMode == TrackingMode.paused) {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.green[400]),
                onPressed: () => setState(() {
                      trackingMode = TrackingMode.tracking;
                    }),
                child: const Text("continue"))),
        const SizedBox(
          width: 10,
        ),
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () => setState(() {
                      trackingMode = TrackingMode.notStarted;
                    }),
                child: const Text("stop"))),
      ];
    } else {
      return [
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.green[400]),
                onPressed: () => setState(() {
                      trackingMode = TrackingMode.tracking;
                    }),
                child: const Text("start"))),
        const SizedBox(
          width: 10,
        ),
        Expanded(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red[400]),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("cancel"))),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
          margin: const EdgeInsets.only(top: 25, bottom: 5),
          child: Text(locationInfo)),
      Expanded(
          child: MapboxMap(
        accessToken: token,
        styleString: style,
        initialCameraPosition: const CameraPosition(
          zoom: 13.0,
          target: LatLng(47.27, 11.33),
        ),
        compassEnabled: true,
        compassViewPosition: CompassViewPosition.TopRight,
        onMapCreated: (MapboxMapController controller) =>
            mapController = controller,
        onStyleLoadedCallback: () => init(mapController),
      )),
      Container(
          padding: const EdgeInsets.all(5),
          color: onPrimaryColorOf(context),
          child: Table(
            children: [
              TableRow(children: [
                _buildCard("00:31:15", "time"),
                _buildCard("6.17 km", "distance"),
              ]),
              TableRow(children: [
                _buildCard("10.7 km/h", "speed"),
                _buildCard("163", "step rate"),
              ]),
              TableRow(children: [
                _buildCard("231 m", "ascent"),
                _buildCard("51 m", "descent"),
              ]),
            ],
          )),
      Container(
          color: onPrimaryColorOf(context),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: _buildButtons(),
          ))
    ]);
  }
}

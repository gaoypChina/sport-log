import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:polyline/polyline.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/secrets.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class RouteEditPage extends StatefulWidget {
  final Route? route;

  const RouteEditPage({Key? key, this.route}) : super(key: key);

  @override
  State<RouteEditPage> createState() => RouteEditPageState();
}

class RouteEditPageState extends State<RouteEditPage> {
  final _logger = Logger('RouteEditPage');

  List<LatLng> _locations = [];

  Line? _line;
  List<Circle> _circles = [];
  List<Symbol> _symbols = [];

  bool _listExpanded = false;

  late MapboxMapController _mapController;

  MapboxApi mapbox = MapboxApi(accessToken: Secrets.mapboxAccessToken);

  late Route _route;

  @override
  void initState() {
    super.initState();
    _logger.i("route");
    _logger.i(widget.route);
    _route = widget.route ??
        Route(
            id: randomId(),
            userId: UserState.instance.currentUser!.id,
            name: "",
            distance: 0,
            ascent: 0,
            descent: 0,
            track: [],
            deleted: false);
    _locations =
        _route.track.map((e) => LatLng(e.latitude, e.longitude)).toList();
    // TODO dont map every point to marked location
  }

  void _saveRoute() {
    // TODO save in DB
    Navigator.of(context).pop(ReturnObject(
        action:
            widget.route != null ? ReturnAction.updated : ReturnAction.created,
        payload: _route));
  }

  Future<void> _matchLocations() async {
    DirectionsApiResponse response = await mapbox.directions.request(
      profile: NavigationProfile.WALKING,
      geometries: NavigationGeometries.POLYLINE6,
      coordinates: _locations.map((e) => [e.latitude, e.longitude]).toList(),
    );
    if (response.error != null) {
      if (response.error is NavigationNoRouteError) {
        _logger.i(response.error);
      } else if (response.error is NavigationNoSegmentError) {
        _logger.i(response.error);
      }
    } else if (response.routes != null && response.routes!.isNotEmpty) {
      NavigationRoute navRoute = response.routes![0];
      setState(() {
        _route.distance = navRoute.distance!.round();
      });

      _route.track = Polyline.Decode(
        encodedString: navRoute.geometry as String,
        precision: 6,
      )
          .decodedCoords
          .map(
            (coordinate) => Position(
                latitude: coordinate[0],
                longitude: coordinate[1],
                elevation: 0, // TODO
                distance: 0, // TODO
                time: 0), // TODO
          )
          .toList();
    }
  }

  Future<void> _updateLine() async {
    await _matchLocations();
    await _mapController.updateLine(_line!,
        LineOptions(geometry: _route.track.map((e) => e.latLng).toList()));
  }

  void _addPoint(LatLng latLng, int number) async {
    _symbols.add(await _mapController.addSymbol(SymbolOptions(
        textField: "$number",
        textOffset: const Offset(0, 1),
        geometry: latLng)));
    _circles.add(await _mapController.addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: '#0060a0',
        circleOpacity: 0.5,
        geometry: latLng,
        draggable: false,
      ),
    ));
  }

  Future<void> _updatePoints() async {
    await _mapController.removeCircles(_circles);
    _circles = [];
    await _mapController.removeSymbols(_symbols);
    _symbols = [];
    _locations.asMap().forEach((index, latLng) {
      _addPoint(latLng, index + 1);
    });
  }

  void _extendLine(LatLng location) async {
    if (_locations.length == 25) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Point maximum reached"),
          content: const Text("You can only set 25 points."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"))
          ],
        ),
      );
      return;
    }
    setState(() {
      _locations.add(location);
    });
    _addPoint(location, _locations.length);
    await _updateLine();
  }

  void _removePoint(int index) async {
    setState(() {
      _locations.removeAt(index);
    });
    await _updatePoints();
    await _updateLine();
  }

  void _switchPoints(int oldIndex, int newIndex) async {
    setState(() {
      _logger.i("old: $oldIndex, new: $newIndex");
      if (oldIndex < newIndex - 1) {
        LatLng location = _locations.removeAt(oldIndex);
        if (newIndex - 1 == _locations.length) {
          _locations.add(location);
        } else {
          _locations.insert(newIndex - 1, location);
        }
      } else if (oldIndex > newIndex) {
        _locations.insert(newIndex, _locations.removeAt(oldIndex));
      }
    });

    await _updatePoints();
    await _updateLine();
  }

  Widget _buildDraggableList() {
    List<Widget> listElements = [];

    Widget _buildDragTarget(int index) {
      return DragTarget(
          onWillAccept: (value) => true,
          onAccept: (value) => _switchPoints(value as int, index),
          builder: (context, candidates, reject) {
            if (candidates.isNotEmpty) {
              int index = candidates[0] as int;
              return ListTile(
                leading: Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: const Icon(
                    Icons.add_rounded,
                  ),
                ),
                title: Text(
                  "${index + 1}",
                  style: const TextStyle(fontSize: 20),
                ),
                dense: true,
              );
            } else {
              return const Divider();
            }
          });
    }

    for (int index = 0; index < _locations.length; index++) {
      listElements.add(_buildDragTarget(index));

      var icon = const Icon(
        Icons.drag_handle,
      );
      Text title = Text(
        "${index + 1}",
        style: const TextStyle(fontSize: 20),
      );
      listElements.add(ListTile(
        leading: IconButton(
            onPressed: () => _removePoint(index),
            icon: const Icon(Icons.delete_rounded)),
        trailing: Draggable(
          axis: Axis.vertical,
          data: index,
          child: icon,
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: icon,
          ),
          feedback: icon,
        ),
        title: title,
        dense: true,
      ));
    }

    listElements.add(_buildDragTarget(_locations.length));

    return ListView(children: listElements);
  }

  Widget _buildExpandableListContainer() {
    if (_listExpanded) {
      return Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          height: 350,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _listExpanded = false;
                  }),
                  child: const Text("hide List"),
                ),
              ),
              Expanded(
                child: _buildDraggableList(),
              ),
            ],
          ));
    } else {
      return Container(
        width: double.infinity,
        color: onPrimaryColorOf(context),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: ElevatedButton(
          onPressed: () => setState(() {
            _listExpanded = true;
          }),
          child: const Text("show List"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TableRow rowSpacer = TableRow(children: [
      Defaults.sizedBox.vertical.normal,
      Defaults.sizedBox.vertical.normal,
    ]);

    return Scaffold(
        appBar: AppBar(
          title: const Text("Cardio Edit"),
          actions: [
            IconButton(
                onPressed: _route.name.isNotEmpty ? () => _saveRoute() : null,
                icon: const Icon(Icons.save))
          ],
        ),
        body: Container(
            color: backgroundColorOf(context),
            child: Column(children: [
              Expanded(
                  child: MapboxMap(
                accessToken: Secrets.mapboxAccessToken,
                styleString: Defaults.mapbox.style.outdoor,
                initialCameraPosition: const CameraPosition(
                  zoom: 13.0,
                  target: LatLng(47.27, 11.33),
                ),
                compassEnabled: true,
                compassViewPosition: CompassViewPosition.TopRight,
                onMapCreated: (MapboxMapController controller) async {
                  _mapController = controller;
                  _line ??= await _mapController.addLine(const LineOptions(
                      lineColor: "red", lineWidth: 3, geometry: []));
                  _updatePoints();
                  _updateLine();
                },
                onMapLongClick: (point, LatLng latLng) => _extendLine(latLng),
              )),
              _buildExpandableListContainer(),
              Table(
                children: [
                  TableRow(children: [
                    ValueUnitDescription(
                      value: (_route.distance / 1000).toString(),
                      unit: "km",
                      description: "distance",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value: _route.name,
                      unit: null,
                      description: "Name",
                      scale: 1.3,
                    )
                  ]),
                  rowSpacer,
                  TableRow(children: [
                    ValueUnitDescription(
                      value: 231.toString(),
                      unit: "m",
                      description: "ascent",
                      scale: 1.3,
                    ),
                    ValueUnitDescription(
                      value: 51.toString(),
                      unit: "m",
                      description: "descent",
                      scale: 1.3,
                    ),
                  ]),
                ],
              ),
              Defaults.sizedBox.vertical.normal,
              Row(
                children: [
                  Defaults.sizedBox.horizontal.normal,
                  Expanded(
                      child: TextFormField(
                    onTap: () => setState(() {
                      _listExpanded = false;
                    }),
                    onFieldSubmitted: (name) => setState(() {
                      _route.name = name;
                    }),
                    style: const TextStyle(height: 1),
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(
                          borderRadius: Defaults.borderRadius.big),
                      contentPadding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                  )),
                  Defaults.sizedBox.horizontal.normal,
                ],
              ),
              Defaults.sizedBox.vertical.normal,
            ])));
  }
}

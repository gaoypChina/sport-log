import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/snackbar.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapController? _mapController;
  final _searchBar = FocusNode();
  final _placesSearch =
      PlacesSearch(apiKey: Config.instance.accessToken, limit: 10);

  String? _search;
  List<MapBoxPlace> _searchResults = [];

  Future<void> _searchPlaces(String name) async {
    setState(() => _search = name);
    List<MapBoxPlace>? places;
    try {
      places = await _placesSearch.getPlaces(_search!);
    } on SocketException {
      showNoInternetToast(context);
    }
    if (mounted) {
      setState(() => _searchResults = places ?? []);
    }
  }

  void _toggleSearch() {
    setState(() {
      _search = _search == null ? "" : null;
      if (_search == null) {
        _searchResults = [];
      }
    });
    if (_search != null) {
      _searchBar.requestFocus();
    }
  }

  Future<void> _goToSearchItem(int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final item = _searchResults[index];
    setState(() => _searchResults = []);

    final coords = item.center!;
    await _mapController?.animateCenter(LatLng(lat: coords[1], lng: coords[0]));

    final bbox = item.bbox;
    if (bbox != null) {
      await _mapController?.setBoundsX(
        [LatLng(lat: bbox[1], lng: bbox[0]), LatLng(lat: bbox[3], lng: bbox[2])]
            .latLngBounds!,
        padded: false,
      );
    } else {
      await _mapController?.setZoom(16);
    }
  }

  static const _searchBackgroundColor = Color.fromARGB(150, 255, 255, 255);

  Future<void> _onDrawerChanged(bool open) async {
    if (open) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );
    } else {
      await _setOrientation();
    }
  }

  Future<void> _setOrientation() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _setOrientation();

    return NeverPop(
      child: ProviderConsumer(
        create: (_) => BoolToggle.on(),
        builder: (context, showOverlays, _) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: showOverlays.isOn
              ? AppBar(
                  title: _search == null
                      ? null
                      : TextFormField(
                          focusNode: _searchBar,
                          onChanged: _searchPlaces,
                          onTap: () => _searchPlaces(_search ?? ""),
                          decoration: Theme.of(context).textFormFieldDecoration,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(color: Colors.black),
                        ),
                  actions: [
                    IconButton(
                      onPressed: _toggleSearch,
                      icon: Icon(
                        _search != null ? AppIcons.close : AppIcons.search,
                      ),
                    ),
                  ],
                  foregroundColor: Theme.of(context).colorScheme.background,
                  backgroundColor: _searchBackgroundColor,
                  elevation: 0,
                )
              : null,
          drawer: const MainDrawer(selectedRoute: Routes.map),
          onDrawerChanged: _onDrawerChanged,
          body: Stack(
            alignment: Alignment.center,
            children: [
              MapboxMapWrapper(
                showFullscreenButton: false,
                showMapStylesButton: true,
                showSelectRouteButton: true,
                showSetNorthButton: true,
                showCurrentLocationButton: true,
                showCenterLocationButton: true,
                showOverlays: showOverlays.isOn,
                buttonTopOffset: 100,
                onMapCreated: (controller) => _mapController = controller,
                onTap: (_) => showOverlays.toggle(),
              ),
              if (showOverlays.isOn && _searchResults.isNotEmpty)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: MapSearchResults(
                      searchResults: _searchResults,
                      backgroundColor: _searchBackgroundColor,
                      onItemTap: _goToSearchItem,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapSearchResults extends StatelessWidget {
  const MapSearchResults({
    required this.searchResults,
    required this.backgroundColor,
    required this.onItemTap,
    super.key,
  });

  final List<MapBoxPlace> searchResults;
  final Color backgroundColor;
  final void Function(int) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Defaults.edgeInsets.normal,
      color: backgroundColor,
      constraints: const BoxConstraints(maxHeight: 200),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => onItemTap(index),
              child: Text(
                searchResults[index].toString(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Colors.black),
              ),
            ),
            itemCount: searchResults.length,
            separatorBuilder: (context, index) => const Divider(),
            shrinkWrap: true,
          ),
        ),
      ),
    );
  }
}

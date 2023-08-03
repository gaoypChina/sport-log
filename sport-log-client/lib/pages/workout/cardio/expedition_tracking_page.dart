import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/expedition_tracking_utils.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class CardioExpeditionTrackingPage extends StatelessWidget {
  const CardioExpeditionTrackingPage.crate({
    required TrackingSettings this.trackingSettings,
    super.key,
  }) : cardioSessionDescription = null;

  const CardioExpeditionTrackingPage.attach({
    required CardioSessionDescription this.cardioSessionDescription,
    super.key,
  }) : trackingSettings = null;

  final TrackingSettings? trackingSettings;
  final CardioSessionDescription? cardioSessionDescription;

  @override
  Widget build(BuildContext context) {
    return ProviderConsumer(
      create: (_) => trackingSettings != null
          ? ExpeditionTrackingUtils.create(
              trackingSettings: trackingSettings!,
            )
          : ExpeditionTrackingUtils.attach(cardioSessionDescription!),
      builder: (context, trackingUtils, _) => SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: ProviderConsumer(
            create: (_) => BoolToggle.off(),
            builder: (context, fullscreen, _) => Column(
              children: [
                Expanded(
                  child: MapboxMapWrapper(
                    showFullscreenButton: true,
                    showMapStylesButton: true,
                    showSelectRouteButton: true,
                    showSetNorthButton: true,
                    showCurrentLocationButton: true,
                    showCenterLocationButton: true,
                    onFullscreenToggle: fullscreen.setState,
                    initialCameraPosition: LatLngZoom(
                      latLng: context.read<Settings>().lastGpsLatLng,
                      zoom: 15,
                    ),
                    onMapCreated: trackingUtils.onMapCreated,
                  ),
                ),
                if (!fullscreen.isOn)
                  Padding(
                    padding: Defaults.edgeInsets.normal,
                    child: Column(
                      children: [
                        CardioValueUnitDescriptionTable(
                          cardioSessionDescription:
                              trackingUtils.cardioSessionDescription,
                          currentDuration: DateTime.now().difference(
                            trackingUtils.cardioSessionDescription.cardioSession
                                .datetime,
                          ),
                          expeditionMode: true,
                        ),
                        Defaults.sizedBox.vertical.small,
                        _TrackingPageButtons(
                          created: ExpeditionTrackingUtils.created,
                          running: trackingUtils.running,
                          onStart: trackingUtils.start,
                          onResume: trackingUtils.resume,
                          onStop: () => trackingUtils.stop(context),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackingPageButtons extends StatelessWidget {
  const _TrackingPageButtons({
    required this.created,
    required this.running,
    required this.onStart,
    required this.onResume,
    required this.onStop,
  });

  final bool created;
  final bool running;
  final VoidCallback onStart;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return running
        ? ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity),
            child: FilledButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: onStop,
              child: const Text("Stop"),
            ),
          )
        : created
            ? Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.errorContainer,
                      ),
                      onPressed: onResume,
                      child: const Text("Resume"),
                    ),
                  ),
                  Defaults.sizedBox.horizontal.normal,
                  Expanded(
                    child: FilledButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: onStop,
                      child: const Text("Stop"),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.errorContainer,
                      ),
                      onPressed: onStart,
                      child: const Text("Start"),
                    ),
                  ),
                  Defaults.sizedBox.horizontal.normal,
                  Expanded(
                    child: FilledButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                ],
              );
  }
}

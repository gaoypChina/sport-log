import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/overview_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';
import 'package:sport_log/pages/workout/comments_box.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_description_card.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_results_card.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/sync_refresh_indicator.dart';

class MetconSessionsPage extends StatelessWidget {
  MetconSessionsPage({super.key});

  final _searchBar = FocusNode();

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<
          OverviewDataProvider<MetconSessionDescription, MetconRecords,
              MetconSessionDescriptionDataProvider, Metcon>>(
        create: (_) => OverviewDataProvider(
          dataProvider: MetconSessionDescriptionDataProvider(),
          entityAccessor: (dataProvider) => (start, end, metcon, search) =>
              dataProvider.getByTimerangeAndMetconAndComment(
                from: start,
                until: end,
                metcon: metcon,
                comment: search,
              ),
          recordAccessor: (dataProvider) =>
              () => dataProvider.getMetconRecords(),
          loggerName: "MetconSessionsPage",
        )..init(),
        builder: (_, dataProvider, __) => Scaffold(
          appBar: AppBar(
            title: dataProvider.isSearch
                ? TextFormField(
                    focusNode: _searchBar,
                    onChanged: (comment) => dataProvider.search = comment,
                    decoration: Theme.of(context).textFormFieldDecoration,
                  )
                : Text(dataProvider.selected?.name ?? "Metcon Sessions"),
            actions: [
              IconButton(
                onPressed: () {
                  dataProvider.search = dataProvider.isSearch ? null : "";
                  if (dataProvider.isSearch) {
                    _searchBar.requestFocus();
                  }
                },
                icon: Icon(
                  dataProvider.isSearch ? AppIcons.close : AppIcons.search,
                ),
              ),
              IconButton(
                // ignore: prefer-extracting-callbacks
                onPressed: () async {
                  final metcon = await showMetconPicker(
                    context: context,
                    selectedMetcon: dataProvider.selected,
                  );
                  if (metcon == null) {
                    return;
                  } else if (metcon.id == dataProvider.selected?.id) {
                    dataProvider.selected = null;
                  } else {
                    dataProvider.selected = metcon;
                  }
                },
                icon: Icon(
                  dataProvider.selected != null
                      ? AppIcons.filterFilled
                      : AppIcons.filter,
                ),
              ),
              IconButton(
                onPressed: () =>
                    Navigator.of(context).newBase(Routes.metconOverview),
                icon: const Icon(AppIcons.notes),
              ),
            ],
            bottom: DateFilter(
              initialState: dataProvider.dateFilter,
              onFilterChanged: (dateFilter) =>
                  dataProvider.dateFilter = dateFilter,
            ),
          ),
          body: Stack(
            alignment: Alignment.topCenter,
            children: [
              SyncRefreshIndicator(
                child: dataProvider.entities.isEmpty
                    ? SessionsPageTab.metcon.noEntriesText
                    : Container(
                        padding: Defaults.edgeInsets.normal,
                        child: dataProvider.selected != null &&
                                dataProvider.entities.isNotEmpty
                            ? ListView.separated(
                                itemBuilder: (_, index) {
                                  if (index == 0) {
                                    return MetconDescriptionCard(
                                      metconDescription: dataProvider
                                          .entities.first.metconDescription,
                                    );
                                  } else if (index == 1) {
                                    return MetconSessionResultsCard(
                                      metconSessionDescription: null,
                                      metconSessionDescriptions:
                                          dataProvider.entities,
                                      metconRecords: dataProvider.records ?? {},
                                    );
                                  } else {
                                    return MetconSessionCard(
                                      metconSessionDescription:
                                          dataProvider.entities[index - 2],
                                      metconRecords: dataProvider.records ?? {},
                                    );
                                  }
                                },
                                separatorBuilder: (_, __) =>
                                    Defaults.sizedBox.vertical.normal,
                                itemCount: dataProvider.entities.length + 2,
                              )
                            : ListView.separated(
                                itemBuilder: (_, index) => MetconSessionCard(
                                  metconSessionDescription:
                                      dataProvider.entities[index],
                                  metconRecords: dataProvider.records ?? {},
                                ),
                                separatorBuilder: (_, __) =>
                                    Defaults.sizedBox.vertical.normal,
                                itemCount: dataProvider.entities.length,
                              ),
                      ),
              ),
              if (dataProvider.isLoading)
                const Positioned(
                  top: 40,
                  child: RefreshProgressIndicator(),
                ),
            ],
          ),
          bottomNavigationBar: SessionsPageTab.bottomNavigationBar(
            context: context,
            sessionsPageTab: SessionsPageTab.metcon,
          ),
          drawer: const MainDrawer(selectedRoute: Routes.metconOverview),
          floatingActionButton: FloatingActionButton(
            child: const Icon(AppIcons.add),
            onPressed: () {
              Navigator.pushNamed(context, Routes.metconSessionEdit);
            },
          ),
        ),
      ),
    );
  }
}

class MetconSessionCard extends StatelessWidget {
  MetconSessionCard({
    required this.metconSessionDescription,
    required MetconRecords metconRecords,
    super.key,
  }) : metconRecord = metconRecords.isMetconRecord(metconSessionDescription);

  final MetconSessionDescription metconSessionDescription;
  final bool metconRecord;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.metconSessionDetails,
          arguments: metconSessionDescription,
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metconSessionDescription.metconSession.datetime
                              .toHumanDateTime(),
                        ),
                        Defaults.sizedBox.vertical.normal,
                        Text(
                          metconSessionDescription
                              .metconDescription.metcon.name,
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                        if (metconRecord) ...[
                          Defaults.sizedBox.vertical.normal,
                          const Icon(
                            AppIcons.medal,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(metconSessionDescription.longResultDescription),
                        Defaults.sizedBox.vertical.normal,
                        Row(
                          children: [
                            const Text("Rx "),
                            Icon(
                              metconSessionDescription.metconSession.rx
                                  ? AppIcons.check
                                  : AppIcons.close,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (metconSessionDescription.metconSession.comments != null) ...[
                const Divider(),
                CommentsBox(
                  comments: metconSessionDescription.metconSession.comments!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/metcon/metcons_page.dart';
import 'package:sport_log/pages/workout/strength/overview_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

import 'date_filter/date_filter_state.dart';
import 'date_filter/date_filter_widget.dart';

enum BottomNavPage { strength, metcon, cardio, diary }

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  BottomNavPage _currentPage = BottomNavPage.strength;
  DateFilterState _dateFilter = MonthFilter.current();

  Movement? _selectedMovement;

  final _movementDataProvider = MovementDataProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedMovement?.name ?? 'Sessions'),
        actions: [
          IconButton(
            onPressed: () async {
              showDialog<void>(
                  context: context, builder: _movementPickerBuilder);
            },
            icon: Icon(_selectedMovement != null
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
          ),
        ],
        bottom: _filter,
      ),
      body: WideScreenFrame(child: _mainPage),
      bottomNavigationBar: BottomNavigationBar(
        items: BottomNavPage.values.map(_toBottomNavItem).toList(),
        currentIndex: _currentPage.index,
        onTap: _onBottomNavItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      drawer: const MainDrawer(selectedRoute: Routes.workout),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _onFabTapped(context),
      ),
    );
  }

  Widget get _mainPage {
    // TODO: preserve state and/or widget when changing tab
    switch (_currentPage) {
      case BottomNavPage.metcon:
        return const MetconsPage();
      case BottomNavPage.strength:
        return StrengthSessionsPage(
          dateFilter: _dateFilter,
          movement: _selectedMovement,
        );
      case BottomNavPage.cardio:
        return const Center(
          child: Text("Cardio"),
        );
      case BottomNavPage.diary:
        return const Center(
          child: Text("Weight and Comments"),
        );
    }
  }

  BottomNavigationBarItem _toBottomNavItem(BottomNavPage page) {
    switch (page) {
      case BottomNavPage.metcon:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.plan),
          label: "Metcons",
        );
      case BottomNavPage.strength:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.dumbbellNotRotated),
          label: "Strength",
        );
      case BottomNavPage.cardio:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.heart),
          label: "Cardio",
        );
      case BottomNavPage.diary:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: "Other",
        );
    }
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentPage = BottomNavPage.values[index];
    });
  }

  void _onFabTapped(BuildContext context) {
    switch (_currentPage) {
      case BottomNavPage.metcon:
        Navigator.of(context).pushNamed(Routes.editMetcon);
        break;
      case BottomNavPage.strength:
        Navigator.of(context).pushNamed(Routes.editStrengthSession);
        break;
      default:
    }
  }

  PreferredSizeWidget get _filter {
    return PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: DateFilter(
          initialState: _dateFilter,
          onFilterChanged: (newFilter) =>
              setState(() => _dateFilter = newFilter),
        ));
  }

  Widget _movementPickerBuilder(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 0,
        child: FutureBuilder<List<Movement>>(
          future: _movementDataProvider.getStrengthSessionMovements(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Nothing here. Create a movement first.'));
              }
              return Scrollbar(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final movement = snapshot.data![index];
                    final selected = _selectedMovement != null &&
                        _selectedMovement!.id == movement.id;
                    return ListTile(
                        title: Center(child: Text(movement.name)),
                        subtitle: Center(child: Text(movement.unit.toDimensionName())),
                        selected: selected,
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedMovement = null;
                            } else {
                              _selectedMovement = movement;
                            }
                            Navigator.of(context).pop();
                          });
                        });
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: snapshot.data!.length,
                ),
              );
            } else if (snapshot.hasError) {
              Future(() =>
                  showSimpleSnackBar(context, 'Failed to select movements.'));
              return const Center(child: Text('Nothing here'));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

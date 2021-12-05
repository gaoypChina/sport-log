import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/cardio/overview_page.dart';
import 'package:sport_log/pages/workout/diary/overview_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/movement_picker.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

import 'strength_sessions/overview_page.dart';
import 'date_filter/date_filter_widget.dart';
import 'metcon_sessions/overview_page.dart';
import 'ui_cubit.dart';

class WorkoutPage extends StatelessWidget {
  WorkoutPage({Key? key}) : super(key: key);

  final GlobalKey<StrengthSessionsPageState> _strengthKey = GlobalKey();
  final GlobalKey<MetconSessionsPageState> _metconKey = GlobalKey();
  final GlobalKey<CardioSessionsPageState> _cardioKey = GlobalKey();
  final GlobalKey<DiaryPageState> _diaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SessionsUiCubit(),
      child: BlocBuilder<SessionsUiCubit, SessionsUiState>(
        buildWhen: (oldState, newState) =>
            oldState.dateFilter != newState.dateFilter ||
            oldState.movement != newState.movement ||
            oldState.tab != newState.tab ||
            oldState.shouldShowFab != newState.shouldShowFab,
        builder: (context, state) {
          final cubit = context.read<SessionsUiCubit>();
          return Scaffold(
            appBar: AppBar(
              title: Text(state.titleText),
              actions: [
                IconButton(
                  onPressed: () =>
                      _onMovementSelection(context, state.movement, cubit),
                  icon: Icon(state.isMovementSelected
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: DateFilter(
                  initialState: state.dateFilter,
                  onFilterChanged: cubit.setDateFilter,
                ),
              ),
            ),
            body: WideScreenFrame(child: _mainPage(state)),
            bottomNavigationBar: BottomNavigationBar(
              items: SessionsPageTab.values.map(_toBottomNavItem).toList(),
              currentIndex: state.tab.index,
              onTap: _onBottomNavItemTapped(cubit),
              type: BottomNavigationBarType.fixed,
            ),
            drawer: const MainDrawer(selectedRoute: Routes.workout),
            floatingActionButton: _fab(state, context),
          );
        },
      ),
    );
  }

  void _onMovementSelection(BuildContext context, Movement? oldMovement,
      SessionsUiCubit cubit) async {
    final Movement? movement =
        await showMovementPickerDialog(context, selectedMovement: oldMovement);
    if (movement == null) {
      return;
    }
    if (movement.id == oldMovement?.id) {
      cubit.removeMovement();
    } else {
      cubit.setMovement(movement);
    }
  }

  Widget _mainPage(SessionsUiState state) {
    // TODO: preserve state and/or widget when changing tab
    switch (state.tab) {
      case SessionsPageTab.strength:
        return StrengthSessionsPage(key: _strengthKey);
      case SessionsPageTab.metcon:
        return MetconSessionsPage(key: _metconKey);
      case SessionsPageTab.cardio:
        return CardioSessionsPage(key: _cardioKey);
      case SessionsPageTab.diary:
        return DiaryPage(key: _diaryKey);
    }
  }

  BottomNavigationBarItem _toBottomNavItem(SessionsPageTab page) {
    switch (page) {
      case SessionsPageTab.metcon:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.plan),
          label: "Metcons",
        );
      case SessionsPageTab.strength:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.dumbbellNotRotated),
          label: "Strength",
        );
      case SessionsPageTab.cardio:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.heartbeat),
          label: "Cardio",
        );
      case SessionsPageTab.diary:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Diary",
        );
    }
  }

  void Function(int) _onBottomNavItemTapped(SessionsUiCubit cubit) {
    return (index) => cubit.setTab(SessionsPageTab.values[index]);
  }

  Widget? _fab(SessionsUiState state, BuildContext context) {
    Logger _logger = Logger('Fab Function');
    _logger.i("fab called");

    switch (state.tab) {
      case SessionsPageTab.strength:
        return _strengthKey.currentState?.fab(context);
      case SessionsPageTab.metcon:
        return _metconKey.currentState?.fab(context);
      case SessionsPageTab.cardio:
        return _cardioKey.currentState?.fab(context);
      case SessionsPageTab.diary:
        return _diaryKey.currentState?.fab(context);
    }
  }
}

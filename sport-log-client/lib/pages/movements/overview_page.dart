import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/state/local_state.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/approve_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MovementsPage extends StatefulWidget {
  const MovementsPage({Key? key}) : super(key: key);

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  final _dataProvider = MovementDataProvider();
  LocalState<MovementDescription> _state = LocalState.empty();

  @override
  void initState() {
    super.initState();
    _dataProvider.getNonDeletedFull().then((mds) {
      setState(() {
        _state = LocalState.fromList(mds);
      });
    });
  }

  void _handlePageReturn(dynamic object) {
    if (object is ReturnObject<MovementDescription>) {
      switch (object.action) {
        case ReturnAction.created:
          setState(() => _state.create(object.object));
          break;
        case ReturnAction.updated:
          setState(() => _state.update(object.object));
          break;
        case ReturnAction.deleted:
          setState(() => _state.delete(object.object.id));
      }
    }
  }

  Future<void> _refreshPage() async {
    await _dataProvider.doFullUpdate().onError((error, stackTrace) {
      if (error is ApiError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toErrorMessage())));
      }
    });
    _dataProvider.getNonDeletedFull().then((mds) {
      setState(() => _state = LocalState.fromList(mds));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Movements"),
      ),
      drawer: const MainDrawer(selectedRoute: Routes.movements),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: _body(context),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.of(context)
                .pushNamed(Routes.editMovement)
                .then(_handlePageReturn);
          }),
    );
  }

  Widget _body(BuildContext context) {
    if (_state.isEmpty) {
      return const Center(child: Text("No movements there."));
    }
    return ImplicitlyAnimatedList(
      items: _state.sortedBy(_compareFunction),
      itemBuilder: _movementToWidget,
      areItemsTheSame: MovementDescription.areTheSame,
    );
  }

  Widget _movementToWidget(
    BuildContext context,
    Animation<double> animation,
    MovementDescription md,
    int index,
  ) {
    final movement = md.movement;
    return SizeFadeTransition(
      key: ValueKey(movement.id),
      animation: animation,
      child: ExpansionTileCard(
          leading: CircleAvatar(child: Text(movement.name[0])),
          title: Text(movement.name),
          subtitle: Text(movement.unit.toDimensionName()),
          children: [
            if (movement.description != null) const Divider(),
            if (movement.description != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(movement.description!),
              ),
            if (movement.userId != null) const Divider(),
            if (movement.userId != null)
              ButtonBar(
                alignment: MainAxisAlignment.spaceAround,
                children: [
                  if (!md.hasReference)
                    IconButton(
                      onPressed: () {
                        assert(movement.userId != null && !md.hasReference);
                        _dataProvider.deleteSingle(movement);
                        setState(() => _state.delete(md.id));
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  IconButton(
                    onPressed: () async {
                      assert(movement.userId != null);
                      if (md.hasReference) {
                        final bool? approved = await showApproveDialog(
                            context,
                            'Warning',
                            'Changes will be reflected in existing workouts.');
                        if (approved == null || !approved) return;
                      }
                      Navigator.of(context)
                          .pushNamed(
                            Routes.editMovement,
                            arguments: md.copy(),
                          )
                          .then(_handlePageReturn);
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
          ]),
    );
  }

  int _compareFunction(MovementDescription m1, MovementDescription m2) {
    if (m1.movement.userId != null) {
      if (m2.movement.userId != null) {
        return m1.movement.name.compareTo(m2.movement.name);
      } else {
        return -1;
      }
    } else {
      if (m2.movement.userId != null) {
        return 1;
      } else {
        return m1.movement.name.compareTo(m2.movement.name);
      }
    }
  }
}

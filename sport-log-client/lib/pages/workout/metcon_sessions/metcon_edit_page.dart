import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_movement_card.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/int_picker.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';
import 'package:sport_log/widgets/message_dialog.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

class EditMetconPage extends StatefulWidget {
  const EditMetconPage({
    Key? key,
    this.metconDescription,
  }) : super(key: key);

  final MetconDescription? metconDescription;

  @override
  State<StatefulWidget> createState() => _EditMetconPageState();
}

class _EditMetconPageState extends State<EditMetconPage> {
  final _logger = Logger('EditMetconPage');
  final _formKey = GlobalKey<FormState>();
  late final MetconDescription _metconDescription;
  final _descriptionFocusNode = FocusNode();
  final _dataProvider = MetconDescriptionDataProvider.instance;

  @override
  void initState() {
    _logger.i("got ${widget.metconDescription}");
    super.initState();
    _metconDescription =
        widget.metconDescription ?? MetconDescription.defaultValue();
  }

  Future<void> _saveMetcon() async {
    if (_metconDescription.metcon.description == "") {
      setState(() => _metconDescription.metcon.description = null);
    }
    final result = widget.metconDescription != null
        ? await _dataProvider.updateSingle(_metconDescription)
        : await _dataProvider.createSingle(_metconDescription);
    if (result) {
      _formKey.currentState!.deactivate();
      Navigator.pop(
        context,
        ReturnObject(
          action: widget.metconDescription != null
              ? ReturnAction.updated
              : ReturnAction.created,
          payload: _metconDescription,
        ), // needed for return to details page
      );
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Metcon failed.',
      );
    }
  }

  Future<void> _deleteMetcon() async {
    if (widget.metconDescription != null) {
      await _dataProvider.deleteSingle(_metconDescription);
    }
    Navigator.pop(
      context,
      ReturnObject(action: ReturnAction.deleted, payload: _metconDescription),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.metconDescription != null ? "Edit Metcon" : "New Metcon",
          ),
          actions: [
            IconButton(
              onPressed: _metconDescription.hasReference ? null : _deleteMetcon,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _metconDescription.isValid()
                  ? _saveMetcon
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: WideScreenFrame(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _nameInput(context),
                  _maybeDescriptionInput(context),
                  _typeInput(context),
                  _additionalFieldsInput(context),
                  const Divider(thickness: 2),
                  _metconMovementsList(context),
                  _addMetconMovementButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameInput(BuildContext context) {
    return TextFormField(
      initialValue: _metconDescription.metcon.name ?? "",
      onChanged: (name) =>
          setState(() => _metconDescription.metcon.name = name),
      validator: Validator.validateStringNotEmpty,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Theme.of(context).textTheme.headline6,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: "Name",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
    );
  }

  Widget _typeInput(BuildContext context) {
    final style = Theme.of(context).textTheme.button!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MetconType.values.map((type) {
        return TextButton(
          onPressed: () => _setType(type),
          child: Text(
            type.displayName,
            style: style.copyWith(
              color: (type == _metconDescription.metcon.metconType)
                  ? primaryColorOf(context)
                  : Theme.of(context).disabledColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _setType(MetconType type) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _metconDescription.metcon.metconType = type;
      switch (type) {
        case MetconType.amrap:
          _metconDescription.metcon.rounds = null;
          _metconDescription.metcon.timecap ??= Metcon.timecapDefaultValue;
          break;
        case MetconType.emom:
          _metconDescription.metcon.rounds ??= Metcon.roundsDefaultValue;
          _metconDescription.metcon.timecap ??= Metcon.timecapDefaultValue;
          break;
        case MetconType.forTime:
          _metconDescription.metcon.rounds ??= Metcon.roundsDefaultValue;
          // timecap can be either null or non null
          break;
      }
    });
  }

  Widget _additionalFieldsInput(BuildContext context) {
    switch (_metconDescription.metcon.metconType) {
      case MetconType.amrap:
        return _amrapInputs(context);
      case MetconType.emom:
        return _emomInputs(context);
      case MetconType.forTime:
        return _forTimeInputs(context);
    }
  }

  Widget _amrapInputs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _timecapInput(context),
        Text(
          plural(
                "min",
                "mins",
                _metconDescription.metcon.timecap?.inMinutes ?? 0,
              ) +
              " in total",
        ),
      ],
    );
  }

  Widget _emomInputs(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roundsInput(context),
            Text(
              plural(
                "round",
                "rounds",
                _metconDescription.metcon.rounds ?? 0,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("in"),
            _timecapInput(context),
            Text(
              plural(
                "min",
                "mins",
                _metconDescription.metcon.timecap?.inMinutes ?? 0,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _forTimeInputs(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roundsInput(context),
            Text(
              plural(
                "round",
                "rounds",
                _metconDescription.metcon.rounds ?? 0,
              ),
            ),
          ],
        ),
        _maybeTimecapInput(context),
      ],
    );
  }

  Widget _descriptionInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        initialValue: _metconDescription.metcon.description ?? "",
        focusNode: _descriptionFocusNode,
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: null,
        onChanged: (description) =>
            setState(() => _metconDescription.metcon.description = description),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          labelText: "Description",
          suffixIcon: IconButton(
            icon: const Icon(AppIcons.cancel),
            onPressed: () =>
                setState(() => _metconDescription.metcon.description = null),
          ),
        ),
      ),
    );
  }

  Widget _maybeDescriptionInput(BuildContext context) {
    if (_metconDescription.metcon.description == null) {
      return OutlinedButton.icon(
        onPressed: () {
          setState(() => _metconDescription.metcon.description = "");
          _descriptionFocusNode.requestFocus();
        },
        icon: const Icon(AppIcons.add),
        label: const Text("Add description..."),
      );
    } else {
      return _descriptionInput(context);
    }
  }

  Widget _roundsInput(BuildContext context) {
    return IntPicker(
      initialValue:
          _metconDescription.metcon.rounds ?? Metcon.roundsDefaultValue,
      setValue: (rounds) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _metconDescription.metcon.rounds = rounds);
      },
    );
  }

  Widget _timecapInput(BuildContext context) {
    return IntPicker(
      initialValue: (_metconDescription.metcon.timecap ??=
              Metcon.timecapDefaultValue)
          .inMinutes,
      setValue: (int timecap) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(
          () => _metconDescription.metcon.timecap = Duration(seconds: timecap),
        );
      },
    );
  }

  Widget _maybeTimecapInput(BuildContext context) {
    if (_metconDescription.metcon.timecap == null) {
      return OutlinedButton.icon(
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(
            () =>
                _metconDescription.metcon.timecap = Metcon.timecapDefaultValue,
          );
        },
        icon: const Icon(AppIcons.add),
        label: const Text("Add timecap..."),
      );
    } else {
      // _metcon.timecap != null
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("in"),
              _timecapInput(context),
              Text(
                plural(
                  "min",
                  "mins",
                  _metconDescription.metcon.timecap!.inMinutes,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(AppIcons.cancel),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _metconDescription.metcon.timecap = null);
            },
          ),
        ],
      );
    }
  }

  Widget _metconMovementsList(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final move = _metconDescription.moves[index];
        return MetconMovementCard(
          key: ObjectKey(move),
          deleteMetconMovement: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _metconDescription.moves.removeAt(index));
          },
          editMetconMovementDescription: (mmd) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _metconDescription.moves[index] = mmd);
          },
          mmd: move,
        );
      },
      itemCount: _metconDescription.moves.length,
      onReorder: (int oldIndex, int newIndex) {
        FocusManager.instance.primaryFocus?.unfocus();
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        setState(() {
          final oldMove = _metconDescription.moves.removeAt(oldIndex);
          _metconDescription.moves.insert(newIndex, oldMove);
        });
      },
    );
  }

  Widget _addMetconMovementButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final movement = await showMovementPickerDialog(context);
        if (movement != null) {
          _addMetconMovementWithMovement(movement);
        }
      },
      icon: const Icon(AppIcons.add),
      label: const Text("Add movement..."),
    );
  }

  void _addMetconMovementWithMovement(Movement movement) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _metconDescription.moves.add(
        MetconMovementDescription(
          metconMovement: MetconMovement.defaultValue(
            metconId: _metconDescription.metcon.id,
            movementId: movement.id,
            movementNumber: _metconDescription.moves.length,
          ),
          movement: movement,
        ),
      );
    });
  }
}

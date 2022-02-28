import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/approve_dialog.dart';
import 'package:sport_log/widgets/form_widgets/selection_bar.dart';
import 'package:sport_log/widgets/message_dialog.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

class EditMovementPage extends StatefulWidget {
  const EditMovementPage({
    required this.movementDescription,
    Key? key,
  })  : name = null,
        super(key: key);

  const EditMovementPage.fromName({
    required String this.name,
    Key? key,
  })  : movementDescription = null,
        super(key: key);

  final MovementDescription? movementDescription;
  final String? name;

  @override
  State<StatefulWidget> createState() => _EditMovementPageState();
}

class _EditMovementPageState extends State<EditMovementPage> {
  final _logger = Logger('EditMovementPage');
  final _dataProvider = MovementDataProvider.instance;
  final _formKey = GlobalKey<FormState>();
  final _descriptionFocusNode = FocusNode();
  late MovementDescription _md;

  @override
  void initState() {
    if (widget.movementDescription != null) {
      _md = widget.movementDescription!;
    } else {
      _md = MovementDescription.defaultValue();
      if (widget.name != null) {
        _md.movement.name = widget.name!;
      }
    }
    super.initState();
  }

  Future<void> _saveMovement() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.movementDescription == null &&
        await _dataProvider.exists(
          _md.movement.name,
          _md.movement.dimension,
        )) {
      await showMessageDialog(
        context: context,
        title: 'Movement exists!',
        text: 'Please use the existing movement.',
      );
      return;
    }

    // TODO: do error handling
    final result = widget.movementDescription != null
        ? await _dataProvider.updateSingle(_md.movement)
        : await _dataProvider.createSingle(_md.movement);
    if (result) {
      _formKey.currentState!.deactivate();
      Navigator.pop(context);
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Movement failed.',
      );
    }
  }

  void _deleteMovement() {
    if (widget.movementDescription != null) {
      assert(_md.movement.userId != null);
      _dataProvider.deleteSingle(_md.movement);
    }
    Navigator.pop(context);
  }

  bool get _inputIsValid => _md.isValid();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.movementDescription != null
                ? "Edit Movement"
                : "New Movement",
          ),
          leading: IconButton(
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final bool? approved = await showDiscardWarningDialog(context);
              if (approved == null || !approved) return;
              Navigator.pop(context);
            },
            icon: const Icon(AppIcons.arrowBack),
          ),
          actions: [
            if (widget.movementDescription != null)
              IconButton(
                onPressed: () => _deleteMovement(),
                icon: const Icon(AppIcons.delete),
              ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _inputIsValid
                  ? () => _saveMovement()
                  : null,
              icon: const Icon(AppIcons.save),
            )
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
                  ..._md.movement.description == null
                      ? [
                          Defaults.sizedBox.vertical.small,
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _md.movement.description = "");
                              _descriptionFocusNode.requestFocus();
                            },
                            icon: const Icon(AppIcons.add),
                            label: const Text("Add description"),
                          ),
                        ]
                      : [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextFormField(
                              initialValue: _md.movement.description ?? "",
                              focusNode: _descriptionFocusNode,
                              keyboardType: TextInputType.multiline,
                              minLines: 1,
                              maxLines: null,
                              onChanged: (description) =>
                                  setState(() => _md.movement.description = ""),
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                labelText: "Description",
                                suffixIcon: IconButton(
                                  icon: const Icon(AppIcons.cancel),
                                  onPressed: () => setState(
                                    () => _md.movement.description = null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                  Defaults.sizedBox.vertical.small,
                  _dimInput,
                  _categoryInput(context),
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
      initialValue: _md.movement.name,
      onChanged: (name) {
        if (Validator.validateStringNotEmpty(name) == null) {
          setState(() => _md.movement.name = name);
        }
      },
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

  Widget get _dimInput {
    return SelectionBar<MovementDimension>(
      onChange: (dim) => setState(() => _md.movement.dimension = dim),
      items: const [
        MovementDimension.reps,
        MovementDimension.time,
        MovementDimension.distance,
        MovementDimension.energy
      ],
      getLabel: (dim) => dim.displayName,
      selectedItem: _md.movement.dimension,
    );
  }

  Widget _categoryInput(BuildContext context) {
    return CheckboxListTile(
      value: _md.movement.cardio,
      checkColor: Theme.of(context).colorScheme.onPrimary,
      onChanged: (bool? isCardio) {
        FocusManager.instance.primaryFocus?.unfocus();
        if (isCardio != null) {
          setState(() => _md.movement.cardio = isCardio);
        }
      },
      title: const Text('Is suitable for cardio sessions'),
    );
  }
}

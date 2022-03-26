import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/input_fields/selection_bar.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

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
  final _dataProvider = MovementDataProvider();
  final _formKey = GlobalKey<FormState>();
  final _descriptionFocusNode = FocusNode();
  late MovementDescription _movementDescription;

  @override
  void initState() {
    if (widget.movementDescription != null) {
      _movementDescription = widget.movementDescription!.clone();
    } else {
      _movementDescription = MovementDescription.defaultValue();
      if (widget.name != null) {
        _movementDescription.movement.name = widget.name!;
      }
    }
    super.initState();
  }

  Future<void> _saveMovement() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = widget.movementDescription != null
        ? await _dataProvider.updateSingle(_movementDescription.movement)
        : await _dataProvider.createSingle(_movementDescription.movement);
    if (result.isSuccess()) {
      _formKey.currentState!.deactivate();
      Navigator.pop(context);
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Movement failed:\n${result.failure}',
      );
    }
  }

  void _deleteMovement() {
    if (widget.movementDescription != null) {
      assert(_movementDescription.movement.userId != null);
      _dataProvider.deleteSingle(_movementDescription.movement);
    }
    Navigator.pop(context);
  }

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
              final bool? approved = await showDiscardWarningDialog(context);
              if (approved != null && approved) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(AppIcons.arrowBack),
          ),
          actions: [
            if (widget.movementDescription != null)
              IconButton(
                onPressed: _deleteMovement,
                icon: const Icon(AppIcons.delete),
              ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _movementDescription.isValid()
                  ? _saveMovement
                  : null,
              icon: const Icon(AppIcons.save),
            )
          ],
        ),
        body: Container(
          padding: Defaults.edgeInsets.normal,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _nameInput(context),
                ..._movementDescription.movement.description == null
                    ? [
                        Defaults.sizedBox.vertical.small,
                        ActionChip(
                          avatar: const Icon(AppIcons.add),
                          label: const Text("Add description"),
                          onPressed: () {
                            setState(
                              () => _movementDescription.movement.description =
                                  "",
                            );
                            _descriptionFocusNode.requestFocus();
                          },
                        ),
                      ]
                    : [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextFormField(
                            initialValue:
                                _movementDescription.movement.description,
                            focusNode: _descriptionFocusNode,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            maxLines: null,
                            onChanged: (description) => setState(
                              () => _movementDescription.movement.description =
                                  description,
                            ),
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 5),
                              labelText: "Description",
                              suffixIcon: IconButton(
                                icon: const Icon(AppIcons.close),
                                onPressed: () => setState(
                                  () => _movementDescription
                                      .movement.description = null,
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
    );
  }

  Widget _nameInput(BuildContext context) {
    return TextFormField(
      initialValue: _movementDescription.movement.name,
      onChanged: (name) {
        if (Validator.validateStringNotEmpty(name) == null) {
          setState(() => _movementDescription.movement.name = name);
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
      onChange: (dim) =>
          setState(() => _movementDescription.movement.dimension = dim),
      items: const [
        MovementDimension.reps,
        MovementDimension.time,
        MovementDimension.distance,
        MovementDimension.energy
      ],
      getLabel: (dim) => dim.displayName,
      selectedItem: _movementDescription.movement.dimension,
    );
  }

  Widget _categoryInput(BuildContext context) {
    return CheckboxListTile(
      value: _movementDescription.movement.cardio,
      checkColor: Theme.of(context).colorScheme.onPrimary,
      onChanged: (bool? isCardio) {
        FocusManager.instance.primaryFocus?.unfocus();
        if (isCardio != null) {
          setState(() => _movementDescription.movement.cardio = isCardio);
        }
      },
      title: const Text('Is suitable for cardio sessions'),
    );
  }
}

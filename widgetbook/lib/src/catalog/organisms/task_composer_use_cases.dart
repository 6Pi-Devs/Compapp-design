import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The most suggestions, rooms and items the playground shows: the length of
/// each sample pool.
const _poolSize = 3;

/// The states of the Organisms board and its contract: nothing typed, a name
/// being typed, a known task found, a name that is a new task, and the form
/// waiting for the request.
enum _ComposerState {
  empty('empty'),
  typing('typing'),
  match('match'),
  newTask('new-task'),
  submitting('submitting');

  new(this.id);

  final String id;
}

/// One use case per state of the contract: the empty field with its hint, a
/// name still being typed with the tasks found so far, the match of the board
/// (the same task as before, in its room), a new task with the line that says
/// so, and the form submitting. The spinner of the waiting button stands still.
WidgetbookComponent buildTaskComposer() {
  return WidgetbookComponent(
    name: 'TaskComposer',
    useCases: [
      _playground(),
      for (final state in _ComposerState.values)
        WidgetbookUseCase(
          name: 'composer-${state.id}',
          builder: (context) => FrozenMotion(
            child: barFrame(
              child: TaskComposer(
                view: _stateView(context, state),
                onQuery: _ignore,
                onPick: _ignore,
                onLink: _ignoreTarget,
                onSubmit: _ignoreSubmit,
              ),
            ),
          ),
        ),
    ],
  );
}

void _ignore(String value) {}

void _ignoreTarget(TaskTarget? target) {}

void _ignoreSubmit(TaskSubmission submission) {}

enum _Suggestion { cleanKitchen, cleanOven, cleanBathroom }

enum _Room { kitchen, bathroom, living }

enum _Item { oven, washer, dishwasher }

TaskSuggestion _suggestion(BuildContext context, _Suggestion sample) =>
    switch (sample) {
      _Suggestion.cleanKitchen => TaskSuggestion(
        id: 'clean-kitchen',
        title: context.sample(en: 'Clean the kitchen', es: 'Limpiar la cocina'),
        subtitle: context.sample(
          en: 'Same task as before · Carlos, 3 days ago',
          es: 'Misma tarea que antes · Carlos, hace 3 días',
        ),
      ),
      _Suggestion.cleanOven => TaskSuggestion(
        id: 'clean-oven',
        title: context.sample(en: 'Clean the oven', es: 'Limpiar el horno'),
        subtitle: context.sample(
          en: 'Last done 12 days ago',
          es: 'Hecha por última vez hace 12 días',
        ),
      ),
      _Suggestion.cleanBathroom => TaskSuggestion(
        id: 'clean-bathroom',
        title: context.sample(en: 'Clean the bathroom', es: 'Limpiar el baño'),
        subtitle: context.sample(
          en: 'Last done 5 days ago',
          es: 'Hecha por última vez hace 5 días',
        ),
      ),
    };

RoomView _room(BuildContext context, _Room sample) => switch (sample) {
  _Room.kitchen => RoomView(
    id: 'kitchen',
    name: context.sample(en: 'Kitchen', es: 'Cocina'),
  ),
  _Room.bathroom => RoomView(
    id: 'bathroom',
    name: context.sample(en: 'Bathroom', es: 'Baño'),
  ),
  _Room.living => RoomView(
    id: 'living',
    name: context.sample(en: 'Living room', es: 'Salón'),
  ),
};

ItemView _item(BuildContext context, _Item sample) => switch (sample) {
  _Item.oven => ItemView(
    id: 'oven',
    name: context.sample(en: 'Oven', es: 'Horno'),
    icon: AppIcons.oven,
  ),
  _Item.washer => ItemView(
    id: 'washer',
    name: context.sample(en: 'Washer', es: 'Lavadora'),
    icon: AppIcons.washer,
  ),
  _Item.dishwasher => ItemView(
    id: 'dishwasher',
    name: context.sample(en: 'Dishwasher', es: 'Lavavajillas'),
    icon: AppIcons.dishwasher,
  ),
};

String _label(BuildContext context) =>
    context.sample(en: 'Log what you did', es: 'Registra lo que hiciste');

String _hint(BuildContext context) => context.sample(
  en: 'For example, clean the kitchen',
  es: 'Por ejemplo, limpiar la cocina',
);

String _newTask(BuildContext context) => context.sample(
  en: 'New task: it will be added to your home',
  es: 'Tarea nueva: se añadirá a tu casa',
);

String _suggestionsLabel(BuildContext context) =>
    context.sample(en: 'Suggestions', es: 'Sugerencias');

String _targetsLabel(BuildContext context) =>
    context.sample(en: 'Where it was done', es: 'Dónde se hizo');

String _submitLabel(BuildContext context) =>
    context.sample(en: 'Log it', es: 'Registrar');

String _loadingLabel(BuildContext context) =>
    context.sample(en: 'Logging', es: 'Registrando');

TaskComposerView _view(
  BuildContext context, {
  required String query,
  List<_Suggestion> suggestions = const [],
  List<_Room> rooms = _Room.values,
  List<_Item> items = _Item.values,
  TaskTarget? linked,
  String? hint,
  String? helperText,
  bool submitting = false,
}) {
  return TaskComposerView(
    query: query,
    suggestions: [for (final s in suggestions) _suggestion(context, s)],
    rooms: [for (final r in rooms) _room(context, r)],
    items: [for (final i in items) _item(context, i)],
    linked: linked,
    label: _label(context),
    hint: hint,
    helperText: helperText,
    suggestionsLabel: _suggestionsLabel(context),
    targetsLabel: _targetsLabel(context),
    submitLabel: _submitLabel(context),
    submitting: submitting,
    loadingLabel: _loadingLabel(context),
  );
}

TaskComposerView _stateView(BuildContext context, _ComposerState state) {
  const kitchen = TaskTarget(TaskTargetKind.room, 'kitchen');
  return switch (state) {
    _ComposerState.empty => _view(context, query: '', hint: _hint(context)),
    _ComposerState.typing => _view(
      context,
      query: context.sample(en: 'cle', es: 'lim'),
      suggestions: [_Suggestion.cleanKitchen, _Suggestion.cleanOven],
    ),
    _ComposerState.match => _view(
      context,
      query: context.sample(en: 'clean the kitchen', es: 'limpiar la cocina'),
      suggestions: [_Suggestion.cleanKitchen],
      linked: kitchen,
    ),
    _ComposerState.newTask => _view(
      context,
      query: context.sample(en: 'Wash the dog', es: 'Lavar al perro'),
      helperText: _newTask(context),
    ),
    _ComposerState.submitting => _view(
      context,
      query: context.sample(en: 'clean the kitchen', es: 'limpiar la cocina'),
      suggestions: [_Suggestion.cleanKitchen],
      linked: kitchen,
      submitting: true,
    ),
  };
}

/// Every prop of [TaskComposer] as a knob: the text, how many suggestions,
/// rooms and items of the sample pools, which of them is linked, the label,
/// the hint, the helper text, the two spoken names, the label of the button,
/// the wait and the spoken value of the button while it waits. The text and
/// the link stay interactive: typing, picking a suggestion and pressing a chip
/// drive them, and a change of a knob starts them over. The callback that logs
/// is plumbing: the story owns it.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      int count(String label, int initial, String description) => context
          .knobs
          .int
          .slider(
            label: label,
            description: description,
            initialValue: initial,
            max: _poolSize,
            divisions: _poolSize,
          )
          .clamp(0, _poolSize);
      String text(String label, String initial) {
        final typed = context.textKnob(
          label,
          initial,
          description:
              'Must not be empty: an empty one falls back to the '
              'sample',
        );
        return typed.isEmpty ? initial : typed;
      }

      final query = context.textKnob(
        'query',
        context.sample(en: 'clean the kitchen', es: 'limpiar la cocina'),
        description: 'The text of the field to start from',
      );
      final suggestions = count('suggestions', 1, 'How many tasks are offered');
      final rooms = count('rooms', _poolSize, 'How many room chips');
      final items = count('items', _poolSize, 'How many item chips');
      final linkedKind = context.enumKnobOrNull<TaskTargetKind>(
        'linkedKind',
        TaskTargetKind.values,
        description:
            'Whether a room or an item starts linked, none for no link',
      );
      final linkedIndex = context.knobs.int
          .slider(
            label: 'linkedIndex',
            description: 'Which chip of that kind starts linked',
            max: _poolSize - 1,
            divisions: _poolSize - 1,
          )
          .clamp(0, _poolSize - 1);
      final label = text('label', _label(context));
      final hint = context.textKnobOrNull('hint', _hint(context));
      final helperText = context.textKnobOrNull(
        'helperText',
        null,
        description: 'A line under the field, for a name that is a new task',
      );
      final suggestionsLabel = text(
        'suggestionsLabel',
        _suggestionsLabel(context),
      );
      final targetsLabel = text('targetsLabel', _targetsLabel(context));
      final submitLabel = text('submitLabel', _submitLabel(context));
      final submitting = context.knobs.boolean(
        label: 'submitting',
        description: 'The request is under way: the button waits',
      );
      final loadingLabel = context.textKnobOrNull(
        'loadingLabel',
        _loadingLabel(context),
        description: 'Spoken value of the button while it waits',
      );

      final suggestionPool = _Suggestion.values.take(suggestions).toList();
      final roomPool = _Room.values.take(rooms).toList();
      final itemPool = _Item.values.take(items).toList();
      final initialLink = switch (linkedKind) {
        TaskTargetKind.room when roomPool.isNotEmpty => TaskTarget(
          TaskTargetKind.room,
          _room(
            context,
            roomPool[linkedIndex.clamp(0, roomPool.length - 1)],
          ).id,
        ),
        TaskTargetKind.item when itemPool.isNotEmpty => TaskTarget(
          TaskTargetKind.item,
          _item(
            context,
            itemPool[linkedIndex.clamp(0, itemPool.length - 1)],
          ).id,
        ),
        _ => null,
      };

      // A playground can grow taller than the preview, and the organism is not
      // a scrollable: it scrolls as it would inside a screen.
      return SingleChildScrollView(
        child: FrozenMotion(
          child: barFrame(
            child: SeededState<String>(
              initial: query,
              builder: (context, text, setText) => SeededState<TaskTarget?>(
                initial: initialLink,
                builder: (context, linked, setLinked) {
                  final offered = [
                    for (final s in suggestionPool) _suggestion(context, s),
                  ];
                  return TaskComposer(
                    view: TaskComposerView(
                      query: text,
                      suggestions: offered,
                      rooms: [for (final r in roomPool) _room(context, r)],
                      items: [for (final i in itemPool) _item(context, i)],
                      linked: linked,
                      label: label,
                      hint: hint,
                      helperText: (helperText ?? '').isEmpty
                          ? null
                          : helperText,
                      suggestionsLabel: suggestionsLabel,
                      targetsLabel: targetsLabel,
                      submitLabel: submitLabel,
                      submitting: submitting,
                      loadingLabel: loadingLabel,
                    ),
                    onQuery: setText,
                    onPick: (id) =>
                        setText(offered.firstWhere((s) => s.id == id).title),
                    onLink: setLinked,
                    onSubmit: _ignoreSubmit,
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

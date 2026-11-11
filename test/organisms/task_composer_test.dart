import 'dart:ui' show Tristate;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

const _kitchen = TaskTarget(TaskTargetKind.room, 'kitchen');
const _oven = TaskTarget(TaskTargetKind.item, 'oven');

const _cleanKitchen = TaskSuggestion(
  id: 'clean-kitchen',
  title: 'Clean the kitchen',
  subtitle: 'Same task as before · Carlos, 3 days ago',
);
const _cleanOven = TaskSuggestion(
  id: 'clean-oven',
  title: 'Clean the oven',
  subtitle: 'Last done 12 days ago',
);

TaskComposerView _view({
  String query = 'clean the kitchen',
  List<TaskSuggestion> suggestions = const [_cleanKitchen],
  List<RoomView> rooms = const [
    RoomView(id: 'kitchen', name: 'Kitchen'),
    RoomView(id: 'bathroom', name: 'Bathroom'),
  ],
  List<ItemView> items = const [
    ItemView(id: 'oven', name: 'Oven', icon: AppIcons.oven),
  ],
  TaskTarget? linked = _kitchen,
  String label = 'Log what you did',
  String? hint,
  String? helperText,
  bool submitting = false,
  String? loadingLabel = 'Logging',
}) => TaskComposerView(
  query: query,
  suggestions: suggestions,
  rooms: rooms,
  items: items,
  linked: linked,
  label: label,
  hint: hint,
  helperText: helperText,
  suggestionsLabel: 'Suggestions',
  targetsLabel: 'Where it was done',
  submitLabel: 'Log it',
  submitting: submitting,
  loadingLabel: loadingLabel,
);

TaskComposer _composer({
  TaskComposerView? view,
  ValueChanged<String>? onQuery,
  ValueChanged<String>? onPick,
  ValueChanged<TaskTarget?>? onLink,
  ValueChanged<TaskSubmission>? onSubmit,
}) => TaskComposer(
  view: view ?? _view(),
  onQuery: onQuery ?? (_) {},
  onPick: onPick ?? (_) {},
  onLink: onLink ?? (_) {},
  onSubmit: onSubmit ?? (_) {},
);

/// A composer that answers its callbacks the way a cubit does: the query and
/// the link are state, and a pick fills the query with the title.
class _Harness extends StatefulWidget {
  const new({required this.build});

  final TaskComposerView Function(
    String query,
    TaskTarget? linked,
    List<TaskSuggestion> suggestions,
  )
  build;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  static const List<TaskSuggestion> _pool = [_cleanKitchen, _cleanOven];

  String query = '';
  TaskTarget? linked;

  @override
  Widget build(BuildContext context) {
    final suggestions = query.isEmpty
        ? const <TaskSuggestion>[]
        : _pool
              .where((s) => s.title.toLowerCase().contains(query.toLowerCase()))
              .toList();
    return TaskComposer(
      view: widget.build(query, linked, suggestions),
      onQuery: (text) => setState(() => query = text),
      onPick: (id) =>
          setState(() => query = _pool.firstWhere((s) => s.id == id).title),
      onLink: (target) => setState(() => linked = target),
      onSubmit: (_) {},
    );
  }
}

Finder get _composerFinder => find.byKey(const Key('tasks.composer'));
Finder get _field => find.byKey(const Key('tasks.composer.field'));
Finder get _input => find.byType(TextField);
Finder get _submit => find.byKey(const Key('tasks.composer.submit'));
Finder get _button =>
    find.descendant(of: _submit, matching: find.byType(FilledButton));
Finder get _suggestionsList =>
    find.byKey(const Key('tasks.composer.suggestions'));
Finder get _targets => find.byKey(const Key('tasks.composer.targets'));
Finder _suggestion(String id) =>
    find.byKey(Key('tasks.composer.suggestion.$id'));
Finder _room(String id) => find.byKey(Key('tasks.composer.room.$id'));
Finder _item(String id) => find.byKey(Key('tasks.composer.item.$id'));

AppChip _chip(WidgetTester tester, Finder finder) =>
    tester.widget<AppChip>(finder);

/// A widget test on a surface tall enough for the whole composer, at the
/// large text sizes it grows to.
void _widgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    tester.view
      ..physicalSize = const Size(800, 8000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await body(tester);
  });
}

List<SemanticsNode> _children(SemanticsNode node) {
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  return children;
}

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    _widgets('draws the field, the suggestions, the chips and the button, in '
        'that order', (tester) async {
      await tester.pumpWidget(host(_composer()));

      expect(find.text('Log what you did'), findsOneWidget);
      expect(find.text('Clean the kitchen'), findsOneWidget);
      expect(
        find.text('Same task as before · Carlos, 3 days ago'),
        findsOneWidget,
      );
      expect(find.text('Log it'), findsOneWidget);
      final tops = [
        for (final finder in [_input, _suggestionsList, _targets, _submit])
          tester.getTopLeft(finder).dy,
      ];
      expect(tops, [...tops]..sort());
    });

    _widgets('has its keys', (tester) async {
      await tester.pumpWidget(host(_composer()));

      for (final key in [
        'tasks.composer',
        'tasks.composer.field',
        'tasks.composer.suggestions',
        'tasks.composer.suggestion.clean-kitchen',
        'tasks.composer.targets',
        'tasks.composer.room.kitchen',
        'tasks.composer.room.bathroom',
        'tasks.composer.item.oven',
        'tasks.composer.submit',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
    });

    _widgets('the field starts with the query, the hint and the helper text '
        'come from the app', (tester) async {
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(
              query: '',
              hint: 'For example, clean the kitchen',
              helperText: 'New task',
            ),
          ),
        ),
      );

      expect(tester.widget<TextField>(_input).controller!.text, '');
      expect(find.text('For example, clean the kitchen'), findsOneWidget);
      expect(find.text('New task'), findsOneWidget);

      await tester.pumpWidget(host(_composer(view: _view(query: 'Wash up'))));
      expect(find.text('Wash up'), findsOneWidget);
    });

    _widgets('offers every suggestion, in order, with its subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(
              suggestions: [
                _cleanOven,
                _cleanKitchen,
                const TaskSuggestion(id: 'bare', title: 'Water the plants'),
              ],
            ),
          ),
        ),
      );

      final tops = [
        for (final id in ['clean-oven', 'clean-kitchen', 'bare'])
          tester.getTopLeft(_suggestion(id)).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(find.text('Last done 12 days ago'), findsOneWidget);
      expect(
        find.descendant(of: _suggestion('bare'), matching: find.byType(Text)),
        findsOneWidget,
        reason: 'no subtitle, no second line',
      );
    });

    _widgets('never offers the same task twice: case and extra spaces do '
        'not make it another', (tester) async {
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(
              suggestions: const [
                _cleanKitchen,
                TaskSuggestion(id: 'dup-1', title: '  clean   THE kitchen '),
                TaskSuggestion(id: 'dup-2', title: 'CLEAN THE KITCHEN'),
                _cleanOven,
              ],
            ),
          ),
        ),
      );

      expect(_suggestion('clean-kitchen'), findsOneWidget);
      expect(_suggestion('dup-1'), findsNothing);
      expect(_suggestion('dup-2'), findsNothing);
      expect(_suggestion('clean-oven'), findsOneWidget);
    });

    _widgets('leaves out the list and the chips when there is nothing to '
        'show', (tester) async {
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(
              suggestions: const [],
              rooms: const [],
              items: const [],
              linked: null,
            ),
          ),
        ),
      );

      expect(_suggestionsList, findsNothing);
      expect(_targets, findsNothing);
      expect(find.byType(AppChip), findsNothing);
      expect(_submit, findsOneWidget);
    });

    _widgets('rooms come first and are solid, items follow and are dashed, '
        'and the linked one is selected', (tester) async {
      await tester.pumpWidget(host(_composer()));

      // Reading order: by line, then along it (the chips wrap in a phone).
      final spots = [
        tester.getTopLeft(_room('kitchen')),
        tester.getTopLeft(_room('bathroom')),
        tester.getTopLeft(_item('oven')),
      ];
      int byReading(Offset a, Offset b) =>
          a.dy != b.dy ? a.dy.compareTo(b.dy) : a.dx.compareTo(b.dx);
      expect([...spots]..sort(byReading), spots);
      expect(_chip(tester, _room('kitchen')).kind, AppChipKind.room);
      expect(_chip(tester, _item('oven')).kind, AppChipKind.item);
      expect(_chip(tester, _room('kitchen')).selected, isTrue);
      expect(_chip(tester, _room('bathroom')).selected, isFalse);
      expect(_chip(tester, _item('oven')).selected, isFalse);
      expect(
        find.descendant(of: _room('kitchen'), matching: find.byType(AppIcon)),
        findsOneWidget,
        reason: 'the check is the cue that it is on, not the color',
      );
    });

    _widgets('a room and an item with the same id are two chips, and only '
        'the one of the linked kind is on', (tester) async {
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(
              rooms: const [RoomView(id: 'x', name: 'Study')],
              items: const [
                ItemView(id: 'x', name: 'Desk', icon: AppIcons.oven),
              ],
              linked: const TaskTarget(TaskTargetKind.item, 'x'),
            ),
          ),
        ),
      );

      expect(_chip(tester, _room('x')).selected, isFalse);
      expect(_chip(tester, _item('x')).selected, isTrue);
    });

    _widgets('the button waits for a name with more than spaces', (
      tester,
    ) async {
      for (final (query, enabled) in [
        ('', false),
        ('   ', false),
        ('\t\n', false),
        ('a', true),
        ('  a ', true),
      ]) {
        await tester.pumpWidget(host(_composer(view: _view(query: query))));
        expect(
          tester.widget<AppButton>(_submit).onPressed != null,
          enabled,
          reason: 'query "${query.replaceAll('\n', r'\n')}"',
        );
      }
    });

    _widgets('submitting makes the button wait', (tester) async {
      await tester.pumpWidget(host(_composer(view: _view(submitting: true))));

      expect(tester.widget<AppButton>(_submit).loading, isTrue);
      expect(tester.widget<AppButton>(_submit).loadingSemanticLabel, 'Logging');
      expect(tester.widget<TextField>(_input).readOnly, isTrue);
    });

    _widgets('an invalid view is a mistake the debug build reports', (
      tester,
    ) async {
      for (final view in [
        _view(suggestions: [_cleanKitchen, _cleanKitchen]),
        _view(
          rooms: const [
            RoomView(id: 'a', name: 'A'),
            RoomView(id: 'a', name: 'B'),
          ],
        ),
        _view(
          items: const [
            ItemView(id: 'a', name: 'A', icon: AppIcons.oven),
            ItemView(id: 'a', name: 'B', icon: AppIcons.oven),
          ],
        ),
      ]) {
        await tester.pumpWidget(host(_composer(view: view)));
        expect(tester.takeException(), isAssertionError);
      }
    });

    test('the models need their words and compare by value', () {
      expect(() => TaskSuggestion(id: '', title: 'A'), throwsAssertionError);
      expect(() => TaskSuggestion(id: 'a', title: ''), throwsAssertionError);
      expect(() => TaskTarget(TaskTargetKind.room, ''), throwsAssertionError);
      expect(
        () => TaskComposerView(
          query: '',
          suggestions: const [],
          rooms: const [],
          items: const [],
          label: '',
          suggestionsLabel: 'S',
          targetsLabel: 'T',
          submitLabel: 'L',
        ),
        throwsAssertionError,
      );
      expect(
        _cleanKitchen,
        const TaskSuggestion(
          id: 'clean-kitchen',
          title: 'Clean the kitchen',
          subtitle: 'Same task as before · Carlos, 3 days ago',
        ),
      );
      expect(_cleanKitchen, isNot(_cleanOven));
      expect(() => TaskSubmission(name: ''), throwsAssertionError);
      expect(
        const TaskSubmission(name: 'A', target: _kitchen),
        const TaskSubmission(name: 'A', target: _kitchen),
      );
      expect(
        const TaskSubmission(name: 'A', target: _kitchen).hashCode,
        const TaskSubmission(name: 'A', target: _kitchen).hashCode,
      );
      expect(
        const TaskSubmission(name: 'A', target: _kitchen),
        isNot(const TaskSubmission(name: 'A')),
      );
      expect(
        const TaskSubmission(name: 'A'),
        isNot(const TaskSubmission(name: 'B')),
      );
      expect(_kitchen, const TaskTarget(TaskTargetKind.room, 'kitchen'));
      expect(_kitchen, isNot(const TaskTarget(TaskTargetKind.item, 'kitchen')));
      expect(
        _kitchen.hashCode,
        const TaskTarget(TaskTargetKind.room, 'kitchen').hashCode,
      );
      expect(_view(), _view());
      expect(_view().hashCode, _view().hashCode);
      expect(_view(), isNot(_view(query: 'other')));
      expect(_view(), isNot(_view(linked: null)));
      expect(_view(), isNot(_view(submitting: true)));
      expect(_view(), isNot(_view(helperText: 'x')));
    });
  });

  group('callbacks', () {
    _widgets('typing calls onQuery with the text', (tester) async {
      final queries = <String>[];
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: ''),
            onQuery: queries.add,
          ),
        ),
      );

      await tester.enterText(_input, 'Clean');
      await tester.enterText(_input, 'Clean the');

      expect(queries, ['Clean', 'Clean the']);
    });

    _widgets('a tap on a suggestion calls onPick with its id', (tester) async {
      final picks = <String>[];
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(suggestions: [_cleanKitchen, _cleanOven]),
            onPick: picks.add,
          ),
        ),
      );

      await tester.tap(_suggestion('clean-oven'));
      await tester.tap(_suggestion('clean-kitchen'));

      expect(picks, ['clean-oven', 'clean-kitchen']);
    });

    _widgets('a chip that is off calls onLink with its target, and the one '
        'that is on calls it with null', (tester) async {
      final links = <TaskTarget?>[];
      await tester.pumpWidget(host(_composer(onLink: links.add)));

      await tester.tap(_room('bathroom'));
      await tester.tap(_item('oven'));
      await tester.tap(_room('kitchen'));

      expect(links, [
        const TaskTarget(TaskTargetKind.room, 'bathroom'),
        _oven,
        null,
      ]);
    });

    _widgets('the button calls onSubmit with the name without the spaces '
        'around it, and the link', (tester) async {
      final submitted = <TaskSubmission>[];
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: '  Clean the kitchen  '),
            onSubmit: submitted.add,
          ),
        ),
      );

      await tester.tap(_submit);

      expect(submitted, [
        const TaskSubmission(name: 'Clean the kitchen', target: _kitchen),
      ]);
    });

    _widgets('with no link the button gives a null target', (tester) async {
      final submitted = <TaskSubmission>[];
      await tester.pumpWidget(
        host(_composer(view: _view(linked: null), onSubmit: submitted.add)),
      );

      await tester.tap(_submit);

      expect(submitted.single.target, isNull);
    });

    _widgets('the done key of the keyboard logs it too, and only when the '
        'button could', (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: 'Wash up'),
            onSubmit: (s) => submitted.add(s.name),
          ),
        ),
      );
      await tester.tap(_input);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, ['Wash up']);

      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: '   '),
            onSubmit: (s) => submitted.add(s.name),
          ),
        ),
      );
      await tester.tap(_input);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, ['Wash up'], reason: 'nothing but spaces: not logged');

      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: 'Wash up', submitting: true),
            onSubmit: (s) => submitted.add(s.name),
          ),
        ),
      );
      await tester.tap(_input);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, ['Wash up'], reason: 'while it waits: not logged');
    });

    _widgets('the button does nothing without a name', (tester) async {
      var submitted = 0;
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: ' '),
            onSubmit: (_) => submitted++,
          ),
        ),
      );

      await tester.tap(_submit);

      expect(submitted, 0);
    });

    _widgets('while submitting nothing can be changed or logged again', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(suggestions: [_cleanKitchen], submitting: true),
            onQuery: (_) => calls.add('query'),
            onPick: (_) => calls.add('pick'),
            onLink: (_) => calls.add('link'),
            onSubmit: (_) => calls.add('submit'),
          ),
        ),
      );

      await tester.tap(_suggestion('clean-kitchen'), warnIfMissed: false);
      await tester.tap(_room('bathroom'), warnIfMissed: false);
      await tester.tap(_submit, warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(calls, isEmpty);
      for (final finder in [
        _room('kitchen'),
        _room('bathroom'),
        _item('oven'),
      ]) {
        expect(_chip(tester, finder).onTap, isNull);
      }
      expect(
        tester.widget<TextButton>(_suggestion('clean-kitchen')).onPressed,
        isNull,
      );
    });

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      _widgets(
        'a focused suggestion takes ${key.keyLabel.isEmpty ? 'Space' : 'Enter'}'
        '',
        (tester) async {
          final picks = <String>[];
          await tester.pumpWidget(host(_composer(onPick: picks.add)));
          await _focus(tester, _suggestion('clean-kitchen'));

          await tester.sendKeyEvent(key);

          expect(picks, ['clean-kitchen']);
        },
      );
    }

    _widgets('a focused chip takes Space and toggles', (tester) async {
      final links = <TaskTarget?>[];
      await tester.pumpWidget(host(_composer(onLink: links.add)));
      await _focus(tester, _room('bathroom'));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);

      expect(links, [const TaskTarget(TaskTargetKind.room, 'bathroom')]);
    });
  });

  group('the text of the field', () {
    _widgets('follows a query the app changes, caret at the end', (
      tester,
    ) async {
      await tester.pumpWidget(host(_composer(view: _view(query: 'cle'))));
      expect(tester.widget<TextField>(_input).controller!.text, 'cle');

      await tester.pumpWidget(
        host(_composer(view: _view(query: 'Clean the kitchen'))),
      );

      final controller = tester.widget<TextField>(_input).controller!;
      expect(controller.text, 'Clean the kitchen');
      expect(controller.selection, const TextSelection.collapsed(offset: 17));

      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      expect(tester.widget<TextField>(_input).controller!.text, '');
    });

    _widgets('leaves the text, and the caret, alone when the query is what '
        'the field already has', (tester) async {
      await tester.pumpWidget(host(_composer(view: _view(query: 'Clean'))));
      final controller = tester.widget<TextField>(_input).controller!
        ..selection = const TextSelection.collapsed(offset: 2);

      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: 'Clean', hint: 'other'),
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: 'Clean', suggestions: const []),
          ),
        ),
      );

      expect(controller.text, 'Clean');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    _widgets('an echo of what was typed leaves the caret where it is', (
      tester,
    ) async {
      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      await tester.enterText(_input, 'clean');
      final controller = tester.widget<TextField>(_input).controller!
        ..selection = const TextSelection.collapsed(offset: 2);

      await tester.pumpWidget(host(_composer(view: _view(query: 'clean'))));

      expect(controller.text, 'clean');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    _widgets('what is typed stays when the app answers with the same text', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _Harness(
            build: (query, linked, suggestions) =>
                _view(query: query, suggestions: suggestions, linked: linked),
          ),
        ),
      );

      await tester.enterText(_input, 'clean');
      await tester.pump();
      expect(tester.widget<TextField>(_input).controller!.text, 'clean');
      expect(_suggestion('clean-kitchen'), findsOneWidget);
      expect(_suggestion('clean-oven'), findsOneWidget);

      await tester.enterText(_input, 'clean the o');
      await tester.pump();
      expect(_suggestion('clean-kitchen'), findsNothing);
      expect(_suggestion('clean-oven'), findsOneWidget);
    });

    _widgets('picking a suggestion fills the field with its title', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _Harness(
            build: (query, linked, suggestions) =>
                _view(query: query, suggestions: suggestions, linked: linked),
          ),
        ),
      );
      await tester.enterText(_input, 'clean');
      await tester.pump();

      await tester.tap(_suggestion('clean-oven'));
      await tester.pump();

      expect(
        tester.widget<TextField>(_input).controller!.text,
        'Clean the oven',
      );
    });

    _widgets('a chip toggles through the app: on, over to another, off', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _Harness(
            build: (query, linked, suggestions) =>
                _view(query: query, suggestions: suggestions, linked: linked),
          ),
        ),
      );

      bool on(Finder chip) => _chip(tester, chip).selected;
      await tester.tap(_room('kitchen'));
      await tester.pump();
      expect([on(_room('kitchen')), on(_room('bathroom'))], [true, false]);

      await tester.tap(_room('bathroom'));
      await tester.pump();
      expect([on(_room('kitchen')), on(_room('bathroom'))], [false, true]);

      await tester.tap(_room('bathroom'));
      await tester.pump();
      expect([on(_room('kitchen')), on(_room('bathroom'))], [false, false]);
    });
  });

  group('typing against a slow app', () {
    _widgets('a stale echo of earlier typing does not overwrite newer typing', (
      tester,
    ) async {
      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      await tester.enterText(_input, 'a');
      await tester.enterText(_input, 'ab');
      final controller = tester.widget<TextField>(_input).controller!;

      await tester.pumpWidget(host(_composer(view: _view(query: 'a'))));
      expect(controller.text, 'ab');

      await tester.pumpWidget(host(_composer(view: _view(query: 'ab'))));
      expect(controller.text, 'ab');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    _widgets('a late echo keeps the caret and the composing region', (
      tester,
    ) async {
      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      await tester.enterText(_input, 'ab');
      final controller = tester.widget<TextField>(_input).controller!
        ..value = const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 2),
        );

      await tester.pumpWidget(host(_composer(view: _view(query: 'ab'))));

      expect(controller.selection, const TextSelection.collapsed(offset: 1));
      expect(controller.value.composing, const TextRange(start: 0, end: 2));
    });

    _widgets('a query the app changes by itself replaces the text, even '
        'after typing', (tester) async {
      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      await tester.enterText(_input, 'ab');
      final controller = tester.widget<TextField>(_input).controller!;

      await tester.pumpWidget(
        host(_composer(view: _view(query: 'Clean the oven'))),
      );
      expect(controller.text, 'Clean the oven');
      expect(controller.selection, const TextSelection.collapsed(offset: 14));

      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      expect(controller.text, '');
    });

    _widgets('once the app has answered, an older text it sends is its own '
        'change', (tester) async {
      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      await tester.enterText(_input, 'a');
      await tester.enterText(_input, 'ab');
      final controller = tester.widget<TextField>(_input).controller!;
      await tester.pumpWidget(host(_composer(view: _view(query: 'ab'))));

      await tester.pumpWidget(host(_composer(view: _view(query: 'a'))));

      expect(controller.text, 'a');
    });
  });

  group('a change the app makes forgets what was sent', () {
    _widgets('an app reset to a text that was typed before is still a '
        'reset', (tester) async {
      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      await tester.enterText(_input, 'a');
      await tester.enterText(_input, 'ab');
      final controller = tester.widget<TextField>(_input).controller!;

      await tester.pumpWidget(
        host(_composer(view: _view(query: 'Clean the oven'))),
      );
      await tester.pumpWidget(host(_composer(view: _view(query: 'a'))));

      expect(controller.text, 'a');
    });
  });

  group('what is logged is what the field shows', () {
    _widgets('the button logs the text of the field when the app has not '
        'heard the last key', (tester) async {
      final submitted = <TaskSubmission>[];
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: 'Clean'),
            onSubmit: submitted.add,
          ),
        ),
      );

      await tester.enterText(_input, ' Clean the oven ');
      await tester.pump();
      await tester.tap(_submit);

      expect(submitted, [
        const TaskSubmission(name: 'Clean the oven', target: _kitchen),
      ]);
    });

    _widgets('the done key logs the text of the field in the same frame', (
      tester,
    ) async {
      final submitted = <TaskSubmission>[];
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: 'Clean'),
            onSubmit: submitted.add,
          ),
        ),
      );

      await tester.enterText(_input, 'Clean the oven');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submitted.map((s) => s.name), ['Clean the oven']);
    });

    _widgets('the button follows the field: off for spaces, on for a name, '
        'whatever the view says', (tester) async {
      await tester.pumpWidget(host(_composer(view: _view(query: 'Clean'))));
      expect(tester.widget<AppButton>(_submit).onPressed, isNotNull);

      await tester.enterText(_input, '   ');
      await tester.pump();
      expect(tester.widget<AppButton>(_submit).onPressed, isNull);

      await tester.pumpWidget(host(_composer(view: _view(query: 'Clean'))));
      await tester.enterText(_input, 'x');
      await tester.pump();
      expect(tester.widget<AppButton>(_submit).onPressed, isNotNull);

      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      expect(tester.widget<AppButton>(_submit).onPressed, isNull);
      await tester.enterText(_input, 'Wash up');
      await tester.pump();
      expect(tester.widget<AppButton>(_submit).onPressed, isNotNull);
    });

    _widgets('a nothing-but-spaces field is not logged by the done key even '
        'if the view has a name', (tester) async {
      final submitted = <TaskSubmission>[];
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(query: 'Clean'),
            onSubmit: submitted.add,
          ),
        ),
      );

      await tester.enterText(_input, '  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submitted, isEmpty);
    });

    _widgets('a linked target that is not among the rooms or items is a '
        'mistake the debug build reports', (tester) async {
      for (final linked in const [
        TaskTarget(TaskTargetKind.room, 'nowhere'),
        TaskTarget(TaskTargetKind.item, 'kitchen'),
        TaskTarget(TaskTargetKind.room, 'oven'),
      ]) {
        await tester.pumpWidget(host(_composer(view: _view(linked: linked))));
        expect(tester.takeException(), isAssertionError, reason: '$linked');
      }
      await tester.pumpWidget(host(_composer(view: _view(linked: _oven))));
      expect(tester.takeException(), isNull);
    });
  });

  group('semantics', () {
    _widgets('the form reads the field, the list, the chips and the button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_composer()));

      expect(
        tester.getSemantics(_composerFinder).getSemanticsData().role,
        SemanticsRole.form,
      );
      expect(semanticsLabels(tester), [
        'Log what you did',
        'Suggestions',
        'Clean the kitchen\nSame task as before · Carlos, 3 days ago',
        'Where it was done',
        'Kitchen',
        'Bathroom',
        'Oven',
        'Log it',
      ]);
      handle.dispose();
    });

    _widgets('the suggestions are a list of single button nodes whose name '
        'is the visible text', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_composer(view: _view(suggestions: [_cleanKitchen, _cleanOven]))),
      );

      final list = tester.getSemantics(_suggestionsList).getSemanticsData();
      expect(list.role, SemanticsRole.list);
      expect(list.label, 'Suggestions');
      final items = _children(tester.getSemantics(_suggestionsList));
      expect(items, hasLength(2));
      for (final (i, expected) in [
        'Clean the kitchen\nSame task as before · Carlos, 3 days ago',
        'Clean the oven\nLast done 12 days ago',
      ].indexed) {
        expect(items[i].getSemanticsData().role, SemanticsRole.listItem);
        final button = _children(items[i]).single.getSemanticsData();
        expect(button.label, expected);
        expect(button.flagsCollection.isButton, isTrue);
        expect(button.hasAction(SemanticsAction.tap), isTrue);
      }
      handle.dispose();
    });

    _widgets('the chips say whether they are on', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_composer()));

      SemanticsData data(Finder chip) => tester
          .getSemantics(
            find.descendant(of: chip, matching: find.byType(FilterChip)),
          )
          .getSemanticsData();
      expect(
        data(_room('kitchen')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        data(_room('bathroom')).flagsCollection.isSelected,
        isNot(Tristate.isTrue),
      );
      expect(
        data(_item('oven')).flagsCollection.isSelected,
        isNot(Tristate.isTrue),
      );
      for (final chip in [_room('kitchen'), _room('bathroom'), _item('oven')]) {
        expect(data(chip).flagsCollection.isButton, isTrue);
        expect(data(chip).hasAction(SemanticsAction.tap), isTrue);
      }
      expect(
        tester.getSemantics(_targets).getSemanticsData().label,
        'Where it was done',
      );
      handle.dispose();
    });

    _widgets('the button is disabled without a name, and says it waits '
        'while submitting', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_composer(view: _view(query: ''))));
      var data = tester.getSemantics(_button).getSemanticsData();
      expect(data.label, 'Log it');
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);

      await tester.pumpWidget(host(_composer()));
      data = tester.getSemantics(_button).getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      await tester.pumpWidget(host(_composer(view: _view(submitting: true))));
      data = tester.getSemantics(_button).getSemanticsData();
      expect(data.label, 'Log it');
      expect(data.value, 'Logging');
      expect(data.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    _widgets('while submitting the suggestions and chips are disabled '
        'buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_composer(view: _view(submitting: true))));

      for (final finder in [
        _suggestion('clean-kitchen'),
        _room('kitchen'),
        _room('bathroom'),
        _item('oven'),
      ]) {
        final data = tester.getSemantics(finder).getSemanticsData();
        expect(data.flagsCollection.isEnabled, Tristate.isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.label, isNotEmpty);
      }
      handle.dispose();
    });

    _widgets('the semantic tap actions do what a tap does', (tester) async {
      final handle = tester.ensureSemantics();
      final calls = <String>[];
      await tester.pumpWidget(
        host(
          _composer(
            onPick: (id) => calls.add('pick $id'),
            onLink: (target) => calls.add('link ${target?.id}'),
            onSubmit: (s) => calls.add('submit ${s.name}'),
          ),
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('Bathroom'));
      tester.semantics.tap(find.semantics.byLabel('Log it'));
      tester.semantics.tap(
        find.semantics.byLabel(RegExp('^Clean the kitchen')),
      );

      expect(calls, [
        'link bathroom',
        'submit clean the kitchen',
        'pick clean-kitchen',
      ]);
      handle.dispose();
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      _widgets('the card is the surface with a hairline edge, and the '
          'suggestions are the sunken color ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            _composer(view: _view(suggestions: [_cleanKitchen, _cleanOven])),
            theme: theme,
          ),
        );

        final card =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: _composerFinder,
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(card.color, scheme.surfaceContainerLowest);
        expect((card.border! as Border).top.color, scheme.outlineVariant);
        expect(card.borderRadius, BorderRadius.circular(AppRadius.md));
        final list =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: _suggestionsList,
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(list.color, scheme.surfaceContainerHigh);
        final dividers = tester
            .widgetList<SizedBox>(
              find.descendant(
                of: _suggestionsList,
                matching: find.byType(SizedBox),
              ),
            )
            .where((box) => box.height == AppSizes.hairline)
            .toList();
        expect(dividers, hasLength(1), reason: 'between two suggestions');
        expect(
          (dividers.single.child! as ColoredBox).color,
          scheme.outlineVariant,
        );
      });

      _widgets('the title is ink and the subtitle muted ink ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(host(_composer(), theme: theme));

        Color? color(String text) =>
            tester.widget<Text>(find.text(text)).style?.color;
        expect(color('Clean the kitchen'), scheme.onSurface);
        expect(
          color('Same task as before · Carlos, 3 days ago'),
          scheme.onSurfaceVariant,
        );
      });

      _widgets('a focused suggestion draws an ink ring outside its shape '
          '($name)', (tester) async {
        await tester.pumpWidget(host(_composer(), theme: theme));

        await _focus(tester, _suggestion('clean-kitchen'));
        await tester.pumpAndSettle();

        final shape =
            tester
                    .widget<Material>(
                      find
                          .descendant(
                            of: _suggestion('clean-kitchen'),
                            matching: find.byType(Material),
                          )
                          .first,
                    )
                    .shape!
                as RoundedRectangleBorder;
        expect(
          shape.side,
          BorderSide(
            color: scheme.onSurface,
            width: AppSizes.borderEmphasis,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        );
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final row = tester
            .getRect(_suggestion('clean-kitchen'))
            .shift(-boundary);
        final ring = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: Rect.fromLTWH(
            row.left + 20,
            row.top - AppSizes.borderEmphasis,
            row.width - 40,
            AppSizes.borderEmphasis,
          ),
        );
        expect(countPixels(ring, scheme.onSurface), greaterThan(0));
      });

      test('the texts and the ring keep their contrast ($name)', () {
        expectContrast(
          {
            'title': (scheme.onSurface, scheme.surfaceContainerHigh),
            'subtitle': (scheme.onSurfaceVariant, scheme.surfaceContainerHigh),
            'label': (scheme.onSurface, scheme.surfaceContainerLowest),
            'helper': (scheme.onSurfaceVariant, scheme.surfaceContainerLowest),
          },
          minimum: 4.5,
          reason: 'the task composer ($name)',
        );
        expectContrast(
          {'focus ring': (scheme.onSurface, scheme.surfaceContainerHigh)},
          minimum: 3,
          reason: 'the focus ring of a suggestion ($name)',
        );
      });
    }

    _widgets('has no danger color and no motion of its own', (tester) async {
      await tester.pumpWidget(host(_composer()));
      final scheme = CompappTheme.light.colorScheme;

      final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
      final all = await paintedPixels(
        tester,
        hostBoundaryKey,
        region: tester.getRect(_composerFinder).shift(-boundary),
      );
      expect(countPixels(all, scheme.error), 0);
      expect(countPixels(all, scheme.errorContainer), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('large text and narrow columns', () {
    setUpAll(loadBundledFonts);

    const longQuery = 'Limpiar la cocina y también el horno de la planta baja';
    TaskComposerView longView({bool submitting = false}) => TaskComposerView(
      query: longQuery,
      suggestions: const [
        TaskSuggestion(
          id: 'a',
          title: 'Limpiar la cocina y también el horno',
          subtitle: 'Misma tarea que antes · María de los Ángeles, hace 3 días',
        ),
        TaskSuggestion(
          id: 'b',
          title: 'Limpiar el baño',
          subtitle: 'Hecha por última vez hace 12 días',
        ),
      ],
      rooms: const [
        RoomView(id: 'k', name: 'Cocina'),
        RoomView(id: 'b', name: 'Baño de invitados'),
        RoomView(id: 'l', name: 'Salón comedor'),
      ],
      items: const [
        ItemView(id: 'o', name: 'Lavavajillas', icon: AppIcons.dishwasher),
      ],
      linked: const TaskTarget(TaskTargetKind.room, 'k'),
      label: 'Registra lo que hiciste hoy en casa',
      hint: 'Por ejemplo, limpiar la cocina',
      helperText: 'Tarea nueva: se añadirá a la lista de tu casa',
      suggestionsLabel: 'Sugerencias',
      targetsLabel: 'Dónde se hizo',
      submitLabel: 'Registrar la tarea',
      submitting: submitting,
      loadingLabel: 'Registrando',
    );

    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.3, 1.5, 2.0]) {
        for (final direction in TextDirection.values) {
          _widgets('width $width, ${scale}x, ${direction.name}: no overflow, '
              'nothing clipped, no word cut', (tester) async {
            await tester.pumpWidget(
              host(
                _composer(view: longView()),
                width: width,
                textScale: scale,
                direction: direction,
              ),
            );

            final reason = 'at $width, ${scale}x, ${direction.name}';
            expect(tester.takeException(), isNull, reason: reason);
            final card = tester.getRect(_composerFinder);
            expect(card.width, width, reason: reason);
            for (final finder in [
              _input,
              _suggestionsList,
              _targets,
              _submit,
              _suggestion('a'),
              _suggestion('b'),
              _room('k'),
              _room('b'),
              _room('l'),
              _item('o'),
            ]) {
              final rect = tester.getRect(finder);
              expect(
                rect.left,
                greaterThanOrEqualTo(card.left),
                reason: reason,
              );
              expect(rect.right, lessThanOrEqualTo(card.right), reason: reason);
              expect(
                rect.bottom,
                lessThanOrEqualTo(card.bottom),
                reason: reason,
              );
            }
            for (final (finder, bold) in [
              (find.text('Registra lo que hiciste hoy en casa'), false),
              (find.text('Limpiar la cocina y también el horno'), false),
              (
                find.text(
                  'Misma tarea que antes · María de los Ángeles, hace 3 días',
                ),
                false,
              ),
              (
                find.text('Tarea nueva: se añadirá a la lista de tu casa'),
                false,
              ),
            ]) {
              expectNoMidWordBreaks(tester, finder, bold: bold, reason: reason);
            }
            for (final id in ['a', 'b']) {
              expect(
                tester.getSize(_suggestion(id)).height,
                greaterThanOrEqualTo(AppSizes.controlLg),
                reason: reason,
              );
              for (final text in tester.widgetList<Text>(
                find.descendant(
                  of: _suggestion(id),
                  matching: find.byType(Text),
                ),
              )) {
                expect(text.overflow, isNull, reason: 'no ellipsis, $reason');
                expect(text.maxLines, isNull);
              }
            }
            for (final chip in [
              _room('k'),
              _room('b'),
              _room('l'),
              _item('o'),
            ]) {
              expect(
                tester.getSize(chip).height,
                greaterThanOrEqualTo(AppSizes.minDrawn),
                reason: reason,
              );
              expectNoMidWordBreaks(
                tester,
                find.descendant(of: chip, matching: find.byType(Text)),
                reason: reason,
              );
            }
          });
        }
      }
    }

    _widgets('the chips wrap onto more lines as the text grows', (
      tester,
    ) async {
      int lines(Finder _) => {
        for (final chip in [_room('k'), _room('b'), _room('l'), _item('o')])
          tester.getTopLeft(chip).dy,
      }.length;

      await tester.pumpWidget(host(_composer(view: longView())));
      final base = lines(_targets);
      await tester.pumpWidget(host(_composer(view: longView()), textScale: 2));

      expect(lines(_targets), greaterThan(base));
      expect(tester.takeException(), isNull);
    });

    _widgets('text is scaled, never clamped, and the composer grows', (
      tester,
    ) async {
      await tester.pumpWidget(host(_composer(view: longView())));
      final base = tester.getSize(_composerFinder).height;
      final baseTitle = tester.getSize(find.text('Limpiar el baño')).height;

      await tester.pumpWidget(host(_composer(view: longView()), textScale: 2));

      expect(tester.getSize(_composerFinder).height, greaterThan(base));
      expect(
        tester.getSize(find.text('Limpiar el baño')).height,
        greaterThanOrEqualTo(baseTitle * 2 - 1),
      );
    });

    _widgets('mirrors in right-to-left: the first chip at the right, the '
        'texts start at the right', (tester) async {
      await tester.pumpWidget(
        host(_composer(view: longView()), direction: TextDirection.rtl),
      );

      expect(
        tester.getTopRight(_room('k')).dx,
        greaterThan(tester.getTopRight(_room('b')).dx - 1),
      );
      final card = tester.getRect(_composerFinder);
      expect(
        card.right - tester.getRect(find.text('Limpiar el baño')).right,
        lessThan(tester.getRect(find.text('Limpiar el baño')).left - card.left),
        reason: 'the title hugs the start edge, the right',
      );
    });

    _widgets('submitting at large text keeps the whole form and the '
        'spinner', (tester) async {
      await tester.pumpWidget(
        host(_composer(view: longView(submitting: true)), textScale: 2),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<AppButton>(_submit).loading, isTrue);
      expectNoMidWordBreaks(
        tester,
        find.descendant(of: _submit, matching: find.text('Registrar la tarea')),
      );
    });

    _widgets('fits when its width is unbounded by an intrinsic parent', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 340,
                child: IntrinsicHeight(child: _composer(view: longView())),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('identity and focus across updates', () {
    _widgets('the field keeps its element, its focus and its caret while the '
        'suggestions and the chips come and go', (tester) async {
      await tester.pumpWidget(
        host(
          _composer(
            view: _view(
              query: 'cle',
              suggestions: const [],
              rooms: const [],
              items: const [],
              linked: null,
            ),
          ),
        ),
      );
      await tester.tap(_input);
      await tester.pump();
      final field = tester.element(_field);
      final focus = FocusManager.instance.primaryFocus;
      final controller = tester.widget<TextField>(_input).controller!
        ..selection = const TextSelection.collapsed(offset: 1);
      expect(focus, isNotNull);

      for (final withSections in [true, false, true]) {
        await tester.pumpWidget(
          host(
            _composer(
              view: _view(
                query: 'cle',
                suggestions: withSections ? [_cleanKitchen] : const [],
                rooms: withSections
                    ? const [RoomView(id: 'kitchen', name: 'Kitchen')]
                    : const [],
                items: const [],
                linked: null,
              ),
            ),
          ),
        );

        expect(tester.element(_field), same(field));
        expect(FocusManager.instance.primaryFocus, same(focus));
        expect(controller.selection, const TextSelection.collapsed(offset: 1));
      }
    });

    _widgets('the suggestions are keyed by id, not by position', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_composer(view: _view(suggestions: [_cleanKitchen, _cleanOven]))),
      );
      final kitchen = tester.element(_suggestion('clean-kitchen'));
      final oven = tester.element(_suggestion('clean-oven'));

      await tester.pumpWidget(
        host(_composer(view: _view(suggestions: [_cleanOven, _cleanKitchen]))),
      );

      expect(
        tester.getTopLeft(_suggestion('clean-oven')).dy,
        lessThan(tester.getTopLeft(_suggestion('clean-kitchen')).dy),
      );
      expect(tester.element(_suggestion('clean-kitchen')), same(kitchen));
      expect(tester.element(_suggestion('clean-oven')), same(oven));
    });

    _widgets('a focused suggestion keeps focus and its node when another '
        'one appears before it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_composer(view: _view(suggestions: [_cleanKitchen]))),
      );
      await _focus(tester, _suggestion('clean-kitchen'));
      final focus = FocusManager.instance.primaryFocus;
      final node = tester.getSemantics(_suggestion('clean-kitchen')).id;

      await tester.pumpWidget(
        host(_composer(view: _view(suggestions: [_cleanOven, _cleanKitchen]))),
      );

      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(tester.getSemantics(_suggestion('clean-kitchen')).id, node);
      handle.dispose();
    });

    _widgets('a focused chip keeps focus when the link moves and when the '
        'suggestions leave', (tester) async {
      await tester.pumpWidget(host(_composer()));
      await _focus(tester, _room('bathroom'));
      final focus = FocusManager.instance.primaryFocus;
      final chip = tester.element(_room('bathroom'));

      await tester.pumpWidget(
        host(
          _composer(
            view: _view(
              linked: const TaskTarget(TaskTargetKind.room, 'bathroom'),
              suggestions: const [],
            ),
          ),
        ),
      );

      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(tester.element(_room('bathroom')), same(chip));
      expect(_chip(tester, _room('bathroom')).selected, isTrue);
    });

    _widgets('the button keeps its element and focus when it starts to wait', (
      tester,
    ) async {
      await tester.pumpWidget(host(_composer()));
      await _focus(tester, _submit);
      final focus = FocusManager.instance.primaryFocus;
      final button = tester.element(_submit);

      await tester.pumpWidget(host(_composer(view: _view(submitting: true))));

      expect(tester.element(_submit), same(button));
      expect(FocusManager.instance.primaryFocus, same(focus));
    });
  });

  group('motion', () {
    _widgets('has none of its own while it is not waiting', (tester) async {
      await tester.pumpWidget(host(_composer()));

      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    _widgets('the spinner stands still when motion is reduced', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(_composer(view: _view(submitting: true))),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}

/// Moves keyboard focus to the control under [finder] with Tab.
Future<void> _focus(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context != null &&
        find
            .descendant(of: finder, matching: find.byWidget(context.widget))
            .evaluate()
            .isNotEmpty) {
      return;
    }
    if (context != null &&
        (context.findAncestorWidgetOfExactType<TextButton>()?.key ==
                finder.evaluate().first.widget.key ||
            context.findAncestorWidgetOfExactType<AppChip>()?.key ==
                finder.evaluate().first.widget.key ||
            context.findAncestorWidgetOfExactType<AppButton>()?.key ==
                finder.evaluate().first.widget.key)) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('focus never reached $finder');
}

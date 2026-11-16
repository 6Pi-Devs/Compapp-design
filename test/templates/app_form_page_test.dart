import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart' show themes;
import '../helpers/bundled_fonts.dart';
import '../helpers/host.dart' show semanticsNodes;

const _title = 'Home settings';
const _spanishTitle = 'Ajustes de la casa compartida, con sus habitaciones';

final Finder _back = find.byKey(const Key('topBar.back'));
final Finder _submit = find.byKey(const Key('formPage.submit'));
final Finder _fields = find.byKey(const Key('formPage.fields'));
final Finder _heading = find.byKey(const Key('topBar.title'));
final Finder _button = find.descendant(
  of: _submit,
  matching: find.byType(FilledButton),
);

/// [count] fields named "Field 0", "Field 1" and so on, with their controllers.
List<AppTextField> _textFields(
  WidgetTester tester,
  int count, {
  String prefix = 'Field',
}) {
  return [
    for (var i = 0; i < count; i++)
      AppTextField(
        key: Key('test.field.$i'),
        label: '$prefix $i',
        controller: _controller(tester),
      ),
  ];
}

TextEditingController _controller(WidgetTester tester) {
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  return controller;
}

AppFormPage _page({
  required List<Widget> fields,
  String title = _title,
  String backLabel = 'Back',
  VoidCallback? onBack,
  String submitLabel = 'Save',
  VoidCallback? onSubmit,
  bool submitting = false,
  String? submittingLabel,
  bool disabled = false,
}) => AppFormPage(
  title: title,
  backLabel: backLabel,
  onBack: onBack ?? () {},
  fields: fields,
  submitLabel: submitLabel,
  onSubmit: disabled ? null : onSubmit ?? () {},
  submitting: submitting,
  submittingLabel: submittingLabel,
);

/// Shows [page] as the home of an app on a screen of [size], with the keyboard
/// and the home indicator the way a phone reports them: while the keyboard is
/// up the bottom padding is already taken out.
Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(320, 568),
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  double keyboard = 0,
  double homeIndicator = 0,
  double statusBar = 0,
  ThemeData? theme,
  bool settle = true,
}) async {
  final padding = keyboard > 0 ? 0.0 : homeIndicator;
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..padding = FakeViewPadding(top: statusBar, bottom: padding)
    ..viewPadding = FakeViewPadding(top: statusBar, bottom: homeIndicator)
    ..viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? CompappTheme.light,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
      ),
      home: page,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A spinner never settles.
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Which part has the focus: "back", "submit", the label of a field or other.
String _focused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return 'none';
  String? found;
  (context as Element).visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is AppTextField) {
      found = widget.label;
    } else if (widget.key == const Key('topBar.back')) {
      found = 'back';
    } else if (widget.key == const Key('formPage.submit')) {
      found = 'submit';
    }
    return found == null;
  });
  return found ?? 'other';
}

Future<void> _tab(WidgetTester tester, {bool shift = false}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBundledFonts);

  group('content and callbacks', () {
    testWidgets('stacks the bar, the fields in order and the button', (
      tester,
    ) async {
      await _pump(
        tester,
        _page(fields: _textFields(tester, 3)),
        size: const Size(360, 640),
      );

      expect(find.text(_title), findsOneWidget);
      final tops = [
        for (var i = 0; i < 3; i++)
          tester.getTopLeft(find.byKey(Key('test.field.$i'))).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(tester.getTopLeft(_heading).dy, lessThan(tops.first));
      expect(
        tester.getTopLeft(_submit).dy,
        greaterThan(
          tester.getRect(find.byKey(const Key('test.field.2'))).bottom,
        ),
      );
      expect(
        tester.getRect(_submit).bottom,
        640 - AppSpacing.md,
        reason: 'the button sits at the bottom of the screen',
      );
      expect(tester.getSize(_submit).width, 360 - 2 * AppSpacing.md);
      expect(
        tester.getSize(find.byKey(const Key('test.field.0'))).width,
        360 - 2 * AppSpacing.md,
        reason: 'the fields are as wide as the page allows',
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('test.field.1'))).dy -
            tester.getRect(find.byKey(const Key('test.field.0'))).bottom,
        AppSpacing.md,
        reason: 'the fields are 16 apart',
      );
    });

    testWidgets('the back button and the submit button call the app', (
      tester,
    ) async {
      var back = 0;
      var submitted = 0;
      await _pump(
        tester,
        _page(
          fields: _textFields(tester, 1),
          onBack: () => back++,
          onSubmit: () => submitted++,
        ),
      );

      await tester.tap(_back);
      await tester.tap(_submit);
      await tester.tap(_submit);

      expect((back, submitted), (1, 2));
    });

    testWidgets('a null onSubmit disables the button', (tester) async {
      await _pump(
        tester,
        _page(fields: _textFields(tester, 1), disabled: true),
      );

      expect(tester.widget<FilledButton>(_button).onPressed, isNull);
    });

    testWidgets('while submitting the button waits and says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var submitted = 0;
      await _pump(
        tester,
        _page(
          fields: _textFields(tester, 1),
          submitting: true,
          submittingLabel: 'Saving',
          onSubmit: () => submitted++,
        ),
        settle: false,
      );

      await tester.tap(_submit, warnIfMissed: false);
      expect(submitted, 0);
      final node = tester.getSemantics(_button);
      expect(node.label, 'Save');
      expect(node.value, 'Saving');
      handle.dispose();
    });

    testWidgets('rejects empty words', (tester) async {
      expect(() => _page(fields: const [], title: ''), throwsAssertionError);
      expect(
        () => _page(fields: const [], backLabel: ''),
        throwsAssertionError,
      );
      expect(
        () => _page(fields: const [], submitLabel: ''),
        throwsAssertionError,
      );
      expect(
        () => _page(fields: const [], submittingLabel: ''),
        throwsAssertionError,
      );
    });

    testWidgets('draws the page of the theme with a line above the button', (
      tester,
    ) async {
      for (final (name, theme) in themes) {
        await _pump(
          tester,
          _page(fields: _textFields(tester, 1)),
          theme: theme,
        );
        final bar = tester.widget<DecoratedBox>(
          find.ancestor(of: _submit, matching: find.byType(DecoratedBox)).first,
        );
        final decoration = bar.decoration as BoxDecoration;

        expect(decoration.color, theme.colorScheme.surface, reason: name);
        expect(
          decoration.border,
          Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
          reason: name,
        );
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          isNull,
          reason: 'the page color is the theme scaffold color',
        );
      }
    });
  });

  group('safe areas', () {
    testWidgets('the bar takes the status bar and the button the indicator', (
      tester,
    ) async {
      await _pump(
        tester,
        _page(fields: _textFields(tester, 1)),
        size: const Size(360, 640),
        statusBar: 24,
        homeIndicator: 34,
      );

      expect(tester.getRect(_back).top, greaterThan(24));
      expect(
        tester.getRect(_submit).bottom,
        640 - AppSpacing.md - 34,
        reason: 'above the home indicator',
      );
    });
  });

  group('the keyboard', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('at $scale the button rides above the keyboard and the '
          'fields are reached by scrolling', (tester) async {
        var submitted = 0;
        await _pump(
          tester,
          _page(fields: _textFields(tester, 8), onSubmit: () => submitted++),
          textScale: scale,
          keyboard: 250,
          homeIndicator: 34,
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(_submit).bottom,
          568 - 250 - AppSpacing.md,
          reason:
              'directly above the keyboard, with no room for the '
              'indicator the keyboard covers',
        );
        expect(tester.getRect(_submit).top, greaterThan(0));
        final last = find.byKey(const Key('test.field.7'));
        expect(tester.getRect(last).top, greaterThan(568 - 250));

        await tester.ensureVisible(last);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(last).bottom,
          lessThanOrEqualTo(tester.getRect(_submit).top),
        );
        await tester.tap(_submit);
        expect(submitted, 1);
      });
    }

    testWidgets('at 2.0 with the keyboard up the bar scrolls away with the '
        'fields so they keep the room', (tester) async {
      await _pump(
        tester,
        _page(
          fields: _textFields(tester, 8, prefix: 'Campo'),
          title: _spanishTitle,
        ),
        textScale: 2,
        keyboard: 250,
      );

      expect(tester.takeException(), isNull);
      final room = tester.getRect(_submit).top;
      final bar = tester.getRect(find.byType(AppTopBar)).height;
      expect(bar, greaterThan(room / 2), reason: 'the bar is the tall part');
      final field = find.byKey(const Key('test.field.0'));
      final before = tester.getTopLeft(field).dy;
      await tester.dragFrom(const Offset(160, 150), const Offset(0, -80));
      await tester.pump();

      expect(tester.getTopLeft(_heading).dy, lessThan(0.1));
      expect(tester.getTopLeft(field).dy, lessThan(before));
      await tester.ensureVisible(find.byKey(const Key('test.field.7')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a focused field is scrolled above the button', (tester) async {
      await _pump(tester, _page(fields: _textFields(tester, 8)), keyboard: 250);
      final last = find.byKey(const Key('test.field.7'));

      await tester.tap(last, warnIfMissed: false);
      await tester.showKeyboard(
        find.descendant(of: last, matching: find.byType(TextField)),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(last).bottom,
        lessThanOrEqualTo(tester.getRect(_submit).top),
      );
    });

    testWidgets('the bar stays pinned while there is room', (tester) async {
      await _pump(
        tester,
        _page(fields: _textFields(tester, 12)),
        size: const Size(360, 640),
      );
      final top = tester.getTopLeft(_heading).dy;

      await tester.dragFrom(const Offset(180, 300), const Offset(0, -300));
      await tester.pump();

      expect(tester.getTopLeft(_heading).dy, top);
      expect(
        tester.getTopLeft(find.byKey(const Key('test.field.0'))).dy,
        lessThan(top),
        reason: 'the fields scrolled under the bar',
      );
    });
  });

  group('focus', () {
    testWidgets('Tab goes back, the fields in order, then the button, also '
        'for the fields out of sight', (tester) async {
      await _pump(tester, _page(fields: _textFields(tester, 10)), textScale: 2);
      final last = find.byKey(const Key('test.field.9'));
      expect(tester.getRect(last).top, greaterThan(568));

      final order = <String>[];
      for (var i = 0; i < 12; i++) {
        await _tab(tester);
        order.add(_focused());
      }

      expect(order, [
        'back',
        for (var i = 0; i < 10; i++) 'Field $i',
        'submit',
      ]);

      await _tab(tester, shift: true);
      expect(_focused(), 'Field 9');
    });

    testWidgets('the page never takes focus by itself', (tester) async {
      await _pump(tester, _page(fields: _textFields(tester, 3)));

      expect(_focused(), anyOf('none', 'other'));
    });

    testWidgets('the fields keep their text and focus when the page '
        'submits', (tester) async {
      final fields = _textFields(tester, 2);
      await _pump(tester, _page(fields: fields));
      await tester.enterText(find.byType(TextField).first, 'Casa Luna');
      expect(_focused(), 'Field 0');

      await _pump(
        tester,
        _page(fields: fields, submitting: true, submittingLabel: 'Saving'),
        settle: false,
      );

      expect(_focused(), 'Field 0');
      expect(find.text('Casa Luna'), findsOneWidget);
    });

    testWidgets('new fields do not disturb the focus of the others', (
      tester,
    ) async {
      final fields = _textFields(tester, 3);
      await _pump(tester, _page(fields: fields.take(2).toList()));
      await tester.tap(find.byType(TextField).last);
      await tester.pump();
      expect(_focused(), 'Field 1');

      await _pump(tester, _page(fields: fields));

      expect(_focused(), 'Field 1');
      expect(find.byType(TextField), findsNWidgets(3));
    });
  });

  group('text scale, width and direction', () {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final width in [320.0, 360.0]) {
        for (final direction in TextDirection.values) {
          testWidgets('at $scale and $width wide in $direction the Spanish '
              'page wraps and nothing is clipped', (tester) async {
            await _pump(
              tester,
              _page(
                title: _spanishTitle,
                backLabel: 'Atrás',
                submitLabel: 'Guardar los cambios de la casa',
                fields: _textFields(tester, 4, prefix: 'Nombre del campo'),
              ),
              size: Size(width, 568),
              textScale: scale,
              direction: direction,
            );

            expect(tester.takeException(), isNull);
            final screen = Offset.zero & Size(width, 568);
            for (final finder in [_back, _submit, _heading]) {
              final rect = tester.getRect(finder);
              expect(rect.left, greaterThanOrEqualTo(0), reason: '$finder');
              expect(rect.right, lessThanOrEqualTo(width), reason: '$finder');
            }
            expect(screen.contains(tester.getRect(_submit).center), isTrue);
            expect(
              tester.getRect(_submit).bottom,
              568 - AppSpacing.md,
              reason:
                  'the button is always at the bottom, reached without '
                  'scrolling',
            );
            expect(
              tester.getSize(_submit).height,
              greaterThanOrEqualTo(AppSizes.minTarget),
            );
            expect(tester.getSize(_back).width, greaterThanOrEqualTo(44));
            final back = tester.getRect(_back);
            expect(
              direction == TextDirection.ltr
                  ? back.left < width / 2
                  : back.right > width / 2,
              isTrue,
              reason: 'the back button is at the start',
            );
          });
        }
      }
    }
  });

  group('as a route', () {
    testWidgets('names the route once, by the title, and scopes it once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const Key('open'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => _page(fields: _textFields(tester, 2)),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      final title = tester.getSemantics(_heading);
      final routes = <SemanticsNode>[];
      for (SemanticsNode? node = title; node != null; node = node.parent) {
        if (node.getSemanticsData().flagsCollection.scopesRoute) {
          routes.add(node);
        }
      }
      expect(routes, hasLength(1));
      final namers = <String>[];
      void visit(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.flagsCollection.namesRoute) namers.add(data.label);
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(routes.single);
      expect(namers, [_title]);
      handle.dispose();
    });
  });

  group('focus order stays out of the fields', () {
    testWidgets('an order a field sets inside the page stays local', (
      tester,
    ) async {
      final fields = _textFields(tester, 3);
      await _pump(
        tester,
        _page(
          fields: [
            fields[0],
            FocusTraversalOrder(
              order: const NumericFocusOrder(5),
              child: fields[1],
            ),
            fields[2],
          ],
        ),
      );

      final order = <String>[];
      for (var i = 0; i < 5; i++) {
        await _tab(tester);
        order.add(_focused());
      }

      expect(order, ['back', 'Field 0', 'Field 1', 'Field 2', 'submit']);
    });

    testWidgets('a group with its own policy orders only its own fields', (
      tester,
    ) async {
      final fields = _textFields(tester, 3);
      await _pump(
        tester,
        _page(
          fields: [
            fields[0],
            FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: fields[1],
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: fields[2],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final order = <String>[];
      for (var i = 0; i < 5; i++) {
        await _tab(tester);
        order.add(_focused());
      }

      expect(order, ['back', 'Field 0', 'Field 2', 'Field 1', 'submit']);
    });
  });

  group('when the button is disabled while it has focus', () {
    Future<void> focusSubmit(
      WidgetTester tester,
      List<AppTextField> fields,
    ) async {
      await _pump(tester, _page(fields: fields));
      for (var i = 0; i < 4; i++) {
        await _tab(tester);
      }
      expect(_focused(), 'submit');
    }

    testWidgets('a keyboard user goes to the back button, not to a field', (
      tester,
    ) async {
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final fields = _textFields(tester, 2);
      await focusSubmit(tester, fields);

      await _pump(tester, _page(fields: fields, disabled: true));

      expect(_focused(), 'back');
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('otherwise nothing is focused and the keyboard stays shut', (
      tester,
    ) async {
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final fields = _textFields(tester, 2);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await focusSubmit(tester, fields);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;

      await _pump(tester, _page(fields: fields, disabled: true));

      expect(_focused(), anyOf('none', 'other'));
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('a button that is disabled because it is submitting keeps '
        'its focus', (tester) async {
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final fields = _textFields(tester, 2);
      await focusSubmit(tester, fields);

      await _pump(
        tester,
        _page(fields: fields, disabled: true, submitting: true),
        settle: false,
      );

      expect(_focused(), 'submit');
    });

    testWidgets('a button that was already disabled hands nothing over', (
      tester,
    ) async {
      final fields = _textFields(tester, 2);
      await _pump(tester, _page(fields: fields, disabled: true));
      await tester.tap(find.byType(TextField).last);
      await tester.pump();
      expect(_focused(), 'Field 1');

      await _pump(tester, _page(fields: fields, disabled: true));

      expect(_focused(), 'Field 1');
    });

    testWidgets('a form needs a field', (tester) async {
      await _pump(tester, _page(fields: const []));

      expect(tester.takeException(), isAssertionError);
    });
  });

  group('SnackBars', () {
    for (final keyboard in [0.0, 250.0]) {
      testWidgets('a SnackBar sits above the button, keyboard $keyboard', (
        tester,
      ) async {
        await _pump(
          tester,
          _page(fields: _textFields(tester, 2)),
          keyboard: keyboard,
        );
        ScaffoldMessenger.of(tester.element(find.byType(AppFormPage)))
            .showSnackBar(const SnackBar(content: Text('Saved')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final snack = tester.getRect(find.byType(SnackBar));
        expect(snack.bottom, lessThanOrEqualTo(tester.getRect(_submit).top));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('semantics', () {
    testWidgets('a heading, a form of fields and a button, in that order', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _page(fields: _textFields(tester, 2)));

      final labels = [
        for (final node in semanticsNodes(tester))
          if (node.label.isNotEmpty) node.label,
      ];
      final ours = labels
          .where(
            (label) => const {
              _title,
              'Back',
              'Field 0',
              'Field 1',
              'Save',
            }.contains(label),
          )
          .toList();
      expect(ours.sublist(2), ['Field 0', 'Field 1', 'Save']);
      expect(ours.take(2), unorderedEquals([_title, 'Back']));
      final form = tester.getSemantics(_fields);
      expect(form.getSemanticsData().role, SemanticsRole.form);
      final texts = <String>[];
      void collect(SemanticsNode node) {
        if (node.label.isNotEmpty) texts.add(node.label);
        node.visitChildren((child) {
          collect(child);
          return true;
        });
      }

      collect(form);
      expect(texts, [
        'Field 0',
        'Field 1',
      ], reason: 'the form group holds the fields and nothing else');
      expect(
        tester
            .getSemantics(_heading)
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      handle.dispose();
    });
  });

  group('the form group', () {
    testWidgets('keeps its fields as nodes of their own', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _page(fields: const [Text('One'), Text('Two'), Text('Three')]),
      );

      final form = tester.getSemantics(_fields);
      final nodes = <SemanticsNode>[];
      void collect(SemanticsNode node) {
        if (node.label.isNotEmpty) nodes.add(node);
        node.visitChildren((child) {
          collect(child);
          return true;
        });
      }

      collect(form);
      expect([for (final node in nodes) node.label], ['One', 'Two', 'Three']);
      expect(form.getSemanticsData().role, SemanticsRole.form);
      expect(
        form.label,
        isEmpty,
        reason: 'the group does not merge its fields',
      );
      handle.dispose();
    });
  });
}

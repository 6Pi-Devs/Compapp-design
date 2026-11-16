import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart';
import '../helpers/bundled_fonts.dart';
import '../helpers/host.dart' show semanticsNodes;
import '../helpers/painted_color.dart';

const _title = 'Archive the Study?';
const _spanishTitle =
    '¿Archivar la habitación de estudio, que sigue contando para el límite?';
const _bodyText =
    'Archived rooms can be restored by the admin. They still count toward '
    'the room limit.';
const _spanishBody =
    'Las habitaciones archivadas se pueden restaurar. Siguen contando para '
    'el límite de habitaciones, así que no liberan sitio.';

final Finder _root = find.byType(AppSheet);

/// The painted sheet, without the room left for the keyboard under it.
final Finder _sheet = find
    .descendant(of: _root, matching: find.byType(DecoratedBox))
    .first;
final Finder _titleText = find.byKey(const Key('sheet.title'));
final Finder _close = find.byKey(const Key('sheet.close'));
final Finder _body = find.byKey(const Key('appSheet.body'));
final Finder _actions = find.byKey(const Key('appSheet.actions'));
final Finder _primary = find.byKey(const Key('test.primary'));
final Finder _secondary = find.byKey(const Key('test.secondary'));
final Finder _field = find.byType(TextField);

List<AppButton> _buttons({
  VoidCallback? onPrimary,
  VoidCallback? onSecondary,
  String primary = 'Archive room',
  String secondary = 'Keep room',
}) => [
  AppButton(
    key: const Key('test.primary'),
    label: primary,
    onPressed: onPrimary ?? () {},
  ),
  AppButton(
    key: const Key('test.secondary'),
    label: secondary,
    variant: AppButtonVariant.ghost,
    onPressed: onSecondary ?? () {},
  ),
];

AppSheet _app({
  String title = _title,
  String closeLabel = 'Close',
  String body = _bodyText,
  Widget? bodyWidget,
  List<AppButton>? actions,
  VoidCallback? onClose,
}) => AppSheet(
  title: title,
  closeLabel: closeLabel,
  onClose: onClose ?? () {},
  body: bodyWidget ?? Text(body),
  actions: actions ?? _buttons(),
);

/// Puts [sheet] in a host as tall as it needs, so only the sheet is measured.
Future<void> _pump(
  WidgetTester tester,
  Widget sheet, {
  ThemeData? theme,
  double width = 360,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view
    ..physicalSize = const Size(800, 4000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    barHost(
      sheet,
      theme: theme,
      width: width,
      textScale: textScale,
      direction: direction,
      padding: padding,
    ),
  );
  await tester.pump();
}

/// Shows [sheet] in the real route, on a screen of [size].
Future<void> _openModal(
  WidgetTester tester,
  Widget Function() sheet, {
  Size size = const Size(320, 568),
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  double topPadding = 0,
  double bottomPadding = 0,
  double keyboard = 0,
  bool scrollControlled = true,
  bool useSafeArea = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..padding = FakeViewPadding(top: topPadding, bottom: bottomPadding)
    ..viewPadding = FakeViewPadding(
      top: topPadding,
      bottom: bottomPadding + keyboard,
    )
    ..viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: CompappTheme.light,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key('open'),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: scrollControlled,
              useSafeArea: useSafeArea,
              backgroundColor: Colors.transparent,
              builder: (_) => sheet(),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

/// Where focus is: the title, the close button, the body, an action or other.
String _focused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return 'none';
  final element = context as Element;
  bool within(Finder finder) {
    var found = false;
    element.visitAncestorElements((ancestor) {
      found = finder.evaluate().contains(ancestor);
      return !found;
    });
    return found;
  }

  if (find
      .ancestor(of: _titleText, matching: find.byType(Focus))
      .evaluate()
      .contains(element)) {
    return 'title';
  }
  if (within(_close)) return 'close';
  if (within(_primary)) return 'primary';
  if (within(_secondary)) return 'secondary';
  if (within(_body)) return 'body';
  return 'other';
}

Future<void> _tab(WidgetTester tester, {bool shift = false}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

/// A body of [lines] paragraphs, tall enough to scroll on a short screen.
Widget _tallBody(int lines, {String text = _bodyText}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: AppSpacing.sm,
  children: [
    for (var i = 0; i < lines; i++) Text(text, key: Key('test.line.$i')),
  ],
);

void main() {
  setUpAll(loadBundledFonts);

  group('content', () {
    testWidgets('stacks the title, the body and the actions in order', (
      tester,
    ) async {
      await _pump(tester, _app());

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_bodyText), findsOneWidget);
      expect(
        tester.getTopLeft(_titleText).dy,
        lessThan(tester.getTopLeft(_body).dy),
      );
      expect(
        tester.getTopLeft(_body).dy,
        lessThan(tester.getTopLeft(_actions).dy),
      );
      expect(
        tester.getTopLeft(_primary).dy,
        lessThan(tester.getTopLeft(_secondary).dy),
        reason: 'the actions keep the order they were given',
      );
      expect(
        tester.getTopLeft(_actions).dy - tester.getRect(_body).bottom,
        12,
        reason: 'the body and the actions are 12 apart',
      );
      expect(
        tester.getTopLeft(_secondary).dy - tester.getRect(_primary).bottom,
        AppSpacing.sm,
      );
      expect(tester.getSize(_primary).width, closeTo(360 - 2 * 16, 0.01));
      expect(
        tester.getSize(_secondary).width,
        tester.getSize(_primary).width,
        reason: 'the actions are as wide as the sheet allows',
      );
    });

    testWidgets('leaves the actions out when there are none', (tester) async {
      await _pump(tester, _app(actions: const []));

      expect(_actions, findsNothing);
      expect(_body, findsOneWidget);
    });

    testWidgets('draws the sheet surface of the theme, light and dark', (
      tester,
    ) async {
      for (final (name, theme) in themes) {
        await _pump(tester, _app(), theme: theme);
        await tester.pumpAndSettle();
        final surface = tester.widget<DecoratedBox>(_sheet);
        final decoration = surface.decoration as BoxDecoration;

        expect(
          decoration.color,
          theme.colorScheme.surfaceContainerLowest,
          reason: name,
        );
        expect(
          decoration.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        );
        expect(decoration.boxShadow, AppShadows.sheet);
        final painted = await paintedColorAt(
          tester,
          barBoundaryKey,
          Offset(
            180,
            tester.getRect(_actions).bottom -
                tester.getTopLeft(find.byKey(barBoundaryKey)).dy +
                4,
          ),
        );
        expect(painted, theme.colorScheme.surfaceContainerLowest, reason: name);
      }
    });

    testWidgets('rejects an empty title and an empty close label', (
      tester,
    ) async {
      expect(() => _app(title: ''), throwsAssertionError);
      expect(() => _app(closeLabel: ''), throwsAssertionError);
    });
  });

  group('callbacks', () {
    testWidgets('the close button calls onClose', (tester) async {
      var closed = 0;
      await _pump(tester, _app(onClose: () => closed++));

      await tester.tap(_close);

      expect(closed, 1);
    });

    testWidgets('Escape calls onClose while focus is inside the sheet', (
      tester,
    ) async {
      var closed = 0;
      await _pump(tester, _app(onClose: () => closed++));
      expect(_focused(), 'title');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      expect(closed, 1);
    });

    testWidgets('Escape in a field of the body also closes', (tester) async {
      var closed = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        _app(
          bodyWidget: AppTextField(label: 'Name', controller: controller),
          onClose: () => closed++,
        ),
      );
      await tester.tap(_field);
      await tester.pump();
      expect(_focused(), 'body');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      expect(closed, 1);
    });

    testWidgets('the actions call their own callbacks', (tester) async {
      var primary = 0;
      var secondary = 0;
      await _pump(
        tester,
        _app(
          actions: _buttons(
            onPrimary: () => primary++,
            onSecondary: () => secondary++,
          ),
        ),
      );

      await tester.tap(_secondary);
      await tester.tap(_primary);
      await tester.tap(_primary);

      expect((primary, secondary), (2, 1));
    });
  });

  group('focus', () {
    testWidgets('starts on the title once the sheet has been laid out', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 4000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(barHost(_app()));
      expect(_focused(), 'title', reason: 'asked for after the first frame');
    });

    testWidgets('Tab reaches the close button, the body, then the actions', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        _app(
          bodyWidget: AppTextField(label: 'Name', controller: controller),
        ),
      );

      final order = <String>[_focused()];
      for (var i = 0; i < 4; i++) {
        await _tab(tester);
        order.add(_focused());
      }

      expect(order, ['title', 'close', 'body', 'primary', 'secondary']);

      await _tab(tester, shift: true);
      expect(_focused(), 'primary');
    });

    testWidgets('a new view never takes focus back', (tester) async {
      await _pump(tester, _app());
      await _tab(tester);
      expect(_focused(), 'close');

      await tester.pumpWidget(
        barHost(_app(title: 'Restore the Study?', body: 'Something else.')),
      );
      await tester.pump();

      expect(_focused(), 'close');
    });

    testWidgets('the body keeps its text and focus when the actions come', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final field = AppTextField(
        key: const Key('test.name'),
        label: 'Name',
        controller: controller,
      );
      await _pump(tester, _app(bodyWidget: field, actions: const []));
      await tester.enterText(_field, 'Study');
      await tester.pump();
      expect(_focused(), 'body');

      await tester.pumpWidget(barHost(_app(bodyWidget: field)));
      await tester.pump();

      expect(_focused(), 'body');
      expect(controller.text, 'Study');
      expect(_primary, findsOneWidget);
    });

    testWidgets('the actions keep their focus when the body changes', (
      tester,
    ) async {
      await _pump(tester, _app());
      await _tab(tester, shift: true);
      expect(_focused(), 'secondary', reason: 'back from the title wraps');

      await tester.pumpWidget(barHost(_app(body: 'A different body.')));
      await tester.pump();

      expect(find.text('A different body.'), findsOneWidget);
      expect(_focused(), 'secondary');
    });

    testWidgets('a sheet removed before its first frame asks for nothing', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 4000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(barHost(_app()));
      await tester.pumpWidget(barHost(const SizedBox()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the title shows the house focus ring with a keyboard', (
      tester,
    ) async {
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      await _pump(tester, _app());
      expect(_focused(), 'title');
      expect(find.byKey(const Key('sheet.titleRing')), findsNothing);

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();

      expect(find.byKey(const Key('sheet.titleRing')), findsOneWidget);
    });
  });

  group('safe areas and the keyboard', () {
    testWidgets('leaves the bottom inset under the last action', (
      tester,
    ) async {
      await _openModal(
        tester,
        _app,
        size: const Size(360, 800),
        bottomPadding: 34,
      );

      expect(
        tester.getRect(_sheet).bottom - tester.getRect(_secondary).bottom,
        AppSpacing.md + 34,
      );
    });

    testWidgets('does not double an inset the app already took out', (
      tester,
    ) async {
      await _openModal(tester, _app, size: const Size(360, 800));

      expect(
        tester.getRect(_sheet).bottom - tester.getRect(_secondary).bottom,
        AppSpacing.md,
      );
    });

    testWidgets('rides above the keyboard and the actions stay reachable', (
      tester,
    ) async {
      const keyboard = 250.0;
      var confirmed = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _openModal(
        tester,
        () => _app(
          bodyWidget: AppTextField(label: 'Name', controller: controller),
          actions: _buttons(onPrimary: () => confirmed++),
        ),
        textScale: 2,
        keyboard: keyboard,
      );

      expect(tester.takeException(), isNull);
      final sheet = tester.getRect(_sheet);
      expect(sheet.bottom, 568 - keyboard, reason: 'the keyboard is not under');
      expect(sheet.top, greaterThanOrEqualTo(0));

      await tester.ensureVisible(_primary);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getRect(_primary).bottom, lessThanOrEqualTo(sheet.bottom));
      await tester.tap(_primary);
      expect(confirmed, 1);
    });

    for (final direction in TextDirection.values) {
      testWidgets('with a status bar, the keyboard up and 2.0 text the header '
          'clears the top inset ($direction)', (tester) async {
        const status = 24.0;
        await _openModal(
          tester,
          () => _app(
            title: _spanishTitle,
            closeLabel: 'Cerrar',
            bodyWidget: _tallBody(4, text: _spanishBody),
          ),
          textScale: 2,
          direction: direction,
          topPadding: status,
          keyboard: 250,
        );

        expect(tester.takeException(), isNull);
        expect(tester.getRect(_sheet).top, greaterThanOrEqualTo(status));
        expect(tester.getRect(_close).top, greaterThanOrEqualTo(status));
        expect(tester.getTopLeft(_titleText).dy, greaterThanOrEqualTo(status));
        expect(tester.getRect(_sheet).bottom, 568 - 250);
      });
    }

    testWidgets('the route without useSafeArea puts the header under the '
        'status bar, which is why the recipe asks for it', (tester) async {
      await _openModal(
        tester,
        () => _app(
          title: _spanishTitle,
          closeLabel: 'Cerrar',
          bodyWidget: _tallBody(4, text: _spanishBody),
        ),
        textScale: 2,
        topPadding: 24,
        keyboard: 250,
        useSafeArea: false,
      );

      expect(tester.getRect(_close).top, lessThan(24));
    });

    testWidgets('a field that takes focus is scrolled into view', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _openModal(
        tester,
        () => _app(
          bodyWidget: Column(
            children: [
              _tallBody(6),
              AppTextField(label: 'Name', controller: controller),
            ],
          ),
        ),
        textScale: 2,
        keyboard: 250,
      );
      final sheet = tester.getRect(_sheet);
      expect(tester.getRect(_field).bottom, greaterThan(sheet.bottom));

      await tester.tap(_field, warnIfMissed: false);
      await tester.showKeyboard(_field);
      await tester.ensureVisible(_field);
      await tester.pumpAndSettle();

      expect(tester.getRect(_field).bottom, lessThanOrEqualTo(sheet.bottom));
      expect(tester.getRect(_field).top, greaterThanOrEqualTo(sheet.top));
    });
  });

  group('text scale, width and direction', () {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final width in [320.0, 360.0]) {
        for (final direction in TextDirection.values) {
          testWidgets(
            'at $scale and $width wide in $direction the Spanish sheet wraps '
            'and nothing is clipped',
            (tester) async {
              await _pump(
                tester,
                _app(
                  title: _spanishTitle,
                  closeLabel: 'Cerrar',
                  body: _spanishBody,
                  actions: _buttons(
                    primary: 'Archivar habitación',
                    secondary: 'Conservar habitación',
                  ),
                ),
                width: width,
                textScale: scale,
                direction: direction,
              );

              expect(tester.takeException(), isNull);
              final sheet = tester.getRect(_sheet);
              expect(sheet.width, width);
              for (final finder in [
                _titleText,
                _body,
                _primary,
                _secondary,
                _close,
              ]) {
                final rect = tester.getRect(finder);
                expect(rect.left, greaterThanOrEqualTo(sheet.left));
                expect(rect.right, lessThanOrEqualTo(sheet.right));
              }
              final title = tester.getRect(_titleText);
              final close = tester.getRect(_close);
              expect(
                title.overlaps(close),
                isFalse,
                reason: 'the title wraps instead of running under the button',
              );
              expect(
                direction == TextDirection.ltr
                    ? close.left > title.right - 1
                    : close.right < title.left + 1,
                isTrue,
                reason: 'the close button is at the end of the line',
              );
              expect(
                tester.getRect(_secondary).bottom,
                lessThanOrEqualTo(sheet.bottom),
              );
            },
          );
        }
      }
    }
  });

  group('in a real route at 320 by 568', () {
    for (final direction in TextDirection.values) {
      testWidgets(
        'at 2.0 ($direction) the last action is reached by scrolling and '
        'nothing overflows',
        (tester) async {
          var confirmed = 0;
          await _openModal(
            tester,
            () => _app(
              title: _spanishTitle,
              closeLabel: 'Cerrar',
              bodyWidget: _tallBody(5, text: _spanishBody),
              actions: _buttons(
                primary: 'Archivar habitación',
                secondary: 'Conservar habitación',
                onSecondary: () => confirmed++,
              ),
            ),
            textScale: 2,
            direction: direction,
          );

          expect(tester.takeException(), isNull);
          final sheet = tester.getRect(_sheet);
          expect(sheet.bottom, lessThanOrEqualTo(568));
          expect(sheet.top, greaterThanOrEqualTo(0));
          expect(tester.getRect(_secondary).bottom, greaterThan(sheet.bottom));
          final header = tester.getRect(find.byType(SheetHeader)).height;
          final pinned = header <= sheet.height / 2;
          final titleTop = tester.getTopLeft(_titleText).dy;

          await tester.ensureVisible(_secondary);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(_secondary).bottom,
            lessThanOrEqualTo(sheet.bottom),
          );
          expect(
            tester.getRect(_secondary).top,
            greaterThanOrEqualTo(sheet.top),
          );
          expect(
            tester.getTopLeft(_titleText).dy == titleTop,
            pinned,
            reason: 'a header that fits stays pinned, a tall one scrolls away',
          );
          await tester.tap(_secondary);
          expect(confirmed, 1);
        },
      );
    }

    testWidgets('in the default route, capped at 9/16, the header scrolls '
        'with the body and the last action is still reached', (tester) async {
      var confirmed = 0;
      await _openModal(
        tester,
        () => _app(
          title: _spanishTitle,
          closeLabel: 'Cerrar',
          bodyWidget: _tallBody(3, text: _spanishBody),
          actions: _buttons(onSecondary: () => confirmed++),
        ),
        textScale: 2,
        scrollControlled: false,
      );

      final sheet = tester.getRect(_sheet);
      expect(sheet.height, closeTo(568 * 9 / 16, 0.01));
      expect(
        tester.getRect(find.byType(SheetHeader)).height,
        greaterThan(sheet.height / 2),
      );
      final titleTop = tester.getTopLeft(_titleText).dy;

      await tester.ensureVisible(_secondary);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(_titleText).dy, lessThan(titleTop));
      expect(
        tester.getRect(_secondary).bottom,
        lessThanOrEqualTo(sheet.bottom),
      );
      await tester.tap(_secondary);
      expect(confirmed, 1);
    });

    testWidgets('the route is named once, by the title', (tester) async {
      final handle = tester.ensureSemantics();
      await _openModal(tester, _app, size: const Size(360, 640));

      final title = tester.getSemantics(_titleText);
      final routes = <SemanticsNode>[];
      for (SemanticsNode? node = title; node != null; node = node.parent) {
        if (node.getSemanticsData().flagsCollection.scopesRoute) {
          routes.add(node);
        }
      }
      expect(routes, hasLength(1), reason: 'one route scope above the title');

      final namers = <String>[];
      var titles = 0;
      void visit(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.flagsCollection.namesRoute && node != routes.single) {
          namers.add(data.label);
        }
        if (data.label == _title) titles++;
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(routes.single);
      expect(namers, [_title]);
      expect(titles, 1, reason: 'the title is not said twice');
      handle.dispose();
    });
  });

  group('semantics', () {
    testWidgets('a heading, the close button, the body and the actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _app());

      final labels = [
        for (final node in semanticsNodes(tester))
          if (node.label.isNotEmpty) node.label,
      ];
      expect(
        labels.where(
          (label) =>
              label == _title ||
              label == 'Close' ||
              label == _bodyText ||
              label == 'Archive room' ||
              label == 'Keep room',
        ),
        [_title, 'Close', _bodyText, 'Archive room', 'Keep room'],
      );
      final heading = tester.getSemantics(_titleText);
      expect(heading.getSemanticsData().flagsCollection.isHeader, isTrue);
      final close = tester.getSemantics(_close);
      expect(close.getSemanticsData().flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });
}

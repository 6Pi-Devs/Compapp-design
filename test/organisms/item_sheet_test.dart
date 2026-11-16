import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart';
import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

const _carlos = MemberView(
  id: 'carlos',
  name: 'Carlos',
  initials: 'C',
  joinOrder: 1,
  semanticLabel: 'Carlos, at home',
);

const _luis = MemberView(
  id: 'luis',
  name: 'Luis',
  initials: 'L',
  joinOrder: 2,
  semanticLabel: 'Luis, at home',
);

const _usage = ItemUsage(member: _carlos, subtitle: 'Started it 34 min ago');

const _washer = ItemView(id: 'washer', name: 'Washer', icon: AppIcons.washer);

ItemSheetView _view({
  ItemSheetMode mode = ItemSheetMode.nudge,
  ItemUsage? usage,
  bool noUsage = false,
  String title = 'Ask Carlos to free the washer?',
  String? message = 'You can ask the same person once every 15 minutes.',
  String confirmLabel = 'Send request',
  ItemView item = _washer,
}) => ItemSheetView(
  item: item,
  mode: mode,
  usage: noUsage || mode == ItemSheetMode.start ? null : usage ?? _usage,
  title: title,
  message: message,
  confirmLabel: confirmLabel,
  closeLabel: 'Close',
);

ItemSheetView get _cooldown => _view(
  mode: ItemSheetMode.cooldown,
  message: 'You can ask Carlos again in 11 minutes.',
);

ItemSheetView get _start => _view(
  mode: ItemSheetMode.start,
  title: 'Start using the washer?',
  message: 'The others will see that it is in use.',
  confirmLabel: 'Start using',
);

ItemSheet _sheet(
  ItemSheetView view, {
  VoidCallback? onConfirm,
  VoidCallback? onClose,
}) => ItemSheet(
  view: view,
  onConfirm: onConfirm ?? () {},
  onClose: onClose ?? () {},
);

final Finder _root = find.byKey(const Key('itemSheet.washer'));
final Finder _title = find.byKey(const Key('sheet.title'));
final Finder _close = find.byKey(const Key('sheet.close'));
final Finder _confirm = find.byKey(const Key('itemSheet.confirm'));
final Finder _button = find.descendant(
  of: _confirm,
  matching: find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.button == true,
  ),
);
final Finder _member = find.byKey(const Key('member.carlos'));
final Finder _message = find.byKey(const Key('itemSheet.message'));
final Finder _ring = find.byKey(const Key('sheet.titleRing'));

/// Where focus is, by the widget that owns it: the title, the close button or
/// the confirm button.
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
      .ancestor(of: _title, matching: find.byType(Focus))
      .evaluate()
      .contains(element)) {
    return 'title';
  }
  if (within(_close)) return 'close';
  if (within(_confirm)) return 'confirm';
  return 'other';
}

Future<void> _tab(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  }
  // The shape of a button animates in its ring.
  await tester.pumpAndSettle();
}

/// A screen as tall as the sheet gets at 200% text, which is the route's job
/// to scroll in an app.
void _tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 4000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Opens [view] and lets the sheet take its first focus.
Future<void> _open(
  WidgetTester tester,
  ItemSheetView view, {
  ThemeData? theme,
  double width = 360,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  VoidCallback? onConfirm,
  VoidCallback? onClose,
}) async {
  _tall(tester);
  await tester.pumpWidget(
    barHost(
      _sheet(view, onConfirm: onConfirm, onClose: onClose),
      theme: theme,
      width: width,
      textScale: textScale,
      direction: direction,
    ),
  );
  await tester.pump();
}

/// Shows its child until [_GoneState.remove] is called.
class _Gone extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<_Gone> createState() => _GoneState();
}

class _GoneState extends State<_Gone> {
  bool _gone = false;

  void remove() => setState(() => _gone = true);

  @override
  Widget build(BuildContext context) => _gone ? const SizedBox() : widget.child;
}

void main() {
  group('content', () {
    testWidgets('shows the title, the person using it, the message and the '
        'button', (tester) async {
      await _open(tester, _view());

      expect(find.text('Ask Carlos to free the washer?'), findsOneWidget);
      expect(find.text('Carlos'), findsOneWidget);
      expect(find.text('Started it 34 min ago'), findsOneWidget);
      expect(
        find.text('You can ask the same person once every 15 minutes.'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _confirm, matching: find.text('Send request')),
        findsOneWidget,
      );
      expect(_close, findsOneWidget);
      expect(tester.widget<MemberRow>(find.byType(MemberRow)).member, _carlos);
    });

    testWidgets('a start has no person and says its message', (tester) async {
      await _open(tester, _start);

      expect(find.byType(MemberRow), findsNothing);
      expect(
        find.text('The others will see that it is in use.'),
        findsOneWidget,
      );
      expect(find.text('Start using'), findsOneWidget);
    });

    testWidgets('a view without a message leaves the line out', (tester) async {
      await _open(tester, _view(message: null));
      expect(_message, findsNothing);

      await _open(tester, _view(message: ''));
      expect(_message, findsNothing);
    });

    testWidgets('the order is the header, the person, the message, the '
        'button', (tester) async {
      await _open(tester, _view());

      final tops = [
        for (final finder in [_title, _member, _message, _confirm])
          tester.getTopLeft(finder).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet(), hasLength(4));
    });

    testWidgets('the button is the confirm and calls onConfirm once', (
      tester,
    ) async {
      var confirmed = 0;
      var closed = 0;
      await _open(
        tester,
        _view(),
        onConfirm: () => confirmed++,
        onClose: () => closed++,
      );

      await tester.tap(_confirm);

      expect(confirmed, 1);
      expect(closed, 0);
    });

    testWidgets('the close button calls onClose once', (tester) async {
      var confirmed = 0;
      var closed = 0;
      await _open(
        tester,
        _view(),
        onConfirm: () => confirmed++,
        onClose: () => closed++,
      );

      await tester.tap(_close);

      expect(closed, 1);
      expect(confirmed, 0);
    });

    testWidgets('Escape closes once, from the title and from the button', (
      tester,
    ) async {
      var closed = 0;
      await _open(tester, _view(), onClose: () => closed++);
      expect(_focused(), 'title');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 1);

      await _tab(tester, 2);
      expect(_focused(), 'confirm');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 2);
    });

    testWidgets('in a cooldown the button is disabled and never confirms', (
      tester,
    ) async {
      var confirmed = 0;
      await _open(tester, _cooldown, onConfirm: () => confirmed++);

      await tester.tap(_confirm, warnIfMissed: false);
      await tester.pump();

      expect(confirmed, 0);
      expect(tester.widget<AppButton>(_confirm).onPressed, isNull);
      expect(
        find.text('You can ask Carlos again in 11 minutes.'),
        findsOneWidget,
      );
    });

    for (final mode in [
      ItemSheetMode.start,
      ItemSheetMode.finish,
      ItemSheetMode.nudge,
      ItemSheetMode.remind,
    ]) {
      testWidgets('${mode.name} has an enabled button', (tester) async {
        await _open(tester, _view(mode: mode));

        expect(tester.widget<AppButton>(_confirm).onPressed, isNotNull);
      });
    }

    testWidgets('the sheet is keyed by the item', (tester) async {
      await _open(
        tester,
        _view(
          item: const ItemView(id: 'oven', name: 'Oven', icon: AppIcons.oven),
        ),
      );

      expect(find.byKey(const Key('itemSheet.oven')), findsOneWidget);
      expect(_root, findsNothing);
    });
  });

  group('surface', () {
    testWidgets('the sheet has the sheet fill, 24 top corners, no bottom '
        'corners and the sheet shadow', (tester) async {
      await _open(tester, _view());

      final box = tester.widget<DecoratedBox>(
        find.descendant(of: _root, matching: find.byType(DecoratedBox)).first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(
        decoration.color,
        CompappTheme.light.colorScheme.surfaceContainerLowest,
      );
      expect(
        decoration.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      );
      expect(decoration.boxShadow, AppShadows.sheet);
    });

    for (final (name, theme) in themes) {
      testWidgets('paints its fill, the sunken card and the primary button '
          '($name)', (tester) async {
        await _open(tester, _view(), theme: theme);
        final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
        final scheme = theme.colorScheme;
        final sheet = tester.getRect(_root).shift(-origin);
        final card = tester
            .getRect(
              find.ancestor(of: _member, matching: find.byType(Padding)).first,
            )
            .shift(-origin);
        final button = tester.getRect(_confirm).shift(-origin);

        Future<Color> at(Offset point) =>
            paintedColorAt(tester, barBoundaryKey, point);
        bool near(Color a, Color b) =>
            (a.r - b.r).abs() < 0.01 &&
            (a.g - b.g).abs() < 0.01 &&
            (a.b - b.b).abs() < 0.01;

        expect(
          near(
            await at(Offset(sheet.center.dx, sheet.top + 70)),
            scheme.surfaceContainerLowest,
          ),
          isTrue,
          reason: 'the sheet fill',
        );
        expect(
          near(
            await at(Offset(card.left + 3, card.center.dy)),
            scheme.surfaceContainerHigh,
          ),
          isTrue,
          reason: 'the card of the person',
        );
        expect(
          near(
            await at(Offset(button.left + 3, button.center.dy)),
            scheme.primary,
          ),
          isTrue,
          reason: 'the button',
        );
        expect(
          (await at(Offset(sheet.left + 1, sheet.top + 1))).a,
          0,
          reason: 'the corner is cut',
        );
      });
    }

    testWidgets('the safe area (padding) is added under the button, and a '
        'view padding the ancestors consumed is not', (tester) async {
      Widget padded(EdgeInsets padding, EdgeInsets viewPadding) => barHost(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: padding, viewPadding: viewPadding),
            child: _sheet(_view()),
          ),
        ),
      );
      double under() =>
          tester.getRect(_root).bottom - tester.getRect(_confirm).bottom;

      await tester.pumpWidget(padded(EdgeInsets.zero, EdgeInsets.zero));
      final bare = under();
      expect(bare, AppSpacing.md);

      await tester.pumpWidget(
        padded(const EdgeInsets.only(bottom: 34), EdgeInsets.zero),
      );
      expect(under() - bare, closeTo(34, 0.01));

      await tester.pumpWidget(
        padded(EdgeInsets.zero, const EdgeInsets.only(bottom: 34)),
      );
      expect(under() - bare, 0, reason: 'a consumed inset is not added again');
    });
  });

  group('asserts', () {
    test('a start has no person and every other mode has one', () {
      expect(
        () => ItemSheetView(
          item: _washer,
          mode: ItemSheetMode.start,
          usage: _usage,
          title: 'T',
          confirmLabel: 'C',
          closeLabel: 'X',
        ),
        throwsAssertionError,
      );
      for (final mode in ItemSheetMode.values.skip(1)) {
        expect(
          () => ItemSheetView(
            item: _washer,
            mode: mode,
            title: 'T',
            message: 'M',
            confirmLabel: 'C',
            closeLabel: 'X',
          ),
          throwsAssertionError,
          reason: mode.name,
        );
      }
    });

    test('a wait says how long is left', () {
      for (final message in [null, '']) {
        expect(
          () => ItemSheetView(
            item: _washer,
            mode: ItemSheetMode.cooldown,
            usage: _usage,
            title: 'T',
            message: message,
            confirmLabel: 'C',
            closeLabel: 'X',
          ),
          throwsAssertionError,
        );
      }
    });

    testWidgets('nobody nudges or reminds themselves, only a finish can be '
        'their own use', (tester) async {
      const you = MemberView(
        id: 'ana',
        name: 'Ana (you)',
        initials: 'A',
        joinOrder: 0,
        isYou: true,
        semanticLabel: 'Ana, you',
      );
      const own = ItemUsage(member: you, subtitle: 'You started it');
      for (final mode in [
        ItemSheetMode.nudge,
        ItemSheetMode.remind,
        ItemSheetMode.cooldown,
      ]) {
        await _open(tester, _view(mode: mode, usage: own, message: 'Wait'));

        expect(
          tester.takeException(),
          isA<AssertionError>(),
          reason: mode.name,
        );
      }
      for (final mode in [ItemSheetMode.start, ItemSheetMode.finish]) {
        await _open(tester, _view(mode: mode, usage: own, message: 'Wait'));

        expect(tester.takeException(), isNull, reason: mode.name);
      }
    });

    test('the words are never empty', () {
      for (final (title, confirm, close) in [
        ('', 'C', 'X'),
        ('T', '', 'X'),
        ('T', 'C', ''),
      ]) {
        expect(
          () => ItemSheetView(
            item: _washer,
            mode: ItemSheetMode.start,
            title: title,
            confirmLabel: confirm,
            closeLabel: close,
          ),
          throwsAssertionError,
        );
      }
      final empty = ' '.trim();
      expect(
        () => ItemUsage(member: _carlos, subtitle: empty),
        throwsAssertionError,
      );
    });
  });

  group('semantics', () {
    testWidgets('the title heading names the route and the sheet scopes '
        'none, nor does it carry a label of its own', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _view());

      final root = tester.getSemantics(_root).getSemanticsData();
      expect(root.flagsCollection.scopesRoute, isFalse);
      expect(root.flagsCollection.namesRoute, isFalse);
      expect(root.label, isEmpty);
      final title = tester.getSemantics(_title).getSemanticsData();
      expect(title.flagsCollection.isHeader, isTrue);
      expect(title.flagsCollection.namesRoute, isTrue);
      expect(title.label, 'Ask Carlos to free the washer?');
      handle.dispose();
    });

    testWidgets('the person is one node: the spoken label, then the '
        'subtitle', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _view());

      final node = tester.getSemantics(_member);
      expect(node.label, contains('Carlos, at home'));
      expect(node.label, contains('Started it 34 min ago'));
      expect(node.label.indexOf('Carlos'), lessThan(node.label.indexOf('34')));
      expect(node.childrenCount, 0);
      handle.dispose();
    });

    testWidgets('the button is one button named by its visible label '
        '(label in name)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _view());

      final node = tester.getSemantics(_button);
      expect(node.label, 'Send request');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(find.text('Send request'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('in a cooldown the same button node is disabled and the '
        'message before it says why', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _cooldown);

      final node = tester.getSemantics(_button);
      expect(node.label, 'Send request');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        tester.getSemantics(_message).label,
        'You can ask Carlos again in 11 minutes.',
      );
      handle.dispose();
    });

    testWidgets('it is read as the title, the close button, the person, the '
        'message and the button', (tester) async {
      final handle = tester.ensureSemantics();
      for (final direction in TextDirection.values) {
        await _open(tester, _view(), direction: direction);

        final labels = <String>[];
        void visit(SemanticsNode node) {
          if (node != tester.getSemantics(_root) && node.label.isNotEmpty) {
            labels.add(node.label);
          }
          node
              .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
              .forEach(visit);
        }

        visit(tester.getSemantics(_root));

        expect(labels, [
          'Ask Carlos to free the washer?',
          'Close',
          'Carlos, at home\nStarted it 34 min ago',
          'You can ask the same person once every 15 minutes.',
          'Send request',
        ], reason: '$direction');
      }
      handle.dispose();
    });

    testWidgets('the title node is focused while it has the focus', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _view());

      final data = tester.getSemantics(_title).getSemanticsData();
      expect(data.flagsCollection.isFocused, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('passes the Flutter tap target and label guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final view in [_view(), _cooldown, _start]) {
        await _open(tester, view);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }
      handle.dispose();
    });
  });

  group('focus', () {
    testWidgets('starts on the title once the sheet is laid out, and the '
        'next Tab reaches the close button, then the button', (tester) async {
      _tall(tester);
      await tester.pumpWidget(barHost(_sheet(_view())));
      await tester.pump();

      expect(_focused(), 'title');

      await _tab(tester);
      expect(_focused(), 'close');
      await _tab(tester);
      expect(_focused(), 'confirm');
    });

    testWidgets('a start also opens on the title', (tester) async {
      await _open(tester, _start);

      expect(_focused(), 'title');
    });

    testWidgets('a rebuild with the same view neither cancels nor repeats '
        'the first focus', (tester) async {
      final view = ValueNotifier(_view());
      addTearDown(view.dispose);
      await tester.pumpWidget(
        barHost(
          ValueListenableBuilder(
            valueListenable: view,
            builder: (context, value, _) => _sheet(value),
          ),
        ),
      );
      // Same data, new object, before the focus has landed.
      view.value = _view();
      await tester.pump();
      expect(_focused(), 'title');

      await _tab(tester, 2);
      expect(_focused(), 'confirm');
      view.value = _view();
      await tester.pump();
      await tester.pump();

      expect(_focused(), 'confirm', reason: 'a rebuild does not take focus');
    });

    testWidgets('a sheet unmounted before the end of its first frame does not '
        'ask for focus', (tester) async {
      _tall(tester);
      final host = GlobalKey<_GoneState>();
      // Registered before the sheet's own, so it runs first: the sheet is
      // gone when its callback runs.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        host.currentState!.remove();
        WidgetsBinding.instance.buildOwner!
          ..buildScope(WidgetsBinding.instance.rootElement!)
          ..finalizeTree();
      });
      await tester.pumpWidget(
        barHost(_Gone(key: host, child: _sheet(_view()))),
      );
      await tester.pump();

      expect(_title, findsNothing);
      expect(tester.takeException(), isNull);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('ItemSheet.title'),
        reason: 'a node that was disposed does not take the focus',
      );
    });

    testWidgets('the button disabled while it has the focus hands it to the '
        'title, not to the route', (tester) async {
      await _open(tester, _view());
      await _tab(tester, 2);
      expect(_focused(), 'confirm');

      await _open(tester, _cooldown);

      expect(_focused(), 'title');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the same hand-over shows the title ring, and the button '
        'takes the focus again when it is enabled', (tester) async {
      await _open(tester, _view());
      await _tab(tester, 2);

      await _open(tester, _cooldown);
      expect(_ring, findsOneWidget);

      await _open(tester, _view());
      expect(_focused(), 'title', reason: 'the title keeps it');
      await _tab(tester, 2);
      expect(_focused(), 'confirm');
    });

    testWidgets('a wait that starts while the focus is elsewhere leaves it '
        'where it is', (tester) async {
      await _open(tester, _view());
      await _tab(tester);
      expect(_focused(), 'close');

      await _open(tester, _cooldown);

      expect(_focused(), 'close');
    });

    testWidgets('the wrapper that watches the button never takes focus '
        'itself', (tester) async {
      await _open(tester, _view());

      final watcher = tester.widget<Focus>(
        find.ancestor(of: _confirm, matching: find.byType(Focus)).first,
      );
      expect(watcher.focusNode!.canRequestFocus, isFalse);
      expect(watcher.focusNode!.skipTraversal, isTrue);
    });

    testWidgets('the focused button keeps its focus when the person and the '
        'message above it go', (tester) async {
      await _open(tester, _view());
      await _tab(tester, 2);
      expect(_focused(), 'confirm');
      final button = tester.element(_confirm);

      await _open(tester, _view(mode: ItemSheetMode.start, message: null));

      expect(_focused(), 'confirm');
      expect(tester.element(_confirm), same(button));
    });

    testWidgets('the close button keeps its focus through the modes', (
      tester,
    ) async {
      await _open(tester, _view());
      await _tab(tester);
      for (final view in [_cooldown, _view(), _start]) {
        await _open(tester, view);

        expect(_focused(), 'close');
      }
    });

    testWidgets('the person keeps its element when the message changes and '
        'is a new one for another person', (tester) async {
      await _open(tester, _view());
      final row = tester.element(_member);

      await _open(tester, _view(message: 'Another line'));
      expect(tester.element(_member), same(row));

      await _open(
        tester,
        _view(
          usage: const ItemUsage(member: _luis, subtitle: 'Started it now'),
        ),
      );
      expect(_member, findsNothing);
      expect(find.byKey(const Key('member.luis')), findsOneWidget);
    });
  });

  group('keyboard ring', () {
    for (final (name, theme) in themes) {
      testWidgets('the focused button and the focused close button have an '
          'ink ring that nothing paints over ($name)', (tester) async {
        await _open(tester, _view(), theme: theme);
        final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
        final ink = theme.colorScheme.onSurface;

        // How near the ink the nearest pixel of the 2 px strip beside a
        // widget gets: the ring is anti-aliased, so it is a distance.
        Future<double> inkNear(
          Finder finder, {
          required bool above,
          double inset = 24,
        }) async {
          final box = tester.getRect(finder).shift(-origin);
          final strip = await paintedPixels(
            tester,
            barBoundaryKey,
            region: Rect.fromLTWH(
              box.left + inset,
              above ? box.top - AppSizes.borderEmphasis : box.bottom,
              box.width - 2 * inset,
              AppSizes.borderEmphasis,
            ),
          );
          return closestColorDistance(strip, ink);
        }

        final closeShape = find
            .descendant(of: _close, matching: find.byType(Material))
            .first;
        expect(await inkNear(_confirm, above: true), greaterThan(0.2));
        expect(
          await inkNear(closeShape, above: false, inset: 12),
          greaterThan(0.2),
        );

        await _tab(tester);
        expect(_focused(), 'close');
        expect(
          await inkNear(closeShape, above: false, inset: 12),
          lessThan(0.1),
          reason: 'the card of the person does not cover the ring',
        );

        await _tab(tester);
        expect(_focused(), 'confirm');
        expect(
          await inkNear(_confirm, above: true),
          lessThan(0.1),
          reason: 'the ring of the button is above the card and the message',
        );
      });
    }

    for (final (name, theme) in themes) {
      test('the rings reach 3:1 on the sheet fill ($name)', () {
        final scheme = theme.colorScheme;
        expectContrast(
          {'ring/sheet': (scheme.onSurface, scheme.surfaceContainerLowest)},
          minimum: 3,
          reason: 'the focus ring in $name',
        );
      });
    }
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      test('the texts reach 4.5:1 on their fills ($name)', () {
        final scheme = theme.colorScheme;
        final sheet = scheme.surfaceContainerLowest;
        final card = scheme.surfaceContainerHigh;
        expectContrast(
          {
            'title/sheet': (scheme.onSurface, sheet),
            'message/sheet': (scheme.onSurfaceVariant, sheet),
            'name/card': (scheme.onSurface, card),
            'subtitle/card': (scheme.onSurfaceVariant, card),
            'close glyph/sheet': (scheme.onSurfaceVariant, sheet),
            'button/primary': (scheme.onPrimary, scheme.primary),
          },
          minimum: 4.5,
          reason: name,
        );
      });

      testWidgets('the texts really paint their colors ($name)', (
        tester,
      ) async {
        await _open(tester, _view(), theme: theme);
        final scheme = theme.colorScheme;

        Color painted(Finder finder) =>
            tester.renderObject<RenderParagraph>(finder).text.style!.color!;
        expect(painted(_title), scheme.onSurface);
        expect(painted(find.text('Carlos')), scheme.onSurface);
        expect(
          painted(find.text('Started it 34 min ago')),
          scheme.onSurfaceVariant,
        );
        expect(painted(_message), scheme.onSurfaceVariant);
      });
    }

    testWidgets('the waiting button is told by its words, not by color '
        'alone', (tester) async {
      await _open(tester, _cooldown);

      expect(find.text('Send request'), findsOneWidget);
      expect(
        find.text('You can ask Carlos again in 11 minutes.'),
        findsOneWidget,
      );
    });
  });

  group('targets', () {
    testWidgets('the close and the confirm buttons are 48 on the real hit '
        'area', (tester) async {
      for (final view in [_view(), _cooldown]) {
        await _open(tester, view);

        for (final finder in [_close, _confirm]) {
          final rect = tester.getRect(finder);
          expect(rect.height, greaterThanOrEqualTo(AppSizes.minTarget));
          expect(rect.width, greaterThanOrEqualTo(AppSizes.minTarget));
          expect(
            tester
                .getRect(
                  find
                      .descendant(of: finder, matching: find.byType(Material))
                      .first,
                )
                .height,
            greaterThanOrEqualTo(AppSizes.minDrawn),
          );
        }
      }
    });

    testWidgets('a tap anywhere on the button, even its corners, confirms', (
      tester,
    ) async {
      var confirmed = 0;
      await _open(tester, _view(), onConfirm: () => confirmed++);
      final rect = tester.getRect(_confirm);

      for (final point in [
        rect.topLeft + const Offset(2, 2),
        rect.bottomRight - const Offset(2, 2),
        rect.center,
      ]) {
        await tester.tapAt(point);
      }

      expect(confirmed, 3);
    });

    testWidgets('the person on the card is not tappable and lights nothing', (
      tester,
    ) async {
      var confirmed = 0;
      var closed = 0;
      await _open(
        tester,
        _view(),
        onConfirm: () => confirmed++,
        onClose: () => closed++,
      );

      final gesture = await tester.startGesture(tester.getCenter(_member));
      await tester.pump(kPressTimeout);
      await gesture.up();
      await tester.pump();

      expect(confirmed + closed, 0);
      expect(
        find.descendant(of: _member, matching: find.byType(InkResponse)),
        findsNothing,
      );
    });
  });

  group('layout', () {
    setUpAll(loadBundledFonts);

    const spanish = (
      title: '¿Pedirle a Carlos que libere la lavadora antes de la noche?',
      message: 'Puedes pedírselo a la misma persona una vez cada 15 minutos.',
      confirm: 'Enviar petición de recordatorio',
    );

    ItemSheetView spanishView() => ItemSheetView(
      item: _washer,
      mode: ItemSheetMode.nudge,
      usage: const ItemUsage(
        member: MemberView(
          id: 'carlos',
          name: 'Carlos Fernández',
          initials: 'C',
          joinOrder: 1,
          semanticLabel: 'Carlos Fernández, en casa',
        ),
        subtitle: 'Empezó hace 34 minutos, probablemente la colada entera',
      ),
      title: spanish.title,
      message: spanish.message,
      confirmLabel: spanish.confirm,
      closeLabel: 'Cerrar',
    );

    for (final width in const [320.0, 360.0]) {
      for (final scale in const [1.0, 1.3, 1.5, 2.0]) {
        for (final direction in TextDirection.values) {
          testWidgets('fits and clips nothing at $width, ${scale}x, '
              '$direction', (tester) async {
            await _open(
              tester,
              spanishView(),
              width: width,
              textScale: scale,
              direction: direction,
            );
            final reason = '$width wide, ${scale}x, $direction';

            expect(tester.takeException(), isNull, reason: reason);
            final sheet = tester.getRect(_root);
            expect(sheet.width, width, reason: reason);
            for (final finder in [
              _title,
              _close,
              _member,
              _message,
              _confirm,
            ]) {
              final box = tester.getRect(finder);
              expect(box.left, greaterThanOrEqualTo(sheet.left - 0.01));
              expect(box.right, lessThanOrEqualTo(sheet.right + 0.01));
              expect(box.bottom, lessThanOrEqualTo(sheet.bottom));
            }
            for (final finder in [
              _title,
              _message,
              find.text(
                'Empezó hace 34 minutos, probablemente la colada entera',
              ),
              find.descendant(of: _confirm, matching: find.byType(Text)),
            ]) {
              expect(
                tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
                isFalse,
                reason: reason,
              );
            }
            expectNoMidWordBreaks(tester, _title, reason: reason);
            expectNoMidWordBreaks(tester, _message, reason: reason);
            expectNoMidWordBreaks(
              tester,
              find.descendant(of: _confirm, matching: find.byType(Text)),
              reason: reason,
            );
            expect(
              tester.getRect(_confirm).height,
              greaterThanOrEqualTo(AppSizes.controlLg),
              reason: reason,
            );
          });
        }
      }
    }

    testWidgets('the sheet grows with large text and the title is never '
        'scaled down', (tester) async {
      await _open(tester, _view(title: 'Free it?'), width: 800);
      final base = tester.getSize(_root).height;
      final title = tester.getSize(_title).height;

      await _open(tester, _view(title: 'Free it?'), textScale: 2, width: 800);

      expect(tester.getSize(_root).height, greaterThan(base));
      expect(tester.getSize(_title).height, closeTo(title * 2, 1));
    });

    testWidgets('right to left puts the pebble and the title at the right '
        'and the close button at the left', (tester) async {
      await _open(tester, _view());
      final ltrPebble = tester.getCenter(find.byType(AppPebble)).dx;
      expect(ltrPebble, lessThan(180));
      expect(tester.getCenter(_close).dx, greaterThan(180));

      await _open(tester, _view(), direction: TextDirection.rtl);

      expect(tester.getCenter(find.byType(AppPebble)).dx, greaterThan(180));
      expect(tester.getCenter(_close).dx, lessThan(180));
      expect(tester.getRect(_title).right, greaterThan(180));
      expect(tester.getRect(_confirm).width, closeTo(360 - 32, 0.01));
    });

    testWidgets('the parts are 12 apart and the button is 16 from the bottom', (
      tester,
    ) async {
      await _open(tester, _view());

      final card = tester.getRect(
        find.ancestor(of: _member, matching: find.byType(DecoratedBox)).first,
      );
      expect(tester.getTopLeft(_message).dy - card.bottom, 12);
      expect(
        tester.getTopLeft(_confirm).dy - tester.getRect(_message).bottom,
        12,
      );
      expect(
        card.top - tester.getRect(find.byType(SheetHeader)).bottom,
        AppSpacing.xs,
      );
      expect(card.left - tester.getRect(_root).left, AppSpacing.md);
      expect(
        tester.getRect(_root).bottom - tester.getRect(_confirm).bottom,
        16,
      );
    });

    testWidgets('the button spans the sheet less its sides', (tester) async {
      await _open(tester, _view());

      final button = tester.getRect(_confirm);
      expect(button.left - tester.getRect(_root).left, AppSpacing.md);
      expect(tester.getRect(_root).right - button.right, AppSpacing.md);
      expect(button.height, AppSizes.controlLg);
    });
  });

  group('in a real bottom sheet', () {
    Future<void> openModal(
      WidgetTester tester,
      ItemSheetView view, {
      required Size size,
      double textScale = 1,
      TextDirection direction = TextDirection.ltr,
      VoidCallback? onConfirm,
      bool scrollControlled = true,
      bool useSafeArea = true,
      double topPadding = 0,
    }) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1
        ..padding = FakeViewPadding(top: topPadding)
        ..viewPadding = FakeViewPadding(top: topPadding);
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
                  builder: (_) => ItemSheet(
                    view: view,
                    onConfirm: onConfirm ?? () {},
                    onClose: () {},
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
    }

    ItemSheetView spanish() => const ItemSheetView(
      item: _washer,
      mode: ItemSheetMode.nudge,
      usage: ItemUsage(
        member: _carlos,
        subtitle: 'Empezó hace 34 minutos, probablemente la colada entera',
      ),
      title: '¿Pedirle a Carlos que libere la lavadora antes de la noche?',
      message: 'Puedes pedírselo a la misma persona una vez cada 15 minutos.',
      confirmLabel: 'Enviar petición',
      closeLabel: 'Cerrar',
    );

    for (final (size, scale, direction) in [
      (const Size(320, 568), 2.0, TextDirection.ltr),
      (const Size(320, 568), 2.0, TextDirection.rtl),
      (const Size(360, 640), 1.3, TextDirection.ltr),
    ]) {
      testWidgets('at ${size.width.toInt()} by ${size.height.toInt()} and '
          '${scale}x ($direction) nothing overflows and the button is '
          'reached by scrolling', (tester) async {
        var confirmed = 0;
        await openModal(
          tester,
          spanish(),
          size: size,
          textScale: scale,
          direction: direction,
          onConfirm: () => confirmed++,
        );

        expect(tester.takeException(), isNull);
        final sheet = tester.getRect(_root);
        expect(sheet.bottom, lessThanOrEqualTo(size.height));
        expect(sheet.top, greaterThanOrEqualTo(0));
        final titleTop = tester.getTopLeft(_title).dy;
        final pinned =
            tester.getRect(find.byType(SheetHeader)).height <= sheet.height / 2;
        if (scale == 2) {
          expect(
            tester.getRect(_confirm).bottom,
            greaterThan(size.height),
            reason: 'it is below the screen until the body is scrolled',
          );
        }

        await tester.ensureVisible(_confirm);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(_confirm).bottom,
          lessThanOrEqualTo(sheet.bottom),
        );
        expect(tester.getRect(_confirm).top, greaterThanOrEqualTo(sheet.top));
        if (pinned) {
          expect(
            tester.getTopLeft(_title).dy,
            titleTop,
            reason: 'the header stays pinned',
          );
        }
        await tester.tap(_confirm);
        expect(confirmed, 1);
      });
    }

    testWidgets('in the default route, capped at 9/16 of the screen, at '
        '320 by 568 and 2.0 nothing overflows and the button is reached', (
      tester,
    ) async {
      var confirmed = 0;
      await openModal(
        tester,
        spanish(),
        size: const Size(320, 568),
        textScale: 2,
        onConfirm: () => confirmed++,
        scrollControlled: false,
      );

      expect(tester.takeException(), isNull);
      final sheet = tester.getRect(_root);
      expect(sheet.height, closeTo(568 * 9 / 16, 0.01));
      expect(
        tester.getRect(find.byType(SheetHeader)).height,
        greaterThan(sheet.height / 2),
        reason: 'the header alone is more than half of the cap',
      );
      final titleTop = tester.getTopLeft(_title).dy;
      expect(tester.getRect(_confirm).bottom, greaterThan(sheet.bottom));

      await tester.ensureVisible(_confirm);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getRect(_confirm).bottom, lessThanOrEqualTo(sheet.bottom));
      expect(tester.getRect(_confirm).top, greaterThanOrEqualTo(sheet.top));
      expect(
        tester.getTopLeft(_title).dy,
        lessThan(titleTop),
        reason: 'the header scrolled away with the body',
      );
      await tester.tap(_confirm);
      expect(confirmed, 1);
    });

    for (final direction in TextDirection.values) {
      testWidgets('with a status bar at 2.0 on a short screen the header '
          'clears the top inset ($direction)', (tester) async {
        const status = 24.0;
        await openModal(
          tester,
          spanish(),
          size: const Size(320, 568),
          textScale: 2,
          direction: direction,
          topPadding: status,
        );

        expect(tester.takeException(), isNull);
        expect(tester.getRect(_root).top, greaterThanOrEqualTo(status));
        expect(tester.getRect(_close).top, greaterThanOrEqualTo(status));
        expect(tester.getTopLeft(_title).dy, greaterThanOrEqualTo(status));
      });
    }

    testWidgets('without useSafeArea the route removes the top inset, which '
        'is why the recipe asks for it', (tester) async {
      await openModal(
        tester,
        spanish(),
        size: const Size(320, 568),
        textScale: 2,
        topPadding: 24,
        useSafeArea: false,
      );

      expect(tester.getRect(_close).top, lessThan(24));
    });

    testWidgets('the route is named once, by the title', (tester) async {
      final handle = tester.ensureSemantics();
      await openModal(tester, _view(), size: const Size(360, 640));

      final title = tester.getSemantics(_title);
      final routes = <SemanticsNode>[];
      for (SemanticsNode? node = title; node != null; node = node.parent) {
        if (node.getSemanticsData().flagsCollection.scopesRoute) {
          routes.add(node);
        }
      }
      expect(routes, hasLength(1), reason: 'one route scope above the title');

      final namers = <String>[];
      final titles = <SemanticsNode>[];
      void visit(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.flagsCollection.namesRoute && node != routes.single) {
          namers.add(data.label);
        }
        if (data.label == 'Ask Carlos to free the washer?') titles.add(node);
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(routes.single);
      expect(namers, ['Ask Carlos to free the washer?']);
      expect(titles, hasLength(1), reason: 'the title is not said twice');
      handle.dispose();
    });
  });

  group('layout under every constraint', () {
    final body = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == 'HeaderBody',
    );

    Widget host({required double? maxHeight}) => barHost(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: maxHeight == null
              ? SingleChildScrollView(child: _sheet(_view()))
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: _sheet(_view()),
                ),
        ),
      ),
    );

    testWidgets('with no bound on the height it is a column, and the dry '
        'layout and the intrinsic heights agree', (tester) async {
      _tall(tester);
      await tester.pumpWidget(host(maxHeight: null));

      final box = tester.renderObject<RenderBox>(body);
      expect(box.size.height, greaterThan(400));
      expect(box.getDryLayout(const BoxConstraints(maxWidth: 360)), box.size);
      expect(box.getMinIntrinsicHeight(360), closeTo(box.size.height, 0.01));
      expect(box.getMaxIntrinsicHeight(360), closeTo(box.size.height, 0.01));
      final header = tester.renderObject<RenderBox>(find.byType(SheetHeader));
      final scroll = tester.renderObject<RenderBox>(
        find.descendant(of: body, matching: find.byType(SingleChildScrollView)),
      );
      expect(
        box.getMinIntrinsicWidth(double.infinity),
        math.max(
          header.getMinIntrinsicWidth(double.infinity),
          scroll.getMinIntrinsicWidth(double.infinity),
        ),
      );
      expect(
        box.getMaxIntrinsicWidth(double.infinity),
        math.max(
          header.getMaxIntrinsicWidth(double.infinity),
          scroll.getMaxIntrinsicWidth(double.infinity),
        ),
      );
      expect(box.getMinIntrinsicWidth(double.infinity), greaterThan(100));

      // A word of the body wider than anything in the header.
      await tester.pumpWidget(
        barHost(
          SingleChildScrollView(
            child: _sheet(
              _view(
                title: 'Free?',
                message: 'Anticonstitucionalmente-extraordinariamente',
              ),
            ),
          ),
        ),
      );
      final wide = tester.renderObject<RenderBox>(body);
      final wideHeader = tester.renderObject<RenderBox>(
        find.byType(SheetHeader),
      );
      expect(
        wide.getMinIntrinsicWidth(double.infinity),
        greaterThan(wideHeader.getMinIntrinsicWidth(double.infinity)),
        reason: 'the body sets the width here',
      );
    });

    testWidgets('with a bound the body takes what the header leaves, and the '
        'dry layout agrees', (tester) async {
      _tall(tester);
      await tester.pumpWidget(host(maxHeight: 400));

      final box = tester.renderObject<RenderBox>(body);
      expect(box.size.height, 400);
      expect(
        box.getDryLayout(const BoxConstraints(maxWidth: 360, maxHeight: 400)),
        box.size,
      );
      final header = tester.getRect(find.byType(SheetHeader));
      expect(
        tester
            .getRect(
              find.descendant(
                of: body,
                matching: find.byType(SingleChildScrollView),
              ),
            )
            .height,
        closeTo(400 - header.height, 0.01),
      );
    });
  });

  group('the header pins only up to half of a bounded height', () {
    final member = find.byKey(const Key('member.carlos'));
    Widget host(double? maxHeight) => barHost(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: maxHeight == null
              ? SingleChildScrollView(child: _sheet(_view()))
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: _sheet(_view()),
                ),
        ),
      ),
    );

    /// How far the title moved when the body is dragged up by 40.
    Future<double> titleShift(WidgetTester tester, double maxHeight) async {
      _tall(tester);
      await tester.pumpWidget(host(maxHeight));
      final before = tester.getTopLeft(_title).dy;
      await tester.dragFrom(
        tester.getTopLeft(member) + const Offset(20, 20),
        const Offset(0, -40),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      return before - tester.getTopLeft(_title).dy;
    }

    Future<double> naturalHeader(WidgetTester tester) async {
      _tall(tester);
      await tester.pumpWidget(host(null));
      return tester.getRect(find.byType(SheetHeader)).height;
    }

    testWidgets('a header that is exactly half stays pinned: the body '
        'scrolls under it', (tester) async {
      final header = await naturalHeader(tester);

      expect(await titleShift(tester, header * 2), 0);
      expect(
        tester.getRect(find.byType(SheetHeader)).height,
        header,
        reason: 'the pinned header is not squeezed',
      );
    });

    testWidgets('a header a hair over half scrolls with the body', (
      tester,
    ) async {
      final header = await naturalHeader(tester);

      expect(await titleShift(tester, header * 2 - 1), 40);
    });

    testWidgets('a header over half still ends at the bounded height, and '
        'the dry layout agrees', (tester) async {
      final header = await naturalHeader(tester);
      _tall(tester);
      await tester.pumpWidget(host(header * 2 - 1));

      final box = tester.renderObject<RenderBox>(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == 'HeaderBody',
        ),
      );
      expect(box.size.height, header * 2 - 1);
      expect(
        box.getDryLayout(
          BoxConstraints(maxWidth: 360, maxHeight: header * 2 - 1),
        ),
        box.size,
      );
    });
  });

  group('the viewport of a header that scrolls with the body', () {
    final headerBody = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == 'HeaderBody',
    );
    final member = find.byKey(const Key('member.carlos'));

    Widget host({required double height, double top = 0}) => barHost(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height),
              child: _sheet(_view()),
            ),
          ),
        ),
      ),
    );

    /// Opens a sheet whose header is more than half of its height, so the
    /// whole scrolls.
    Future<void> openScrolling(WidgetTester tester, {double top = 0}) async {
      _tall(tester);
      await tester.pumpWidget(host(height: 300, top: top));
      expect(
        tester.getRect(find.byType(SheetHeader)).height,
        greaterThan(150),
        reason: 'the header is over half of 300',
      );
    }

    bool listened(ViewportOffset offset) =>
        // The count of listeners is only visible through a protected getter.
        // ignore: invalid_use_of_protected_member
        offset.hasListeners;

    RenderAbstractViewport viewport(WidgetTester tester) =>
        tester.renderObject<RenderAbstractViewport>(headerBody);

    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    /// Where the target should land for an alignment, worked out from its
    /// place in the content: its top then, less what the alignment leaves.
    double expectedOffset(
      WidgetTester tester,
      Finder target,
      double alignment,
    ) {
      final top =
          tester.getTopLeft(target).dy - tester.getTopLeft(headerBody).dy;
      final room =
          tester.getSize(headerBody).height - tester.getSize(target).height;
      return (position(tester).pixels + top - room * alignment).clamp(
        0,
        position(tester).maxScrollExtent,
      );
    }

    testWidgets('the offset to reveal a widget is the same from any scroll '
        'position', (tester) async {
      await openScrolling(tester);
      final box = tester.renderObject<RenderBox>(member);
      final max = position(tester).maxScrollExtent;

      final first = viewport(tester).getOffsetToReveal(box, 0).offset;
      position(tester).jumpTo(40);
      await tester.pump();
      final scrolled = viewport(tester).getOffsetToReveal(box, 0).offset;

      expect(first, greaterThan(0));
      expect(first, lessThan(max), reason: 'not clamped');
      expect(scrolled, closeTo(first, 0.01));
      expect(first, closeTo(expectedOffset(tester, member, 0), 0.01));
    });

    testWidgets('the offset to reveal follows the alignment', (tester) async {
      await openScrolling(tester);
      final box = tester.renderObject<RenderBox>(member);
      final max = position(tester).maxScrollExtent;

      final start = viewport(tester).getOffsetToReveal(box, 0).offset;
      final middle = viewport(tester).getOffsetToReveal(box, 0.5).offset;

      expect(start, inExclusiveRange(0, max));
      expect(middle, inExclusiveRange(0, max));
      expect(middle, lessThan(start));
      expect(start, closeTo(expectedOffset(tester, member, 0), 0.01));
      expect(middle, closeTo(expectedOffset(tester, member, 0.5), 0.01));
    });

    testWidgets('the rect after revealing is where the widget ends up', (
      tester,
    ) async {
      await openScrolling(tester);
      final box = tester.renderObject<RenderBox>(member);

      final revealed = viewport(tester).getOffsetToReveal(box, 0);

      expect(revealed.rect.top, closeTo(0, 0.01));
    });

    testWidgets('a screen reader asking to show the button scrolls it into '
        'view', (tester) async {
      await openScrolling(tester);
      final sheet = tester.getRect(headerBody);
      expect(tester.getRect(_confirm).bottom, greaterThan(sheet.bottom));

      tester.renderObject<RenderBox>(_confirm).showOnScreen();
      await tester.pump();

      expect(tester.getRect(_confirm).bottom, lessThanOrEqualTo(sheet.bottom));
      expect(tester.getRect(_confirm).top, greaterThanOrEqualTo(sheet.top));
    });

    testWidgets('while scrolled nothing paints above the sheet', (
      tester,
    ) async {
      await openScrolling(tester, top: 300);
      position(tester).jumpTo(position(tester).maxScrollExtent);
      await tester.pump();
      final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
      final sheet = tester.getRect(headerBody).shift(-origin);
      expect(
        position(tester).pixels,
        greaterThan(150),
        reason: 'the header is scrolled well out of the sheet',
      );

      // The shadow of the sheet reaches a little above it; the header, were it
      // not clipped, would show higher than that.
      final above = await paintedPixels(
        tester,
        barBoundaryKey,
        region: Rect.fromLTRB(
          sheet.left,
          sheet.top - 140,
          sheet.right,
          sheet.top - 60,
        ),
      );

      expect(above.where((pixel) => pixel.a > 0), isEmpty);
    });

    testWidgets('a header that is gone lets go of its offset', (tester) async {
      await openScrolling(tester);
      final spy = ViewportOffset.fixed(0);
      addTearDown(spy.dispose);
      // The spy takes the place of the scroll position in the render object.
      (viewport(tester) as dynamic).offset = spy;
      expect(listened(spy), isTrue);

      await tester.pumpWidget(barHost(const SizedBox()));

      expect(listened(spy), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a new offset is listened to and the old one let go', (
      tester,
    ) async {
      await openScrolling(tester);
      final spy = ViewportOffset.fixed(0);
      addTearDown(spy.dispose);

      (viewport(tester) as dynamic).offset = spy;

      expect(listened(spy), isTrue);
    });
  });

  group('between views', () {
    testWidgets('in directional navigation a tick of the wait leaves the '
        'focus on the disabled button', (tester) async {
      Widget sheet(ItemSheetView view) => barHost(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(navigationMode: NavigationMode.directional),
            child: _sheet(view),
          ),
        ),
      );
      _tall(tester);
      await tester.pumpWidget(sheet(_cooldown));
      await tester.pump();
      await _tab(tester, 2);
      expect(_focused(), 'confirm', reason: 'a disabled button holds focus');

      await tester.pumpWidget(
        sheet(
          _view(
            mode: ItemSheetMode.cooldown,
            message: 'You can ask Carlos again in 10 minutes.',
          ),
        ),
      );
      await tester.pump();

      expect(_focused(), 'confirm');
    });

    testWidgets('a new item asks for the focus on its title again', (
      tester,
    ) async {
      await _open(tester, _view());
      await _tab(tester);
      expect(_focused(), 'close');

      await _open(
        tester,
        _view(
          item: const ItemView(id: 'oven', name: 'Oven', icon: AppIcons.oven),
        ),
      );

      expect(_focused(), 'title');
    });

    testWidgets('a new view of the same item does not', (tester) async {
      await _open(tester, _view());
      await _tab(tester);

      await _open(tester, _view(title: 'Another question?'));

      expect(_focused(), 'close');
    });
  });

  group('themes', () {
    for (final (name, theme) in themes) {
      testWidgets('builds in every mode ($name)', (tester) async {
        for (final mode in ItemSheetMode.values) {
          await _open(
            tester,
            _view(
              mode: mode,
              message: mode == ItemSheetMode.cooldown ? 'Wait' : null,
            ),
            theme: theme,
          );

          expect(tester.takeException(), isNull, reason: '$mode $name');
          expect(_confirm, findsOneWidget);
        }
      });
    }
  });
}

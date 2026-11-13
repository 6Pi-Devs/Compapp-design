import 'dart:ui' show Tristate;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart' show themes;
import '../helpers/bundled_fonts.dart';
import '../helpers/host.dart' show semanticsNodes;
import '../helpers/painted_color.dart';

const _title = 'Calle Luna 12';
const _spanishTitle = 'Casa compartida de la calle Luna número doce';

final Finder _heading = find.byKey(const Key('topBar.title'));
final Finder _bell = find.byKey(const Key('topBar.activity'));
final Finder _account = find.byKey(const Key('topBar.account'));
final Finder _navLandmark = find.byType(AppNavBar);
final Finder _body = find.byKey(const Key('test.body'));
final Finder _shellLayout = find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ShellLayout',
);

Finder _nav(String id) => find.byKey(Key('nav.$id'));
Finder _field(int index) => find.byKey(Key('test.field.$index'));

const _me = MemberView(
  id: 'me',
  name: 'Alex',
  initials: 'AL',
  joinOrder: 0,
  semanticLabel: 'Alex',
  isYou: true,
);

List<NavDestinationView> _destinations({
  bool spanish = false,
  int calendarBadge = 0,
  bool shortLabels = false,
}) {
  final calendar = shortLabels ? 'Plan' : (spanish ? 'Calendario' : 'Calendar');
  return [
    NavDestinationView(
      id: 'home',
      icon: AppIcons.floorplan,
      label: spanish ? 'Casa' : 'Home',
    ),
    NavDestinationView(
      id: 'things',
      icon: AppIcons.washer,
      label: spanish ? 'Cosas' : 'Things',
    ),
    NavDestinationView(
      id: 'tasks',
      icon: AppIcons.tasks,
      label: spanish ? 'Tareas' : 'Tasks',
    ),
    NavDestinationView(
      id: 'calendar',
      icon: AppIcons.calendar,
      label: calendar,
      badgeCount: calendarBadge,
      semanticLabel: calendarBadge == 0
          ? null
          : spanish
          ? '$calendar, $calendarBadge eventos nuevos'
          : '$calendar, $calendarBadge new events',
    ),
  ];
}

/// A tab body: a list with [fields] text fields named "Field 0", "Field 1" and
/// so on, then a long text, so the body scrolls at large text.
Widget _bodyOf(
  WidgetTester tester, {
  int fields = 1,
  String prefix = 'Field',
}) => SingleChildScrollView(
  key: const Key('test.body'),
  child: Column(
    children: [
      for (var i = 0; i < fields; i++)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: TextField(
            key: Key('test.field.$i'),
            controller: _controller(tester),
            decoration: InputDecoration(labelText: '$prefix $i'),
          ),
        ),
    ],
  ),
);

TextEditingController _controller(WidgetTester tester) {
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  return controller;
}

AppHomeShell _shell(
  WidgetTester tester, {
  Widget? body,
  String title = _title,
  String? subtitle,
  int selectedIndex = 0,
  ValueChanged<int>? onTabSelected,
  int unreadCount = 0,
  VoidCallback? onActivity,
  VoidCallback? onAccount,
  List<NavDestinationView>? destinations,
  String activityLabel = 'Activity',
  String accountLabel = 'Your account',
  String navigationLabel = 'Main',
}) => AppHomeShell(
  title: title,
  subtitle: subtitle,
  activityLabel: activityLabel,
  unreadCount: unreadCount,
  onActivity: onActivity ?? () {},
  me: _me,
  accountLabel: accountLabel,
  onAccount: onAccount ?? () {},
  destinations: destinations ?? _destinations(),
  selectedIndex: selectedIndex,
  onTabSelected: onTabSelected ?? (_) {},
  navigationLabel: navigationLabel,
  body: body ?? _bodyOf(tester),
);

/// Shows [shell] as the home of an app on a screen of [size], with the keyboard
/// and the insets the way a phone reports them: while the keyboard is up the
/// bottom padding is already taken out.
Future<void> _pump(
  WidgetTester tester,
  Widget shell, {
  Size size = const Size(360, 640),
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  double keyboard = 0,
  double homeIndicator = 0,
  double statusBar = 0,
  ThemeData? theme,
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
      home: shell,
    ),
  );
  await tester.pumpAndSettle();
}

void _keyboardMode() {
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
}

// Which part has the focus: "bell", "account", "nav.<id>", "field <n>" or
// "none"/"other".
String _focused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return 'none';
  String? found;
  (context as Element).visitAncestorElements((element) {
    final key = element.widget.key;
    if (key == const Key('topBar.activity')) {
      found = 'bell';
    } else if (key == const Key('topBar.account')) {
      found = 'account';
    } else if (key is ValueKey<String> &&
        (key.value.startsWith('nav.') || key.value.startsWith('test.field.'))) {
      found = key.value.startsWith('nav.')
          ? key.value
          : 'field ${key.value.substring('test.field.'.length)}';
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

// Tabs [stops] times and returns what had the focus after each.
Future<List<String>> _tabThrough(WidgetTester tester, int stops) async {
  final seen = <String>[];
  for (var i = 0; i < stops; i++) {
    await _tab(tester);
    seen.add(_focused());
  }
  return seen;
}

/// Selects a tab the way an app does: it rebuilds the shell.
class _Tabs extends StatefulWidget {
  const new({required this.builder});

  final Widget Function(int selected, ValueChanged<int> select) builder;

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int selected = 0;

  @override
  Widget build(BuildContext context) =>
      widget.builder(selected, (index) => setState(() => selected = index));
}

/// Remembers how many times it was built from scratch, and holds [fields]
/// text fields.
class _Probe extends StatefulWidget {
  const new({required this.name, this.fields = 1, super.key});

  final String name;
  final int fields;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  static final List<String> created = [];
  final List<TextEditingController> controllers = [
    for (var i = 0; i < 4; i++) TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    created.add(widget.name);
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('test.body'),
    child: Column(
      children: [
        for (var i = 0; i < widget.fields; i++)
          TextField(key: Key('test.field.$i'), controller: controllers[i]),
      ],
    ),
  );
}

/// What the body of the shell sees of the screen.
class _Spy extends StatelessWidget {
  const new(this.sink, {super.key});

  final List<MediaQueryData> sink;

  @override
  Widget build(BuildContext context) {
    sink.add(MediaQuery.of(context));
    return const SizedBox.expand();
  }
}

void main() {
  setUpAll(loadBundledFonts);

  group('content and callbacks', () {
    testWidgets('stacks the bar, the body and the nav bar', (tester) async {
      await _pump(tester, _shell(tester, subtitle: 'Ana is home'));

      expect(find.text(_title), findsOneWidget);
      expect(find.text('Ana is home'), findsOneWidget);
      final bar = tester.getRect(_heading);
      final body = tester.getRect(_body);
      final nav = tester.getRect(_navLandmark);
      expect(bar.top, lessThan(body.top));
      expect(
        body.bottom,
        nav.top,
        reason: 'the body ends where the bar starts',
      );
      expect(nav.bottom, 640, reason: 'the nav bar is at the bottom');
      expect(body.width, 360);
      expect(nav.width, 360);
      for (final id in ['home', 'things', 'tasks', 'calendar']) {
        expect(find.byKey(Key('nav.$id')), findsOneWidget);
      }
    });

    testWidgets('the buttons call the app with the index', (tester) async {
      final tapped = <int>[];
      var bell = 0;
      var account = 0;
      await _pump(
        tester,
        _shell(
          tester,
          selectedIndex: 2,
          onTabSelected: tapped.add,
          onActivity: () => bell++,
          onAccount: () => account++,
        ),
      );

      await tester.tap(_nav('things'));
      await tester.tap(_nav('tasks'));
      await tester.tap(_nav('calendar'));
      await tester.tap(_bell);
      await tester.tap(_account);

      expect(tapped, [1, 2, 3], reason: 'the selected one is also reported');
      expect((bell, account), (1, 1));
    });

    testWidgets('owns no tab state: the selection is the one it is given', (
      tester,
    ) async {
      final tapped = <int>[];
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _shell(tester, selectedIndex: 1, onTabSelected: tapped.add),
      );

      await tester.tap(_nav('calendar'));
      await tester.pumpAndSettle();

      expect(tapped, [3]);
      bool selected(String id) =>
          tester
              .getSemantics(_nav(id))
              .getSemanticsData()
              .flagsCollection
              .isSelected ==
          Tristate.isTrue;
      expect(
        [
          for (final id in ['home', 'things', 'tasks', 'calendar'])
            selected(id),
        ],
        [false, true, false, false],
      );
      handle.dispose();
    });

    testWidgets('passes a badge through as plain data', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _shell(
          tester,
          destinations: _destinations(calendarBadge: 2),
          unreadCount: 3,
          activityLabel: 'Activity, 3 unread',
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('Calendar, 2 new events'), findsOneWidget);
      expect(find.bySemanticsLabel('Activity, 3 unread'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('rejects empty words, a bad index and too many tabs', (
      tester,
    ) async {
      Future<void> expectAssertion(AppHomeShell Function() build) async {
        await _pump(tester, Builder(builder: (_) => build()));
        expect(tester.takeException(), isAssertionError);
      }

      await expectAssertion(() => _shell(tester, title: ''));
      await expectAssertion(() => _shell(tester, activityLabel: ''));
      await expectAssertion(() => _shell(tester, accountLabel: ''));
      await expectAssertion(() => _shell(tester, navigationLabel: ''));
      await expectAssertion(() => _shell(tester, selectedIndex: 4));
      await expectAssertion(() => _shell(tester, selectedIndex: -1));
      await expectAssertion(() => _shell(tester, unreadCount: -1));
      await expectAssertion(() => _shell(tester, destinations: const []));
      await expectAssertion(
        () => _shell(
          tester,
          destinations: [
            ..._destinations(),
            const NavDestinationView(
              id: 'more',
              icon: AppIcons.add,
              label: 'M',
            ),
          ],
        ),
      );
    });

    testWidgets('draws the page and the nav bar of each theme', (tester) async {
      for (final (name, theme) in themes) {
        await _pump(
          tester,
          RepaintBoundary(key: const Key('boundary'), child: _shell(tester)),
          theme: theme,
        );
        final scheme = theme.colorScheme;
        final navColor = await paintedColorAt(
          tester,
          const Key('boundary'),
          const Offset(2, 640 - 2),
        );
        final bodyColor = await paintedColorAt(
          tester,
          const Key('boundary'),
          Offset(180, tester.getRect(_body).bottom - 2),
        );
        expect(navColor, scheme.surfaceContainerLowest, reason: name);
        expect(bodyColor, theme.scaffoldBackgroundColor, reason: name);
        expect(
          navColor,
          isNot(bodyColor),
          reason: '$name: the nav bar is a surface of its own',
        );
      }
    });
  });

  group('safe areas', () {
    testWidgets('the bar takes the status bar and the nav bar the indicator', (
      tester,
    ) async {
      await _pump(tester, _shell(tester));
      final plainBar = tester.getRect(_heading).top;
      final plainNav = tester.getSize(_navLandmark).height;

      await _pump(tester, _shell(tester), statusBar: 40, homeIndicator: 34);

      expect(tester.getRect(_heading).top, plainBar + 40);
      expect(tester.getSize(_navLandmark).height, plainNav + 34);
      expect(tester.getRect(_navLandmark).bottom, 640);
      expect(
        tester.getRect(_nav('home')).bottom,
        lessThanOrEqualTo(640 - 34),
        reason: 'the buttons stay above the home indicator',
      );
    });

    testWidgets('the body sees neither inset, so nothing is counted twice', (
      tester,
    ) async {
      final seen = <MediaQueryData>[];
      await _pump(
        tester,
        _shell(tester, body: _Spy(seen, key: const Key('test.body'))),
        statusBar: 40,
        homeIndicator: 34,
        textScale: 1.5,
      );

      final data = seen.last;
      expect(data.padding.top, 0);
      expect(data.padding.bottom, 0);
      expect(data.viewPadding.top, 0);
      expect(data.textScaler.scale(10), 15);
      expect(tester.getSize(_body).width, 360);
    });

    testWidgets('a SafeArea in the body adds nothing', (tester) async {
      await _pump(
        tester,
        _shell(
          tester,
          body: const SafeArea(child: SizedBox.expand(key: Key('test.body'))),
        ),
        statusBar: 40,
        homeIndicator: 34,
      );

      final screenBody = tester.getRect(_body);
      final bar = tester.getRect(find.byType(AppTopBar));
      expect(screenBody.top, bar.bottom);
      expect(screenBody.bottom, tester.getRect(_navLandmark).top);
    });
  });

  group('the keyboard', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('at $scale the body ends above the keyboard and the nav bar '
          'is under it', (tester) async {
        final seen = <MediaQueryData>[];
        await _pump(
          tester,
          _shell(
            tester,
            body: Column(
              key: const Key('test.body'),
              children: [
                Expanded(child: _Spy(seen, key: const Key('test.spy'))),
                TextField(
                  key: const Key('test.field.0'),
                  controller: _controller(tester),
                ),
              ],
            ),
          ),
          size: const Size(320, 568),
          textScale: scale,
          keyboard: 270,
          homeIndicator: 34,
          statusBar: 24,
        );

        expect(tester.takeException(), isNull);
        final body = tester.getRect(_body);
        expect(
          body.bottom,
          568 - 270,
          reason: 'the body ends at the keyboard, not above it twice',
        );
        expect(
          tester.getRect(_navLandmark).top,
          greaterThanOrEqualTo(568 - 270),
          reason: 'the nav bar is under the keyboard and takes no room',
        );
        expect(seen.last.viewInsets.bottom, 0, reason: 'taken out once');
        expect(seen.last.padding.bottom, 0);
        expect(tester.getRect(_field(0)).bottom, lessThanOrEqualTo(568 - 270));
      });
    }

    testWidgets(
      'at 2.0 on 320 by 568 the bar gives way and a field is usable',
      (tester) async {
        await _pump(
          tester,
          _shell(tester, body: _bodyOf(tester, fields: 3)),
          size: const Size(320, 568),
          textScale: 2,
          keyboard: 270,
          statusBar: 24,
        );

        expect(tester.takeException(), isNull);
        expect(tester.getRect(_body).top, 0, reason: 'the body takes the room');
        expect(tester.getRect(_body).bottom, 568 - 270);
        expect(find.text(_title).hitTestable(), findsNothing);

        await tester.tap(_field(0));
        await tester.enterText(_field(0), 'Bathroom');
        await tester.pumpAndSettle();

        final field = tester.getRect(_field(0));
        expect(field.top, greaterThanOrEqualTo(0));
        expect(field.bottom, lessThanOrEqualTo(568 - 270));
        expect(find.text('Bathroom'), findsOneWidget);
      },
    );

    testWidgets('the bar stays while it takes at most half of the room', (
      tester,
    ) async {
      await _pump(tester, _shell(tester), keyboard: 270, statusBar: 24);

      expect(find.text(_title).hitTestable(), findsOneWidget);
      expect(
        tester.getRect(_body).top,
        tester.getRect(find.byType(AppTopBar)).bottom,
      );
      expect(tester.getRect(_body).bottom, 640 - 270);
    });

    testWidgets('the bar gives way exactly when it takes more than half of '
        'the room above the keyboard', (tester) async {
      const screen = Size(320, 568);
      await _pump(
        tester,
        _shell(tester, subtitle: 'Ana y Luis en casa'),
        size: screen,
        textScale: 1.5,
        statusBar: 24,
      );
      final bar = tester.getSize(find.byType(AppTopBar)).height;

      // The room above the keyboard is the screen minus the keyboard.
      Future<bool> barShown(double room) async {
        await _pump(
          tester,
          _shell(tester, subtitle: 'Ana y Luis en casa'),
          size: screen,
          textScale: 1.5,
          keyboard: screen.height - room,
          statusBar: 24,
        );
        return find.text(_title).hitTestable().evaluate().isNotEmpty;
      }

      expect(await barShown(bar * 2 + 2), isTrue, reason: 'just under half');
      expect(await barShown(bar * 2 - 2), isFalse, reason: 'just over half');
    });

    testWidgets('a bar that is out of the layout is not painted and takes no '
        'tap', (tester) async {
      var bell = 0;
      Future<void> pump(double keyboard) => _pump(
        tester,
        RepaintBoundary(
          key: const Key('boundary'),
          child: _shell(
            tester,
            onActivity: () => bell++,
            body: const Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(key: Key('test.body'), width: 40, height: 40),
            ),
          ),
        ),
        size: const Size(320, 568),
        textScale: 2,
        keyboard: keyboard,
        statusBar: 24,
      );

      await pump(270);
      final bellCenter = tester.getCenter(_bell);
      final painted = await paintedColorAt(
        tester,
        const Key('boundary'),
        tester.getCenter(_heading),
      );
      await tester.tapAt(bellCenter);
      await tester.pump();

      expect(bell, 0, reason: 'the hidden bell takes no tap');
      expect(
        painted,
        CompappTheme.light.scaffoldBackgroundColor,
        reason: 'nothing of the bar is painted over the body',
      );

      await pump(0);
      await tester.tap(_bell);

      expect(bell, 1, reason: 'with the room back the bell works');
    });

    testWidgets('without the keyboard the bar never gives way, however tall', (
      tester,
    ) async {
      await _pump(
        tester,
        _shell(tester, title: _spanishTitle, subtitle: 'Ana y Luis en casa'),
        size: const Size(320, 568),
        textScale: 2,
        statusBar: 24,
      );

      expect(find.text(_spanishTitle).hitTestable(), findsOneWidget);
      expect(
        tester.getRect(_body).top,
        tester.getRect(find.byType(AppTopBar)).bottom,
      );
    });

    testWidgets('the bar comes back with the room, and the body keeps its '
        'text', (tester) async {
      Future<void> at(double keyboard) => _pump(
        tester,
        _shell(tester, body: const _Probe(name: 'one')),
        size: const Size(320, 568),
        textScale: 2,
        keyboard: keyboard,
        statusBar: 24,
      );
      await at(270);
      await tester.enterText(_field(0), 'Bathroom');
      expect(find.text(_title).hitTestable(), findsNothing);

      await at(0);

      expect(find.text(_title).hitTestable(), findsOneWidget);
      expect(find.text('Bathroom'), findsOneWidget);

      await at(270);

      expect(find.text(_title).hitTestable(), findsNothing);
      expect(find.text('Bathroom'), findsOneWidget);
    });

    testWidgets('a bar that is out of the layout is out of the focus order '
        'and the semantics', (tester) async {
      _keyboardMode();
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _shell(tester, body: _bodyOf(tester, fields: 2)),
        size: const Size(320, 568),
        textScale: 2,
        keyboard: 270,
        statusBar: 24,
      );

      expect(
        find.bySemanticsLabel(RegExp('Activity|Your account')),
        findsNothing,
      );
      expect(find.bySemanticsLabel(_title), findsNothing);
      expect(await _tabThrough(tester, 3), ['field 0', 'field 1', 'field 0']);
      handle.dispose();
    });

    testWidgets('the covered nav bar is out of the focus order and the '
        'semantics until the keyboard goes', (tester) async {
      _keyboardMode();
      final handle = tester.ensureSemantics();
      await _pump(tester, _shell(tester, body: _bodyOf(tester)), keyboard: 270);

      expect(find.bySemanticsLabel('Main'), findsNothing);
      expect(find.bySemanticsLabel('Home'), findsNothing);
      expect(await _tabThrough(tester, 4), isNot(contains(startsWith('nav.'))));

      await _pump(tester, _shell(tester, body: _bodyOf(tester)));

      expect(find.bySemanticsLabel('Main'), findsOneWidget);
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a field that takes focus is scrolled above the keyboard', (
      tester,
    ) async {
      await _pump(
        tester,
        _shell(tester, body: _bodyOf(tester, fields: 12)),
        size: const Size(320, 568),
        textScale: 2,
        keyboard: 270,
        statusBar: 24,
      );
      expect(tester.getRect(_field(11)).top, greaterThan(568 - 270));

      await tester.ensureVisible(_field(11));
      await tester.pumpAndSettle();

      expect(tester.getRect(_field(11)).bottom, lessThanOrEqualTo(568 - 270));
      expect(tester.getRect(_field(11)).top, greaterThanOrEqualTo(0));
    });
  });

  group('text scale, width and direction', () {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final width in [320.0, 360.0]) {
        for (final direction in TextDirection.values) {
          testWidgets('at $scale and $width wide in $direction the Spanish '
              'shell wraps and nothing is clipped', (tester) async {
            await _pump(
              tester,
              _shell(
                tester,
                title: _spanishTitle,
                subtitle: 'Ana y Luis en casa',
                activityLabel: 'Actividad',
                accountLabel: 'Tu cuenta',
                navigationLabel: 'Principal',
                destinations: _destinations(
                  spanish: true,
                  calendarBadge: 12,
                  shortLabels: width < 360,
                ),
                body: _bodyOf(tester, fields: 3, prefix: 'Campo'),
              ),
              size: Size(width, 568),
              textScale: scale,
              direction: direction,
              statusBar: 24,
              homeIndicator: 34,
            );

            expect(tester.takeException(), isNull);
            final screen = Offset.zero & Size(width, 568);
            for (final finder in [
              _heading,
              _bell,
              _account,
              _nav('home'),
              _nav('things'),
              _nav('tasks'),
              _nav('calendar'),
            ]) {
              final rect = tester.getRect(finder);
              expect(rect.left, greaterThanOrEqualTo(0), reason: '$finder');
              expect(rect.right, lessThanOrEqualTo(width), reason: '$finder');
              expect(rect.bottom, lessThanOrEqualTo(568), reason: '$finder');
            }
            expect(
              tester.getRect(_navLandmark).bottom,
              568,
              reason: 'the nav bar is always at the bottom, no scrolling',
            );
            for (final id in ['home', 'things', 'tasks', 'calendar']) {
              final rect = tester.getRect(_nav(id));
              expect(rect.width, greaterThanOrEqualTo(AppSizes.minTarget));
              expect(rect.height, greaterThanOrEqualTo(AppSizes.minTarget));
              expect(screen.contains(rect.center), isTrue);
              // The label fits its column: laid out to the full word.
              final label = find.descendant(
                of: _nav(id),
                matching: find.text(
                  {
                    'home': 'Casa',
                    'things': 'Cosas',
                    'tasks': 'Tareas',
                    'calendar': width < 360 ? 'Plan' : 'Calendario',
                  }[id]!,
                ),
              );
              expect(
                tester.getRect(label).width,
                lessThanOrEqualTo(rect.width),
                reason: id,
              );
            }
            for (final text in tester.widgetList<Text>(
              find.descendant(
                of: find.byWidgetPredicate(
                  (widget) => widget is AppTopBar || widget is AppNavBar,
                ),
                matching: find.byType(Text),
              ),
            )) {
              expect(
                text.overflow,
                isNot(TextOverflow.ellipsis),
                reason: 'nothing is ellipsized',
              );
            }
            final home = tester.getRect(_nav('home'));
            expect(
              direction == TextDirection.ltr
                  ? home.left < width / 2
                  : home.right > width / 2,
              isTrue,
              reason: 'the first destination is at the start',
            );
            expect(
              tester.getRect(_body).bottom,
              tester.getRect(_navLandmark).top,
            );
            expect(tester.getRect(_body).height, greaterThan(0));
          });
        }
      }
    }

    testWidgets('the nav bar stops growing at 1.3 and the rest keeps growing', (
      tester,
    ) async {
      Future<(double, double, double)> measure(double scale) async {
        await _pump(
          tester,
          _shell(
            tester,
            destinations: _destinations(calendarBadge: 7, shortLabels: true),
          ),
          textScale: scale,
        );
        return (
          tester.getSize(_navLandmark).height,
          tester.getSize(find.text('Tasks')).height,
          tester.getSize(find.byType(AppTopBar)).height,
        );
      }

      final at13 = await measure(1.3);
      final at20 = await measure(2);

      expect(at20.$1, at13.$1, reason: 'the nav bar is clamped at 1.3');
      expect(at20.$2, at13.$2, reason: 'and so is its label');
      expect(at20.$3, greaterThan(at13.$3), reason: 'the bar is not clamped');
    });
  });

  group('as a route', () {
    Future<void> openFrom(WidgetTester tester, {int tab = 0}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          home: _Tabs(
            builder: (selected, select) => _shell(
              tester,
              selectedIndex: selected,
              onTabSelected: select,
              title: selected == 0 ? _title : 'Tasks of the home',
              body: Builder(
                builder: (context) => TextButton(
                  key: const Key('open'),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            body: Text('Pushed page', key: Key('pushed')),
                          ),
                        ),
                      ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('names the route once, by the title, and scopes it once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openFrom(tester);

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

    testWidgets('a tab change renames the route and announces nothing else', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final announcements = <MethodCall>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            if (message is Map && message['type'] == 'announce') {
              announcements.add(MethodCall('announce', message));
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await openFrom(tester);

      await tester.tap(_nav('tasks'));
      await tester.pumpAndSettle();

      final data = tester.getSemantics(_heading).getSemanticsData();
      expect(data.label, 'Tasks of the home');
      expect(data.flagsCollection.namesRoute, isTrue);
      expect(announcements, isEmpty, reason: 'the selected state is the cue');
      handle.dispose();
    });

    testWidgets('a page pushed from a tab goes above the shell and the shell '
        'keeps its state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          home: _Tabs(
            builder: (selected, select) => _shell(
              tester,
              selectedIndex: selected,
              onTabSelected: select,
              body: Builder(
                builder: (context) => Column(
                  key: const Key('test.column'),
                  children: [
                    const Expanded(child: _Probe(name: 'tab')),
                    TextButton(
                      key: const Key('open'),
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const Scaffold(
                                body: Text('Pushed page', key: Key('pushed')),
                              ),
                            ),
                          ),
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      _ProbeState.created.clear();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bathroom');

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pushed')), findsOneWidget);
      expect(find.byType(Scaffold).hitTestable(), findsOneWidget);
      expect(find.byType(AppNavBar).hitTestable(), findsNothing);

      Navigator.of(tester.element(find.byKey(const Key('pushed')))).pop();
      await tester.pumpAndSettle();

      expect(find.text('Bathroom'), findsOneWidget);
    });
  });

  group('focus', () {
    testWidgets('Tab goes through the bar, the body, then the nav bar', (
      tester,
    ) async {
      _keyboardMode();
      await _pump(tester, _shell(tester, body: _bodyOf(tester, fields: 2)));

      expect(await _tabThrough(tester, 9), [
        'bell',
        'account',
        'field 0',
        'field 1',
        'nav.home',
        'nav.things',
        'nav.tasks',
        'nav.calendar',
        'bell',
      ]);
      await _tab(tester, shift: true);
      expect(_focused(), 'nav.calendar');
    });

    testWidgets('the order holds for fields that have scrolled out of sight', (
      tester,
    ) async {
      _keyboardMode();
      await _pump(
        tester,
        _shell(tester, body: _bodyOf(tester, fields: 14)),
        size: const Size(320, 568),
        textScale: 2,
      );

      final stops = await _tabThrough(tester, 2 + 14 + 1);

      expect(stops.sublist(0, 2), ['bell', 'account']);
      expect(stops.sublist(2, 16), [for (var i = 0; i < 14; i++) 'field $i']);
      expect(stops.last, 'nav.home');
    });

    testWidgets('an order the body sets inside stays local', (tester) async {
      _keyboardMode();
      await _pump(
        tester,
        _shell(
          tester,
          body: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: SingleChildScrollView(
              key: const Key('test.body'),
              child: Column(
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(9),
                    child: TextField(
                      key: const Key('test.field.0'),
                      controller: _controller(tester),
                    ),
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(-5),
                    child: TextField(
                      key: const Key('test.field.1'),
                      controller: _controller(tester),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(await _tabThrough(tester, 5), [
        'bell',
        'account',
        'field 1',
        'field 0',
        'nav.home',
      ]);
    });

    testWidgets('an order set in the body without a group of its own does not '
        'reach the shell', (tester) async {
      _keyboardMode();
      await _pump(
        tester,
        _shell(
          tester,
          body: SingleChildScrollView(
            key: const Key('test.body'),
            child: Column(
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(9),
                  child: TextField(
                    key: const Key('test.field.0'),
                    controller: _controller(tester),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(-5),
                  child: TextField(
                    key: const Key('test.field.1'),
                    controller: _controller(tester),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(await _tabThrough(tester, 5), [
        'bell',
        'account',
        'field 0',
        'field 1',
        'nav.home',
      ]);
    });

    testWidgets('a group with its own policy in the body orders only the '
        'body', (tester) async {
      _keyboardMode();
      await _pump(
        tester,
        _shell(
          tester,
          body: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: SingleChildScrollView(
              key: const Key('test.body'),
              child: Column(
                children: [
                  for (var i = 0; i < 2; i++)
                    TextField(
                      key: Key('test.field.$i'),
                      controller: _controller(tester),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(await _tabThrough(tester, 5), [
        'bell',
        'account',
        'field 0',
        'field 1',
        'nav.home',
      ]);
    });

    testWidgets('the shell never takes focus by itself', (tester) async {
      await _pump(tester, _shell(tester));

      expect(_focused(), anyOf('none', 'other'));
    });

    testWidgets('the body keeps its state and focus when the shell rebuilds '
        'with the same tab', (tester) async {
      _keyboardMode();
      Widget shell({
        required String title,
        required int unread,
        required int badge,
      }) => _shell(
        tester,
        title: title,
        unreadCount: unread,
        destinations: _destinations(calendarBadge: badge),
        body: const _Probe(name: 'one'),
      );
      await _pump(tester, shell(title: _title, unread: 0, badge: 0));
      _ProbeState.created.clear();
      await tester.tap(_field(0));
      await tester.enterText(_field(0), 'Bathroom');
      await tester.pump();
      expect(_focused(), 'field 0');

      await _pump(tester, shell(title: 'Other', unread: 4, badge: 3));
      await _pump(tester, shell(title: _title, unread: 0, badge: 0));

      expect(find.text('Bathroom'), findsOneWidget);
      expect(_focused(), 'field 0');
      expect(_ProbeState.created, isEmpty, reason: 'the body was not rebuilt');
    });

    testWidgets('the shell leaves the body alone on a tab change: the app '
        'keys it to get a fresh one', (tester) async {
      Future<void> pumpBody(Widget Function(int selected) body) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MaterialApp(
            theme: CompappTheme.light,
            home: _Tabs(
              builder: (selected, select) => _shell(
                tester,
                selectedIndex: selected,
                onTabSelected: select,
                body: body(selected),
              ),
            ),
          ),
        );
        _ProbeState.created.clear();
        await tester.pumpAndSettle();
        await tester.enterText(_field(0), 'Bathroom');
        await tester.tap(_nav('tasks'));
        await tester.pumpAndSettle();
      }

      await pumpBody((selected) => const _Probe(name: 'same'));
      expect(find.text('Bathroom'), findsOneWidget, reason: 'not keyed');
      expect(_ProbeState.created, isEmpty);

      await pumpBody(
        (selected) => _Probe(key: ValueKey(selected), name: 'tab$selected'),
      );
      expect(find.text('Bathroom'), findsNothing, reason: 'keyed by the app');
      expect(_ProbeState.created, ['tab2']);
    });

    testWidgets('choosing a destination with the keyboard leaves focus on '
        'that button', (tester) async {
      _keyboardMode();
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          home: _Tabs(
            builder: (selected, select) => _shell(
              tester,
              selectedIndex: selected,
              onTabSelected: select,
              body: _Probe(key: ValueKey(selected), name: 'tab$selected'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await _tab(tester);
      }
      expect(_focused(), 'nav.home');
      await _tab(tester);
      expect(_focused(), 'nav.things');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(_focused(), 'nav.things');
    });

    testWidgets('a rebuild that leaves focus where it was moves nothing', (
      tester,
    ) async {
      _keyboardMode();
      Widget shell(String title) => _shell(
        tester,
        title: title,
        body: const _Probe(name: 'one', fields: 2),
      );
      await _pump(tester, shell(_title));
      await tester.tap(_field(1));
      await tester.pump();
      expect(_focused(), 'field 1');

      await _pump(tester, shell('Other'));

      expect(_focused(), 'field 1');
    });

    testWidgets('when the focused field goes away in a rebuild a keyboard user '
        'lands on the first stop of the body', (tester) async {
      _keyboardMode();
      Widget shell(int fields) => _shell(
        tester,
        body: _Probe(name: 'one', fields: fields),
      );
      await _pump(tester, shell(2));
      await tester.tap(_field(1));
      await tester.pump();
      expect(_focused(), 'field 1');

      await _pump(tester, shell(1));

      expect(_focused(), 'field 0');
    });

    testWidgets('the nav bar is the fallback when the body has nothing left '
        'to focus', (tester) async {
      _keyboardMode();
      await _pump(tester, _shell(tester, body: const _Probe(name: 'one')));
      await tester.tap(_field(0));
      await tester.pump();

      await _pump(
        tester,
        _shell(tester, body: const SizedBox.expand(key: Key('test.body'))),
      );

      expect(_focused(), 'nav.home');
    });

    testWidgets('a bar that leaves the layout hands its focus to the body', (
      tester,
    ) async {
      _keyboardMode();
      Future<void> pump(double keyboard) => _pump(
        tester,
        _shell(tester, body: const _Probe(name: 'one')),
        size: const Size(320, 568),
        textScale: 2,
        keyboard: keyboard,
        statusBar: 24,
      );
      await pump(0);
      await _tab(tester);
      expect(_focused(), 'bell');

      await pump(270);
      await tester.pumpAndSettle();

      expect(_focused(), 'field 0');
      expect(find.text(_title).hitTestable(), findsNothing);
    });

    testWidgets('a nav bar the keyboard covers hands its focus to the body', (
      tester,
    ) async {
      _keyboardMode();
      Future<void> pump(double keyboard) => _pump(
        tester,
        _shell(tester, body: const _Probe(name: 'one')),
        keyboard: keyboard,
      );
      await pump(0);
      // Focus goes straight to the nav bar: a scope that remembers a field
      // would otherwise hand focus back to it by itself.
      Focus.of(
        tester.element(
          find.descendant(of: _nav('home'), matching: find.byType(AppIcon)),
        ),
      ).requestFocus();
      await tester.pump();
      expect(_focused(), 'nav.home');

      await pump(270);
      await tester.pumpAndSettle();

      expect(_focused(), 'field 0');
    });

    group('bodies that hold their tabs', () {
      Widget stack(int selected, {Key? key, bool keyedByTab = false}) {
        final body = IndexedStack(
          key: key,
          index: selected,
          children: [for (var i = 0; i < 4; i++) _Probe(name: 'branch$i')],
        );
        return keyedByTab
            ? KeyedSubtree(key: ValueKey(selected), child: body)
            : body;
      }

      Future<void> pumpStack(
        WidgetTester tester,
        Widget Function(int selected) body,
        void Function(ValueChanged<int> select) capture,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CompappTheme.light,
            home: _Tabs(
              builder: (selected, select) {
                capture(select);
                return _shell(
                  tester,
                  selectedIndex: selected,
                  onTabSelected: select,
                  body: body(selected),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      bool inActiveBranch(WidgetTester tester) => tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode
          .hasPrimaryFocus;

      for (final (name, build) in <(String, Widget Function(int, GlobalKey))>[
        ('a plain IndexedStack', (selected, key) => stack(selected)),
        (
          'an IndexedStack with a GlobalKey, as go_router has',
          (selected, key) => stack(selected, key: key),
        ),
        (
          'a GlobalKey body that the app reparents by keying it by tab',
          (selected, key) => stack(selected, key: key, keyedByTab: true),
        ),
      ]) {
        testWidgets('focus lands in the new branch with $name', (tester) async {
          _keyboardMode();
          final key = GlobalKey();
          late ValueChanged<int> select;
          await pumpStack(tester, (selected) => build(selected, key), (s) {
            select = s;
          });
          await tester.tap(_field(0));
          await tester.pump();
          expect(inActiveBranch(tester), isTrue);

          select(2);
          await tester.pumpAndSettle();

          expect(find.byType(EditableText), findsOneWidget);
          expect(
            inActiveBranch(tester),
            isTrue,
            reason: 'the field of the new branch has focus',
          );
        });
      }

      testWidgets('a tab change with the same body hands focus to the first '
          'stop', (tester) async {
        _keyboardMode();
        late ValueChanged<int> select;
        await pumpStack(
          tester,
          (selected) => const _Probe(name: 'same', fields: 2),
          (s) => select = s,
        );
        await tester.tap(_field(1));
        await tester.pump();
        expect(_focused(), 'field 1');

        select(1);
        await tester.pumpAndSettle();

        expect(_focused(), 'field 0');
      });
    });

    group('when the tab changes under focus in the body', () {
      Future<void> pumpTabs(
        WidgetTester tester,
        Widget Function(int selected) body,
        void Function(ValueChanged<int> select) capture,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CompappTheme.light,
            home: _Tabs(
              builder: (selected, select) {
                capture(select);
                return _shell(
                  tester,
                  selectedIndex: selected,
                  onTabSelected: select,
                  body: body(selected),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('a keyboard user lands on the first stop of the new body', (
        tester,
      ) async {
        _keyboardMode();
        late ValueChanged<int> select;
        await pumpTabs(
          tester,
          (selected) => _Probe(key: ValueKey(selected), name: 'tab$selected'),
          (s) => select = s,
        );
        await tester.tap(_field(0));
        await tester.pump();
        expect(_focused(), 'field 0');

        select(2);
        await tester.pumpAndSettle();

        expect(_focused(), 'field 0');
        expect(
          FocusManager.instance.primaryFocus!.parent,
          isNotNull,
          reason: 'an attached node',
        );
        expect(find.byType(TextField), findsOneWidget);
        expect(
          tester
              .state<EditableTextState>(find.byType(EditableText))
              .widget
              .focusNode
              .hasPrimaryFocus,
          isTrue,
          reason: 'the field of the new tab, not the one of the old',
        );
      });

      testWidgets(
        'a new body with nothing to focus hands over to the nav bar',
        (tester) async {
          _keyboardMode();
          late ValueChanged<int> select;
          await pumpTabs(
            tester,
            (selected) => selected == 0
                ? const _Probe(name: 'tab0')
                : const SizedBox.expand(key: Key('test.body')),
            (s) => select = s,
          );
          await tester.tap(_field(0));
          await tester.pump();

          select(1);
          await tester.pumpAndSettle();

          expect(
            _focused(),
            'nav.home',
            reason: 'the first stop of the nav bar',
          );
        },
      );

      testWidgets('every change hands over, not only the first', (
        tester,
      ) async {
        _keyboardMode();
        late ValueChanged<int> select;
        await pumpTabs(
          tester,
          (selected) => _Probe(key: ValueKey(selected), name: 'tab$selected'),
          (s) => select = s,
        );
        for (final tab in [1, 2, 3]) {
          await tester.tap(_field(0));
          await tester.pump();
          await tester.enterText(_field(0), 'text');

          select(tab);
          await tester.pumpAndSettle();

          expect(_focused(), 'field 0', reason: 'tab $tab');
          expect(find.text('text'), findsNothing, reason: 'a fresh body');
        }
      });

      testWidgets('with touch focus is not moved', (tester) async {
        late ValueChanged<int> select;
        await pumpTabs(
          tester,
          (selected) => _Probe(key: ValueKey(selected), name: 'tab$selected'),
          (s) => select = s,
        );
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTouch;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await tester.tap(_field(0));
        await tester.pump();

        select(2);
        await tester.pumpAndSettle();

        expect(_focused(), anyOf('none', 'other'));
        expect(tester.testTextInput.isVisible, isFalse);
      });

      testWidgets('focus that was in the bar stays there', (tester) async {
        _keyboardMode();
        late ValueChanged<int> select;
        await pumpTabs(
          tester,
          (selected) => _Probe(key: ValueKey(selected), name: 'tab$selected'),
          (s) => select = s,
        );
        await _tab(tester);
        expect(_focused(), 'bell');

        select(2);
        await tester.pumpAndSettle();

        expect(_focused(), 'bell');
      });

      testWidgets('focus that moved on before the frame is not taken back', (
        tester,
      ) async {
        _keyboardMode();
        late ValueChanged<int> select;
        await pumpTabs(
          tester,
          (selected) => _Probe(key: ValueKey(selected), name: 'tab$selected'),
          (s) => select = s,
        );
        await tester.tap(_field(0));
        await tester.pump();

        select(2);
        Focus.of(
          tester.element(
            find.descendant(of: _bell, matching: find.byType(AppIcon)),
          ),
        ).requestFocus();
        await tester.pumpAndSettle();

        expect(_focused(), 'bell');
      });
    });
  });

  group('SnackBars', () {
    for (final keyboard in [0.0, 270.0]) {
      testWidgets('a SnackBar from a tab body sits above the nav bar and the '
          'keyboard, keyboard $keyboard', (tester) async {
        await _pump(
          tester,
          _shell(
            tester,
            body: Builder(
              builder: (context) => TextButton(
                key: const Key('test.body'),
                onPressed: () =>
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Saved'))),
                child: const Text('Show'),
              ),
            ),
          ),
          keyboard: keyboard,
          homeIndicator: 34,
        );
        await tester.tap(_body);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final snack = tester.getRect(find.byType(SnackBar));
        final limit = keyboard > 0
            ? 640 - keyboard
            : tester.getRect(_navLandmark).top;
        expect(snack.bottom, lessThanOrEqualTo(limit));
        expect(snack.bottom, greaterThan(limit - 24), reason: 'right above it');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('semantics', () {
    testWidgets('a heading, the bar buttons, the body and a navigation '
        'landmark, in that order', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _shell(
          tester,
          body: const Text('Body text', key: Key('test.body')),
          destinations: _destinations(calendarBadge: 2),
        ),
      );

      final labels = [
        for (final node in semanticsNodes(tester))
          if (node.label.isNotEmpty) node.label,
      ];
      const ours = {
        _title,
        'Activity',
        'Your account',
        'Body text',
        'Main',
        'Home',
        'Things',
        'Tasks',
        'Calendar, 2 new events',
      };
      expect(labels.where(ours.contains).toList().sublist(3), [
        'Body text',
        'Main',
        'Home',
        'Things',
        'Tasks',
        'Calendar, 2 new events',
      ]);
      expect(
        labels.where(ours.contains).take(3),
        unorderedEquals([_title, 'Activity', 'Your account']),
      );
      expect(
        tester
            .getSemantics(_heading)
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      expect(
        tester.getSemantics(_navLandmark).getSemanticsData().role,
        SemanticsRole.navigation,
      );
      expect(
        tester
            .getSemantics(_nav('home'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });
  });

  group('layout contract', () {
    testWidgets('dry layout and intrinsics agree with the real layout', (
      tester,
    ) async {
      for (final keyboard in [0.0, 270.0]) {
        await _pump(
          tester,
          _shell(
            tester,
            body: const SizedBox(key: Key('test.body'), height: 40),
          ),
          size: const Size(320, 568),
          textScale: 2,
          keyboard: keyboard,
          statusBar: 24,
        );
        final render = tester.renderObject<RenderBox>(_shellLayout);

        expect(render.getDryLayout(render.constraints), render.size);
        expect(
          render.getDryLayout(const BoxConstraints(maxWidth: 200)).width,
          200,
        );
        final header = tester.getSize(find.byType(AppTopBar)).height;
        final bar = tester.renderObject<RenderBox>(find.byType(AppTopBar));
        expect(
          render.getMinIntrinsicHeight(320),
          bar.getMinIntrinsicHeight(320) + 40,
          reason: 'the header and the body, as a column',
        );
        expect(
          render.getMaxIntrinsicHeight(320),
          bar.getMaxIntrinsicHeight(320) + 40,
        );
        expect(
          render.getMinIntrinsicWidth(100),
          greaterThanOrEqualTo(bar.getMinIntrinsicWidth(100)),
        );
        if (keyboard == 0) {
          final column = render.getDryLayout(
            const BoxConstraints(minWidth: 320, maxWidth: 320),
          );
          expect(column.height, greaterThan(header));
        }
      }
    });
  });
}

import 'dart:ui' show Tristate;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

ActivityEntry _entry(
  String id, {
  String actor = 'Carlos',
  String message = 'asked you to free the oven',
  String? meta = 'Oven · 4 min ago',
  AppIcons icon = AppIcons.oven,
}) => ActivityEntry(
  view: ActivityView(
    id: id,
    icon: icon,
    text: [ActivityText('$actor ', strong: true), ActivityText(message)],
    meta: meta,
  ),
  semanticLabel: '$actor $message',
);

ActivityListView _view({
  List<ActivityEntry>? unread,
  List<ActivityEntry>? earlier,
  String unreadTitle = 'New',
  String unreadLabel = 'New, 2 unread',
  String unreadPrefix = 'Unread',
  int? unreadCount,
  String earlierTitle = 'Earlier',
  String markAll = 'Mark all as read',
  String emptyTitle = 'Nothing new yet',
  String emptyBody = 'When someone does something, you will see it here.',
}) => ActivityListView(
  unread:
      unread ??
      [
        _entry('oven'),
        _entry(
          'calendar',
          message: 'added “Sara stays over”',
          meta: 'Calendar · 1 h ago',
          icon: AppIcons.calendar,
        ),
      ],
  earlier:
      earlier ??
      [
        const ActivityEntry(
          view: ActivityView(
            id: 'draw',
            icon: AppIcons.draw,
            text: [
              ActivityText('Room draw: you got '),
              ActivityText('Bedroom 1', strong: true),
            ],
          ),
          semanticLabel: 'Room draw: you got Bedroom 1',
        ),
      ],
  unreadTitle: unreadTitle,
  unreadSemanticLabel: unreadLabel,
  unreadPrefix: unreadPrefix,
  unreadCount: unreadCount,
  earlierTitle: earlierTitle,
  markAllReadLabel: markAll,
  emptyTitle: emptyTitle,
  emptyBody: emptyBody,
);

ActivityList _list({
  ActivityListView? view,
  ValueChanged<String>? onOpen,
  VoidCallback? onMarkAllRead,
}) => ActivityList(
  view: view ?? _view(),
  onOpen: onOpen ?? (_) {},
  onMarkAllRead: onMarkAllRead ?? () {},
);

Finder _row(String id) => find.byKey(Key('activity.$id'));
Finder get _unreadHeading => find.byKey(const Key('activity.group.unread'));
Finder get _earlierHeading => find.byKey(const Key('activity.group.earlier'));
Finder get _markAll => find.byKey(const Key('activity.markAllRead'));
Finder get _listFinder => find.byKey(const Key('activity.list'));
Finder _card(String group) => find.byKey(Key('activity.card.$group'));

/// Entries `e0` to `e{count-1}`, all distinct, for a long feed.
List<ActivityEntry> _many(int count) => [
  for (var i = 0; i < count; i++) _entry('e$i', actor: 'Member $i'),
];

/// The children of [node] in traversal order.
List<SemanticsNode> _children(SemanticsNode node) {
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  return children;
}

/// A widget test on a surface tall enough for the whole list, so the column
/// never overflows the test window: the list is not a scrollable.
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

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    _widgets('lists the new entries, then the earlier ones, in order', (
      tester,
    ) async {
      await tester.pumpWidget(host(_list()));

      expect(find.byType(ActivityRow), findsNWidgets(3));
      final oven = tester.getRect(_row('oven'));
      final calendar = tester.getRect(_row('calendar'));
      final draw = tester.getRect(_row('draw'));
      expect(oven.top, lessThan(calendar.top));
      expect(calendar.bottom, lessThan(draw.top));
      expect(
        tester.getTopLeft(_unreadHeading).dy,
        lessThan(tester.getTopLeft(_row('oven')).dy),
      );
      expect(
        tester.getTopLeft(_earlierHeading).dy,
        greaterThan(tester.getBottomLeft(_row('calendar')).dy),
      );
    });

    _widgets('shows the heading texts and the count of the new ones', (
      tester,
    ) async {
      await tester.pumpWidget(host(_list()));

      expect(
        find.descendant(of: _unreadHeading, matching: find.text('New')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _earlierHeading, matching: find.text('Earlier')),
        findsOneWidget,
      );
      final badge = tester.widget<AppBadge>(find.byType(AppBadge));
      expect(badge.count, 2);
      expect(
        find.descendant(of: _unreadHeading, matching: find.byType(AppBadge)),
        findsOneWidget,
        reason: 'the count is only on the first heading',
      );
      expect(
        find.descendant(of: _earlierHeading, matching: find.byType(AppBadge)),
        findsNothing,
      );
    });

    _widgets('the count follows the number of new entries', (tester) async {
      await tester.pumpWidget(host(_list(view: _view(unread: _many(5)))));

      expect(tester.widget<AppBadge>(find.byType(AppBadge)).count, 5);
    });

    _widgets('only the new entries have the unread dot', (tester) async {
      await tester.pumpWidget(host(_list()));

      final dots = find.byType(AppStatusDot);
      expect(dots, findsNWidgets(2));
      for (final id in ['oven', 'calendar']) {
        expect(
          find.descendant(of: _row(id), matching: dots),
          findsOneWidget,
          reason: id,
        );
      }
      expect(find.descendant(of: _row('draw'), matching: dots), findsNothing);
    });

    _widgets('a tap on a row gives the id of the entry', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(host(_list(onOpen: opened.add)));

      await tester.tap(_row('calendar'));
      await tester.tap(_row('draw'));
      await tester.tap(_row('oven'));

      expect(opened, ['calendar', 'draw', 'oven']);
    });

    _widgets('mark all as read is a ghost action that calls the callback', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(host(_list(onMarkAllRead: () => calls++)));

      final button = tester.widget<AppButton>(_markAll);
      expect(button.label, 'Mark all as read');
      expect(button.variant, AppButtonVariant.ghost);
      await tester.tap(_markAll);

      expect(calls, 1);
    });

    _widgets('a group with no entries is left out, with its action', (
      tester,
    ) async {
      await tester.pumpWidget(host(_list(view: _view(unread: const []))));

      expect(_unreadHeading, findsNothing);
      expect(_markAll, findsNothing);
      expect(find.byType(AppBadge), findsNothing);
      expect(find.byType(AppStatusDot), findsNothing);
      expect(_earlierHeading, findsOneWidget);
      expect(find.byType(ActivityRow), findsOneWidget);
      expect(
        tester.getRect(_listFinder).top,
        tester.getRect(_earlierHeading).top,
        reason: 'no gap where the first group would be',
      );

      await tester.pumpWidget(host(_list(view: _view(earlier: const []))));

      expect(_earlierHeading, findsNothing);
      expect(_unreadHeading, findsOneWidget);
      expect(_markAll, findsOneWidget);
      expect(find.byType(ActivityRow), findsNWidgets(2));
      expect(
        tester.getRect(_listFinder).bottom,
        tester.getRect(_card('unread')).bottom,
        reason: 'no gap where the second group would be',
      );
    });

    _widgets('with nothing at all it is the empty state, with no action', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _list(
            view: _view(unread: const [], earlier: const []),
          ),
        ),
      );

      expect(_listFinder, findsOneWidget, reason: 'the root key stays');
      expect(find.byType(ActivityRow), findsNothing);
      expect(find.byType(AppButton), findsNothing);
      final empty = tester.widget<AppEmptyState>(
        find.byKey(const Key('activity.empty')),
      );
      expect(empty.title, 'Nothing new yet');
      expect(empty.body, 'When someone does something, you will see it here.');
      expect(empty.actionLabel, isNull);
      expect(find.text('Nothing new yet'), findsOneWidget);
    });

    _widgets('the empty state shows its own words, not the headings', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _list(
            view: _view(
              unread: const [],
              earlier: const [],
              emptyTitle: 'Quiet here',
              emptyBody: 'Come back later.',
            ),
          ),
        ),
      );

      expect(find.text('Quiet here'), findsOneWidget);
      expect(find.text('Come back later.'), findsOneWidget);
      expect(find.text('New'), findsNothing);
      expect(find.text('Earlier'), findsNothing);
    });

    _widgets('the rows fill the width of the list', (tester) async {
      await tester.pumpWidget(host(_list()));

      expect(tester.getSize(_listFinder).width, hostWidth);
      final card = tester.getRect(_card('unread'));
      expect(card.width, hostWidth);
      final row = tester.getRect(_row('oven'));
      expect(row.left, card.left + AppSpacing.xs);
      expect(row.right, card.right - AppSpacing.xs);
    });
  });

  group('keys and identity', () {
    _widgets('the rows are keyed by entry id, not by position', (tester) async {
      final a = _entry('a', actor: 'Ana');
      final b = _entry('b', actor: 'Bea');
      await tester.pumpWidget(host(_list(view: _view(unread: [a, b]))));
      final elementA = tester.element(_row('a'));
      final elementB = tester.element(_row('b'));
      expect(
        tester.getTopLeft(_row('a')).dy,
        lessThan(tester.getTopLeft(_row('b')).dy),
      );

      await tester.pumpWidget(host(_list(view: _view(unread: [b, a]))));

      expect(
        tester.getTopLeft(_row('b')).dy,
        lessThan(tester.getTopLeft(_row('a')).dy),
      );
      expect(tester.element(_row('a')), same(elementA));
      expect(tester.element(_row('b')), same(elementB));
    });

    _widgets('the list, the headings and the cards have their keys', (
      tester,
    ) async {
      await tester.pumpWidget(host(_list()));

      for (final key in [
        'activity.list',
        'activity.group.unread',
        'activity.group.earlier',
        'activity.card.unread',
        'activity.card.earlier',
        'activity.markAllRead',
        'activity.oven',
        'activity.calendar',
        'activity.draw',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
    });

    _widgets('an id in both lists is a mistake the debug build reports', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _list(
            view: _view(unread: [_entry('same')], earlier: [_entry('same')]),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    test('a view needs its words and its spoken labels', () {
      expect(() => _view(unreadLabel: ''), throwsAssertionError);
      expect(() => _view(unreadTitle: ''), throwsAssertionError);
      expect(() => _view(earlierTitle: ''), throwsAssertionError);
      expect(() => _view(markAll: ''), throwsAssertionError);
      expect(() => _view(emptyTitle: ''), throwsAssertionError);
      expect(() => _view(emptyBody: ''), throwsAssertionError);
    });
  });

  group('scrolling', () {
    Widget scrollHost(Widget list, {required Widget Function(Widget) wrap}) =>
        host(SizedBox(height: 480, child: wrap(list)));

    final longView = _view(unread: _many(3), earlier: _many(0));
    final hugeView = ActivityListView(
      unread: [for (final e in _many(40)) e],
      earlier: [for (var i = 0; i < 160; i++) _entry('old$i', actor: 'Old $i')],
      unreadTitle: 'New',
      unreadSemanticLabel: 'New, 40 unread',
      unreadPrefix: 'Unread',
      earlierTitle: 'Earlier',
      markAllReadLabel: 'Mark all as read',
      emptyTitle: 'Empty',
      emptyBody: 'Nothing.',
    );

    _widgets('works as the child of a ListView and scrolls to its end', (
      tester,
    ) async {
      final opened = <String>[];
      await tester.pumpWidget(
        scrollHost(
          _list(view: hugeView, onOpen: opened.add),
          wrap: (list) => ListView(children: [list]),
        ),
      );

      await tester.ensureVisible(_row('old159'));
      await tester.pump();
      await tester.tap(_row('old159'));

      expect(tester.takeException(), isNull);
      expect(opened, ['old159']);
      expect(find.byType(ActivityRow), findsNWidgets(200));
    });

    _widgets('works inside a CustomScrollView with a sliver adapter', (
      tester,
    ) async {
      await tester.pumpWidget(
        scrollHost(
          _list(view: hugeView),
          wrap: (list) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: list),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      );
      final top = tester.getTopLeft(_row('e0')).dy;

      await tester.drag(find.byType(Scrollable), const Offset(0, -300));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(_row('e0')).dy, lessThan(top));
      expect(
        tester.getSize(_listFinder).height,
        greaterThan(480),
        reason: 'it takes the height of every row, the scrollable scrolls',
      );
    });

    _widgets('works inside a SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        scrollHost(
          _list(view: longView),
          wrap: (list) => SingleChildScrollView(child: list),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ActivityRow), findsNWidgets(3));
    });

    _widgets('has no scrollable of its own', (tester) async {
      await tester.pumpWidget(host(_list(view: longView)));

      expect(
        find.descendant(of: _listFinder, matching: find.byType(Scrollable)),
        findsNothing,
      );
    });
  });

  group('semantics', () {
    List<String> labels(WidgetTester tester) => semanticsLabels(tester);

    _widgets('reads headings, the action and one button per entry', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_list()));

      expect(labels(tester), [
        'New, 2 unread',
        'Mark all as read',
        'Unread. Carlos asked you to free the oven',
        'Unread. Carlos added “Sara stays over”',
        'Earlier',
        'Room draw: you got Bedroom 1',
      ], reason: 'every spoken thing once, in reading order');
      handle.dispose();
    });

    _widgets('both headings are heading nodes, and nothing else is', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_list()));

      final headings = [
        for (final node in semanticsNodes(tester))
          if (node.getSemanticsData().flagsCollection.isHeader) node,
      ];
      expect(
        [for (final node in headings) node.label],
        ['New, 2 unread', 'Earlier'],
      );
      for (final node in headings) {
        final data = node.getSemanticsData();
        expect(data.flagsCollection.isButton, isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
      }
      handle.dispose();
    });

    _widgets('the count is said in the heading, once', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_list()));

      final text = labels(tester).join('|');
      expect('2 unread'.allMatches(text).length, 1);
      expect(
        labels(tester).where((label) => label == '2'),
        isEmpty,
        reason: 'the badge number is not a node of its own',
      );
      expect(
        labels(tester).where((label) => label == 'New'),
        isEmpty,
        reason: 'the visible heading is not said again after the label',
      );
      handle.dispose();
    });

    _widgets('every entry is one button named by its spoken label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final opened = <String>[];
      await tester.pumpWidget(host(_list(onOpen: opened.add)));

      for (final (id, label) in [
        ('oven', 'Unread. Carlos asked you to free the oven'),
        ('draw', 'Room draw: you got Bedroom 1'),
      ]) {
        final nodes = [
          for (final node in semanticsNodes(tester))
            if (node.label == label) node,
        ];
        expect(nodes, hasLength(1), reason: '$id said once');
        final data = nodes.single.getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue, reason: id);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue, reason: id);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: id);
      }
      tester.semantics.tap(
        find.semantics.byLabel('Unread. Carlos asked you to free the oven'),
      );
      expect(opened, ['oven']);
      handle.dispose();
    });

    _widgets('the card is a list and each entry a list item', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_list()));

      final roles = [
        for (final node in semanticsNodes(tester)) node.getSemanticsData().role,
      ];
      expect(roles.where((role) => role == SemanticsRole.list), hasLength(2));
      expect(
        roles.where((role) => role == SemanticsRole.listItem),
        hasLength(3),
      );
      for (final node in semanticsNodes(tester)) {
        if (node.getSemanticsData().role != SemanticsRole.listItem) continue;
        var buttons = 0;
        node.visitChildren((child) {
          if (child.getSemanticsData().flagsCollection.isButton) buttons++;
          return true;
        });
        expect(buttons, 1, reason: 'one button node under each list item');
        expect(node.label, isEmpty, reason: 'the item says nothing itself');
      }
      handle.dispose();
    });

    _widgets('the action is a button named by its visible label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_list()));

      final data = tester
          .getSemantics(find.text('Mark all as read'))
          .getSemanticsData();
      expect(data.label, 'Mark all as read');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    for (final (parent, wrap) in <(String, Widget Function(Widget))>[
      (
        'ListView',
        (list) => SizedBox(height: 600, child: ListView(children: [list])),
      ),
      ('Card', (list) => Card(child: list)),
      (
        'labeled container',
        (list) => Semantics(container: true, label: 'Activity', child: list),
      ),
    ]) {
      _widgets('says the same things once under a $parent', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(wrap(_list())));

        final spoken = labels(tester).where((label) => label != 'Activity');
        expect(spoken, [
          'New, 2 unread',
          'Mark all as read',
          'Unread. Carlos asked you to free the oven',
          'Unread. Carlos added “Sara stays over”',
          'Earlier',
          'Room draw: you got Bedroom 1',
        ]);
        for (final label in spoken) {
          expect(
            [
              for (final node in semanticsNodes(tester))
                if (node.label.contains(label)) node,
            ],
            hasLength(1),
            reason: '"$label" is in one node under $parent',
          );
        }
        final heading = tester.getSemantics(_unreadHeading).getSemanticsData();
        expect(heading.flagsCollection.isHeader, isTrue);
        final row = tester.getSemantics(_row('oven')).getSemanticsData();
        expect(row.flagsCollection.isButton, isTrue);
        expect(row.label, 'Unread. Carlos asked you to free the oven');
        handle.dispose();
      });
    }

    _widgets('the empty state is one group, without a button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          _list(
            view: _view(unread: const [], earlier: const []),
          ),
        ),
      );

      expect(labels(tester), [
        'Nothing new yet\nWhen someone does something, you will see it here.',
      ]);
      expect([
        for (final node in semanticsNodes(tester))
          if (node.getSemanticsData().flagsCollection.isButton) node,
      ], isEmpty);
      handle.dispose();
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      _widgets('the card is the surface with a hairline edge ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(host(_list(), theme: theme));
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final card = tester.getRect(_card('unread')).shift(-boundary);

        final inside = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: card.deflate(AppSpacing.md),
        );
        expect(
          countPixels(inside, scheme.surfaceContainerLowest),
          greaterThan(card.width * 4),
          reason: 'the fill of the card is painted',
        );
        final top = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: Rect.fromLTWH(
            card.left + AppRadius.md,
            card.top,
            card.width - 2 * AppRadius.md,
            AppSizes.hairline,
          ),
        );
        expect(
          countPixels(top, scheme.outlineVariant),
          greaterThan(card.width ~/ 2),
          reason: 'the edge is the hairline color, not the ink',
        );
      });

      _widgets('the headings are muted ink on the page ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(_list(), theme: theme, background: scheme.surface),
        );

        final unread = tester.getCenter(
          find.descendant(of: _unreadHeading, matching: find.text('New')),
        );
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final color = await paintedColorAt(
          tester,
          hostBoundaryKey,
          unread - boundary,
        );
        expect(color, scheme.onSurfaceVariant);
      });

      test('the heading reaches 4.5:1 on the page ($name)', () {
        expectContrast(
          {'heading': (scheme.onSurfaceVariant, scheme.surface)},
          minimum: 4.5,
          reason: name,
        );
      });

      _widgets('the unread dot is painted primary, a read row has none '
          '($name)', (tester) async {
        await tester.pumpWidget(host(_list(), theme: theme));
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        for (final (id, painted) in [('oven', true), ('draw', false)]) {
          final pixels = await paintedPixels(
            tester,
            hostBoundaryKey,
            region: tester.getRect(_row(id)).shift(-boundary),
          );
          expect(
            countPixels(pixels, scheme.primary) > 20,
            painted,
            reason: '$id: the dot is the one primary thing in the row',
          );
        }
      });
    }

    _widgets('has no color of its own: no danger, no busy', (tester) async {
      final scheme = CompappTheme.light.colorScheme;
      await tester.pumpWidget(host(_list()));

      final pixels = await paintedPixels(tester, hostBoundaryKey);
      expect(countPixels(pixels, scheme.error), 0);
      expect(countPixels(pixels, scheme.errorContainer), 0);
    });
  });

  group('right to left', () {
    // Real fonts: with the test font the action is wider than the real one and
    // would wrap under the heading even at 1.0.
    setUpAll(loadBundledFonts);

    _widgets('mirrors: the heading starts at the right, the action at the '
        'left', (tester) async {
      await tester.pumpWidget(host(_list(), direction: TextDirection.rtl));

      final card = tester.getRect(_card('unread'));
      final heading = tester.getRect(_unreadHeading);
      final action = tester.getRect(_markAll);
      expect(heading.right, card.right);
      expect(action.left, card.left);
      expect(heading.left, greaterThan(action.right));
      expect(
        tester
            .getTopLeft(
              find.descendant(
                of: _unreadHeading,
                matching: find.byType(AppBadge),
              ),
            )
            .dx,
        lessThan(
          tester
              .getTopRight(
                find.descendant(of: _unreadHeading, matching: find.text('New')),
              )
              .dx,
        ),
        reason: 'the badge follows the title, so it is at its left',
      );
    });

    _widgets('a row has its tile at the right and its dot at the left', (
      tester,
    ) async {
      await tester.pumpWidget(host(_list(), direction: TextDirection.rtl));

      final row = tester.getRect(_row('oven'));
      final tile = tester.getRect(
        find.descendant(of: _row('oven'), matching: find.byType(AppIcon)),
      );
      final dot = tester.getRect(
        find.descendant(of: _row('oven'), matching: find.byType(AppStatusDot)),
      );
      expect(tile.center.dx, greaterThan(row.center.dx));
      expect(dot.center.dx, lessThan(row.center.dx));
    });

    _widgets('the empty state is the same in right to left', (tester) async {
      await tester.pumpWidget(
        host(
          _list(
            view: _view(unread: const [], earlier: const []),
          ),
          direction: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('activity.empty')), findsOneWidget);
    });
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const title = 'Novedades para ti desde tu última visita';
    const earlierTitle = 'Anteriores a tu última visita';
    const markAll = 'Marcar todo como leído';
    const message =
        'te pidió liberar el horno antes de que lleguen las visitas del '
        'sábado por la mañana';
    const actor = 'María de los Ángeles';

    ActivityList longList() => _list(
      view: _view(
        unread: [
          _entry(
            'long',
            actor: actor,
            message: message,
            meta: 'Horno · hace 4 min',
          ),
          _entry('short', actor: 'Luis', message: 'terminó la lavadora'),
        ],
        earlier: [_entry('old', actor: actor, message: message)],
        unreadTitle: title,
        unreadLabel: '$title, 2 sin leer',
        earlierTitle: earlierTitle,
        markAll: markAll,
      ),
    );

    _widgets(
      'the action sits on the line of the first heading at 1.0, real fonts',
      (tester) async {
        await tester.pumpWidget(host(_list()));

        expect(_markAll, findsOneWidget);
        final heading = tester.getRect(_unreadHeading);
        final action = tester.getRect(_markAll);
        expect(action.center.dy, closeTo(heading.center.dy, 0.01));
        expect(action.left, greaterThan(heading.right));
        expect(
          action.right,
          tester.getRect(_card('unread')).right,
          reason: 'the action hugs the end edge of the list',
        );
      },
    );

    for (final scale in [1.3, 1.5, 2.0]) {
      _widgets('grows at ${scale}x: no overflow, nothing clipped, no word '
          'cut', (tester) async {
        await tester.pumpWidget(host(longList()));
        final baseHeight = tester.getSize(_listFinder).height;
        final baseRow = tester.getSize(_row('long')).height;

        await tester.pumpWidget(host(longList(), textScale: scale));

        final reason = 'at ${scale}x';
        expect(tester.takeException(), isNull, reason: reason);
        final list = tester.getRect(_listFinder);
        expect(
          list.height,
          greaterThan(baseHeight),
          reason: '$reason: grows, never clamps',
        );
        expect(
          tester.getSize(_row('long')).height,
          greaterThan(baseRow),
          reason: reason,
        );
        for (final finder in [
          _unreadHeading,
          _earlierHeading,
          _markAll,
          _row('long'),
          _row('short'),
          _row('old'),
          _card('unread'),
          _card('earlier'),
        ]) {
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(list.left - 0.01));
          expect(rect.right, lessThanOrEqualTo(list.right + 0.01));
          expect(rect.bottom, lessThanOrEqualTo(list.bottom + 0.01));
        }
        final text = find.byWidgetPredicate(
          (widget) => widget is Text && widget.textSpan != null,
        );
        for (var i = 0; i < 3; i++) {
          expectNoMidWordBreaks(tester, text.at(i), bold: true, reason: reason);
        }
        expectNoMidWordBreaks(
          tester,
          find.descendant(of: _unreadHeading, matching: find.text(title)),
          reason: '$reason: the first heading',
        );
        expectNoMidWordBreaks(
          tester,
          find.descendant(
            of: _earlierHeading,
            matching: find.text(earlierTitle),
          ),
          reason: '$reason: the second heading',
        );
        expect(
          tester.getSize(_markAll).height,
          greaterThanOrEqualTo(AppSizes.controlMd),
          reason: reason,
        );
      });
    }

    _widgets('at 2.0 the action goes under the heading, whole', (tester) async {
      await tester.pumpWidget(host(longList(), textScale: 2));

      final heading = tester.getRect(_unreadHeading);
      final action = tester.getRect(_markAll);
      expect(action.top, greaterThanOrEqualTo(heading.bottom));
      expectNoMidWordBreaks(
        tester,
        find.descendant(of: _markAll, matching: find.text(markAll)),
        reason: 'the action label wraps by word',
      );
    });

    _widgets('the empty state grows too, and does not clip', (tester) async {
      final view = _view(
        unread: const [],
        earlier: const [],
        emptyTitle: 'Todavía no hay novedades en la casa',
        emptyBody:
            'Cuando alguien de la casa haga algo, lo verás aquí mismo, '
            'ordenado por día.',
      );
      await tester.pumpWidget(host(_list(view: view)));
      final base = tester.getSize(find.byKey(const Key('activity.empty')));

      await tester.pumpWidget(host(_list(view: view), textScale: 2));

      expect(tester.takeException(), isNull);
      final empty = tester.getSize(find.byKey(const Key('activity.empty')));
      expect(empty.height, greaterThan(base.height));
      expectNoMidWordBreaks(tester, find.byKey(const Key('emptyState.title')));
      expectNoMidWordBreaks(tester, find.byKey(const Key('emptyState.body')));
    });

    _widgets('right to left wraps the same way at 2.0', (tester) async {
      await tester.pumpWidget(host(longList(), textScale: 2));
      final ltr = tester.getSize(_listFinder);

      await tester.pumpWidget(
        host(longList(), textScale: 2, direction: TextDirection.rtl),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_listFinder), ltr);
    });
  });

  group('motion', () {
    _widgets('has none: nothing animates, with or without reduce motion', (
      tester,
    ) async {
      await tester.pumpWidget(host(_list()));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
  group('the number of unread entries and what the rows say', () {
    _widgets('the badge shows the count of the view, not the entries listed', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _list(
            view: _view(
              unread: _many(2),
              unreadCount: 14,
              unreadLabel: 'New, 14 unread',
            ),
          ),
        ),
      );

      expect(tester.widget<AppBadge>(find.byType(AppBadge)).count, 14);
      expect(find.byType(ActivityRow), findsNWidgets(3));
    });

    _widgets('the count defaults to the entries listed', (tester) async {
      await tester.pumpWidget(host(_list(view: _view(unread: _many(3)))));

      expect(tester.widget<AppBadge>(find.byType(AppBadge)).count, 3);
      expect(_view(unread: _many(3)).unreadCount, 3);
    });

    _widgets('the count cannot be less than the entries listed', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_list(view: _view(unread: _many(3), unreadCount: 2))),
      );

      expect(tester.takeException(), isAssertionError);
      expect(_view(unread: _many(3), unreadCount: 3).unreadCount, 3);
      expect(() => _view(unreadPrefix: ''), throwsAssertionError);
    });

    test('the view equals one with the same count and prefix only', () {
      expect(_view(unreadCount: 9), _view(unreadCount: 9));
      expect(_view(unreadCount: 9), isNot(_view(unreadCount: 8)));
      expect(_view(), isNot(_view(unreadPrefix: 'Not read')));
      expect(_view(unreadCount: 9).hashCode, _view(unreadCount: 9).hashCode);
    });

    _widgets('the list puts the prefix before unread entries only', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_list(view: _view(unreadPrefix: 'Sin leer'))),
      );

      final spoken = semanticsLabels(tester);
      expect(spoken, contains('Sin leer. Carlos asked you to free the oven'));
      expect(spoken, contains('Room draw: you got Bedroom 1'));
      expect(
        spoken.where((label) => label.startsWith('Sin leer')),
        hasLength(2),
        reason: 'the earlier entry says nothing about unread',
      );
      handle.dispose();
    });
  });

  group('focus and identity across the groups', () {
    Future<void> focusButton(WidgetTester tester, Key key) async {
      for (var i = 0; i < 40; i++) {
        final context = FocusManager.instance.primaryFocus?.context;
        final found =
            context?.findAncestorWidgetOfExactType<TextButton>()?.key == key;
        if (found) return;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      fail('focus never reached $key');
    }

    Widget changing(ValueNotifier<bool> withUnread) => host(
      ValueListenableBuilder<bool>(
        valueListenable: withUnread,
        builder: (context, value, _) =>
            _list(view: _view(unread: value ? null : const [])),
      ),
    );

    _widgets('focus and the node stay on an earlier row while the new group '
        'appears and leaves', (tester) async {
      final handle = tester.ensureSemantics();
      final withUnread = ValueNotifier(false);
      addTearDown(withUnread.dispose);
      await tester.pumpWidget(changing(withUnread));
      await focusButton(tester, const Key('activity.draw'));
      final focus = FocusManager.instance.primaryFocus;
      final node = tester.getSemantics(_row('draw')).id;
      expect(focus, isNotNull);

      for (final appears in [true, false, true, false]) {
        withUnread.value = appears;
        await tester.pump();
        await tester.pump();

        expect(
          FocusManager.instance.primaryFocus,
          same(focus),
          reason: 'focus stays on the row, appears: $appears',
        );
        expect(focus!.hasPrimaryFocus, isTrue);
        expect(
          tester.getSemantics(_row('draw')).id,
          node,
          reason: 'the node is not replaced, appears: $appears',
        );
      }
      handle.dispose();
    });

    _widgets('the row element is kept when the first group comes and goes', (
      tester,
    ) async {
      final withUnread = ValueNotifier(false);
      addTearDown(withUnread.dispose);
      await tester.pumpWidget(changing(withUnread));
      final element = tester.element(_row('draw'));

      withUnread.value = true;
      await tester.pump();
      expect(tester.element(_row('draw')), same(element));

      withUnread.value = false;
      await tester.pump();
      expect(tester.element(_row('draw')), same(element));
    });

    _widgets('after mark all as read takes the action away, focus moves to '
        'the earlier heading', (tester) async {
      final unread = ValueNotifier(true);
      addTearDown(unread.dispose);
      await tester.pumpWidget(
        host(
          ValueListenableBuilder<bool>(
            valueListenable: unread,
            builder: (context, value, _) => _list(
              view: _view(unread: value ? null : const []),
              onMarkAllRead: () => unread.value = false,
            ),
          ),
        ),
      );
      for (var i = 0; i < 40; i++) {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context?.findAncestorWidgetOfExactType<AppButton>() != null) break;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<AppButton>(),
        isNotNull,
        reason: 'the action has focus',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();

      expect(_markAll, findsNothing);
      final heading = tester.widget<Focus>(
        find.ancestor(of: _earlierHeading, matching: find.byType(Focus)).first,
      );
      expect(heading.focusNode!.hasPrimaryFocus, isTrue);
    });

    _widgets('mark all as read does not steal focus held elsewhere', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final unread = ValueNotifier(true);
      addTearDown(unread.dispose);
      await tester.pumpWidget(
        host(
          ValueListenableBuilder<bool>(
            valueListenable: unread,
            builder: (context, value, _) => _list(
              view: _view(unread: value ? null : const []),
              onMarkAllRead: () => unread.value = false,
            ),
          ),
        ),
      );
      await focusButton(tester, const Key('activity.draw'));
      final focus = FocusManager.instance.primaryFocus;

      tester.semantics.tap(find.semantics.byLabel('Mark all as read'));
      await tester.pump();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, same(focus));
      handle.dispose();
    });
  });

  group('the shape of the semantics tree', () {
    List<String> shape(SemanticsNode node, [int depth = 0]) {
      final data = node.getSemanticsData();
      final flags = data.flagsCollection;
      final line = [
        '  ' * depth,
        data.role.name,
        if (flags.isHeader) ' header',
        if (flags.isButton) ' button',
        if (data.label.isNotEmpty) ' "${data.label}"',
      ].join();
      return [
        line,
        for (final child in _children(node)) ...shape(child, depth + 1),
      ];
    }

    const expected = [
      'none',
      '  none',
      '    none header "New, 2 unread"',
      '    none button "Mark all as read"',
      '    list',
      '      listItem',
      '        none button "Unread. Carlos asked you to free the oven"',
      '      listItem',
      '        none button "Unread. Carlos added “Sara stays over”"',
      '  none',
      '    none header "Earlier"',
      '    list',
      '      listItem',
      '        none button "Room draw: you got Bedroom 1"',
    ];

    _widgets('is a root, a container per group, a heading, a list and its '
        'items', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_list()));

      expect(shape(tester.getSemantics(_listFinder)), expected);
      handle.dispose();
    });

    _widgets('the root is a node of its own above the groups', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_list(view: _view(unread: const []))));

      final whole = shape(tester.getSemantics(find.byType(Scaffold)));
      final at = whole.indexWhere((line) => line.contains('"Earlier"'));
      expect(whole.sublist(at - 2), [
        '  none',
        '    none',
        '      none header "Earlier"',
        '      list',
        '        listItem',
        '          none button "Room draw: you got Bedroom 1"',
      ], reason: 'the root, then the group, then the heading');
      handle.dispose();
    });

    _widgets('is the same in the sliver form', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 1200,
            child: CustomScrollView(
              slivers: [
                ActivityList.sliver(
                  view: _view(),
                  onOpen: (_) {},
                  onMarkAllRead: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(shape(tester.getSemantics(_listFinder)), expected);
      handle.dispose();
    });
  });

  group('the dividers', () {
    for (final (name, theme) in themes) {
      _widgets('are the line color, a hairline ($name)', (tester) async {
        await tester.pumpWidget(host(_list(), theme: theme));
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final first = tester.getRect(_row('oven')).shift(-boundary);
        final second = tester.getRect(_row('calendar')).shift(-boundary);
        final y = (first.bottom + second.top) / 2;
        final line = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: Rect.fromLTWH(first.left + 8, y - 0.5, first.width - 16, 1),
        );
        expect(
          countPixels(line, theme.colorScheme.outlineVariant),
          greaterThan(first.width ~/ 2),
        );
        final above = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: Rect.fromLTWH(first.left + 8, y - 3, first.width - 16, 1),
        );
        expect(
          countPixels(above, theme.colorScheme.outlineVariant),
          0,
          reason: 'it is one pixel thick',
        );
      });
    }
  });

  group('calm', () {
    for (final (name, theme) in themes) {
      _widgets('no danger color, with a busy entry too ($name)', (
        tester,
      ) async {
        final scheme = theme.colorScheme;
        const busy = ActivityEntry(
          view: ActivityView(
            id: 'busy',
            icon: AppIcons.washer,
            tone: ActivityTone.busy,
            text: [ActivityText('Luis ', strong: true), ActivityText('did it')],
          ),
          semanticLabel: 'Luis did it',
        );
        await tester.pumpWidget(
          host(
            _list(view: _view(unread: [busy, _entry('x')])),
            theme: theme,
          ),
        );

        final pixels = await paintedPixels(tester, hostBoundaryKey);
        expect(countPixels(pixels, scheme.error), 0);
        final colors = theme.extension<AppColors>()!;
        expect(
          countPixels(pixels, colors.busySoft),
          greaterThan(100),
          reason: 'the busy tile is painted, and it is not a danger color',
        );
      });
    }
  });

  group('the sliver form', () {
    Widget sliverHost(
      ActivityListView view, {
      ValueChanged<String>? onOpen,
      double height = 600,
      double textScale = 1,
      TextDirection direction = TextDirection.ltr,
      double width = hostWidth,
    }) => host(
      SizedBox(
        height: height,
        child: CustomScrollView(
          slivers: [
            ActivityList.sliver(
              view: view,
              onOpen: onOpen ?? (_) {},
              onMarkAllRead: () {},
            ),
          ],
        ),
      ),
      textScale: textScale,
      direction: direction,
      width: width,
    );

    ActivityListView thousand() => _view(
      unread: _many(300),
      earlier: [for (var i = 0; i < 700; i++) _entry('old$i', actor: 'Old $i')],
    );

    _widgets('builds only the rows near the viewport out of 1000', (
      tester,
    ) async {
      await tester.pumpWidget(sliverHost(thousand()));

      final built = find.byType(ActivityRow).evaluate().length;
      expect(built, greaterThan(3));
      expect(built, lessThan(30), reason: '1000 entries, $built built');
      debugPrint('sliver builds $built rows of 1000 at the top');

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      // The extent of the rows not built yet is an estimate: jump until the
      // last row is there.
      for (var i = 0; i < 6 && _row('old699').evaluate().isEmpty; i++) {
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pump();
      }

      final atEnd = find.byType(ActivityRow).evaluate().length;
      expect(atEnd, lessThan(30), reason: 'at the end, $atEnd built');
      debugPrint('sliver builds $atEnd rows of 1000 at the end');
      expect(_row('old699'), findsOneWidget);
      expect(_row('e0'), findsNothing);
    });

    _widgets('the box form builds every row, the reason for the sliver', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 600,
            child: ListView(children: [_list(view: thousand())]),
          ),
        ),
      );

      expect(find.byType(ActivityRow).evaluate().length, 1000);
      expect(tester.takeException(), isNull);
    });

    _widgets('a tap on a row gives its id, and the rows scroll', (
      tester,
    ) async {
      final opened = <String>[];
      await tester.pumpWidget(sliverHost(thousand(), onOpen: opened.add));

      await tester.tap(_row('e1'));
      await tester.drag(find.byType(Scrollable), const Offset(0, -400));
      await tester.pump();

      expect(opened, ['e1']);
      expect(_row('e0'), findsNothing, reason: 'scrolled out and not kept');
    });

    _widgets('looks the same as the box form: same sizes and positions', (
      tester,
    ) async {
      final view = _view();
      Map<String, Rect> rects() => {
        for (final key in ['oven', 'calendar', 'draw'])
          key: tester.getRect(_row(key)),
        'markAll': tester.getRect(_markAll),
        'unreadHeading': tester.getRect(_unreadHeading),
        'earlierHeading': tester.getRect(_earlierHeading),
      };
      await tester.pumpWidget(sliverHost(view, height: 1200));
      final sliver = rects();

      await tester.pumpWidget(host(_list(view: view)));

      expect(sliver, rects());
    });

    _widgets('says the same things as the box form', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(sliverHost(_view(), height: 1200));

      expect(semanticsLabels(tester), [
        'New, 2 unread',
        'Mark all as read',
        'Unread. Carlos asked you to free the oven',
        'Unread. Carlos added “Sara stays over”',
        'Earlier',
        'Room draw: you got Bedroom 1',
      ]);
      handle.dispose();
    });

    _widgets('an empty view is the empty state, with the root key', (
      tester,
    ) async {
      await tester.pumpWidget(
        sliverHost(_view(unread: const [], earlier: const [])),
      );

      expect(_listFinder, findsOneWidget);
      expect(find.byKey(const Key('activity.empty')), findsOneWidget);
      expect(find.byType(ActivityRow), findsNothing);
    });

    _widgets('keeps the row element when the new group comes and goes', (
      tester,
    ) async {
      await tester.pumpWidget(
        sliverHost(_view(unread: const []), height: 1200),
      );
      final element = tester.element(_row('draw'));

      await tester.pumpWidget(sliverHost(_view(), height: 1200));
      expect(tester.element(_row('draw')), same(element));
      await tester.pumpWidget(
        sliverHost(_view(unread: const []), height: 1200),
      );
      expect(tester.element(_row('draw')), same(element));
    });

    for (final (label, scale, direction) in [
      ('2.0 left to right', 2.0, TextDirection.ltr),
      ('2.0 right to left', 2.0, TextDirection.rtl),
      ('1.0 right to left', 1.0, TextDirection.rtl),
    ]) {
      _widgets('works at $label, in a narrow column', (tester) async {
        await tester.pumpWidget(
          sliverHost(
            _view(),
            height: 3000,
            textScale: scale,
            direction: direction,
          ),
        );

        expect(tester.takeException(), isNull);
        final card = tester.getRect(find.byType(CustomScrollView));
        final heading = tester.getRect(_unreadHeading);
        expect(
          direction == TextDirection.rtl ? heading.right : heading.left,
          direction == TextDirection.rtl ? card.right : card.left,
          reason: 'the heading starts at the start edge',
        );
        for (final id in ['oven', 'calendar', 'draw']) {
          final row = tester.getRect(_row(id));
          expect(row.left, greaterThanOrEqualTo(card.left - 0.01));
          expect(row.right, lessThanOrEqualTo(card.right + 0.01));
        }
      });
    }

    _widgets('the empty state in a sliver grows at 2.0 without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        sliverHost(
          _view(unread: const [], earlier: const []),
          textScale: 2,
          height: 3000,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
  group('the focus handoff in depth', () {
    Future<void> tabTo(
      WidgetTester tester,
      bool Function(FocusNode node) match,
    ) async {
      for (var i = 0; i < 60; i++) {
        final node = FocusManager.instance.primaryFocus;
        if (node != null && match(node)) return;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      fail('focus never reached the control');
    }

    bool insideKey(FocusNode node, Key key) {
      var found = false;
      node.context?.visitAncestorElements((element) {
        found = element.widget.key == key;
        return !found;
      });
      return found;
    }

    bool isAction(FocusNode node) =>
        node.context?.findAncestorWidgetOfExactType<AppButton>()?.key ==
        const Key('activity.markAllRead');

    // 0: new and earlier, 1: nothing unread, 2: only an earlier entry,
    // 3: everything gone.
    ActivityListView stage(int stage) => switch (stage) {
      0 => _view(),
      1 => _view(unread: const []),
      2 => _view(unread: const []),
      _ => _view(unread: const [], earlier: const []),
    };

    Widget screen({
      required ValueNotifier<int> stageOf,
      required FocusNode outside,
      required VoidCallback onMarkAllRead,
      ActivityListView Function(int stage)? views,
    }) => host(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            focusNode: outside,
            onPressed: () {},
            child: const Text('Outside'),
          ),
          ValueListenableBuilder<int>(
            valueListenable: stageOf,
            builder: (context, value, _) => _list(
              view: (views ?? stage)(value),
              onMarkAllRead: onMarkAllRead,
            ),
          ),
        ],
      ),
    );

    _widgets('a list that empties does not take focus when an earlier entry '
        'arrives later', (tester) async {
      final stageOf = ValueNotifier(0);
      final outside = FocusNode();
      addTearDown(() {
        stageOf.dispose();
        outside.dispose();
      });
      ActivityListView views(int value) => switch (value) {
        0 => _view(unread: [_entry('oven')], earlier: const []),
        1 => _view(unread: const [], earlier: const []),
        _ => _view(unread: const [], earlier: [_entry('draw')]),
      };
      await tester.pumpWidget(
        screen(
          stageOf: stageOf,
          outside: outside,
          views: views,
          onMarkAllRead: () => stageOf.value = 1,
        ),
      );
      await tabTo(tester, isAction);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(_markAll, findsNothing);
      outside.requestFocus();
      await tester.pump();
      expect(outside.hasPrimaryFocus, isTrue);

      stageOf.value = 2;
      await tester.pump();
      await tester.pump();

      expect(_earlierHeading, findsOneWidget);
      expect(
        outside.hasPrimaryFocus,
        isTrue,
        reason: 'a request made on a detached heading must not come back',
      );
    });

    _widgets('an update that comes after an await still hands focus over', (
      tester,
    ) async {
      final stageOf = ValueNotifier(0);
      final outside = FocusNode();
      addTearDown(() {
        stageOf.dispose();
        outside.dispose();
      });
      await tester.pumpWidget(
        screen(
          stageOf: stageOf,
          outside: outside,
          onMarkAllRead: () => Future<void>.delayed(
            const Duration(milliseconds: 300),
            () => stageOf.value = 1,
          ),
        ),
      );
      await tabTo(tester, isAction);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_markAll, findsOneWidget, reason: 'the app has not answered yet');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(_markAll, findsNothing);
      final heading = tester.widget<Focus>(
        find.ancestor(of: _earlierHeading, matching: find.byType(Focus)).first,
      );
      expect(heading.focusNode!.hasPrimaryFocus, isTrue);
    });

    _widgets('focus that moved elsewhere before the late update is left '
        'alone', (tester) async {
      final stageOf = ValueNotifier(0);
      final outside = FocusNode();
      addTearDown(() {
        stageOf.dispose();
        outside.dispose();
      });
      await tester.pumpWidget(
        screen(
          stageOf: stageOf,
          outside: outside,
          onMarkAllRead: () => Future<void>.delayed(
            const Duration(milliseconds: 300),
            () => stageOf.value = 1,
          ),
        ),
      );
      await tabTo(tester, isAction);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));

      outside.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(_markAll, findsNothing);
      expect(outside.hasPrimaryFocus, isTrue);
    });

    _widgets('an update that leaves something unread drops the handoff', (
      tester,
    ) async {
      final stageOf = ValueNotifier(0);
      final outside = FocusNode();
      addTearDown(() {
        stageOf.dispose();
        outside.dispose();
      });
      ActivityListView views(int value) => value == 0
          ? _view()
          : value == 1
          ? _view(unread: [_entry('oven')])
          : _view(unread: const []);
      await tester.pumpWidget(
        screen(
          stageOf: stageOf,
          outside: outside,
          views: views,
          onMarkAllRead: () => stageOf.value = 1,
        ),
      );
      await tabTo(tester, isAction);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();

      expect(_markAll, findsOneWidget, reason: 'something is still unread');
      final earlierHeading = tester.widget<Focus>(
        find.ancestor(of: _earlierHeading, matching: find.byType(Focus)).first,
      );
      expect(
        earlierHeading.focusNode!.hasPrimaryFocus,
        isFalse,
        reason: 'the action is still there, so nothing is handed over',
      );
      outside.requestFocus();
      await tester.pump();
      stageOf.value = 2;
      await tester.pump();
      await tester.pump();

      expect(outside.hasPrimaryFocus, isTrue);
    });

    _widgets('focus held outside the list is not taken by mark all as read', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final stageOf = ValueNotifier(0);
      final outside = FocusNode();
      addTearDown(() {
        stageOf.dispose();
        outside.dispose();
      });
      await tester.pumpWidget(
        screen(
          stageOf: stageOf,
          outside: outside,
          onMarkAllRead: () => stageOf.value = 1,
        ),
      );
      outside.requestFocus();
      await tester.pump();

      tester.semantics.tap(find.semantics.byLabel('Mark all as read'));
      await tester.pump();
      await tester.pump();

      expect(_markAll, findsNothing);
      expect(outside.hasPrimaryFocus, isTrue);
      handle.dispose();
    });

    _widgets('with two lists only the one whose action had focus hands it '
        'over', (tester) async {
      final a = ValueNotifier(true);
      final b = ValueNotifier(true);
      addTearDown(() {
        a.dispose();
        b.dispose();
      });
      Widget list(String id, ValueNotifier<bool> unread) =>
          ValueListenableBuilder<bool>(
            valueListenable: unread,
            builder: (context, value, _) => KeyedSubtree(
              key: ValueKey(id),
              child: _list(
                view: _view(unread: value ? null : const []),
                onMarkAllRead: () => unread.value = false,
              ),
            ),
          );
      await tester.pumpWidget(
        host(Column(children: [list('a', a), list('b', b)])),
      );
      Finder inA(Finder finder) => find.descendant(
        of: find.byKey(const ValueKey('a')),
        matching: finder,
      );
      Finder inB(Finder finder) => find.descendant(
        of: find.byKey(const ValueKey('b')),
        matching: finder,
      );
      bool hasFocus(Finder heading) => tester
          .widget<Focus>(
            find.ancestor(of: heading, matching: find.byType(Focus)).first,
          )
          .focusNode!
          .hasPrimaryFocus;

      // Focus the action of the second list and press the first one by
      // pointer: the first list had no focus, so it must not take it.
      await tabTo(
        tester,
        (node) => isAction(node) && insideKey(node, const ValueKey('b')),
      );
      final bAction = FocusManager.instance.primaryFocus;
      await tester.tap(inA(_markAll));
      await tester.pump();
      await tester.pump();

      expect(inA(_markAll), findsNothing);
      expect(inB(_markAll), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(bAction));
      expect(hasFocus(inA(_earlierHeading)), isFalse);

      // Now the second action has focus and is pressed: it hands over, and
      // the first list is not the one that gets focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();

      expect(inB(_markAll), findsNothing);
      expect(hasFocus(inB(_earlierHeading)), isTrue);
      expect(hasFocus(inA(_earlierHeading)), isFalse);
    });

    _widgets('the earlier heading is never a stop of the tab order', (
      tester,
    ) async {
      await tester.pumpWidget(host(_list()));
      final heading = tester.widget<Focus>(
        find.ancestor(of: _earlierHeading, matching: find.byType(Focus)).first,
      );
      expect(heading.focusNode!.skipTraversal, isTrue);

      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(heading.focusNode!.hasPrimaryFocus, isFalse, reason: '$i tabs');
      }
    });
  });

  group('the sliver keeps rows across inserts and reorders', () {
    Widget sliverScreen(ValueNotifier<List<String>> ids) => host(
      ValueListenableBuilder<List<String>>(
        valueListenable: ids,
        builder: (context, value, _) => SizedBox(
          height: 1200,
          child: CustomScrollView(
            slivers: [
              ActivityList.sliver(
                view: _view(
                  unread: const [],
                  earlier: [for (final id in value) _entry(id, actor: id)],
                ),
                onOpen: (_) {},
                onMarkAllRead: () {},
              ),
            ],
          ),
        ),
      ),
    );

    _widgets('element, focus and node stay with the row when one is inserted '
        'above it and when rows are reordered', (tester) async {
      final handle = tester.ensureSemantics();
      final ids = ValueNotifier(['draw', 'washer', 'joined']);
      addTearDown(ids.dispose);
      await tester.pumpWidget(sliverScreen(ids));
      for (var i = 0; i < 40; i++) {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context?.findAncestorWidgetOfExactType<TextButton>()?.key ==
            const Key('activity.washer')) {
          break;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      final focus = FocusManager.instance.primaryFocus;
      final element = tester.element(_row('washer'));
      final node = tester.getSemantics(_row('washer')).id;
      expect(focus, isNotNull);

      for (final order in [
        ['new', 'draw', 'washer', 'joined'],
        ['joined', 'washer', 'new', 'draw'],
        ['washer', 'joined', 'draw'],
      ]) {
        ids.value = order;
        await tester.pump();
        await tester.pump();

        final reason = order.join(',');
        expect(tester.element(_row('washer')), same(element), reason: reason);
        expect(FocusManager.instance.primaryFocus, same(focus), reason: reason);
        expect(tester.getSemantics(_row('washer')).id, node, reason: reason);
      }
      handle.dispose();
    });
  });
  group('the focus handoff, attached nodes and rebuilds', () {
    Future<void> tabTo(
      WidgetTester tester,
      bool Function(FocusNode node) match,
    ) async {
      for (var i = 0; i < 60; i++) {
        final node = FocusManager.instance.primaryFocus;
        if (node != null && match(node)) return;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      fail('focus never reached the control');
    }

    bool isAction(FocusNode node) =>
        node.context?.findAncestorWidgetOfExactType<AppButton>()?.key ==
        const Key('activity.markAllRead');

    FocusNode headingNode(WidgetTester tester) => tester
        .widget<Focus>(
          find
              .ancestor(of: _earlierHeading, matching: find.byType(Focus))
              .first,
        )
        .focusNode!;

    Widget screen({
      required ValueNotifier<int> stageOf,
      required ValueNotifier<int> tick,
      required FocusNode outside,
      required ActivityListView Function(int stage) views,
      required VoidCallback onMarkAllRead,
    }) => host(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            focusNode: outside,
            onPressed: () {},
            child: const Text('Outside'),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([stageOf, tick]),
            builder: (context, _) =>
                _list(view: views(stageOf.value), onMarkAllRead: onMarkAllRead),
          ),
        ],
      ),
    );

    _widgets('a heading that unmounted cannot take focus when an earlier entry '
        'arrives, even though it once had a context', (tester) async {
      final stageOf = ValueNotifier(0);
      final tick = ValueNotifier(0);
      final outside = FocusNode();
      addTearDown(() {
        stageOf.dispose();
        tick.dispose();
        outside.dispose();
      });
      ActivityListView views(int value) => switch (value) {
        0 => _view(unread: [_entry('oven')], earlier: [_entry('draw')]),
        1 => _view(unread: const [], earlier: const []),
        _ => _view(unread: const [], earlier: [_entry('draw')]),
      };
      await tester.pumpWidget(
        screen(
          stageOf: stageOf,
          tick: tick,
          outside: outside,
          views: views,
          onMarkAllRead: () => stageOf.value = 1,
        ),
      );
      await tabTo(tester, isAction);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(_markAll, findsNothing);
      expect(_earlierHeading, findsNothing, reason: 'the empty state');
      outside.requestFocus();
      await tester.pump();

      stageOf.value = 2;
      await tester.pump();
      await tester.pump();

      expect(_earlierHeading, findsOneWidget);
      expect(
        outside.hasPrimaryFocus,
        isTrue,
        reason: 'the heading that came back must not take focus',
      );
    });

    _widgets('a rebuild with the same view while the app answers does not '
        'cancel the handoff', (tester) async {
      final stageOf = ValueNotifier(0);
      final tick = ValueNotifier(0);
      final outside = FocusNode();
      addTearDown(() {
        stageOf.dispose();
        tick.dispose();
        outside.dispose();
      });
      await tester.pumpWidget(
        screen(
          stageOf: stageOf,
          tick: tick,
          outside: outside,
          views: (value) => value == 0 ? _view() : _view(unread: const []),
          onMarkAllRead: () => Future<void>.delayed(
            const Duration(milliseconds: 300),
            () => stageOf.value = 1,
          ),
        ),
      );
      await tabTo(tester, isAction);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));

      tick.value++;
      await tester.pump();
      expect(_markAll, findsOneWidget, reason: 'the app has not answered');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();

      expect(_markAll, findsNothing);
      expect(headingNode(tester).hasPrimaryFocus, isTrue);
    });

    _widgets('pressing twice before the answer still hands focus over once', (
      tester,
    ) async {
      final stageOf = ValueNotifier(0);
      final tick = ValueNotifier(0);
      final outside = FocusNode();
      addTearDown(() {
        stageOf.dispose();
        tick.dispose();
        outside.dispose();
      });
      var presses = 0;
      await tester.pumpWidget(
        screen(
          stageOf: stageOf,
          tick: tick,
          outside: outside,
          views: (value) => value == 0 ? _view() : _view(unread: const []),
          onMarkAllRead: () {
            presses++;
            Future<void>.delayed(
              const Duration(milliseconds: 300),
              () => stageOf.value = 1,
            );
          },
        ),
      );
      await tabTo(tester, isAction);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 50));
      expect(presses, 2);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();

      expect(headingNode(tester).hasPrimaryFocus, isTrue);
      // One listener per press would leave one behind when the handoff ends
      // (the end removes one): the focus manager has no other listener in this
      // app, so none may be left, with the list still on the screen.
      // The only way to ask the manager whether a listener is left.
      // ignore: invalid_use_of_protected_member
      expect(FocusManager.instance.hasListeners, isFalse);
    });

    _widgets('the index callback of the sliver ignores keys that are not a '
        'row', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 1200,
            child: CustomScrollView(
              slivers: [
                ActivityList.sliver(
                  view: _view(),
                  onOpen: (_) {},
                  onMarkAllRead: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final delegates = [
        for (final list in tester.widgetList<SliverList>(
          find.byType(SliverList),
        ))
          list.delegate as SliverChildBuilderDelegate,
      ];
      expect(delegates, hasLength(2));
      final callback = delegates.first.findChildIndexCallback!;
      expect(callback(const Key('activity.item.oven')), 0);
      expect(callback(const Key('activity.item.calendar')), 1);
      expect(callback(const Key('activity.item.nobody')), isNull);
      expect(callback(const ValueKey<String>('other')), isNull);
      expect(callback(const ValueKey<int>(3)), isNull);
      expect(callback(const Key('')), isNull);
    });
  });

  group('the focus ring of the earlier heading', () {
    for (final (name, theme) in themes) {
      _widgets('shows only while it has focus, in the ink color ($name)', (
        tester,
      ) async {
        final scheme = theme.colorScheme;
        await tester.pumpWidget(host(_list(), theme: theme));
        final node = tester
            .widget<Focus>(
              find
                  .ancestor(of: _earlierHeading, matching: find.byType(Focus))
                  .first,
            )
            .focusNode!;
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final heading = tester.getRect(_earlierHeading).shift(-boundary);
        final size = tester.getSize(_earlierHeading);
        final unfocused = await paintedPixels(tester, hostBoundaryKey);

        node.requestFocus();
        await tester.pump();

        expect(tester.getSize(_earlierHeading), size, reason: 'same layout');
        final focused = await paintedPixels(tester, hostBoundaryKey);
        final ring = heading.inflate(AppSizes.borderEmphasis + 1);
        final boundaryRect = tester.getRect(find.byKey(hostBoundaryKey));
        final width = boundaryRect.width.round();
        var differOutside = 0;
        var differInside = 0;
        for (var i = 0; i < unfocused.length; i++) {
          if (unfocused[i] == focused[i]) continue;
          final point = Offset((i % width).toDouble(), (i ~/ width).toDouble());
          if (ring.contains(point)) {
            differInside++;
          } else {
            differOutside++;
          }
        }
        expect(differInside, greaterThan(20), reason: 'the ring is drawn');
        expect(differOutside, 0, reason: 'nothing else changes');
        final around = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: Rect.fromLTWH(
            heading.left + AppSizes.borderEmphasis * 2,
            heading.top - AppSizes.borderEmphasis,
            heading.width - AppSizes.borderEmphasis * 4,
            AppSizes.borderEmphasis,
          ),
        );
        expect(
          closestColorDistance(around, scheme.onSurface),
          lessThan(0.05),
          reason: 'the ring is the ink color',
        );
        expect(
          contrastRatio(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(3),
          reason: 'at least 3:1 against the page',
        );

        node.unfocus();
        await tester.pump();
        await tester.pump();
        expect(node.hasFocus, isFalse, reason: 'unfocused');
        final after = await paintedPixels(tester, hostBoundaryKey);
        var stillDrawn = 0;
        for (var i = 0; i < unfocused.length; i++) {
          final point = Offset((i % width).toDouble(), (i ~/ width).toDouble());
          if (ring.contains(point) && unfocused[i] != after[i]) stillDrawn++;
        }
        expect(stillDrawn, 0, reason: 'it goes away with the focus');
      });
    }
  });
}

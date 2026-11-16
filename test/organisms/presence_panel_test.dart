import 'dart:ui' show Tristate;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

PresenceEntry _entry(
  String id,
  String name, {
  MemberStatus status = MemberStatus.home,
  int joinOrder = 1,
  String? subtitle = 'In the kitchen',
  String? trailing = 'since 5 h',
  bool isYou = false,
  String? label,
}) => PresenceEntry(
  member: MemberView(
    id: id,
    name: name,
    initials: name.substring(0, 1),
    joinOrder: joinOrder,
    status: status,
    isYou: isYou,
    semanticLabel: label ?? '$name, ${status.name}',
  ),
  subtitle: subtitle,
  trailing: trailing,
);

const _cooldown = KnockCooldown(
  remaining: 0.73,
  label: 'Asked',
  remainingLabel: '11 min',
  semanticLabel: "Asked who's home. You can ask again in 11 minutes",
);

PresenceBroadcast _broadcast({
  KnockCooldown? cooldown,
  String? message,
  String? hint = 'Once every 15 minutes per home',
  String label = "Who's home?",
}) => PresenceBroadcast(
  knockLabel: label,
  cooldown: cooldown,
  message: message,
  hint: hint,
);

PresenceView _view({
  PresenceGroup? home,
  PresenceGroup? away,
  PresenceGroup? invited,
  bool withInvited = true,
  PresenceBroadcast? broadcast,
}) => PresenceView(
  home:
      home ??
      PresenceGroup(
        title: 'At home',
        entries: [
          _entry('ana', 'Ana', isYou: true, label: 'Ana, you, at home'),
          _entry('carlos', 'Carlos', joinOrder: 2),
        ],
        emptyLabel: 'Nobody is home right now',
      ),
  away:
      away ??
      PresenceGroup(
        title: 'Away',
        entries: [
          _entry(
            'luis',
            'Luis',
            status: MemberStatus.away,
            joinOrder: 3,
            subtitle: 'Absence in the calendar',
            trailing: 'until Fri',
          ),
        ],
      ),
  invited: withInvited
      ? invited ??
            PresenceGroup(
              title: 'Invited',
              entries: [
                _entry(
                  'marta',
                  'Marta',
                  status: MemberStatus.invited,
                  joinOrder: 4,
                  subtitle: 'Invited by Ana',
                  trailing: 'pending',
                ),
              ],
            )
      : null,
  broadcast: broadcast ?? _broadcast(),
);

PresencePanel _panel({PresenceView? view, VoidCallback? onKnock}) =>
    PresencePanel(view: view ?? _view(), onKnock: onKnock ?? () {});

PresenceView get _cooling => _view(
  broadcast: _broadcast(cooldown: _cooldown, message: 'Carlos asked 4 min ago'),
);

PresenceView get _everyoneAway => _view(
  home: const PresenceGroup(
    title: 'At home',
    entries: [],
    emptyLabel: 'Nobody is home right now',
  ),
  away: PresenceGroup(
    title: 'Away',
    entries: [
      _entry('ana', 'Ana', status: MemberStatus.away, isYou: true),
      _entry('luis', 'Luis', status: MemberStatus.away, joinOrder: 3),
    ],
  ),
  withInvited: false,
);

Finder _section(String id) => find.byKey(Key('presence.section.$id'));
Finder _card(String id) => find.byKey(Key('presence.card.$id'));
Finder _member(String id) => find.byKey(Key('member.$id'));
Finder _row(String id) =>
    find.ancestor(of: _member(id), matching: find.byType(MemberRow));
Finder get _panelFinder => find.byKey(const Key('presence.panel'));
Finder get _knock => find.byKey(const Key('presence.knock'));
Finder get _broadcastFinder => find.byKey(const Key('presence.broadcast'));
Finder get _message => find.byKey(const Key('presence.message'));
Finder get _hint => find.byKey(const Key('presence.hint'));
Finder _heading(String id) => find.descendant(
  of: _section(id),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.header == true &&
        widget.child is Text,
  ),
);

/// The children of [node] in traversal order.
List<SemanticsNode> _children(SemanticsNode node) {
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  return children;
}

/// A widget test on a surface tall enough for the whole panel, so the column
/// never overflows the test window: the panel is not a scrollable.
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
    _widgets('lists home, away and invited, each under its heading, then the '
        'button', (tester) async {
      await tester.pumpWidget(host(_panel()));

      for (final id in ['home', 'away', 'invited']) {
        expect(_section(id), findsOneWidget, reason: id);
        expect(_card(id), findsOneWidget, reason: id);
      }
      expect(find.byType(MemberRow), findsNWidgets(4));
      final tops = [
        for (final finder in [
          _section('home'),
          _section('away'),
          _section('invited'),
          _broadcastFinder,
        ])
          tester.getTopLeft(finder).dy,
      ];
      expect(tops, [...tops]..sort(), reason: 'in reading order');
      expect(
        tester.getTopLeft(_member('ana')).dy,
        lessThan(tester.getTopLeft(_member('carlos')).dy),
      );
      expect(
        tester.getBottomLeft(_card('invited')).dy,
        lessThan(tester.getTopLeft(_knock).dy),
      );
    });

    _widgets('shows the title of each group', (tester) async {
      await tester.pumpWidget(host(_panel()));

      for (final (id, title) in [
        ('home', 'At home'),
        ('away', 'Away'),
        ('invited', 'Invited'),
      ]) {
        expect(
          find.descendant(of: _section(id), matching: find.text(title)),
          findsOneWidget,
          reason: id,
        );
      }
    });

    _widgets('each row shows its member, subtitle and trailing text', (
      tester,
    ) async {
      await tester.pumpWidget(host(_panel()));

      final luis = tester.widget<MemberRow>(_row('luis'));
      expect(luis.member.name, 'Luis');
      expect(luis.member.status, MemberStatus.away);
      expect(luis.subtitle, 'Absence in the calendar');
      expect(luis.trailing, 'until Fri');
      expect(
        find.descendant(of: _member('luis'), matching: find.text('until Fri')),
        findsOneWidget,
      );
      final marta = tester.widget<MemberRow>(_row('marta'));
      expect(marta.member.status, MemberStatus.invited);
      expect(
        tester.widget<MemberRow>(_row('ana')).member.isYou,
        isTrue,
        reason: 'the person using the app is one of the members',
      );
    });

    _widgets('the invited group is left out when the view has none', (
      tester,
    ) async {
      await tester.pumpWidget(host(_panel(view: _view(withInvited: false))));

      expect(_section('invited'), findsNothing);
      expect(find.byType(MemberRow), findsNWidgets(3));
    });

    _widgets('a group with no members and no label is left out', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _panel(
            view: _view(
              away: const PresenceGroup(title: 'Away', entries: []),
              withInvited: false,
            ),
          ),
        ),
      );

      expect(_section('away'), findsNothing);
      expect(find.text('Away'), findsNothing);
      expect(_section('home'), findsOneWidget);

      await tester.pumpWidget(
        host(
          _panel(
            view: _view(
              away: const PresenceGroup(
                title: 'Away',
                entries: [],
                emptyLabel: '',
              ),
              withInvited: false,
            ),
          ),
        ),
      );

      expect(_section('away'), findsNothing, reason: 'an empty label is none');
    });

    _widgets('everyone away says so in place of the home rows', (tester) async {
      await tester.pumpWidget(host(_panel(view: _everyoneAway)));

      expect(_section('home'), findsOneWidget);
      expect(
        find.descendant(of: _section('home'), matching: find.text('At home')),
        findsOneWidget,
        reason: 'the heading stays',
      );
      expect(find.text('Nobody is home right now'), findsOneWidget);
      expect(
        find.descendant(of: _section('home'), matching: find.byType(MemberRow)),
        findsNothing,
      );
      expect(find.byType(MemberRow), findsNWidgets(2));
      expect(_knock, findsOneWidget, reason: 'the home can still be asked');
    });

    _widgets('the button is a KnockButton with the label and the wait of the '
        'view', (tester) async {
      await tester.pumpWidget(host(_panel(view: _cooling)));

      final button = tester.widget<KnockButton>(find.byType(KnockButton));
      expect(button.label, "Who's home?");
      expect(button.cooldown, _cooldown);
      expect(find.text('Asked'), findsOneWidget);
      expect(find.text('11 min'), findsOneWidget);

      await tester.pumpWidget(host(_panel()));

      expect(
        tester.widget<KnockButton>(find.byType(KnockButton)).cooldown,
        isNull,
      );
      expect(find.text("Who's home?"), findsOneWidget);
    });

    _widgets('a tap on the button calls onKnock while the home can be asked, '
        'and not while it waits', (tester) async {
      var calls = 0;
      await tester.pumpWidget(host(_panel(onKnock: () => calls++)));

      await tester.tap(_knock);
      expect(calls, 1);

      await tester.pumpWidget(
        host(_panel(view: _cooling, onKnock: () => calls++)),
      );
      await tester.tap(_knock);

      expect(calls, 1);
    });

    _widgets('shows the message and the hint, and leaves out the missing '
        'ones', (tester) async {
      await tester.pumpWidget(host(_panel(view: _cooling)));

      expect(tester.widget<Text>(_message).data, 'Carlos asked 4 min ago');
      expect(tester.widget<Text>(_hint).data, 'Once every 15 minutes per home');

      await tester.pumpWidget(host(_panel()));
      expect(_message, findsNothing);
      expect(_hint, findsOneWidget);

      await tester.pumpWidget(
        host(
          _panel(
            view: _view(broadcast: _broadcast(hint: null, message: '')),
          ),
        ),
      );
      expect(_message, findsNothing, reason: 'an empty message is none');
      expect(_hint, findsNothing);
    });

    _widgets('fills the width it is given', (tester) async {
      await tester.pumpWidget(host(_panel()));

      expect(tester.getSize(_panelFinder).width, hostWidth);
      for (final finder in [_card('home'), _card('away'), _broadcastFinder]) {
        expect(tester.getSize(finder).width, hostWidth);
      }
    });
  });

  group('keys and identity', () {
    _widgets('has its keys', (tester) async {
      await tester.pumpWidget(host(_panel(view: _cooling)));

      for (final key in [
        'presence.panel',
        'presence.section.home',
        'presence.section.away',
        'presence.section.invited',
        'presence.card.home',
        'presence.card.away',
        'presence.card.invited',
        'presence.item.ana',
        'presence.item.carlos',
        'member.ana',
        'member.luis',
        'member.marta',
        'presence.broadcast',
        'presence.knock',
        'presence.message',
        'presence.hint',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
    });

    _widgets('the rows are keyed by member id, not by position', (
      tester,
    ) async {
      PresenceView ordered(List<String> ids) => _view(
        home: PresenceGroup(
          title: 'At home',
          entries: [for (final id in ids) _entry(id, id.toUpperCase())],
        ),
      );
      await tester.pumpWidget(host(_panel(view: ordered(['a', 'b']))));
      final a = tester.element(_member('a'));
      final b = tester.element(_member('b'));

      await tester.pumpWidget(host(_panel(view: ordered(['b', 'a']))));

      expect(
        tester.getTopLeft(_member('b')).dy,
        lessThan(tester.getTopLeft(_member('a')).dy),
      );
      expect(tester.element(_member('a')), same(a));
      expect(tester.element(_member('b')), same(b));
    });

    _widgets('a member in two groups is a mistake the debug build reports', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _panel(
            view: _view(
              away: PresenceGroup(
                title: 'Away',
                entries: [_entry('ana', 'Ana', status: MemberStatus.away)],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    test('a group and a broadcast need their words', () {
      expect(
        () => PresenceGroup(title: '', entries: const []),
        throwsAssertionError,
      );
      expect(() => _broadcast(label: ''), throwsAssertionError);
    });
  });

  group('scrolling', () {
    for (final (name, wrap) in <(String, Widget Function(Widget))>[
      ('ListView', (panel) => ListView(children: [panel])),
      (
        'CustomScrollView',
        (panel) =>
            CustomScrollView(slivers: [SliverToBoxAdapter(child: panel)]),
      ),
      ('SingleChildScrollView', (panel) => SingleChildScrollView(child: panel)),
    ]) {
      _widgets('works inside a $name and the button still answers', (
        tester,
      ) async {
        var calls = 0;
        await tester.pumpWidget(
          host(
            SizedBox(height: 360, child: wrap(_panel(onKnock: () => calls++))),
          ),
        );

        await tester.ensureVisible(_knock);
        await tester.pump();
        await tester.tap(_knock);

        expect(tester.takeException(), isNull);
        expect(calls, 1);
      });
    }

    _widgets('has no scrollable of its own', (tester) async {
      await tester.pumpWidget(host(_panel()));

      expect(
        find.descendant(of: _panelFinder, matching: find.byType(Scrollable)),
        findsNothing,
      );
    });
  });

  group('semantics', () {
    final ready = [
      'At home',
      'Ana, you, at home\nIn the kitchen\nsince 5 h',
      'Carlos, home\nIn the kitchen\nsince 5 h',
      'Away',
      'Luis, away\nAbsence in the calendar\nuntil Fri',
      'Invited',
      'Marta, invited\nInvited by Ana\npending',
      "Who's home?",
      'Once every 15 minutes per home',
    ];

    _widgets('reads each group, each member once, then the button and the '
        'words', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_panel()));

      expect(semanticsLabels(tester), ready);
      handle.dispose();
    });

    _widgets('the groups are heading nodes, and nothing else is', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_panel()));

      final headings = [
        for (final node in semanticsNodes(tester))
          if (node.getSemanticsData().flagsCollection.isHeader) node.label,
      ];
      expect(headings, ['At home', 'Away', 'Invited']);
      handle.dispose();
    });

    _widgets('every group is a list with one item per member, and the empty '
        'one is no list', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_panel()));

      List<SemanticsRole> roles() => [
        for (final node in semanticsNodes(tester)) node.getSemanticsData().role,
      ];
      expect(roles().where((r) => r == SemanticsRole.list), hasLength(3));
      expect(roles().where((r) => r == SemanticsRole.listItem), hasLength(4));

      await tester.pumpWidget(host(_panel(view: _everyoneAway)));

      expect(
        roles().where((r) => r == SemanticsRole.list),
        hasLength(1),
        reason: 'only away has rows',
      );
      expect(roles().where((r) => r == SemanticsRole.listItem), hasLength(2));
      expect(semanticsLabels(tester), contains('Nobody is home right now'));
      handle.dispose();
    });

    _widgets('a member is one node: the visible name is not said again', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_panel()));

      final nodes = [
        for (final node in semanticsNodes(tester))
          if (node.label.contains('Luis')) node,
      ];
      expect(nodes, hasLength(1));
      expect(
        nodes.single.label,
        'Luis, away\nAbsence in the calendar\nuntil Fri',
      );
      final data = nodes.single.getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    _widgets('the button is one node, enabled and named by its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var calls = 0;
      await tester.pumpWidget(host(_panel(onKnock: () => calls++)));

      final nodes = [
        for (final node in semanticsNodes(tester))
          if (node.getSemanticsData().flagsCollection.isButton) node,
      ];
      expect(nodes, hasLength(1), reason: 'the button is the only control');
      final data = nodes.single.getSemanticsData();
      expect(data.label, "Who's home?");
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      tester.semantics.tap(find.semantics.byLabel("Who's home?"));
      expect(calls, 1);
      handle.dispose();
    });

    _widgets('while it waits the same node is disabled and says the wait', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_panel()));
      final before = tester.getSemantics(_knock).id;

      await tester.pumpWidget(host(_panel(view: _cooling)));

      final node = tester.getSemantics(_knock);
      final data = node.getSemanticsData();
      expect(node.id, before, reason: 'the node is kept, so is the cursor');
      expect(data.label, "Asked who's home. You can ask again in 11 minutes");
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(
        semanticsLabels(tester).where((label) => label.contains('Asked')),
        hasLength(1),
        reason: 'the visible Asked and 11 min are not said again',
      );
      expect(
        semanticsLabels(tester).last,
        'Carlos asked 4 min ago\nOnce every 15 minutes per home',
        reason: 'the message and the hint are one node',
      );
      handle.dispose();
    });

    for (final (parent, wrap) in <(String, Widget Function(Widget))>[
      (
        'ListView',
        (panel) => SizedBox(height: 900, child: ListView(children: [panel])),
      ),
      ('Card', (panel) => Card(child: panel)),
      (
        'labeled container',
        (panel) => Semantics(container: true, label: 'Presence', child: panel),
      ),
    ]) {
      _widgets('says the same things once under a $parent', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(wrap(_panel())));

        final spoken = semanticsLabels(tester)
            .where((label) => label != 'Presence')
            .toList();
        expect(spoken, ready);
        for (final label in ready) {
          expect(
            [
              for (final node in semanticsNodes(tester))
                if (node.label == label) node,
            ],
            hasLength(1),
            reason: '"$label" is in one node under $parent',
          );
        }
        final heading = tester.getSemantics(_heading('away'));
        expect(heading.getSemanticsData().flagsCollection.isHeader, isTrue);
        handle.dispose();
      });
    }
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      _widgets('each card is the surface with a hairline edge ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(host(_panel(), theme: theme));
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));

        for (final finder in [
          _card('home'),
          _card('away'),
          _card('invited'),
          find
              .descendant(
                of: _broadcastFinder,
                matching: find.byType(DecoratedBox),
              )
              .first,
        ]) {
          final card = tester.getRect(finder).shift(-boundary);
          final inside = await paintedPixels(
            tester,
            hostBoundaryKey,
            region: Rect.fromLTWH(
              card.left + AppRadius.md,
              card.top + AppSizes.hairline + 1,
              card.width - 2 * AppRadius.md,
              2,
            ),
          );
          expect(
            countPixels(inside, scheme.surfaceContainerLowest),
            greaterThan(card.width ~/ 2),
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
        }
      });

      _widgets('the headings and the empty label are muted ink, the message '
          'is ink ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            _panel(
              view: _view(
                home: const PresenceGroup(
                  title: 'At home',
                  entries: [],
                  emptyLabel: 'Nobody is home right now',
                ),
                broadcast: _broadcast(message: 'Carlos asked 4 min ago'),
              ),
            ),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        // The first glyph of the text: the middle of a text may be a space,
        // which the test font leaves blank.
        Future<Color> colorOf(Finder finder) => paintedColorAt(
          tester,
          hostBoundaryKey,
          tester.getTopLeft(finder) + const Offset(2, 4) - boundary,
        );

        expect(
          await colorOf(
            find.descendant(
              of: _section('home'),
              matching: find.text('At home'),
            ),
          ),
          scheme.onSurfaceVariant,
        );
        expect(
          await colorOf(find.byKey(const Key('presence.empty.home'))),
          scheme.onSurfaceVariant,
        );
        expect(await colorOf(_message), scheme.onSurface);
        expect(await colorOf(_hint), scheme.onSurfaceVariant);
      });

      test('the texts reach 4.5:1 on the page and on a card ($name)', () {
        expectContrast(
          {
            'heading/page': (scheme.onSurfaceVariant, scheme.surface),
            'empty label/card': (
              scheme.onSurfaceVariant,
              scheme.surfaceContainerLowest,
            ),
            'message/card': (scheme.onSurface, scheme.surfaceContainerLowest),
            'hint/card': (
              scheme.onSurfaceVariant,
              scheme.surfaceContainerLowest,
            ),
          },
          minimum: 4.5,
          reason: name,
        );
      });

      _widgets('away is a hollow ring and at home a filled dot ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(host(_panel(), theme: theme));
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final colors = theme.extension<AppColors>()!;

        Rect dot(String id) => tester
            .getRect(
              find.descendant(
                of: _member(id),
                matching: find.byType(AppStatusDot),
              ),
            )
            .shift(-boundary);
        Future<Color> centerOf(String id) =>
            paintedColorAt(tester, hostBoundaryKey, dot(id).center);

        expect(await centerOf('carlos'), scheme.primary);
        expect(
          await centerOf('luis'),
          scheme.surfaceContainerLowest,
          reason: 'the away dot is a ring: its middle is the card, not filled',
        );
        final ring = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: dot('luis'),
        );
        expect(
          closestColorDistance(ring, colors.presenceAway),
          lessThan(0.05),
          reason: 'the ring itself is the away color',
        );
      });
    }

    for (final (name, view) in [
      ('ready', _view()),
      ('cooldown', _cooling),
      ('everyone away', _everyoneAway),
    ]) {
      _widgets('uses no danger color ($name)', (tester) async {
        final scheme = CompappTheme.light.colorScheme;
        await tester.pumpWidget(host(_panel(view: view)));

        final pixels = await paintedPixels(tester, hostBoundaryKey);
        expect(countPixels(pixels, scheme.error), 0);
      });
    }
  });

  group('right to left', () {
    setUpAll(loadBundledFonts);

    _widgets('mirrors: pebbles at the right, trailing text at the left', (
      tester,
    ) async {
      await tester.pumpWidget(host(_panel(), direction: TextDirection.rtl));

      final card = tester.getRect(_card('away'));
      final pebble = tester.getRect(
        find.descendant(of: _member('luis'), matching: find.byType(AppPebble)),
      );
      final trailing = tester.getRect(find.text('until Fri'));
      expect(pebble.right, closeTo(card.right - 12, 0.01));
      expect(trailing.left, greaterThan(card.left));
      expect(trailing.center.dx, lessThan(card.center.dx));
      expect(pebble.center.dx, greaterThan(card.center.dx));
      expect(
        tester.getTopRight(_heading('away')).dx,
        card.right,
        reason: 'the heading starts at the right',
      );
    });

    _widgets('the button is at the right and the words at its left', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_panel(view: _cooling), direction: TextDirection.rtl),
      );

      final card = tester.getRect(_broadcastFinder);
      final button = tester.getRect(_knock);
      final message = tester.getRect(_message);
      expect(button.right, closeTo(card.right - 12, 0.01));
      expect(message.right, lessThanOrEqualTo(button.left));
    });

    _widgets('the empty home label starts at the right', (tester) async {
      await tester.pumpWidget(
        host(_panel(view: _everyoneAway), direction: TextDirection.rtl),
      );

      final card = tester.getRect(_card('home'));
      expect(
        tester.getTopRight(find.byKey(const Key('presence.empty.home'))).dx,
        closeTo(card.right - 12, 0.01),
      );
    });
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const longTitle = 'Personas que están en casa ahora mismo';
    const longName = 'María de los Ángeles Vega';
    const longSubtitle = 'Ausencia en el calendario de casa';
    const longMessage = 'Carlos preguntó hace 4 minutos quién está en casa';
    const longHint = 'Una vez cada 15 minutos por cada casa';
    const longEmpty = 'Ahora mismo no hay nadie en casa, vuelve más tarde';

    PresenceView longView({bool everyoneAway = false}) => PresenceView(
      home: PresenceGroup(
        title: longTitle,
        entries: everyoneAway
            ? const []
            : [
                _entry(
                  'maria',
                  longName,
                  subtitle: longSubtitle,
                  trailing: 'desde hace 5 horas',
                ),
              ],
        emptyLabel: longEmpty,
      ),
      away: PresenceGroup(
        title: 'Fuera de casa',
        entries: [
          _entry(
            'luis',
            'Luis',
            status: MemberStatus.away,
            subtitle: longSubtitle,
            trailing: 'hasta el viernes',
          ),
        ],
      ),
      broadcast: _broadcast(
        cooldown: _cooldown,
        message: longMessage,
        hint: longHint,
        label: '¿Quién está en casa?',
      ),
    );

    _widgets('the words sit beside the button when they fit, at 1.0', (
      tester,
    ) async {
      await tester.pumpWidget(host(_panel(view: _cooling)));

      final button = tester.getRect(_knock);
      final message = tester.getRect(_message);
      final hint = tester.getRect(_hint);
      expect(message.left, greaterThanOrEqualTo(button.right));
      expect(hint.left, message.left, reason: 'one column of two lines');
      expect(message.center.dy, lessThan(hint.center.dy));
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.3, 1.5, 2.0]) {
      _widgets('grows at ${scale}x: no overflow, nothing clipped, no word '
          'cut', (tester) async {
        await tester.pumpWidget(host(_panel(view: longView())));
        final base = tester.getSize(_panelFinder).height;
        final baseMessage = tester.getSize(_message).height;

        await tester.pumpWidget(
          host(_panel(view: longView()), textScale: scale),
        );

        final reason = 'at ${scale}x';
        expect(tester.takeException(), isNull, reason: reason);
        final panel = tester.getRect(_panelFinder);
        expect(panel.height, greaterThan(base), reason: reason);
        expect(
          tester.getSize(_message).height,
          greaterThanOrEqualTo(baseMessage * scale - 1),
          reason: '$reason: the text is scaled, never clamped',
        );
        for (final finder in [
          _section('home'),
          _section('away'),
          _card('home'),
          _card('away'),
          _member('maria'),
          _member('luis'),
          _broadcastFinder,
          _knock,
          _message,
          _hint,
        ]) {
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(panel.left - 0.01));
          expect(rect.right, lessThanOrEqualTo(panel.right + 0.01));
          expect(rect.bottom, lessThanOrEqualTo(panel.bottom + 0.01));
        }
        for (final finder in [
          find.text(longTitle),
          find.text(longName),
          find.text(longSubtitle).first,
          _message,
          _hint,
        ]) {
          expectNoMidWordBreaks(tester, finder, reason: reason);
        }
        final card = tester.getRect(_broadcastFinder);
        final button = tester.getRect(_knock);
        expect(button.right, lessThanOrEqualTo(card.right));
        expect(
          button.width,
          greaterThanOrEqualTo(AppSizes.knockWidth),
          reason: reason,
        );
      });
    }

    _widgets('at 2.0 the words go under the button, whole', (tester) async {
      await tester.pumpWidget(host(_panel(view: longView()), textScale: 2));

      final button = tester.getRect(_knock);
      final message = tester.getRect(_message);
      expect(message.top, greaterThanOrEqualTo(button.bottom));
      expect(message.left, lessThan(button.right));
      expectNoMidWordBreaks(tester, _message);
    });

    _widgets('the empty home label grows and does not clip', (tester) async {
      await tester.pumpWidget(host(_panel(view: longView(everyoneAway: true))));
      final base = tester.getSize(find.text(longEmpty));

      await tester.pumpWidget(
        host(_panel(view: longView(everyoneAway: true)), textScale: 2),
      );

      expect(tester.takeException(), isNull);
      final label = tester.getRect(find.text(longEmpty));
      expect(label.height, greaterThan(base.height * 2 - 1));
      final card = tester.getRect(_card('home'));
      expect(label.left, greaterThanOrEqualTo(card.left));
      expect(label.right, lessThanOrEqualTo(card.right));
      expect(label.bottom, lessThanOrEqualTo(card.bottom));
      expectNoMidWordBreaks(tester, find.text(longEmpty));
    });

    _widgets('right to left wraps the same way at 2.0', (tester) async {
      await tester.pumpWidget(host(_panel(view: longView()), textScale: 2));
      final ltr = tester.getSize(_panelFinder);

      await tester.pumpWidget(
        host(
          _panel(view: longView()),
          textScale: 2,
          direction: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_panelFinder), ltr);
    });
  });

  group('motion', () {
    _widgets('has none of its own: nothing animates while waiting', (
      tester,
    ) async {
      await tester.pumpWidget(host(_panel(view: _cooling)));

      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
  group('identity across the groups', () {
    _widgets('a member keeps its element and its node when an earlier group '
        'gains its first member', (tester) async {
      final handle = tester.ensureSemantics();
      PresenceView view({required bool withHome}) => _view(
        home: PresenceGroup(
          title: 'At home',
          entries: [if (withHome) _entry('ana', 'Ana')],
        ),
        withInvited: false,
      );
      await tester.pumpWidget(host(_panel(view: view(withHome: false))));
      expect(_section('home'), findsNothing);
      final element = tester.element(_member('luis'));
      final node = tester.getSemantics(_member('luis')).id;

      await tester.pumpWidget(host(_panel(view: view(withHome: true))));

      expect(_section('home'), findsOneWidget);
      expect(tester.element(_member('luis')), same(element));
      expect(tester.getSemantics(_member('luis')).id, node);

      await tester.pumpWidget(host(_panel(view: view(withHome: false))));

      expect(tester.element(_member('luis')), same(element));
      expect(tester.getSemantics(_member('luis')).id, node);
      handle.dispose();
    });

    _widgets('the invited group coming and going leaves the others alone', (
      tester,
    ) async {
      await tester.pumpWidget(host(_panel(view: _view(withInvited: false))));
      final carlos = tester.element(_member('carlos'));
      final luis = tester.element(_member('luis'));
      final knock = tester.element(_knock);

      await tester.pumpWidget(host(_panel()));

      expect(tester.element(_member('carlos')), same(carlos));
      expect(tester.element(_member('luis')), same(luis));
      expect(tester.element(_knock), same(knock));
    });
  });

  group('the status of the members', () {
    for (final (name, view) in [
      (
        'away in home',
        _view(
          home: PresenceGroup(
            title: 'At home',
            entries: [_entry('luis', 'Luis', status: MemberStatus.away)],
          ),
        ),
      ),
      (
        'home in away',
        _view(
          away: PresenceGroup(title: 'Away', entries: [_entry('ana', 'Ana')]),
        ),
      ),
      (
        'home in invited',
        _view(
          invited: PresenceGroup(
            title: 'Invited',
            entries: [_entry('marta', 'Marta')],
          ),
        ),
      ),
    ]) {
      _widgets('$name is a mistake the debug build reports', (tester) async {
        await tester.pumpWidget(host(_panel(view: view)));

        expect(tester.takeException(), isAssertionError);
      });
    }

    _widgets('a group of its own status is fine', (tester) async {
      await tester.pumpWidget(host(_panel()));

      expect(tester.takeException(), isNull);
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
        if (data.label.isNotEmpty) ' "${data.label.replaceAll('\n', '|')}"',
      ].join();
      return [
        line,
        for (final child in _children(node)) ...shape(child, depth + 1),
      ];
    }

    _widgets('is a root, a container per group and one for the asking part', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_panel(view: _everyoneAway)));

      final whole = shape(tester.getSemantics(find.byType(Scaffold)));
      final at = whole.indexWhere((line) => line.contains('"At home"'));
      expect(whole.sublist(at - 2), [
        '  none',
        '    none',
        '      none header "At home"',
        '      none "Nobody is home right now"',
        '    none',
        '      none header "Away"',
        '      list',
        '        listItem',
        '          none "Ana, away|In the kitchen|since 5 h"',
        '        listItem',
        '          none "Luis, away|In the kitchen|since 5 h"',
        '    none',
        '      none button "Who\'s home?"',
        '      none "Once every 15 minutes per home"',
      ]);
      handle.dispose();
    });
  });

  group('the dividers', () {
    for (final (name, theme) in themes) {
      _widgets('are the line color, a hairline ($name)', (tester) async {
        await tester.pumpWidget(host(_panel(), theme: theme));
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final first = tester.getRect(_member('ana')).shift(-boundary);
        final second = tester.getRect(_member('carlos')).shift(-boundary);
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

  group('calm in both themes', () {
    for (final (name, theme) in themes) {
      for (final (state, view) in [
        ('ready', _view()),
        ('cooldown', _cooling),
        ('everyone away', _everyoneAway),
      ]) {
        _widgets('no danger color: $state ($name)', (tester) async {
          await tester.pumpWidget(host(_panel(view: view), theme: theme));

          final pixels = await paintedPixels(tester, hostBoundaryKey);
          expect(countPixels(pixels, theme.colorScheme.error), 0);
        });
      }
    }
  });

  group('realistic names and trailing texts', () {
    setUpAll(loadBundledFonts);

    const names = [
      'María Fernández',
      'Guillermo Domínguez',
      'Inmaculada Rodríguez',
      'Cristóbal Hernández',
    ];
    PresenceView realistic(String name) => PresenceView(
      home: PresenceGroup(
        title: 'En casa',
        entries: [
          _entry(
            'home',
            name,
            subtitle: 'En la cocina',
            trailing: 'desde hace 5 h',
          ),
        ],
      ),
      away: PresenceGroup(
        title: 'Fuera de casa',
        entries: [
          _entry(
            'away',
            name,
            status: MemberStatus.away,
            subtitle: 'De viaje',
            trailing: 'hasta el viernes',
          ),
        ],
      ),
      invited: PresenceGroup(
        title: 'Invitados',
        entries: [
          _entry(
            'invited',
            name,
            status: MemberStatus.invited,
            subtitle: 'Invitado por Ana',
            trailing: 'pendiente',
          ),
        ],
      ),
      broadcast: _broadcast(
        cooldown: _cooldown,
        message: 'Carlos preguntó hace 4 min',
        hint: 'Una vez cada 15 minutos por casa',
        label: '¿Quién está?',
      ),
    );

    for (final name in names) {
      for (final width in [320.0, 360.0]) {
        for (final direction in TextDirection.values) {
          for (final scale in [1.3, 1.5, 2.0]) {
            final id = '$name|${width.toInt()}|${direction.name}|$scale';
            _widgets('no word is cut: $id', (tester) async {
              await tester.pumpWidget(
                host(
                  _panel(view: realistic(name)),
                  width: width,
                  textScale: scale,
                  direction: direction,
                ),
              );

              expect(tester.takeException(), isNull);
              final texts = find.descendant(
                of: _panelFinder,
                matching: find.byType(Text),
              );
              final cut = <String>[];
              for (var i = 0; i < texts.evaluate().length; i++) {
                try {
                  expectNoMidWordBreaks(tester, texts.at(i));
                } on TestFailure catch (failure) {
                  cut.add('${failure.message}'.replaceAll('\n', ' '));
                }
              }
              expect(cut, isEmpty, reason: id);
            });
          }
        }
      }
    }
  });
}

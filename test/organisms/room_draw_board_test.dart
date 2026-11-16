import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/foundation/dashed_border.dart';
import 'package:compapp_design/src/foundation/equal_pair.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';
import '../helpers/word_breaks.dart';

const _ana = MemberView(
  id: 'ana',
  name: 'Ana Fernández',
  initials: 'A',
  joinOrder: 0,
  isYou: true,
  semanticLabel: 'Ana Fernández, tú, en casa',
);
const _carlos = MemberView(
  id: 'carlos',
  name: 'Carlos',
  initials: 'C',
  joinOrder: 1,
  semanticLabel: 'Carlos, en casa',
);
const _luis = MemberView(
  id: 'luis',
  name: 'Luis',
  initials: 'L',
  joinOrder: 2,
  semanticLabel: 'Luis, en casa',
);
const _sara = MemberView(
  id: 'sara',
  name: 'Sara',
  initials: 'S',
  joinOrder: 3,
  semanticLabel: 'Sara, en casa',
);

RoomDrawRoom _room(
  String id,
  String name, {
  List<MemberView> members = const [],
  String? from,
  String? caption,
  String? label,
}) {
  final line = caption ?? (members.isEmpty ? 'Queda libre' : 'desde $from');
  final who = members.map((m) => m.name).join(' y ');
  return RoomDrawRoom(
    room: RoomView(id: id, name: name),
    members: members,
    caption: line,
    semanticLabel:
        label ?? (members.isEmpty ? '$name, $line' : '$name: $who, $line'),
  );
}

List<RoomDrawRoom> _rooms() => [
  _room('b1', 'Dormitorio 1', members: [_carlos], from: 'Dormitorio 3'),
  _room('b2', 'Dormitorio 2 · 2 camas', members: [_ana], from: 'Dormitorio 1'),
  _room('b3', 'Dormitorio 3'),
  _room(
    'b4',
    'Dormitorio 4 · 2 camas',
    members: [_luis, _sara],
    from: 'Dormitorio 2',
  ),
];

RoomDrawView _view({
  String drawId = 'draw-1',
  RoomDrawStatus status = RoomDrawStatus.pending,
  bool isAdmin = true,
  List<RoomDrawRoom>? rooms,
  String? note,
}) => RoomDrawView(
  drawId: drawId,
  status: status,
  statusLabel: status == RoomDrawStatus.pending
      ? 'Pendiente de aplicar'
      : 'Aplicado',
  bedrooms: rooms ?? _rooms(),
  drawAgainLabel: 'Sortear de nuevo',
  applyLabel: 'Aplicar resultado',
  isAdmin: isAdmin,
  readOnlyNote: isAdmin
      ? null
      : note ??
            'Solo Ana Fernández puede sortear de nuevo o aplicar el '
                'resultado',
);

/// The calls the board made, in order.
class _Log {
  final calls = <String>[];
}

Widget _board(
  RoomDrawView view,
  _Log log, {
  bool draw = true,
  bool apply = true,
}) => RoomDrawBoard(
  view: view,
  onDrawAgain: draw ? () => log.calls.add('drawAgain') : null,
  onApply: apply ? () => log.calls.add('apply') : null,
);

Future<void> _pump(
  WidgetTester tester,
  RoomDrawView view, {
  _Log? log,
  bool draw = true,
  bool apply = true,
  double width = hostWidth,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  ThemeData? theme,
}) async {
  tester.view
    ..physicalSize = const Size(800, 12000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      _board(view, log ?? _Log(), draw: draw, apply: apply),
      width: width,
      textScale: textScale,
      direction: direction,
      theme: theme,
      background: (theme ?? CompappTheme.light).colorScheme.surface,
    ),
  );
}

Finder _k(String key) => find.byKey(Key(key));
Finder get _draw => _k('roomDraw.drawAgain');
Finder get _apply => _k('roomDraw.apply');
Finder get _status => _k('roomDraw.status');
Finder get _note => _k('roomDraw.note');
Finder _item(String id) => _k('roomDraw.room.$id');
Finder _tile(String id) => _k('floorplan.room.$id');
Finder _tileWidget(String id) => find.byWidgetPredicate(
  (widget) => widget is RoomTile && widget.room.id == id,
);

FocusNode _nodeOf(WidgetTester tester, Finder button) =>
    tester.widget<AppButton>(button).focusNode!;

FocusNode _statusNode(WidgetTester tester) => Focus.of(
  tester.element(find.descendant(of: _status, matching: find.byType(AppBadge))),
);

void _traditional() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

void main() {
  setUpAll(loadBundledFonts);
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows each bedroom with its caption and the people who go '
        'there', (tester) async {
      await _pump(tester, _view());

      for (final text in [
        'Dormitorio 1',
        'desde Dormitorio 3',
        'Dormitorio 2 · 2 camas',
        'desde Dormitorio 1',
        'Dormitorio 3',
        'Queda libre',
        'Dormitorio 4 · 2 camas',
        'desde Dormitorio 2',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(
        find.descendant(of: _item('b1'), matching: find.byType(AppPebble)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _tile('b4'), matching: find.byType(AppPebble)),
        findsNWidgets(2),
        reason: 'a group goes together',
      );
      expect(
        find.descendant(of: _tile('b3'), matching: find.byType(AppPebble)),
        findsNothing,
      );
      expect(find.byType(RoomTile), findsNWidgets(4));
      expect(
        tester.widgetList<RoomTile>(find.byType(RoomTile)).every((t) => t.draw),
        isTrue,
      );
    });

    testWidgets('a bedroom with people is home and a free one has the dashed '
        'outline', (tester) async {
      await _pump(tester, _view());

      expect(
        tester.widget<RoomTile>(_tileWidget('b1')).state,
        RoomTileState.home,
      );
      expect(
        tester.widget<RoomTile>(_tileWidget('b4')).state,
        RoomTileState.home,
      );
      expect(
        tester.widget<RoomTile>(_tileWidget('b3')).state,
        RoomTileState.free,
      );
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: _tile('b3'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;
      expect(decoration.shape, isA<DashedBorder>());
    });

    testWidgets('the pebbles keep the order of the group', (tester) async {
      await _pump(tester, _view(), width: 360);

      expect(
        tester.getRect(_k('roomTile.pebble.luis')).left,
        lessThan(tester.getRect(_k('roomTile.pebble.sara')).left),
      );
    });

    testWidgets('the status is a word in a badge, busy while pending and soft '
        'once applied', (tester) async {
      await _pump(tester, _view());
      var badge = tester.widget<AppBadge>(
        find.descendant(of: _status, matching: find.byType(AppBadge)),
      );
      expect(badge.label, 'Pendiente de aplicar');
      expect(badge.tone, AppBadgeTone.busy);

      await _pump(tester, _view(status: RoomDrawStatus.applied));
      badge = tester.widget<AppBadge>(
        find.descendant(of: _status, matching: find.byType(AppBadge)),
      );
      expect(badge.label, 'Aplicado');
      expect(badge.tone, AppBadgeTone.soft);
    });

    testWidgets('the card sits on the surface color with a hairline edge', (
      tester,
    ) async {
      await _pump(tester, _view());

      final box = tester.widget<DecoratedBox>(
        find.ancestor(of: _status, matching: find.byType(DecoratedBox)).first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(
        decoration.color,
        CompappTheme.light.colorScheme.surfaceContainerLowest,
      );
      expect(
        (decoration.border! as Border).top.color,
        CompappTheme.light.colorScheme.outlineVariant,
      );
    });

    testWidgets('the list is keyed by the draw id', (tester) async {
      await _pump(tester, _view(drawId: 'draw-7'));

      expect(_k('roomDraw.draw-7'), findsOneWidget);
      expect(_k('roomDraw.board'), findsOneWidget);
    });
  });

  group('who sees what', () {
    testWidgets('the admin of a pending draw sees both buttons, Draw again '
        'first', (tester) async {
      await _pump(tester, _view());

      expect(_draw, findsOneWidget);
      expect(_apply, findsOneWidget);
      expect(_note, findsNothing);
      expect(tester.getRect(_draw).left, lessThan(tester.getRect(_apply).left));
      expect(
        tester.widget<AppButton>(_draw).variant,
        AppButtonVariant.secondary,
      );
      expect(
        tester.widget<AppButton>(_apply).variant,
        AppButtonVariant.primary,
      );
      expect(find.text('Sortear de nuevo'), findsOneWidget);
      expect(find.text('Aplicar resultado'), findsOneWidget);
    });

    testWidgets('an applied draw offers Draw again alone, over the whole '
        'width', (tester) async {
      await _pump(tester, _view(status: RoomDrawStatus.applied));

      expect(_apply, findsNothing);
      expect(_draw, findsOneWidget);
      expect(
        tester.getSize(_draw).width,
        tester.getSize(_k('roomDraw.board')).width,
      );
    });

    testWidgets('a member sees the note and no button, pending or applied', (
      tester,
    ) async {
      for (final status in RoomDrawStatus.values) {
        await _pump(tester, _view(status: status, isAdmin: false));

        expect(_draw, findsNothing, reason: status.name);
        expect(_apply, findsNothing, reason: status.name);
        expect(find.byType(AppButton), findsNothing);
        expect(
          find.text(
            'Solo Ana Fernández puede sortear de nuevo o aplicar el '
            'resultado',
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('an admin never sees the note, even if the view carries one', (
      tester,
    ) async {
      await _pump(
        tester,
        RoomDrawView(
          drawId: 'draw-1',
          status: RoomDrawStatus.pending,
          statusLabel: 'Pendiente de aplicar',
          bedrooms: _rooms(),
          drawAgainLabel: 'Sortear de nuevo',
          applyLabel: 'Aplicar resultado',
          isAdmin: true,
          readOnlyNote: 'Solo Ana decide',
        ),
      );

      expect(_note, findsNothing);
      expect(find.text('Solo Ana decide'), findsNothing);
    });

    testWidgets('a member gets no button even with callbacks', (tester) async {
      await _pump(tester, _view(isAdmin: false));

      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('a null callback hides its button, it never disables it', (
      tester,
    ) async {
      await _pump(tester, _view(), apply: false);
      expect(_apply, findsNothing);
      expect(tester.widget<AppButton>(_draw).onPressed, isNotNull);

      await _pump(tester, _view(), draw: false);
      expect(_draw, findsNothing);
      expect(tester.widget<AppButton>(_apply).onPressed, isNotNull);

      await _pump(tester, _view(), draw: false, apply: false);
      expect(find.byType(AppButton), findsNothing);
      expect(find.byType(EqualPair), findsNothing);
    });

    testWidgets('every button shown is enabled', (tester) async {
      await _pump(tester, _view());

      for (final button in tester.widgetList<AppButton>(
        find.byType(AppButton),
      )) {
        expect(button.onPressed, isNotNull);
        expect(button.loading, isFalse);
      }
    });
  });

  group('callbacks', () {
    testWidgets('each button calls its own callback once per tap', (
      tester,
    ) async {
      final log = _Log();
      await _pump(tester, _view(), log: log);

      await tester.tap(_apply);
      await tester.tap(_draw);
      await tester.tap(_draw);

      expect(log.calls, ['apply', 'drawAgain', 'drawAgain']);
    });

    testWidgets('a rebuild with the same view uses the new callbacks', (
      tester,
    ) async {
      final first = _Log();
      final second = _Log();
      await _pump(tester, _view(), log: first);
      await tester.pumpWidget(host(_board(_view(), second)));

      await tester.tap(_apply);

      expect(first.calls, isEmpty);
      expect(second.calls, ['apply']);
    });

    testWidgets('Enter and Space on a focused button call it', (tester) async {
      _traditional();
      final log = _Log();
      await _pump(tester, _view(), log: log);

      _nodeOf(tester, _apply).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      _nodeOf(tester, _draw).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(log.calls, ['apply', 'apply', 'drawAgain']);
    });

    testWidgets('tapping a tile does nothing', (tester) async {
      final log = _Log();
      await _pump(tester, _view(), log: log);

      await tester.tap(_tile('b1'));

      expect(log.calls, isEmpty);
      expect(tester.widget<RoomTile>(_tileWidget('b1')).onTap, isNull);
    });
  });

  group('targets', () {
    testWidgets('the buttons have a hit area of 48 and nothing lights the '
        'tiles', (tester) async {
      await _pump(tester, _view());

      for (final finder in [_draw, _apply]) {
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTarget));
      }
      expect(
        find.ancestor(of: _tile('b1'), matching: find.byType(InkResponse)),
        findsNothing,
      );
    });

    testWidgets('a tap at the corners of each button reaches it', (
      tester,
    ) async {
      final log = _Log();
      await _pump(tester, _view(), log: log);

      for (final (finder, name) in [(_draw, 'drawAgain'), (_apply, 'apply')]) {
        final rect = tester.getRect(finder);
        for (final point in [
          rect.topLeft + const Offset(2, 2),
          rect.bottomRight - const Offset(2, 2),
        ]) {
          log.calls.clear();
          await tester.tapAt(point);
          expect(log.calls, [name], reason: '$name at $point');
        }
      }
    });

    testWidgets('the gaps keep the focus ring of a button clear of what '
        'follows', (tester) async {
      await _pump(tester, _view());

      final card = tester.getRect(
        find.ancestor(of: _status, matching: find.byType(DecoratedBox)).first,
      );
      final draw = tester.getRect(_draw);
      final apply = tester.getRect(_apply);
      expect(draw.top - card.bottom, AppSpacing.sm + AppSpacing.xs);
      expect(
        apply.left - draw.right,
        greaterThanOrEqualTo(2 * AppSizes.borderEmphasis),
      );
    });
  });

  group('semantics', () {
    testWidgets('lists the status, the bedrooms and the buttons in reading '
        'order', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      expect(semanticsLabels(tester), [
        'Pendiente de aplicar',
        'Dormitorio 1: Carlos, desde Dormitorio 3',
        'Dormitorio 2 · 2 camas: Ana Fernández, desde Dormitorio 1',
        'Dormitorio 3, Queda libre',
        'Dormitorio 4 · 2 camas: Luis y Sara, desde Dormitorio 2',
        'Sortear de nuevo',
        'Aplicar resultado',
      ]);
      handle.dispose();
    });

    testWidgets('a member hears the note instead of the buttons', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view(isAdmin: false));

      expect(semanticsLabels(tester).last, startsWith('Solo Ana'));
      expect(semanticsLabels(tester), isNot(contains('Sortear de nuevo')));
      handle.dispose();
    });

    testWidgets('the bedrooms are a list of items, each one node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      final list = tester.getSemantics(_k('roomDraw.draw-1'));
      expect(list.getSemanticsData().role, SemanticsRole.list);
      final items = <SemanticsNode>[];
      list.visitChildren((child) {
        items.add(child);
        return true;
      });
      expect(items, hasLength(4));
      for (final item in items) {
        expect(item.getSemanticsData().role, SemanticsRole.listItem);
      }
      expect(
        tester.getSemantics(_tile('b1')),
        isSemantics(label: 'Dormitorio 1: Carlos, desde Dormitorio 3'),
      );
      handle.dispose();
    });

    testWidgets('the buttons are named by their visible labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      for (final (finder, label) in [
        (_draw, 'Sortear de nuevo'),
        (_apply, 'Aplicar resultado'),
      ]) {
        expect(
          tester.getSemantics(
            find.descendant(
              of: finder,
              matching: find.byWidgetPredicate(
                (w) => w is FilledButton || w is OutlinedButton,
              ),
            ),
          ),
          isSemantics(
            label: label,
            isButton: true,
            isFocusable: true,
            isEnabled: true,
            hasEnabledState: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      }
      handle.dispose();
    });

    testWidgets('the status node says its word, as a live region that is '
        'not focusable for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      final live = find.descendant(
        of: _status,
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(
        tester.getSemantics(live),
        isSemantics(
          label: 'Pendiente de aplicar',
          isLiveRegion: true,
          isFocusable: false,
        ),
      );
      expect(
        tester
            .widget<Focus>(
              find.descendant(of: _status, matching: find.byType(Focus)).first,
            )
            .includeSemantics,
        isFalse,
        reason: 'the focus node is a keyboard target, not a node of its own',
      );
      handle.dispose();
    });

    testWidgets('a change of status is the same live region with a new word', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());
      final live = find.descendant(
        of: _status,
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      final element = tester.element(live);

      await _pump(tester, _view(status: RoomDrawStatus.applied));

      expect(tester.element(live), same(element));
      expect(
        tester.getSemantics(live),
        isSemantics(label: 'Aplicado', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('the state is in words: the free bedroom says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      expect(
        tester.getSemantics(_tile('b3')).label,
        'Dormitorio 3, Queda libre',
      );
      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('two columns of equal width, the first tile at the start', (
      tester,
    ) async {
      await _pump(tester, _view(), width: 360);

      final b1 = tester.getRect(_item('b1'));
      final b2 = tester.getRect(_item('b2'));
      final b3 = tester.getRect(_item('b3'));
      final b4 = tester.getRect(_item('b4'));
      expect(b1.width, closeTo(b2.width, 0.01));
      expect(b1.top, b2.top);
      expect(b3.top, greaterThan(b1.bottom));
      expect(b3.left, b1.left);
      expect(b4.left, b2.left);
      expect(b2.left - b1.right, AppSpacing.sm);
      expect(b3.top - b1.bottom, AppSpacing.sm);
      expect(b1.height, greaterThanOrEqualTo(AppSizes.rowTall));
    });

    testWidgets('a last tile that is alone keeps the width of a column', (
      tester,
    ) async {
      await _pump(tester, _view(rooms: _rooms().take(3).toList()), width: 360);

      expect(
        tester.getRect(_item('b3')).width,
        closeTo(tester.getRect(_item('b1')).width, 0.01),
      );
    });

    testWidgets('a single bedroom takes the whole width', (tester) async {
      await _pump(tester, _view(rooms: _rooms().take(1).toList()), width: 360);

      expect(
        tester.getSize(_item('b1')).width,
        tester.getSize(_k('roomDraw.draw-1')).width,
      );
    });

    testWidgets('tiles of a row are as tall as the row', (tester) async {
      await _pump(tester, _view(), textScale: 1.5, width: 360);

      expect(
        tester.getSize(_tile('b1')).height,
        tester.getSize(_tile('b2')).height,
      );
    });

    testWidgets('the buttons share a row of equal halves', (tester) async {
      await _pump(tester, _view(), width: 360);

      final draw = tester.getRect(_draw);
      final apply = tester.getRect(_apply);
      expect(draw.top, apply.top);
      expect(draw.width, closeTo(apply.width, 0.01));
    });

    testWidgets('the board mirrors in right-to-left', (tester) async {
      await _pump(tester, _view(), width: 360, direction: TextDirection.rtl);

      final b1 = tester.getRect(_item('b1'));
      final b2 = tester.getRect(_item('b2'));
      expect(b1.left, greaterThan(b2.left), reason: 'the first at the right');
      expect(
        tester.getRect(_draw).left,
        greaterThan(tester.getRect(_apply).left),
      );
      expect(
        tester.getRect(_status).right,
        closeTo(tester.getRect(_k('roomDraw.draw-1')).right, 0.01),
        reason: 'the status starts at the right',
      );
    });

    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final width in [320.0, 360.0]) {
        for (final direction in TextDirection.values) {
          testWidgets('Spanish text at ${scale}x in ${width.toInt()} '
              '${direction.name} wraps whole words and overflows nowhere', (
            tester,
          ) async {
            await _pump(
              tester,
              _view(),
              textScale: scale,
              width: width,
              direction: direction,
            );

            expect(tester.takeException(), isNull);
            final board = tester.getRect(_k('roomDraw.board'));
            expect(board.width, width);
            for (final text in [
              'Dormitorio 1',
              'Dormitorio 4 · 2 camas',
              'desde Dormitorio 3',
              'desde Dormitorio 2',
              'Queda libre',
              'Pendiente de aplicar',
              'Sortear de nuevo',
              'Aplicar resultado',
            ]) {
              final finder = find.text(text);
              expectNoMidWordBreaks(
                tester,
                finder,
                bold: text == 'Dormitorio 1' || text == 'Pendiente de aplicar',
                reason: 'at ${scale}x in ${direction.name}',
              );
              final box = tester.getRect(finder);
              expect(box.left, greaterThanOrEqualTo(board.left - 0.01));
              expect(box.right, lessThanOrEqualTo(board.right + 0.01));
            }
            final grid = tester.getRect(_k('roomDraw.draw-1'));
            for (final id in ['b1', 'b2', 'b3', 'b4']) {
              final item = tester.getRect(_item(id));
              expect(item.left, greaterThanOrEqualTo(grid.left - 0.01));
              expect(item.right, lessThanOrEqualTo(grid.right + 0.01));
              for (final pebble
                  in find
                      .descendant(
                        of: _tile(id),
                        matching: find.byType(AppPebble),
                      )
                      .evaluate()) {
                final box = tester.getRect(find.byWidget(pebble.widget));
                expect(box.left, greaterThanOrEqualTo(item.left));
                expect(box.right, lessThanOrEqualTo(item.right + 0.01));
              }
            }
          });
        }
      }
    }

    testWidgets('large text moves the bedrooms to one column and the buttons '
        'under each other, never cutting a word', (tester) async {
      await _pump(tester, _view(), textScale: 2);

      expect(
        tester.getRect(_item('b2')).top,
        greaterThanOrEqualTo(tester.getRect(_item('b1')).bottom),
      );
      expect(tester.getRect(_item('b1')).width, 320 - 2 * AppSpacing.sm);
      expect(
        tester.getRect(_apply).top,
        greaterThanOrEqualTo(tester.getRect(_draw).bottom),
      );
      expect(
        tester.getSize(find.text('Dormitorio 1')).height,
        greaterThan(30),
        reason: 'the text is scaled, never clamped',
      );
    });

    testWidgets('two columns return when the text is small again', (
      tester,
    ) async {
      await _pump(tester, _view(), textScale: 2);
      await tester.pumpWidget(host(_board(_view(), _Log()), width: 360));

      expect(tester.getRect(_item('b1')).top, tester.getRect(_item('b2')).top);
    });

    testWidgets('its least width holds the longest word of every tile', (
      tester,
    ) async {
      for (final scale in [1.0, 2.0]) {
        await _pump(tester, _view(), textScale: scale);
        final grid = tester.renderObject<RenderBox>(_k('roomDraw.draw-1'));
        var need = 0.0;
        for (final tile in tester.renderObjectList<RenderBox>(
          find.byType(RoomTile),
        )) {
          need = need > tile.getMinIntrinsicWidth(double.infinity)
              ? need
              : tile.getMinIntrinsicWidth(double.infinity);
        }

        expect(grid.getMinIntrinsicWidth(0), need, reason: '${scale}x');
        expect(
          grid.getMaxIntrinsicWidth(0),
          greaterThanOrEqualTo(2 * need),
          reason: 'two columns when there is room',
        );
      }
    });

    testWidgets('a column is as narrow as its longest word, with no floor '
        'of 48', (tester) async {
      await _pump(
        tester,
        _view(
          rooms: [
            _room('a', 'A', caption: 'B', label: 'A, B'),
            _room('b', 'C', caption: 'D', label: 'C, D'),
          ],
        ),
      );
      final grid = tester.renderObject<RenderBox>(_k('roomDraw.draw-1'));
      final widest = [
        for (final id in ['a', 'b'])
          tester
              .renderObject<RenderBox>(_tileWidget(id))
              .getMinIntrinsicWidth(double.infinity),
      ].reduce((a, b) => a > b ? a : b);

      expect(widest, lessThan(48));
      expect(grid.getMinIntrinsicWidth(0), widest);
    });

    testWidgets('measures by intrinsic sizing and dry layout, as the goldens '
        'do', (tester) async {
      await _pump(tester, _view());
      await tester.pumpWidget(
        host(
          IntrinsicWidth(
            child: IntrinsicHeight(child: _board(_view(), _Log())),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      for (final scale in [1.0, 2.0]) {
        await _pump(tester, _view(), textScale: scale);
        final grid = tester.renderObject<RenderBox>(_k('roomDraw.draw-1'));
        final box = tester.renderObject<RenderBox>(_k('roomDraw.board'));
        expect(
          box.getDryLayout(BoxConstraints(maxWidth: box.size.width)),
          box.size,
        );
        expect(
          grid.getDryLayout(BoxConstraints(maxWidth: grid.size.width)),
          grid.size,
        );
        expect(
          grid.getMinIntrinsicHeight(grid.size.width),
          grid.size.height,
          reason: 'at ${scale}x',
        );
      }
    });
  });

  group('colors', () {
    for (final (name, theme) in themes) {
      testWidgets('keeps the texts at 4.5:1 in $name', (tester) async {
        await _pump(tester, _view(isAdmin: false), theme: theme);
        final scheme = theme.colorScheme;
        final colors = theme.extension<AppColors>()!;

        expectContrast(
          {
            'note': (
              tester
                  .widget<Text>(find.textContaining('Solo Ana'))
                  .style!
                  .color!,
              scheme.surface,
            ),
            'status pending': (scheme.onSurface, colors.busySoft),
            'status applied': (scheme.onSurface, scheme.primaryContainer),
            'caption': (scheme.onSurface, scheme.primaryContainer),
            'free caption': (
              scheme.onSurfaceVariant,
              scheme.surfaceContainerLowest,
            ),
          },
          minimum: 4.5,
          reason: name,
        );
        expect(
          tester.widget<Text>(find.textContaining('Solo Ana')).style!.color,
          scheme.onSurfaceVariant,
        );
      });

      testWidgets('the dashed outline and the card edge are hairlines '
          '($name)', (tester) async {
        await _pump(tester, _view(), theme: theme);

        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: _tile('b3'),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as ShapeDecoration;
        expect(
          (decoration.shape as DashedBorder).side.color,
          theme.colorScheme.outlineVariant,
        );
      });

      testWidgets('the status ring is 2 px of ink outside the badge and '
          'reaches 3:1 ($name)', (tester) async {
        _traditional();
        await _pump(tester, _view(isAdmin: false), theme: theme);
        _statusNode(tester).requestFocus();
        await tester.pump();

        final scheme = theme.colorScheme;
        final badge = tester.getRect(
          find.descendant(of: _status, matching: find.byType(AppBadge)),
        );
        final origin = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final above = badge.topCenter - origin - const Offset(0, 1);
        final inside = Offset(badge.left + 3, badge.center.dy) - origin;
        final far = badge.topCenter - origin - const Offset(0, 4);

        final ring = await paintedColorAt(tester, hostBoundaryKey, above);
        expect(ring, isSameColorAs(scheme.onSurface));
        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(badge.center.dx, badge.top) - origin,
          ),
          isNot(isSameColorAs(scheme.onSurface)),
          reason: 'the first row of the badge is not covered by the ring',
        );
        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            badge.topCenter - origin - const Offset(0, 2),
          ),
          isSameColorAs(scheme.onSurface),
          reason: 'the ring is 2 px thick',
        );
        expect(
          await paintedColorAt(tester, hostBoundaryKey, inside),
          isNot(isSameColorAs(scheme.onSurface)),
          reason: 'never inside the badge',
        );
        expect(
          await paintedColorAt(tester, hostBoundaryKey, far),
          isNot(isSameColorAs(scheme.onSurface)),
          reason: 'only 2 px',
        );
        expectContrast(
          {'ring': (ring, scheme.surfaceContainerLowest)},
          minimum: 3,
          reason: name,
        );
      });
    }

    testWidgets('no ring is drawn while the status does not hold focus', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());

      final badge = tester.getRect(
        find.descendant(of: _status, matching: find.byType(AppBadge)),
      );
      final origin = tester.getTopLeft(find.byKey(hostBoundaryKey));
      expect(
        await paintedColorAt(
          tester,
          hostBoundaryKey,
          badge.topCenter - origin - const Offset(0, 1),
        ),
        isNot(isSameColorAs(CompappTheme.light.colorScheme.onSurface)),
      );
    });

    testWidgets('the ring is for the keyboard only', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await _pump(tester, _view(isAdmin: false));
      _statusNode(tester).requestFocus();
      await tester.pump();

      final badge = tester.getRect(
        find.descendant(of: _status, matching: find.byType(AppBadge)),
      );
      final origin = tester.getTopLeft(find.byKey(hostBoundaryKey));
      expect(
        await paintedColorAt(
          tester,
          hostBoundaryKey,
          badge.topCenter - origin - const Offset(0, 1),
        ),
        isNot(isSameColorAs(CompappTheme.light.colorScheme.onSurface)),
      );
    });
  });

  group('focus', () {
    testWidgets('Tab goes from Draw again to Apply result and never to a '
        'tile or the status', (tester) async {
      _traditional();
      await _pump(tester, _view());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(_nodeOf(tester, _draw).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(_nodeOf(tester, _apply).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(_statusNode(tester).hasPrimaryFocus, isFalse);
    });

    testWidgets('moves from Apply to Draw again when the draw is applied', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _apply).requestFocus();
      await tester.pump();

      await _pump(tester, _view(status: RoomDrawStatus.applied));
      await tester.pump();

      expect(_nodeOf(tester, _draw).hasPrimaryFocus, isTrue);
    });

    testWidgets('moves from Apply to Draw again when its callback goes', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _apply).requestFocus();
      await tester.pump();

      await _pump(tester, _view(), apply: false);
      await tester.pump();

      expect(_nodeOf(tester, _draw).hasPrimaryFocus, isTrue);
    });

    testWidgets('moves from Draw again to Apply when its callback goes', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _draw).requestFocus();
      await tester.pump();

      await _pump(tester, _view(), draw: false);
      await tester.pump();

      expect(_nodeOf(tester, _apply).hasPrimaryFocus, isTrue);
    });

    testWidgets('falls to the status when no button is left', (tester) async {
      _traditional();
      for (final (focused, view, draw, apply) in [
        (_apply, _view(isAdmin: false), true, true),
        (_draw, _view(isAdmin: false), true, true),
        (_apply, _view(), false, false),
        (_draw, _view(), false, false),
        (_draw, _view(status: RoomDrawStatus.applied), false, true),
      ]) {
        await _pump(tester, _view(status: view.status));
        _nodeOf(tester, focused).requestFocus();
        await tester.pump();

        await _pump(tester, view, draw: draw, apply: apply);
        await tester.pump();

        expect(
          _statusNode(tester).hasPrimaryFocus,
          isTrue,
          reason: '${view.isAdmin} $draw $apply',
        );
      }
    });

    testWidgets('the status holds focus as a fallback and then a button '
        'returns it to nobody', (tester) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _apply).requestFocus();
      await tester.pump();
      await _pump(tester, _view(isAdmin: false));
      await tester.pump();
      expect(_statusNode(tester).hasPrimaryFocus, isTrue);

      await _pump(tester, _view());
      await tester.pump();

      expect(
        _statusNode(tester).hasPrimaryFocus,
        isTrue,
        reason: 'a view that offers the buttons again does not pull focus',
      );
    });

    testWidgets('a new draw keeps the focus of the button that held it', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _draw).requestFocus();
      await tester.pump();
      final element = tester.element(_draw);

      await _pump(
        tester,
        _view(
          drawId: 'draw-2',
          rooms: [
            _room('b1', 'Dormitorio 1', members: [_ana], from: 'Dormitorio 1'),
            _room(
              'b2',
              'Dormitorio 2',
              members: [_carlos],
              from: 'Dormitorio 3',
            ),
            _room('b3', 'Dormitorio 3'),
            _room(
              'b4',
              'Dormitorio 4 · 2 camas',
              members: [_luis, _sara],
              from: 'Dormitorio 2',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(_nodeOf(tester, _draw).hasPrimaryFocus, isTrue);
      expect(tester.element(_draw), same(element));
      expect(_k('roomDraw.draw-2'), findsOneWidget);
      expect(_k('roomDraw.draw-1'), findsNothing);
    });

    testWidgets('does not move focus for someone using touch', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await _pump(tester, _view());
      _nodeOf(tester, _apply).requestFocus();
      await tester.pump();

      await _pump(tester, _view(status: RoomDrawStatus.applied));
      await tester.pump();

      expect(_nodeOf(tester, _draw).hasFocus, isFalse);
      expect(_statusNode(tester).hasFocus, isFalse);
    });

    testWidgets('a rebuild of the same view leaves focus where it is', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _apply).requestFocus();
      await tester.pump();

      await _pump(tester, _view());
      await _pump(tester, _view());
      await tester.pump();

      expect(_nodeOf(tester, _apply).hasPrimaryFocus, isTrue);
    });

    /// Pumps [first] and gives focus to Apply. Then it builds twice before the
    /// next frame is drawn, as the framework does when two things change in
    /// one frame: the board is rebuilt with [during] (an update that schedules
    /// a hand-over), and then with [second] or, when it is null, removed. The
    /// callbacks of the frame run after both. Returns what shows another view
    /// later.
    Future<Future<void> Function(RoomDrawView)> frameWith(
      WidgetTester tester, {
      required RoomDrawView first,
      required RoomDrawView during,
      RoomDrawView? second,
    }) async {
      _traditional();
      var current = first;
      var show = true;
      late StateSetter setBoard;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setBoard = setState;
              return show ? _board(current, _Log()) : const SizedBox();
            },
          ),
        ),
      );
      _nodeOf(tester, _apply).requestFocus();
      await tester.pump();

      void build() =>
          tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
      setBoard(() => current = during);
      build();
      setBoard(() {
        if (second == null) {
          show = false;
        } else {
          current = second;
        }
      });
      build();
      await tester.pump();

      Future<void> showView(RoomDrawView view) async {
        setBoard(() => current = view);
        await tester.pump();
      }

      return showView;
    }

    testWidgets('a board removed in the frame that updated it hands nothing '
        'over', (tester) async {
      await frameWith(
        tester,
        first: _view(),
        during: _view(status: RoomDrawStatus.applied),
      );
      // The update asked for a hand-over and the board was removed before the
      // frame ran it.
      expect(find.byType(RoomDrawBoard), findsNothing);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a hand-over aimed at a button that left in the same frame '
        'does not grab focus when it comes back', (tester) async {
      final show = await frameWith(
        tester,
        first: _view(),
        during: _view(drawId: 'draw-2'),
        second: _view(status: RoomDrawStatus.applied),
      );
      expect(_apply, findsNothing);
      expect(_nodeOf(tester, _draw).hasPrimaryFocus, isTrue);

      _nodeOf(tester, _draw).unfocus();
      await tester.pump();
      await show(_view());
      await tester.pump();

      expect(
        _nodeOf(tester, _apply).hasPrimaryFocus,
        isFalse,
        reason: 'a request made while it was detached must not wait for it',
      );
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('roomDraw.apply'),
      );
    });
  });

  group('identity', () {
    testWidgets('the tiles keep their elements when the order changes', (
      tester,
    ) async {
      await _pump(tester, _view());
      final before = {
        for (final id in ['b1', 'b2', 'b3', 'b4'])
          id: tester.element(_item(id)),
      };

      await _pump(tester, _view(rooms: _rooms().reversed.toList()));

      for (final id in before.keys) {
        expect(tester.element(_item(id)), same(before[id]), reason: id);
      }
      expect(tester.getRect(_item('b4')).top, tester.getRect(_item('b3')).top);
    });

    testWidgets('the buttons and the status stay mounted across a new draw', (
      tester,
    ) async {
      await _pump(tester, _view());
      final draw = tester.element(_draw);
      final apply = tester.element(_apply);
      final status = tester.element(_status);

      await _pump(tester, _view(drawId: 'draw-2'));

      expect(tester.element(_draw), same(draw));
      expect(tester.element(_apply), same(apply));
      expect(tester.element(_status), same(status));
    });

    testWidgets('a tile that stays free and one that gets people swap '
        'cleanly', (tester) async {
      await _pump(tester, _view());
      await _pump(
        tester,
        _view(
          rooms: [
            _room('b1', 'Dormitorio 1'),
            _room('b2', 'Dormitorio 2', members: [_ana], from: 'Dormitorio 1'),
            _room(
              'b3',
              'Dormitorio 3',
              members: [_carlos],
              from: 'Dormitorio 3',
            ),
            _room(
              'b4',
              'Dormitorio 4 · 2 camas',
              members: [_luis, _sara],
              from: 'Dormitorio 2',
            ),
          ],
        ),
      );

      expect(
        tester.widget<RoomTile>(_tileWidget('b1')).state,
        RoomTileState.free,
      );
      expect(
        tester.widget<RoomTile>(_tileWidget('b3')).state,
        RoomTileState.home,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('going from pending to applied removes only the apply '
        'button', (tester) async {
      await _pump(tester, _view());
      final draw = tester.element(_draw);

      await _pump(tester, _view(status: RoomDrawStatus.applied));

      expect(_apply, findsNothing);
      expect(
        tester
            .widget<AppBadge>(
              find.descendant(of: _status, matching: find.byType(AppBadge)),
            )
            .label,
        'Aplicado',
      );
      expect(
        tester.element(_draw),
        isNot(same(draw)),
        reason: 'the pair gives way to a single button',
      );
    });
  });

  group('themes', () {
    for (final (name, theme) in themes) {
      testWidgets('draws every state without an error in $name', (
        tester,
      ) async {
        for (final status in RoomDrawStatus.values) {
          for (final admin in [true, false]) {
            await _pump(
              tester,
              _view(status: status, isAdmin: admin),
              theme: theme,
            );
            expect(tester.takeException(), isNull, reason: '$status $admin');
          }
        }
      });
    }
  });

  group('debug checks', () {
    testWidgets('rejects a bedroom id that repeats', (tester) async {
      await _pump(
        tester,
        _view(
          rooms: [_room('b1', 'Dormitorio 1'), _room('b1', 'Dormitorio 2')],
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('rejects a member who goes to two bedrooms', (tester) async {
      await _pump(
        tester,
        _view(
          rooms: [
            _room('b1', 'Dormitorio 1', members: [_ana], from: 'Dormitorio 2'),
            _room('b2', 'Dormitorio 2', members: [_ana], from: 'Dormitorio 1'),
          ],
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('one bedroom'),
        ),
      );
    });

    testWidgets('rejects a spoken label that lacks the name or the caption', (
      tester,
    ) async {
      for (final label in ['Carlos va a la primera', 'Dormitorio 1: Carlos']) {
        await _pump(
          tester,
          _view(
            rooms: [
              _room(
                'b1',
                'Dormitorio 1',
                members: [_carlos],
                from: 'Dormitorio 3',
                label: label,
              ),
            ],
          ),
        );

        expect(tester.takeException(), isA<AssertionError>(), reason: label);
      }
    });

    testWidgets('rejects a draw without bedrooms', (tester) async {
      await _pump(tester, _view(rooms: const []));

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('at least one bedroom'),
        ),
      );
    });

    testWidgets('rejects a member view without the note', (tester) async {
      await _pump(
        tester,
        const RoomDrawView(
          drawId: 'd',
          status: RoomDrawStatus.pending,
          statusLabel: 'Pendiente',
          bedrooms: [
            RoomDrawRoom(
              room: RoomView(id: 'b1', name: 'Dormitorio 1'),
              caption: 'Queda libre',
              semanticLabel: 'Dormitorio 1, Queda libre',
            ),
          ],
          drawAgainLabel: 'Sortear',
          applyLabel: 'Aplicar',
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('note'),
        ),
      );
    });
  });
}

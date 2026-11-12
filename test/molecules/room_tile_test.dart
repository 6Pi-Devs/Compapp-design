import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/foundation/dashed_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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

const _tileWidth = 168.0;
const _cellHeight = 104.0;

const _carlos = MemberView(
  id: 'carlos',
  name: 'Carlos',
  initials: 'C',
  joinOrder: 1,
  semanticLabel: 'Carlos',
);
const _ana = MemberView(
  id: 'ana',
  name: 'Ana',
  initials: 'A',
  joinOrder: 0,
  semanticLabel: 'Ana',
);

/// A stand-in for an item beacon: a molecule cannot import another one, and a
/// tile takes any widget.
Widget _beacon(String name) =>
    TextButton(key: Key('beacon.$name'), onPressed: () {}, child: Text(name));

RoomTile _tile({
  RoomTileState state = RoomTileState.occupied,
  String id = 'bathroom',
  String name = 'Bathroom',
  String caption = 'occupied',
  String label = 'Bathroom, occupied by Carlos, 12 minutes',
  List<MemberView> occupants = const [],
  List<Widget> beacons = const [],
  bool draw = false,
  VoidCallback? onTap,
}) => RoomTile(
  room: RoomView(id: id, name: name),
  state: state,
  caption: caption,
  semanticLabel: label,
  occupants: occupants,
  beacons: beacons,
  draw: draw,
  onTap: onTap,
);

Widget _cell(
  Widget tile, {
  double height = _cellHeight,
  double width = _tileWidth,
}) => Align(
  alignment: AlignmentDirectional.topStart,
  child: SizedBox(width: width, height: height, child: tile),
);

Finder _key(String id) => find.byKey(Key('floorplan.room.$id'));
Finder _pebble(String id) => find.byKey(Key('roomTile.pebble.$id'));

ShapeDecoration _decoration(WidgetTester tester, {String id = 'bathroom'}) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: _key(id), matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as ShapeDecoration;
}

bool _same(Color a, Color b) =>
    (a.r - b.r).abs() < 0.01 &&
    (a.g - b.g).abs() < 0.01 &&
    (a.b - b.b).abs() < 0.01;

Color _fillOf(ThemeData theme, RoomTileState state) {
  final scheme = theme.colorScheme;
  final colors = theme.extension<AppColors>()!;
  return switch (state) {
    RoomTileState.home => scheme.primaryContainer,
    RoomTileState.away => scheme.surfaceContainerHigh,
    RoomTileState.occupied => colors.busySoft,
    RoomTileState.free => scheme.surfaceContainerLowest,
  };
}

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows the name and the caption', (tester) async {
      await tester.pumpWidget(host(_cell(_tile())));

      expect(find.text('Bathroom'), findsOneWidget);
      expect(find.text('occupied'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Bathroom')).dy,
        lessThan(tester.getTopLeft(find.text('occupied')).dy),
      );
    });

    testWidgets('the key is built from the room id', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _tile(id: 'a'),
              _tile(id: 'b'),
            ],
          ),
        ),
      );

      expect(_key('a'), findsOneWidget);
      expect(_key('b'), findsOneWidget);
    });

    testWidgets('only an occupied tile shows the lock, in the busy color', (
      tester,
    ) async {
      for (final state in RoomTileState.values) {
        await tester.pumpWidget(host(_cell(_tile(state: state))));

        final locks = find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.icon == AppIcons.occupied,
        );
        if (state == RoomTileState.occupied) {
          expect(
            tester.widget<AppIcon>(locks).color,
            CompappTheme.light.extension<AppColors>()!.busy,
          );
          expect(
            tester.getTopLeft(locks).dx,
            greaterThan(tester.getTopRight(find.text('Bathroom')).dx - 1),
            reason: 'the lock follows the name',
          );
        } else {
          expect(locks, findsNothing, reason: state.name);
        }
      }
    });

    testWidgets('occupants are s36 pebbles at the bottom end of the tile', (
      tester,
    ) async {
      await tester.pumpWidget(host(_cell(_tile(occupants: const [_carlos]))));

      final pebble = tester.widget<AppPebble>(_pebble('carlos'));
      expect(pebble.size, AppPebbleSize.s36);
      expect(pebble.initials, 'C');
      expect(pebble.joinOrder, 1);
      final tile = tester.getRect(_key('bathroom'));
      final box = tester.getRect(_pebble('carlos'));
      expect(box.size, const Size.square(36));
      expect(box.right, tile.right - AppSpacing.sm);
      expect(box.bottom, tile.bottom - AppSpacing.sm);
    });

    testWidgets('without occupants and beacons there is no footer', (
      tester,
    ) async {
      await tester.pumpWidget(host(_cell(_tile())));

      expect(find.byType(AppPebble), findsNothing);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('beacons are pinned at the bottom start, in order', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _cell(
            _tile(beacons: [_beacon('Oven'), _beacon('Dryer')]),
            width: 300,
          ),
        ),
      );

      final tile = tester.getRect(_key('bathroom'));
      final oven = tester.getRect(find.byKey(const Key('beacon.Oven')));
      final dryer = tester.getRect(find.byKey(const Key('beacon.Dryer')));
      expect(oven.left, tile.left + AppSpacing.sm);
      expect(dryer.left, greaterThan(oven.left));
      expect(oven.bottom, tile.bottom - AppSpacing.sm);
    });

    testWidgets('fills the height it is given and shrinks to its content', (
      tester,
    ) async {
      await tester.pumpWidget(host(_cell(_tile())));
      expect(tester.getSize(_key('bathroom')).height, _cellHeight);

      await tester.pumpWidget(
        host(
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: _tileWidth, child: _tile()),
          ),
        ),
      );
      expect(
        tester.getSize(_key('bathroom')).height,
        lessThan(_cellHeight),
        reason: 'two lines of text and the padding',
      );
    });

    testWidgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          IntrinsicWidth(
            child: IntrinsicHeight(
              child: _tile(
                occupants: const [_carlos],
                beacons: [_beacon('Oven')],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      for (final state in RoomTileState.values) {
        testWidgets('${state.name} paints its wall ($name)', (tester) async {
          await tester.pumpWidget(
            host(
              _cell(_tile(state: state)),
              theme: theme,
              background: scheme.surface,
            ),
          );
          final size = tester.getSize(_key('bathroom'));

          expect(
            await paintedColorAt(
              tester,
              hostBoundaryKey,
              Offset(size.width - 12, 12),
            ),
            isSameColorAs(_fillOf(theme, state)),
          );
        });
      }

      testWidgets('home has a presence-home edge and a glow ring ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            _cell(_tile(state: RoomTileState.home)),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final size = tester.getSize(_key('bathroom'));

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(0, size.height / 2),
          ),
          isSameColorAs(colors.presenceHome),
          reason: 'the 1.5 edge',
        );
        final decoration = _decoration(tester);
        expect(decoration.shadows, hasLength(1));
        expect(decoration.shadows!.single.spreadRadius, AppSpacing.xs);
        expect(
          decoration.shadows!.single.color,
          colors.presenceHome.withValues(alpha: AppDecor.roomEdge),
        );
      });

      testWidgets('occupied has an amber edge at 35 percent ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(_cell(_tile()), theme: theme, background: scheme.surface),
        );
        final size = tester.getSize(_key('bathroom'));

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(0, size.height / 2),
          ),
          isSameColorAs(
            Color.alphaBlend(
              colors.busy.withValues(alpha: AppDecor.roomEdge),
              colors.busySoft,
            ),
          ),
        );
        expect(_decoration(tester).shadows, anyOf(isNull, isEmpty));
      });

      testWidgets('away has a line edge and free a dashed line edge '
          '($name)', (tester) async {
        for (final (state, edge) in [
          (RoomTileState.away, scheme.outlineVariant),
          (RoomTileState.free, scheme.outlineVariant),
        ]) {
          await tester.pumpWidget(
            host(
              _cell(_tile(state: state)),
              theme: theme,
              background: scheme.surface,
            ),
          );
          final size = tester.getSize(_key('bathroom'));

          // Along the top edge, between the corners.
          final edgeRow = <Color>[
            for (var x = 24; x < size.width - 24; x++)
              await paintedColorAt(tester, hostBoundaryKey, Offset(x + 0.0, 0)),
          ];
          final edgePixels = edgeRow.where((c) => _same(c, edge)).length;
          final gapPixels = edgeRow.where((c) => !_same(c, edge)).length;
          if (state == RoomTileState.free) {
            expect(edgePixels, greaterThan(20), reason: 'the dashes');
            expect(gapPixels, greaterThan(10), reason: 'and the gaps');
          } else {
            expect(edgePixels, edgeRow.length, reason: 'a solid line');
          }
        }
      });
    }

    testWidgets('every wall has a 1.5 border and 16 corners', (tester) async {
      for (final state in RoomTileState.values) {
        await tester.pumpWidget(host(_cell(_tile(state: state))));

        final shape = _decoration(tester).shape as RoundedRectangleBorder;
        expect(shape.side.width, AppSizes.borderRoom, reason: state.name);
        expect(
          shape.borderRadius,
          BorderRadius.circular(AppRadius.md),
          reason: state.name,
        );
      }
    });

    testWidgets('only the free tile is dashed', (tester) async {
      for (final state in RoomTileState.values) {
        await tester.pumpWidget(host(_cell(_tile(state: state))));

        final dashed = _decoration(tester).shape is DashedBorder;
        expect(dashed, state == RoomTileState.free, reason: state.name);
      }
    });

    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      testWidgets('name is ink and the caption follows the state ($name)', (
        tester,
      ) async {
        for (final (state, caption) in [
          (RoomTileState.home, scheme.onSurface),
          (RoomTileState.away, scheme.onSurfaceVariant),
          (RoomTileState.occupied, scheme.onSurface),
          (RoomTileState.free, scheme.onSurfaceVariant),
        ]) {
          await tester.pumpWidget(
            host(
              _cell(_tile(state: state, name: 'Kitchen', caption: 'Quiet')),
              theme: theme,
              background: scheme.surface,
            ),
          );

          expect(
            await paintedColorAtCenter(
              tester,
              hostBoundaryKey,
              find.text('Kitchen'),
            ),
            isSameColorAs(scheme.onSurface),
            reason: '${state.name} name',
          );
          expect(
            await paintedColorAtCenter(
              tester,
              hostBoundaryKey,
              find.text('Quiet'),
            ),
            isSameColorAs(caption),
            reason: '${state.name} caption',
          );
        }
      });
    }
  });

  group('right to left', () {
    testWidgets('the name is at the right, the pebbles at the left and the '
        'beacons at the right', (tester) async {
      await tester.pumpWidget(
        host(
          _cell(
            _tile(occupants: const [_carlos], beacons: [_beacon('Oven')]),
            height: 160,
          ),
          direction: TextDirection.rtl,
        ),
      );
      final tile = tester.getRect(_key('bathroom'));

      expect(
        tester.getRect(find.text('Bathroom')).right,
        closeTo(tile.right - AppSpacing.sm, 14),
      );
      expect(tester.getRect(_pebble('carlos')).left, tile.left + AppSpacing.sm);
      expect(
        tester.getRect(find.byKey(const Key('beacon.Oven'))).right,
        tile.right - AppSpacing.sm,
      );
    });
  });

  group('semantics', () {
    testWidgets('is one node named by the label, not a button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_cell(_tile(occupants: const [_carlos]))));

      expect(
        tester.getSemantics(_key('bathroom')),
        isSemantics(label: 'Bathroom, occupied by Carlos, 12 minutes'),
      );
      expect(semanticsLabels(tester), [
        'Bathroom, occupied by Carlos, 12 minutes',
      ], reason: 'the name, caption, lock and pebble say nothing again');
      handle.dispose();
    });

    testWidgets('each beacon stays its own button, a child of the tile', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          _cell(
            _tile(
              occupants: const [_ana],
              beacons: [_beacon('Oven'), _beacon('Dryer')],
            ),
            height: 220,
          ),
        ),
      );

      final tile = tester.getSemantics(_key('bathroom'));
      expect(semanticsLabels(tester), [
        'Bathroom, occupied by Carlos, 12 minutes',
        'Oven',
        'Dryer',
      ]);
      for (final name in ['Oven', 'Dryer']) {
        final node = tester.getSemantics(find.byKey(Key('beacon.$name')));
        expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
        expect(node.parent, tile, reason: '$name is a child of the tile');
        expect(
          node.label,
          name,
          reason: 'its label is not merged into the tile',
        );
      }
      expect(tile.label, isNot(contains('Oven')));
      handle.dispose();
    });

    testWidgets('stays its own node under a labeled container parent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(Semantics(container: true, label: 'Plan', child: _cell(_tile()))),
      );

      expect(semanticsLabels(tester), [
        'Plan',
        'Bathroom, occupied by Carlos, 12 minutes',
      ], reason: 'the tile label is not merged into the plan label');
      final plan = semanticsNodes(tester)
          .firstWhere((node) => node.label == 'Plan');
      expect(tester.getSemantics(_key('bathroom')).parent, plan);
      handle.dispose();
    });

    testWidgets('needs a spoken label', (tester) async {
      expect(() => _tile(label: ''), throwsAssertionError);
    });

    testWidgets('the state caption is not announced on top of the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_cell(_tile(label: 'Bathroom, busy'))));

      expect(semanticsLabels(tester), ['Bathroom, busy']);
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      test('text reaches 4.5:1 on every wall ($name)', () {
        expectContrast(
          {
            for (final state in RoomTileState.values) ...{
              '${state.name} name': (scheme.onSurface, _fillOf(theme, state)),
              '${state.name} caption': (
                switch (state) {
                  RoomTileState.away ||
                  RoomTileState.free => scheme.onSurfaceVariant,
                  RoomTileState.home ||
                  RoomTileState.occupied => scheme.onSurface,
                },
                _fillOf(theme, state),
              ),
            },
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('the lock reaches 3:1 on the occupied wall ($name)', () {
        expectContrast(
          {'lock/occupied': (colors.busy, colors.busySoft)},
          minimum: 3,
          reason: name,
        );
      });

      test('the pebbles keep their ink on every wall ($name)', () {
        expectContrast(
          {
            'initials/carlos': (colors.onPebble, colors.pebbleAt(1)),
            'initials/ana': (colors.onPebble, colors.pebbleAt(0)),
          },
          minimum: 4.5,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const longName = 'Habitación de María de los Ángeles';
    const longCaption = 'ocupada desde hace doce minutos';

    Widget longTile(RoomTileState state) => _tile(
      state: state,
      name: longName,
      caption: longCaption,
      label: 'Habitación de María de los Ángeles, ocupada',
      occupants: const [_carlos, _ana],
      beacons: [
        const SizedBox(key: Key('beacon.a'), width: 120, height: 48),
        const SizedBox(key: Key('beacon.b'), width: 120, height: 48),
      ],
    );

    testWidgets('wraps, grows and keeps everything inside at 1.5 and 2.0', (
      tester,
    ) async {
      for (final state in RoomTileState.values) {
        await tester.pumpWidget(
          host(
            Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(width: _tileWidth, child: longTile(state)),
            ),
          ),
        );
        final base = tester.getSize(find.text(longName));

        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(
            host(
              Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(width: _tileWidth, child: longTile(state)),
              ),
              textScale: scale,
            ),
          );
          final reason = '${state.name} at ${scale}x';
          final tile = tester.getRect(_key('bathroom'));

          expect(tester.takeException(), isNull, reason: reason);
          expect(tile.width, _tileWidth, reason: reason);
          expect(
            tester.getSize(find.text(longName)).height,
            greaterThanOrEqualTo(base.height * scale - 1),
            reason: '$reason: the text is scaled, never clamped',
          );
          for (final (label, finder) in [
            ('name', find.text(longName)),
            ('caption', find.text(longCaption)),
            ('pebble', _pebble('carlos')),
            ('other pebble', _pebble('ana')),
            ('beacon a', find.byKey(const Key('beacon.a'))),
            ('beacon b', find.byKey(const Key('beacon.b'))),
          ]) {
            final box = tester.getRect(finder);
            expect(
              box.left,
              greaterThanOrEqualTo(tile.left + AppSpacing.sm - 0.01),
              reason: '$reason: $label inside, left',
            );
            expect(
              box.right,
              lessThanOrEqualTo(tile.right - AppSpacing.sm + 0.01),
              reason: '$reason: $label inside, right',
            );
            expect(
              box.bottom,
              lessThanOrEqualTo(tile.bottom - AppSpacing.sm + 0.01),
              reason: '$reason: $label inside, bottom',
            );
          }
          expect(
            tester.getRect(find.text(longCaption)).bottom,
            lessThanOrEqualTo(
              tester.getRect(find.byKey(const Key('beacon.a'))).top,
            ),
            reason: '$reason: the footer starts under the texts',
          );
        }
      }
    });
  });

  group('the cells of the plan', () {
    setUpAll(loadBundledFonts);

    Widget oven() => ItemBeacon(
      item: const ItemView(id: 'oven', name: 'Oven', icon: AppIcons.oven),
      inUse: false,
      statusLabel: 'free',
      semanticLabel: 'Oven, free',
      onTap: () {},
    );

    Widget cell(RoomTile tile, {required double width, double? height}) =>
        Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, height: height, child: tile),
        );

    Finder beacon() => find.byKey(const Key('floorplan.item.oven'));

    testWidgets('170 x 104 holds a beacon and an occupant on one line', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          cell(
            _tile(occupants: const [_carlos], beacons: [oven()]),
            width: 170,
            height: 104,
          ),
        ),
      );
      final tile = tester.getRect(_key('bathroom'));
      final oven0 = tester.getRect(beacon());
      final pebble = tester.getRect(_pebble('carlos'));

      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(tile.height, 104);
      expect(oven0.left, tile.left + AppSpacing.sm);
      expect(pebble.right, tile.right - AppSpacing.sm);
      expect(oven0.right, lessThanOrEqualTo(pebble.left));
      expect(pebble.bottom, closeTo(oven0.bottom, 1), reason: 'one line');
      expect(pebble.bottom, tile.bottom - AppSpacing.sm);
    });

    testWidgets('110 x 100 holds a beacon, or an occupant', (tester) async {
      for (final tile in [
        _tile(beacons: [oven()]),
        _tile(occupants: const [_carlos]),
      ]) {
        await tester.pumpWidget(host(cell(tile, width: 110, height: 100)));

        expect(tester.takeException(), isNull);
        expect(tester.getSize(_key('bathroom')), const Size(110, 100));
      }
    });

    testWidgets('a beacon and an occupant too wide for one line wrap, they '
        'never overflow', (tester) async {
      await tester.pumpWidget(
        host(
          cell(
            _tile(occupants: const [_carlos], beacons: [oven()]),
            width: 110,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(_pebble('carlos')).top,
        greaterThanOrEqualTo(tester.getRect(beacon()).bottom),
        reason: 'the pebble wrapped under the beacon',
      );
      expect(
        tester.getRect(_key('bathroom')).bottom,
        greaterThanOrEqualTo(
          tester.getRect(_pebble('carlos')).bottom + AppSpacing.sm,
        ),
      );
    });

    testWidgets('grows at 1.5 and 2.0 when the parent lets the row grow', (
      tester,
    ) async {
      for (final scale in [1.5, 2.0]) {
        await tester.pumpWidget(
          host(
            cell(
              _tile(occupants: const [_carlos], beacons: [oven()]),
              width: 170,
            ),
            textScale: scale,
          ),
        );
        final reason = 'at ${scale}x';
        final tile = tester.getRect(_key('bathroom'));

        expect(tester.takeException(), isNull, reason: reason);
        expect(tile.height, greaterThan(104), reason: reason);
        for (final finder in [beacon(), _pebble('carlos')]) {
          final box = tester.getRect(finder);
          expect(box.left, greaterThanOrEqualTo(tile.left), reason: reason);
          expect(box.right, lessThanOrEqualTo(tile.right), reason: reason);
          expect(
            box.bottom,
            lessThanOrEqualTo(tile.bottom - AppSpacing.sm + 0.01),
            reason: reason,
          );
        }
      }
    });
  });

  group('draw form', () {
    setUpAll(loadBundledFonts);

    RoomTile drawTile({
      RoomTileState state = RoomTileState.home,
      String id = 'bedroom1',
      String name = 'Bedroom 1',
      String caption = 'from Bedroom 3',
      String? label,
      List<MemberView> occupants = const [_carlos],
      VoidCallback? onTap,
    }) => _tile(
      state: state,
      id: id,
      name: name,
      caption: caption,
      label:
          label ??
          '$name: ${occupants.map((m) => m.name).join(' and ')}, $caption',
      occupants: occupants,
      onTap: onTap,
      draw: true,
    );

    Finder bedroom() => _key('bedroom1');

    testWidgets('the name is alone on top and the caption sits at the bottom, '
        'beside the pebble', (tester) async {
      await tester.pumpWidget(host(_cell(drawTile())));

      final tile = tester.getRect(bedroom());
      final name = tester.getRect(find.text('Bedroom 1'));
      final caption = tester.getRect(find.text('from Bedroom 3'));
      final pebble = tester.getRect(_pebble('carlos'));
      expect(pebble.left, tile.left + AppSpacing.sm, reason: 'at the start');
      expect(pebble.bottom, tile.bottom - AppSpacing.sm);
      expect(
        caption.left,
        closeTo(pebble.right + AppSpacing.xs, 0.01),
        reason: 'beside the pebble',
      );
      expect(caption.center.dy, closeTo(pebble.center.dy, 0.5));
      expect(caption.top, greaterThan(name.bottom + 8), reason: 'not under it');
    });

    testWidgets('a group of people keeps its order, pebbles first', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _cell(
            drawTile(
              id: 'bedroom2',
              name: 'Bedroom 2 · 2 beds',
              occupants: const [_ana, _carlos],
              caption: 'from Bedroom 4',
            ),
            width: 240,
          ),
        ),
      );

      final ana = tester.getRect(_pebble('ana'));
      final carlos = tester.getRect(_pebble('carlos'));
      final caption = tester.getRect(find.text('from Bedroom 4'));
      expect(ana.right + AppSpacing.xs, closeTo(carlos.left, 0.01));
      expect(carlos.right + AppSpacing.xs, closeTo(caption.left, 0.01));
    });

    testWidgets('a bedroom that stays free shows only the caption at the '
        'bottom start, on the dashed wall', (tester) async {
      await tester.pumpWidget(
        host(
          _cell(
            drawTile(
              state: RoomTileState.free,
              occupants: const [],
              caption: 'Stays free',
              label: 'Bedroom 1, stays free',
            ),
          ),
        ),
      );

      final tile = tester.getRect(bedroom());
      final caption = tester.getRect(find.text('Stays free'));
      expect(find.byType(AppPebble), findsNothing);
      expect(caption.left, tile.left + AppSpacing.sm);
      expect(caption.bottom, tile.bottom - AppSpacing.sm);
      expect(
        (_decoration(tester, id: 'bedroom1').shape as DashedBorder).side.color,
        CompappTheme.light.colorScheme.outlineVariant,
      );
    });

    testWidgets('every state keeps its wall in the draw form', (tester) async {
      for (final state in RoomTileState.values) {
        await tester.pumpWidget(
          host(
            _cell(drawTile(state: state)),
            background: CompappTheme.light.colorScheme.surface,
          ),
        );
        final size = tester.getSize(bedroom());

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(size.width - 12, 12),
          ),
          isSameColorAs(_fillOf(CompappTheme.light, state)),
          reason: state.name,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is AppIcon && w.icon == AppIcons.occupied,
          ),
          state == RoomTileState.occupied ? findsOneWidget : findsNothing,
        );
      }
    });

    testWidgets('without draw the caption stays under the name', (
      tester,
    ) async {
      await tester.pumpWidget(host(_cell(_tile(occupants: const [_carlos]))));
      final caption = tester.getRect(find.text('occupied'));
      final name = tester.getRect(find.text('Bathroom'));

      expect(caption.top, closeTo(name.bottom, 4));
      expect(caption.left, name.left);
    });

    testWidgets('the caption wraps under the pebbles when the line is full', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _cell(
            drawTile(occupants: const [_ana, _carlos]),
            width: 128,
            height: 140,
          ),
        ),
      );

      final carlos = tester.getRect(_pebble('carlos'));
      final caption = tester.getRect(find.text('from Bedroom 3'));
      expect(caption.top, greaterThanOrEqualTo(carlos.bottom));
      expect(caption.left, tester.getRect(bedroom()).left + AppSpacing.sm);
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final (width, direction) in [
        (_tileWidth, TextDirection.ltr),
        (_tileWidth, TextDirection.rtl),
        (320.0, TextDirection.ltr),
        (360.0, TextDirection.rtl),
      ]) {
        testWidgets('Spanish text at ${scale}x in ${width.toInt()} '
            '${direction.name} wraps whole words and stays inside', (
          tester,
        ) async {
          const name = 'Dormitorio 4 · 2 camas';
          const caption = 'desde Dormitorio 3';
          await tester.pumpWidget(
            host(
              Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: width,
                  child: drawTile(
                    name: name,
                    caption: caption,
                    occupants: const [_ana, _carlos],
                  ),
                ),
              ),
              textScale: scale,
              direction: direction,
              width: 400,
            ),
          );

          expect(tester.takeException(), isNull);
          final tile = tester.getRect(bedroom());
          for (final finder in [
            find.text(name),
            find.text(caption),
            _pebble('ana'),
            _pebble('carlos'),
          ]) {
            final box = tester.getRect(finder);
            expect(
              box.left,
              greaterThanOrEqualTo(tile.left + AppSpacing.sm - 0.01),
            );
            expect(
              box.right,
              lessThanOrEqualTo(tile.right - AppSpacing.sm + 0.01),
            );
            expect(
              box.bottom,
              lessThanOrEqualTo(tile.bottom - AppSpacing.sm + 0.01),
            );
          }
          expectNoMidWordBreaks(tester, find.text(name));
          expectNoMidWordBreaks(tester, find.text(caption));
          if (direction == TextDirection.rtl) {
            expect(
              tester.getRect(_pebble('ana')).right,
              tile.right - AppSpacing.sm,
              reason: 'the pebbles start at the right',
            );
          }
        });
      }
    }

    testWidgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          IntrinsicWidth(
            child: IntrinsicHeight(
              child: drawTile(occupants: const [_ana, _carlos]),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('its dry layout agrees with its real one', (tester) async {
      await tester.pumpWidget(
        host(
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: 150,
              child: drawTile(occupants: const [_ana, _carlos]),
            ),
          ),
        ),
      );
      final box = tester.renderObject<RenderBox>(bedroom());

      expect(box.getDryLayout(const BoxConstraints(maxWidth: 150)), box.size);
    });

    testWidgets('is one node named by the label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_cell(drawTile())));

      expect(
        tester.getSemantics(bedroom()),
        isSemantics(label: 'Bedroom 1: Carlos, from Bedroom 3'),
      );
      expect(semanticsLabels(tester), ['Bedroom 1: Carlos, from Bedroom 3']);
      handle.dispose();
    });

    testWidgets('with an onTap it is still a button named by the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(host(_cell(drawTile(onTap: () => taps++))));

      expect(
        tester.getSemantics(bedroom()),
        isSemantics(
          label: 'Bedroom 1: Carlos, from Bedroom 3',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(bedroom());
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a draw tile with beacons is refused', (tester) async {
      await tester.pumpWidget(
        host(
          _cell(
            RoomTile(
              room: const RoomView(id: 'a', name: 'A'),
              state: RoomTileState.free,
              caption: 'free',
              semanticLabel: 'A, free',
              draw: true,
              beacons: [_beacon('Oven')],
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('no beacons'),
        ),
      );
    });

    testWidgets('a draw tile whose label lacks its name is refused', (
      tester,
    ) async {
      await tester.pumpWidget(host(_cell(drawTile(label: 'Carlos goes here'))));

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('label in name'),
        ),
      );
    });

    for (final (name, theme) in themes) {
      test('its caption reaches 4.5:1 on every wall ($name)', () {
        final scheme = theme.colorScheme;
        expectContrast(
          {
            for (final state in RoomTileState.values)
              '${state.name} caption': (
                switch (state) {
                  RoomTileState.away ||
                  RoomTileState.free => scheme.onSurfaceVariant,
                  RoomTileState.home ||
                  RoomTileState.occupied => scheme.onSurface,
                },
                _fillOf(theme, state),
              ),
          },
          minimum: 4.5,
          reason: name,
        );
      });
    }
  });

  group('tapped', () {
    RoomTile tappable({
      VoidCallback? onTap,
      List<Widget> beacons = const [],
      RoomTileState state = RoomTileState.free,
    }) => RoomTile(
      room: const RoomView(id: 'bathroom', name: 'Bathroom'),
      state: state,
      caption: 'free',
      semanticLabel: 'Bathroom, free',
      beacons: beacons,
      onTap: onTap ?? () {},
    );

    /// Room for the ring: it is drawn outside the tile, and the host clips at
    /// its boundary.
    Widget padded(Widget child) =>
        Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: child);

    Future<void> tab(WidgetTester tester, [int times = 1]) async {
      for (var i = 0; i < times; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.pumpAndSettle();
    }

    Future<int> inkAbove(
      WidgetTester tester,
      ThemeData theme, {
      double depth = AppSizes.borderEmphasis,
    }) async {
      final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
      final tile = tester.getRect(_key('bathroom')).shift(-boundary);
      final strip = await paintedPixels(
        tester,
        hostBoundaryKey,
        region: Rect.fromLTWH(
          tile.left + 24,
          tile.top - depth,
          tile.width - 48,
          depth,
        ),
      );
      return countPixels(strip, theme.colorScheme.onSurface);
    }

    testWidgets('a tap on the tile calls onTap once, anywhere on it', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(_cell(tappable(onTap: () => taps++), width: 200)),
      );
      final rect = tester.getRect(_key('bathroom'));

      for (final point in [
        rect.center,
        rect.topLeft + const Offset(1, 1),
        rect.bottomRight - const Offset(1, 1),
      ]) {
        await tester.tapAt(point);
      }
      expect(taps, 3);
    });

    testWidgets('a tile without onTap takes no focus and is no button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_cell(_tile(beacons: [_beacon('Oven')]))));

      await tab(tester);

      expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('RoomTile'));
      expect(
        tester.getSemantics(_key('bathroom')),
        isSemantics(
          label: 'Bathroom, occupied by Carlos, 12 minutes',
          isButton: false,
          isFocusable: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('a tap on a beacon calls the beacon and not the tile', (
      tester,
    ) async {
      var tile = 0;
      var beacon = 0;
      await tester.pumpWidget(
        host(
          _cell(
            tappable(
              onTap: () => tile++,
              beacons: [
                TextButton(
                  key: const Key('beacon.Oven'),
                  onPressed: () => beacon++,
                  child: const Text('Oven'),
                ),
              ],
            ),
            height: 140,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('beacon.Oven')));

      expect([tile, beacon], [0, 1]);
    });

    testWidgets('Enter and Space on the focused tile call onTap', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(_cell(tappable(onTap: () => taps++), width: 200)),
      );

      await tab(tester);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'RoomTile');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);

      expect(taps, 2);
    });

    testWidgets('Enter on a focused beacon is the beacon, not the tile', (
      tester,
    ) async {
      var tile = 0;
      var beacon = 0;
      await tester.pumpWidget(
        host(
          _cell(
            tappable(
              onTap: () => tile++,
              beacons: [
                TextButton(
                  key: const Key('beacon.Oven'),
                  onPressed: () => beacon++,
                  child: const Text('Oven'),
                ),
              ],
            ),
            height: 140,
          ),
        ),
      );

      await tab(tester, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect([tile, beacon], [0, 1]);
    });

    testWidgets('a rebuild during a press neither cancels it nor keeps the '
        'old callback', (tester) async {
      var first = 0;
      var second = 0;
      await tester.pumpWidget(
        host(_cell(tappable(onTap: () => first++), width: 200)),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(_key('bathroom')),
      );
      await tester.pump(kPressTimeout);

      await tester.pumpWidget(
        host(_cell(tappable(onTap: () => second++), width: 200)),
      );
      await gesture.up();

      expect([first, second], [0, 1]);
    });

    group('the press layer', () {
      RoomTile withBeacon() => RoomTile(
        room: const RoomView(id: 'bathroom', name: 'Bathroom'),
        state: RoomTileState.free,
        caption: 'free',
        semanticLabel: 'Bathroom, free',
        beacons: [
          TextButton(
            key: const Key('beacon.Oven'),
            onPressed: () {},
            child: const Text('Oven'),
          ),
        ],
        onTap: () {},
      );

      final scheme = CompappTheme.light.colorScheme;
      final fill = scheme.surfaceContainerLowest;
      final layer = Color.alphaBlend(
        scheme.onSurface.withValues(alpha: AppStateLayers.pressedSecondary),
        fill,
      );
      bool near(Color a, Color b) =>
          (a.r - b.r).abs() < 0.01 &&
          (a.g - b.g).abs() < 0.01 &&
          (a.b - b.b).abs() < 0.01;

      Future<bool> showsLayer(WidgetTester tester) async {
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final point =
            tester.getTopLeft(_key('bathroom')) -
            boundary +
            const Offset(40, 8);
        final color = await paintedColorAt(tester, hostBoundaryKey, point);
        expect(near(color, layer) || near(color, fill), isTrue);
        return near(color, layer);
      }

      testWidgets('a press on a beacon shows no layer on the tile, held for '
          'as long as you like', (tester) async {
        await tester.pumpWidget(host(_cell(withBeacon(), height: 140)));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('beacon.Oven'))),
        );

        for (final held in [150, 300, 1000]) {
          await tester.pump(Duration(milliseconds: held));
          expect(await showsLayer(tester), isFalse, reason: 'held $held ms');
        }
        await gesture.up();
        await tester.pump();
        expect(await showsLayer(tester), isFalse);
      });

      testWidgets('the layer is back for the tile after a beacon was '
          'pressed and released', (tester) async {
        await tester.pumpWidget(host(_cell(withBeacon(), height: 140)));
        await tester.tap(find.byKey(const Key('beacon.Oven')));
        await tester.pump(kPressTimeout);

        final gesture = await tester.startGesture(
          tester.getTopLeft(_key('bathroom')) + const Offset(40, 8),
        );
        await tester.pump(kPressTimeout);
        expect(await showsLayer(tester), isTrue);
        await gesture.up();
      });

      testWidgets('a press held past 100 ms and then dragged away or '
          'cancelled leaves no layer', (tester) async {
        await tester.pumpWidget(host(_cell(withBeacon(), height: 140)));
        final start = tester.getTopLeft(_key('bathroom')) + const Offset(40, 8);

        final drag = await tester.startGesture(start);
        await tester.pump(kPressTimeout);
        expect(await showsLayer(tester), isTrue);
        await drag.moveBy(const Offset(0, 80));
        await tester.pump();
        expect(await showsLayer(tester), isFalse, reason: 'dragged away');
        await drag.up();

        final cancelled = await tester.startGesture(start);
        await tester.pump(kPressTimeout);
        expect(await showsLayer(tester), isTrue);
        await cancelled.cancel();
        await tester.pump();
        expect(await showsLayer(tester), isFalse, reason: 'cancelled');
      });
    });

    group('semantics', () {
      testWidgets('has the focus action, and screen-reader focus moves the '
          'input focus', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(_cell(tappable(), width: 200)));

        expect(
          tester.getSemantics(_key('bathroom')),
          isSemantics(hasFocusAction: true),
        );
        tester.semantics.performAction(
          find.semantics.byLabel('Bathroom, free'),
          SemanticsAction.focus,
        );
        await tester.pump();

        expect(FocusManager.instance.primaryFocus?.debugLabel, 'RoomTile');
        handle.dispose();
      });

      testWidgets('has no focus action on iOS, where VoiceOver keeps its own '
          'focus', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(_cell(tappable(), width: 200)));

        expect(
          tester.getSemantics(_key('bathroom')),
          isSemantics(hasFocusAction: false),
        );
        debugDefaultTargetPlatformOverride = null;
        handle.dispose();
      });

      testWidgets('is one focusable button node named by the label, with '
          'a tap action', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(_cell(tappable(), width: 200)));

        expect(
          tester.getSemantics(_key('bathroom')),
          isSemantics(
            label: 'Bathroom, free',
            isButton: true,
            isFocusable: true,
            isFocused: false,
            hasTapAction: true,
          ),
        );
        expect(semanticsLabels(tester), ['Bathroom, free']);
        handle.dispose();
      });

      testWidgets('says it is focused only while the tile itself is', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          host(_cell(tappable(beacons: [_beacon('Oven')]), height: 140)),
        );

        await tab(tester);
        expect(
          tester.getSemantics(_key('bathroom')),
          isSemantics(isFocused: true),
        );

        await tab(tester);
        expect(
          tester.getSemantics(_key('bathroom')),
          isSemantics(isFocused: false),
          reason: 'the beacon has the focus now',
        );
        handle.dispose();
      });

      testWidgets('the beacon is still its own button, a child of the tile', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          host(_cell(tappable(beacons: [_beacon('Oven')]), height: 140)),
        );

        final tile = tester.getSemantics(_key('bathroom'));
        final oven = tester.getSemantics(find.byKey(const Key('beacon.Oven')));
        expect(oven.parent, tile);
        expect(oven.label, 'Oven');
        expect(tile.label, 'Bathroom, free');
        expect(oven, isSemantics(isButton: true, hasTapAction: true));
        handle.dispose();
      });

      testWidgets('the semantics tap runs onTap', (tester) async {
        final handle = tester.ensureSemantics();
        var taps = 0;
        await tester.pumpWidget(
          host(_cell(tappable(onTap: () => taps++), width: 200)),
        );

        tester.semantics.tap(find.semantics.byLabel('Bathroom, free'));

        expect(taps, 1);
        handle.dispose();
      });
    });

    for (final (name, theme) in themes) {
      testWidgets('a focused tile has a 2 px ink ring outside its shape, '
          'and none inside it ($name)', (tester) async {
        await tester.pumpWidget(
          host(padded(_cell(tappable(), width: 200)), theme: theme),
        );
        expect(await inkAbove(tester, theme), 0);

        await tab(tester);

        expect(
          await inkAbove(tester, theme),
          greaterThan(0),
          reason: 'the ring is above the wall',
        );
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final tile = tester.getRect(_key('bathroom')).shift(-boundary);
        final inside = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: Rect.fromLTWH(
            tile.left + 24,
            tile.top + 2,
            tile.width - 48,
            4,
          ),
        );
        expect(
          countPixels(inside, theme.colorScheme.onSurface),
          lessThan(inside.length ~/ 2),
          reason: 'the ring leaves the wall to its own fill',
        );
      });

      testWidgets('the ring is not drawn when a beacon holds the focus, nor '
          'after a touch ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            padded(
              _cell(
                tappable(beacons: [_beacon('Oven')]),
                width: 200,
                height: 140,
              ),
            ),
            theme: theme,
          ),
        );

        await tab(tester);
        expect(await inkAbove(tester, theme), greaterThan(0));
        await tab(tester);
        expect(
          await inkAbove(tester, theme),
          0,
          reason: 'the beacon has the focus, not the tile',
        );

        await tab(tester);
        expect(await inkAbove(tester, theme), greaterThan(0));
        await tester.tapAt(
          tester.getTopLeft(_key('bathroom')) + const Offset(20, 100),
        );
        await tester.pumpAndSettle();
        expect(
          await inkAbove(tester, theme),
          0,
          reason: 'a touch ends the keyboard highlight',
        );
      });

      testWidgets('a press shows the surface layer over the wall and lifts '
          'with the finger ($name)', (tester) async {
        await tester.pumpWidget(
          host(padded(_cell(tappable(), width: 200)), theme: theme),
        );
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        final point =
            tester.getTopLeft(_key('bathroom')) -
            boundary +
            const Offset(40, 10);
        final fill = theme.colorScheme.surfaceContainerLowest;
        final pressed = Color.alphaBlend(
          theme.colorScheme.onSurface.withValues(
            alpha: AppStateLayers.pressedSecondary,
          ),
          fill,
        );
        bool near(Color a, Color b) =>
            (a.r - b.r).abs() < 0.01 &&
            (a.g - b.g).abs() < 0.01 &&
            (a.b - b.b).abs() < 0.01;

        expect(
          near(await paintedColorAt(tester, hostBoundaryKey, point), fill),
          isTrue,
        );
        final gesture = await tester.startGesture(point + boundary);
        await tester.pump(kPressTimeout);
        expect(
          near(await paintedColorAt(tester, hostBoundaryKey, point), pressed),
          isTrue,
        );
        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          near(await paintedColorAt(tester, hostBoundaryKey, point), fill),
          isTrue,
        );
      });

      test('the ring reaches 3:1 on the page and on every wall ($name)', () {
        final scheme = theme.colorScheme;
        final colors = theme.extension<AppColors>()!;
        expectContrast(
          {
            for (final (wall, color) in [
              ('page', scheme.surface),
              ('free', scheme.surfaceContainerLowest),
              ('away', scheme.surfaceContainerHigh),
              ('home', scheme.primaryContainer),
              ('occupied', colors.busySoft),
            ])
              wall: (scheme.onSurface, color),
          },
          minimum: 3,
          reason: 'the focus ring of a tile ($name)',
        );
      });
    }
  });
}

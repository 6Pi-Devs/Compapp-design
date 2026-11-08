import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';

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
}) => RoomTile(
  room: RoomView(id: id, name: name),
  state: state,
  caption: caption,
  semanticLabel: label,
  occupants: occupants,
  beacons: beacons,
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

ShapeDecoration _decoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(of: _key('bathroom'), matching: find.byType(DecoratedBox))
        .first,
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

        final dashed =
            _decoration(tester).shape.runtimeType.toString() == '_DashedBorder';
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
}

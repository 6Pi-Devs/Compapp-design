import 'dart:io';

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

const _boundaryKey = Key('pebble-boundary');

Widget _host(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  bool boundary = false,
}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    builder: (context, app) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: boundary
              ? RepaintBoundary(key: _boundaryKey, child: child)
              : child,
        ),
      ),
    ),
  );
}

AppPebble _pebble({
  String initials = 'A',
  int joinOrder = 0,
  AppPebbleSize size = AppPebbleSize.s44,
  AppPebbleStatus status = AppPebbleStatus.home,
  bool isYou = false,
  bool isAdmin = false,
  String label = 'Ana',
}) => AppPebble(
  initials: initials,
  joinOrder: joinOrder,
  semanticLabel: label,
  size: size,
  status: status,
  isYou: isYou,
  isAdmin: isAdmin,
);

Finder get _away => find.byKey(const Key('pebble.badge.away'));
Finder get _admin => find.byKey(const Key('pebble.badge.admin'));
Finder get _initials =>
    find.descendant(of: find.byType(AppPebble), matching: find.byType(Text));

Color _badgeFill(WidgetTester tester, Finder badge) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: badge, matching: find.byType(DecoratedBox)),
  );
  return (box.decoration as BoxDecoration).color!;
}

Color _badgeGlyph(WidgetTester tester, Finder badge) => tester
    .widget<AppIcon>(find.descendant(of: badge, matching: find.byType(AppIcon)))
    .color!;

/// The dashes the pebble draws on top of its face.
int _dashes(WidgetTester tester) {
  final canvas = TestRecordingCanvas();
  final custom = tester.renderObject<RenderCustomPaint>(
    find
        .descendant(
          of: find.byType(AppPebble),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  custom.foregroundPainter?.paint(canvas, custom.size);
  return canvas.invocations
      .where((call) => call.invocation.memberName == #drawPath)
      .length;
}

Future<Color> _pixel(WidgetTester tester, Offset point) =>
    paintedColorAt(tester, _boundaryKey, point);

/// How much of each pixel of the pebble in the boundary is ink, from 0 (the
/// pastel fill) to 1 (the dark on-pebble ink), at four pixels per logical
/// pixel. Anti-aliased edge pixels count in proportion, so a faint fringe is
/// seen. Pixels outside the rounded shape (transparent) are 0.
class _InkGrid {
  const new(this.width, this.height, this.coverage);

  static const scale = 4;

  final int width;
  final int height;
  final List<double> coverage;

  double at(int x, int y) => coverage[y * width + x];

  /// The box around every pixel with more than [threshold] of ink.
  Rect? bounds({double threshold = _fringe}) {
    var left = width;
    var top = height;
    var right = -1;
    var bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (at(x, y) > threshold) {
          if (x < left) left = x;
          if (y < top) top = y;
          if (x > right) right = x;
          if (y > bottom) bottom = y;
        }
      }
    }
    if (right < 0) return null;
    return Rect.fromLTRB(
      left / scale,
      top / scale,
      (right + 1) / scale,
      (bottom + 1) / scale,
    );
  }

  /// Whether a pixel with more than [threshold] of ink shares area with the
  /// painted [shape], in the logical coordinates of the boundary. A pixel
  /// counts when any of nine points spread over it is inside the shape, so
  /// the empty corner of a badge's bounding box is not part of the badge.
  bool touches(RRect shape, {double threshold = _fringe}) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (at(x, y) <= threshold) continue;
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 3; j++) {
            final point = Offset(
              (x + (i + 0.5) / 3) / scale,
              (y + (j + 0.5) / 3) / scale,
            );
            if (shape.contains(point)) return true;
          }
        }
      }
    }
    return false;
  }

  /// The pixels that are ink here and not in [other]: the part of a glyph
  /// that [other] (the same letters without it) does not draw.
  _InkGrid minus(_InkGrid other) => _InkGrid(width, height, [
    for (var i = 0; i < coverage.length; i++)
      if (coverage[i] > 0.5 && other.coverage[i] < 0.1) coverage[i] else 0,
  ]);
}

/// The faintest share of ink that counts as a mark, so an anti-aliased fringe
/// is seen and rounding noise is not.
const _fringe = 0.02;

Future<_InkGrid> _inkGrid(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  final grid = await tester.runAsync<_InkGrid>(() async {
    final image = await boundary.toImage(pixelRatio: _InkGrid.scale.toDouble());
    final data = (await image.toByteData())!;
    final fill = CompappTheme.light.extension<AppColors>()!.pebbles.first;
    final ink = CompappTheme.light.extension<AppColors>()!.onPebble;
    int sum(Color c) =>
        (c.r * 255).round() + (c.g * 255).round() + (c.b * 255).round();
    final span = sum(fill) - sum(ink);
    final w = image.width;
    final h = image.height;
    // The anti-aliased rim of the pebble itself is not ink: keep only the
    // pixels that are opaque for one logical pixel around.
    const reach = _InkGrid.scale;
    final opaque = [
      for (var i = 0; i < w * h; i++) data.getUint8(i * 4 + 3) >= 250,
    ];
    final across = List<bool>.filled(w * h, false);
    for (var y = 0; y < h; y++) {
      for (var x = reach; x < w - reach; x++) {
        var all = true;
        for (var k = -reach; k <= reach && all; k++) {
          all = opaque[y * w + x + k];
        }
        across[y * w + x] = all;
      }
    }
    final inside = List<bool>.filled(w * h, false);
    for (var x = 0; x < w; x++) {
      for (var y = reach; y < h - reach; y++) {
        var all = true;
        for (var k = -reach; k <= reach && all; k++) {
          all = across[(y + k) * w + x];
        }
        inside[y * w + x] = all;
      }
    }
    final coverage = <double>[];
    for (var i = 0; i < w * h; i++) {
      if (!inside[i]) {
        coverage.add(0);
        continue;
      }
      final pixel =
          data.getUint8(i * 4) +
          data.getUint8(i * 4 + 1) +
          data.getUint8(i * 4 + 2);
      coverage.add(((sum(fill) - pixel) / span).clamp(0.0, 1.0));
    }
    return _InkGrid(image.width, image.height, coverage);
  });
  return grid!;
}

List<SemanticsNode> _nodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(Scaffold)));
  return nodes;
}

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      testWidgets('the pebble color follows the join order, wrapping after '
          'six ($name)', (tester) async {
        for (var order = 0; order < 14; order++) {
          await tester.pumpWidget(
            _host(_pebble(joinOrder: order), theme: theme, boundary: true),
          );

          final fill = await _pixel(tester, const Offset(3, 22));
          expect(
            fill,
            isSameColorAs(colors.pebbles[order % 6]),
            reason: 'join order $order',
          );
        }
      });

      testWidgets('initials are dark ink on the pastel pebble in both themes '
          '($name)', (tester) async {
        await tester.pumpWidget(_host(_pebble(), theme: theme, boundary: true));

        final text = await paintedColorAtCenter(
          tester,
          _boundaryKey,
          _initials,
        );
        expect(text, isSameColorAs(colors.onPebble));
        expect(text, isSameColorAs(const Color(0xFF1C2B22)));
      });

      testWidgets('invited has no fill and muted initials and outline '
          '($name)', (tester) async {
        await tester.pumpWidget(
          _host(
            _pebble(status: AppPebbleStatus.invited),
            theme: theme,
            boundary: true,
          ),
        );

        expect((await _pixel(tester, const Offset(3, 22))).a, 0);
        expect(
          await paintedColorAtCenter(tester, _boundaryKey, _initials),
          isSameColorAs(scheme.onSurfaceVariant),
        );
        expect(_dashes(tester), greaterThan(8));
        final custom = tester.renderObject<RenderCustomPaint>(
          find
              .descendant(
                of: find.byType(AppPebble),
                matching: find.byType(CustomPaint),
              )
              .first,
        );
        expect(
          custom,
          paints..something((method, arguments) {
            if (method != #drawPath) return false;
            final paint = arguments[1] as Paint;
            expect(paint.color, isSameColorAs(scheme.onSurfaceVariant));
            expect(paint.strokeWidth, AppSizes.borderDashed);
            return true;
          }),
        );
      });

      testWidgets('isYou on a filled pebble draws a dark 2 px ring inset by '
          '2 px and keeps the fill ($name)', (tester) async {
        await tester.pumpWidget(
          _host(_pebble(isYou: true), theme: theme, boundary: true),
        );

        final fill = colors.pebbles.first;
        for (final (x, expected) in [
          (1.0, fill),
          (2.0, colors.onPebble),
          (3.0, colors.onPebble),
          (5.0, fill),
        ]) {
          expect(
            await _pixel(tester, Offset(x, 22)),
            isSameColorAs(expected),
            reason: 'x = $x',
          );
        }

        await tester.pumpWidget(_host(_pebble(), theme: theme, boundary: true));
        expect(await _pixel(tester, const Offset(3, 22)), isSameColorAs(fill));
      });

      testWidgets('invited and isYou together draw the solid border, not '
          'dashes, and still no fill ($name)', (tester) async {
        await tester.pumpWidget(
          _host(
            _pebble(status: AppPebbleStatus.invited, isYou: true),
            theme: theme,
            boundary: true,
          ),
        );

        expect(_dashes(tester), 0);
        expect(
          await _pixel(tester, const Offset(1, 22)),
          isSameColorAs(scheme.onSurface),
        );
        expect((await _pixel(tester, const Offset(0, 22))).a, 1);
        expect((await _pixel(tester, const Offset(5, 22))).a, 0);
        expect(
          await paintedColorAtCenter(tester, _boundaryKey, _initials),
          isSameColorAs(scheme.onSurfaceVariant),
        );
      });

      testWidgets('badges use the away and ink colors with a glyph on top '
          '($name)', (tester) async {
        await tester.pumpWidget(
          _host(
            _pebble(status: AppPebbleStatus.away, isAdmin: true),
            theme: theme,
          ),
        );

        expect(_badgeFill(tester, _away), isSameColorAs(colors.presenceAway));
        expect(
          _badgeGlyph(tester, _away),
          isSameColorAs(colors.onPresenceAway),
        );
        expect(
          _badgeFill(tester, _admin),
          isSameColorAs(scheme.inverseSurface),
        );
        expect(
          _badgeGlyph(tester, _admin),
          isSameColorAs(scheme.onInverseSurface),
        );
        expect(
          tester
              .widget<AppIcon>(
                find.descendant(of: _away, matching: find.byType(AppIcon)),
              )
              .icon,
          AppIcons.away,
        );
        expect(
          tester
              .widget<AppIcon>(
                find.descendant(of: _admin, matching: find.byType(AppIcon)),
              )
              .icon,
          AppIcons.adminKey,
        );
      });
    }
  });

  group('size and shape', () {
    testWidgets('every size is a square of its side with 30% corners', (
      tester,
    ) async {
      for (final (size, side) in const [
        (AppPebbleSize.s28, 28.0),
        (AppPebbleSize.s36, 36.0),
        (AppPebbleSize.s44, 44.0),
        (AppPebbleSize.s56, 56.0),
        (AppPebbleSize.s72, 72.0),
      ]) {
        await tester.pumpWidget(_host(_pebble(size: size)));

        expect(tester.getSize(find.byType(AppPebble)), Size.square(side));
        final face = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(AppPebble),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(
          (face.decoration as BoxDecoration).borderRadius,
          BorderRadius.circular(side * 0.3),
          reason: '$size',
        );
      }
    });

    testWidgets('badges are 20 from s44 up and not drawn on s28 and s36', (
      tester,
    ) async {
      for (final size in AppPebbleSize.values) {
        await tester.pumpWidget(
          _host(
            _pebble(size: size, status: AppPebbleStatus.away, isAdmin: true),
          ),
        );

        if (size.hasBadges) {
          expect(tester.getSize(_away), const Size.square(20), reason: '$size');
          expect(tester.getSize(_admin), const Size.square(20));
        } else {
          expect(_away, findsNothing, reason: '$size draws no away badge');
          expect(_admin, findsNothing, reason: '$size draws no admin badge');
        }
      }
      expect(
        [for (final size in AppPebbleSize.values) size.hasBadges],
        [false, false, true, true, true],
      );
    });

    testWidgets('home draws no badge, admin and away draw theirs apart', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_pebble()));
      expect(_away, findsNothing);
      expect(_admin, findsNothing);

      await tester.pumpWidget(_host(_pebble(isAdmin: true)));
      expect(_away, findsNothing);
      expect(_admin, findsOneWidget);

      await tester.pumpWidget(_host(_pebble(status: AppPebbleStatus.away)));
      expect(_away, findsOneWidget);
      expect(_admin, findsNothing);

      await tester.pumpWidget(_host(_pebble(status: AppPebbleStatus.invited)));
      expect(_away, findsNothing);
      expect(_admin, findsNothing);

      await tester.pumpWidget(
        _host(_pebble(status: AppPebbleStatus.away, isAdmin: true)),
      );
      expect(
        tester.getRect(_admin).overlaps(tester.getRect(_away)),
        isFalse,
        reason: 'two badges never sit on top of each other',
      );
    });

    for (final (direction, label) in const [
      (TextDirection.ltr, 'ltr'),
      (TextDirection.rtl, 'rtl'),
    ]) {
      testWidgets('badges hang at the trailing edge, status below and admin '
          'above ($label)', (tester) async {
        await tester.pumpWidget(
          _host(
            _pebble(status: AppPebbleStatus.away, isAdmin: true),
            direction: direction,
          ),
        );

        const hang = AppSizes.pebbleBadgeOffset;
        final pebble = tester.getRect(find.byType(AppPebble));
        final away = tester.getRect(_away);
        final admin = tester.getRect(_admin);
        final ltr = direction == TextDirection.ltr;
        expect(
          ltr ? away.right : away.left,
          ltr ? pebble.right + hang : pebble.left - hang,
        );
        expect(away.bottom, pebble.bottom + hang);
        expect(
          ltr ? admin.right : admin.left,
          ltr ? pebble.right + hang : pebble.left - hang,
        );
        expect(admin.top, pebble.top - hang);
      });

      testWidgets('the initials stay centered and unmirrored ($label)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(_pebble(initials: 'AB'), direction: direction),
        );

        expect(
          tester.getCenter(_initials),
          tester.getCenter(find.byType(AppPebble)),
        );
      });
    }
  });

  group('semantics', () {
    testWidgets('is one image named by the label, drawn parts excluded', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          _pebble(
            status: AppPebbleStatus.away,
            isAdmin: true,
            isYou: true,
            label: 'Ana, you, admin, away',
          ),
        ),
      );

      final labeled = _nodes(tester).where((node) => node.label.isNotEmpty);
      expect(labeled, hasLength(1));
      expect(labeled.single.label, 'Ana, you, admin, away');
      expect(labeled.single.flagsCollection.isImage, isTrue);
      expect(find.bySemanticsLabel('A'), findsNothing);
      handle.dispose();
    });

    testWidgets('keeps its own node inside a labeled container parent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Semantics(
            container: true,
            label: 'Roommates',
            child: _pebble(label: 'Ana, away'),
          ),
        ),
      );

      final labels = [
        for (final node in _nodes(tester))
          if (node.label.isNotEmpty) node.label,
      ];
      expect(labels, containsAll(['Roommates', 'Ana, away']));
      expect(labels, isNot(contains('Roommates\nAna, away')));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Ana, away'))
            .flagsCollection
            .isImage,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('has no tap target: nothing in it is a button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_pebble(isAdmin: true)));

      expect(
        _nodes(tester).any((node) => node.flagsCollection.isButton),
        isFalse,
      );
      handle.dispose();
    });
  });

  group('semantics under a merging parent', () {
    testWidgets('merges into the row it sits in, label after label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MergeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Roommates'),
                _pebble(label: 'Ana, away'),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Roommates')).getSemanticsData().label,
        'Roommates\nAna, away',
      );
      handle.dispose();
    });

    testWidgets('needs a spoken label', (tester) async {
      expect(() => _pebble(label: ''), throwsAssertionError);
    });
  });

  group('repaint', () {
    CustomPainter painterOf(WidgetTester tester) => tester
        .renderObject<RenderCustomPaint>(
          find
              .descendant(
                of: find.byType(AppPebble),
                matching: find.byType(CustomPaint),
              )
              .first,
        )
        .foregroundPainter!;

    testWidgets('repaints when only the color changes', (tester) async {
      await tester.pumpWidget(
        _host(
          _pebble(status: AppPebbleStatus.invited),
          theme: CompappTheme.light,
        ),
      );
      final light = painterOf(tester);
      await tester.pumpWidget(
        _host(
          _pebble(status: AppPebbleStatus.invited),
          theme: CompappTheme.dark,
        ),
      );
      await tester.pumpAndSettle();
      final dark = painterOf(tester);

      expect(dark.shouldRepaint(light), isTrue);
    });

    testWidgets('repaints when only the inset changes', (tester) async {
      // In the light theme the ink and on-pebble colors are the same, and both
      // rings are solid and 2 px wide: only the inset tells them apart.
      await tester.pumpWidget(
        _host(_pebble(status: AppPebbleStatus.invited, isYou: true)),
      );
      final edge = painterOf(tester);
      await tester.pumpWidget(_host(_pebble(isYou: true)));
      final inset = painterOf(tester);

      expect(inset.shouldRepaint(edge), isTrue);
    });

    testWidgets('repaints when only the width or the dashes change', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_pebble(status: AppPebbleStatus.invited, isYou: true)),
      );
      final solid = painterOf(tester);
      await tester.pumpWidget(_host(_pebble(status: AppPebbleStatus.invited)));
      final dashed = painterOf(tester);

      expect(dashed.shouldRepaint(solid), isTrue);
    });

    testWidgets('repaints for another corner radius, not for the same look', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_pebble(isYou: true)));
      final small = painterOf(tester);
      await tester.pumpWidget(_host(_pebble(isYou: true)));
      final same = painterOf(tester);
      await tester.pumpWidget(
        _host(_pebble(isYou: true, size: AppPebbleSize.s72)),
      );
      final large = painterOf(tester);

      expect(same.shouldRepaint(small), isFalse);
      expect(large.shouldRepaint(small), isTrue);
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;
      final cards = {
        'card': scheme.surfaceContainerLowest,
        'page': scheme.surface,
        'sunken': scheme.surfaceContainerHigh,
      };

      test('initials reach 4.5:1 on every pebble color ($name)', () {
        expectContrast(
          {
            for (final (i, pebble) in colors.pebbles.indexed)
              'onPebble/${AppColors.pebbleNames[i]}': (colors.onPebble, pebble),
            for (final card in cards.entries)
              'onSurfaceVariant (invited)/${card.key}': (
                scheme.onSurfaceVariant,
                card.value,
              ),
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('shapes and glyphs reach 3:1 on what they sit on ($name)', () {
        expectContrast(
          {
            'away glyph/away badge': (
              colors.onPresenceAway,
              colors.presenceAway,
            ),
            'admin glyph/admin badge': (
              scheme.onInverseSurface,
              scheme.inverseSurface,
            ),
            for (final card in cards.entries) ...{
              'away badge/${card.key}': (colors.presenceAway, card.value),
              'admin badge/${card.key}': (scheme.inverseSurface, card.value),
              'invited outline/${card.key}': (
                scheme.onSurfaceVariant,
                card.value,
              ),
              'you ring (invited)/${card.key}': (scheme.onSurface, card.value),
            },
            for (final (i, pebble) in colors.pebbles.indexed)
              'you ring/${AppColors.pebbleNames[i]}': (colors.onPebble, pebble),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(() async {
      // The real glyphs: without the bundled fonts a test draws every glyph
      // as a solid em square, which proves nothing about the fit.
      Future<void> load(String family, List<String> files) async {
        final loader = FontLoader('packages/compapp_design/$family');
        for (final file in files) {
          final bytes = File('fonts/$file').readAsBytesSync();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
        }
        await loader.load();
      }

      await load('Bricolage Grotesque', ['BricolageGrotesque-Variable.ttf']);
      await load('Instrument Sans', [
        'InstrumentSans-Regular.ttf',
        'InstrumentSans-SemiBold.ttf',
      ]);
    });

    testWidgets('initials are never scaled down and the pebble grows to hold '
        'them at every size', (tester) async {
      for (final size in AppPebbleSize.values) {
        await tester.pumpWidget(_host(_pebble(initials: 'AB', size: size)));
        final base = tester.getSize(_initials);
        expect(tester.getSize(find.byType(AppPebble)), Size.square(size.side));

        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(
            _host(
              _pebble(initials: 'AB', size: size),
              textScale: scale,
            ),
          );

          final reason = '${size.name} at ${scale}x';
          final text = tester.getRect(_initials);
          final pebble = tester.getRect(find.byType(AppPebble));
          expect(text.height, closeTo(base.height * scale, 1), reason: reason);
          expect(text.width, closeTo(base.width * scale, 1.5), reason: reason);
          expect(
            text.left - pebble.left,
            greaterThanOrEqualTo(AppSpacing.xs - 0.01),
            reason: '$reason: room on the left',
          );
          expect(
            pebble.right - text.right,
            greaterThanOrEqualTo(AppSpacing.xs - 0.01),
            reason: '$reason: room on the right',
          );
          expect(
            text.top,
            greaterThanOrEqualTo(pebble.top),
            reason: '$reason: not cut above',
          );
          expect(
            text.bottom,
            lessThanOrEqualTo(pebble.bottom),
            reason: '$reason: not cut below',
          );
          expect(
            pebble.width,
            greaterThanOrEqualTo(size.side),
            reason: '$reason: never smaller than its side',
          );
        }
      }
    });

    testWidgets('the smallest pebble grows at 2.0 instead of clipping', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_pebble(initials: 'AB', size: AppPebbleSize.s28), textScale: 2),
      );

      final pebble = tester.getSize(find.byType(AppPebble));
      expect(pebble.width, greaterThan(AppPebbleSize.s28.side));
      expect(
        find.descendant(
          of: find.byType(AppPebble),
          matching: find.byType(ClipRect),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    // Every state at once: ring, away badge and admin key.
    const allStates = [
      ('home', AppPebbleStatus.home, false, false),
      ('away', AppPebbleStatus.away, false, false),
      ('invited', AppPebbleStatus.invited, false, false),
      ('you', AppPebbleStatus.home, false, true),
      ('admin', AppPebbleStatus.home, true, false),
      ('you + away + admin', AppPebbleStatus.away, true, true),
      ('you + invited + admin', AppPebbleStatus.invited, true, true),
    ];
    const worstInitials = ['A', 'MW', 'Á', 'Ñ'];
    const scales = [1.0, 1.01, 1.15, 1.3, 1.5, 2.0];

    Future<Size> pumpPebble(
      WidgetTester tester, {
      required AppPebbleSize size,
      required String initials,
      required AppPebbleStatus status,
      required bool admin,
      required bool you,
      double scale = 1,
    }) async {
      await tester.pumpWidget(
        _host(
          _pebble(
            initials: initials,
            size: size,
            status: status,
            isAdmin: admin,
            isYou: you,
          ),
          textScale: scale,
        ),
      );
      return tester.getSize(find.byType(AppPebble));
    }

    testWidgets('is exactly its nominal side at scale 1, in every state, for '
        'one or two initials', (tester) async {
      for (final size in AppPebbleSize.values) {
        for (final (name, status, admin, you) in allStates) {
          for (final initials in worstInitials) {
            expect(
              await pumpPebble(
                tester,
                size: size,
                initials: initials,
                status: status,
                admin: admin,
                you: you,
              ),
              Size.square(size.side),
              reason: '$name ${size.name} "$initials"',
            );
          }
        }
      }
    });

    testWidgets('is a square at every scale, and grows without a jump', (
      tester,
    ) async {
      for (final size in AppPebbleSize.values) {
        for (final (name, status, admin, you) in allStates) {
          for (final initials in ['A', 'MW']) {
            var previous = 0.0;
            for (final scale in scales) {
              final pebble = await pumpPebble(
                tester,
                size: size,
                initials: initials,
                status: status,
                admin: admin,
                you: you,
                scale: scale,
              );
              final reason = '$name ${size.name} "$initials" at ${scale}x';

              expect(pebble.width, pebble.height, reason: '$reason: square');
              expect(
                pebble.width,
                greaterThanOrEqualTo(previous),
                reason: '$reason: never smaller than at a smaller scale',
              );
              if (scale == 1.01) {
                expect(
                  pebble.width - previous,
                  lessThan(0.5),
                  reason: '$reason: tiny step from 1.0',
                );
              }
              previous = pebble.width;
            }
          }
        }
      }
    });

    testWidgets('grows at 2.0 once the text outgrows the side, and only then', (
      tester,
    ) async {
      final plain = await pumpPebble(
        tester,
        size: AppPebbleSize.s28,
        initials: 'MW',
        status: AppPebbleStatus.home,
        admin: false,
        you: true,
        scale: 2,
      );
      expect(plain.width, greaterThan(28));

      final small = await pumpPebble(
        tester,
        size: AppPebbleSize.s72,
        initials: 'A',
        status: AppPebbleStatus.home,
        admin: false,
        you: true,
        scale: 1.15,
      );
      expect(small, const Size.square(72));
    });

    testWidgets('the initials stay clear of the ring band at every size and '
        'scale', (tester) async {
      for (final size in AppPebbleSize.values) {
        for (final initials in worstInitials) {
          for (final scale in scales) {
            for (final status in [
              AppPebbleStatus.home,
              AppPebbleStatus.invited,
            ]) {
              await pumpPebble(
                tester,
                size: size,
                initials: initials,
                status: status,
                admin: true,
                you: true,
                scale: scale,
              );

              final pebble = tester.getRect(find.byType(AppPebble));
              final text = tester.getRect(_initials);
              // The ring band of a filled pebble: 2 px inset plus 2 px stroke.
              final inside = pebble.deflate(AppSizes.borderEmphasis * 2);
              final reason =
                  '${status.name} ${size.name} "$initials" ${scale}x';
              expect(
                inside.left,
                lessThanOrEqualTo(text.left + 0.01),
                reason: reason,
              );
              expect(
                text.right,
                lessThanOrEqualTo(inside.right + 0.01),
                reason: reason,
              );
              expect(
                inside.top,
                lessThanOrEqualTo(text.top + 0.01),
                reason: reason,
              );
              expect(
                text.bottom,
                lessThanOrEqualTo(inside.bottom + 0.01),
                reason: reason,
              );
            }
          }
        }
      }
    });

    testWidgets('from s44 up the text line stays clear of each badge at every '
        'scale, with away alone, admin alone and both', (tester) async {
      for (final size in AppPebbleSize.values.where((s) => s.hasBadges)) {
        for (final (name, status, admin) in const [
          ('away', AppPebbleStatus.away, false),
          ('admin', AppPebbleStatus.home, true),
          ('away + admin', AppPebbleStatus.away, true),
        ]) {
          for (final initials in worstInitials) {
            for (final scale in scales) {
              await pumpPebble(
                tester,
                size: size,
                initials: initials,
                status: status,
                admin: admin,
                you: true,
                scale: scale,
              );

              final text = tester.getRect(_initials);
              final reason = '$name ${size.name} "$initials" at ${scale}x';
              for (final badge in [
                if (status == AppPebbleStatus.away) _away,
                if (admin) _admin,
              ]) {
                expect(badge, findsOneWidget, reason: reason);
                final rect = tester.getRect(badge);
                expect(
                  text.overlaps(rect),
                  isFalse,
                  reason: '$reason: $text against the badge $rect',
                );
              }
            }
          }
        }
      }
    });

    testWidgets('pebbles of one size stay equal in every state at every '
        'scale', (tester) async {
      for (final size in AppPebbleSize.values) {
        for (final initials in ['A', 'MW']) {
          for (final scale in [1.0, 1.15, 1.5, 2.0]) {
            final sizes = <String, Size>{};
            for (final (name, status, admin, you) in [
              ...allStates,
              ('away + you', AppPebbleStatus.away, false, true),
            ]) {
              sizes[name] = await pumpPebble(
                tester,
                size: size,
                initials: initials,
                status: status,
                admin: admin,
                you: you,
                scale: scale,
              );
            }

            expect(
              sizes.values.toSet(),
              hasLength(1),
              reason: '${size.name} "$initials" at ${scale}x: $sizes',
            );
          }
        }
      }
    });

    testWidgets('one initial keeps the board size, two use the pair token', (
      tester,
    ) async {
      double fontSize(WidgetTester tester) =>
          tester.renderObject<RenderParagraph>(_initials).text.style!.fontSize!;

      for (final (size, one, two) in const [
        (AppPebbleSize.s28, 12.0, 10.0),
        (AppPebbleSize.s36, 14.0, 14.0),
        (AppPebbleSize.s44, 15.0, 15.0),
        (AppPebbleSize.s56, 20.0, 20.0),
        (AppPebbleSize.s72, 28.0, 28.0),
      ]) {
        await tester.pumpWidget(_host(_pebble(size: size)));
        expect(fontSize(tester), one, reason: '${size.name} one letter');
        await tester.pumpWidget(_host(_pebble(size: size, initials: 'MW')));
        expect(fontSize(tester), two, reason: '${size.name} two letters');
      }
    });

    testWidgets('a pair wider than MW grows the two smallest pebbles by a '
        'little, never more than 3 px, and fits from s44 up', (tester) async {
      for (final (size, pair) in [
        (AppPebbleSize.s28, 'WW'),
        (AppPebbleSize.s28, 'ÆW'),
        (AppPebbleSize.s36, 'WW'),
        (AppPebbleSize.s44, 'WW'),
        (AppPebbleSize.s56, 'WW'),
        (AppPebbleSize.s72, 'WW'),
      ]) {
        final grown = await pumpPebble(
          tester,
          size: size,
          initials: pair,
          status: AppPebbleStatus.home,
          admin: false,
          you: true,
        );

        if (size.side < AppSizes.pebbleMd) {
          expect(
            grown.width,
            greaterThan(size.side),
            reason: '${size.name} $pair',
          );
          expect(
            grown.width,
            lessThan(size.side + 3),
            reason: '${size.name} $pair',
          );
        } else {
          expect(grown, Size.square(size.side), reason: '${size.name} $pair');
        }
        expect(grown.width, grown.height);
      }
    });

    testWidgets('the ink of accents and descenders keeps the 4 px band clear '
        'on every size, at 1.0 and 2.0', (tester) async {
      for (final size in AppPebbleSize.values) {
        for (final initials in ['MÁ', 'ÑÁ', 'AÇ', 'Wg', 'Á', 'Ñ', 'j']) {
          for (final scale in [1.0, 2.0]) {
            await tester.pumpWidget(
              _host(
                _pebble(initials: initials, size: size),
                textScale: scale,
                boundary: true,
              ),
            );
            final ink = (await _inkGrid(tester)).bounds();
            final pebble = tester.getSize(find.byType(AppPebble));
            // The padding is AppSpacing.xs, which is also the width of the
            // ring band (2 px inset plus 2 px of stroke), and the faintest
            // anti-aliased pixel counts: no tolerance.
            const clear = AppSpacing.xs;
            final reason = '${size.name} "$initials" at ${scale}x: $ink';

            expect(ink, isNotNull, reason: reason);
            expect(ink!.left, greaterThanOrEqualTo(clear), reason: reason);
            expect(ink.top, greaterThanOrEqualTo(clear), reason: reason);
            expect(
              ink.right,
              lessThanOrEqualTo(pebble.width - clear),
              reason: reason,
            );
            expect(
              ink.bottom,
              lessThanOrEqualTo(pebble.height - clear),
              reason: reason,
            );

            // The ring does not change the side.
            await tester.pumpWidget(
              _host(
                _pebble(initials: initials, size: size, isYou: true),
                textScale: scale,
              ),
            );
            expect(
              tester.getSize(find.byType(AppPebble)),
              pebble,
              reason: reason,
            );
          }
        }
      }
    });

    // The ink of the same letters with an accent or a descender turned into a
    // plain capital (or the round "o"): what the capitals fill. The advances of
    // "g" and "o" differ by a fraction of a pixel, so the horizontal edge of a
    // capital box next to a "g" can be off by that much; the tests use the
    // vertical extent and capitals whose substitute has the same advance.
    String capitalsOf(String initials) => initials
        .replaceAll('Á', 'A')
        .replaceAll('Ñ', 'N')
        .replaceAll('Ç', 'C')
        .replaceAll('g', 'o');

    Future<_InkGrid> inkOf(
      WidgetTester tester, {
      required AppPebbleSize size,
      required String initials,
      required double scale,
    }) async {
      await tester.pumpWidget(
        _host(
          _pebble(initials: initials, size: size),
          textScale: scale,
          boundary: true,
        ),
      );
      return await _inkGrid(tester);
    }

    /// The painted shapes of the two badges of an away and admin pebble, in
    /// the coordinates of the pebble: rounded squares, so the corner of the
    /// bounding box is empty.
    Future<Map<String, RRect>> badgeRects(
      WidgetTester tester, {
      required AppPebbleSize size,
      required String initials,
      required double scale,
    }) async {
      await pumpPebble(
        tester,
        size: size,
        initials: initials,
        status: AppPebbleStatus.away,
        admin: true,
        you: false,
        scale: scale,
      );
      final origin = tester.getTopLeft(find.byType(AppPebble));
      RRect shape(Finder badge) =>
          AppRadius.pebble(AppSizes.pebbleBadge)
              .toRRect(tester.getRect(badge).shift(-origin));
      return {'away': shape(_away), 'admin': shape(_admin)};
    }

    testWidgets('the capitals are never covered by a badge, on s44 up, at '
        'every scale from 1.0 to 2.0', (tester) async {
      for (final size in AppPebbleSize.values.where((s) => s.hasBadges)) {
        for (final initials in ['MW', 'WW', 'MÁ', 'AC', 'OC', 'GS']) {
          for (final scale in [1.0, 1.04, 1.1, 1.2, 1.5, 2.0]) {
            final capitals = await inkOf(
              tester,
              size: size,
              initials: capitalsOf(initials),
              scale: scale,
            );
            final badges = await badgeRects(
              tester,
              size: size,
              initials: initials,
              scale: scale,
            );

            for (final MapEntry(key: name, value: rect) in badges.entries) {
              expect(
                capitals.touches(rect),
                isFalse,
                reason:
                    '${size.name} "$initials" at ${scale}x: the capitals '
                    '${capitals.bounds()} touch the $name badge $rect',
              );
            }
          }
        }
      }
    });

    testWidgets('accepted: on s44 a badge may cover the tip of an accent or a '
        'descender, but never the capitals', (tester) async {
      for (final (initials, badge) in [
        ('MÁ', 'admin'),
        ('ÑÁ', 'admin'),
        ('Wg', 'away'),
      ]) {
        final full = await inkOf(
          tester,
          size: AppPebbleSize.s44,
          initials: initials,
          scale: 1,
        );
        final capitals = await inkOf(
          tester,
          size: AppPebbleSize.s44,
          initials: capitalsOf(initials),
          scale: 1,
        );
        final rect = (await badgeRects(
          tester,
          size: AppPebbleSize.s44,
          initials: initials,
          scale: 1,
        ))[badge]!;

        // The accent's or the descender's own pixels, not the whole ink.
        final extra = full.minus(capitals);
        expect(
          extra.touches(rect, threshold: 0.5),
          isTrue,
          reason:
              '"$initials": the accent or descender reaches the $badge badge',
        );
        expect(
          capitals.touches(rect),
          isFalse,
          reason: '"$initials": the capitals do not',
        );
      }
    });

    testWidgets('a decomposed accent is one initial', (tester) async {
      double fontSize(WidgetTester tester) =>
          tester.renderObject<RenderParagraph>(_initials).text.style!.fontSize!;

      // "A" and a combining acute is two code units and one letter: it keeps
      // the board size on s28, where two letters would use the pair token.
      await tester.pumpWidget(
        _host(_pebble(initials: 'A\u0301', size: AppPebbleSize.s28)),
      );
      expect('A\u0301'.length, 2);
      expect(fontSize(tester), 12);
      await tester.pumpWidget(
        _host(_pebble(initials: 'AB', size: AppPebbleSize.s28)),
      );
      expect(fontSize(tester), 10);
    });
  });
}

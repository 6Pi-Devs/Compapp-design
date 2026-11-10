import 'dart:math' as math;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

const _group = 'Your presence';

PresenceSwitch _switch({
  Presence value = Presence.home,
  ValueChanged<Presence>? onChanged,
  String home = 'Home',
  String away = 'Out',
  String label = _group,
}) => PresenceSwitch(
  value: value,
  onChanged: onChanged ?? (_) {},
  homeLabel: home,
  awayLabel: away,
  semanticLabel: label,
);

Finder get _track => find.byKey(const Key('presence.switch'));
Finder get _home => find.byKey(const Key('presence.switch.home'));
Finder get _away => find.byKey(const Key('presence.switch.away'));

Finder _icon(Finder side) =>
    find.descendant(of: side, matching: find.byType(AppIcon));

/// A point inside a side that is neither its label nor its glyph: the left
/// padding of the side, one pixel in from its edge.
Offset _fillProbe(WidgetTester tester, Finder side) {
  final box = tester.getRect(find.byKey(hostBoundaryKey));
  final rect = tester.getRect(side);
  return Offset(rect.left + 3 - box.left, rect.center.dy - box.top);
}

/// Shows [child] with animations off, as the system setting does.
Widget _frozen(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows both labels with the sun and the moon', (tester) async {
      await tester.pumpWidget(host(_switch()));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Out'), findsOneWidget);
      expect(tester.widget<AppIcon>(_icon(_home)).icon, AppIcons.home);
      expect(tester.widget<AppIcon>(_icon(_away)).icon, AppIcons.away);
      expect(tester.widget<AppIcon>(_icon(_home)).size, AppSizes.glyphLg);
    });

    testWidgets('the track is 64 tall, fills the width and splits it into two '
        'equal sides', (tester) async {
      await tester.pumpWidget(host(_switch()));

      expect(tester.getSize(_track).width, hostWidth);
      expect(tester.getSize(_track).height, AppSizes.presenceControl);
      expect(tester.getSize(_home).width, tester.getSize(_away).width);
      expect(
        tester.getSize(_home).height,
        AppSizes.presenceControl - 2 * (AppSpacing.xs + AppSizes.hairline),
      );
      expect(
        tester.getRect(_away).left - tester.getRect(_home).right,
        AppSpacing.xs,
      );
    });

    testWidgets('each side is drawn at least 44 and hit at least 48', (
      tester,
    ) async {
      await tester.pumpWidget(host(_switch()));

      for (final side in [_home, _away]) {
        expect(tester.getSize(side).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(side).width, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(host(IntrinsicHeight(child: _switch())));

      expect(tester.takeException(), isNull);
    });

    testWidgets('needs a label on both sides and for the group', (
      tester,
    ) async {
      expect(() => _switch(home: ''), throwsAssertionError);
      expect(() => _switch(away: ''), throwsAssertionError);
      expect(() => _switch(label: ''), throwsAssertionError);
    });
  });

  group('choosing', () {
    testWidgets('tapping the other side calls onChanged with it, once', (
      tester,
    ) async {
      final calls = <Presence>[];
      await tester.pumpWidget(host(_switch(onChanged: calls.add)));

      await tester.tap(_away);
      await tester.pump();
      expect(calls, [Presence.away]);

      await tester.pumpWidget(
        host(_switch(value: Presence.away, onChanged: calls.add)),
      );
      await tester.tap(_home);
      await tester.pump();
      expect(calls, [Presence.away, Presence.home]);
    });

    testWidgets('tapping the selected side does nothing', (tester) async {
      final calls = <Presence>[];
      await tester.pumpWidget(host(_switch(onChanged: calls.add)));

      await tester.tap(_home);
      await tester.pump();
      await tester.tap(find.text('Home'));
      await tester.pump();

      expect(calls, isEmpty);
    });

    testWidgets('tapping the label or the glyph of a side chooses it', (
      tester,
    ) async {
      final calls = <Presence>[];
      await tester.pumpWidget(host(_switch(onChanged: calls.add)));

      await tester.tap(find.text('Out'));
      await tester.tap(_icon(_away));
      await tester.pump();

      expect(calls, [Presence.away, Presence.away]);
    });

    testWidgets('Tab visits the home side then the away side, and Enter and '
        'Space choose the unselected one', (tester) async {
      final calls = <Presence>[];
      await tester.pumpWidget(host(_switch(onChanged: calls.add)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, isEmpty, reason: 'the home side is already selected');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, [Presence.away, Presence.away]);
    });

    testWidgets('has two tab stops: the track and the glyphs are not '
        'focusable', (tester) async {
      await tester.pumpWidget(host(_switch()));

      final focusable = FocusManager.instance.rootScope.traversalDescendants
          .where(
            (node) =>
                node is! FocusScopeNode &&
                node.canRequestFocus &&
                !node.skipTraversal,
          );
      expect(focusable, hasLength(2));
    });

    testWidgets('a semantic tap chooses the other side', (tester) async {
      final handle = tester.ensureSemantics();
      final calls = <Presence>[];
      await tester.pumpWidget(host(_switch(onChanged: calls.add)));

      tester.semantics.tap(find.semantics.byLabel('Out'));
      await tester.pump();

      expect(calls, [Presence.away]);
      handle.dispose();
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      for (final direction in TextDirection.values) {
        testWidgets('the selected side is filled: primary at home, the away '
            'color away, and the other side shows the track, $direction '
            '($name)', (tester) async {
          for (final (value, selected, other, fill) in [
            (Presence.home, _home, _away, scheme.primary),
            (Presence.away, _away, _home, colors.presenceAway),
          ]) {
            await tester.pumpWidget(
              host(
                _switch(value: value),
                theme: theme,
                background: scheme.surface,
                direction: direction,
              ),
            );
            await tester.pumpAndSettle();

            expect(
              await paintedColorAt(
                tester,
                hostBoundaryKey,
                _fillProbe(tester, selected),
              ),
              isSameColorAs(fill),
              reason: '$value selected',
            );
            expect(
              await paintedColorAt(
                tester,
                hostBoundaryKey,
                _fillProbe(tester, other),
              ),
              isSameColorAs(scheme.surfaceContainerHigh),
              reason: '$value: the other side has no fill',
            );
            expect(
              tester.getRect(selected).center.dx <
                  tester.getRect(other).center.dx,
              (value == Presence.home) == (direction == TextDirection.ltr),
              reason: '$value: home is at the start',
            );
          }
        });
      }

      testWidgets('the track has an outline border ($name)', (tester) async {
        await tester.pumpWidget(
          host(_switch(), theme: theme, background: scheme.surface),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final track = tester.getRect(_track);

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(track.center.dx - box.left, track.top - box.top),
          ),
          isSameColorAs(scheme.outline),
        );
      });

      testWidgets('labels and glyphs follow the fill: on-color on the '
          'selected side, muted ink on the other ($name)', (tester) async {
        for (final (value, selected, other, onFill) in [
          (Presence.home, _home, _away, scheme.onPrimary),
          (Presence.away, _away, _home, colors.onPresenceAway),
        ]) {
          await tester.pumpWidget(
            host(
              _switch(value: value),
              theme: theme,
              background: scheme.surface,
            ),
          );
          await tester.pumpAndSettle();
          final box = tester.getRect(find.byKey(hostBoundaryKey));

          for (final (side, color) in [
            (selected, onFill),
            (other, scheme.onSurfaceVariant),
          ]) {
            final label = value == Presence.home
                ? (side == selected ? 'Home' : 'Out')
                : (side == selected ? 'Out' : 'Home');
            expect(
              await paintedColorAtCenter(
                tester,
                hostBoundaryKey,
                find.text(label),
              ),
              isSameColorAs(color),
              reason: '$value: label $label',
            );
            expect(
              countPixels(
                await paintedPixels(
                  tester,
                  hostBoundaryKey,
                  region: tester.getRect(_icon(side)).shift(-box.topLeft),
                ),
                color,
              ),
              greaterThan(10),
              reason: '$value: glyph of $label',
            );
          }
        }
      });

      testWidgets('is calm: no danger color is drawn ($name)', (tester) async {
        for (final value in Presence.values) {
          await tester.pumpWidget(
            host(
              _switch(value: value),
              theme: theme,
              background: scheme.surface,
            ),
          );
          await tester.pumpAndSettle();
          final pixels = await paintedPixels(tester, hostBoundaryKey);

          expect(countPixels(pixels, scheme.error), 0);
          expect(countPixels(pixels, scheme.errorContainer), 0);
        }
      });

      testWidgets('keyboard focus draws a 2 px ink ring outside the side '
          '($name)', (tester) async {
        await tester.pumpWidget(
          host(_switch(), theme: theme, background: scheme.surface),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final away = tester.getRect(_away);
        final probe = Offset(away.center.dx - box.left, away.top - box.top - 1);
        expect(
          await paintedColorAt(tester, hostBoundaryKey, probe),
          isSameColorAs(scheme.surfaceContainerHigh),
          reason: 'no ring before focus',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.pump(AppMotion.presence);

        expect(
          await paintedColorAt(tester, hostBoundaryKey, probe),
          isSameColorAs(scheme.onSurface),
        );
      });
    }
  });

  group('motion', () {
    Future<Color> fill(WidgetTester tester, Finder side) =>
        paintedColorAt(tester, hostBoundaryKey, _fillProbe(tester, side));

    Rect inBoundary(WidgetTester tester, Rect rect) =>
        rect.shift(-tester.getTopLeft(find.byKey(hostBoundaryKey)));

    /// The rows of pixels painted in [region], whole pixels, top to bottom.
    Future<List<List<Color>>> rows(WidgetTester tester, Rect region) async {
      final left = region.left.floor();
      final right = region.right.ceil();
      final top = region.top.floor();
      final bottom = region.bottom.ceil();
      final flat = await paintedPixels(
        tester,
        hostBoundaryKey,
        region: Rect.fromLTRB(
          left.toDouble(),
          top.toDouble(),
          right.toDouble(),
          bottom.toDouble(),
        ),
      );
      final width = right - left;
      return [
        for (var y = 0; y < bottom - top; y++)
          flat.sublist(y * width, (y + 1) * width),
      ];
    }

    /// What one frame of the slide shows.
    ///
    /// Every pixel of a label or a glyph is read against the background right
    /// beside it, in the same row of the face when the sides are stacked (the
    /// thumb edge is then a horizontal line) and in the same column otherwise.
    /// A pixel is the ink, the background or a blend of the two (the edge of a
    /// stroke); a color that is none of them is a blend of the two inks or of
    /// anything else, and only the seam where the two drawings meet, one or two
    /// lines of pixels at most, may have it. Every pixel that is all ink, up to
    /// a rounding, is held to the contrast of its kind.
    Future<({double label, double glyph, bool split, int scored})> readFrame(
      WidgetTester tester,
      ThemeData theme, {
      required bool stacked,
      required String homeText,
      required String awayText,
    }) async {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;
      var label = double.infinity;
      var glyph = double.infinity;
      var split = false;
      var scored = 0;

      /// Reads the pixels of [rect] (a drawn thing) and returns the least
      /// contrast of its near-solid ink pixels, or null when it has none.
      Future<double?> score(
        Rect rect,
        List<Color> inks, {
        required String what,
        required bool onlyMiddle,
      }) async {
        const margin = 3;
        final grid = await rows(
          tester,
          Rect.fromLTRB(
            rect.left - margin,
            rect.top - margin,
            rect.right,
            rect.bottom,
          ),
        );
        final height = grid.length;
        final width = grid.first.length;
        final firstRow = onlyMiddle ? (height / 2).round() - 5 : margin;
        final lastRow = onlyMiddle ? (height / 2).round() + 5 : height;

        // The seam is where the background itself changes, from the track to
        // the thumb: read it from the background beside the drawing, and give
        // it one line of pixels on each side for the anti-aliasing.
        final backgrounds = stacked
            ? [for (final row in grid) row[0]]
            : grid.first;
        final seam = <int>{};
        for (var i = 1; i < backgrounds.length; i++) {
          if (_distance(backgrounds[i], backgrounds[i - 1]) > 0.02) {
            seam.addAll([i - 2, i - 1, i, i + 1]);
          }
        }
        expect(
          seam.length,
          lessThanOrEqualTo(8),
          reason: '$what: the track and the thumb meet in two lines at most',
        );

        double? least;
        for (var r = firstRow; r < lastRow; r++) {
          for (var c = margin + 2; c < width - 2; c++) {
            if (seam.contains(stacked ? r : c)) continue;
            final pixel = grid[r][c];
            final background = stacked ? grid[r][0] : grid[0][c];
            final isPure = _nearAny(pixel, [background, ...inks], 0.05);
            final isEdge = inks.any(
              (ink) => _distanceToSegment(pixel, background, ink) < 0.05,
            );
            expect(
              isPure || isEdge,
              isTrue,
              reason:
                  '$what: a color that is neither ink, background nor a '
                  'blend of the two, outside the seam: $pixel',
            );
            for (final ink in inks) {
              if (_distance(pixel, background) > 0.1 &&
                  _coverage(pixel, background, ink) >= 0.98 &&
                  _distanceToSegment(pixel, background, ink) < 0.05) {
                final ratio = contrastRatio(pixel, background);
                least = least == null ? ratio : math.min(least, ratio);
              }
            }
          }
        }
        return least;
      }

      for (final (text, side, onFill, which) in [
        (homeText, _home, scheme.onPrimary, 'home'),
        (awayText, _away, colors.onPresenceAway, 'away'),
      ]) {
        final inks = [scheme.onSurfaceVariant, onFill];
        final textRect = inBoundary(
          tester,
          tester.getRect(find.text(text).first),
        );
        final iconRect = inBoundary(tester, tester.getRect(_icon(side)));

        // The test font draws a solid square as tall as the font size in the
        // middle of the line: the rows around the middle are all ink.
        final ofLabel = await score(
          textRect,
          inks,
          what: '$which label',
          onlyMiddle: true,
        );
        final ofGlyph = await score(
          iconRect,
          inks,
          what: '$which glyph',
          onlyMiddle: false,
        );
        // A drawing that sits on the seam in this frame has no pixel left to
        // score; most frames have one, which the test checks.
        if (ofLabel != null) label = math.min(label, ofLabel);
        if (ofGlyph != null) glyph = math.min(glyph, ofGlyph);
        scored += (ofLabel != null ? 1 : 0) + (ofGlyph != null ? 1 : 0);

        final labelRows = await rows(tester, textRect);
        final middle = (labelRows.length / 2).round();
        final flat = [
          for (final row in labelRows.sublist(middle - 5, middle + 5)) ...row,
        ];
        split =
            split ||
            (countPixels(flat, inks.first) > 0 &&
                countPixels(flat, onFill) > 0);
      }
      return (label: label, glyph: glyph, split: split, scored: scored);
    }

    for (final (name, theme) in themes) {
      for (final (scene, direction, scale, homeText, awayText, stacked)
          in <(String, TextDirection, double, String, String, bool)>[
            ('side by side', TextDirection.ltr, 1, 'Home', 'Out', false),
            (
              'side by side, right to left',
              TextDirection.rtl,
              1,
              'Home',
              'Out',
              false,
            ),
            ('stacked', TextDirection.ltr, 2, 'Casa', 'Fuera', true),
            (
              'stacked, right to left',
              TextDirection.rtl,
              2,
              'Disponible',
              'Fuera',
              true,
            ),
          ]) {
        for (final toAway in [true, false]) {
          final way = toAway ? 'home to away' : 'away to home';
          testWidgets('every label and glyph reads on every frame of the '
              'thumb sliding from $way, $scene ($name)', (tester) async {
            final scheme = theme.colorScheme;
            Widget at(Presence value) => host(
              _switch(value: value, home: homeText, away: awayText),
              theme: theme,
              background: scheme.surface,
              direction: direction,
              textScale: scale,
            );
            await tester.pumpWidget(at(toAway ? Presence.home : Presence.away));
            await tester.pumpAndSettle();
            await tester.pumpWidget(at(toAway ? Presence.away : Presence.home));
            if (stacked) {
              expect(
                tester.getRect(_away).top,
                greaterThanOrEqualTo(tester.getRect(_home).bottom),
                reason: 'the scene is stacked',
              );
            } else {
              expect(tester.getRect(_home).top, tester.getRect(_away).top);
            }

            var label = double.infinity;
            var glyph = double.infinity;
            var split = false;
            var frames = 0;
            var scored = 0;
            for (var elapsed = 0; elapsed <= 700; elapsed += 16) {
              await tester.pump(
                elapsed == 0 ? Duration.zero : const Duration(milliseconds: 16),
              );
              // The second drawings sit exactly where the button draws.
              final moving = find.text(homeText).evaluate().length == 3;
              if (moving) {
                for (final copies in [
                  find.text(homeText),
                  find.text(awayText),
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is AppIcon && widget.icon == AppIcons.home,
                  ),
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is AppIcon && widget.icon == AppIcons.away,
                  ),
                ]) {
                  expect(copies, findsNWidgets(3));
                  for (var i = 1; i < 3; i++) {
                    expect(
                      tester.getRect(copies.at(i)),
                      tester.getRect(copies.first),
                      reason: 'frame $frames: drawing $i is not on its button',
                    );
                  }
                }
              }
              final frame = await readFrame(
                tester,
                theme,
                stacked: stacked,
                homeText: homeText,
                awayText: awayText,
              );
              label = math.min(label, frame.label);
              glyph = math.min(glyph, frame.glyph);
              split = split || frame.split;
              scored += frame.scored;
              frames++;
            }

            expect(
              label,
              greaterThanOrEqualTo(4.5),
              reason:
                  'text, every frame ($frames frames, least '
                  '${label.toStringAsFixed(2)})',
            );
            expect(
              glyph,
              greaterThanOrEqualTo(3),
              reason:
                  'glyph, every frame ($frames frames, least '
                  '${glyph.toStringAsFixed(2)})',
            );
            expect(split, isTrue, reason: 'the thumb edge split a label');
            expect(
              scored,
              greaterThan(frames * 4 * 0.75),
              reason: 'most drawings have pixels to score in most frames',
            );
            expect(tester.hasRunningAnimations, isFalse);
          });
        }
      }
    }

    testWidgets('the thumb slides over motion.presence: it is under the old '
        'side at the start and between the sides halfway', (tester) async {
      final scheme = CompappTheme.light.colorScheme;
      await tester.pumpWidget(host(_switch(), background: scheme.surface));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        host(_switch(value: Presence.away), background: scheme.surface),
      );
      await tester.pump();
      expect(await fill(tester, _home), isSameColorAs(scheme.primary));

      await tester.pump(AppMotion.presence ~/ 2);
      final box = tester.getRect(find.byKey(hostBoundaryKey));
      final middle = Offset(
        (tester.getRect(_home).right + tester.getRect(_away).left) / 2 -
            box.left,
        tester.getRect(_home).center.dy - box.top,
      );
      expect(
        await paintedColorAt(tester, hostBoundaryKey, middle),
        isNot(isSameColorAs(scheme.surfaceContainerHigh)),
        reason: 'the thumb is over the gap between the sides',
      );

      await tester.pump(AppMotion.presence);
      expect(
        await fill(tester, _home),
        isSameColorAs(scheme.surfaceContainerHigh),
      );
      expect(
        await fill(tester, _away),
        isSameColorAs(CompappTheme.light.extension<AppColors>()!.presenceAway),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('each side is drawn once at rest and the second drawing only '
        'exists while the thumb slides', (tester) async {
      await tester.pumpWidget(host(_switch()));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Out'), findsOneWidget);

      await tester.pumpWidget(host(_switch(value: Presence.away)));
      await tester.pump(AppMotion.presence ~/ 2);
      expect(find.text('Home'), findsNWidgets(3));
      expect(find.text('Out'), findsNWidgets(3));

      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Out'), findsOneWidget);
    });

    testWidgets('the second drawing adds nothing for assistive technology '
        'and takes no tap or focus', (tester) async {
      final handle = tester.ensureSemantics();
      final calls = <Presence>[];
      await tester.pumpWidget(host(_switch(onChanged: calls.add)));
      await tester.pumpWidget(
        host(_switch(value: Presence.away, onChanged: calls.add)),
      );
      await tester.pump(AppMotion.presence ~/ 2);

      expect(semanticsLabels(tester), [_group, 'Home', 'Out']);
      final focusable = FocusManager.instance.rootScope.traversalDescendants
          .where(
            (node) =>
                node is! FocusScopeNode &&
                node.canRequestFocus &&
                !node.skipTraversal,
          );
      expect(focusable, hasLength(2));
      await tester.tapAt(tester.getCenter(_home));
      await tester.pump();
      expect(calls, [Presence.home]);
      handle.dispose();
    });

    testWidgets('the thumb jumps when animations are off: no second drawing '
        'at all', (tester) async {
      final scheme = CompappTheme.light.colorScheme;
      await tester.pumpWidget(
        host(_frozen(_switch()), background: scheme.surface),
      );
      await tester.pumpWidget(
        host(
          _frozen(_switch(value: Presence.away)),
          background: scheme.surface,
        ),
      );
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(
        await fill(tester, _home),
        isSameColorAs(scheme.surfaceContainerHigh),
      );
      expect(
        await fill(tester, _away),
        isSameColorAs(CompappTheme.light.extension<AppColors>()!.presenceAway),
      );
    });

    testWidgets('the labels do not change with the text style around the '
        'switch, at rest or mid-slide', (tester) async {
      Widget switchAt(Presence value, {required bool around}) => host(
        around
            ? DefaultTextStyle(
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline,
                  fontSize: 31,
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                child: _switch(
                  value: value,
                  home: 'Estoy en casa y disponible',
                  away: 'Estoy fuera de casa',
                ),
              )
            : _switch(
                value: value,
                home: 'Estoy en casa y disponible',
                away: 'Estoy fuera de casa',
              ),
        textScale: 1.5,
      );
      const homeText = 'Estoy en casa y disponible';

      await tester.pumpWidget(switchAt(Presence.home, around: false));
      final plain = tester.getRect(find.text(homeText));
      await tester.pumpWidget(switchAt(Presence.home, around: true));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text(homeText)), plain);

      await tester.pumpWidget(switchAt(Presence.away, around: true));
      await tester.pump(AppMotion.presence ~/ 2);

      final copies = find.text(homeText);
      expect(copies, findsNWidgets(3), reason: 'the button and two drawings');
      for (var i = 0; i < 3; i++) {
        final paragraph = tester.renderObject<RenderParagraph>(copies.at(i));
        final style = (paragraph.text as TextSpan).style!;
        expect(paragraph.maxLines, isNull, reason: 'copy $i');
        expect(paragraph.softWrap, isTrue, reason: 'copy $i');
        expect(paragraph.overflow, TextOverflow.clip, reason: 'copy $i');
        expect(style.fontStyle, isNot(FontStyle.italic), reason: 'copy $i');
        expect(
          style.decoration ?? TextDecoration.none,
          TextDecoration.none,
          reason: 'copy $i',
        );
        expect(
          style.fontSize,
          AppTypography.labelLg.fontSize,
          reason: 'copy $i',
        );
        expect(
          tester.getRect(copies.at(i)),
          tester.getRect(copies.first),
          reason: 'copy $i is laid out like the button',
        );
      }
    });

    testWidgets('the thumb slides in the reading direction in right to left '
        'too, and down when the sides stack', (tester) async {
      final scheme = CompappTheme.light.colorScheme;
      await tester.pumpWidget(
        host(
          _switch(),
          direction: TextDirection.rtl,
          background: scheme.surface,
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        host(
          _switch(value: Presence.away),
          direction: TextDirection.rtl,
          background: scheme.surface,
        ),
      );
      await tester.pump(AppMotion.presence ~/ 2);
      final box = tester.getRect(find.byKey(hostBoundaryKey));
      final middle = Offset(
        (tester.getRect(_home).left + tester.getRect(_away).right) / 2 -
            box.left,
        tester.getRect(_home).center.dy - box.top,
      );
      expect(
        await paintedColorAt(tester, hostBoundaryKey, middle),
        isNot(isSameColorAs(scheme.surfaceContainerHigh)),
        reason: 'right to left: the thumb is over the gap too',
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        host(
          _switch(home: 'Estoy en casa y disponible', away: 'Estoy fuera'),
          textScale: 2,
          background: scheme.surface,
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        host(
          _switch(
            value: Presence.away,
            home: 'Estoy en casa y disponible',
            away: 'Estoy fuera',
          ),
          textScale: 2,
          background: scheme.surface,
        ),
      );
      await tester.pump(AppMotion.presence ~/ 2);
      final stackedBox = tester.getRect(find.byKey(hostBoundaryKey));
      final between = Offset(
        tester.getRect(_home).center.dx - stackedBox.left,
        (tester.getRect(_home).bottom + tester.getRect(_away).top) / 2 -
            stackedBox.top,
      );
      expect(
        await paintedColorAt(tester, hostBoundaryKey, between),
        isNot(isSameColorAs(scheme.surfaceContainerHigh)),
        reason: 'stacked: the thumb is over the gap between the rows',
      );
    });
  });

  group('intrinsic sizes', () {
    setUpAll(loadBundledFonts);

    const home = 'Estoy en casa y disponible';
    const away = 'Estoy fuera de casa';
    // The track around the pair: the inset and the hairline on both sides.
    const around = 2 * (AppSpacing.xs + AppSizes.hairline);

    Finder pair() => find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ThumbPair',
    );

    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final width in [200.0, 260.0, 320.0, 400.0]) {
        testWidgets('the pair answers its sizes as it lays out, at $width '
            'wide and ${scale}x', (tester) async {
          await tester.pumpWidget(
            host(
              _switch(home: home, away: away),
              width: width,
              textScale: scale,
            ),
          );
          final box = tester.renderObject<RenderBox>(pair());

          expect(box.getMinIntrinsicHeight(box.size.width), box.size.height);
          expect(box.getMaxIntrinsicHeight(box.size.width), box.size.height);
          expect(box.getDryLayout(box.constraints), box.size);
          expect(
            box.getDryLayout(BoxConstraints(maxWidth: box.size.width)),
            box.size,
          );
        });
      }
    }

    testWidgets('at its largest intrinsic width the sides are side by side', (
      tester,
    ) async {
      await tester.pumpWidget(host(_switch(home: home, away: away)));
      final widest = tester
          .renderObject<RenderBox>(pair())
          .getMaxIntrinsicWidth(double.infinity);

      await tester.pumpWidget(
        host(
          _switch(home: home, away: away),
          width: widest + around,
        ),
      );

      expect(tester.getRect(_home).top, tester.getRect(_away).top);
      expect(tester.getRect(_home).right, lessThan(tester.getRect(_away).left));
      expect(
        tester.getSize(_home).width,
        greaterThanOrEqualTo(
          tester
              .renderObject<RenderBox>(_home)
              .getMinIntrinsicWidth(double.infinity),
        ),
      );
    });

    testWidgets('its largest intrinsic width is enough for nothing to wrap: '
        'more room does not make it shorter', (tester) async {
      await tester.pumpWidget(host(_switch(home: home, away: away)));
      final widest = tester
          .renderObject<RenderBox>(pair())
          .getMaxIntrinsicWidth(double.infinity);

      await tester.pumpWidget(
        host(
          _switch(home: home, away: away),
          width: widest + around,
        ),
      );
      final snug = tester.getSize(_track).height;
      await tester.pumpWidget(
        host(
          _switch(home: home, away: away),
          width: widest + around + 200,
        ),
      );

      expect(tester.getSize(_track).height, snug);
      expect(snug, AppSizes.presenceControl, reason: 'one line each');
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('at its least intrinsic width no word is cut, at '
          '${scale}x', (tester) async {
        await tester.pumpWidget(
          host(
            _switch(home: home, away: away),
            textScale: scale,
          ),
        );
        final least = tester
            .renderObject<RenderBox>(pair())
            .getMinIntrinsicWidth(double.infinity);

        await tester.pumpWidget(
          host(
            _switch(home: home, away: away),
            width: least + around,
            textScale: scale,
          ),
        );

        expect(tester.takeException(), isNull);
        expectNoMidWordBreaks(tester, find.text(home));
        expectNoMidWordBreaks(tester, find.text(away));
        expect(
          tester.getRect(_away).top,
          greaterThanOrEqualTo(tester.getRect(_home).bottom),
          reason: 'stacked, each as wide as the longest word needs',
        );
      });
    }
  });

  group('right to left', () {
    testWidgets('the home side is at the start, the right', (tester) async {
      await tester.pumpWidget(host(_switch(), direction: TextDirection.rtl));

      expect(
        tester.getRect(_home).center.dx,
        greaterThan(tester.getRect(_away).center.dx),
      );
    });

    testWidgets('the track keeps the same inset on both sides', (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(host(_switch(), direction: direction));
        final track = tester.getRect(_track);
        final first = direction == TextDirection.ltr
            ? tester.getRect(_home)
            : tester.getRect(_away);
        final last = direction == TextDirection.ltr
            ? tester.getRect(_away)
            : tester.getRect(_home);

        const inset = AppSpacing.xs + AppSizes.hairline;
        expect(first.left - track.left, inset, reason: '$direction');
        expect(track.right - last.right, inset, reason: '$direction');
      }
    });

    testWidgets('the glyph stays before its label in reading order', (
      tester,
    ) async {
      await tester.pumpWidget(host(_switch(), direction: TextDirection.rtl));

      expect(
        tester.getRect(_icon(_home)).center.dx,
        greaterThan(tester.getRect(find.text('Home')).center.dx),
      );
    });
  });

  group('semantics', () {
    testWidgets('is a labeled group of two toggle buttons, one checked, and '
        'nothing is said twice', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_switch()));

      expect(tester.getSemantics(_track).getSemanticsData().label, _group);
      expect(
        tester.getSemantics(_track).getSemanticsData().role,
        SemanticsRole.radioGroup,
      );
      expect(
        tester.getSemantics(_home),
        isSemantics(
          label: 'Home',
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(_away),
        isSemantics(
          label: 'Out',
          isButton: true,
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(semanticsLabels(tester), [_group, 'Home', 'Out']);
      handle.dispose();
    });

    testWidgets('the checked side follows the value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_switch(value: Presence.away)));

      expect(
        tester.getSemantics(_home),
        isSemantics(
          label: 'Home',
          isButton: true,
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(_away),
        isSemantics(
          label: 'Out',
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    for (final (name, wrap) in <(String, Widget Function(Widget))>[
      (
        'a labeled container',
        (child) => Semantics(container: true, label: 'Panel', child: child),
      ),
      (
        'a list view',
        (child) => SizedBox(height: 200, child: ListView(children: [child])),
      ),
      ('a card', (child) => Card(child: child)),
    ]) {
      testWidgets('keeps its group and sides apart under $name', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(wrap(_switch())));

        expect(tester.getSemantics(_track).getSemanticsData().label, _group);
        expect(tester.getSemantics(_home).getSemanticsData().label, 'Home');
        expect(tester.getSemantics(_away).getSemanticsData().label, 'Out');
        expect(
          semanticsLabels(tester)
              .where((label) => const {_group, 'Home', 'Out'}.contains(label)),
          [_group, 'Home', 'Out'],
          reason: 'each said once, none merged into the parent',
        );
        handle.dispose();
      });
    }
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;
      final backgrounds = {
        'page': scheme.surface,
        'card': scheme.surfaceContainerLowest,
      };

      test('labels reach 4.5:1 on every fill ($name)', () {
        expectContrast(
          {
            'home selected': (scheme.onPrimary, scheme.primary),
            'away selected': (colors.onPresenceAway, colors.presenceAway),
            'unselected': (
              scheme.onSurfaceVariant,
              scheme.surfaceContainerHigh,
            ),
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('the selected fill, the track and the ring reach 3:1 ($name)', () {
        expectContrast(
          {
            'home fill/track': (scheme.primary, scheme.surfaceContainerHigh),
            'away fill/track': (
              colors.presenceAway,
              scheme.surfaceContainerHigh,
            ),
            for (final background in backgrounds.entries) ...{
              'track outline/${background.key}': (
                scheme.outline,
                background.value,
              ),
              'focus ring/${background.key}': (
                scheme.onSurface,
                background.value,
              ),
            },
            'focus ring/track': (scheme.onSurface, scheme.surfaceContainerHigh),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const home = 'Estoy en casa y disponible';
    const away = 'Estoy fuera de casa';

    testWidgets('both sides grow together at 1.3, 1.5 and 2.0, and no word '
        'is cut', (tester) async {
      for (final scale in [1.0, 1.3, 1.5, 2.0]) {
        await tester.pumpWidget(
          host(
            _switch(home: home, away: away),
            textScale: scale,
          ),
        );
        final reason = 'at ${scale}x';
        final track = tester.getRect(_track);
        final homeSide = tester.getRect(_home);
        final awaySide = tester.getRect(_away);

        expect(tester.takeException(), isNull, reason: reason);
        expect(track.height, greaterThanOrEqualTo(AppSizes.presenceControl));
        final stacked = awaySide.top >= homeSide.bottom;
        if (stacked) {
          expect(homeSide.width, awaySide.width, reason: reason);
          expect(homeSide.left, awaySide.left, reason: reason);
          expect(awaySide.top - homeSide.bottom, AppSpacing.xs);
          expect(homeSide.width, track.width - 2 * (AppSpacing.xs + 1));
        } else {
          expect(homeSide.height, awaySide.height, reason: reason);
          expect(homeSide.top, awaySide.top, reason: reason);
        }
        expect(
          stacked,
          scale == 2.0,
          reason: '$reason: side by side while the longest word fits a half',
        );
        for (final (label, side) in [(home, homeSide), (away, awaySide)]) {
          final text = tester.getRect(find.text(label));
          expect(text.left, greaterThanOrEqualTo(side.left), reason: reason);
          expect(text.right, lessThanOrEqualTo(side.right), reason: reason);
          expect(text.top, greaterThanOrEqualTo(side.top), reason: reason);
          expect(text.bottom, lessThanOrEqualTo(side.bottom), reason: reason);
          expectNoMidWordBreaks(tester, find.text(label), reason: reason);
        }
        expect(
          tester.getSize(_icon(_home)),
          const Size.square(AppSizes.glyphLg),
          reason: '$reason: the glyph keeps its size',
        );
        expect(track.bottom, greaterThanOrEqualTo(homeSide.bottom));
      }
    });

    testWidgets('the text is scaled, never clamped', (tester) async {
      await tester.pumpWidget(host(_switch(home: home, away: away)));
      final base = tester.getSize(find.text(home)).height;

      await tester.pumpWidget(
        host(_switch(home: home, away: away), textScale: 2),
      );

      expect(
        tester.getSize(find.text(home)).height,
        greaterThanOrEqualTo(base * 2 - 1),
      );
    });

    testWidgets('right to left wraps the same way at 2.0', (tester) async {
      await tester.pumpWidget(
        host(
          _switch(home: home, away: away),
          textScale: 2,
          direction: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getRect(_home).left, tester.getRect(_away).left);
      expect(
        tester.getRect(_away).top,
        greaterThanOrEqualTo(tester.getRect(_home).bottom),
        reason: 'stacked at 2.0, the home side first',
      );
      expectNoMidWordBreaks(tester, find.text(home));
      expectNoMidWordBreaks(tester, find.text(away));
    });
  });
}

/// Whether [pixel] is within [distance] of one of [targets], in the cube of
/// red, green and blue.
bool _nearAny(Color pixel, List<Color> targets, double distance) =>
    closestColorDistance(targets, pixel) < distance;

double _distance(Color a, Color b) => closestColorDistance([a], b);

/// How far [pixel] is from the segment from [from] to [to].
double _distanceToSegment(Color pixel, Color from, Color to) {
  final t = _coverage(pixel, from, to).clamp(0.0, 1.0);
  final nearest = Color.lerp(from, to, t)!;
  return _distance(pixel, nearest);
}

/// How much of the way from [from] to [to] [pixel] is, by projection.
double _coverage(Color pixel, Color from, Color to) {
  final dr = to.r - from.r;
  final dg = to.g - from.g;
  final db = to.b - from.b;
  final length = dr * dr + dg * dg + db * db;
  if (length == 0) return 0;
  return ((pixel.r - from.r) * dr +
          (pixel.g - from.g) * dg +
          (pixel.b - from.b) * db) /
      length;
}

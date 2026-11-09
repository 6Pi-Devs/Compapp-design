import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';

const _logLabel = 'Log Clean the kitchen again';

TaskRow _row({
  String id = 'kitchen',
  String title = 'Clean the kitchen',
  int ageDays = 3,
  String subtitle = 'Carlos · 3 days ago · Kitchen',
  String label = _logLabel,
  VoidCallback? onLogAgain,
}) => TaskRow(
  task: TaskView(id: id, title: title, ageDays: ageDays),
  subtitle: subtitle,
  logAgainSemanticLabel: label,
  onLogAgain: onLogAgain ?? () {},
);

Finder _key(String id) => find.byKey(Key('task.$id'));
Finder get _log => find.byKey(const Key('task.kitchen.logAgain'));
Finder get _bar => find.byType(AppFreshnessBar);

/// The drawn plate of the log button, without the invisible hit padding.
Rect _drawn(WidgetTester tester) => tester.getRect(
  find.descendant(of: _log, matching: find.byType(Material)).first,
);

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows the title, the subtitle and the freshness bar', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row()));

      expect(find.text('Clean the kitchen'), findsOneWidget);
      expect(find.text('Carlos · 3 days ago · Kitchen'), findsOneWidget);
      expect(_bar, findsOneWidget);
    });

    testWidgets('the bar shows the age the app counted, unchanged', (
      tester,
    ) async {
      for (final age in [-2, 0, 1, 2, 3, 6, 7, 400]) {
        await tester.pumpWidget(host(_row(ageDays: age)));

        expect(tester.widget<AppFreshnessBar>(_bar).ageDays, age);
        expect(tester.widget<AppFreshnessBar>(_bar).semanticLabel, isNull);
      }
    });

    testWidgets('the bar sits under the texts, as wide as their column', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row(title: 'Dishes', subtitle: 'Carlos')));

      final bar = tester.getRect(_bar);
      expect(
        bar.top,
        greaterThanOrEqualTo(tester.getRect(find.text('Carlos')).bottom),
      );
      expect(bar.height, AppSizes.freshnessBar);
      expect(bar.left, tester.getRect(find.text('Dishes')).left);
      expect(
        bar.right,
        tester.getRect(_log).left - AppSpacing.md,
        reason: 'the column takes what the button leaves',
      );
    });

    testWidgets('is at least 72 tall and fills the width it is given', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row(title: 'Dishes', subtitle: 'Carlos')));

      expect(tester.getSize(_key('kitchen')).width, hostWidth);
      expect(tester.getSize(_key('kitchen')).height, AppSizes.rowTall);
    });

    testWidgets('the keys are built from the task id', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _row(id: 'a'),
              _row(id: 'b'),
            ],
          ),
        ),
      );

      expect(_key('a'), findsOneWidget);
      expect(_key('b'), findsOneWidget);
      expect(find.byKey(const Key('task.a.logAgain')), findsOneWidget);
      expect(find.byKey(const Key('task.b.logAgain')), findsOneWidget);
    });

    testWidgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(host(IntrinsicHeight(child: _row())));

      expect(tester.takeException(), isNull);
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      testWidgets('title is ink and subtitle muted ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            _row(title: 'Kitchen', subtitle: 'Carlos'),
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
        );
        expect(
          await paintedColorAtCenter(
            tester,
            hostBoundaryKey,
            find.text('Carlos'),
          ),
          isSameColorAs(scheme.onSurfaceVariant),
        );
      });

      testWidgets('the bar is calm at every age: never a danger color '
          '($name)', (tester) async {
        for (final age in [0, 1, 3, 9, 60]) {
          await tester.pumpWidget(
            host(
              _row(ageDays: age),
              theme: theme,
              background: scheme.surface,
            ),
          );
          final bar = tester.getRect(_bar);
          final box = tester.getRect(find.byKey(hostBoundaryKey));
          final y = bar.center.dy - box.top;

          for (final x in [bar.left + 3, bar.right - 3]) {
            final pixel = await paintedColorAt(
              tester,
              hostBoundaryKey,
              Offset(x - box.left, y),
            );
            expect(pixel, isNot(isSameColorAs(scheme.error)), reason: '$age');
            expect(
              pixel,
              isNot(isSameColorAs(scheme.errorContainer)),
              reason: '$age',
            );
          }
        }
      });

      testWidgets('the bar fills the share of its age ($name)', (tester) async {
        await tester.pumpWidget(
          host(_row(), theme: theme, background: scheme.surface),
        );
        final bar = tester.getRect(_bar);
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final y = bar.center.dy - box.top;
        final left = bar.left - box.left;

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(left + bar.width * 0.6 - 4, y),
          ),
          isSameColorAs(scheme.primary),
          reason: 'three days is 60 percent',
        );
        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            Offset(left + bar.width * 0.6 + 4, y),
          ),
          isSameColorAs(scheme.surfaceContainerHigh),
        );
      });
    }
  });

  group('log button', () {
    testWidgets('is a 44 square plate with a 48 hit area and a plus', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row()));

      expect(_drawn(tester).size, const Size.square(AppSizes.minDrawn));
      expect(tester.getSize(_log).height, greaterThanOrEqualTo(48));
      final icon = tester.widget<AppIcon>(
        find.descendant(of: _log, matching: find.byType(AppIcon)),
      );
      expect(icon.icon, AppIcons.add);
      expect(icon.size, AppSizes.glyphLg);
      final shape =
          tester.widget<OutlinedButton>(_log).style!.shape!.resolve({})!
              as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.sm));
    });

    testWidgets('a tap calls onLogAgain once, a tap on the row does not', (
      tester,
    ) async {
      var logged = 0;
      await tester.pumpWidget(host(_row(onLogAgain: () => logged++)));

      await tester.tap(find.text('Clean the kitchen'));
      await tester.tap(_bar);
      await tester.pump();
      expect(logged, 0);

      await tester.tap(_log);
      await tester.pump();
      expect(logged, 1);
    });

    testWidgets('takes focus and Enter and Space activate it', (tester) async {
      var logged = 0;
      await tester.pumpWidget(host(_row(onLogAgain: () => logged++)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(logged, 2);
    });

    for (final (name, theme) in themes) {
      testWidgets('keyboard focus draws a 2 px ink ring outside ($name)', (
        tester,
      ) async {
        final scheme = theme.colorScheme;
        await tester.pumpWidget(
          host(
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _row(),
            ),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final drawn = _drawn(tester);
        final probe = Offset(
          drawn.left - box.left - 1,
          drawn.center.dy - box.top,
        );
        expect(
          await paintedColorAt(tester, hostBoundaryKey, probe),
          isSameColorAs(scheme.surface),
          reason: 'no ring before focus',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          await paintedColorAt(tester, hostBoundaryKey, probe),
          isSameColorAs(scheme.onSurface),
        );
      });
    }
  });

  group('right to left', () {
    testWidgets('the button is at the start (left) and the texts at the '
        'right', (tester) async {
      await tester.pumpWidget(host(_row(), direction: TextDirection.rtl));
      final row = tester.getRect(_key('kitchen'));

      expect(tester.getRect(_log).left, row.left);
      expect(tester.getRect(find.text('Clean the kitchen')).right, row.right);
      expect(tester.getRect(_bar).right, row.right);
    });

    testWidgets('the bar still fills from the start edge, the right', (
      tester,
    ) async {
      final scheme = CompappTheme.light.colorScheme;
      await tester.pumpWidget(
        host(_row(), direction: TextDirection.rtl, background: scheme.surface),
      );
      final bar = tester.getRect(_bar);
      final box = tester.getRect(find.byKey(hostBoundaryKey));
      final y = bar.center.dy - box.top;

      expect(
        await paintedColorAt(
          tester,
          hostBoundaryKey,
          Offset(bar.right - box.left - 4, y),
        ),
        isSameColorAs(scheme.primary),
      );
      expect(
        await paintedColorAt(
          tester,
          hostBoundaryKey,
          Offset(bar.left - box.left + 4, y),
        ),
        isSameColorAs(scheme.surfaceContainerHigh),
      );
    });
  });

  group('semantics', () {
    testWidgets('the texts are one node and the log control one button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_row()));

      expect(
        tester
            .getSemantics(find.text('Carlos · 3 days ago · Kitchen'))
            .getSemanticsData()
            .label,
        'Clean the kitchen\nCarlos · 3 days ago · Kitchen',
      );
      expect(
        tester.getSemantics(_log),
        isSemantics(
          label: _logLabel,
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(semanticsLabels(tester), [
        'Clean the kitchen\nCarlos · 3 days ago · Kitchen',
        _logLabel,
      ], reason: 'the bar and the plus add nothing');
      handle.dispose();
    });

    testWidgets('the text node is not a button and has no tap action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_row()));

      final data = tester
          .getSemantics(find.text('Clean the kitchen'))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('needs a spoken label for the log button', (tester) async {
      expect(() => _row(label: ''), throwsAssertionError);
    });

    testWidgets('a semantic tap on the log button calls onLogAgain', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var logged = 0;
      await tester.pumpWidget(host(_row(onLogAgain: () => logged++)));

      tester.semantics.tap(find.semantics.byLabel(_logLabel));
      await tester.pump();

      expect(logged, 1);
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final away = theme.extension<AppColors>()!.presenceAway;
      final backgrounds = {
        'page': scheme.surface,
        'card': scheme.surfaceContainerLowest,
      };

      test('text reaches 4.5:1 on the page and on a card ($name)', () {
        expectContrast(
          {
            for (final background in backgrounds.entries) ...{
              'title/${background.key}': (scheme.onSurface, background.value),
              'subtitle/${background.key}': (
                scheme.onSurfaceVariant,
                background.value,
              ),
            },
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('the bar, the plus and the button border reach 3:1 ($name)', () {
        expectContrast(
          {
            for (final background in backgrounds.entries) ...{
              'bar primary/${background.key}': (
                scheme.primary,
                background.value,
              ),
              'bar away/${background.key}': (away, background.value),
              'border/${background.key}': (scheme.outline, background.value),
            },
            'plus/button': (scheme.onSurface, scheme.surfaceContainerLowest),
            'bar primary/track': (scheme.primary, scheme.surfaceContainerHigh),
            'bar away/track': (away, scheme.surfaceContainerHigh),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const longTitle = 'Limpiar la cocina y el fregadero después de cenar';
    const longSubtitle = 'María de los Ángeles · hace tres días · Cocina';

    Widget longRow() => _row(
      title: longTitle,
      subtitle: longSubtitle,
      label: 'Registrar de nuevo: Limpiar la cocina',
    );

    testWidgets('wraps and grows at 1.5 and 2.0, the button keeps its size', (
      tester,
    ) async {
      await tester.pumpWidget(host(longRow()));
      final baseTitle = tester.getSize(find.text(longTitle));

      for (final scale in [1.5, 2.0]) {
        await tester.pumpWidget(host(longRow(), textScale: scale));
        final reason = 'at ${scale}x';
        final row = tester.getRect(_key('kitchen'));
        final title = tester.getRect(find.text(longTitle));
        final subtitle = tester.getRect(find.text(longSubtitle));
        final bar = tester.getRect(_bar);

        expect(tester.takeException(), isNull, reason: reason);
        expect(row.height, greaterThanOrEqualTo(AppSizes.rowTall));
        expect(
          title.height,
          greaterThanOrEqualTo(baseTitle.height * scale - 1),
          reason: '$reason: the text is scaled, never clamped',
        );
        expect(
          title.height,
          greaterThanOrEqualTo(2 * 22 * scale - 1),
          reason: '$reason: the long title wrapped over two lines or more',
        );
        expect(_drawn(tester).size, const Size.square(AppSizes.minDrawn));
        for (final (label, box) in [
          ('title', title),
          ('subtitle', subtitle),
          ('bar', bar),
        ]) {
          expect(
            box.right,
            lessThanOrEqualTo(tester.getRect(_log).left),
            reason: '$reason: $label stays clear of the button',
          );
          expect(box.left, greaterThanOrEqualTo(row.left), reason: reason);
        }
        expect(
          bar.top,
          greaterThanOrEqualTo(subtitle.bottom),
          reason: '$reason: the bar stays under the texts',
        );
        expect(bar.height, AppSizes.freshnessBar, reason: reason);
        expect(
          bar.bottom,
          lessThanOrEqualTo(row.bottom),
          reason: '$reason: nothing is cut below',
        );
      }
    });

    testWidgets('right to left wraps the same way', (tester) async {
      await tester.pumpWidget(
        host(longRow(), textScale: 2, direction: TextDirection.rtl),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text(longTitle)).left,
        greaterThanOrEqualTo(tester.getRect(_log).right),
      );
    });
  });
}

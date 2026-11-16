import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

const _label = 'Unread. Carlos finished your washer';

ActivityRow _row({
  String id = 'a1',
  AppIcons icon = AppIcons.washer,
  ActivityTone tone = ActivityTone.busy,
  String? actor = 'Carlos',
  String message = 'finished your washer',
  List<ActivityText>? runs,
  String? meta = 'Washer · 2 h ago',
  bool unread = true,
  String label = _label,
  VoidCallback? onTap,
}) => ActivityRow(
  entry: ActivityView(
    id: id,
    icon: icon,
    tone: tone,
    text:
        runs ??
        [
          if (actor != null && actor.isNotEmpty)
            ActivityText('$actor ', strong: true),
          ActivityText(message),
        ],
    meta: meta,
  ),
  unread: unread,
  semanticLabel: label,
  onTap: onTap ?? () {},
);

Finder _key(String id) => find.byKey(Key('activity.$id'));
Finder get _button => _key('a1');
Finder get _dot => find.byType(AppStatusDot);
Finder get _message => find.byWidgetPredicate(
  (widget) => widget is Text && widget.textSpan != null,
);

/// The drawn tile: the 40 square that holds the glyph.
Finder get _tile => find.ancestor(
  of: find.byType(AppIcon),
  matching: find.byType(DecoratedBox),
);

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows the actor in bold, the message and the meta line', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row()));

      final text = tester.widget<Text>(_message);
      expect(text.textSpan!.toPlainText(), 'Carlos finished your washer');
      final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.first.text, 'Carlos ');
      expect(spans.first.style!.fontWeight, FontWeight.w600);
      expect(spans.last.text, 'finished your washer');
      expect(spans.last.style, isNull, reason: 'the message is regular');
      expect(find.text('Washer · 2 h ago'), findsOneWidget);
    });

    testWidgets('the actor and the meta line are optional', (tester) async {
      await tester.pumpWidget(host(_row(actor: null, meta: null)));

      final text = tester.widget<Text>(_message);
      expect(text.textSpan!.toPlainText(), 'finished your washer');
      expect(find.byType(Text), findsOneWidget);

      await tester.pumpWidget(host(_row(actor: '', meta: '')));

      expect(
        tester.widget<Text>(_message).textSpan!.toPlainText(),
        'finished your washer',
      );
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('the tile shows the glyph of the entry at 18 in a 40 square', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row(icon: AppIcons.adminKey)));

      final icon = tester.widget<AppIcon>(find.byType(AppIcon));
      expect(icon.icon, AppIcons.adminKey);
      expect(icon.size, AppSizes.glyphLg);
      expect(tester.getSize(_tile.first), const Size.square(40));
    });

    testWidgets('an unread row has the dot at its end and a read one has '
        'none', (tester) async {
      await tester.pumpWidget(host(_row()));
      expect(tester.widget<AppStatusDot>(_dot).status, AppDotStatus.unread);
      final row = tester.getRect(_button);
      expect(
        tester.getRect(_dot).right,
        row.right - (AppSpacing.sm + AppSpacing.xs),
      );

      await tester.pumpWidget(host(_row(unread: false)));
      expect(_dot, findsNothing);
    });

    testWidgets('is at least 64 tall and fills the width it is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_row(actor: null, message: 'Hi', meta: null)),
      );

      expect(tester.getSize(_button).width, hostWidth);
      expect(tester.getSize(_button).height, AppSizes.row);
    });

    testWidgets('the tile sits 12 from the top and the bottom of a 64 row', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_row(actor: null, message: 'Hi', meta: 'Meta')),
      );
      final row = tester.getRect(_button);
      final tile = tester.getRect(_tile.first);

      expect(row.height, AppSizes.row);
      expect(tile.top - row.top, 12);
      expect(row.bottom - tile.bottom, 12);
    });

    testWidgets('the key is built from the entry id', (tester) async {
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
    });

    testWidgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(host(IntrinsicHeight(child: _row())));

      expect(tester.takeException(), isNull);
    });

    test('the view compares by value, runs included', () {
      const a = ActivityView(
        id: 'x',
        icon: AppIcons.bell,
        text: [ActivityText('m')],
      );
      const b = ActivityView(
        id: 'x',
        icon: AppIcons.bell,
        text: [ActivityText('m')],
      );
      const c = ActivityView(
        id: 'x',
        icon: AppIcons.bell,
        text: [ActivityText('m')],
        tone: ActivityTone.busy,
      );
      const d = ActivityView(
        id: 'x',
        icon: AppIcons.bell,
        text: [ActivityText('m', strong: true)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
      expect(const ActivityText('m'), const ActivityText('m'));
      expect(
        const ActivityText('m'),
        isNot(const ActivityText('m', strong: true)),
      );
    });

    testWidgets('an entry without a text is rejected when it is built', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row(runs: const [])));

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('the runs are drawn in order, with the strong one in the '
        'middle of the line', (tester) async {
      await tester.pumpWidget(
        host(
          _row(
            runs: const [
              ActivityText('Room draw: you got '),
              ActivityText('Bedroom 1', strong: true),
              ActivityText(' today'),
            ],
          ),
        ),
      );

      final span = tester.widget<Text>(_message).textSpan! as TextSpan;
      expect(span.toPlainText(), 'Room draw: you got Bedroom 1 today');
      final runs = span.children!.cast<TextSpan>();
      expect(
        [for (final run in runs) run.text],
        ['Room draw: you got ', 'Bedroom 1', ' today'],
      );
      expect(
        [for (final run in runs) run.style?.fontWeight],
        [null, FontWeight.w600, null],
      );
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      testWidgets('the tile is sunken for a neutral entry and amber for a '
          'busy one, with the glyph drawn in its color ($name)', (
        tester,
      ) async {
        for (final (tone, fill, glyph) in [
          (ActivityTone.neutral, scheme.surfaceContainerHigh, scheme.onSurface),
          (ActivityTone.busy, colors.busySoft, colors.busy),
        ]) {
          await tester.pumpWidget(
            host(
              _row(tone: tone),
              theme: theme,
              background: scheme.surface,
            ),
          );
          final box = tester.getRect(find.byKey(hostBoundaryKey));
          final tile = tester.getRect(_tile.first).shift(-box.topLeft);

          expect(
            await paintedColorAt(
              tester,
              hostBoundaryKey,
              Offset(tile.left + 2, tile.center.dy),
            ),
            isSameColorAs(fill),
            reason: '$tone fill',
          );
          expect(
            countPixels(
              await paintedPixels(tester, hostBoundaryKey, region: tile),
              glyph,
            ),
            greaterThan(10),
            reason: '$tone glyph is drawn in its color',
          );
        }
      });

      testWidgets('the tile has rounded corners of radius.sm ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(_row(), theme: theme, background: scheme.surface),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final tile = tester.getRect(_tile.first).shift(-box.topLeft);

        final decoration =
            tester.widget<DecoratedBox>(_tile.first).decoration
                as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(AppRadius.sm));
        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            tile.topLeft + const Offset(1, 1),
          ),
          isSameColorAs(scheme.surface),
          reason: 'the corner is cut, the page shows through',
        );
        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            tile.topLeft + const Offset(AppRadius.sm, 1),
          ),
          isNot(isSameColorAs(scheme.surface)),
          reason: 'the edge of the tile past the corner is filled',
        );
      });

      testWidgets('the unread dot is drawn in primary ($name)', (tester) async {
        await tester.pumpWidget(
          host(_row(), theme: theme, background: scheme.surface),
        );

        expect(
          await paintedColorAtCenter(tester, hostBoundaryKey, _dot),
          isSameColorAs(scheme.primary),
        );
      });

      testWidgets('the texts are ink and muted ink ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            _row(actor: null, message: 'Hello', meta: 'Washer'),
            theme: theme,
            background: scheme.surface,
          ),
        );

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            tester.getRect(_message).center -
                tester.getTopLeft(find.byKey(hostBoundaryKey)),
          ),
          isSameColorAs(scheme.onSurface),
        );
        expect(
          await paintedColorAtCenter(
            tester,
            hostBoundaryKey,
            find.text('Washer'),
          ),
          isSameColorAs(scheme.onSurfaceVariant),
        );
      });

      testWidgets('is calm in every combination: no danger color is drawn '
          '($name)', (tester) async {
        for (final tone in ActivityTone.values) {
          for (final unread in [true, false]) {
            await tester.pumpWidget(
              host(
                _row(tone: tone, unread: unread),
                theme: theme,
                background: scheme.surface,
              ),
            );
            final pixels = await paintedPixels(tester, hostBoundaryKey);

            expect(countPixels(pixels, scheme.error), 0, reason: '$tone');
            expect(
              countPixels(pixels, scheme.errorContainer),
              0,
              reason: '$tone',
            );
          }
        }
      });

      testWidgets('keyboard focus draws a 2 px ink ring outside ($name)', (
        tester,
      ) async {
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
        final row = tester.getRect(_button);
        final probe = Offset(row.center.dx - box.left, row.top - box.top - 1);
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

  group('interaction', () {
    testWidgets('a tap anywhere on the row calls onTap once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(_row(onTap: () => taps++)));

      await tester.tap(find.text('Washer · 2 h ago'));
      await tester.pump();
      expect(taps, 1);

      await tester.tap(_tile.first);
      await tester.pump();
      expect(taps, 2);

      await tester.tap(_dot);
      await tester.pump();
      expect(taps, 3);
    });

    testWidgets('takes focus, and Enter and Space activate it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(_row(onTap: () => taps++)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(taps, 2);
    });

    testWidgets('has one tab stop: the tile, the texts and the dot are not '
        'focusable', (tester) async {
      await tester.pumpWidget(host(_row()));

      final focusable = FocusManager.instance.rootScope.traversalDescendants
          .where(
            (node) =>
                node is! FocusScopeNode &&
                node.canRequestFocus &&
                !node.skipTraversal,
          );
      expect(focusable, hasLength(1));
    });

    testWidgets('a semantic tap calls onTap', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(host(_row(onTap: () => taps++)));

      tester.semantics.tap(find.semantics.byLabel(_label));
      await tester.pump();

      expect(taps, 1);
      handle.dispose();
    });
  });

  group('right to left', () {
    testWidgets('the tile is at the start (right) and the dot at the end '
        '(left)', (tester) async {
      await tester.pumpWidget(host(_row(), direction: TextDirection.rtl));
      final row = tester.getRect(_button);

      expect(tester.getRect(_tile.first).right, lessThanOrEqualTo(row.right));
      expect(tester.getRect(_tile.first).center.dx, greaterThan(row.center.dx));
      expect(tester.getRect(_dot).center.dx, lessThan(row.center.dx));
      expect(
        tester.getRect(_message).right,
        lessThanOrEqualTo(tester.getRect(_tile.first).left),
      );
      expect(
        tester.getRect(_message).left,
        greaterThanOrEqualTo(tester.getRect(_dot).right),
      );
    });

    testWidgets('padding mirrors: the tile keeps 12 from the start edge', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(host(_row(), direction: direction));
        final row = tester.getRect(_button);
        final tile = tester.getRect(_tile.first);

        final gap = direction == TextDirection.ltr
            ? tile.left - row.left
            : row.right - tile.right;
        expect(gap, AppSpacing.sm + AppSpacing.xs, reason: '$direction');
      }
    });
  });

  group('semantics', () {
    testWidgets('is one button named by the spoken label, and nothing is '
        'said twice', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_row()));

      expect(
        tester.getSemantics(_button),
        isSemantics(
          label: _label,
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(semanticsLabels(tester), [_label]);
      handle.dispose();
    });

    testWidgets('a read row has the same single node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_row(unread: false, label: 'Carlos finished your washer')),
      );

      expect(semanticsLabels(tester), ['Carlos finished your washer']);
      handle.dispose();
    });

    for (final (name, wrap) in <(String, Widget Function(Widget))>[
      (
        'a labeled container',
        (child) => Semantics(container: true, label: 'Feed', child: child),
      ),
      (
        'a list view',
        (child) => SizedBox(height: 200, child: ListView(children: [child])),
      ),
      ('a card', (child) => Card(child: child)),
    ]) {
      testWidgets('stays its own button under $name', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(wrap(_row())));

        final data = tester.getSemantics(_button).getSemanticsData();
        expect(data.label, _label);
        expect(data.flagsCollection.isButton, isTrue);
        expect(
          semanticsLabels(tester).where((label) => label.contains('Carlos')),
          [_label],
          reason: 'said once, not merged into the parent',
        );
        handle.dispose();
      });
    }

    testWidgets('needs a spoken label', (tester) async {
      expect(() => _row(label: ''), throwsAssertionError);
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;
      final backgrounds = {
        'page': scheme.surface,
        'card': scheme.surfaceContainerLowest,
      };

      test('texts reach 4.5:1 on the page and on a card ($name)', () {
        expectContrast(
          {
            for (final background in backgrounds.entries) ...{
              'message/${background.key}': (scheme.onSurface, background.value),
              'meta/${background.key}': (
                scheme.onSurfaceVariant,
                background.value,
              ),
            },
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('the glyphs and the dot reach 3:1 ($name)', () {
        expectContrast(
          {
            'neutral glyph/tile': (
              scheme.onSurface,
              scheme.surfaceContainerHigh,
            ),
            'busy glyph/tile': (colors.busy, colors.busySoft),
            for (final background in backgrounds.entries)
              'dot/${background.key}': (scheme.primary, background.value),
            for (final background in backgrounds.entries)
              'focus ring/${background.key}': (
                scheme.onSurface,
                background.value,
              ),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const actor = 'María de los Ángeles';
    const message = 'terminó de usar la lavadora y te avisó';
    const meta = 'Lavadora · hace dos horas';
    const spoken = 'Sin leer. María de los Ángeles terminó de usar la lavadora';

    Widget longRow({bool unread = true}) => _row(
      actor: actor,
      message: message,
      meta: meta,
      unread: unread,
      label: spoken,
    );

    testWidgets('wraps and grows at 1.3, 1.5 and 2.0 without clipping or '
        'cutting a word', (tester) async {
      await tester.pumpWidget(host(longRow()));
      final base = tester.getSize(_message).height;

      for (final scale in [1.3, 1.5, 2.0]) {
        await tester.pumpWidget(host(longRow(), textScale: scale));
        final reason = 'at ${scale}x';
        final row = tester.getRect(_button);
        final text = tester.getRect(_message);
        final metaBox = tester.getRect(find.text(meta));

        expect(tester.takeException(), isNull, reason: reason);
        expect(row.height, greaterThanOrEqualTo(AppSizes.row));
        expect(
          text.height,
          greaterThanOrEqualTo(base * scale - 1),
          reason: '$reason: the text is scaled, never clamped',
        );
        expect(
          tester.getSize(_tile.first),
          const Size.square(40),
          reason: '$reason: the tile keeps its size',
        );
        expect(
          tester.getSize(_dot),
          const Size.square(AppSizes.dotUnread),
          reason: '$reason: the dot keeps its size',
        );
        expect(
          text.right,
          lessThanOrEqualTo(tester.getRect(_dot).left),
          reason: '$reason: the text stays clear of the dot',
        );
        expect(
          text.left,
          greaterThanOrEqualTo(tester.getRect(_tile.first).right),
          reason: '$reason: the text stays clear of the tile',
        );
        expect(metaBox.top, greaterThanOrEqualTo(text.bottom), reason: reason);
        expect(
          metaBox.bottom,
          lessThanOrEqualTo(row.bottom),
          reason: '$reason: nothing is cut below',
        );
        expectNoMidWordBreaks(tester, _message, bold: true, reason: reason);
        expectNoMidWordBreaks(tester, find.text(meta), reason: reason);
      }
    });

    testWidgets('the dot stays on the first line, which grows with the text', (
      tester,
    ) async {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(host(longRow(), textScale: scale));
        final text = tester.getRect(_message);
        final dot = tester.getRect(_dot);
        final firstLine = 22 * scale;

        expect(dot.center.dy, closeTo(text.top + firstLine / 2, 1));
      }
    });

    testWidgets('the dot stays centered on the first line under a text scale '
        'that is not linear', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const _OffsetScaler()),
              child: longRow(),
            ),
          ),
        ),
      );
      final text = tester.getRect(_message);
      final dot = tester.getRect(_dot);
      final firstLine = const _OffsetScaler().scale(15) * 22 / 15;

      expect(dot.center.dy, closeTo(text.top + firstLine / 2, 0.5));
    });

    testWidgets('right to left wraps the same way', (tester) async {
      await tester.pumpWidget(
        host(longRow(), textScale: 2, direction: TextDirection.rtl),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(_message).left,
        greaterThanOrEqualTo(tester.getRect(_dot).right),
      );
      expectNoMidWordBreaks(tester, _message, bold: true);
    });
  });
}

/// A text scaler that adds to the font size instead of multiplying it, as the
/// platform scalers of some phones do: 15 becomes 28.5.
class _OffsetScaler extends TextScaler {
  const new();

  @override
  double scale(double fontSize) => fontSize * 1.5 + 6;

  @override
  double get textScaleFactor => 1.5;

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) => this;
}

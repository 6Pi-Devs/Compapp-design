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

const _code = '4829 1736';
const _label = 'Your personal code';

CodeCard _card({
  String code = _code,
  String label = _label,
  String copy = 'Copy',
  String copied = 'Copied',
  String share = 'Share',
  bool isCopied = false,
  VoidCallback? onCopy,
  VoidCallback? onShare,
}) => CodeCard(
  code: code,
  label: label,
  copyLabel: copy,
  copiedLabel: copied,
  shareLabel: share,
  copied: isCopied,
  onCopy: onCopy ?? () {},
  onShare: onShare ?? () {},
);

Finder get _root => find.byKey(const Key('account.code'));
Finder get _value => find.byKey(const Key('account.code.value'));
Finder get _copy => find.byKey(const Key('account.code.copy'));
Finder get _share => find.byKey(const Key('account.code.share'));

/// The Material button inside an `AppButton`: the node assistive technology
/// sees.
Finder _node(Finder button) =>
    find.descendant(of: button, matching: find.byType(OutlinedButton));

Finder _icon(Finder button) =>
    find.descendant(of: button, matching: find.byType(AppIcon));

/// The dashed card: the box that holds the caption and the code.
Finder get _cardBox =>
    find.ancestor(of: _value, matching: find.byType(DecoratedBox)).first;

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows the caption, the code and the two buttons', (
      tester,
    ) async {
      await tester.pumpWidget(host(_card()));

      expect(find.text(_label), findsOneWidget);
      expect(find.text(_code), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(tester.widget<AppIcon>(_icon(_copy)).icon, AppIcons.copy);
      expect(tester.widget<AppIcon>(_icon(_share)).icon, AppIcons.share);
      for (final key in [_copy, _share]) {
        final button = tester.widget<AppButton>(key);
        expect(button.variant, AppButtonVariant.secondary);
      }
    });

    testWidgets('the code is the code style in ink, as written', (
      tester,
    ) async {
      await tester.pumpWidget(host(_card()));

      final style = tester.widget<Text>(_value).style!;
      expect(style.fontSize, AppTypography.code.fontSize);
      expect(style.letterSpacing, 4);
      expect(style.fontFamily, AppTypography.code.fontFamily);
      expect(style.fontFeatures, AppTypography.code.fontFeatures);
      expect(tester.widget<Text>(_value).data, _code);
    });

    testWidgets('copied says copiedLabel with a check on the copy button', (
      tester,
    ) async {
      await tester.pumpWidget(host(_card(isCopied: true)));

      expect(find.text('Copied'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      expect(tester.widget<AppIcon>(_icon(_copy)).icon, AppIcons.check);
      expect(tester.widget<AppIcon>(_icon(_share)).icon, AppIcons.share);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('fills the width, with the buttons as equal halves of it', (
      tester,
    ) async {
      await tester.pumpWidget(host(_card()));

      expect(tester.getSize(_root).width, hostWidth);
      expect(tester.getSize(_cardBox).width, hostWidth);
      expect(tester.getSize(_copy).width, tester.getSize(_share).width);
      expect(
        tester.getRect(_share).left - tester.getRect(_copy).right,
        AppSpacing.sm,
      );
      expect(tester.getRect(_copy).left, tester.getRect(_root).left);
      expect(tester.getRect(_share).right, tester.getRect(_root).right);
      expect(tester.getRect(_copy).top, tester.getRect(_share).top);
      expect(
        tester.getRect(_copy).top - tester.getRect(_cardBox).bottom,
        AppSpacing.sm + AppSpacing.xs,
      );
    });

    testWidgets('the caption and the code are 4 apart, and the card has 16 '
        'above and below them', (tester) async {
      await tester.pumpWidget(host(_card()));
      final caption = tester.getRect(find.text(_label));
      final code = tester.getRect(_value);
      final card = tester.getRect(_cardBox);

      expect(code.top - caption.bottom, AppSpacing.xs);
      expect(caption.top - card.top, AppSpacing.md);
      expect(card.bottom - code.bottom, AppSpacing.md);
    });

    testWidgets('the buttons are at least 48 tall', (tester) async {
      await tester.pumpWidget(host(_card()));

      for (final button in [_copy, _share]) {
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(host(IntrinsicHeight(child: _card())));

      expect(tester.takeException(), isNull);
    });

    testWidgets('needs every text', (tester) async {
      expect(() => _card(code: ''), throwsAssertionError);
      expect(() => _card(label: ''), throwsAssertionError);
      expect(() => _card(copy: ''), throwsAssertionError);
      expect(() => _card(copied: ''), throwsAssertionError);
      expect(() => _card(share: ''), throwsAssertionError);
    });
  });

  group('actions', () {
    testWidgets('each button calls its own callback once per tap', (
      tester,
    ) async {
      var copies = 0;
      var shares = 0;
      await tester.pumpWidget(
        host(_card(onCopy: () => copies++, onShare: () => shares++)),
      );

      await tester.tap(_copy);
      await tester.pump();
      expect((copies, shares), (1, 0));

      await tester.tap(_share);
      await tester.pump();
      expect((copies, shares), (1, 1));
    });

    testWidgets('the copy button still copies after it was copied', (
      tester,
    ) async {
      var copies = 0;
      await tester.pumpWidget(
        host(_card(isCopied: true, onCopy: () => copies++)),
      );

      await tester.tap(_copy);
      await tester.pump();

      expect(copies, 1);
    });

    testWidgets('a tap on the code or the card does nothing', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(_card(onCopy: () => calls++, onShare: () => calls++)),
      );

      await tester.tap(_value);
      await tester.tap(find.text(_label));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('Tab visits copy then share, and Enter and Space activate '
        'them', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        host(
          _card(
            onCopy: () => calls.add('copy'),
            onShare: () => calls.add('share'),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(calls, ['copy', 'share']);
    });

    testWidgets('has two tab stops: the code and the card are not '
        'focusable', (tester) async {
      await tester.pumpWidget(host(_card()));

      final focusable = FocusManager.instance.rootScope.traversalDescendants
          .where(
            (node) =>
                node is! FocusScopeNode &&
                node.canRequestFocus &&
                !node.skipTraversal,
          );
      expect(focusable, hasLength(2));
    });

    testWidgets('a semantic tap activates the button', (tester) async {
      final handle = tester.ensureSemantics();
      var shares = 0;
      await tester.pumpWidget(host(_card(onShare: () => shares++)));

      tester.semantics.tap(find.semantics.byLabel('Share'));
      await tester.pump();

      expect(shares, 1);
      handle.dispose();
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      testWidgets('the card is a surface with a dashed hairline edge, and '
          'the texts are muted and ink ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            _card(label: 'Code', code: 'Aa'),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final card = tester.getRect(_cardBox).shift(-box.topLeft);

        expect(
          await paintedColorAt(
            tester,
            hostBoundaryKey,
            card.center + Offset(card.width / 2 - 8, 0),
          ),
          isSameColorAs(scheme.surfaceContainerLowest),
        );
        final edge = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: Rect.fromLTRB(
            card.left + 30,
            card.top,
            card.right - 30,
            card.top + 1,
          ),
        );
        final dashes = countPixels(edge, scheme.outlineVariant);
        expect(dashes, greaterThan(20), reason: 'dashes in the hairline color');
        expect(
          edge.length - dashes,
          greaterThan(10),
          reason: 'with gaps between them: the edge is dashed, not solid',
        );
        expect(
          await paintedColorAtCenter(
            tester,
            hostBoundaryKey,
            find.text('Code'),
          ),
          isSameColorAs(scheme.onSurfaceVariant),
        );
        expect(
          await paintedColorAtCenter(tester, hostBoundaryKey, _value),
          isSameColorAs(scheme.onSurface),
        );
      });

      testWidgets('the buttons are secondary buttons, and the copied label '
          'and check are drawn in ink ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            _card(isCopied: true, copied: 'Done'),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));

        expect(
          await paintedColorAtCenter(
            tester,
            hostBoundaryKey,
            find.text('Done'),
          ),
          isSameColorAs(scheme.onSurface),
        );
        expect(
          closestColorDistance(
            await paintedPixels(
              tester,
              hostBoundaryKey,
              region: tester.getRect(_icon(_copy)).shift(-box.topLeft),
            ),
            scheme.onSurface,
          ),
          lessThan(0.25),
          reason: 'the check is drawn in ink, as dark as a thin stroke gets',
        );
      });

      testWidgets('is calm: no danger color is drawn ($name)', (tester) async {
        for (final isCopied in [false, true]) {
          await tester.pumpWidget(
            host(
              _card(isCopied: isCopied),
              theme: theme,
              background: scheme.surface,
            ),
          );
          final pixels = await paintedPixels(tester, hostBoundaryKey);

          expect(countPixels(pixels, scheme.error), 0);
          expect(countPixels(pixels, scheme.errorContainer), 0);
        }
      });

      testWidgets('keyboard focus draws an ink ring around a button ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _card(),
            ),
            theme: theme,
            background: scheme.surface,
          ),
        );
        final box = tester.getRect(find.byKey(hostBoundaryKey));
        final button = tester.getRect(_copy);
        final probe = Offset(
          button.center.dx - box.left,
          button.bottom - box.top + 1,
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

  group('intrinsic sizes', () {
    setUpAll(loadBundledFonts);

    const label = 'Tu código personal de la casa';

    CodeCard longCard() => _card(
      label: label,
      copy: 'Copiar',
      copied: 'Copiado',
      share: 'Compartir',
    );

    Finder pair() => find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_EqualPair',
    );

    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final width in [200.0, 260.0, 320.0, 400.0]) {
        testWidgets('the pair answers its sizes as it lays out, at $width '
            'wide and ${scale}x', (tester) async {
          // A narrow column at 2.0x is taller than the default surface.
          tester.view.physicalSize *= 8;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            host(longCard(), width: width, textScale: scale),
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

    testWidgets('at its largest intrinsic width the buttons are side by side '
        'and nothing wraps: more room does not make it shorter', (
      tester,
    ) async {
      await tester.pumpWidget(host(longCard()));
      final widest = tester
          .renderObject<RenderBox>(pair())
          .getMaxIntrinsicWidth(double.infinity);

      await tester.pumpWidget(host(longCard(), width: widest));
      expect(tester.getRect(_copy).top, tester.getRect(_share).top);
      expect(
        tester.getRect(_copy).right,
        lessThan(tester.getRect(_share).left),
      );
      final snug = tester.getSize(_root).height;

      await tester.pumpWidget(host(longCard(), width: widest + 200));
      expect(tester.getSize(_root).height, snug);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('at its least intrinsic width no word is cut and the '
          'buttons stack, at ${scale}x', (tester) async {
        await tester.pumpWidget(host(longCard(), textScale: scale));
        final least = tester
            .renderObject<RenderBox>(pair())
            .getMinIntrinsicWidth(double.infinity);

        await tester.pumpWidget(
          host(longCard(), width: least, textScale: scale),
        );

        expect(tester.takeException(), isNull);
        expectNoMidWordBreaks(tester, find.text('Compartir'));
        expectNoMidWordBreaks(tester, find.text('Copiar'));
        expect(
          tester.getRect(_share).top,
          greaterThanOrEqualTo(tester.getRect(_copy).bottom),
        );
      });
    }
  });

  group('right to left', () {
    testWidgets('the copy button is at the start, the right', (tester) async {
      await tester.pumpWidget(host(_card(), direction: TextDirection.rtl));

      expect(
        tester.getRect(_copy).center.dx,
        greaterThan(tester.getRect(_share).center.dx),
      );
      expect(tester.getRect(_copy).right, tester.getRect(_root).right);
      expect(tester.getRect(_share).left, tester.getRect(_root).left);
    });

    testWidgets('the code still reads left to right and stays centered', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(host(_card(), direction: direction));

        expect(
          tester.renderObject<RenderParagraph>(_value).textDirection,
          TextDirection.ltr,
          reason: '$direction',
        );
        expect(
          tester.getRect(_value).center.dx,
          closeTo(tester.getRect(_cardBox).center.dx, 0.5),
        );
      }
    });

    testWidgets('the caption follows the text direction', (tester) async {
      await tester.pumpWidget(host(_card(), direction: TextDirection.rtl));

      expect(
        tester.renderObject<RenderParagraph>(find.text(_label)).textDirection,
        TextDirection.rtl,
      );
    });
  });

  group('semantics', () {
    testWidgets('the code is one node named by the caption with the code '
        'spelled out, and the buttons are their own', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_card()));

      final data = tester.getSemantics(_value).getSemanticsData();
      expect(data.label, _label);
      expect(data.attributedValue.string, _code);
      expect(data.attributedValue.attributes, hasLength(1));
      final spell = data.attributedValue.attributes.single;
      expect(spell, isA<SpellOutStringAttribute>());
      expect(spell.range, const TextRange(start: 0, end: _code.length));
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);

      for (final (button, label) in [(_copy, 'Copy'), (_share, 'Share')]) {
        expect(
          tester.getSemantics(_node(button)),
          isSemantics(
            label: label,
            isButton: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      }
      expect(semanticsLabels(tester), [_label, 'Copy', 'Share']);
      handle.dispose();
    });

    testWidgets('copied renames the copy button and nothing is said '
        'twice', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_card(isCopied: true)));

      expect(semanticsLabels(tester), [_label, 'Copied', 'Share']);
      handle.dispose();
    });

    for (final (name, wrap) in <(String, Widget Function(Widget))>[
      (
        'a labeled container',
        (child) => Semantics(container: true, label: 'Account', child: child),
      ),
      (
        'a list view',
        (child) => SizedBox(height: 300, child: ListView(children: [child])),
      ),
      ('a card', (child) => Card(child: child)),
    ]) {
      testWidgets('keeps the code and the buttons apart under $name', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(wrap(_card())));

        expect(tester.getSemantics(_value).getSemanticsData().label, _label);
        expect(
          tester.getSemantics(_node(_copy)).getSemanticsData().label,
          'Copy',
        );
        expect(
          tester.getSemantics(_node(_share)).getSemanticsData().label,
          'Share',
        );
        expect(
          semanticsLabels(
            tester,
          ).where((label) => const {_label, 'Copy', 'Share'}.contains(label)),
          [_label, 'Copy', 'Share'],
          reason: 'each said once, none merged into the parent',
        );
        handle.dispose();
      });
    }
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      test('the caption and the code reach 4.5:1 on the card ($name)', () {
        expectContrast(
          {
            'caption': (scheme.onSurfaceVariant, scheme.surfaceContainerLowest),
            'code': (scheme.onSurface, scheme.surfaceContainerLowest),
            'button label': (scheme.onSurface, scheme.surfaceContainerLowest),
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('the button border, its glyphs and the focus ring reach 3:1 '
          '($name)', () {
        expectContrast(
          {
            'button border/page': (scheme.outline, scheme.surface),
            'button border/card': (
              scheme.outline,
              scheme.surfaceContainerLowest,
            ),
            'glyph/button': (scheme.onSurface, scheme.surfaceContainerLowest),
            'focus ring/page': (scheme.onSurface, scheme.surface),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const label = 'Tu código personal de la casa';

    CodeCard longCard({bool isCopied = false}) => _card(
      label: label,
      copy: 'Copiar',
      copied: 'Copiado',
      share: 'Compartir',
      isCopied: isCopied,
    );

    testWidgets('grows at 1.3, 1.5 and 2.0 without clipping or cutting a '
        'word', (tester) async {
      for (final isCopied in [false, true]) {
        await tester.pumpWidget(host(longCard(isCopied: isCopied)));
        final base = tester.getSize(_value).height;

        for (final scale in [1.0, 1.3, 1.5, 2.0]) {
          await tester.pumpWidget(
            host(longCard(isCopied: isCopied), textScale: scale),
          );
          final reason = 'copied $isCopied at ${scale}x';
          final card = tester.getRect(_cardBox);
          final copy = tester.getRect(_copy);
          final share = tester.getRect(_share);

          expect(tester.takeException(), isNull, reason: reason);
          expect(
            tester.getSize(_value).height,
            greaterThanOrEqualTo(base * scale - 1),
            reason: '$reason: the text is scaled, never clamped',
          );
          for (final box in [
            tester.getRect(_value),
            tester.getRect(find.text(label)),
          ]) {
            expect(box.left, greaterThanOrEqualTo(card.left), reason: reason);
            expect(box.right, lessThanOrEqualTo(card.right), reason: reason);
            expect(box.bottom, lessThanOrEqualTo(card.bottom), reason: reason);
          }
          expectNoMidWordBreaks(tester, _value, reason: reason);
          expectNoMidWordBreaks(tester, find.text(label), reason: reason);
          for (final text in [
            if (isCopied) 'Copiado' else 'Copiar',
            'Compartir',
          ]) {
            expectNoMidWordBreaks(tester, find.text(text), reason: reason);
          }

          final stacked = share.top >= copy.bottom;
          if (stacked) {
            expect(copy.width, share.width, reason: reason);
            expect(copy.width, hostWidth, reason: reason);
            expect(share.top - copy.bottom, AppSpacing.sm, reason: reason);
          } else {
            expect(copy.width, share.width, reason: reason);
            expect(copy.top, share.top, reason: reason);
            expect(copy.height, share.height, reason: reason);
          }
          expect(
            stacked,
            scale > 1.0,
            reason: '$reason: side by side until a word does not fit a half',
          );
        }
      }
    });

    testWidgets('the code wraps at its space when a group no longer fits one '
        'line, and never inside a group', (tester) async {
      await tester.pumpWidget(host(longCard(), textScale: 2));

      final lines = tester
          .renderObject<RenderParagraph>(_value)
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: _code.length),
          );
      final tops = {for (final box in lines) box.top.round()};
      expect(tops, hasLength(2), reason: 'two lines, one group each');
      expectNoMidWordBreaks(tester, _value);
    });

    testWidgets('right to left grows the same way at 2.0', (tester) async {
      await tester.pumpWidget(
        host(longCard(), textScale: 2, direction: TextDirection.rtl),
      );

      expect(tester.takeException(), isNull);
      expectNoMidWordBreaks(tester, _value);
      expectNoMidWordBreaks(tester, find.text(label));
      expect(
        tester.getRect(_copy).top,
        lessThan(tester.getRect(_share).top),
        reason: 'stacked, copy first',
      );
    });
  });
}

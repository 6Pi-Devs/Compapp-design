import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart';
import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

void _noop() {}

AppSnackbar _bar({
  String message = 'Request sent to Carlos',
  SnackTone tone = SnackTone.info,
  String? actionLabel,
  VoidCallback? onAction = _noop,
  bool visible = true,
}) => AppSnackbar(
  message: message,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
  visible: visible,
);

final Finder _message = find.byKey(const Key('snackbar.message'));
final Finder _icon = find.byKey(const Key('snackbar.icon'));
final Finder _action = find.byKey(const Key('snackbar.action'));

Finder get _opacity => find.descendant(
  of: find.byType(AppSnackbar),
  matching: find.byType(FadeTransition),
);

/// The drawn bar: it moves with the slide, the widget around it does not.
Finder get _surface => find
    .descendant(
      of: find.byType(SlideTransition),
      matching: find.byType(DecoratedBox),
    )
    .first;

double _opacityNow(WidgetTester tester) =>
    tester.widget<FadeTransition>(_opacity).opacity.value;

/// A shown bar in its own host, settled.
Future<void> _pumpShown(
  WidgetTester tester,
  AppSnackbar bar, {
  ThemeData? theme,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    barHost(bar, theme: theme, textScale: textScale, direction: direction),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('content', () {
    testWidgets('shows the message and a glyph for each tone', (tester) async {
      for (final (tone, glyph) in [
        (SnackTone.info, AppIcons.check),
        (SnackTone.error, AppIcons.alert),
      ]) {
        await _pumpShown(tester, _bar(tone: tone));

        expect(find.text('Request sent to Carlos'), findsOneWidget);
        expect(tester.widget<AppIcon>(_icon).icon, glyph, reason: '$tone');
      }
    });

    testWidgets('a null or empty actionLabel leaves the action out', (
      tester,
    ) async {
      for (final label in <String?>[null, '']) {
        await _pumpShown(tester, _bar(actionLabel: label));

        expect(_action, findsNothing, reason: '"$label"');
      }
    });

    testWidgets('the action calls onAction and a null one disables it', (
      tester,
    ) async {
      var taps = 0;
      await _pumpShown(
        tester,
        _bar(actionLabel: 'Retry', onAction: () => taps++),
      );
      await tester.tap(_action);
      expect(taps, 1);

      await _pumpShown(tester, _bar(actionLabel: 'Retry', onAction: null));
      expect(tester.widget<TextButton>(_action).onPressed, isNull);
    });

    testWidgets('keeps no timer: it stays shown however long it waits', (
      tester,
    ) async {
      await _pumpShown(tester, _bar(actionLabel: 'Retry'));

      await tester.pump(const Duration(minutes: 10));

      expect(find.text('Request sent to Carlos'), findsOneWidget);
      expect(_opacityNow(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('is at least 52 tall and as wide as it is given', (
      tester,
    ) async {
      await _pumpShown(tester, _bar());

      expect(
        tester.getSize(find.byType(AppSnackbar)).height,
        greaterThanOrEqualTo(AppSizes.controlLg),
      );
      expect(tester.getSize(find.byType(AppSnackbar)).width, 360);
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      testWidgets('inverse fill, light text and soft glyph ($name)', (
        tester,
      ) async {
        await _pumpShown(tester, _bar(actionLabel: 'Retry'), theme: theme);
        final scheme = theme.colorScheme;
        final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
        final bar = tester.getRect(find.byType(AppSnackbar)).shift(-origin);

        expect(
          await paintedColorAt(
            tester,
            barBoundaryKey,
            Offset(bar.center.dx, bar.top + 2),
          ),
          isSameColorAs(scheme.inverseSurface),
          reason: 'fill',
        );
        expect(
          tester.widget<Text>(_message).style!.color,
          scheme.onInverseSurface,
        );
        expect(tester.widget<AppIcon>(_icon).color, scheme.inversePrimary);
        expect(
          tester
              .widget<TextButton>(_action)
              .style!
              .foregroundColor!
              .resolve({}),
          scheme.inversePrimary,
        );
      });

      testWidgets('the glyph is really painted in the soft primary ($name)', (
        tester,
      ) async {
        await _pumpShown(tester, _bar(tone: SnackTone.error), theme: theme);
        final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
        final icon = tester.getRect(_icon).shift(-origin);

        var hits = 0;
        for (var y = icon.top; y < icon.bottom; y++) {
          for (var x = icon.left; x < icon.right; x++) {
            final color = await paintedColorAt(
              tester,
              barBoundaryKey,
              Offset(x, y),
            );
            if (isSameColorAs(theme.colorScheme.inversePrimary)
                .matches(color, {})) {
              hits++;
            }
          }
        }

        expect(hits, greaterThan(3), reason: 'pixels of the glyph stroke');
      });

      testWidgets('both tones use the same calm colors ($name)', (
        tester,
      ) async {
        Future<List<Object?>> look(SnackTone tone) async {
          await _pumpShown(
            tester,
            _bar(tone: tone, actionLabel: 'Retry'),
            theme: theme,
          );
          return [
            tester.widget<AppIcon>(_icon).color,
            tester.widget<Text>(_message).style!.color,
            tester
                .widget<TextButton>(_action)
                .style!
                .foregroundColor!
                .resolve({}),
          ];
        }

        final scheme = theme.colorScheme;
        final info = await look(SnackTone.info);
        final error = await look(SnackTone.error);

        expect(error, info, reason: 'the tone is the glyph, not the color');
        expect(error, isNot(contains(scheme.error)));
        expect(error, isNot(contains(scheme.errorContainer)));
      });
    }

    testWidgets('the corners are rounded with radius.sm', (tester) async {
      await _pumpShown(tester, _bar());

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(AppSnackbar),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.sm));
    });
  });

  group('semantics', () {
    testWidgets('is one live region named by the message, announced once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpShown(tester, _bar());

      final labeled = labeledNodes(tester);
      expect(labeled, hasLength(1));
      expect(labeled.single.label, 'Request sent to Carlos');
      expect(labeled.single.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('the action is a focusable button named by its label, after '
        'the message', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpShown(tester, _bar(actionLabel: 'Retry'));

      final labels = [for (final n in labeledNodes(tester)) n.label];
      expect(labels, ['Request sent to Carlos', 'Retry']);
      expect(
        tester.getSemantics(_action),
        isSemantics(
          label: 'Retry',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final live = labeledNodes(tester).first;
      expect(
        tester.getSemantics(_action).flagsCollection.isLiveRegion,
        isFalse,
        reason: 'the action is not announced with the message',
      );
      expect(live.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('passes the Flutter tap target and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpShown(tester, _bar(actionLabel: 'Retry'));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('a hidden bar has no semantics, no focus and no size', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        barHost(_bar(actionLabel: 'Retry', visible: false)),
      );
      await tester.pumpAndSettle();

      expect(labeledNodes(tester), isEmpty);
      expect(find.byType(TextButton), findsNothing);
      expect(tester.getSize(find.byType(AppSnackbar)).height, 0);
      handle.dispose();
    });

    testWidgets('while it leaves, it is already out of semantics and focus', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpShown(tester, _bar(actionLabel: 'Retry'));

      await tester.pumpWidget(
        barHost(_bar(actionLabel: 'Retry', visible: false)),
      );
      await tester.pump(AppMotion.snackbar ~/ 2);

      expect(find.byType(TextButton), findsOneWidget, reason: 'still drawn');
      expect(labeledNodes(tester).where((n) => n.label == 'Retry'), isEmpty);
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .descendant(
                    of: find.byType(AppSnackbar),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring,
        isTrue,
      );
      handle.dispose();
    });
  });

  group('targets and focus', () {
    testWidgets('the action is 44 drawn with a 48 hit area', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpShown(tester, _bar(actionLabel: 'Retry'));

      final drawn = tester.getSize(
        find.descendant(of: _action, matching: find.byType(Material)).first,
      );
      expect(drawn.height, greaterThanOrEqualTo(AppSizes.minDrawn));
      expect(
        tester.getSemantics(_action).rect.height,
        greaterThanOrEqualTo(AppSizes.minTarget),
      );
      handle.dispose();
    });

    testWidgets('keyboard focus draws a ring in the light color of the bar', (
      tester,
    ) async {
      await _pumpShown(tester, _bar(actionLabel: 'Retry'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final style = tester.widget<TextButton>(_action).style!;
      final side = style.side!.resolve({WidgetState.focused})!;
      final scheme = CompappTheme.light.colorScheme;

      expect(side.color, scheme.onInverseSurface);
      expect(side.width, AppSizes.borderEmphasis);
      expect(side.strokeAlign, BorderSide.strokeAlignOutside);
      expect(style.side!.resolve({}), isNull);
      expect(
        Focus.of(tester.element(_action)).hasFocus,
        isTrue,
        reason: 'the action takes keyboard focus',
      );
    });
  });

  group('motion', () {
    testWidgets('enters over motion.snackbar: from hidden to shown', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar()));
      await tester.pump();
      expect(_opacityNow(tester), 0);

      await tester.pump(AppMotion.snackbar ~/ 2);
      final midway = _opacityNow(tester);
      expect(midway, greaterThan(0));
      expect(midway, lessThan(1));

      await tester.pump(
        AppMotion.snackbar ~/ 2 - const Duration(milliseconds: 1),
      );
      expect(_opacityNow(tester), lessThan(1), reason: 'not done a tick early');

      await tester.pump(const Duration(milliseconds: 1));
      expect(_opacityNow(tester), 1);
    });

    testWidgets('slides up while it enters', (tester) async {
      await tester.pumpWidget(barHost(_bar()));
      await tester.pump();
      final start = tester.getTopLeft(_surface).dy;

      await tester.pumpAndSettle();

      expect(tester.getTopLeft(_surface).dy, lessThan(start));
    });

    testWidgets('leaves over motion.snackbar and then takes no space', (
      tester,
    ) async {
      await _pumpShown(tester, _bar());

      await tester.pumpWidget(barHost(_bar(visible: false)));
      await tester.pump();
      await tester.pump(AppMotion.snackbar ~/ 2);
      final midway = _opacityNow(tester);
      expect(midway, greaterThan(0));
      expect(midway, lessThan(1));

      await tester.pump(AppMotion.snackbar);
      expect(tester.getSize(find.byType(AppSnackbar)).height, 0);
    });

    testWidgets('shows again after a hide', (tester) async {
      await _pumpShown(tester, _bar());
      await tester.pumpWidget(barHost(_bar(visible: false)));
      await tester.pumpAndSettle();

      await tester.pumpWidget(barHost(_bar()));
      await tester.pumpAndSettle();

      expect(find.text('Request sent to Carlos'), findsOneWidget);
      expect(_opacityNow(tester), 1);
    });

    testWidgets('disableAnimations: appears and disappears at once', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar(), disableAnimations: true));
      expect(_opacityNow(tester), 1, reason: 'shown on the first frame');
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(
        barHost(_bar(visible: false), disableAnimations: true),
      );
      expect(tester.getSize(find.byType(AppSnackbar)).height, 0);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(barHost(_bar(), disableAnimations: true));
      expect(_opacityNow(tester), 1);
    });

    testWidgets('the system turning reduce motion on mid-flight settles it', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_bar()));
      await tester.pump(AppMotion.snackbar ~/ 4);

      await tester.pumpWidget(barHost(_bar(), disableAnimations: true));

      expect(_opacityNow(tester), 1);
    });
  });

  group('hidden bar and focus', () {
    testWidgets('Tab never lands on the action of a hidden bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        barHost(
          Column(
            children: [
              _bar(actionLabel: 'Retry', visible: false),
              TextButton(onPressed: () {}, child: const Text('Other')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_action, findsNothing);
        final primary = FocusManager.instance.primaryFocus;
        expect(
          primary == null ||
              find
                  .descendant(
                    of: find.byType(AppSnackbar),
                    matching: find.byElementPredicate(
                      (e) => identical(e, primary.context),
                    ),
                  )
                  .evaluate()
                  .isEmpty,
          isTrue,
        );
      }
    });

    testWidgets('while it leaves, Tab skips the action and a focused action '
        'loses focus', (tester) async {
      Widget host({required bool visible}) => barHost(
        Column(
          children: [
            _bar(actionLabel: 'Retry', visible: visible),
            TextButton(onPressed: () {}, child: const Text('Other')),
          ],
        ),
      );
      bool actionFocused() => Focus.of(tester.element(_action)).hasFocus;

      await tester.pumpWidget(host(visible: true));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(actionFocused(), isTrue, reason: 'it takes focus while shown');

      await tester.pumpWidget(host(visible: false));
      await tester.pump();
      await tester.pump(AppMotion.snackbar ~/ 2);

      expect(find.byType(TextButton), findsNWidgets(2), reason: 'still drawn');
      expect(actionFocused(), isFalse, reason: 'it lost focus when it hid');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(actionFocused(), isFalse, reason: 'Tab skips it while it leaves');
    });
  });

  group('action states', () {
    for (final (name, theme) in themes) {
      testWidgets(
        'overlay of the soft primary, not of the page primary ($name)',
        (tester) async {
          await _pumpShown(tester, _bar(actionLabel: 'Retry'), theme: theme);
          final scheme = theme.colorScheme;
          final overlay = tester
              .widget<TextButton>(_action)
              .style!
              .overlayColor!;

          expect(
            overlay.resolve({WidgetState.pressed}),
            scheme.inversePrimary.withValues(
              alpha: AppStateLayers.pressedPrimary,
            ),
          );
          for (final state in [WidgetState.hovered, WidgetState.focused]) {
            expect(
              overlay.resolve({state}),
              scheme.inversePrimary.withValues(
                alpha: AppStateLayers.pressedSecondary,
              ),
            );
          }
          expect(overlay.resolve({}), isNull);
          final pressed = Color.alphaBlend(
            overlay.resolve({WidgetState.pressed})!,
            scheme.inverseSurface,
          );
          expect(
            contrastRatio(pressed, scheme.inverseSurface),
            greaterThan(1.1),
            reason: 'visible on the bar, unlike the 1.05 of the page primary',
          );
        },
      );

      testWidgets('a disabled action is dimmer but still legible ($name)', (
        tester,
      ) async {
        await _pumpShown(
          tester,
          _bar(actionLabel: 'Retry', onAction: null),
          theme: theme,
        );
        final scheme = theme.colorScheme;
        final color = tester
            .widget<TextButton>(_action)
            .style!
            .foregroundColor!;
        final enabled = color.resolve({});
        final disabled = color.resolve({WidgetState.disabled})!;

        expect(disabled, isNot(enabled));
        expect(disabled.a, lessThan(1));
        expect(
          contrastRatio(
            Color.alphaBlend(disabled, scheme.inverseSurface),
            scheme.inverseSurface,
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'dim, but as legible as the repo disabled stories',
        );
      });
    }
  });

  group('action on its own line', () {
    setUpAll(loadBundledFonts);

    const message = 'No se puede conectar con el servidor';
    const action = 'Deshacer la solicitud';

    testWidgets('a long action moves under the message, end-aligned', (
      tester,
    ) async {
      for (final scale in [1.0, 2.0]) {
        for (final direction in TextDirection.values) {
          await _pumpShown(
            tester,
            _bar(message: message, tone: SnackTone.error, actionLabel: action),
            textScale: scale,
            direction: direction,
          );

          final reason = '$scale $direction';
          expect(tester.takeException(), isNull, reason: reason);
          final bar = tester.getRect(find.byType(AppSnackbar));
          final button = tester.getRect(
            find.descendant(of: _action, matching: find.byType(Material)).first,
          );
          expect(
            button.top,
            greaterThanOrEqualTo(tester.getRect(_message).bottom),
            reason: '$reason: under the message',
          );
          expect(bar.contains(button.topLeft), isTrue, reason: reason);
          expect(bar.contains(button.bottomRight), isTrue, reason: reason);
          if (direction == TextDirection.ltr) {
            expect(bar.right - button.right, AppSpacing.sm, reason: reason);
          } else {
            expect(button.left - bar.left, AppSpacing.sm, reason: reason);
          }
          expectNoMidWordBreaks(tester, _message, reason: reason);
        }
      }
    });

    testWidgets('a short action stays beside the message', (tester) async {
      await _pumpShown(tester, _bar(message: 'Sent', actionLabel: 'Undo'));

      expect(
        tester.getRect(_action).center.dy,
        lessThan(tester.getRect(find.byType(AppSnackbar)).bottom),
      );
      expect(
        tester.getRect(_action).left,
        greaterThan(tester.getRect(_message).left),
      );
    });

    testWidgets('no message breaks inside a word, with or without an action', (
      tester,
    ) async {
      const messages = [
        'Request sent to Carlos',
        "Can't reach the server",
        message,
        'Solicitud enviada a Carlos',
      ];
      const actions = [null, 'Undo', 'Retry', 'Reintentar', action];

      for (final text in messages) {
        for (final label in actions) {
          for (final scale in [1.0, 1.3, 2.0]) {
            for (final direction in TextDirection.values) {
              await _pumpShown(
                tester,
                _bar(message: text, actionLabel: label),
                textScale: scale,
                direction: direction,
              );

              expectNoMidWordBreaks(
                tester,
                _message,
                reason: '$label $scale $direction',
              );
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    });
  });

  group('asserts', () {
    test('a snackbar needs a message', () {
      expect(() => AppSnackbar(message: ''), throwsAssertionError);
    });
  });

  group('intrinsic sizes', () {
    setUpAll(loadBundledFonts);

    Widget table(Widget bar) => Table(
      children: [
        TableRow(children: [bar]),
      ],
    );
    final hosts = <String, Widget Function(Widget)>{
      'IntrinsicHeight': (bar) => IntrinsicHeight(child: bar),
      'Table': table,
      'IntrinsicWidth in IntrinsicHeight': (bar) =>
          IntrinsicHeight(child: IntrinsicWidth(child: bar)),
      'Align with factors': (bar) => IntrinsicHeight(
        child: Align(
          alignment: Alignment.topLeft,
          widthFactor: 1,
          heightFactor: 1,
          child: bar,
        ),
      ),
    };

    testWidgets('the size in an intrinsic parent is the size it has alone', (
      tester,
    ) async {
      // 52 for a message alone, 52 with a short action beside it, and 98 with
      // a long one on its own line.
      const heights = {null: 52.0, 'Undo': 52.0, 'Deshacer la solicitud': 98.0};
      for (final MapEntry(key: label, value: height) in heights.entries) {
        final bar = _bar(actionLabel: label);
        await tester.pumpWidget(barHost(bar));
        await tester.pumpAndSettle();
        final alone = tester.getSize(find.byType(AppSnackbar));
        expect(alone, Size(360, height), reason: 'alone, $label');

        for (final MapEntry(key: name, value: wrap) in hosts.entries) {
          await tester.pumpWidget(barHost(wrap(bar)));
          await tester.pumpAndSettle();

          final reason = '$name, $label';
          expect(tester.takeException(), isNull, reason: reason);
          final size = tester.getSize(find.byType(AppSnackbar));
          final rect = tester.getRect(find.byType(AppSnackbar));
          expect(size.height, height, reason: reason);
          if (name != 'IntrinsicWidth in IntrinsicHeight') {
            expect(size, alone, reason: reason);
          }
          if (label != null) {
            final action = tester.getRect(_action);
            expect(rect.contains(action.topLeft), isTrue, reason: reason);
            expect(
              rect.inflate(1).contains(action.bottomRight),
              isTrue,
              reason: reason,
            );
          }
        }
      }
    });

    testWidgets('the dry layout is the size it is laid out with', (
      tester,
    ) async {
      for (final label in <String?>[null, 'Undo', 'Deshacer la solicitud']) {
        for (final width in [360.0, 240.0, 160.0]) {
          await tester.pumpWidget(
            barHost(_bar(actionLabel: label), width: width),
          );
          await tester.pumpAndSettle();
          final flow = tester.renderObject<RenderBox>(
            find.byWidgetPredicate(
              (widget) => widget.runtimeType.toString() == '_ActionFlow',
            ),
          );

          expect(
            flow.getDryLayout(flow.constraints),
            flow.size,
            reason: '$label at $width',
          );
        }
      }
    });

    testWidgets('in an IntrinsicWidth it is as wide as its content needs', (
      tester,
    ) async {
      await tester.pumpWidget(
        barHost(IntrinsicWidth(child: _bar(message: 'Sent')), width: null),
      );
      final short = tester.getSize(find.byType(AppSnackbar));
      await tester.pumpWidget(
        barHost(
          IntrinsicWidth(
            child: _bar(message: 'Sent', actionLabel: 'Undo'),
          ),
          width: null,
        ),
      );
      final withAction = tester.getSize(find.byType(AppSnackbar));

      expect(short.width, greaterThan(80), reason: 'glyph and a word');
      expect(short.width, lessThan(360));
      expect(
        withAction.width,
        greaterThan(short.width + 50),
        reason: 'it makes room for the action',
      );
      expect(withAction.width, lessThan(360));
      expect(
        tester.getRect(_action).right,
        lessThanOrEqualTo(tester.getRect(find.byType(AppSnackbar)).right),
      );
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      test('text 4.5:1 and graphics 3:1 on the bar ($name)', () {
        final scheme = theme.colorScheme;
        final bar = scheme.inverseSurface;
        expectContrast(
          {
            'message/bar': (scheme.onInverseSurface, bar),
            'action/bar': (scheme.inversePrimary, bar),
          },
          minimum: 4.5,
          reason: name,
        );
        expectContrast(
          {
            'glyph/bar': (scheme.inversePrimary, bar),
            'focus ring/bar': (scheme.onInverseSurface, bar),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('right to left', () {
    testWidgets('the glyph sits at the right and the action at the left', (
      tester,
    ) async {
      await _pumpShown(tester, _bar(actionLabel: 'Retry'));
      expect(
        tester.getCenter(_icon).dx,
        lessThan(tester.getCenter(_action).dx),
      );

      await _pumpShown(
        tester,
        _bar(actionLabel: 'Retry'),
        direction: TextDirection.rtl,
      );

      expect(
        tester.getCenter(_icon).dx,
        greaterThan(tester.getCenter(_action).dx),
      );
      expect(tester.getCenter(_icon).dx, greaterThan(180));
      expect(tester.getCenter(_action).dx, lessThan(180));
    });

    testWidgets('the slide is vertical in both directions', (tester) async {
      await tester.pumpWidget(barHost(_bar(), direction: TextDirection.rtl));
      await tester.pump();
      final start = tester.getTopLeft(_surface);

      await tester.pumpAndSettle();

      expect(tester.getTopLeft(_surface).dx, start.dx);
      expect(tester.getTopLeft(_surface).dy, lessThan(start.dy));
    });
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const long =
        'No se puede conectar con el servidor de la casa en este momento, '
        'inténtalo de nuevo más tarde';

    testWidgets('the message wraps, the bar grows and nothing overflows', (
      tester,
    ) async {
      await _pumpShown(tester, _bar(message: long, actionLabel: 'Reintentar'));
      final base = tester.getSize(find.byType(AppSnackbar)).height;

      for (final direction in TextDirection.values) {
        await _pumpShown(
          tester,
          _bar(message: long, tone: SnackTone.error, actionLabel: 'Reintentar'),
          textScale: 2,
          direction: direction,
        );

        expect(tester.takeException(), isNull, reason: '$direction');
        final bar = tester.getRect(find.byType(AppSnackbar));
        expect(bar.height, greaterThan(base));
        for (final finder in [_message, _action, _icon]) {
          final rect = tester.getRect(finder);
          expect(bar.contains(rect.topLeft), isTrue);
          expect(bar.contains(rect.bottomRight), isTrue);
        }
        expect(
          tester.renderObject<RenderParagraph>(_message).didExceedMaxLines,
          isFalse,
        );
        expect(
          tester.getRect(_message).overlaps(tester.getRect(_action)),
          isFalse,
        );
      }
    });

    testWidgets('a bar without an action centers its message', (tester) async {
      for (final tone in SnackTone.values) {
        for (final direction in TextDirection.values) {
          await _pumpShown(
            tester,
            _bar(message: 'Hola', tone: tone),
            direction: direction,
          );

          final bar = tester.getRect(find.byType(AppSnackbar));
          final message = tester.getRect(_message);
          final icon = tester.getRect(_icon);
          final reason = '$tone $direction';
          expect(
            message.top - bar.top,
            closeTo(bar.bottom - message.bottom, 0.5),
            reason: '$reason: equal gaps above and below the message',
          );
          expect(icon.center.dy, closeTo(bar.center.dy, 0.5), reason: reason);
        }
      }
    });

    testWidgets('one line of real text still makes a 52 tall bar', (
      tester,
    ) async {
      await _pumpShown(tester, _bar(message: 'Hola'));

      expect(tester.getSize(find.byType(AppSnackbar)).height, 52);
    });

    testWidgets('the action sits 8 from the end edge, a message alone 16', (
      tester,
    ) async {
      await _pumpShown(tester, _bar(actionLabel: 'Retry'));
      expect(
        tester.getRect(find.byType(AppSnackbar)).right -
            tester
                .getRect(
                  find
                      .descendant(of: _action, matching: find.byType(Material))
                      .first,
                )
                .right,
        AppSpacing.sm,
      );

      await _pumpShown(tester, _bar(message: long));
      expect(
        tester.getRect(find.byType(AppSnackbar)).right -
            tester.getRect(_message).right,
        AppSpacing.md,
      );
    });

    testWidgets('the text is never scaled down', (tester) async {
      await _pumpShown(tester, _bar(message: 'Hola', actionLabel: 'Ok'));
      final base = tester.getSize(_message).height;

      await _pumpShown(
        tester,
        _bar(message: 'Hola', actionLabel: 'Ok'),
        textScale: 2,
      );

      expect(tester.getSize(_message).height, closeTo(base * 2, 1));
    });
  });
}

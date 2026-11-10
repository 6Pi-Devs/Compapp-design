import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart' show themes;
import '../helpers/bundled_fonts.dart';
import '../helpers/host.dart';

const _title = 'Generate a new personal code?';
const _message = 'Your current code stops working.';

AppConfirmDialog _dialog({
  bool destructive = false,
  String title = _title,
  String message = _message,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) => AppConfirmDialog(
  title: title,
  message: message,
  confirmLabel: 'Generate',
  cancelLabel: 'Cancel',
  onConfirm: onConfirm ?? () {},
  onCancel: onCancel ?? () {},
  destructive: destructive,
);

/// [host] at the width of a phone, where the two buttons fit side by side.
Widget _host(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  double width = 360,
}) => host(
  child,
  theme: theme,
  textScale: textScale,
  direction: direction,
  width: width,
);

final Finder _confirm = find.byKey(const Key('confirmDialog.confirm'));
final Finder _cancel = find.byKey(const Key('confirmDialog.cancel'));

/// A page with a button that opens the dialog through [AppConfirmDialog.show]
/// and records what it completes with in [result].
Widget _opener(
  List<bool> result, {
  bool destructive = false,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            key: const Key('open'),
            onPressed: () async => result.add(
              await AppConfirmDialog.show(
                context,
                title: _title,
                message: _message,
                confirmLabel: 'Generate',
                cancelLabel: 'Cancel',
                destructive: destructive,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBundledFonts);

  group('content', () {
    testWidgets('shows the title, the message and both labels', (tester) async {
      await tester.pumpWidget(_host(_dialog()));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_message), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirm and cancel call their callbacks', (tester) async {
      var confirmed = 0;
      var cancelled = 0;
      await tester.pumpWidget(
        _host(
          _dialog(onConfirm: () => confirmed++, onCancel: () => cancelled++),
        ),
      );

      await tester.tap(_confirm);
      expect((confirmed, cancelled), (1, 0));

      await tester.tap(_cancel);
      expect((confirmed, cancelled), (1, 1));
    });

    testWidgets('both buttons are the md button and the same height', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_dialog()));

      expect(tester.widget<AppButton>(_confirm).size, AppButtonSize.md);
      expect(tester.widget<AppButton>(_cancel).size, AppButtonSize.md);
      expect(tester.getSize(_confirm).height, tester.getSize(_cancel).height);
    });

    testWidgets('the cancel button comes before the confirm button', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_dialog()));

      expect(
        tester.getTopLeft(_cancel).dx,
        lessThan(tester.getTopLeft(_confirm).dx),
      );
    });
  });

  group('destructive', () {
    testWidgets('is off by default and the confirm button is primary', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_dialog()));

      expect(
        tester.widget<AppButton>(_confirm).variant,
        AppButtonVariant.primary,
      );
      expect(tester.widget<AppButton>(_cancel).variant, AppButtonVariant.ghost);
    });

    for (final (name, theme) in themes) {
      testWidgets('the confirm button is filled with the error color ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(_dialog(destructive: true), theme: theme),
        );

        expect(
          tester.widget<AppButton>(_confirm).variant,
          AppButtonVariant.danger,
        );
        final fill = tester
            .widget<FilledButton>(
              find.descendant(
                of: _confirm,
                matching: find.byType(FilledButton),
              ),
            )
            .style!
            .backgroundColor!
            .resolve({});
        expect(fill, theme.colorScheme.error, reason: name);
        expect(
          tester.widget<AppButton>(_cancel).variant,
          AppButtonVariant.ghost,
          reason: 'cancel never turns red',
        );
      });
    }
  });

  group('show', () {
    testWidgets('confirm completes with true and closes the dialog', (
      tester,
    ) async {
      final result = <bool>[];
      await tester.pumpWidget(_opener(result));
      await _open(tester);

      expect(find.byType(AppConfirmDialog), findsOneWidget);
      await tester.tap(_confirm);
      await tester.pumpAndSettle();

      expect(result, [true]);
      expect(find.byType(AppConfirmDialog), findsNothing);
    });

    testWidgets('cancel completes with false', (tester) async {
      final result = <bool>[];
      await tester.pumpWidget(_opener(result));
      await _open(tester);

      await tester.tap(_cancel);
      await tester.pumpAndSettle();

      expect(result, [false]);
      expect(find.byType(AppConfirmDialog), findsNothing);
    });

    testWidgets('a tap on the barrier completes with false', (tester) async {
      final result = <bool>[];
      await tester.pumpWidget(_opener(result));
      await _open(tester);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(result, [false]);
      expect(find.byType(AppConfirmDialog), findsNothing);
    });

    testWidgets('back completes with false', (tester) async {
      final result = <bool>[];
      await tester.pumpWidget(_opener(result));
      await _open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(result, [false]);
      expect(find.byType(AppConfirmDialog), findsNothing);
    });

    testWidgets('passes destructive to the dialog', (tester) async {
      await tester.pumpWidget(_opener([], destructive: true));
      await _open(tester);

      expect(
        tester
            .widget<AppConfirmDialog>(find.byType(AppConfirmDialog))
            .destructive,
        isTrue,
      );
    });

    testWidgets('works in the dark theme', (tester) async {
      final result = <bool>[];
      await tester.pumpWidget(_opener(result, theme: CompappTheme.dark));
      await _open(tester);

      await tester.tap(_confirm);
      await tester.pumpAndSettle();

      expect(result, [true]);
    });
  });

  group('asserts', () {
    test('the title and both labels must not be empty', () {
      expect(() => _dialog(title: ''), throwsAssertionError);
      expect(
        () => AppConfirmDialog(
          title: 'T',
          message: 'M',
          confirmLabel: '',
          cancelLabel: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
        ),
        throwsAssertionError,
      );
      expect(
        () => AppConfirmDialog(
          title: 'T',
          message: 'M',
          confirmLabel: 'OK',
          cancelLabel: '',
          onConfirm: () {},
          onCancel: () {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('wide screens and keyboard', () {
    testWidgets('the dialog is capped at the dialog max width', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_opener([]));
      await _open(tester);

      final width = tester
          .getSize(
            find
                .descendant(
                  of: find.byType(AppConfirmDialog),
                  matching: find.byType(Material),
                )
                .first,
          )
          .width;
      expect(width, lessThanOrEqualTo(AppSizes.dialogMaxWidth));
      expect(width, AppSizes.dialogMaxWidth);
    });

    testWidgets('escape completes with false', (tester) async {
      final result = <bool>[];
      await tester.pumpWidget(_opener(result));
      await _open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(result, [false]);
      expect(find.byType(AppConfirmDialog), findsNothing);
    });

    testWidgets('tab reaches cancel first, then confirm', (tester) async {
      await tester.pumpWidget(_opener([]));
      await _open(tester);

      bool focusIn(Finder finder) {
        final focus = FocusManager.instance.primaryFocus?.context;
        if (focus == null) return false;
        return find
            .descendant(
              of: finder,
              matching: find.byElementPredicate((e) => e == focus),
            )
            .evaluate()
            .isNotEmpty;
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusIn(_cancel), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusIn(_confirm), isTrue);
    });

    testWidgets('show from a nested navigator uses the root navigator', (
      tester,
    ) async {
      final result = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: TextButton(
                  key: const Key('open'),
                  onPressed: () async => result.add(
                    await AppConfirmDialog.show(
                      context,
                      title: _title,
                      message: _message,
                      confirmLabel: 'Generate',
                      cancelLabel: 'Cancel',
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await _open(tester);

      await tester.tap(_confirm);
      await tester.pumpAndSettle();

      expect(result, [true]);
      expect(find.byType(AppConfirmDialog), findsNothing);
      expect(find.byKey(const Key('open')), findsOneWidget);
    });

    testWidgets('a second activation in the same frame pops only once', (
      tester,
    ) async {
      final result = <bool>[];
      await tester.pumpWidget(_opener(result));
      await _open(tester);

      final dialog = tester.widget<AppConfirmDialog>(
        find.byType(AppConfirmDialog),
      );
      dialog.onConfirm();
      dialog.onCancel();
      dialog.onConfirm();
      await tester.pumpAndSettle();

      expect(result, [true]);
      expect(find.byKey(const Key('open')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('semantics', () {
    testWidgets('the title is a heading and the buttons are named', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_dialog()));

      final title = tester.getSemantics(find.text(_title));
      expect(title.label, _title);
      expect(title.flagsCollection.isHeader, isTrue);
      for (final (finder, label) in [
        (_confirm, 'Generate'),
        (_cancel, 'Cancel'),
      ]) {
        final node = tester.getSemantics(
          find.descendant(of: finder, matching: find.byType(Text)),
        );
        expect(node.label, label);
        expect(node.flagsCollection.isButton, isTrue, reason: label);
      }
      handle.dispose();
    });

    testWidgets('the dialog is a route named by the title', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_dialog()));

      final nodes = semanticsNodes(tester);
      final scopes = nodes.where((node) => node.flagsCollection.scopesRoute);
      final names = nodes.where((node) => node.flagsCollection.namesRoute);
      expect(scopes, isNotEmpty);
      expect(names, hasLength(1));
      expect(names.single.label, _title);
      expect(names.single.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('the title is announced once', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_dialog()));

      expect(semanticsLabels(tester).where((l) => l == _title), hasLength(1));
      handle.dispose();
    });

    testWidgets('the buttons are read in the order cancel, confirm', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_dialog()));

      final labels = semanticsLabels(tester);
      expect(labels.indexOf('Cancel'), lessThan(labels.indexOf('Generate')));
      handle.dispose();
    });
  });

  group('large text', () {
    const long =
        'Your current code stops working as soon as the new one is ready. '
        'Share the new code with anyone who still needs to join your home.';

    for (final scale in [1.0, 2.0, 3.0]) {
      for (final (name, theme) in themes) {
        testWidgets('wraps without overflow at ${scale}x ($name)', (
          tester,
        ) async {
          await tester.pumpWidget(
            _host(
              _dialog(
                title:
                    'Generate a new personal code for the Maple Street flat?',
                message: long,
                destructive: true,
              ),
              theme: theme,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          for (final button in [_confirm, _cancel]) {
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            final rect = tester.getRect(button);
            final screen =
                tester.view.physicalSize / tester.view.devicePixelRatio;
            expect(
              rect.bottom,
              lessThanOrEqualTo(screen.height),
              reason: '$scale',
            );
          }
        });
      }
    }

    testWidgets('the buttons stack when they do not fit side by side', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_dialog(), textScale: 3));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(_confirm).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(_cancel).dy),
      );
    });
  });

  testWidgets('mirrors in right-to-left text', (tester) async {
    await tester.pumpWidget(_host(_dialog(), direction: TextDirection.rtl));

    expect(
      tester.getTopLeft(_cancel).dx,
      greaterThan(tester.getTopLeft(_confirm).dx),
    );
  });
}

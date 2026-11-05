import 'dart:io';

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {ThemeData? theme, double width = 360}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

Finder get _input => find.byType(TextField);

Finder _cell(int index) => find.byKey(Key('codeInput.digit.$index'));

/// The border of cell [index] as drawn.
BoxDecoration _decoration(WidgetTester tester, int index) {
  final box = find.descendant(
    of: _cell(index),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).border != null,
    ),
  );
  return tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
}

Color _borderColor(WidgetTester tester, int index) =>
    (_decoration(tester, index).border! as Border).top.color;

double _borderWidth(WidgetTester tester, int index) =>
    (_decoration(tester, index).border! as Border).top.width;

String _digit(WidgetTester tester, int index) => tester
    .widget<Text>(
      find.descendant(of: _cell(index), matching: find.byType(Text)),
    )
    .data!;

/// Whether cell [index] shows the focus ring and primary border.
bool _isActive(WidgetTester tester, int index) =>
    _borderColor(tester, index) == CompappTheme.light.colorScheme.primary;

String _text(WidgetTester tester) =>
    tester.widget<TextField>(_input).controller!.text;

/// Replaces the text of the field the way a paste or a suggestion does, with
/// the caret after the insertion.
void _insert(WidgetTester tester, String before, String after) {
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: after,
      selection: TextSelection.collapsed(offset: after.length),
    ),
  );
}

AppCodeInput _code({
  required ValueChanged<String> onCompleted,
  int length = 6,
  bool numeric = true,
  TextEditingController? controller,
  String? errorText,
  ValueChanged<String>? onChanged,
  bool autofocus = false,
}) {
  return AppCodeInput(
    label: 'Reset code',
    length: length,
    numeric: numeric,
    controller: controller,
    errorText: errorText,
    onChanged: onChanged,
    autofocus: autofocus,
    onCompleted: onCompleted,
  );
}

void main() {
  group('cells', () {
    testWidgets('draws one keyed cell per character of length', (tester) async {
      for (final length in [4, 6, 8]) {
        await tester.pumpWidget(
          _host(_code(length: length, onCompleted: (_) {})),
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'codeInput.digit.',
                ),
          ),
          findsNWidgets(length),
        );
        expect(_cell(length - 1), findsOneWidget);
        expect(_cell(length), findsNothing);
      }
    });

    testWidgets('cells are 60 tall and at most 56 wide, 8 apart', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {}), width: 400));

      expect(tester.getSize(_cell(0)), const Size(56, 60));
      expect(
        tester.getTopLeft(_cell(1)).dx - tester.getTopRight(_cell(0)).dx,
        AppSpacing.sm,
      );
    });

    testWidgets('cells shrink to fit a narrow column without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {}), width: 280));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_cell(0)).width, lessThan(56));
      expect(tester.getTopRight(_cell(5)).dx, lessThanOrEqualTo(24 + 280));
    });

    testWidgets('shows what was typed in the cells in order', (tester) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      await tester.enterText(_input, '481');
      await tester.pump();

      expect(
        [for (var i = 0; i < 6; i++) _digit(tester, i)],
        ['4', '8', '1', '', '', ''],
      );
    });
  });

  group('typing and auto-advance', () {
    testWidgets('the active cell follows the next empty one', (tester) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.tap(_input);
      await tester.pump();

      expect(_isActive(tester, 0), isTrue);

      await tester.enterText(_input, '4');
      await tester.pump();
      expect(_isActive(tester, 1), isTrue);
      expect(_isActive(tester, 0), isFalse);

      await tester.enterText(_input, '48');
      await tester.pump();
      expect(_isActive(tester, 2), isTrue);
    });

    testWidgets('the last cell stays active when the code is full', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.tap(_input);

      await tester.enterText(_input, '481592');
      await tester.pump();

      expect(_isActive(tester, 5), isTrue);
      expect(_isActive(tester, 4), isFalse);
    });

    testWidgets('no cell is active without focus', (tester) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      for (var i = 0; i < 6; i++) {
        expect(_isActive(tester, i), isFalse, reason: 'cell $i');
      }
    });

    testWidgets('digits only: other characters are dropped', (tester) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      await tester.enterText(_input, '4a8-1 x');
      await tester.pump();

      expect(tester.widget<TextField>(_input).controller!.text, '481');
    });

    testWidgets('onChanged reports every edit', (tester) async {
      final seen = <String>[];
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, onChanged: seen.add)),
      );

      await tester.enterText(_input, '4');
      await tester.enterText(_input, '48');

      expect(seen, ['4', '48']);
    });

    testWidgets('onCompleted fires when the last cell is filled', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));

      await tester.enterText(_input, '48159');
      expect(completed, isEmpty);

      await tester.enterText(_input, '481592');
      expect(completed, ['481592']);
    });

    testWidgets('onCompleted fires again after the code is edited and filled', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));

      await tester.enterText(_input, '481592');
      await tester.enterText(_input, '48159');
      await tester.enterText(_input, '481593');

      expect(completed, ['481592', '481593']);
    });

    testWidgets('respects a different length', (tester) async {
      final completed = <String>[];
      await tester.pumpWidget(
        _host(_code(length: 4, onCompleted: completed.add)),
      );

      await tester.enterText(_input, '48159');

      expect(completed, ['8159']);
      expect(tester.widget<TextField>(_input).controller!.text, '8159');
    });
  });

  group('paste', () {
    testWidgets('a pasted full code fills every cell and completes', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.tap(_input);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '481592',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.pump();

      expect(
        [for (var i = 0; i < 6; i++) _digit(tester, i)],
        ['4', '8', '1', '5', '9', '2'],
      );
      expect(completed, ['481592']);
    });

    testWidgets('a pasted code with separators keeps its digits', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.tap(_input);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '481 592',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      await tester.pump();

      expect(completed, ['481592']);
    });

    testWidgets('a pasted code that is too long keeps its last digits', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.tap(_input);

      _insert(tester, '', '48159200');
      await tester.pump();

      expect(completed, ['159200']);
      expect(_digit(tester, 5), '0');
    });

    testWidgets('a full code pasted into a partial field replaces it', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.tap(_input);
      await tester.enterText(_input, '48');

      _insert(tester, '48', '48123456');
      await tester.pump();

      expect(_text(tester), '123456');
      expect(completed, ['123456']);
    });

    testWidgets('a full code pasted into a full field replaces it', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.tap(_input);
      await tester.enterText(_input, '481592');
      completed.clear();

      _insert(tester, '481592', '481592735104');
      await tester.pump();

      expect(_text(tester), '735104');
      expect(completed, ['735104']);
    });

    testWidgets('an iOS suggestion inserted into a partial field wins', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.tap(_input);
      await tester.enterText(_input, '4');

      // The suggestion lands after what is typed.
      _insert(tester, '4', '4735104');
      await tester.pump();

      expect(_text(tester), '735104');
      expect(completed, ['735104']);
    });

    testWidgets('a suggestion that replaces the selection gives the code', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.tap(_input);
      await tester.enterText(_input, '481');

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '735104',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.pump();

      expect(_text(tester), '735104');
      expect(completed, ['735104']);
    });

    testWidgets('a short paste that fits is appended', (tester) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.tap(_input);
      await tester.enterText(_input, '48');

      _insert(tester, '48', '4815');
      await tester.pump();

      expect(_text(tester), '4815');
    });

    testWidgets('a paste into a partial field that does not fit is kept', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.tap(_input);
      await tester.enterText(_input, '48');

      _insert(tester, '48', '4815923');
      await tester.pump();

      expect(_text(tester), '15923');
    });

    testWidgets('a typed digit past the end is ignored', (tester) async {
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.tap(_input);
      await tester.enterText(_input, '481592');
      completed.clear();

      _insert(tester, '481592', '4815927');
      await tester.pump();

      expect(_text(tester), '481592');
      expect(completed, isEmpty);
    });

    testWidgets('a pasted code with separators in a full field keeps digits', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.tap(_input);
      await tester.enterText(_input, '481592');

      _insert(tester, '481592', '481592735 104');
      await tester.pump();

      expect(_text(tester), '735104');
    });

    testWidgets('a pasted partial code lands in the first cells', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.tap(_input);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '48',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();

      expect(_digit(tester, 0), '4');
      expect(_digit(tester, 1), '8');
      expect(_digit(tester, 2), '');
      expect(_isActive(tester, 2), isTrue);
    });
  });

  group('backspace', () {
    testWidgets('removes the last digit and moves back across cells', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.tap(_input);
      await tester.enterText(_input, '481');
      await tester.pump();
      expect(_isActive(tester, 3), isTrue);

      for (final (digits, active) in [('48', 2), ('4', 1), ('', 0)]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pump();

        expect(
          tester.widget<TextField>(_input).controller!.text,
          digits,
          reason: 'after backspace to "$digits"',
        );
        expect(_isActive(tester, active), isTrue, reason: 'cell $active');
        expect(_digit(tester, active), '', reason: 'cell $active is empty');
      }
    });

    testWidgets('backspace on a full code frees the last cell', (tester) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.tap(_input);
      await tester.enterText(_input, '481592');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(_digit(tester, 5), '');
      expect(_digit(tester, 4), '9');
      expect(_isActive(tester, 5), isTrue);
    });

    testWidgets('tapping a cell puts the caret back after the last digit', (
      tester,
    ) async {
      final controller = TextEditingController(text: '481');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.tap(_cell(1), warnIfMissed: false);
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(offset: 3));
    });
  });

  group('keyboard', () {
    testWidgets('is numeric for digits and shows no suggestions', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      final field = tester.widget<TextField>(_input);
      expect(field.keyboardType, TextInputType.number);
      expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
      expect(field.enableSuggestions, isFalse);
      expect(field.autocorrect, isFalse);
    });

    testWidgets('is a text keyboard in capitals for a non-numeric code', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_code(numeric: false, onCompleted: (_) {})),
      );

      final field = tester.widget<TextField>(_input);
      expect(field.keyboardType, TextInputType.text);
      expect(field.textCapitalization, TextCapitalization.characters);

      await tester.enterText(_input, 'a7-K');
      expect(
        tester.widget<TextField>(_input).controller!.text,
        'a7-K',
        reason: 'letters and symbols are kept when the code is not numeric',
      );
    });
  });

  group('controller and focus', () {
    testWidgets('shows a code held by an external controller', (tester) async {
      final controller = TextEditingController(text: '4815');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );

      expect(_digit(tester, 3), '5');

      controller.text = '48';
      await tester.pump();

      expect(_digit(tester, 3), '');
      expect(_digit(tester, 1), '8');
    });

    testWidgets('autofocus focuses the field and activates a cell', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, autofocus: true)),
      );
      await tester.pump();

      expect(_isActive(tester, 0), isTrue);
    });

    testWidgets('keeps a focus node given by the app', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          AppCodeInput(label: 'Code', focusNode: node, onCompleted: (_) {}),
        ),
      );

      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isTrue);
      expect(_isActive(tester, 0), isTrue);
    });

    testWidgets('the focused cell has the ring and a 2 px primary border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, autofocus: true)),
      );
      await tester.pump();

      expect(_borderWidth(tester, 0), AppSizes.borderEmphasis);
      expect(_borderWidth(tester, 1), AppSizes.hairline);
      final ring = find.descendant(
        of: _cell(0),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).border == null,
        ),
      );
      expect(
        tester.getRect(ring),
        tester.getRect(_cell(0)).inflate(AppSizes.focusRing),
      );
    });
  });

  group('look', () {
    for (final (name, theme) in [
      ('light', CompappTheme.light),
      ('dark', CompappTheme.dark),
    ]) {
      final scheme = theme.colorScheme;

      testWidgets('empty cells are sunken, filled ones are surfaces ($name)', (
        tester,
      ) async {
        final controller = TextEditingController(text: '48');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            _code(onCompleted: (_) {}, controller: controller),
            theme: theme,
          ),
        );

        expect(_decoration(tester, 0).color, scheme.surfaceContainerLowest);
        expect(_decoration(tester, 2).color, scheme.surfaceContainerHigh);
        expect(_borderColor(tester, 0), scheme.outline);
      });

      testWidgets('an error turns every border to the error color ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            _code(onCompleted: (_) {}, errorText: 'Not valid'),
            theme: theme,
          ),
        );

        for (var i = 0; i < 6; i++) {
          expect(_borderColor(tester, i), scheme.error, reason: 'cell $i');
          expect(_borderWidth(tester, i), AppSizes.borderEmphasis);
        }
        expect(
          tester.widget<Text>(find.text('Not valid')).style?.color,
          scheme.error,
        );
      });
    }

    testWidgets('on error the focused cell keeps a danger-soft ring', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _code(onCompleted: (_) {}, errorText: 'Not valid', autofocus: true),
        ),
      );
      await tester.pump();

      final scheme = CompappTheme.light.colorScheme;
      final ring = find.descendant(
        of: _cell(0),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  scheme.errorContainer,
        ),
      );
      expect(ring, findsOneWidget);
      expect(_borderColor(tester, 0), scheme.error);
    });

    testWidgets('digits use the headline style in ink', (tester) async {
      final controller = TextEditingController(text: '4');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );

      final style = tester
          .widget<Text>(
            find.descendant(of: _cell(0), matching: find.byType(Text)),
          )
          .style!;
      expect(style.fontSize, 28);
      expect(style.color, CompappTheme.light.colorScheme.onSurface);
    });

    testWidgets('the invisible field paints nothing', (tester) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: _input, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 0);
    });
  });

  group('semantics', () {
    testWidgets('is one text field node named by the label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      final node = tester.getSemantics(_input);
      expect(
        node,
        isSemantics(label: 'Reset code', isTextField: true, isEnabled: true),
      );
      expect(node.hasChildren, isFalse);
      handle.dispose();
    });

    testWidgets('the value is spelled out, not read as a number', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      expect(tester.getSemantics(_input).attributedValue.attributes, isEmpty);

      await tester.enterText(_input, '481592');
      await tester.pump();

      final value = tester.getSemantics(_input).attributedValue;
      expect(value.string, '481592');
      expect(value.attributes, hasLength(1));
      final spell = value.attributes.single as SpellOutStringAttribute;
      expect(spell.range, const TextRange(start: 0, end: 6));
      handle.dispose();
    });

    testWidgets('the node says how long the code can be and is', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_code(length: 4, onCompleted: (_) {})));
      await tester.enterText(_input, '48');
      await tester.pump();

      final node = tester.getSemantics(_input);
      expect(node.maxValueLength, 4);
      expect(node.currentValueLength, 2);
      handle.dispose();
    });

    testWidgets('activating the node focuses the field', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      expect(_isActive(tester, 0), isFalse);

      tester.semantics.tap(find.semantics.byLabel('Reset code'));
      await tester.pump();

      expect(_isActive(tester, 0), isTrue);
      handle.dispose();
    });

    testWidgets('its value is the code entered so far', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      await tester.enterText(_input, '481');
      await tester.pump();

      expect(
        tester.getSemantics(_input),
        isSemantics(label: 'Reset code', value: '481', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('the cells add no semantics nodes of their own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: '481592');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );

      for (var i = 0; i < 6; i++) {
        expect(find.bySemanticsLabel(_digit(tester, i)), findsNothing);
      }
      var nodes = 0;
      void visit(SemanticsNode node) {
        if (node.label.isNotEmpty || node.value.isNotEmpty) nodes++;
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(tester.getSemantics(find.byType(AppCodeInput)));
      expect(nodes, 1);
      handle.dispose();
    });

    testWidgets('the error marks the field invalid and is a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, errorText: 'That code is not valid')),
      );

      expect(
        tester.getSemantics(find.text('That code is not valid')),
        isSemantics(label: 'That code is not valid', isLiveRegion: true),
      );
      expect(
        tester.getSemantics(_input),
        isSemantics(
          isTextField: true,
          validationResult: SemanticsValidationResult.invalid,
        ),
      );
      handle.dispose();
    });

    testWidgets('a valid code is not marked invalid', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      expect(
        tester.getSemantics(_input),
        isSemantics(
          isTextField: true,
          validationResult: SemanticsValidationResult.none,
        ),
      );
      handle.dispose();
    });
  });

  group('semantic actions', () {
    void mockClipboard(WidgetTester tester, String? text) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData' && text != null
            ? <String, dynamic>{'text': text}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    testWidgets('set text goes through the formatter and completes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final completed = <String>[];
      final changes = <String>[];
      await tester.pumpWidget(
        _host(_code(onCompleted: completed.add, onChanged: changes.add)),
      );

      tester.semantics.performAction(
        find.semantics.byLabel('Reset code'),
        SemanticsAction.setText,
        args: '73 5104',
      );
      await tester.pump();

      expect(_text(tester), '735104');
      expect(changes, ['735104']);
      expect(completed, ['735104']);
      expect([for (var i = 0; i < 6; i++) _digit(tester, i)].join(), '735104');
      handle.dispose();
    });

    testWidgets('set text replaces a partial code and cuts a long one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
      await tester.enterText(_input, '48');

      tester.semantics.performAction(
        find.semantics.byLabel('Reset code'),
        SemanticsAction.setText,
        args: '1234567890',
      );
      await tester.pump();

      expect(_text(tester), '567890');
      handle.dispose();
    });

    testWidgets('paste appends the clipboard through the formatter', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      mockClipboard(tester, '735104');
      final completed = <String>[];
      await tester.pumpWidget(_host(_code(onCompleted: completed.add)));
      await tester.enterText(_input, '48');

      tester.semantics.performAction(
        find.semantics.byLabel('Reset code'),
        SemanticsAction.paste,
      );
      await tester.pumpAndSettle();

      expect(_text(tester), '735104', reason: 'a full code replaces a partial');
      expect(completed, ['735104']);
      handle.dispose();
    });

    testWidgets(
      'paste of a short code appends it, and no clipboard is a no-op',
      (tester) async {
        final handle = tester.ensureSemantics();
        mockClipboard(tester, '15');
        await tester.pumpWidget(_host(_code(onCompleted: (_) {})));
        await tester.enterText(_input, '48');

        tester.semantics.performAction(
          find.semantics.byLabel('Reset code'),
          SemanticsAction.paste,
        );
        await tester.pumpAndSettle();
        expect(_text(tester), '4815');

        mockClipboard(tester, null);
        tester.semantics.performAction(
          find.semantics.byLabel('Reset code'),
          SemanticsAction.paste,
        );
        await tester.pumpAndSettle();
        expect(_text(tester), '4815');
        handle.dispose();
      },
    );

    testWidgets('the node is its own node inside a labeled group', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Semantics(
            container: true,
            label: 'Verify your email',
            child: _code(onCompleted: (_) {}),
          ),
        ),
      );

      expect(tester.getSemantics(_input).label, 'Reset code');
      expect(find.bySemanticsLabel('Verify your email'), findsOneWidget);
      handle.dispose();
    });
  });

  group('composing', () {
    testWidgets('a composing region of an unchanged text is kept', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );
      await tester.tap(_input);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '48',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        ),
      );
      await tester.pump();

      expect(controller.text, '48');
      expect(controller.value.composing, const TextRange(start: 0, end: 2));
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    testWidgets('the caret is clamped but the composing region stays', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );
      await tester.tap(_input);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '481',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 1, end: 3),
        ),
      );
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(offset: 3));
      expect(controller.value.composing, const TextRange(start: 1, end: 3));
    });

    testWidgets('a composing region is dropped when the text is rewritten', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );
      await tester.tap(_input);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '4a8',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 0, end: 3),
        ),
      );
      await tester.pump();

      expect(controller.text, '48');
      expect(controller.value.composing, TextRange.empty);
    });
  });

  group('caret', () {
    testWidgets('arrow keys never move the caret inside the code', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );
      await tester.tap(_input);
      await tester.enterText(_input, '481');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(offset: 3));

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(controller.text, '48', reason: 'backspace still edits the end');
    });

    testWidgets('select all cannot leave a range selected', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(onCompleted: (_) {}, controller: controller)),
      );
      await tester.tap(_input);
      await tester.enterText(_input, '481');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(controller.selection.isCollapsed, isTrue);
    });
  });

  group('length', () {
    testWidgets('shrinking it truncates the code and tells the app', (
      tester,
    ) async {
      final controller = TextEditingController(text: '481592');
      addTearDown(controller.dispose);
      final changes = <String>[];
      final completed = <String>[];
      Widget build(int length) => _host(
        _code(
          length: length,
          controller: controller,
          onCompleted: completed.add,
          onChanged: changes.add,
        ),
      );

      await tester.pumpWidget(build(6));
      await tester.pumpWidget(build(4));
      await tester.pump();

      expect(controller.text, '4815');
      expect(changes, ['4815']);
      expect(completed, ['4815'], reason: 'the truncated code is complete');
      expect(_cell(3), findsOneWidget);
      expect(_cell(4), findsNothing);
    });

    testWidgets('shows only the first cells while the value catches up', (
      tester,
    ) async {
      final controller = TextEditingController(text: '481592');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(_code(length: 4, controller: controller, onCompleted: (_) {})),
      );

      expect(
        [for (var i = 0; i < 4; i++) _digit(tester, i)],
        ['4', '8', '1', '5'],
      );
    });

    testWidgets('a code that becomes complete by a shorter length completes', (
      tester,
    ) async {
      final controller = TextEditingController(text: '4815');
      addTearDown(controller.dispose);
      final completed = <String>[];
      final changes = <String>[];
      Widget build(int length) => _host(
        _code(
          length: length,
          controller: controller,
          onCompleted: completed.add,
          onChanged: changes.add,
        ),
      );

      await tester.pumpWidget(build(6));
      expect(completed, isEmpty);
      await tester.pumpWidget(build(4));
      await tester.pump();

      expect(completed, ['4815']);
      expect(changes, isEmpty, reason: 'nothing was truncated');
      expect(controller.text, '4815');
    });

    testWidgets('an empty code never completes by a length change', (
      tester,
    ) async {
      final completed = <String>[];
      Widget build(int length) =>
          _host(_code(length: length, onCompleted: completed.add));

      await tester.pumpWidget(build(6));
      await tester.pumpWidget(build(4));
      await tester.pump();

      expect(completed, isEmpty);
    });

    testWidgets('growing it keeps the code', (tester) async {
      final controller = TextEditingController(text: '4815');
      addTearDown(controller.dispose);
      Widget build(int length) => _host(
        _code(length: length, controller: controller, onCompleted: (_) {}),
      );

      await tester.pumpWidget(build(4));
      await tester.pumpWidget(build(6));
      await tester.pump();

      expect(controller.text, '4815');
      expect(_cell(5), findsOneWidget);
    });
  });

  group('large text', () {
    setUpAll(() async {
      // The real digits: without the bundled font a test draws every glyph
      // as a solid em square, which proves nothing about the fit.
      final bytes = File('fonts/BricolageGrotesque-Variable.ttf')
          .readAsBytesSync();
      final loader = FontLoader('packages/compapp_design/Bricolage Grotesque')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    });

    Future<void> pumpAt(
      WidgetTester tester,
      double scale, {
      required double width,
      String code = '481592',
    }) async {
      final controller = TextEditingController(text: code);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: app!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: _code(onCompleted: (_) {}, controller: controller),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('a digit and its line fit in the cell at every text scale', (
      tester,
    ) async {
      for (final width in [400.0, 360.0 - AppSpacing.lg * 2]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          await pumpAt(tester, scale, width: width);

          for (var i = 0; i < 6; i++) {
            final cell = tester.getRect(_cell(i));
            final digit = tester.getRect(
              find.descendant(of: _cell(i), matching: find.byType(Text)),
            );
            final reason = 'cell $i at ${scale}x in $width';
            // The painted line, and the glyph inside it, are not cut off.
            expect(
              digit.top - cell.top,
              greaterThanOrEqualTo(AppSpacing.sm - 0.01),
              reason: '$reason: room above the line',
            );
            expect(
              cell.bottom - digit.bottom,
              greaterThanOrEqualTo(AppSpacing.sm - 0.01),
              reason: '$reason: room below the line',
            );
            expect(
              digit.left - cell.left,
              greaterThanOrEqualTo(AppSpacing.xs - 0.01),
              reason: '$reason: room on the left',
            );
            expect(
              cell.right - digit.right,
              greaterThanOrEqualTo(AppSpacing.xs - 0.01),
              reason: '$reason: room on the right',
            );
          }
        }
      }
    });

    testWidgets('the cells grow with the text and stay equal and aligned', (
      tester,
    ) async {
      await pumpAt(tester, 1, width: 400, code: '48');
      expect(tester.getSize(_cell(0)).height, AppSizes.codeCellHeight);

      await pumpAt(tester, 2, width: 400, code: '48');
      final heights = {
        for (var i = 0; i < 6; i++) tester.getSize(_cell(i)).height,
      };
      expect(heights, hasLength(1), reason: 'filled and empty cells match');
      expect(heights.single, greaterThan(AppSizes.codeCellHeight));
      final tops = {for (var i = 0; i < 6; i++) tester.getTopLeft(_cell(i)).dy};
      expect(tops, hasLength(1));
    });

    testWidgets('nothing around the digit clips it', (tester) async {
      await pumpAt(tester, 2, width: 400);

      expect(
        find.descendant(
          of: find.byType(AppCodeInput),
          matching: find.byType(ClipRect),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the field still covers every cell when they grow', (
      tester,
    ) async {
      await pumpAt(tester, 2, width: 400);

      final cells = tester
          .getRect(_cell(0))
          .expandToInclude(tester.getRect(_cell(5)));
      expect(tester.getRect(_input), cells);
    });
  });

  group('swapping the controller and the focus node', () {
    testWidgets('a given controller can become the own one and back', (
      tester,
    ) async {
      final given = TextEditingController(text: '481');
      addTearDown(given.dispose);
      Widget build(TextEditingController? controller) =>
          _host(_code(onCompleted: (_) {}, controller: controller));

      await tester.pumpWidget(build(given));
      await tester.pumpWidget(build(null));

      expect(tester.takeException(), isNull);
      expect(
        _digit(tester, 2),
        '1',
        reason: 'the own controller took the code',
      );
      await tester.enterText(_input, '4815');
      await tester.pump();
      expect(_digit(tester, 3), '5');
      expect(given.text, '481', reason: 'the given controller is let go');

      given.text = '73';
      await tester.pumpWidget(build(given));
      expect(_digit(tester, 0), '7');
      expect(_digit(tester, 2), '');
      await tester.enterText(_input, '730');
      await tester.pump();
      expect(given.text, '730', reason: 'typing now goes to the given one');
    });

    testWidgets('one given controller can replace another', (tester) async {
      final first = TextEditingController(text: '48');
      final second = TextEditingController(text: '73');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      Widget build(TextEditingController controller) =>
          _host(_code(onCompleted: (_) {}, controller: controller));

      await tester.pumpWidget(build(first));
      await tester.pumpWidget(build(second));

      expect(_digit(tester, 0), '7');
      second.text = '7351';
      await tester.pump();
      expect(_digit(tester, 3), '1');
      first.text = '999999';
      await tester.pump();
      expect(_digit(tester, 3), '1', reason: 'the old controller is ignored');
    });

    testWidgets('a given focus node can become the own one and back', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      Widget build(FocusNode? focusNode) => _host(
        AppCodeInput(label: 'Code', focusNode: focusNode, onCompleted: (_) {}),
      );

      await tester.pumpWidget(build(node));
      await tester.pumpWidget(build(null));
      await tester.tap(_input);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(node.hasFocus, isFalse);
      expect(_isActive(tester, 0), isTrue, reason: 'its own node drives it');

      await tester.pumpWidget(build(node));
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(_isActive(tester, 0), isTrue, reason: 'the given node drives it');
    });
  });

  group('layout', () {
    testWidgets('the hidden field is single-line', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_code(onCompleted: (_) {})));

      expect(tester.widget<TextField>(_input).maxLines, 1);
      expect(tester.widget<TextField>(_input).expands, isFalse);
      expect(
        tester.getSemantics(_input),
        isSemantics(isTextField: true, isMultiline: false),
      );
      handle.dispose();
    });

    testWidgets('the field fills the cells, so a tap anywhere focuses it', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_code(onCompleted: (_) {}), width: 400));

      final cells = tester
          .getRect(_cell(0))
          .expandToInclude(tester.getRect(_cell(5)));
      expect(tester.getRect(_input), cells);

      await tester.tapAt(tester.getBottomLeft(_cell(2)) + const Offset(2, -2));
      await tester.pump();
      expect(_isActive(tester, 0), isTrue);
    });

    testWidgets('cells run left to right in right-to-left text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          locale: const Locale('ar'),
          builder: (context, app) =>
              Directionality(textDirection: TextDirection.rtl, child: app!),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 400, child: _code(onCompleted: (_) {})),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(_cell(0)).dx,
        lessThan(tester.getTopLeft(_cell(1)).dx),
      );
      expect(
        tester.getTopLeft(_cell(4)).dx,
        lessThan(tester.getTopLeft(_cell(5)).dx),
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(of: _cell(0), matching: find.byType(Text)),
            )
            .data,
        '',
      );
    });

    testWidgets('the digits are filled left to right in right-to-left text', (
      tester,
    ) async {
      final controller = TextEditingController(text: '48');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          builder: (context, app) =>
              Directionality(textDirection: TextDirection.rtl, child: app!),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: _code(onCompleted: (_) {}, controller: controller),
              ),
            ),
          ),
        ),
      );

      expect(_digit(tester, 0), '4');
      expect(
        tester.getCenter(_cell(0)).dx,
        lessThan(tester.getCenter(_cell(1)).dx),
      );
    });

    testWidgets('works inside a Row with no width limit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          home: Scaffold(
            body: Row(children: [_code(onCompleted: (_) {})]),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_cell(0)), const Size(56, 60));
    });
  });

  testWidgets('a length below one is rejected', (tester) async {
    expect(
      () => AppCodeInput(label: 'Code', length: 0, onCompleted: (_) {}),
      throwsAssertionError,
    );
  });
}

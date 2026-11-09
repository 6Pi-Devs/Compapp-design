import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

AppTextField _field(
  TextEditingController controller, {
  String? hint,
  String? helperText,
  String? errorText,
  bool obscure = false,
  String? reveal,
  String? conceal,
  bool enabled = true,
  bool autofocus = false,
  ValueChanged<String>? onChanged,
  TextInputType? keyboardType,
  bool? autocorrect,
  bool? enableSuggestions,
  TextCapitalization textCapitalization = TextCapitalization.none,
  bool readOnly = false,
}) {
  return AppTextField(
    label: 'Email',
    controller: controller,
    hint: hint,
    helperText: helperText,
    errorText: errorText,
    obscure: obscure,
    revealSemanticLabel: reveal,
    concealSemanticLabel: conceal,
    enabled: enabled,
    autofocus: autofocus,
    onChanged: onChanged,
    keyboardType: keyboardType,
    autocorrect: autocorrect,
    enableSuggestions: enableSuggestions,
    textCapitalization: textCapitalization,
    readOnly: readOnly,
  );
}

Finder get _input => find.byType(TextField);

/// A focus node that counts the listeners it has right now.
class _CountingNode extends FocusNode {
  int listeners = 0;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }
}

/// A focus node that reports focus without having it.
class _FocusedNode extends FocusNode {
  @override
  bool get hasFocus => true;
}

const _boundaryKey = Key('field-boundary');

Widget _hostBoundary(Widget child, {ThemeData? theme}) => _host(
  RepaintBoundary(key: _boundaryKey, child: child),
  theme: theme,
);

/// The color the text of the field is really painted with, read from the
/// rendered pixels. flutter_test draws text with its FlutterTest font, whose
/// glyphs are solid squares, so a pixel inside the first character is the
/// text color.
Future<Color> _paintedTextColor(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  final field = tester.getRect(_input);
  final origin = tester.getTopLeft(find.byKey(_boundaryKey));
  final point =
      Offset(field.left + AppSpacing.md + 4, field.center.dy) - origin;
  final color = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    final offset = (point.dy.round() * image.width + point.dx.round()) * 4;
    return Color.fromARGB(
      data.getUint8(offset + 3),
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
    );
  });
  return color!;
}

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  group('layout', () {
    testWidgets('the input box is 52 tall in every state', (tester) async {
      for (final (errorText, enabled, helper) in [
        (null, true, null),
        ('Enter a full email address', true, null),
        (null, false, null),
        (null, true, 'We never share it'),
      ]) {
        await tester.pumpWidget(
          _host(
            _field(
              controller,
              errorText: errorText,
              enabled: enabled,
              helperText: helper,
            ),
          ),
        );

        expect(
          tester.getSize(_input).height,
          AppSizes.controlLg,
          reason: '$errorText $enabled $helper',
        );
      }
    });

    testWidgets('shows the label above the field and the message below', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_field(controller, helperText: 'We never share it')),
      );

      expect(
        tester.getBottomLeft(find.text('Email')).dy,
        lessThanOrEqualTo(tester.getTopLeft(_input).dy),
      );
      expect(
        tester.getTopLeft(find.text('We never share it')).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(_input).dy),
      );
    });

    testWidgets('an error replaces the helper text', (tester) async {
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            helperText: 'We never share it',
            errorText: 'Enter a full email address',
          ),
        ),
      );

      expect(find.text('We never share it'), findsNothing);
      expect(find.text('Enter a full email address'), findsOneWidget);
    });

    testWidgets('lays out at 2x text in a narrow column', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: app!,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: _field(
                controller,
                hint: 'name@example.com',
                errorText: 'Enter a full email address',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('look', () {
    for (final (name, theme) in [
      ('light', CompappTheme.light),
      ('dark', CompappTheme.dark),
    ]) {
      final scheme = theme.colorScheme;

      testWidgets('an error turns the border to the error color ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(_field(controller, errorText: 'Nope'), theme: theme),
        );

        final decoration = tester.widget<TextField>(_input).decoration!;
        final error = decoration.enabledBorder! as OutlineInputBorder;
        final focusedError = decoration.focusedBorder! as OutlineInputBorder;
        expect(error.borderSide.color, scheme.error);
        expect(error.borderSide.width, AppSizes.borderEmphasis);
        expect(focusedError.borderSide.color, scheme.error);
      });

      testWidgets('without an error the theme borders apply ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(_host(_field(controller), theme: theme));

        final decoration = tester.widget<TextField>(_input).decoration!;
        expect(decoration.enabledBorder, isNull);
        expect(decoration.focusedBorder, isNull);
      });

      testWidgets('the error text is the error color ($name)', (tester) async {
        await tester.pumpWidget(
          _host(_field(controller, errorText: 'Nope'), theme: theme),
        );

        expect(
          tester.widget<Text>(find.text('Nope')).style?.color,
          scheme.error,
        );
      });

      testWidgets('the helper text is muted ($name)', (tester) async {
        await tester.pumpWidget(
          _host(_field(controller, helperText: 'Hi'), theme: theme),
        );

        expect(
          tester.widget<Text>(find.text('Hi')).style?.color,
          scheme.onSurfaceVariant,
        );
      });

      testWidgets('disabled mutes the label and the text ($name)', (
        tester,
      ) async {
        controller.text = 'ana@compapp.test';
        await tester.pumpWidget(
          _host(_field(controller, enabled: false), theme: theme),
        );

        expect(
          tester.widget<Text>(find.text('Email')).style?.color,
          scheme.onSurfaceVariant,
        );
        expect(
          tester.widget<TextField>(_input).style?.color,
          scheme.onSurfaceVariant,
        );
      });
    }

    for (final (name, theme) in [
      ('light', CompappTheme.light),
      ('dark', CompappTheme.dark),
    ]) {
      final scheme = theme.colorScheme;

      testWidgets('the typed text is really painted in ink ($name)', (
        tester,
      ) async {
        controller.text = 'ana@compapp.test';
        await tester.pumpWidget(
          _hostBoundary(_field(controller), theme: theme),
        );

        expect(
          await _paintedTextColor(tester),
          isSameColorAs(scheme.onSurface),
        );
      });

      testWidgets('the disabled text is really painted muted ($name)', (
        tester,
      ) async {
        controller.text = 'ana@compapp.test';
        await tester.pumpWidget(
          _hostBoundary(_field(controller, enabled: false), theme: theme),
        );

        expect(
          await _paintedTextColor(tester),
          isSameColorAs(scheme.onSurfaceVariant),
        );
      });
    }

    testWidgets('uses the body style for the text', (tester) async {
      await tester.pumpWidget(_host(_field(controller)));

      expect(tester.widget<TextField>(_input).style?.fontSize, 15);
    });
  });

  group('focus ring', () {
    Finder ring() => find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color ==
              CompappTheme.light.colorScheme.primaryContainer &&
          (widget.decoration as BoxDecoration).borderRadius != null,
    );

    testWidgets('appears around the field while focused', (tester) async {
      await tester.pumpWidget(_host(_field(controller)));
      expect(ring(), findsNothing);

      await tester.tap(_input);
      await tester.pump();

      expect(ring(), findsOneWidget);
      final field = tester.getRect(_input);
      final band = tester.getRect(ring());
      expect(band, field.inflate(AppSizes.focusRing));
    });

    testWidgets('is danger-soft around an error, with the red border', (
      tester,
    ) async {
      final node = _FocusedNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          AppTextField(
            label: 'Email',
            controller: controller,
            focusNode: node,
            errorText: 'Nope',
          ),
        ),
      );

      final ringBox = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                CompappTheme.light.colorScheme.errorContainer,
      );
      expect(ringBox, findsOneWidget);
      final decoration = tester.widget<TextField>(_input).decoration!;
      expect(
        (decoration.focusedBorder! as OutlineInputBorder).borderSide.color,
        CompappTheme.light.colorScheme.error,
      );
    });

    testWidgets('leaves a gap between the ring and the message', (
      tester,
    ) async {
      final node = _FocusedNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          AppTextField(
            label: 'Email',
            controller: controller,
            focusNode: node,
            helperText: 'We never share it',
          ),
        ),
      );

      final gap =
          tester.getTopLeft(find.text('We never share it')).dy -
          tester.getRect(_input).inflate(AppSizes.focusRing).bottom;
      expect(gap, greaterThanOrEqualTo(AppSpacing.xs));
    });

    testWidgets('goes away on blur', (tester) async {
      await tester.pumpWidget(_host(_field(controller, autofocus: true)));
      await tester.pump();
      expect(ring(), findsOneWidget);

      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();

      expect(ring(), findsNothing);
    });

    testWidgets('does not show on a disabled field', (tester) async {
      final node = _FocusedNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          AppTextField(
            label: 'Email',
            controller: controller,
            focusNode: node,
            enabled: false,
          ),
        ),
      );
      await tester.pump();

      expect(node.hasFocus, isTrue, reason: 'the node claims focus');
      expect(ring(), findsNothing);
    });

    testWidgets('does not change the layout', (tester) async {
      await tester.pumpWidget(_host(_field(controller)));
      final before = tester.getRect(_input);

      await tester.tap(_input);
      await tester.pump();

      expect(tester.getRect(_input), before);
    });
  });

  group('input', () {
    testWidgets('reports changes and keeps the controller text', (
      tester,
    ) async {
      final seen = <String>[];
      await tester.pumpWidget(_host(_field(controller, onChanged: seen.add)));

      await tester.enterText(_input, 'ana@compapp.test');

      expect(seen, ['ana@compapp.test']);
      expect(controller.text, 'ana@compapp.test');
    });

    testWidgets('passes the keyboard type through', (tester) async {
      await tester.pumpWidget(
        _host(_field(controller, keyboardType: TextInputType.emailAddress)),
      );

      expect(
        tester.widget<TextField>(_input).keyboardType,
        TextInputType.emailAddress,
      );
    });

    testWidgets('a disabled field takes no input', (tester) async {
      await tester.pumpWidget(_host(_field(controller, enabled: false)));

      expect(tester.widget<TextField>(_input).enabled, isFalse);
    });

    testWidgets('shows the hint', (tester) async {
      await tester.pumpWidget(
        _host(_field(controller, hint: 'name@example.com')),
      );

      expect(find.text('name@example.com'), findsOneWidget);
    });

    testWidgets('keeps a focus node given by the app', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          AppTextField(label: 'Email', controller: controller, focusNode: node),
        ),
      );

      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isTrue);
      expect(tester.widget<TextField>(_input).focusNode, node);
    });

    testWidgets('moves its focus listener to a new node and drops the old', (
      tester,
    ) async {
      final first = _CountingNode();
      final second = _CountingNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      Widget build(FocusNode? node) => _host(
        AppTextField(label: 'Email', controller: controller, focusNode: node),
      );
      Finder ring() => find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                CompappTheme.light.colorScheme.primaryContainer,
      );

      await tester.pumpWidget(build(first));
      await tester.pumpWidget(build(second));

      expect(first.listeners, 0, reason: 'the old node is let go');
      expect(second.listeners, greaterThan(0), reason: 'the new one is used');

      second.requestFocus();
      await tester.pumpAndSettle();
      expect(ring(), findsOneWidget, reason: 'the new node drives the ring');

      second.unfocus();
      await tester.pumpAndSettle();
      expect(ring(), findsNothing, reason: 'and takes it away on blur');
    });

    testWidgets('swaps between a given node and its own', (tester) async {
      final node = _CountingNode();
      addTearDown(node.dispose);
      Widget build(FocusNode? given) => _host(
        AppTextField(label: 'Email', controller: controller, focusNode: given),
      );
      Finder ring() => find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                CompappTheme.light.colorScheme.primaryContainer,
      );

      await tester.pumpWidget(build(node));
      await tester.pumpWidget(build(null));
      expect(node.listeners, 0);

      await tester.tap(_input);
      await tester.pump();
      expect(ring(), findsOneWidget, reason: 'its own node drives the ring');

      await tester.pumpWidget(build(node));
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(ring(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('obscure', () {
    testWidgets('hides the text without a toggle by default', (tester) async {
      await tester.pumpWidget(_host(_field(controller, obscure: true)));

      expect(tester.widget<TextField>(_input).obscureText, isTrue);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('turns off suggestions and autocorrect', (tester) async {
      await tester.pumpWidget(_host(_field(controller, obscure: true)));

      final field = tester.widget<TextField>(_input);
      expect(field.enableSuggestions, isFalse);
      expect(field.autocorrect, isFalse);
    });

    testWidgets('needs both labels to show the toggle', (tester) async {
      await tester.pumpWidget(
        _host(_field(controller, obscure: true, reveal: 'Show password')),
      );

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('the toggle reveals and hides, named by its next action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            obscure: true,
            reveal: 'Show password',
            conceal: 'Hide password',
          ),
        ),
      );

      String? toggleName() =>
          tester.getSemantics(find.byType(IconButton)).tooltip;
      expect(toggleName(), 'Show password');

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tester.widget<TextField>(_input).obscureText, isFalse);
      expect(toggleName(), 'Hide password');
      expect(
        tester.getSemantics(find.byType(IconButton)),
        isSemantics(
          tooltip: 'Hide password',
          isButton: true,
          hasSelectedState: false,
          isSelected: false,
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tester.widget<TextField>(_input).obscureText, isTrue);
      handle.dispose();
    });

    testWidgets('the toggle is a 48 hit area and shows the eye glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            obscure: true,
            reveal: 'Show password',
            conceal: 'Hide password',
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(IconButton)).shortestSide,
        greaterThanOrEqualTo(AppSizes.minTarget),
      );
      expect(tester.widget<AppIcon>(find.byType(AppIcon)).icon, AppIcons.show);
    });

    testWidgets('a disabled field cannot be revealed', (tester) async {
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            obscure: true,
            reveal: 'Show password',
            conceal: 'Hide password',
            enabled: false,
          ),
        ),
      );

      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
    });
  });

  group('typing aids', () {
    Future<TextField> pumpField(
      WidgetTester tester, {
      TextInputType? keyboardType,
      bool obscure = false,
      bool? autocorrect,
      bool? enableSuggestions,
    }) async {
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            keyboardType: keyboardType,
            obscure: obscure,
            autocorrect: autocorrect,
            enableSuggestions: enableSuggestions,
          ),
        ),
      );
      return tester.widget<TextField>(_input);
    }

    testWidgets('plain text keeps autocorrect, suggestions and smart typing', (
      tester,
    ) async {
      final field = await pumpField(tester);

      expect(field.autocorrect, isTrue);
      expect(field.enableSuggestions, isTrue);
      expect(field.smartQuotesType, SmartQuotesType.enabled);
      expect(field.smartDashesType, SmartDashesType.enabled);
    });

    testWidgets('an email field turns off autocorrect and smart typing', (
      tester,
    ) async {
      final field = await pumpField(
        tester,
        keyboardType: TextInputType.emailAddress,
      );

      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isTrue);
      expect(field.smartQuotesType, SmartQuotesType.disabled);
      expect(field.smartDashesType, SmartDashesType.disabled);
    });

    testWidgets('a url field turns off autocorrect and smart typing', (
      tester,
    ) async {
      final field = await pumpField(tester, keyboardType: TextInputType.url);

      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isTrue);
      expect(field.smartQuotesType, SmartQuotesType.disabled);
      expect(field.smartDashesType, SmartDashesType.disabled);
    });

    testWidgets('other keyboards keep autocorrect', (tester) async {
      final field = await pumpField(tester, keyboardType: TextInputType.number);

      expect(field.autocorrect, isTrue);
    });

    testWidgets('an obscure field turns off both', (tester) async {
      final field = await pumpField(tester, obscure: true);

      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
    });

    testWidgets('a revealed password keeps smart typing off', (tester) async {
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            obscure: true,
            reveal: 'Show password',
            conceal: 'Hide password',
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      final field = tester.widget<TextField>(_input);
      expect(field.obscureText, isFalse);
      expect(field.smartQuotesType, SmartQuotesType.disabled);
      expect(field.smartDashesType, SmartDashesType.disabled);
    });

    testWidgets('an override wins over the keyboard default', (tester) async {
      final field = await pumpField(
        tester,
        keyboardType: TextInputType.emailAddress,
        autocorrect: true,
        enableSuggestions: false,
      );

      expect(field.autocorrect, isTrue);
      expect(field.enableSuggestions, isFalse);
    });

    testWidgets('an override wins over the obscure default', (tester) async {
      final field = await pumpField(
        tester,
        obscure: true,
        autocorrect: true,
        enableSuggestions: true,
      );

      expect(field.autocorrect, isTrue);
      expect(field.enableSuggestions, isTrue);
    });

    testWidgets('false overrides a plain field', (tester) async {
      final field = await pumpField(
        tester,
        autocorrect: false,
        enableSuggestions: false,
      );

      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
    });
  });

  group('text capitalization', () {
    TextCapitalization capitalizationOf(WidgetTester tester) =>
        tester.widget<TextField>(_input).textCapitalization;

    testWidgets('is none by default', (tester) async {
      await tester.pumpWidget(
        _host(AppTextField(label: 'Name', controller: controller)),
      );

      expect(capitalizationOf(tester), TextCapitalization.none);
    });

    testWidgets('passes an explicit value to the TextField', (tester) async {
      await tester.pumpWidget(
        _host(_field(controller, textCapitalization: TextCapitalization.words)),
      );

      expect(capitalizationOf(tester), TextCapitalization.words);
    });

    testWidgets('still applies to an obscure field', (tester) async {
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            obscure: true,
            textCapitalization: TextCapitalization.characters,
          ),
        ),
      );

      final field = tester.widget<TextField>(_input);
      expect(field.obscureText, isTrue);
      expect(field.textCapitalization, TextCapitalization.characters);
    });
  });

  group('read only', () {
    testWidgets('is off by default', (tester) async {
      await tester.pumpWidget(
        _host(AppTextField(label: 'Email', controller: controller)),
      );

      expect(tester.widget<TextField>(_input).readOnly, isFalse);
    });

    testWidgets('refuses edits but keeps the enabled look and focus', (
      tester,
    ) async {
      controller.text = 'ana@compapp.test';
      await tester.pumpWidget(_host(_field(controller, readOnly: true)));

      final field = tester.widget<TextField>(_input);
      expect(field.readOnly, isTrue);
      expect(field.enabled, isTrue);

      await tester.tap(_input);
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.enterText(_input, 'other');
      expect(controller.text, 'ana@compapp.test');
    });

    testWidgets('closes the keyboard until the field is editable again', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_field(controller, readOnly: true)));

      await tester.tap(_input);
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isFalse);

      await tester.pumpWidget(_host(_field(controller)));
      await tester.pump();

      expect(editable.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
    });

    testWidgets('together with disabled, the field is disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      controller.text = 'ana@compapp.test';
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            obscure: true,
            reveal: 'Show password',
            conceal: 'Hide password',
            readOnly: true,
            enabled: false,
          ),
        ),
      );
      final scheme = CompappTheme.light.colorScheme;

      expect(
        tester.widget<Text>(find.text('Email')).style?.color,
        scheme.onSurfaceVariant,
      );
      expect(
        tester.widget<TextField>(_input).style?.color,
        scheme.onSurfaceVariant,
      );
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
      expect(
        tester.getSemantics(_input),
        isSemantics(
          label: 'Email',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: false,
          isReadOnly: true,
        ),
      );

      await tester.tap(_input);
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isFalse);
      expect(tester.testTextInput.hasAnyClients, isFalse);
      handle.dispose();
    });

    testWidgets('the reveal toggle still works', (tester) async {
      await tester.pumpWidget(
        _host(
          _field(
            controller,
            obscure: true,
            readOnly: true,
            reveal: 'Show password',
            conceal: 'Hide password',
          ),
        ),
      );
      expect(tester.widget<TextField>(_input).obscureText, isTrue);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tester.widget<TextField>(_input).obscureText, isFalse);
    });
  });

  group('semantics', () {
    testWidgets('is one text field node named by the label with the hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(_field(controller, hint: 'name@example.com')),
      );

      expect(
        tester.getSemantics(_input),
        isSemantics(
          label: 'Email\nname@example.com',
          isTextField: true,
          isEnabled: true,
        ),
      );
      expect(find.bySemanticsLabel(RegExp('^Email')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('exposes the entered value', (tester) async {
      final handle = tester.ensureSemantics();
      controller.text = 'ana@compapp.test';
      await tester.pumpWidget(_host(_field(controller)));

      expect(
        tester.getSemantics(_input),
        isSemantics(
          label: 'Email',
          value: 'ana@compapp.test',
          isTextField: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the error is a live region and the field is invalid', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(_field(controller, errorText: 'Enter a full email address')),
      );

      expect(
        tester.getSemantics(find.text('Enter a full email address')),
        isSemantics(label: 'Enter a full email address', isLiveRegion: true),
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

    testWidgets('the error is also the hint of the field itself', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(_field(controller, errorText: 'Enter a full email address')),
      );

      final node = tester.getSemantics(_input);
      expect(node.hint, 'Enter a full email address');
      expect(node.label, 'Email');

      await tester.pumpWidget(_host(_field(controller)));
      expect(tester.getSemantics(_input).hint, isEmpty);
      handle.dispose();
    });

    testWidgets('the helper is not a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(_field(controller, helperText: 'We never share it')),
      );

      expect(
        tester.getSemantics(find.text('We never share it')),
        isSemantics(label: 'We never share it', isLiveRegion: false),
      );
      handle.dispose();
    });

    testWidgets('a valid field is not marked invalid', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_field(controller)));

      expect(
        tester.getSemantics(_input),
        isSemantics(
          isTextField: true,
          validationResult: SemanticsValidationResult.none,
        ),
      );
      handle.dispose();
    });

    testWidgets('a disabled field is reported disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_field(controller, enabled: false)));

      expect(
        tester.getSemantics(_input),
        isSemantics(
          label: 'Email',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('a read-only field is reported read-only and enabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_field(controller)));
      expect(
        tester.getSemantics(_input),
        isSemantics(isTextField: true, isReadOnly: false),
      );

      await tester.pumpWidget(_host(_field(controller, readOnly: true)));

      expect(
        tester.getSemantics(_input),
        isSemantics(
          label: 'Email',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
          isReadOnly: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the visible label adds no second node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_field(controller)));

      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      handle.dispose();
    });
  });
}

import 'dart:math' as math;
import 'dart:ui' show SemanticsInputType, SemanticsValidationResult;

import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// A one-time code entry with one cell per character, like the reset code and
/// invitation screens.
///
/// A single invisible, single-line text field holds the whole code and the
/// cells only draw it. That is what makes the behaviors of a code box come for
/// free: typing advances to the next cell, backspace goes back across cells,
/// and the platform can autofill a code from an SMS. The caret is always after
/// the last character, so arrow keys and taps never edit the middle of a code.
///
/// Characters that do not belong (anything but digits when [numeric], white
/// space otherwise) are dropped. A typed character past the end is ignored. A
/// pasted or suggested code (two or more characters) that fills the code or
/// does not fit replaces the value with its last [length] characters, so
/// inserting a full code into a partial or a full field gives that code.
/// Shrinking [length] truncates the value.
///
/// Assistive technology gets one text field node, named by [label], whose
/// value is the code entered so far spelled out character by character (so
/// "481592" is not read as a number), not one node per cell. The keyboard is
/// numeric when [numeric] is true (the default). [onCompleted] fires each time
/// the code reaches [length] characters. The cells always run left to right,
/// as a code is read, even in right-to-left text.
///
/// A non-null [errorText] turns the cells red, marks the field as invalid and
/// shows the text below, announced as a live region.
///
/// Cell `i` (from 0) has the key `codeInput.digit.<i>`.
class AppCodeInput extends StatefulWidget {
  const new({
    required this.label,
    required this.onCompleted,
    this.length = 6,
    this.numeric = true,
    this.controller,
    this.errorText,
    this.onChanged,
    this.autofocus = false,
    this.focusNode,
    super.key,
  }) : assert(length > 0, 'A code has at least one cell');

  final String label;
  final ValueChanged<String> onCompleted;
  final int length;
  final bool numeric;

  /// Holds the code. Optional: the widget keeps its own when it is null.
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<AppCodeInput> createState() => _AppCodeInputState();
}

class _AppCodeInputState extends State<AppCodeInput> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;

  TextEditingController get _controller => widget.controller ?? _ownController!;
  FocusNode get _focusNode => widget.focusNode ?? _ownFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _ownController = TextEditingController();
    if (widget.focusNode == null) _ownFocusNode = FocusNode();
    _controller.addListener(_clampCaret);
  }

  @override
  void didUpdateWidget(AppCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController!).removeListener(_clampCaret);
      if (widget.controller == null) {
        _ownController = TextEditingController.fromValue(
          oldWidget.controller!.value,
        );
      } else {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller.addListener(_clampCaret);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (widget.focusNode == null) {
        _ownFocusNode = FocusNode();
      } else {
        _ownFocusNode?.dispose();
        _ownFocusNode = null;
      }
    }
    if (widget.length != oldWidget.length) {
      // The controller and the app are notified after the frame: neither can
      // change while building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        var code = _controller.text;
        if (code.length > widget.length) {
          code = code.substring(0, widget.length);
          _controller.value = TextEditingValue(
            text: code,
            selection: TextSelection.collapsed(offset: code.length),
          );
          widget.onChanged?.call(code);
        }
        if (code.isNotEmpty && code.length == widget.length) {
          widget.onCompleted(code);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_clampCaret);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  /// Input formatters only see text changes, so arrow keys, Home and a
  /// selection set by the platform are clamped here.
  void _clampCaret() {
    final end = TextSelection.collapsed(offset: _controller.text.length);
    if (_controller.selection != end) _controller.selection = end;
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted(value);
  }

  void _requestFocus() => _focusNode.requestFocus();

  _CodeFormatter get _formatter =>
      _CodeFormatter(length: widget.length, numeric: widget.numeric);

  /// Sets the whole text the way the platform does, through the formatter, for
  /// the semantic set-text and paste actions.
  void _applyText(String text) {
    final old = _controller.value;
    final next = _formatter.formatEditUpdate(
      old,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    if (next.text == old.text) return;
    _controller.value = next;
    _handleChanged(next.text);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || !mounted) return;
    _applyText(_controller.text + pasted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = widget.errorText != null;

    final field = ExcludeSemantics(
      child: Opacity(
        opacity: 0,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          keyboardType: widget.numeric
              ? TextInputType.number
              : TextInputType.text,
          textCapitalization: widget.numeric
              ? TextCapitalization.none
              : TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [_formatter],
          onChanged: _handleChanged,
          showCursor: false,
          selectionControls: _toolbarOnlyControls,
          decoration: const InputDecoration.collapsed(hintText: null),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A code is read left to right whatever the text direction is.
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListenableBuilder(
            listenable: Listenable.merge([_controller, _focusNode]),
            builder: (context, _) {
              final code = _controller.text;
              return Semantics(
                // A container, so the node does not merge into a labeled
                // group around the code input.
                container: true,
                textField: true,
                enabled: true,
                label: widget.label,
                attributedValue: AttributedString(
                  code,
                  attributes: [
                    if (code.isNotEmpty)
                      SpellOutStringAttribute(
                        range: TextRange(start: 0, end: code.length),
                      ),
                  ],
                ),
                maxValueLength: widget.length,
                currentValueLength: code.length,
                inputType: SemanticsInputType.text,
                focusable: true,
                focused: _focusNode.hasFocus,
                validationResult: hasError
                    ? SemanticsValidationResult.invalid
                    : SemanticsValidationResult.none,
                onTap: _requestFocus,
                onFocus: _requestFocus,
                onSetText: _applyText,
                onPaste: _paste,
                child: Stack(
                  children: [
                    ExcludeSemantics(
                      child: _Cells(
                        code: code,
                        length: widget.length,
                        focused: _focusNode.hasFocus,
                        hasError: hasError,
                      ),
                    ),
                    Positioned.fill(child: field),
                  ],
                ),
              );
            },
          ),
        ),
        if (hasError)
          Semantics(
            container: true,
            liveRegion: true,
            child: Padding(
              // The focus ring takes the first `size.focus-ring` below.
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                widget.errorText!,
                style: theme.textTheme.bodySmall!.copyWith(color: scheme.error),
              ),
            ),
          ),
      ],
    );
  }
}

/// Keeps the code to its allowed characters and to its length, and the caret
/// after the last one.
class _CodeFormatter extends TextInputFormatter {
  const new({required this.length, required this.numeric});

  final int length;
  final bool numeric;

  static final _notDigit = RegExp('[^0-9]');
  static final _whitespace = RegExp(r'\s');

  String _allowed(String text) =>
      text.replaceAll(numeric ? _notDigit : _whitespace, '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final before = oldValue.text;
    final after = newValue.text;

    // What was inserted: what the new text has between the characters it
    // still shares with the old one at both ends.
    var start = 0;
    while (start < before.length &&
        start < after.length &&
        before[start] == after[start]) {
      start++;
    }
    var end = 0;
    while (end < before.length - start &&
        end < after.length - start &&
        before[before.length - 1 - end] == after[after.length - 1 - end]) {
      end++;
    }
    final inserted = _allowed(after.substring(start, after.length - end));
    final all = _allowed(after);

    final String code;
    if (inserted.length >= length) {
      code = inserted.substring(inserted.length - length);
    } else if (all.length <= length) {
      code = all;
    } else if (inserted.length > 1) {
      code = inserted;
    } else if (inserted.isEmpty) {
      code = all.substring(0, length);
    } else {
      final kept = _allowed(before);
      code = kept.length <= length ? kept : kept.substring(0, length);
    }

    final caret = TextSelection.collapsed(offset: code.length);
    if (code != after) return TextEditingValue(text: code, selection: caret);

    // The text is as the platform made it: keep an IME composing region (cut
    // to the text) so a keyboard that composes is not interrupted.
    final composing = newValue.composing;
    return newValue.copyWith(
      selection: caret,
      composing: composing.isValid
          ? TextRange(
              start: composing.start.clamp(0, code.length),
              end: composing.end.clamp(0, code.length),
            )
          : TextRange.empty,
    );
  }
}

/// The platform's paste toolbar without selection handles: the text is
/// invisible, so a handle would float where no cell is.
class _ToolbarOnlyControls extends MaterialTextSelectionControls {
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => const SizedBox.shrink();

  @override
  Size getHandleSize(double textLineHeight) => Size.zero;

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      Offset.zero;
}

final TextSelectionControls _toolbarOnlyControls = _ToolbarOnlyControls();

class _Cells extends StatelessWidget {
  const new({
    required this.code,
    required this.length,
    required this.focused,
    required this.hasError,
  });

  final String code;
  final int length;
  final bool focused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final shown = code.length > length ? code.substring(0, length) : code;
    final activeCell = math.min(shown.length, length - 1);

    // The cell height is a minimum: it grows with a large text scale, so the
    // line of the digit keeps `space.sm` above and below inside the cell.
    final style = Theme.of(context).textTheme.headlineSmall!;
    final line =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    final height = math.max(AppSizes.codeCellHeight, line + AppSpacing.sm * 2);

    // The cells share the width when there is not enough for `length` of
    // them, and take their own width when the parent gives no limit.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: SizedBox(
              width: AppSizes.codeCellWidth,
              height: height,
              child: _Cell(
                key: Key('codeInput.digit.$i'),
                character: i < shown.length ? shown[i] : '',
                active: focused && i == activeCell,
                hasError: hasError,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const new({
    required this.character,
    required this.active,
    required this.hasError,
    super.key,
  });

  final String character;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = active || hasError;
    final borderColor = hasError
        ? scheme.error
        : active
        ? scheme.primary
        : scheme.outline;
    final radius = BorderRadius.circular(AppRadius.sm);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (active)
          Positioned(
            left: -AppSizes.focusRing,
            top: -AppSizes.focusRing,
            right: -AppSizes.focusRing,
            bottom: -AppSizes.focusRing,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: hasError
                    ? scheme.errorContainer
                    : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(
                  AppRadius.sm + AppSizes.focusRing,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: character.isNotEmpty || active
                  ? scheme.surfaceContainerLowest
                  : scheme.surfaceContainerHigh,
              borderRadius: radius,
              border: Border.all(
                color: borderColor,
                width: emphasized ? AppSizes.borderEmphasis : AppSizes.hairline,
              ),
            ),
            child: Center(
              child: Text(
                character,
                style: theme.textTheme.headlineSmall!.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

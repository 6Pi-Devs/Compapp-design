import 'dart:ui' show SemanticsValidationResult;

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A labeled single-line text field on top of Material's `TextField`, which
/// `CompappTheme` styles through its input decoration theme: 52 tall,
/// `radius.sm`, a 2 px primary border and a primary-soft ring when focused.
///
/// The [label] sits above the field and names it for assistive technology
/// together with [hint]. [helperText] is shown below the field until
/// [errorText] replaces it. An error also turns the border red and the focus
/// ring danger-soft, marks the field as invalid, becomes the hint of the
/// field's own semantics (so a user who comes back to the field hears it) and
/// is announced once as a live region when it appears.
///
/// With [obscure] the text is hidden. When both [revealSemanticLabel] and
/// [concealSemanticLabel] are given, a toggle in the field shows or hides it,
/// named by the label of the action it will do.
class AppTextField extends StatefulWidget {
  const new({
    required this.label,
    required this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscure = false,
    this.revealSemanticLabel,
    this.concealSemanticLabel,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool obscure;

  /// Names the toggle while the text is hidden, for example "Show password".
  final String? revealSemanticLabel;

  /// Names the toggle while the text is shown, for example "Hide password".
  final String? concealSemanticLabel;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// False renders the disabled state and refuses focus and input.
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownFocusNode;
  bool _revealed = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) _ownFocusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    (oldWidget.focusNode ?? _ownFocusNode!).removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _ownFocusNode ??= FocusNode();
    } else {
      _ownFocusNode?.dispose();
      _ownFocusNode = null;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final decorations = theme.inputDecorationTheme;
    final hasError = widget.errorText != null;
    final enabled = widget.enabled;

    final reveal = widget.revealSemanticLabel;
    final conceal = widget.concealSemanticLabel;
    final showToggle = widget.obscure && reveal != null && conceal != null;

    final field = Semantics(
      label: widget.label,
      hint: widget.errorText,
      validationResult: hasError
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: enabled,
        autofocus: widget.autofocus,
        obscureText: widget.obscure && !_revealed,
        enableSuggestions: !widget.obscure,
        autocorrect: !widget.obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: text.bodyMedium!.copyWith(
          color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          enabledBorder: hasError ? decorations.errorBorder : null,
          focusedBorder: hasError ? decorations.focusedErrorBorder : null,
          suffixIcon: showToggle
              ? IconButton(
                  onPressed: enabled
                      ? () => setState(() => _revealed = !_revealed)
                      : null,
                  tooltip: _revealed ? conceal : reveal,
                  color: _revealed ? scheme.primary : scheme.onSurfaceVariant,
                  icon: const AppIcon(AppIcons.show),
                )
              : null,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: text.labelLarge!.copyWith(
              color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _FocusRing(
          focused: enabled && _focusNode.hasFocus,
          color: hasError ? scheme.errorContainer : scheme.primaryContainer,
          child: field,
        ),
        if (hasError)
          _Message(widget.errorText!, color: scheme.error, liveRegion: true)
        else if (widget.helperText != null)
          _Message(widget.helperText!, color: scheme.onSurfaceVariant),
      ],
    );
  }
}

/// The helper or error line under the field.
class _Message extends StatelessWidget {
  const new(this.message, {required this.color, this.liveRegion = false});

  final String message;
  final Color color;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Padding(
        // The focus ring takes the first `size.focus-ring` below the field.
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: color),
        ),
      ),
    );
  }
}

/// A primary-soft band `size.focus-ring` wide around [child] while [focused].
/// It is a fill, not a shadow, so it also shows in CI goldens.
class _FocusRing extends StatelessWidget {
  const new({required this.focused, required this.color, required this.child});

  final bool focused;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (focused)
          Positioned(
            left: -AppSizes.focusRing,
            top: -AppSizes.focusRing,
            right: -AppSizes.focusRing,
            bottom: -AppSizes.focusRing,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      AppRadius.sm + AppSizes.focusRing,
                    ),
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_progress_ring.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/knock_cooldown.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// The "Who's home?" button: it asks the home who is in, and while the home
/// was asked a short time ago it waits and shows how long.
///
/// Ready, it is Material's `OutlinedButton` (surface fill, outline border, ink
/// focus ring) with a door glyph over the [label], and a tap calls [onKnock].
/// While [cooldown] is set it is inert: a sunken fill, a ring that shows the
/// share of the wait that is left, the cooldown's label and the time left, and
/// a press does nothing. It is never told by color alone, because the words and
/// the ring change too, and it is calm: no danger color, no blame, only how
/// long to wait.
///
/// The design system keeps no clock and no dates: the app counts the wait and
/// passes it in as a [KnockCooldown] (strings and a share), and the button only
/// draws what it is given. It has no motion of its own: the ring follows the
/// share the app passes.
///
/// For assistive technology it is ONE node in both states, which is never
/// replaced: a button, focusable, with a focus action, that says whether it has
/// focus. Ready, it is enabled, named by its visible [label] and a tap calls
/// [onKnock]. In cooldown the same node is marked disabled, loses the tap
/// action and is named by [KnockCooldown.semanticLabel] ("Asked who's home.
/// You can ask again in 11 minutes"). The visible texts, the ring and
/// Material's own node add nothing. A screen reader's cursor and keyboard
/// focus are therefore still on it when the wait starts, and the sentence is
/// read in place. The Material button is the same widget in both states too,
/// inert in the wait, with its own focus ring. It is at least 96 wide and
/// `AppSizes.presenceControl` tall in both states, drawn and hit, and grows
/// with large text: the texts wrap by word and nothing is clamped. It takes the
/// width of its content up to the width it is given. It reads the same in
/// right-to-left: the ring is a clock face.
class KnockButton extends StatefulWidget {
  const new({
    required this.label,
    required this.onKnock,
    this.cooldown,
    super.key,
  }) : assert(label != '', 'The button needs a label');

  final String label;
  final VoidCallback onKnock;

  /// The wait that is on, or null while the home can be asked.
  final KnockCooldown? cooldown;

  @override
  State<KnockButton> createState() => _KnockButtonState();
}

class _KnockButtonState extends State<KnockButton> {
  final FocusNode _node = FocusNode(debugLabel: 'presence.knock');
  bool _focused = false;

  static void _inert() {}

  @override
  void initState() {
    super.initState();
    _node.addListener(_follow);
  }

  void _follow() {
    if (_node.hasFocus != _focused) setState(() => _focused = _node.hasFocus);
  }

  @override
  void dispose() {
    _node
      ..removeListener(_follow)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final waiting = widget.cooldown;
    final label = widget.label;

    final glyph = AppIcon(
      AppIcons.knock,
      size: AppSizes.glyphLg,
      color: scheme.onSurface,
    );
    final content = waiting == null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              glyph,
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(color: scheme.onSurface),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppProgressRing(
                semanticLabel: null,
                value: waiting.ringValue,
                size: AppSizes.knockRing,
              ),
              Text(
                waiting.label,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                waiting.remainingLabel,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );

    // The same chain of widgets in both states, so the button keeps its element
    // and its keyboard focus when the wait starts. In the wait its own node is
    // left out and one marked disabled and named by the sentence stands in.
    final button = OutlinedButton(
      key: const Key('presence.knock'),
      focusNode: _node,
      onPressed: waiting == null ? widget.onKnock : _inert,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(AppSizes.knockWidth, AppSizes.presenceControl),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
        ),
        // A wait is a sunken, decorative state: the button is not a control
        // then, so its edge is the hairline color the board draws.
        backgroundColor: waiting == null
            ? null
            : WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        side: waiting == null
            ? null
            : WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? BorderSide(
                        color: scheme.onSurface,
                        width: AppSizes.borderEmphasis,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : BorderSide(color: scheme.outlineVariant),
              ),
        // The wait does not answer a press: no ripple, no pressed fill.
        overlayColor: waiting == null
            ? null
            : const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: waiting == null ? null : NoSplash.splashFactory,
        mouseCursor: waiting == null
            ? null
            : const WidgetStatePropertyAll(SystemMouseCursors.basic),
      ),
      child: content,
    );

    // One node in both states, so it is never replaced and a screen reader
    // keeps its cursor when the wait starts. Material's own node is left out.
    return Semantics(
      container: true,
      button: true,
      enabled: waiting == null,
      label: waiting?.semanticLabel ?? label,
      onTap: waiting == null ? widget.onKnock : null,
      onFocus: _node.requestFocus,
      focusable: true,
      focused: _focused,
      child: ExcludeSemantics(child: button),
    );
  }
}

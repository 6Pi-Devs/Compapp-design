import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/foundation/dashed_border.dart';
import 'package:compapp_design/src/foundation/equal_pair.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A personal or home code on a dashed card, with a copy and a share button
/// under it.
///
/// The [code] is the text to show, already grouped by the app ("4829 1736"):
/// it wraps at the spaces, so each group has to fit the card, and it always
/// reads left to right, as a code is read. It is a string and the design
/// system does nothing with it: copying and sharing are the callbacks
/// [onCopy] and [onShare], and the app does the clipboard and the share sheet.
/// [copied] is the state the app sets after it copied: the copy button then
/// says [copiedLabel] and shows a check instead of the copy glyph, so it is
/// never told by color alone. The app owns how long it lasts.
///
/// The button changes its label without a word, so the app must announce the
/// copy too, for example with an `AppSnackbar`, which is a live region.
///
/// For assistive technology the code is one node named by [label] ("Your
/// personal code") whose value is the code spelled out character by character,
/// so "48291736" is not read as a number. The visible texts add nothing of
/// their own. The copy and share buttons are their own buttons, named by their
/// visible labels. Nothing is announced twice, and the card itself is not
/// interactive.
///
/// The dashed edge is decoration in the hairline color, not a control
/// boundary: the code and the buttons carry the meaning. The card grows with
/// large text, and nothing is clamped. The buttons share the width in two
/// equal halves while the longest word of each fits its half, and stack, each
/// as wide as the card, when one does not, so no word is cut. It needs a
/// bounded width and mirrors in right-to-left, with the copy button at the
/// start. It has no motion.
class CodeCard extends StatelessWidget {
  const new({
    required this.code,
    required this.label,
    required this.copyLabel,
    required this.copiedLabel,
    required this.shareLabel,
    required this.onCopy,
    required this.onShare,
    this.copied = false,
    super.key,
  }) : assert(code != '', 'The card needs a code'),
       assert(label != '', 'The code needs a spoken name'),
       assert(copyLabel != '', 'The copy button needs a label'),
       assert(copiedLabel != '', 'The copied state needs a label'),
       assert(shareLabel != '', 'The share button needs a label');

  final String code;

  /// The caption over the code, which also names it for assistive technology.
  final String label;
  final String copyLabel;
  final String copiedLabel;
  final String shareLabel;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  static const double _cardRadius = AppRadius.sm;
  static const double _cardPadding = AppSpacing.sm + AppSpacing.xs;
  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final card = Semantics(
      container: true,
      label: label,
      attributedValue: AttributedString(
        code,
        attributes: [
          SpellOutStringAttribute(range: TextRange(start: 0, end: code.length)),
        ],
      ),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.surfaceContainerLowest,
          shape: DashedBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: BorderSide(
              color: scheme.outlineVariant,
              width: AppSizes.borderDashed,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: _cardPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // A code is read left to right whatever the text direction is.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  code,
                  key: const Key('account.code.value'),
                  textAlign: TextAlign.center,
                  style: AppTypography.code.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      key: const Key('account.code'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: _gap),
        EqualPair(
          spacing: AppSpacing.sm,
          textDirection: Directionality.of(context),
          children: [
            AppButton(
              key: const Key('account.code.copy'),
              label: copied ? copiedLabel : copyLabel,
              icon: copied ? AppIcons.check : AppIcons.copy,
              variant: AppButtonVariant.secondary,
              onPressed: onCopy,
            ),
            AppButton(
              key: const Key('account.code.share'),
              label: shareLabel,
              icon: AppIcons.share,
              variant: AppButtonVariant.secondary,
              onPressed: onShare,
            ),
          ],
        ),
      ],
    );
  }
}

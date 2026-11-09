import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The top of a bottom sheet: a drag handle, the title and a close button.
///
/// The header draws no surface, shadow or corners: the sheet around it owns
/// them. The [title] is a heading. The close button is 44 drawn with a 48 hit
/// area, named by [closeLabel] for assistive technology and calls [onClose].
/// The handle only hints that the sheet can be dragged: it is decorative and
/// excluded from semantics, because the close button is the way out that
/// everyone can reach.
///
/// The header is its own semantics group, so under a grouping parent such as
/// a `Card` the title stays a heading node of its own, read before the close
/// button, and the button stays a button. [closeLabel] is never empty.
///
/// Every string is a prop. A long title wraps and the header grows with it,
/// while the close button stays at the top end. It mirrors in right-to-left
/// text.
///
/// One snap to the board: the title is centered on the 48 hit area of the
/// close button, so its first line sits 15 below the handle where the board
/// has 12.
class SheetHeader extends StatelessWidget {
  const new({
    required this.title,
    required this.onClose,
    required this.closeLabel,
    super.key,
  }) : assert(closeLabel != '', 'The close button needs a spoken label');

  final String title;
  final VoidCallback onClose;

  /// Spoken name of the close button, for example "Close".
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  key: const Key('sheet.handle'),
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(
                      AppSizes.sheetHandleHeight / 2,
                    ),
                  ),
                  child: const SizedBox(
                    width: AppSizes.sheetHandleWidth,
                    height: AppSizes.sheetHandleHeight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.minTarget,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(
                        container: true,
                        header: true,
                        sortKey: const OrdinalSortKey(0),
                        child: Text(
                          title,
                          key: const Key('sheet.title'),
                          style: AppTypography.title.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: const Key('sheet.close'),
                  onPressed: onClose,
                  style: ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(
                      Size.square(AppSizes.minDrawn),
                    ),
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    foregroundColor: WidgetStatePropertyAll(
                      scheme.onSurfaceVariant,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                  child: Semantics(
                    label: closeLabel,
                    sortKey: const OrdinalSortKey(1),
                    excludeSemantics: true,
                    child: const AppIcon(
                      AppIcons.close,
                      size: AppSizes.glyphAction,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

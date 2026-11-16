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
/// A sheet that opens with the title as its starting point passes a
/// [titleFocusNode]: the title then takes focus like any widget, without a stop
/// of its own in the Tab order, and while the node holds the focus of someone
/// using a keyboard the title has the house focus ring, 2 px of ink drawn
/// outside its text. The node is the caller's: it creates, requests and
/// disposes it. Without one the title is plain text, as before.
///
/// One snap to the board: the title is centered on the 48 hit area of the
/// close button, so its first line sits 15 below the handle where the board
/// has 12.
class SheetHeader extends StatelessWidget {
  const new({
    required this.title,
    required this.onClose,
    required this.closeLabel,
    this.titleFocusNode,
    this.namesRoute = false,
    super.key,
  }) : assert(closeLabel != '', 'The close button needs a spoken label');

  final String title;
  final VoidCallback onClose;

  /// Spoken name of the close button, for example "Close".
  final String closeLabel;

  /// Focus node of the title, for a sheet that starts with focus on it.
  final FocusNode? titleFocusNode;

  /// Whether the title names the route that holds the header, for a sheet
  /// shown in its own route: assistive technology then announces the title
  /// when the sheet opens. The route itself must be a route scope.
  final bool namesRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focusNode = titleFocusNode;
    final title = Text(
      this.title,
      key: const Key('sheet.title'),
      style: AppTypography.title.copyWith(color: scheme.onSurface),
    );

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
                        namesRoute: namesRoute,
                        sortKey: const OrdinalSortKey(0),
                        child: focusNode == null
                            ? title
                            : _FocusRing(node: focusNode, child: title),
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

/// Makes the title focusable (no Tab stop) and draws the keyboard focus ring
/// around it, outside its text and above it.
class _FocusRing extends StatefulWidget {
  const new({required this.node, required this.child});

  final FocusNode node;
  final Widget child;

  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    widget.node.addListener(_update);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
    _show = _shown;
  }

  @override
  void didUpdateWidget(_FocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node != widget.node) {
      oldWidget.node.removeListener(_update);
      widget.node.addListener(_update);
      _show = _shown;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    widget.node.removeListener(_update);
    super.dispose();
  }

  bool get _shown =>
      widget.node.hasFocus &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  void _onHighlightMode(FocusHighlightMode mode) => _update();

  void _update() {
    if (_shown != _show) setState(() => _show = _shown);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.node,
      skipTraversal: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_show)
            Positioned(
              left: -AppSizes.borderEmphasis,
              top: -AppSizes.borderEmphasis,
              right: -AppSizes.borderEmphasis,
              bottom: -AppSizes.borderEmphasis,
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const Key('sheet.titleRing'),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: AppSizes.borderEmphasis,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

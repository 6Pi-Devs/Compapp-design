import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/foundation/dashed_border.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// What a chip stands for. It changes the border only: [room] and [type] are
/// solid, [item] (a thing in the home) is dashed.
enum AppChipKind { room, item, type }

/// A toggleable chip on top of Material's `FilterChip`, which `CompappTheme`
/// styles: 44 tall with `radius.sm`, never a pill.
///
/// Selected adds a check and a primary border, so selection never relies on
/// color alone. A null [onTap] disables the chip. The label names the chip
/// for assistive technology and the selected state is exposed as selected.
///
/// Material paints every child of a disabled chip at 38% opacity, which would
/// turn the muted label of the board into a washed-out one. So a disabled
/// chip is an enabled one to Material that ignores pointer and focus, with the
/// disabled colors and the disabled semantics (a disabled button that keeps
/// its label and selected state) passed in explicitly.
class AppChip extends StatelessWidget {
  const new({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.kind = AppChipKind.room,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final AppChipKind kind;

  /// Height of the label box. The chip theme pads the content by `space.sm`
  /// above and below and Material adds the border inside that padding, so the
  /// box shrinks by both to keep the chip `size.control-md` tall, selected or
  /// not.
  double get _labelMinHeight {
    final border = selected && onTap != null
        ? AppSizes.borderEmphasis
        : AppSizes.hairline;
    return AppSizes.controlMd - (AppSpacing.sm + border) * 2;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Semantics(
      // A container, so the disabled node does not merge into the labeled
      // group around the chip.
      container: !enabled,
      excludeSemantics: !enabled,
      button: enabled ? null : true,
      enabled: enabled ? null : false,
      selected: enabled ? null : selected,
      label: enabled ? null : label,
      child: IgnorePointer(
        ignoring: !enabled,
        child: ExcludeFocus(
          excluding: !enabled,
          child: FilterChip(
            label: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _labelMinHeight),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(label),
              ),
            ),
            selected: selected,
            onSelected: (_) => onTap?.call(),
            showCheckmark: false,
            avatar: selected ? const AppIcon(AppIcons.check) : null,
            avatarBoxConstraints: BoxConstraints.tight(
              const Size.square(AppSizes.glyphMd),
            ),
            labelPadding: selected
                ? const EdgeInsetsDirectional.only(start: AppSpacing.sm)
                : EdgeInsets.zero,
            color: enabled ? null : WidgetStatePropertyAll(scheme.surface),
            side: enabled
                ? null
                : BorderSide(color: scheme.surfaceContainerHigh),
            labelStyle: enabled
                ? null
                : TextStyle(color: scheme.onSurfaceVariant),
            shape: kind == AppChipKind.item
                ? const DashedBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.sm),
                    ),
                  )
                : null,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
          ),
        ),
      ),
    );
  }
}

import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A labeled on/off switch on top of Material's `Switch`, which
/// `CompappTheme` styles: the 52x32 track is primary when on and sunken with a
/// line border when off.
///
/// The whole row, the track and the [label], toggles it, and is at least 48
/// tall. A null [onChanged] disables it. The label names the switch for
/// assistive technology, which hears it with the on or off state in one node.
class AppSwitch extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;

    return MergeSemantics(
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        canRequestFocus: false,
        excludeFromSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: value, onChanged: onChanged),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

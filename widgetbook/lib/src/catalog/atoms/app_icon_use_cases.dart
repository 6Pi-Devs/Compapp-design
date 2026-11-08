import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildAppIcon() {
  return WidgetbookComponent(
    name: 'AppIcon',
    useCases: [
      _playground(),
      WidgetbookUseCase(name: 'gallery-default', builder: _gallery),
    ],
  );
}

Widget _gallery(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  return Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.sample(en: 'Icons', es: 'Iconos'),
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final icon in AppIcons.values)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(icon),
                  const SizedBox(height: AppSpacing.xs),
                  Text(icon.name, style: textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    ),
  );
}

const _minIconSize = 8.0;
const _maxIconSize = 96.0;

/// Every prop of [AppIcon] as a knob. A null size, color or semantic label
/// falls back to the ambient icon theme, or to a decorative icon.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final icon = context.enumKnob('icon', AppIcons.values);
      final size = context.knobs.doubleOrNull.slider(
        label: 'size',
        description: 'Null uses the size of the icon theme',
        min: _minIconSize,
        max: _maxIconSize,
        defaultToNull: true,
      );
      final color = context.knobs.colorOrNull(
        label: 'color',
        description: 'Null uses the color of the icon theme',
        defaultToNull: true,
      );
      final semanticLabel = context.textKnobOrNull('semanticLabel', null);

      return useCaseFrame(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppIcon(
            icon,
            size: size,
            color: color,
            semanticLabel: semanticLabel,
          ),
        ),
      );
    },
  );
}

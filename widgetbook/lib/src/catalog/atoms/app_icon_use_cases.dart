import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildAppIcon() {
  return WidgetbookComponent(
    name: 'AppIcon',
    useCases: [WidgetbookUseCase(name: 'gallery-default', builder: _gallery)],
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

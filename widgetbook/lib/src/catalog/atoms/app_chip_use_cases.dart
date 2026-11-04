import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per kind and state. Room and type chips have a solid border,
/// item chips a dashed one, as on the Atoms board.
WidgetbookComponent buildAppChip() {
  return WidgetbookComponent(
    name: 'AppChip',
    useCases: [
      for (final kind in AppChipKind.values) ...[
        WidgetbookUseCase(
          name: '${kind.name}-default',
          builder: (context) => _frame(_label(context, kind, 0), kind),
        ),
        WidgetbookUseCase(
          name: '${kind.name}-selected',
          builder: (context) =>
              _frame(_label(context, kind, 1), kind, selected: true),
        ),
        WidgetbookUseCase(
          name: '${kind.name}-disabled',
          builder: (context) =>
              _frame(_label(context, kind, 2), kind, enabled: false),
        ),
      ],
    ],
  );
}

String _label(BuildContext context, AppChipKind kind, int index) {
  final samples = switch (kind) {
    AppChipKind.room => [
      context.sample(en: 'Bathroom', es: 'Baño'),
      context.sample(en: 'Kitchen', es: 'Cocina'),
      context.sample(en: 'Terrace', es: 'Terraza'),
    ],
    AppChipKind.item => [
      context.sample(en: 'Dishwasher', es: 'Lavavajillas'),
      context.sample(en: 'Washer', es: 'Lavadora'),
      context.sample(en: 'Oven', es: 'Horno'),
    ],
    AppChipKind.type => [
      context.sample(en: 'Cleaning', es: 'Limpieza'),
      context.sample(en: 'Shopping', es: 'Compras'),
      context.sample(en: 'Repairs', es: 'Arreglos'),
    ],
  };
  return samples[index];
}

Widget _frame(
  String label,
  AppChipKind kind, {
  bool selected = false,
  bool enabled = true,
}) {
  return useCaseFrame(
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppChip(
        label: label,
        kind: kind,
        selected: selected,
        onTap: enabled ? () {} : null,
      ),
    ),
  );
}

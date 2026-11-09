import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per state of the Molecules board: the washer in use (a
/// breathing ring, frozen so the golden is deterministic) and the oven free.
WidgetbookComponent buildItemBeacon() {
  return WidgetbookComponent(
    name: 'ItemBeacon',
    useCases: [
      _playground(),
      WidgetbookUseCase(
        name: 'beacon-in-use',
        builder: (context) => useCaseFrame(
          child: FrozenMotion(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ItemBeacon(
                item: ItemView(
                  id: 'washer',
                  name: context.sample(en: 'Washer', es: 'Lavadora'),
                  icon: AppIcons.washer,
                ),
                inUse: true,
                statusLabel: context.sample(en: '34 min', es: '34 min'),
                semanticLabel: context.sample(
                  en: 'Washer, in use by Carlos, 34 minutes',
                  es: 'Lavadora, en uso por Carlos, 34 minutos',
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'beacon-free',
        builder: (context) => useCaseFrame(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ItemBeacon(
              item: ItemView(
                id: 'oven',
                name: context.sample(en: 'Oven', es: 'Horno'),
                icon: AppIcons.oven,
              ),
              inUse: false,
              statusLabel: context.sample(en: 'free', es: 'libre'),
              semanticLabel: context.sample(
                en: 'Oven, free',
                es: 'Horno, libre',
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    ],
  );
}

/// Every prop of [ItemBeacon] as a knob: the item (its name and glyph), in use
/// or free, the status line and the spoken label. The callback is plumbing:
/// the story owns it. In use, the ring breathes unless the system reduces
/// motion.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final name = context.textKnob(
        'name',
        context.sample(en: 'Washer', es: 'Lavadora'),
      );
      final icon = context.enumKnob(
        'icon',
        AppIcons.values,
        initial: AppIcons.washer,
      );
      final inUse = context.knobs.boolean(
        label: 'inUse',
        description: 'In use: a breathing ring and a busy status text',
      );
      final statusLabel = context.textKnob(
        'statusLabel',
        context.sample(en: 'free', es: 'libre'),
      );
      final sampleLabel = context.sample(
        en: 'Washer, free',
        es: 'Lavadora, libre',
      );
      final typedLabel = context.textKnob(
        'semanticLabel',
        sampleLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );

      return useCaseFrame(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ItemBeacon(
            item: ItemView(id: 'playground', name: name, icon: icon),
            inUse: inUse,
            statusLabel: statusLabel,
            semanticLabel: typedLabel.isEmpty ? sampleLabel : typedLabel,
            onTap: () {},
          ),
        ),
      );
    },
  );
}

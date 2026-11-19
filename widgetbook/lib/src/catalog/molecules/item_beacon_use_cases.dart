import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per state of the Molecules board: the oven free, the washer
/// in use by the person (a check before the status) and by someone else (a
/// lock), and the oven busy while an action runs. The rings breathe unless
/// frozen, so the use cases that show one are frozen to keep the golden
/// deterministic.
WidgetbookComponent buildItemBeacon() {
  return WidgetbookComponent(
    name: 'ItemBeacon',
    useCases: [
      _playground(),
      _useCase(
        'beacon-free',
        (context) => _beacon(
          context,
          id: 'oven',
          icon: AppIcons.oven,
          name: context.sample(en: 'Oven', es: 'Horno'),
          status: ItemStatus.free,
          statusLabel: context.sample(en: 'free', es: 'libre'),
          semanticLabel: context.sample(en: 'Oven, free', es: 'Horno, libre'),
        ),
      ),
      _useCase(
        'beacon-mine',
        (context) => _beacon(
          context,
          id: 'washer',
          icon: AppIcons.washer,
          name: context.sample(en: 'Washer', es: 'Lavadora'),
          status: ItemStatus.mine,
          statusLabel: context.sample(en: 'You, 12 min', es: 'Tú, 12 min'),
          semanticLabel: context.sample(
            en: 'Washer, in use by you, 12 minutes',
            es: 'Lavadora, en uso por ti, 12 minutos',
          ),
        ),
      ),
      _useCase(
        'beacon-others',
        (context) => _beacon(
          context,
          id: 'washer',
          icon: AppIcons.washer,
          name: context.sample(en: 'Washer', es: 'Lavadora'),
          status: ItemStatus.others,
          statusLabel: context.sample(en: '34 min', es: '34 min'),
          semanticLabel: context.sample(
            en: 'Washer, in use by Carlos, 34 minutes',
            es: 'Lavadora, en uso por Carlos, 34 minutos',
          ),
        ),
      ),
      _useCase(
        'beacon-busy',
        (context) => _beacon(
          context,
          id: 'oven',
          icon: AppIcons.oven,
          name: context.sample(en: 'Oven', es: 'Horno'),
          status: ItemStatus.free,
          statusLabel: context.sample(en: 'free', es: 'libre'),
          semanticLabel: context.sample(en: 'Oven, free', es: 'Horno, libre'),
          busy: true,
          busySemanticLabel: context.sample(en: 'Updating', es: 'Actualizando'),
        ),
      ),
    ],
  );
}

WidgetbookUseCase _useCase(
  String name,
  Widget Function(BuildContext context) beacon,
) {
  return WidgetbookUseCase(
    name: name,
    builder: (context) => useCaseFrame(
      child: FrozenMotion(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: beacon(context),
        ),
      ),
    ),
  );
}

Widget _beacon(
  BuildContext context, {
  required String id,
  required AppIcons icon,
  required String name,
  required ItemStatus status,
  required String statusLabel,
  required String semanticLabel,
  bool busy = false,
  String? busySemanticLabel,
}) {
  return ItemBeacon(
    item: ItemView(id: id, name: name, icon: icon),
    status: status,
    statusLabel: statusLabel,
    semanticLabel: semanticLabel,
    onTap: () {},
    busy: busy,
    busySemanticLabel: busySemanticLabel,
  );
}

/// Every prop of [ItemBeacon] as a knob: the item (its name and glyph), who
/// has it, the status line, the spoken label, whether a long press is wired,
/// and the busy state with its announced label. The callbacks are plumbing:
/// the story owns them, and a long press is an "enabled" switch because null
/// means no secondary action. A used beacon or a busy one breathes unless the
/// system reduces motion.
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
      final status = context.enumKnob(
        'status',
        ItemStatus.values,
        initial: ItemStatus.free,
        description: 'Who has it: nobody, you, or someone else',
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
      final longPressEnabled = context.knobs.boolean(
        label: 'longPressEnabled',
        description: 'onLongPress is set: null means no secondary action',
      );
      final busy = context.knobs.boolean(
        label: 'busy',
        description: 'An action is running: a ring, and every tap is ignored',
      );
      final busySemanticLabel = context.textKnobOrNull(
        'busySemanticLabel',
        context.sample(en: 'Updating', es: 'Actualizando'),
        description: 'Announced as the value while busy',
      );

      return useCaseFrame(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ItemBeacon(
            item: ItemView(id: 'playground', name: name, icon: icon),
            status: status,
            statusLabel: statusLabel,
            semanticLabel: typedLabel.isEmpty ? sampleLabel : typedLabel,
            onTap: () {},
            onLongPress: longPressEnabled ? () {} : null,
            busy: busy,
            busySemanticLabel: busySemanticLabel,
          ),
        ),
      );
    },
  );
}

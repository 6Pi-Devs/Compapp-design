import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Width of the row. The golden harness sizes a scenario to its content, so a
/// row that takes the space that is left would be drawn with none.
const _rowWidth = 320.0;

/// One use case per tone and read state of the Molecules board: the amber
/// washer entry and the neutral admin entry, each unread (with its dot) and
/// read.
WidgetbookComponent buildActivityRow() {
  return WidgetbookComponent(
    name: 'ActivityRow',
    useCases: [
      _playground(),
      for (final tone in ActivityTone.values)
        for (final unread in const [true, false])
          WidgetbookUseCase(
            name: '${tone.name}-${unread ? 'unread' : 'read'}',
            builder: (context) {
              final busy = tone == ActivityTone.busy;
              final actor = busy ? 'Carlos' : 'Luis';
              final message = busy
                  ? context.sample(
                      en: 'finished your washer',
                      es: 'terminó tu lavadora',
                    )
                  : context.sample(
                      en: 'made you the admin',
                      es: 'te hizo administrador',
                    );
              final read = '$actor $message';
              return useCaseFrame(
                child: SizedBox(
                  width: _rowWidth,
                  child: ActivityRow(
                    entry: ActivityView(
                      id: tone.name,
                      icon: busy ? AppIcons.washer : AppIcons.adminKey,
                      tone: tone,
                      text: [
                        ActivityText('$actor ', strong: true),
                        ActivityText(message),
                      ],
                      meta: busy
                          ? context.sample(
                              en: 'Washer · 2 h ago',
                              es: 'Lavadora · hace 2 h',
                            )
                          : context.sample(
                              en: 'Home · Yesterday',
                              es: 'Casa · Ayer',
                            ),
                    ),
                    unread: unread,
                    semanticLabel: unread
                        ? '${context.sample(en: 'Unread', es: 'Sin leer')}. '
                              '$read'
                        : read,
                    onTap: () {},
                  ),
                ),
              );
            },
          ),
    ],
  );
}

/// Every prop of [ActivityRow] as a knob: the entry (glyph, tone, a strong run
/// between two plain ones, which is how the position of the bold text moves,
/// and the meta line), the unread state and the spoken label. The id is fixed
/// and the callback is plumbing: the story owns them.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final icon = context.enumKnob(
        'icon',
        AppIcons.values,
        initial: AppIcons.washer,
      );
      final tone = context.enumKnob(
        'tone',
        ActivityTone.values,
        initial: ActivityTone.busy,
      );
      final before = context.textKnob(
        'before',
        '',
        description: 'Plain text before the strong run, empty for none',
      );
      final strong = context.textKnob(
        'strong',
        'Carlos ',
        description: 'The strong run, empty for none: the spaces are yours',
      );
      final after = context.textKnob(
        'after',
        context.sample(en: 'finished your washer', es: 'terminó tu lavadora'),
        description: 'Plain text after the strong run, empty for none',
      );
      final meta = context.textKnobOrNull(
        'meta',
        context.sample(en: 'Washer · 2 h ago', es: 'Lavadora · hace 2 h'),
      );
      final unread = context.knobs.boolean(
        label: 'unread',
        description: 'Unread: a dot at the end of the row',
        initialValue: true,
      );
      final sampleLabel = context.sample(
        en: 'Carlos finished your washer',
        es: 'Carlos terminó tu lavadora',
      );
      final typedLabel = context.textKnob(
        'semanticLabel',
        sampleLabel,
        description:
            'What the row says, as in the visible text; the story adds '
            '"Unread." while unread is on. An empty one falls back to the '
            'sample',
      );
      final spoken = typedLabel.isEmpty ? sampleLabel : typedLabel;
      final runs = [
        if (before.isNotEmpty) ActivityText(before),
        if (strong.isNotEmpty) ActivityText(strong, strong: true),
        if (after.isNotEmpty) ActivityText(after),
      ];

      return useCaseFrame(
        child: SizedBox(
          width: _rowWidth,
          child: ActivityRow(
            entry: ActivityView(
              id: 'playground',
              icon: icon,
              tone: tone,
              text: runs.isEmpty ? [ActivityText(spoken)] : runs,
              meta: meta,
            ),
            unread: unread,
            semanticLabel: unread
                ? '${context.sample(en: 'Unread', es: 'Sin leer')}. $spoken'
                : spoken,
            onTap: () {},
          ),
        ),
      );
    },
  );
}

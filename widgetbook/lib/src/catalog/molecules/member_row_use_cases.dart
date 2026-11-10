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

/// One use case per state of the Molecules board: at home, away, invited and
/// you (the member of this device, with the inset ring on the pebble), and a
/// long one, whose long name, subtitle and trailing text reach the stacked
/// layout at the large text scale of the golden scenarios.
WidgetbookComponent buildMemberRow() {
  return WidgetbookComponent(
    name: 'MemberRow',
    useCases: [
      _playground(),
      for (final state in _MemberState.values)
        WidgetbookUseCase(
          name: 'row-${state.name}',
          builder: (context) => useCaseFrame(
            child: SizedBox(width: _rowWidth, child: _row(context, state)),
          ),
        ),
    ],
  );
}

enum _MemberState { home, away, invited, you, long }

Widget _row(BuildContext context, _MemberState state) {
  return switch (state) {
    _MemberState.home => MemberRow(
      member: MemberView(
        id: 'carlos',
        name: 'Carlos',
        initials: 'C',
        joinOrder: 1,
        semanticLabel: context.sample(
          en: 'Carlos, at home',
          es: 'Carlos, en casa',
        ),
      ),
      subtitle: context.sample(en: 'In the kitchen', es: 'En la cocina'),
      trailing: context.sample(en: 'since 5 h', es: 'desde hace 5 h'),
    ),
    _MemberState.away => MemberRow(
      member: MemberView(
        id: 'luis',
        name: 'Luis',
        initials: 'L',
        joinOrder: 2,
        status: MemberStatus.away,
        semanticLabel: context.sample(
          en: 'Luis, away',
          es: 'Luis, fuera de casa',
        ),
      ),
      subtitle: context.sample(
        en: 'Absence in the calendar',
        es: 'Ausencia en el calendario',
      ),
      trailing: context.sample(en: 'until Fri', es: 'hasta el vie'),
    ),
    _MemberState.invited => MemberRow(
      member: MemberView(
        id: 'marta',
        name: 'Marta',
        initials: 'M',
        joinOrder: 3,
        status: MemberStatus.invited,
        semanticLabel: context.sample(
          en: 'Marta, invited',
          es: 'Marta, invitada',
        ),
      ),
      subtitle: context.sample(en: 'Invited by Ana', es: 'Invitada por Ana'),
      trailing: context.sample(en: 'pending', es: 'pendiente'),
    ),
    _MemberState.you => MemberRow(
      member: MemberView(
        id: 'ana',
        name: context.sample(en: 'Ana (you)', es: 'Ana (tú)'),
        initials: 'A',
        joinOrder: 0,
        isYou: true,
        semanticLabel: context.sample(
          en: 'Ana, you, at home',
          es: 'Ana, tú, en casa',
        ),
      ),
      subtitle: context.sample(en: 'In Bedroom 1', es: 'En el dormitorio 1'),
      trailing: context.sample(en: 'since 3 h', es: 'desde hace 3 h'),
    ),
    _MemberState.long => MemberRow(
      member: MemberView(
        id: 'guillermo',
        name: context.sample(
          en: 'Alexander Montgomery',
          es: 'Guillermo Castellanos',
        ),
        initials: context.sample(en: 'AM', es: 'GC'),
        joinOrder: 4,
        semanticLabel: context.sample(
          en: 'Alexander Montgomery, at home',
          es: 'Guillermo Castellanos, en casa',
        ),
      ),
      subtitle: context.sample(
        en: 'Shared calendar',
        es: 'Calendario compartido',
      ),
      trailing: context.sample(
        en: 'until Friday night',
        es: 'hasta el viernes por la noche',
      ),
    ),
  };
}

const _maxJoinOrder = 11;

/// Every prop of [MemberRow] as a knob. The member is built from the knobs:
/// its name, initials, join order, status, you and admin, and its spoken
/// label. The pebble badges draw from s44 up, which is the size the row uses.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final name = context.textKnob(
        'name',
        context.sample(en: 'Ana (you)', es: 'Ana (tú)'),
      );
      final initials = context.textKnob('initials', 'A');
      final joinOrder = context.knobs.int
          .slider(
            label: 'joinOrder',
            description: 'Picks the pebble color, cycling through the palette',
            max: _maxJoinOrder,
            divisions: _maxJoinOrder,
          )
          .clamp(0, _maxJoinOrder);
      final status = context.enumKnob('status', MemberStatus.values);
      final isYou = context.knobs.boolean(label: 'isYou');
      final isAdmin = context.knobs.boolean(label: 'isAdmin');
      final sampleLabel = context.sample(
        en: 'Ana, you, at home',
        es: 'Ana, tú, en casa',
      );
      final typedLabel = context.textKnob(
        'semanticLabel',
        sampleLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final subtitle = context.textKnobOrNull(
        'subtitle',
        context.sample(en: 'In Bedroom 1', es: 'En el dormitorio 1'),
      );
      final trailing = context.textKnobOrNull(
        'trailing',
        context.sample(en: 'since 3 h', es: 'desde hace 3 h'),
        description: 'The status dot only shows beside a trailing text',
      );

      return useCaseFrame(
        child: SizedBox(
          width: _rowWidth,
          child: MemberRow(
            member: MemberView(
              id: 'playground',
              name: name,
              initials: initials,
              joinOrder: joinOrder,
              semanticLabel: typedLabel.isEmpty ? sampleLabel : typedLabel,
              status: status,
              isYou: isYou,
              isAdmin: isAdmin,
            ),
            subtitle: subtitle,
            trailing: trailing,
          ),
        ),
      );
    },
  );
}

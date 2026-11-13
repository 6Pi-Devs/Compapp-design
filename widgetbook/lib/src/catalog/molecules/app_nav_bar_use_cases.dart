import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per selected destination, plain and with a count on Calendar.
WidgetbookComponent buildAppNavBar() {
  return WidgetbookComponent(
    name: 'AppNavBar',
    useCases: [
      _playground(),
      for (final (index, name) in const [
        (0, 'home'),
        (1, 'things'),
        (2, 'tasks'),
        (3, 'calendar'),
      ])
        for (final (state, badge) in const [('default', 0), ('badge', 2)])
          WidgetbookUseCase(
            name: '$name-$state',
            builder: (context) => barFrame(
              child: AppNavBar(
                destinations: _destinations(context, calendarBadge: badge),
                selectedIndex: index,
                onSelected: _noop,
                semanticLabel: _landmark(context),
              ),
            ),
          ),
    ],
  );
}

void _noop(int _) {}

String _landmark(BuildContext context) =>
    context.sample(en: 'Main', es: 'Principal');

List<NavDestinationView> _destinations(
  BuildContext context, {
  required int calendarBadge,
}) => [
  NavDestinationView(
    id: 'home',
    icon: AppIcons.floorplan,
    label: context.sample(en: 'Home', es: 'Casa'),
  ),
  NavDestinationView(
    id: 'things',
    icon: AppIcons.washer,
    label: context.sample(en: 'Things', es: 'Cosas'),
  ),
  NavDestinationView(
    id: 'tasks',
    icon: AppIcons.tasks,
    label: context.sample(en: 'Tasks', es: 'Tareas'),
  ),
  NavDestinationView(
    id: 'calendar',
    icon: AppIcons.calendar,
    label: context.sample(en: 'Calendar', es: 'Calendario'),
    badgeCount: calendarBadge,
    semanticLabel: calendarBadge == 0
        ? null
        : context.sample(
            en: 'Calendar, $calendarBadge new events',
            es: 'Calendario, $calendarBadge eventos nuevos',
          ),
  ),
];

const _minPlaygroundDestinations = 2;
const int _maxPlaygroundDestinations = AppNavBar.maxDestinations;
const _maxPlaygroundBadge = 150;

/// Every prop of [AppNavBar] as a knob. `destinations` is the number of
/// destinations (2 to 4, the most the bar holds), taken from a pool of four.
/// The knobs that describe
/// one destination (`icon`, `label`, `badgeCount`, `destinationSemanticLabel`)
/// edit the one at `selectedIndex` as the knob sets it. Tapping a destination
/// still selects it: the selection is local state seeded by the knob.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final pool = _destinations(context, calendarBadge: 0);
      final count = context.knobs.int
          .slider(
            label: 'destinations',
            description: 'How many destinations the bar has',
            initialValue: 4,
            min: _minPlaygroundDestinations,
            max: _maxPlaygroundDestinations,
            divisions: _maxPlaygroundDestinations - _minPlaygroundDestinations,
          )
          .clamp(_minPlaygroundDestinations, _maxPlaygroundDestinations);
      final selected = context.knobs.int
          .slider(
            label: 'selectedIndex',
            description:
                'Starts here, and a tap moves it. Past the last '
                'destination it stops at the last',
            max: _maxPlaygroundDestinations - 1,
            divisions: _maxPlaygroundDestinations - 1,
          )
          .clamp(0, count - 1);
      final semanticLabel = context.textKnob(
        'semanticLabel',
        _landmark(context),
        description: 'Name of the navigation landmark',
      );
      final icon = context.enumKnob(
        'icon',
        AppIcons.values,
        initial: pool[selected].icon,
        description: 'Icon of the destination at selectedIndex',
      );
      final label = _nonEmpty(
        context.textKnob(
          'label',
          pool[selected].label,
          description:
              'Label of the destination at selectedIndex. An empty '
              'text falls back to the sample',
        ),
        pool[selected].label,
      );
      final badge = context.knobs.int
          .slider(
            label: 'badgeCount',
            description:
                'Count on the destination at selectedIndex. 0 draws '
                'none, past 99 shows 99+',
            max: _maxPlaygroundBadge,
            divisions: _maxPlaygroundBadge,
          )
          .clamp(0, _maxPlaygroundBadge);
      final spokenKnob = context.textKnobOrNull(
        'destinationSemanticLabel',
        null,
        description: 'Spoken name of the destination at selectedIndex',
      );

      final spoken = spokenKnob == null || spokenKnob.isEmpty
          ? null
          : spokenKnob;

      final destinations = [
        for (final (index, destination) in pool.take(count).indexed)
          if (index == selected)
            NavDestinationView(
              id: destination.id,
              icon: icon,
              label: label,
              badgeCount: badge,
              semanticLabel: spoken,
            )
          else
            destination,
      ];

      return useCaseFrame(
        child: SeededState<int>(
          initial: selected,
          builder: (context, value, onChanged) => AppNavBar(
            destinations: destinations,
            selectedIndex: value,
            onSelected: onChanged,
            semanticLabel: semanticLabel,
          ),
        ),
      );
    },
  );
}

/// The label asserts it is not empty, so a hand-edited empty one falls back.
String _nonEmpty(String value, String fallback) =>
    value.isEmpty ? fallback : value;

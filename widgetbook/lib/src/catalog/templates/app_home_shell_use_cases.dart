import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The height of the shell in a use case: the shell fills the height it is
/// given, so a use case gives it a phone screen.
const _shellHeight = 640.0;

/// The tabs of the app, in the order of the nav bar. The id names the use
/// case and the manifest variant.
enum _Tab { home, things, tasks, calendar }

/// The states of every tab: the plain shell, and the shell with the unread
/// count on the bell and a count on Calendar.
const _states = [('default', false), ('badges', true)];

/// One use case per tab and state: the shell with the body of that tab, a real
/// organism or the molecules of the board. The bodies follow the business
/// rules: the plan shows who is home and who is away, the items are in use by
/// one person at a time, a task shows when it was last done and never who is
/// behind, and the calendar is informational.
WidgetbookComponent buildAppHomeShell() {
  return WidgetbookComponent(
    name: 'AppHomeShell',
    useCases: [
      _playground(),
      for (final tab in _Tab.values)
        for (final (state, badges) in _states)
          WidgetbookUseCase(
            name: '${tab.name}-$state',
            builder: (context) => FrozenMotion(
              child: _frame(
                context,
                AppHomeShell(
                  title: _title(context),
                  subtitle: _subtitle(context, tab),
                  activityLabel: _activityLabel(context, badges ? 3 : 0),
                  unreadCount: badges ? 3 : 0,
                  onActivity: _noop,
                  me: _me(context),
                  accountLabel: _accountLabel(context),
                  onAccount: _noop,
                  destinations: _destinations(
                    context,
                    calendarBadge: badges ? 2 : 0,
                  ),
                  selectedIndex: tab.index,
                  onTabSelected: _ignore,
                  navigationLabel: _landmark(context),
                  body: _body(context, tab),
                ),
              ),
            ),
          ),
    ],
  );
}

void _noop() {}

void _ignore(int index) {}

/// The shell on a phone screen, with a hairline so a golden shows where the
/// screen ends.
Widget _frame(BuildContext context, Widget shell) {
  return useCaseFrame(
    child: SizedBox(
      width: barStoryWidth,
      height: _shellHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: shell,
      ),
    ),
  );
}

String _title(BuildContext context) =>
    context.sample(en: 'Calle Luna 12', es: 'Calle Luna 12');

String _subtitle(BuildContext context, _Tab tab) => switch (tab) {
  _Tab.home => context.sample(
    en: 'Ana and Carlos are home',
    es: 'Ana y Carlos están en casa',
  ),
  _Tab.things => context.sample(
    en: 'The washer is in use',
    es: 'La lavadora está en uso',
  ),
  _Tab.tasks => context.sample(
    en: 'Last done, newest first',
    es: 'Lo último hecho, primero',
  ),
  _Tab.calendar => context.sample(en: 'This week', es: 'Esta semana'),
};

String _activityLabel(BuildContext context, int unread) => unread == 0
    ? context.sample(en: 'Activity', es: 'Actividad')
    : context.sample(
        en: 'Activity, $unread unread',
        es: 'Actividad, $unread sin leer',
      );

String _accountLabel(BuildContext context) =>
    context.sample(en: 'Your account', es: 'Tu cuenta');

String _landmark(BuildContext context) =>
    context.sample(en: 'Main', es: 'Principal');

MemberView _me(BuildContext context) => const MemberView(
  id: 'ana',
  name: 'Ana',
  initials: 'A',
  joinOrder: 0,
  semanticLabel: 'Ana',
  isYou: true,
  isAdmin: true,
);

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

/// The body of a tab, scrolling inside the room the shell leaves it.
Widget _body(BuildContext context, _Tab tab) {
  final content = switch (tab) {
    _Tab.home => _plan(context),
    _Tab.things => _things(context),
    _Tab.tasks => _tasks(context),
    _Tab.calendar => _week(context),
  };
  return SingleChildScrollView(
    key: Key('sample.body.${tab.name}'),
    padding: const EdgeInsets.all(AppSpacing.md),
    child: content,
  );
}

MemberView _member(
  BuildContext context,
  String id,
  String name,
  int joinOrder, {
  MemberStatus status = MemberStatus.home,
}) => MemberView(
  id: id,
  name: name,
  initials: name[0],
  joinOrder: joinOrder,
  status: status,
  semanticLabel: status == MemberStatus.away
      ? context.sample(en: '$name, away', es: '$name, fuera')
      : name,
);

Widget _plan(BuildContext context) {
  final carlos = _member(context, 'carlos', 'Carlos', 1);
  return FloorplanMap(
    view: FloorplanView(
      rooms: [
        FloorplanRoom(
          room: RoomView(
            id: 'ana',
            name: context.sample(en: "Ana's room", es: 'Cuarto de Ana'),
          ),
          kind: FloorplanRoomKind.bedroom,
          state: RoomTileState.home,
          caption: context.sample(en: 'Home · 3 h', es: 'En casa · 3 h'),
          semanticLabel: context.sample(
            en: "Ana's room, Ana is home, 3 hours",
            es: 'Cuarto de Ana, Ana está en casa, 3 horas',
          ),
          occupants: [_member(context, 'ana', 'Ana', 0)],
        ),
        FloorplanRoom(
          room: RoomView(
            id: 'bathroom',
            name: context.sample(en: 'Bathroom', es: 'Baño'),
          ),
          kind: FloorplanRoomKind.common,
          state: RoomTileState.occupied,
          caption: context.sample(
            en: 'In use · 12 min',
            es: 'Ocupado · 12 min',
          ),
          semanticLabel: context.sample(
            en: 'Bathroom, occupied by Carlos, 12 minutes',
            es: 'Baño, ocupado por Carlos, 12 minutos',
          ),
          occupants: [carlos],
        ),
        FloorplanRoom(
          room: RoomView(
            id: 'luis',
            name: context.sample(en: "Luis's room", es: 'Cuarto de Luis'),
          ),
          kind: FloorplanRoomKind.bedroom,
          state: RoomTileState.away,
          caption: context.sample(en: 'Away', es: 'Fuera'),
          semanticLabel: context.sample(
            en: "Luis's room, Luis is away",
            es: 'Cuarto de Luis, Luis está fuera',
          ),
        ),
        FloorplanRoom(
          room: RoomView(
            id: 'kitchen',
            name: context.sample(en: 'Kitchen', es: 'Cocina'),
          ),
          kind: FloorplanRoomKind.common,
          state: RoomTileState.free,
          caption: context.sample(en: 'Free', es: 'Libre'),
          semanticLabel: context.sample(
            en: 'Kitchen, free',
            es: 'Cocina, libre',
          ),
        ),
      ],
      absences: [
        FloorplanAbsence(
          member: _member(
            context,
            'luis',
            'Luis',
            2,
            status: MemberStatus.away,
          ),
          label: context.sample(en: 'until Fri', es: 'hasta el vie'),
        ),
      ],
      awayLabel: context.sample(en: 'Away', es: 'Fuera'),
      emptyTitle: context.sample(
        en: 'No rooms yet',
        es: 'Todavía no hay habitaciones',
      ),
      emptyBody: context.sample(
        en: 'Add the rooms of the home to see them here.',
        es: 'Añade las habitaciones de la casa para verlas aquí.',
      ),
      loadingLabel: context.sample(
        en: 'Loading the plan',
        es: 'Cargando el plano',
      ),
    ),
    onRoomTap: _ignoreId,
    onItemTap: _ignoreId,
    onMemberTap: _ignoreId,
  );
}

void _ignoreId(String id) {}

Widget _things(BuildContext context) {
  Widget beacon({
    required String id,
    required AppIcons icon,
    required String name,
    required bool inUse,
    required String status,
    required String spoken,
  }) => ItemBeacon(
    item: ItemView(id: id, name: name, icon: icon),
    inUse: inUse,
    statusLabel: status,
    semanticLabel: spoken,
    onTap: _noop,
  );

  return Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.md,
    children: [
      beacon(
        id: 'washer',
        icon: AppIcons.washer,
        name: context.sample(en: 'Washer', es: 'Lavadora'),
        inUse: true,
        status: context.sample(en: '34 min', es: '34 min'),
        spoken: context.sample(
          en: 'Washer, in use by Carlos, 34 minutes',
          es: 'Lavadora, en uso por Carlos, 34 minutos',
        ),
      ),
      beacon(
        id: 'dryer',
        icon: AppIcons.dryer,
        name: context.sample(en: 'Dryer', es: 'Secadora'),
        inUse: false,
        status: context.sample(en: 'Free', es: 'Libre'),
        spoken: context.sample(en: 'Dryer, free', es: 'Secadora, libre'),
      ),
      beacon(
        id: 'oven',
        icon: AppIcons.oven,
        name: context.sample(en: 'Oven', es: 'Horno'),
        inUse: false,
        status: context.sample(en: 'Free', es: 'Libre'),
        spoken: context.sample(en: 'Oven, free', es: 'Horno, libre'),
      ),
    ],
  );
}

Widget _tasks(BuildContext context) {
  Widget row(String id, String title, int days, String when, String where) =>
      TaskRow(
        task: TaskView(id: id, title: title, ageDays: days),
        subtitle: '$when · $where',
        logAgainSemanticLabel: context.sample(
          en: 'Log $title again',
          es: 'Registrar de nuevo: $title',
        ),
        onLogAgain: _noop,
      );

  return Column(
    spacing: AppSpacing.sm,
    children: [
      row(
        'kitchen',
        context.sample(en: 'Clean the kitchen', es: 'Limpiar la cocina'),
        0,
        context.sample(en: 'Carlos · today', es: 'Carlos · hoy'),
        context.sample(en: 'Kitchen', es: 'Cocina'),
      ),
      row(
        'bins',
        context.sample(en: 'Take out the bins', es: 'Sacar la basura'),
        1,
        context.sample(en: 'Ana · yesterday', es: 'Ana · ayer'),
        context.sample(en: 'Hall', es: 'Pasillo'),
      ),
      row(
        'bathroom',
        context.sample(en: 'Clean the bathroom', es: 'Limpiar el baño'),
        9,
        context.sample(en: 'Luis · 9 days ago', es: 'Luis · hace 9 días'),
        context.sample(en: 'Bathroom', es: 'Baño'),
      ),
    ],
  );
}

String _date(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The week of 2 to 8 November 2026, with today on Tuesday, an absence of Luis
/// and a visit.
Widget _week(BuildContext context) {
  final start = DateTime.utc(2026, 11, 2);
  final weekdays = [
    (
      context.sample(en: 'Mon', es: 'lun'),
      context.sample(en: 'Monday', es: 'lunes'),
    ),
    (
      context.sample(en: 'Tue', es: 'mar'),
      context.sample(en: 'Tuesday', es: 'martes'),
    ),
    (
      context.sample(en: 'Wed', es: 'mié'),
      context.sample(en: 'Wednesday', es: 'miércoles'),
    ),
    (
      context.sample(en: 'Thu', es: 'jue'),
      context.sample(en: 'Thursday', es: 'jueves'),
    ),
    (
      context.sample(en: 'Fri', es: 'vie'),
      context.sample(en: 'Friday', es: 'viernes'),
    ),
    (
      context.sample(en: 'Sat', es: 'sáb'),
      context.sample(en: 'Saturday', es: 'sábado'),
    ),
    (
      context.sample(en: 'Sun', es: 'dom'),
      context.sample(en: 'Sunday', es: 'domingo'),
    ),
  ];
  final days = [
    for (var i = 0; i < 7; i++)
      CalendarStripDay(
        date: _date(start.add(Duration(days: i))),
        weekday: weekdays[i].$1,
        dayNumber: '${2 + i}',
        semanticLabel: context.sample(
          en: '${weekdays[i].$2} ${2 + i} November${i == 1 ? ', today' : ''}',
          es: '${weekdays[i].$2} ${2 + i} de noviembre${i == 1 ? ', hoy' : ''}',
        ),
      ),
  ];
  final absence = context.sample(
    en: 'Luis away · until Fri',
    es: 'Luis fuera · hasta el vie',
  );
  final visit = context.sample(en: 'Visit', es: 'Visita');
  return CalendarStrip(
    view: CalendarStripView(
      days: days,
      today: days[1].date,
      events: [
        CalendarStripEvent(
          event: CalendarEventView(
            id: 'luis-away',
            kind: CalendarEventKind.absence,
            title: absence,
          ),
          startDate: days[0].date,
          endDate: days[4].date,
          semanticLabel: context.sample(
            en: 'Absence. $absence 6 Nov',
            es: 'Ausencia. $absence 6 nov',
          ),
        ),
        CalendarStripEvent(
          event: CalendarEventView(
            id: 'marta-visit',
            kind: CalendarEventKind.visit,
            title: visit,
          ),
          startDate: days[3].date,
          endDate: days[3].date,
          semanticLabel: context.sample(
            en: '$visit, Thu 5 Nov',
            es: '$visit, jue 5 nov',
          ),
        ),
      ],
    ),
    onDayTap: _ignoreId,
    onEventTap: _ignoreId,
  );
}

const _maxPlaygroundBadge = 150;

/// Every prop of [AppHomeShell] as a knob: the title, the subtitle (empty or
/// null draws none), the spoken names of the bell, the account and the
/// landmark, the unread count, how many destinations the bar has (2 to 4, taken
/// from a pool of four), the selected one and the count on Calendar (a count is
/// plain data of a destination), and the body, which is the sample of the
/// selected tab. Tapping a destination still selects it: the selection is
/// local state seeded by the knob. The callbacks are plumbing: the story owns
/// them. A title or a label must not be empty, so an empty one falls back to
/// the sample.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      String text(String label, String initial) {
        final typed = context.textKnob(
          label,
          initial,
          description:
              'Must not be empty: an empty one falls back to the sample',
        );
        return typed.isEmpty ? initial : typed;
      }

      final title = text('title', _title(context));
      final subtitle = context.textKnobOrNull(
        'subtitle',
        _subtitle(context, _Tab.home),
        description: 'Second line of the bar. Empty or null draws none',
      );
      final unread = context.knobs.int
          .slider(
            label: 'unreadCount',
            description: 'Count on the bell. 0 draws none, past 99 shows 99+',
            max: _maxPlaygroundBadge,
            divisions: _maxPlaygroundBadge,
          )
          .clamp(0, _maxPlaygroundBadge);
      final activityLabel = text(
        'activityLabel',
        _activityLabel(context, unread),
      );
      final accountLabel = text('accountLabel', _accountLabel(context));
      final navigationLabel = text('navigationLabel', _landmark(context));
      final count = context.knobs.int
          .slider(
            label: 'destinations',
            description: 'How many destinations the bar has',
            initialValue: 4,
            min: 2,
            max: AppNavBar.maxDestinations,
            divisions: AppNavBar.maxDestinations - 2,
          )
          .clamp(2, AppNavBar.maxDestinations);
      final selected = context.knobs.int
          .slider(
            label: 'selectedIndex',
            description:
                'Starts here, and a tap moves it. Past the last '
                'destination it stops at the last',
            max: AppNavBar.maxDestinations - 1,
            divisions: AppNavBar.maxDestinations - 1,
          )
          .clamp(0, count - 1);
      final calendarBadge = context.knobs.int
          .slider(
            label: 'calendarBadgeCount',
            description:
                'Count on the Calendar destination when it is in the bar. '
                '0 draws none',
            max: _maxPlaygroundBadge,
            divisions: _maxPlaygroundBadge,
          )
          .clamp(0, _maxPlaygroundBadge);
      final destinations = _destinations(
        context,
        calendarBadge: calendarBadge,
      ).take(count).toList();

      return FrozenMotion(
        child: _frame(
          context,
          SeededState<int>(
            initial: selected,
            builder: (context, value, onChanged) => AppHomeShell(
              title: title,
              subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
              activityLabel: activityLabel,
              unreadCount: unread,
              onActivity: _noop,
              me: _me(context),
              accountLabel: accountLabel,
              onAccount: _noop,
              destinations: destinations,
              selectedIndex: value,
              onTabSelected: onChanged,
              navigationLabel: navigationLabel,
              body: _body(
                context,
                _Tab.values.firstWhere(
                  (tab) => tab.name == destinations[value].id,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

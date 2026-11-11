import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The most entries a group of a story or the playground shows: the length of
/// each sample pool.
const _poolSize = 3;

/// The most unread entries beyond the listed ones the playground can claim.
const _maxMoreUnread = 20;

/// The states of the Organisms board and its contract: new and earlier
/// entries together, everything read, and nothing at all.
enum _ListState {
  newAndEarlier('new-and-earlier', unread: 2, earlier: 2),
  allRead('all-read', unread: 0, earlier: 3),
  empty('empty', unread: 0, earlier: 0);

  new(this.id, {required this.unread, required this.earlier});

  final String id;
  final int unread;
  final int earlier;
}

/// One use case per state of the board: the new entries with their count and
/// the action, the earlier ones under their own heading, all of them read, and
/// the empty state. Nothing moves, so no motion is frozen.
WidgetbookComponent buildActivityList() {
  return WidgetbookComponent(
    name: 'ActivityList',
    useCases: [
      _playground(),
      for (final state in _ListState.values)
        WidgetbookUseCase(
          name: 'list-${state.id}',
          builder: (context) => barFrame(
            child: ActivityList(
              view: _view(
                context,
                unread: state.unread,
                earlier: state.earlier,
              ),
              onOpen: _ignore,
              onMarkAllRead: _noop,
            ),
          ),
        ),
    ],
  );
}

void _noop() {}

void _ignore(String id) {}

ActivityEntry _entry({
  required String id,
  required AppIcons icon,
  required List<ActivityText> text,
  required String meta,
  ActivityTone tone = ActivityTone.neutral,
}) => ActivityEntry(
  view: ActivityView(id: id, icon: icon, tone: tone, text: text, meta: meta),
  semanticLabel: text.map((run) => run.text).join(),
);

/// The new entries of the board, then a third. The first two are the board's.
List<ActivityEntry> _unreadPool(BuildContext context) => [
  _entry(
    id: 'oven',
    icon: AppIcons.oven,
    tone: ActivityTone.busy,
    text: [
      const ActivityText('Carlos ', strong: true),
      ActivityText(
        context.sample(
          en: 'asked you to free the oven',
          es: 'te pidió liberar el horno',
        ),
      ),
    ],
    meta: context.sample(en: 'Oven · 4 min ago', es: 'Horno · hace 4 min'),
  ),
  _entry(
    id: 'calendar',
    icon: AppIcons.calendar,
    text: [
      const ActivityText('Carlos ', strong: true),
      ActivityText(
        context.sample(
          en: 'added “Sara stays over”',
          es: 'añadió “Sara se queda a dormir”',
        ),
      ),
    ],
    meta: context.sample(en: 'Calendar · 1 h ago', es: 'Calendario · hace 1 h'),
  ),
  _entry(
    id: 'dishwasher',
    icon: AppIcons.dishwasher,
    tone: ActivityTone.busy,
    text: [
      const ActivityText('Luis ', strong: true),
      ActivityText(
        context.sample(
          en: 'finished the dishwasher',
          es: 'terminó el lavavajillas',
        ),
      ),
    ],
    meta: context.sample(
      en: 'Dishwasher · 3 h ago',
      es: 'Lavavajillas · hace 3 h',
    ),
  ),
];

/// The earlier entries: the board's room draw first.
List<ActivityEntry> _earlierPool(BuildContext context) => [
  _entry(
    id: 'draw',
    icon: AppIcons.draw,
    text: [
      ActivityText(
        context.sample(en: 'Room draw: you got ', es: 'Sorteo: te tocó el '),
      ),
      ActivityText(
        context.sample(en: 'Bedroom 1', es: 'dormitorio 1'),
        strong: true,
      ),
    ],
    meta: context.sample(en: 'Rooms · Yesterday', es: 'Dormitorios · Ayer'),
  ),
  _entry(
    id: 'washer',
    icon: AppIcons.washer,
    tone: ActivityTone.busy,
    text: [
      const ActivityText('Luis ', strong: true),
      ActivityText(
        context.sample(en: 'finished your washer', es: 'terminó tu lavadora'),
      ),
    ],
    meta: context.sample(en: 'Washer · Yesterday', es: 'Lavadora · Ayer'),
  ),
  _entry(
    id: 'joined',
    icon: AppIcons.add,
    text: [
      const ActivityText('Marta ', strong: true),
      ActivityText(
        context.sample(en: 'joined the home', es: 'se unió a la casa'),
      ),
    ],
    meta: context.sample(en: 'Home · 2 days ago', es: 'Casa · hace 2 días'),
  ),
];

ActivityListView _view(
  BuildContext context, {
  required int unread,
  required int earlier,
  int moreUnread = 0,
  String? unreadTitle,
  String? unreadSemanticLabel,
  String? unreadPrefix,
  String? earlierTitle,
  String? markAllReadLabel,
  String? emptyTitle,
  String? emptyBody,
}) {
  return ActivityListView(
    unread: _unreadPool(context).take(unread).toList(),
    earlier: _earlierPool(context).take(earlier).toList(),
    unreadCount: unread + moreUnread,
    unreadTitle: unreadTitle ?? context.sample(en: 'New', es: 'Nuevas'),
    unreadSemanticLabel:
        unreadSemanticLabel ??
        context.sample(
          en: 'New, ${unread + moreUnread} unread',
          es: 'Nuevas, ${unread + moreUnread} sin leer',
        ),
    unreadPrefix: unreadPrefix ?? context.sample(en: 'Unread', es: 'Sin leer'),
    earlierTitle:
        earlierTitle ?? context.sample(en: 'Earlier', es: 'Anteriores'),
    markAllReadLabel:
        markAllReadLabel ??
        context.sample(en: 'Mark all as read', es: 'Marcar todo como leído'),
    emptyTitle:
        emptyTitle ??
        context.sample(en: 'Nothing new yet', es: 'Aún no hay novedades'),
    emptyBody:
        emptyBody ??
        context.sample(
          en: 'When someone in the home does something, you will see it here.',
          es: 'Cuando alguien de la casa haga algo, lo verás aquí.',
        ),
  );
}

/// Every prop of [ActivityList] as a knob: how many new and earlier entries
/// (from the sample pools, so both empty shows the empty state), the headings,
/// the spoken first heading, the label of the action and the words of the
/// empty state. The callbacks are plumbing: the story owns them.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final unread = context.knobs.int
          .slider(
            label: 'unreadEntries',
            description: 'How many new entries, none leaves the heading out',
            initialValue: 2,
            max: _poolSize,
            divisions: _poolSize,
          )
          .clamp(0, _poolSize);
      final earlier = context.knobs.int
          .slider(
            label: 'earlierEntries',
            description:
                'How many earlier entries, none leaves the heading out',
            initialValue: 1,
            max: _poolSize,
            divisions: _poolSize,
          )
          .clamp(0, _poolSize);
      final moreUnread = context.knobs.int
          .slider(
            label: 'moreUnread',
            description:
                'Unread entries the app has beyond the ones listed, as when '
                'it pages: the badge counts them too',
          )
          .clamp(0, _maxMoreUnread);
      final sample = _view(
        context,
        unread: unread,
        earlier: earlier,
        moreUnread: moreUnread,
      );
      String text(String label, String initial, {String? note}) {
        final typed = context.textKnob(
          label,
          initial,
          description:
              note ??
              'Must not be empty: an empty one falls back to the sample',
        );
        return typed.isEmpty ? initial : typed;
      }

      // A playground can grow taller than the preview, and the organism is not
      // a scrollable: it scrolls as it would inside a screen.
      return SingleChildScrollView(
        child: barFrame(
          child: ActivityList(
            view: ActivityListView(
              unread: sample.unread,
              earlier: sample.earlier,
              unreadCount: sample.unreadCount,
              unreadPrefix: text('unreadPrefix', sample.unreadPrefix),
              unreadTitle: text('unreadTitle', sample.unreadTitle),
              unreadSemanticLabel: text(
                'unreadSemanticLabel',
                sample.unreadSemanticLabel,
                note:
                    'What the first heading says, with the count in words: it '
                    'does not follow the entries or moreUnread. An empty one '
                    'falls back to the sample',
              ),
              earlierTitle: text('earlierTitle', sample.earlierTitle),
              markAllReadLabel: text(
                'markAllReadLabel',
                sample.markAllReadLabel,
              ),
              emptyTitle: text('emptyTitle', sample.emptyTitle),
              emptyBody: text('emptyBody', sample.emptyBody),
            ),
            onOpen: _ignore,
            onMarkAllRead: _noop,
          ),
        ),
      );
    },
  );
}

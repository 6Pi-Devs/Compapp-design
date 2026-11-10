import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per bar and text: the plain bar and one with long Spanish-like
/// text that has to wrap.
WidgetbookComponent buildAppTopBar() {
  return WidgetbookComponent(
    name: 'AppTopBar',
    useCases: [
      _playground(),
      for (final variant in AppTopBarVariant.values)
        for (final (state, long) in const [
          ('default', false),
          ('long-text', true),
        ])
          WidgetbookUseCase(
            name: '${variant.name}-$state',
            builder: (context) =>
                barFrame(child: _bar(context, variant, long: long)),
          ),
    ],
  );
}

void _noop() {}

/// The member behind the account pebble. The bar reads only the initials and
/// the join order, so the other fields are plumbing the story owns.
MemberView _member(
  BuildContext context, {
  required String initials,
  required int joinOrder,
}) => MemberView(
  id: 'me',
  name: context.sample(en: 'Ana (you)', es: 'Ana (tú)'),
  initials: initials,
  joinOrder: joinOrder,
  semanticLabel: context.sample(
    en: 'Ana, you, at home',
    es: 'Ana, tú, en casa',
  ),
  isYou: true,
);

Widget _bar(
  BuildContext context,
  AppTopBarVariant variant, {
  required bool long,
}) {
  return switch (variant) {
    AppTopBarVariant.home => AppTopBar.home(
      title: long
          ? context.sample(
              en: 'The shared flat on Doctor Fleming street, number twelve',
              es: 'El piso compartido de la calle Doctor Fleming, número doce',
            )
          : 'Calle Luna 12',
      subtitle: long
          ? context.sample(
              en: '2 people at home and 1 person away until tomorrow',
              es: '2 personas en casa y 1 persona fuera hasta mañana',
            )
          : context.sample(en: '2 home · 1 away', es: '2 en casa · 1 fuera'),
      activityLabel: context.sample(
        en: 'Activity, ${long ? 120 : 3} unread',
        es: 'Actividad, ${long ? 120 : 3} sin leer',
      ),
      unreadCount: long ? 120 : 3,
      onActivity: _noop,
      me: _member(context, initials: 'A', joinOrder: 0),
      accountLabel: context.sample(en: 'Your account', es: 'Tu cuenta'),
      onAccount: _noop,
    ),
    AppTopBarVariant.pushed => AppTopBar.pushed(
      title: long
          ? context.sample(
              en: 'Everything that happened in the flat this week',
              es: 'Todo lo que ha pasado en el piso durante esta semana',
            )
          : context.sample(en: 'Activity', es: 'Actividad'),
      backLabel: context.sample(en: 'Back', es: 'Atrás'),
      onBack: _noop,
      actionLabel: long
          ? context.sample(
              en: 'Mark everything as read',
              es: 'Marcar todo como leído',
            )
          : context.sample(en: 'Mark all as read', es: 'Marcar como leído'),
      onAction: _noop,
    ),
  };
}

const _maxPlaygroundUnread = 150;
const _maxPlaygroundJoinOrder = 10;

/// Every prop of [AppTopBar] as a knob, `me` through the three fields the bar
/// reads. The form picks the home or the pushed
/// constructor, and only the knobs of that form show an effect. All knobs are
/// registered in both forms. The callbacks are plumbing the story owns.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final form = context.enumKnob('form', AppTopBarVariant.values);
      final home = form == AppTopBarVariant.home;
      final title = context.textKnob(
        'title',
        home
            ? 'Calle Luna 12'
            : context.sample(en: 'Activity', es: 'Actividad'),
        description: 'Both forms',
      );
      final subtitle = context.textKnobOrNull(
        'subtitle',
        context.sample(en: '2 home · 1 away', es: '2 en casa · 1 fuera'),
        description: 'Home form. Empty leaves the line out',
      );
      final activitySample = context.sample(
        en: 'Activity, 3 unread',
        es: 'Actividad, 3 sin leer',
      );
      final activityLabel = _nonEmpty(
        context.textKnob(
          'activityLabel',
          activitySample,
          description: 'Home form. An empty text falls back to the sample',
        ),
        activitySample,
      );
      final unreadCount = context.knobs.int
          .slider(
            label: 'unreadCount',
            description: 'Home form. 0 draws no badge, past 99 shows 99+',
            initialValue: 3,
            max: _maxPlaygroundUnread,
            divisions: _maxPlaygroundUnread,
          )
          .clamp(0, _maxPlaygroundUnread);
      final initials = context.textKnob(
        'meInitials',
        'A',
        description: 'Home form. Initials of the member in the account pebble',
      );
      final joinOrder = context.knobs.int
          .slider(
            label: 'meJoinOrder',
            description: 'Home form. Picks the pebble color',
            max: _maxPlaygroundJoinOrder,
            divisions: _maxPlaygroundJoinOrder,
          )
          .clamp(0, _maxPlaygroundJoinOrder);
      final accountLabel = _nonEmpty(
        context.textKnob(
          'accountLabel',
          context.sample(en: 'Your account', es: 'Tu cuenta'),
          description: 'Home form. An empty text falls back to the sample',
        ),
        context.sample(en: 'Your account', es: 'Tu cuenta'),
      );
      final backSample = context.sample(en: 'Back', es: 'Atrás');
      final backLabel = _nonEmpty(
        context.textKnob(
          'backLabel',
          backSample,
          description: 'Pushed form. An empty text falls back to the sample',
        ),
        backSample,
      );
      final actionLabel = context.textKnobOrNull(
        'actionLabel',
        context.sample(en: 'Mark all as read', es: 'Marcar como leído'),
        description: 'Pushed form. Empty leaves the action out',
      );
      final actionEnabled = context.knobs.boolean(
        label: 'actionEnabled',
        description: 'Pushed form. Off means a null onAction',
        initialValue: true,
      );

      return useCaseFrame(
        child: home
            ? AppTopBar.home(
                title: title,
                subtitle: subtitle,
                activityLabel: activityLabel,
                unreadCount: unreadCount,
                onActivity: _noop,
                me: _member(context, initials: initials, joinOrder: joinOrder),
                accountLabel: accountLabel,
                onAccount: _noop,
              )
            : AppTopBar.pushed(
                title: title,
                backLabel: backLabel,
                onBack: _noop,
                actionLabel: actionLabel,
                onAction: actionEnabled ? _noop : null,
              ),
      );
    },
  );
}

/// The pebble asserts a spoken label, so a hand-edited empty one falls back.
String _nonEmpty(String value, String fallback) =>
    value.isEmpty ? fallback : value;

import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The most members a group of the playground shows: the length of each sample
/// pool.
const _poolSize = 3;

const _ringDivisions = 20;

/// The ring and the texts of the board's wait: 11 of 15 minutes left.
const _boardRemaining = 0.73;

/// One use case per state of the Organisms board and its contract: the home
/// can be asked, the home was asked a short time ago and the button waits, and
/// everyone is away. The ring does not move, so no motion is frozen.
WidgetbookComponent buildPresencePanel() {
  return WidgetbookComponent(
    name: 'PresencePanel',
    useCases: [
      _playground(),
      WidgetbookUseCase(
        name: 'panel-ready',
        builder: (context) => barFrame(
          child: PresencePanel(
            view: PresenceView(
              home: _group(context, _Section.home, [
                _Sample.ana,
                _Sample.carlos,
              ]),
              away: _group(context, _Section.away, [_Sample.luis]),
              invited: _group(context, _Section.invited, [_Sample.marta]),
              broadcast: _broadcast(context),
            ),
            onKnock: _noop,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'panel-cooldown',
        builder: (context) => barFrame(
          child: PresencePanel(
            view: PresenceView(
              home: _group(context, _Section.home, [_Sample.carlos]),
              away: _group(context, _Section.away, [_Sample.luis]),
              broadcast: _broadcast(
                context,
                cooldown: _boardCooldown(context),
                message: context.sample(
                  en: 'Carlos asked 4 min ago',
                  es: 'Carlos preguntó hace 4 min',
                ),
              ),
            ),
            onKnock: _noop,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'panel-everyone-away',
        builder: (context) => barFrame(
          child: PresencePanel(
            view: PresenceView(
              home: _group(
                context,
                _Section.home,
                const [],
                emptyLabel: _emptyHome(context),
              ),
              away: _group(context, _Section.away, [
                _Sample.anaAway,
                _Sample.luis,
              ]),
              broadcast: _broadcast(context),
            ),
            onKnock: _noop,
          ),
        ),
      ),
    ],
  );
}

void _noop() {}

enum _Section { home, away, invited }

/// A sample member: the stable ids and join orders keep the pebble colors
/// the same in every story.
enum _Sample {
  ana('ana', 'A', 0, MemberStatus.home, isYou: true),
  carlos('carlos', 'C', 1, MemberStatus.home),
  sara('sara', 'S', 4, MemberStatus.home),
  anaAway('ana', 'A', 0, MemberStatus.away, isYou: true),
  luis('luis', 'L', 2, MemberStatus.away),
  pablo('pablo', 'P', 5, MemberStatus.away),
  eva('eva', 'E', 6, MemberStatus.away),
  marta('marta', 'M', 3, MemberStatus.invited),
  jon('jon', 'J', 7, MemberStatus.invited),
  lia('lia', 'L', 8, MemberStatus.invited);

  new(
    this.id,
    this.initials,
    this.joinOrder,
    this.status, {
    this.isYou = false,
  });

  final String id;
  final String initials;
  final int joinOrder;
  final MemberStatus status;
  final bool isYou;
}

String _name(BuildContext context, _Sample sample) => switch (sample) {
  _Sample.ana ||
  _Sample.anaAway => context.sample(en: 'Ana (you)', es: 'Ana (tú)'),
  _Sample.carlos => 'Carlos',
  _Sample.sara => 'Sara',
  _Sample.luis => 'Luis',
  _Sample.pablo => 'Pablo',
  _Sample.eva => 'Eva',
  _Sample.marta => 'Marta',
  _Sample.jon => 'Jon',
  _Sample.lia => 'Lía',
};

PresenceEntry _entry(BuildContext context, _Sample sample) {
  final name = _name(context, sample);
  final (spoken, subtitle, trailing) = switch (sample.status) {
    MemberStatus.home => (
      sample.isYou
          ? context.sample(en: 'Ana, you, at home', es: 'Ana, tú, en casa')
          : context.sample(en: '$name, at home', es: '$name, en casa'),
      context.sample(en: 'In the kitchen', es: 'En la cocina'),
      context.sample(en: 'since 5 h', es: 'desde hace 5 h'),
    ),
    MemberStatus.away => (
      sample.isYou
          ? context.sample(en: 'Ana, you, away', es: 'Ana, tú, fuera de casa')
          : context.sample(en: '$name, away', es: '$name, fuera de casa'),
      context.sample(
        en: 'Absence in the calendar',
        es: 'Ausencia en el calendario',
      ),
      context.sample(en: 'until Fri', es: 'hasta el vie'),
    ),
    MemberStatus.invited => (
      context.sample(en: '$name, invited', es: '$name, invitado'),
      context.sample(en: 'Invited by Ana', es: 'Invitado por Ana'),
      context.sample(en: 'pending', es: 'pendiente'),
    ),
  };
  return PresenceEntry(
    member: MemberView(
      id: sample.id,
      name: name,
      initials: sample.initials,
      joinOrder: sample.joinOrder,
      semanticLabel: spoken,
      status: sample.status,
      isYou: sample.isYou,
    ),
    subtitle: subtitle,
    trailing: trailing,
  );
}

String _title(BuildContext context, _Section section) => switch (section) {
  _Section.home => context.sample(en: 'At home', es: 'En casa'),
  _Section.away => context.sample(en: 'Away', es: 'Fuera de casa'),
  _Section.invited => context.sample(en: 'Invited', es: 'Invitados'),
};

String _emptyHome(BuildContext context) => context.sample(
  en: 'Nobody is home right now',
  es: 'Ahora mismo no hay nadie en casa',
);

PresenceGroup _group(
  BuildContext context,
  _Section section,
  List<_Sample> members, {
  String? title,
  String? emptyLabel,
}) => PresenceGroup(
  title: title ?? _title(context, section),
  entries: [for (final member in members) _entry(context, member)],
  emptyLabel: emptyLabel,
);

String _knockLabel(BuildContext context) =>
    context.sample(en: "Who's home?", es: '¿Quién está?');

String _hint(BuildContext context) => context.sample(
  en: 'Once every 15 minutes per home',
  es: 'Una vez cada 15 minutos por casa',
);

KnockCooldown _boardCooldown(BuildContext context) => KnockCooldown(
  remaining: _boardRemaining,
  label: context.sample(en: 'Asked', es: 'Preguntado'),
  remainingLabel: context.sample(en: '11 min', es: '11 min'),
  semanticLabel: context.sample(
    en: "Asked who's home. You can ask again in 11 minutes",
    es:
        'Preguntaste quién está en casa. '
        'Puedes volver a preguntar en 11 minutos',
  ),
);

PresenceBroadcast _broadcast(
  BuildContext context, {
  KnockCooldown? cooldown,
  String? message,
}) => PresenceBroadcast(
  knockLabel: _knockLabel(context),
  cooldown: cooldown,
  message: message,
  hint: _hint(context),
);

/// Every prop of [PresencePanel] as a knob: how many members of each group
/// (from the sample pools, none leaves invited out and shows the empty label
/// of the home), the headings and the empty label, the label of the button,
/// the message and the hint, and the wait, which is off while the home can be
/// asked. The callback is plumbing: the story owns it.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      int count(String label, int initial, String description) => context
          .knobs
          .int
          .slider(
            label: label,
            description: description,
            initialValue: initial,
            max: _poolSize,
            divisions: _poolSize,
          )
          .clamp(0, _poolSize);
      final home = count('homeMembers', 2, 'How many at home');
      final away = count('awayMembers', 1, 'How many away');
      final invited = count(
        'invitedMembers',
        0,
        'How many invited, none leaves the group out',
      );
      String text(String label, String initial) {
        final typed = context.textKnob(
          label,
          initial,
          description:
              'Must not be empty: an empty one falls back to the '
              'sample',
        );
        return typed.isEmpty ? initial : typed;
      }

      final homeTitle = text('homeTitle', _title(context, _Section.home));
      final awayTitle = text('awayTitle', _title(context, _Section.away));
      final invitedTitle = text(
        'invitedTitle',
        _title(context, _Section.invited),
      );
      final emptyHome = context.textKnobOrNull(
        'emptyHomeLabel',
        _emptyHome(context),
        description: 'Said in place of the rows when nobody is at home',
      );
      final emptyAway = context.textKnobOrNull(
        'awayEmptyLabel',
        null,
        description: 'Said in place of the rows when nobody is away',
      );
      final emptyInvited = context.textKnobOrNull(
        'invitedEmptyLabel',
        null,
        description:
            'Said in place of the rows when nobody is invited: it shows the '
            'group even with no members',
      );
      final knockLabel = text('knockLabel', _knockLabel(context));
      final message = context.textKnobOrNull(
        'message',
        null,
        description: 'Who asked and when, empty or null leaves it out',
      );
      final hint = context.textKnobOrNull('hint', _hint(context));
      final waiting = context.knobs.boolean(
        label: 'cooldown',
        description: 'The home was asked a short time ago: wait',
      );
      final rawRemaining = context.knobs.double.slider(
        label: 'remaining',
        description: 'The share of the wait that is left',
        initialValue: _boardRemaining,
        max: 1,
        divisions: _ringDivisions,
        precision: 2,
      );
      final board = _boardCooldown(context);
      final cooldownLabel = text('cooldownLabel', board.label);
      final remainingLabel = text('remainingLabel', board.remainingLabel);
      final cooldownSemanticLabel = text(
        'cooldownSemanticLabel',
        board.semanticLabel,
      );

      // A playground can grow taller than the preview, and the organism is not
      // a scrollable: it scrolls as it would inside a screen.
      return SingleChildScrollView(
        child: barFrame(
          child: PresencePanel(
            view: PresenceView(
              home: _group(
                context,
                _Section.home,
                const [
                  _Sample.ana,
                  _Sample.carlos,
                  _Sample.sara,
                ].take(home).toList(),
                title: homeTitle,
                emptyLabel: emptyHome,
              ),
              away: _group(
                context,
                _Section.away,
                const [
                  _Sample.luis,
                  _Sample.pablo,
                  _Sample.eva,
                ].take(away).toList(),
                title: awayTitle,
                emptyLabel: emptyAway,
              ),
              invited: invited == 0 && (emptyInvited ?? '').isEmpty
                  ? null
                  : _group(
                      context,
                      _Section.invited,
                      const [
                        _Sample.marta,
                        _Sample.jon,
                        _Sample.lia,
                      ].take(invited).toList(),
                      title: invitedTitle,
                      emptyLabel: emptyInvited,
                    ),
              broadcast: PresenceBroadcast(
                knockLabel: knockLabel,
                message: message,
                hint: hint,
                cooldown: waiting
                    ? KnockCooldown(
                        remaining: rawRemaining.isNaN ? 0 : rawRemaining,
                        label: cooldownLabel,
                        remainingLabel: remainingLabel,
                        semanticLabel: cooldownSemanticLabel,
                      )
                    : null,
              ),
            ),
            onKnock: _noop,
          ),
        ),
      );
    },
  );
}

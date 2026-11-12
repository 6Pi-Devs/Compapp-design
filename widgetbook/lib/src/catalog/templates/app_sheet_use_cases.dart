import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The most paragraphs and actions the playground offers.
const _maxParagraphs = 8;
const _maxActions = 3;

/// One use case per shape of the slots: a body alone, with one action and
/// with two. The sheet draws no motion, so none is frozen. The first holds a
/// real organism (the panel of who is home), the others the words of two
/// business rules.
WidgetbookComponent buildAppSheet() {
  return WidgetbookComponent(
    name: 'AppSheet',
    useCases: [
      _playground(),
      WidgetbookUseCase(
        name: 'sheet-plain',
        builder: (context) => barFrame(
          child: AppSheet(
            title: context.sample(
              en: 'Who is home?',
              es: '¿Quién está en casa?',
            ),
            closeLabel: _closeLabel(context),
            onClose: _noop,
            body: PresencePanel(view: _presence(context), onKnock: _noop),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'sheet-one-action',
        builder: (context) => barFrame(
          child: AppSheet(
            title: _archiveTitle(context),
            closeLabel: _closeLabel(context),
            onClose: _noop,
            body: _paragraph(context, _archiveBody(context)),
            actions: [_primary(_archiveLabel(context))],
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'sheet-two-actions',
        builder: (context) => barFrame(
          child: AppSheet(
            title: _leaveTitle(context),
            closeLabel: _closeLabel(context),
            onClose: _noop,
            body: _paragraph(context, _leaveBody(context)),
            actions: [
              _primary(_leaveLabel(context)),
              _secondary(_stayLabel(context)),
            ],
          ),
        ),
      ),
    ],
  );
}

void _noop() {}

String _closeLabel(BuildContext context) =>
    context.sample(en: 'Close', es: 'Cerrar');

String _archiveTitle(BuildContext context) =>
    context.sample(en: 'Archive the Study?', es: '¿Archivar el Estudio?');

String _archiveBody(BuildContext context) => context.sample(
  en:
      'Archived rooms can be restored by the admin. They still count toward '
      'the room limit.',
  es:
      'El administrador puede restaurar las habitaciones archivadas. '
      'Siguen contando para el límite de habitaciones.',
);

String _archiveLabel(BuildContext context) =>
    context.sample(en: 'Archive room', es: 'Archivar habitación');

String _leaveTitle(BuildContext context) =>
    context.sample(en: 'Leave the home?', es: '¿Salir de la casa?');

String _leaveBody(BuildContext context) => context.sample(
  en:
      'Anyone can leave. If you are the admin, the role passes to the '
      'oldest member.',
  es:
      'Cualquiera puede salir. Si eres el administrador, el rol pasa al '
      'miembro más antiguo.',
);

String _leaveLabel(BuildContext context) =>
    context.sample(en: 'Leave home', es: 'Salir de la casa');

String _stayLabel(BuildContext context) =>
    context.sample(en: 'Stay', es: 'Quedarme');

Widget _paragraph(BuildContext context, String text) => Text(
  text,
  style: AppTypography.body.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
);

AppButton _primary(String label) => AppButton(label: label, onPressed: _noop);

AppButton _secondary(String label) =>
    AppButton(label: label, variant: AppButtonVariant.ghost, onPressed: _noop);

MemberView _member(
  BuildContext context,
  String id,
  String name,
  int joinOrder, {
  required MemberStatus status,
  bool you = false,
}) {
  final shown = you
      ? context.sample(en: '$name (you)', es: '$name (tú)')
      : name;
  final where = switch (status) {
    MemberStatus.home => context.sample(en: 'at home', es: 'en casa'),
    MemberStatus.away => context.sample(en: 'away', es: 'fuera'),
    MemberStatus.invited => context.sample(en: 'invited', es: 'invitado'),
  };
  return MemberView(
    id: id,
    name: shown,
    initials: name.substring(0, 1),
    joinOrder: joinOrder,
    status: status,
    isYou: you,
    semanticLabel: you
        ? context.sample(en: '$name, you, $where', es: '$name, tú, $where')
        : '$name, $where',
  );
}

PresenceView _presence(BuildContext context) => PresenceView(
  home: PresenceGroup(
    title: context.sample(en: 'At home', es: 'En casa'),
    entries: [
      PresenceEntry(
        member: _member(
          context,
          'ana',
          'Ana',
          0,
          status: MemberStatus.home,
          you: true,
        ),
      ),
      PresenceEntry(
        member: _member(
          context,
          'carlos',
          'Carlos',
          1,
          status: MemberStatus.home,
        ),
        subtitle: context.sample(
          en: 'Home since 18:20',
          es: 'En casa desde las 18:20',
        ),
      ),
    ],
  ),
  away: PresenceGroup(
    title: context.sample(en: 'Away', es: 'Fuera'),
    entries: [
      PresenceEntry(
        member: _member(context, 'luis', 'Luis', 2, status: MemberStatus.away),
        subtitle: context.sample(
          en: 'Away since 9:05',
          es: 'Fuera desde las 9:05',
        ),
      ),
    ],
  ),
  broadcast: PresenceBroadcast(
    knockLabel: context.sample(
      en: 'Ask who is home',
      es: 'Preguntar quién está',
    ),
  ),
);

/// Every prop of [AppSheet] as a knob: the title and the close label, and for
/// the two slots, the sample they are filled with: the words and number of
/// paragraphs of the body, and how many actions (up to three) with the labels
/// of the first two. The callback is plumbing: the story owns it. A title or a
/// label must not be empty, so an empty one falls back to the sample.
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

      final title = text('title', _archiveTitle(context));
      final closeLabel = text('closeLabel', _closeLabel(context));
      final bodyText = context.textKnob(
        'bodyText',
        _archiveBody(context),
        description: 'The text of each paragraph of the body slot',
      );
      final paragraphs = context.knobs.int.slider(
        label: 'bodyParagraphs',
        description:
            'How many paragraphs the body slot holds: enough make the body '
            'scroll',
        initialValue: 1,
        min: 1,
        max: _maxParagraphs,
        divisions: _maxParagraphs - 1,
      );
      final actionCount = context.knobs.int.slider(
        label: 'actions',
        description: 'How many buttons the actions slot holds',
        initialValue: 1,
        max: _maxActions,
        divisions: _maxActions,
      );
      final primaryLabel = text('primaryLabel', _archiveLabel(context));
      final secondaryLabel = text(
        'secondaryLabel',
        context.sample(en: 'Keep room', es: 'Conservar habitación'),
      );

      return SingleChildScrollView(
        child: barFrame(
          child: AppSheet(
            title: title,
            closeLabel: closeLabel,
            onClose: _noop,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < paragraphs; i++)
                  _paragraph(context, bodyText),
              ],
            ),
            actions: [
              for (var i = 0; i < actionCount; i++)
                switch (i) {
                  0 => _primary(primaryLabel),
                  1 => _secondary(secondaryLabel),
                  _ => _secondary(
                    context.sample(en: 'Not now', es: 'Ahora no'),
                  ),
                },
            ],
          ),
        ),
      );
    },
  );
}

import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The longest join order the playground offers for the member.
const _maxJoinOrder = 11;

/// One use case per mode of the contract: the board's nudge, a start, a
/// finish, a reminder, and the same nudge while it waits. The sheet draws no
/// motion, so none is frozen.
WidgetbookComponent buildItemSheet() {
  return WidgetbookComponent(
    name: 'ItemSheet',
    useCases: [
      _playground(),
      for (final mode in ItemSheetMode.values)
        WidgetbookUseCase(
          name: 'sheet-${mode.name}',
          builder: (context) => barFrame(
            child: ItemSheet(
              view: _view(context, mode),
              onConfirm: _noop,
              onClose: _noop,
            ),
          ),
        ),
    ],
  );
}

void _noop() {}

ItemView _item() =>
    const ItemView(id: 'washer', name: 'Washer', icon: AppIcons.washer);

MemberView _member(
  BuildContext context, {
  required bool you,
  String? name,
  int joinOrder = 1,
  bool admin = false,
  MemberStatus status = MemberStatus.home,
  String? semanticLabel,
}) {
  final shown =
      name ??
      (you ? context.sample(en: 'Ana (you)', es: 'Ana (tú)') : 'Carlos');
  return MemberView(
    id: you ? 'ana' : 'carlos',
    name: shown,
    initials: shown.isEmpty ? '?' : shown.substring(0, 1),
    joinOrder: you ? 0 : joinOrder,
    status: status,
    isYou: you,
    isAdmin: admin,
    semanticLabel:
        semanticLabel ??
        (you
            ? context.sample(en: 'Ana, you, at home', es: 'Ana, tú, en casa')
            : context.sample(en: 'Carlos, at home', es: 'Carlos, en casa')),
  );
}

String _usageSubtitle(BuildContext context, {required bool you}) => you
    ? context.sample(
        en: 'You started it 34 min ago',
        es: 'Empezaste hace 34 min',
      )
    : context.sample(en: 'Started it 34 min ago', es: 'Empezó hace 34 min');

String _closeLabel(BuildContext context) =>
    context.sample(en: 'Close', es: 'Cerrar');

/// The words of each mode. The board's sheet is the nudge.
({String title, String? message, String confirm}) _words(
  BuildContext context,
  ItemSheetMode mode,
) => switch (mode) {
  ItemSheetMode.start => (
    title: context.sample(
      en: 'Start using the washer?',
      es: '¿Empezar a usar la lavadora?',
    ),
    message: context.sample(
      en: 'The others will see that it is in use.',
      es: 'Los demás verán que está en uso.',
    ),
    confirm: context.sample(en: 'Start using', es: 'Empezar a usar'),
  ),
  ItemSheetMode.finish => (
    title: context.sample(
      en: 'Done with the washer?',
      es: '¿Terminaste con la lavadora?',
    ),
    message: context.sample(
      en: 'The others will see that it is free.',
      es: 'Los demás verán que está libre.',
    ),
    confirm: context.sample(en: "I'm done", es: 'Ya terminé'),
  ),
  ItemSheetMode.nudge => (
    title: context.sample(
      en: 'Ask Carlos to free the washer?',
      es: '¿Pedirle a Carlos que libere la lavadora?',
    ),
    message: context.sample(
      en: 'You can ask the same person once every 15 minutes.',
      es: 'Puedes pedírselo a la misma persona una vez cada 15 minutos.',
    ),
    confirm: context.sample(en: 'Send request', es: 'Enviar petición'),
  ),
  ItemSheetMode.remind => (
    title: context.sample(
      en: 'Remind Carlos about the washer?',
      es: '¿Recordarle a Carlos la lavadora?',
    ),
    message: context.sample(
      en: 'Carlos gets a gentle reminder that it is still in use.',
      es: 'Carlos recibe un recordatorio amable de que sigue en uso.',
    ),
    confirm: context.sample(en: 'Send reminder', es: 'Enviar recordatorio'),
  ),
  ItemSheetMode.cooldown => (
    title: context.sample(
      en: 'Ask Carlos to free the washer?',
      es: '¿Pedirle a Carlos que libere la lavadora?',
    ),
    message: context.sample(
      en: 'You can ask Carlos again in 11 minutes.',
      es: 'Puedes volver a pedírselo a Carlos en 11 minutos.',
    ),
    confirm: context.sample(en: 'Send request', es: 'Enviar petición'),
  ),
};

ItemSheetView _view(BuildContext context, ItemSheetMode mode) {
  final words = _words(context, mode);
  final you = mode == ItemSheetMode.finish;
  return ItemSheetView(
    item: _item(),
    mode: mode,
    usage: mode == ItemSheetMode.start
        ? null
        : ItemUsage(
            member: _member(context, you: you),
            subtitle: _usageSubtitle(context, you: you),
          ),
    title: words.title,
    message: words.message,
    confirmLabel: words.confirm,
    closeLabel: _closeLabel(context),
  );
}

/// Every prop of [ItemSheet] as a knob: the mode, the person using it (their
/// name, join order, status, you and admin flags, spoken label and the
/// subtitle), the words and the message. The item is fixed: its id only keys
/// the sheet. A start has no usage, so the member knobs have
/// no effect then, and a wait always says something: an empty message falls
/// back to the sample. The two callbacks are plumbing: the story owns them.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final mode = context.enumKnob(
        'mode',
        ItemSheetMode.values,
        initial: ItemSheetMode.nudge,
        description: 'A start has no usage, the others have one',
      );
      final words = _words(context, mode);
      String text(String label, String initial, {String? description}) {
        final typed = context.textKnob(
          label,
          initial,
          description:
              description ??
              'Must not be empty: an empty one falls back to the sample',
        );
        return typed.isEmpty ? initial : typed;
      }

      final title = text('title', words.title);
      final message = mode == ItemSheetMode.cooldown
          ? text('message', words.message!)
          : context.textKnobOrNull(
              'message',
              words.message,
              description: 'Empty or null leaves the line out',
            );
      final confirmLabel = text('confirmLabel', words.confirm);
      final closeLabel = text('closeLabel', _closeLabel(context));

      // Nobody nudges or reminds themselves: only a finish can be your own
      // use, so the other modes ignore the knob instead of building a view
      // the sheet rejects.
      final you =
          context.knobs.boolean(
            label: 'memberIsYou',
            description:
                'The person using the item is you. Only a finish can be your '
                'own use: the other modes ignore it',
          ) &&
          mode == ItemSheetMode.finish;
      final memberName = text('memberName', _member(context, you: you).name);
      final joinOrder = context.knobs.int
          .slider(
            label: 'memberJoinOrder',
            description: 'Picks the pebble color',
            initialValue: 1,
            max: _maxJoinOrder,
            divisions: _maxJoinOrder,
          )
          .clamp(0, _maxJoinOrder);
      final status = context.enumKnob(
        'memberStatus',
        MemberStatus.values,
        initial: MemberStatus.home,
      );
      final admin = context.knobs.boolean(label: 'memberIsAdmin');
      final spoken = text(
        'memberSemanticLabel',
        _member(context, you: you).semanticLabel,
      );
      final subtitle = text('usageSubtitle', _usageSubtitle(context, you: you));

      return SingleChildScrollView(
        child: barFrame(
          child: ItemSheet(
            view: ItemSheetView(
              item: _item(),
              mode: mode,
              usage: mode == ItemSheetMode.start
                  ? null
                  : ItemUsage(
                      member: _member(
                        context,
                        you: you,
                        name: memberName,
                        joinOrder: joinOrder,
                        admin: admin,
                        status: status,
                        semanticLabel: spoken,
                      ),
                      subtitle: subtitle,
                    ),
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              closeLabel: closeLabel,
            ),
            onConfirm: _noop,
            onClose: _noop,
          ),
        ),
      );
    },
  );
}

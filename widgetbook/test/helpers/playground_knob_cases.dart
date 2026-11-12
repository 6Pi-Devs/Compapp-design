import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One row of the knob table: a knob of a playground, a value other than its
/// default, and a check of what the rendered component receives. [also] holds
/// the knobs that must be set too for the knob to show (the badge label only
/// shows in the label form).
class KnobCase {
  const new(this.knob, this.value, this.check, {this.also = const {}});

  final String knob;
  final String value;
  final void Function(WidgetTester tester) check;
  final Map<String, String> also;
}

T _widget<T extends Widget>(WidgetTester tester) =>
    tester.widget<T>(find.byType(T));

const _green = Color(0xFF00FF00);

/// Every knob of every playground, keyed by component class. The playground
/// test fails when a playground registers a knob that has no row here, when a
/// row has no knob, and when a knob is not connected to its component: each
/// check must pass with the knob set and fail with the default.
final playgroundKnobCases = <String, List<KnobCase>>{
  'AppButton': [
    KnobCase('label', 'Zed', (t) => expect(_widget<AppButton>(t).label, 'Zed')),
    KnobCase(
      'enabled',
      'false',
      (t) => expect(_widget<AppButton>(t).onPressed, isNull),
    ),
    KnobCase(
      'variant',
      'ghost',
      (t) => expect(_widget<AppButton>(t).variant, AppButtonVariant.ghost),
    ),
    KnobCase(
      'size',
      'md',
      (t) => expect(_widget<AppButton>(t).size, AppButtonSize.md),
    ),
    KnobCase(
      'icon',
      'oven',
      (t) => expect(_widget<AppButton>(t).icon, AppIcons.oven),
    ),
    KnobCase(
      'loading',
      'true',
      (t) => expect(_widget<AppButton>(t).loading, isTrue),
    ),
    KnobCase(
      'semanticLabel',
      'Spoken',
      (t) => expect(_widget<AppButton>(t).semanticLabel, 'Spoken'),
    ),
    KnobCase(
      'loadingSemanticLabel',
      'Busy',
      (t) => expect(_widget<AppButton>(t).loadingSemanticLabel, 'Busy'),
    ),
    KnobCase(
      'disclosure',
      'true',
      (t) => expect(_widget<AppButton>(t).expanded, isFalse),
    ),
    KnobCase(
      'expanded',
      'true',
      (t) => expect(_widget<AppButton>(t).expanded, isTrue),
      also: {'disclosure': 'true'},
    ),
    KnobCase(
      'forced state',
      'pressed',
      (t) => expect(
        _widget<AppButton>(t).statesController?.value,
        contains(WidgetState.pressed),
      ),
    ),
  ],
  'AppIcon': [
    KnobCase(
      'icon',
      'oven',
      (t) => expect(_widget<AppIcon>(t).icon, AppIcons.oven),
    ),
    KnobCase('size', '40.0', (t) => expect(_widget<AppIcon>(t).size, 40)),
    KnobCase(
      'color',
      'ff00ff00',
      (t) => expect(_widget<AppIcon>(t).color, _green),
    ),
    KnobCase(
      'semanticLabel',
      'Spoken',
      (t) => expect(_widget<AppIcon>(t).semanticLabel, 'Spoken'),
    ),
  ],
  'AppChip': [
    KnobCase('label', 'Zed', (t) => expect(_widget<AppChip>(t).label, 'Zed')),
    KnobCase(
      'kind',
      'item',
      (t) => expect(_widget<AppChip>(t).kind, AppChipKind.item),
    ),
    KnobCase(
      'selected',
      'true',
      (t) => expect(_widget<AppChip>(t).selected, isTrue),
    ),
    KnobCase(
      'enabled',
      'false',
      (t) => expect(_widget<AppChip>(t).onTap, isNull),
    ),
  ],
  'AppSwitch': [
    KnobCase('label', 'Zed', (t) => expect(_widget<AppSwitch>(t).label, 'Zed')),
    KnobCase(
      'value',
      'true',
      (t) => expect(_widget<AppSwitch>(t).value, isTrue),
    ),
    KnobCase(
      'enabled',
      'false',
      (t) => expect(_widget<AppSwitch>(t).onChanged, isNull),
    ),
  ],
  'AppTextField': [
    KnobCase(
      'text',
      'abc',
      (t) => expect(_widget<AppTextField>(t).controller.text, 'abc'),
    ),
    KnobCase(
      'label',
      'Zed',
      (t) => expect(_widget<AppTextField>(t).label, 'Zed'),
    ),
    KnobCase(
      'hint',
      'Zed',
      (t) => expect(_widget<AppTextField>(t).hint, 'Zed'),
    ),
    KnobCase(
      'helperText',
      'Zed',
      (t) => expect(_widget<AppTextField>(t).helperText, 'Zed'),
    ),
    KnobCase(
      'errorText',
      'Bad',
      (t) => expect(_widget<AppTextField>(t).errorText, 'Bad'),
    ),
    KnobCase(
      'obscure',
      'true',
      (t) => expect(_widget<AppTextField>(t).obscure, isTrue),
    ),
    KnobCase(
      'revealSemanticLabel',
      'Zed',
      (t) => expect(_widget<AppTextField>(t).revealSemanticLabel, 'Zed'),
    ),
    KnobCase(
      'concealSemanticLabel',
      'Zed',
      (t) => expect(_widget<AppTextField>(t).concealSemanticLabel, 'Zed'),
    ),
    KnobCase(
      'keyboardType',
      'number',
      (t) =>
          expect(_widget<AppTextField>(t).keyboardType, TextInputType.number),
    ),
    KnobCase(
      'autocorrect',
      'false',
      (t) => expect(_widget<AppTextField>(t).autocorrect, isFalse),
    ),
    KnobCase(
      'enableSuggestions',
      'false',
      (t) => expect(_widget<AppTextField>(t).enableSuggestions, isFalse),
    ),
    KnobCase(
      'textCapitalization',
      'words',
      (t) => expect(
        _widget<AppTextField>(t).textCapitalization,
        TextCapitalization.words,
      ),
    ),
    KnobCase(
      'readOnly',
      'true',
      (t) => expect(_widget<AppTextField>(t).readOnly, isTrue),
    ),
    KnobCase(
      'textInputAction',
      'done',
      (t) => expect(
        _widget<AppTextField>(t).textInputAction,
        TextInputAction.done,
      ),
    ),
    KnobCase(
      'autofillHints',
      'password',
      (t) => expect(_widget<AppTextField>(t).autofillHints, [
        AutofillHints.password,
      ]),
    ),
    KnobCase(
      'enabled',
      'false',
      (t) => expect(_widget<AppTextField>(t).enabled, isFalse),
    ),
    KnobCase(
      'autofocus',
      'true',
      (t) => expect(_widget<AppTextField>(t).autofocus, isTrue),
    ),
    KnobCase(
      'focused look',
      'true',
      (t) => expect(_widget<AppTextField>(t).focusNode, isNotNull),
    ),
  ],
  'AppCodeInput': [
    KnobCase(
      'code',
      '12',
      (t) => expect(_widget<AppCodeInput>(t).controller?.text, '12'),
    ),
    KnobCase(
      'label',
      'Zed',
      (t) => expect(_widget<AppCodeInput>(t).label, 'Zed'),
    ),
    KnobCase('length', '4', (t) => expect(_widget<AppCodeInput>(t).length, 4)),
    KnobCase(
      'numeric',
      'false',
      (t) => expect(_widget<AppCodeInput>(t).numeric, isFalse),
    ),
    KnobCase(
      'errorText',
      'Bad',
      (t) => expect(_widget<AppCodeInput>(t).errorText, 'Bad'),
    ),
    KnobCase(
      'autofocus',
      'true',
      (t) => expect(_widget<AppCodeInput>(t).autofocus, isTrue),
    ),
    KnobCase(
      'focused look',
      'true',
      (t) => expect(_widget<AppCodeInput>(t).focusNode, isNotNull),
    ),
  ],
  'AppPebble': [
    KnobCase(
      'size',
      's56',
      (t) => expect(_widget<AppPebble>(t).size, AppPebbleSize.s56),
    ),
    KnobCase(
      'status',
      'away',
      (t) => expect(_widget<AppPebble>(t).status, AppPebbleStatus.away),
    ),
    KnobCase(
      'isYou',
      'true',
      (t) => expect(_widget<AppPebble>(t).isYou, isTrue),
    ),
    KnobCase(
      'isAdmin',
      'true',
      (t) => expect(_widget<AppPebble>(t).isAdmin, isTrue),
    ),
    KnobCase(
      'initials',
      'Z',
      (t) => expect(_widget<AppPebble>(t).initials, 'Z'),
    ),
    KnobCase(
      'joinOrder',
      '3',
      (t) => expect(_widget<AppPebble>(t).joinOrder, 3),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<AppPebble>(t).semanticLabel, 'Zed'),
    ),
  ],
  'AppStatusDot': [
    KnobCase(
      'status',
      'busy',
      (t) => expect(_widget<AppStatusDot>(t).status, AppDotStatus.busy),
    ),
  ],
  'AppBadge': [
    KnobCase(
      'form',
      'label',
      (t) => expect(_widget<AppBadge>(t).label, isNotNull),
    ),
    KnobCase('count', '42', (t) => expect(_widget<AppBadge>(t).count, 42)),
    KnobCase(
      'label',
      'Zed',
      (t) => expect(_widget<AppBadge>(t).label, 'Zed'),
      also: {'form': 'label'},
    ),
    KnobCase(
      'tone',
      'busy',
      (t) => expect(_widget<AppBadge>(t).tone, AppBadgeTone.busy),
    ),
    KnobCase(
      'semanticLabel',
      'Spoken',
      (t) => expect(_widget<AppBadge>(t).semanticLabel, 'Spoken'),
    ),
  ],
  'AppProgressRing': [
    KnobCase(
      'in use',
      'true',
      (t) => expect(_widget<AppProgressRing>(t).value, isNull),
    ),
    KnobCase(
      'value',
      '0.5',
      (t) => expect(_widget<AppProgressRing>(t).value, 0.5),
    ),
    KnobCase(
      'tone',
      'busy',
      (t) => expect(_widget<AppProgressRing>(t).tone, AppRingTone.busy),
    ),
    KnobCase(
      'size',
      '80.0',
      (t) => expect(_widget<AppProgressRing>(t).size, 80),
    ),
    KnobCase(
      'label',
      'Zed',
      (t) => expect(_widget<AppProgressRing>(t).label, 'Zed'),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<AppProgressRing>(t).semanticLabel, 'Zed'),
    ),
    KnobCase(
      'semanticValue',
      'Zed',
      (t) => expect(_widget<AppProgressRing>(t).semanticValue, 'Zed'),
    ),
  ],
  'MemberRow': [
    KnobCase(
      'name',
      'Zed',
      (t) => expect(_widget<MemberRow>(t).member.name, 'Zed'),
    ),
    KnobCase(
      'initials',
      'Z',
      (t) => expect(_widget<MemberRow>(t).member.initials, 'Z'),
    ),
    KnobCase(
      'joinOrder',
      '3',
      (t) => expect(_widget<MemberRow>(t).member.joinOrder, 3),
    ),
    KnobCase(
      'status',
      'away',
      (t) => expect(_widget<MemberRow>(t).member.status, MemberStatus.away),
    ),
    KnobCase(
      'isYou',
      'true',
      (t) => expect(_widget<MemberRow>(t).member.isYou, isTrue),
    ),
    KnobCase(
      'isAdmin',
      'true',
      (t) => expect(_widget<MemberRow>(t).member.isAdmin, isTrue),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<MemberRow>(t).member.semanticLabel, 'Zed'),
    ),
    KnobCase(
      'subtitle',
      'Zed',
      (t) => expect(_widget<MemberRow>(t).subtitle, 'Zed'),
    ),
    KnobCase(
      'trailing',
      'Zed',
      (t) => expect(_widget<MemberRow>(t).trailing, 'Zed'),
    ),
  ],
  'ItemBeacon': [
    KnobCase(
      'name',
      'Zed',
      (t) => expect(_widget<ItemBeacon>(t).item.name, 'Zed'),
    ),
    KnobCase(
      'icon',
      'oven',
      (t) => expect(_widget<ItemBeacon>(t).item.icon, AppIcons.oven),
    ),
    KnobCase(
      'inUse',
      'true',
      (t) => expect(_widget<ItemBeacon>(t).inUse, isTrue),
    ),
    KnobCase(
      'statusLabel',
      'Zed',
      (t) => expect(_widget<ItemBeacon>(t).statusLabel, 'Zed'),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<ItemBeacon>(t).semanticLabel, 'Zed'),
    ),
  ],
  'RoomTile': [
    KnobCase(
      'name',
      'Zed',
      (t) => expect(_widget<RoomTile>(t).room.name, 'Zed'),
    ),
    KnobCase(
      'state',
      'occupied',
      (t) => expect(_widget<RoomTile>(t).state, RoomTileState.occupied),
    ),
    KnobCase(
      'caption',
      'Zed',
      (t) => expect(_widget<RoomTile>(t).caption, 'Zed'),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<RoomTile>(t).semanticLabel, 'Zed'),
    ),
    KnobCase(
      'occupants',
      '2',
      (t) => expect(_widget<RoomTile>(t).occupants, hasLength(2)),
    ),
    KnobCase(
      'beacons',
      '2',
      (t) => expect(_widget<RoomTile>(t).beacons, hasLength(2)),
    ),
    KnobCase(
      'tappable',
      'true',
      (t) => expect(_widget<RoomTile>(t).onTap, isNotNull),
    ),
    KnobCase('draw', 'true', (t) => expect(_widget<RoomTile>(t).draw, isTrue)),
  ],
  'TaskRow': [
    KnobCase(
      'title',
      'Zed',
      (t) => expect(_widget<TaskRow>(t).task.title, 'Zed'),
    ),
    KnobCase(
      'ageDays',
      '9',
      (t) => expect(_widget<TaskRow>(t).task.ageDays, 9),
    ),
    KnobCase(
      'subtitle',
      'Zed',
      (t) => expect(_widget<TaskRow>(t).subtitle, 'Zed'),
    ),
    KnobCase(
      'logAgainSemanticLabel',
      'Zed',
      (t) => expect(_widget<TaskRow>(t).logAgainSemanticLabel, 'Zed'),
    ),
  ],
  'EventRibbon': [
    KnobCase(
      'kind',
      'absence',
      (t) =>
          expect(_widget<EventRibbon>(t).event.kind, CalendarEventKind.absence),
    ),
    KnobCase(
      'title',
      'Zed',
      (t) => expect(_widget<EventRibbon>(t).event.title, 'Zed'),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<EventRibbon>(t).semanticLabel, 'Zed'),
    ),
    KnobCase(
      'continuesBefore',
      'true',
      (t) => expect(_widget<EventRibbon>(t).continuesBefore, isTrue),
    ),
    KnobCase(
      'continuesAfter',
      'true',
      (t) => expect(_widget<EventRibbon>(t).continuesAfter, isTrue),
    ),
    KnobCase(
      'compact',
      'true',
      (t) => expect(_widget<EventRibbon>(t).compact, isTrue),
    ),
  ],
  'ActivityRow': [
    KnobCase(
      'icon',
      'oven',
      (t) => expect(_widget<ActivityRow>(t).entry.icon, AppIcons.oven),
    ),
    KnobCase(
      'tone',
      'neutral',
      (t) => expect(_widget<ActivityRow>(t).entry.tone, ActivityTone.neutral),
    ),
    KnobCase(
      'before',
      'Zed',
      (t) => expect(_widget<ActivityRow>(t).entry.text.first.text, 'Zed'),
    ),
    KnobCase(
      'strong',
      'Zed',
      (t) => expect(
        _widget<ActivityRow>(t).entry.text
            .where((run) => run.strong)
            .map((run) => run.text),
        ['Zed'],
      ),
    ),
    KnobCase(
      'after',
      'Zed',
      (t) => expect(_widget<ActivityRow>(t).entry.text.last.text, 'Zed'),
    ),
    KnobCase(
      'meta',
      'Zed',
      (t) => expect(_widget<ActivityRow>(t).entry.meta, 'Zed'),
    ),
    KnobCase(
      'unread',
      'false',
      (t) => expect(_widget<ActivityRow>(t).unread, isFalse),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<ActivityRow>(t).semanticLabel, endsWith('Zed')),
    ),
  ],
  'PresenceSwitch': [
    KnobCase(
      'value',
      'away',
      (t) => expect(_widget<PresenceSwitch>(t).value, Presence.away),
    ),
    KnobCase(
      'homeLabel',
      'Zed',
      (t) => expect(_widget<PresenceSwitch>(t).homeLabel, 'Zed'),
    ),
    KnobCase(
      'awayLabel',
      'Zed',
      (t) => expect(_widget<PresenceSwitch>(t).awayLabel, 'Zed'),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<PresenceSwitch>(t).semanticLabel, 'Zed'),
    ),
  ],
  'KnockButton': [
    KnobCase(
      'label',
      'Zed',
      (t) => expect(_widget<KnockButton>(t).label, 'Zed'),
    ),
    KnobCase(
      'cooldown',
      'true',
      (t) => expect(_widget<KnockButton>(t).cooldown, isNotNull),
    ),
    KnobCase(
      'remaining',
      '0.4',
      (t) => expect(_widget<KnockButton>(t).cooldown?.remaining, 0.4),
      also: {'cooldown': 'true'},
    ),
    KnobCase(
      'cooldownLabel',
      'Zed',
      (t) => expect(_widget<KnockButton>(t).cooldown?.label, 'Zed'),
      also: {'cooldown': 'true'},
    ),
    KnobCase(
      'remainingLabel',
      'Zed',
      (t) => expect(_widget<KnockButton>(t).cooldown?.remainingLabel, 'Zed'),
      also: {'cooldown': 'true'},
    ),
    KnobCase(
      'cooldownSemanticLabel',
      'Zed',
      (t) => expect(_widget<KnockButton>(t).cooldown?.semanticLabel, 'Zed'),
      also: {'cooldown': 'true'},
    ),
  ],
  'CodeCard': [
    KnobCase(
      'code',
      '0000 1111',
      (t) => expect(_widget<CodeCard>(t).code, '0000 1111'),
    ),
    KnobCase('label', 'Zed', (t) => expect(_widget<CodeCard>(t).label, 'Zed')),
    KnobCase(
      'copyLabel',
      'Zed',
      (t) => expect(_widget<CodeCard>(t).copyLabel, 'Zed'),
    ),
    KnobCase(
      'copiedLabel',
      'Zed',
      (t) => expect(_widget<CodeCard>(t).copiedLabel, 'Zed'),
    ),
    KnobCase(
      'shareLabel',
      'Zed',
      (t) => expect(_widget<CodeCard>(t).shareLabel, 'Zed'),
    ),
    KnobCase(
      'copied',
      'true',
      (t) => expect(_widget<CodeCard>(t).copied, isTrue),
    ),
  ],
  'AppFreshnessBar': [
    KnobCase(
      'ageDays',
      '9',
      (t) => expect(_widget<AppFreshnessBar>(t).ageDays, 9),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<AppFreshnessBar>(t).semanticLabel, 'Zed'),
    ),
  ],
  'AppTopBar': [
    KnobCase(
      'form',
      'pushed',
      (t) => expect(_widget<AppTopBar>(t).variant, AppTopBarVariant.pushed),
    ),
    KnobCase('title', 'Zed', (t) => expect(_widget<AppTopBar>(t).title, 'Zed')),
    KnobCase(
      'subtitle',
      'Zed',
      (t) => expect(_widget<AppTopBar>(t).subtitle, 'Zed'),
    ),
    KnobCase(
      'activityLabel',
      'Zed',
      (t) => expect(_widget<AppTopBar>(t).activityLabel, 'Zed'),
    ),
    KnobCase(
      'unreadCount',
      '42',
      (t) => expect(_widget<AppTopBar>(t).unreadCount, 42),
    ),
    KnobCase(
      'meInitials',
      'Z',
      (t) => expect(_widget<AppTopBar>(t).me?.initials, 'Z'),
    ),
    KnobCase(
      'meJoinOrder',
      '3',
      (t) => expect(_widget<AppTopBar>(t).me?.joinOrder, 3),
    ),
    KnobCase(
      'accountLabel',
      'Zed',
      (t) => expect(_widget<AppTopBar>(t).accountLabel, 'Zed'),
    ),
    KnobCase(
      'backLabel',
      'Zed',
      (t) => expect(_widget<AppTopBar>(t).backLabel, 'Zed'),
      also: {'form': 'pushed'},
    ),
    KnobCase(
      'actionLabel',
      'Zed',
      (t) => expect(_widget<AppTopBar>(t).actionLabel, 'Zed'),
      also: {'form': 'pushed'},
    ),
    KnobCase('actionEnabled', 'false', (t) {
      final bar = _widget<AppTopBar>(t);
      expect(bar.variant, AppTopBarVariant.pushed);
      expect(bar.onAction, isNull);
    }, also: {'form': 'pushed'}),
    KnobCase(
      'namesRoute',
      'true',
      (t) => expect(_widget<AppTopBar>(t).namesRoute, isTrue),
    ),
  ],
  'AppNavBar': [
    KnobCase(
      'destinations',
      '3',
      (t) => expect(_widget<AppNavBar>(t).destinations, hasLength(3)),
    ),
    KnobCase(
      'selectedIndex',
      '2',
      (t) => expect(_widget<AppNavBar>(t).selectedIndex, 2),
    ),
    KnobCase(
      'semanticLabel',
      'Zed',
      (t) => expect(_widget<AppNavBar>(t).semanticLabel, 'Zed'),
    ),
    KnobCase(
      'icon',
      'oven',
      (t) => expect(_widget<AppNavBar>(t).destinations[0].icon, AppIcons.oven),
    ),
    KnobCase(
      'label',
      'Zed',
      (t) => expect(_widget<AppNavBar>(t).destinations[0].label, 'Zed'),
    ),
    KnobCase(
      'badgeCount',
      '42',
      (t) => expect(_widget<AppNavBar>(t).destinations[0].badgeCount, 42),
    ),
    KnobCase(
      'destinationSemanticLabel',
      'Zed',
      (t) => expect(_widget<AppNavBar>(t).destinations[0].semanticLabel, 'Zed'),
    ),
  ],
  'SheetHeader': [
    KnobCase(
      'title',
      'Zed',
      (t) => expect(_widget<SheetHeader>(t).title, 'Zed'),
    ),
    KnobCase(
      'closeLabel',
      'Zed',
      (t) => expect(_widget<SheetHeader>(t).closeLabel, 'Zed'),
    ),
    KnobCase(
      'focused look',
      'true',
      (t) => expect(_widget<SheetHeader>(t).titleFocusNode, isNotNull),
    ),
    KnobCase(
      'namesRoute',
      'true',
      (t) => expect(_widget<SheetHeader>(t).namesRoute, isTrue),
    ),
  ],
  'AppEmptyState': [
    KnobCase(
      'title',
      'Zed',
      (t) => expect(_widget<AppEmptyState>(t).title, 'Zed'),
    ),
    KnobCase(
      'body',
      'Zed',
      (t) => expect(_widget<AppEmptyState>(t).body, 'Zed'),
    ),
    KnobCase(
      'actionLabel',
      'Zed',
      (t) => expect(_widget<AppEmptyState>(t).actionLabel, 'Zed'),
    ),
    KnobCase(
      'actionEnabled',
      'false',
      (t) => expect(_widget<AppEmptyState>(t).onAction, isNull),
    ),
  ],
  'AppSnackbar': [
    KnobCase(
      'tone',
      'error',
      (t) => expect(_widget<AppSnackbar>(t).tone, SnackTone.error),
    ),
    KnobCase(
      'message',
      'Zed',
      (t) => expect(_widget<AppSnackbar>(t).message, 'Zed'),
    ),
    KnobCase(
      'actionLabel',
      'Zed',
      (t) => expect(_widget<AppSnackbar>(t).actionLabel, 'Zed'),
    ),
    KnobCase(
      'actionEnabled',
      'false',
      (t) => expect(_widget<AppSnackbar>(t).onAction, isNull),
    ),
    KnobCase(
      'visible',
      'false',
      (t) => expect(_widget<AppSnackbar>(t).visible, isFalse),
    ),
  ],
  'ActivityList': [
    KnobCase(
      'unreadEntries',
      '1',
      (t) => expect(_widget<ActivityList>(t).view.unread, hasLength(1)),
    ),
    KnobCase(
      'earlierEntries',
      '3',
      (t) => expect(_widget<ActivityList>(t).view.earlier, hasLength(3)),
    ),
    KnobCase(
      'moreUnread',
      '5',
      (t) => expect(
        _widget<ActivityList>(t).view.unreadCount,
        _widget<ActivityList>(t).view.unread.length + 5,
      ),
    ),
    KnobCase(
      'unreadPrefix',
      'Zed',
      (t) => expect(_widget<ActivityList>(t).view.unreadPrefix, 'Zed'),
    ),
    KnobCase(
      'unreadTitle',
      'Zed',
      (t) => expect(_widget<ActivityList>(t).view.unreadTitle, 'Zed'),
    ),
    KnobCase(
      'unreadSemanticLabel',
      'Zed',
      (t) => expect(_widget<ActivityList>(t).view.unreadSemanticLabel, 'Zed'),
    ),
    KnobCase(
      'earlierTitle',
      'Zed',
      (t) => expect(_widget<ActivityList>(t).view.earlierTitle, 'Zed'),
    ),
    KnobCase(
      'markAllReadLabel',
      'Zed',
      (t) => expect(_widget<ActivityList>(t).view.markAllReadLabel, 'Zed'),
    ),
    KnobCase(
      'emptyTitle',
      'Zed',
      (t) => expect(_widget<ActivityList>(t).view.emptyTitle, 'Zed'),
    ),
    KnobCase(
      'emptyBody',
      'Zed',
      (t) => expect(_widget<ActivityList>(t).view.emptyBody, 'Zed'),
    ),
  ],
  'PresencePanel': [
    KnobCase(
      'homeMembers',
      '3',
      (t) => expect(_widget<PresencePanel>(t).view.home.entries, hasLength(3)),
    ),
    KnobCase(
      'awayMembers',
      '3',
      (t) => expect(_widget<PresencePanel>(t).view.away.entries, hasLength(3)),
    ),
    KnobCase(
      'invitedMembers',
      '2',
      (t) =>
          expect(_widget<PresencePanel>(t).view.invited?.entries, hasLength(2)),
    ),
    KnobCase(
      'homeTitle',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.home.title, 'Zed'),
    ),
    KnobCase(
      'awayTitle',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.away.title, 'Zed'),
    ),
    KnobCase(
      'invitedTitle',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.invited?.title, 'Zed'),
      also: {'invitedMembers': '1'},
    ),
    KnobCase(
      'emptyHomeLabel',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.home.emptyLabel, 'Zed'),
      also: {'homeMembers': '0'},
    ),
    KnobCase(
      'awayEmptyLabel',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.away.emptyLabel, 'Zed'),
      also: {'awayMembers': '0'},
    ),
    KnobCase(
      'invitedEmptyLabel',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.invited?.emptyLabel, 'Zed'),
    ),
    KnobCase(
      'knockLabel',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.broadcast.knockLabel, 'Zed'),
    ),
    KnobCase(
      'message',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.broadcast.message, 'Zed'),
    ),
    KnobCase(
      'hint',
      'Zed',
      (t) => expect(_widget<PresencePanel>(t).view.broadcast.hint, 'Zed'),
    ),
    KnobCase(
      'cooldown',
      'true',
      (t) =>
          expect(_widget<PresencePanel>(t).view.broadcast.cooldown, isNotNull),
    ),
    KnobCase(
      'remaining',
      '0.4',
      (t) => expect(
        _widget<PresencePanel>(t).view.broadcast.cooldown?.remaining,
        0.4,
      ),
      also: {'cooldown': 'true'},
    ),
    KnobCase(
      'cooldownLabel',
      'Zed',
      (t) => expect(
        _widget<PresencePanel>(t).view.broadcast.cooldown?.label,
        'Zed',
      ),
      also: {'cooldown': 'true'},
    ),
    KnobCase(
      'remainingLabel',
      'Zed',
      (t) => expect(
        _widget<PresencePanel>(t).view.broadcast.cooldown?.remainingLabel,
        'Zed',
      ),
      also: {'cooldown': 'true'},
    ),
    KnobCase(
      'cooldownSemanticLabel',
      'Zed',
      (t) => expect(
        _widget<PresencePanel>(t).view.broadcast.cooldown?.semanticLabel,
        'Zed',
      ),
      also: {'cooldown': 'true'},
    ),
  ],
  'CalendarStrip': [
    KnobCase(
      'startOffset',
      '10',
      (t) =>
          expect(_widget<CalendarStrip>(t).view.days.first.date, '2026-11-11'),
    ),
    KnobCase(
      'todayIndex',
      '3',
      (t) => expect(
        _widget<CalendarStrip>(t).view.today,
        _widget<CalendarStrip>(t).view.days[3].date,
      ),
    ),
    KnobCase(
      'events',
      '1',
      (t) => expect(_widget<CalendarStrip>(t).view.events, hasLength(1)),
    ),
    KnobCase(
      'longWeekdays',
      'true',
      (t) => expect(
        _widget<CalendarStrip>(t).view.days.first.weekday.length,
        greaterThan(3),
      ),
    ),
    KnobCase(
      'todayLabel',
      'Zed',
      (t) => expect(
        _widget<CalendarStrip>(t).view.days.first.semanticLabel,
        endsWith('Zed'),
      ),
    ),
    KnobCase(
      'firstEventTitle',
      'Zed',
      (t) => expect(
        _widget<CalendarStrip>(t).view.events.first.event.title,
        'Zed',
      ),
    ),
    KnobCase(
      'firstEventLabel',
      'Zed',
      (t) => expect(
        _widget<CalendarStrip>(t).view.events.first.semanticLabel,
        contains('Zed'),
      ),
    ),
  ],
  'TaskComposer': [
    KnobCase(
      'query',
      'Zed',
      (t) => expect(_widget<TaskComposer>(t).view.query, 'Zed'),
    ),
    KnobCase(
      'suggestions',
      '3',
      (t) => expect(_widget<TaskComposer>(t).view.suggestions, hasLength(3)),
    ),
    KnobCase(
      'rooms',
      '1',
      (t) => expect(_widget<TaskComposer>(t).view.rooms, hasLength(1)),
    ),
    KnobCase(
      'items',
      '1',
      (t) => expect(_widget<TaskComposer>(t).view.items, hasLength(1)),
    ),
    KnobCase(
      'linkedKind',
      'item',
      (t) => expect(
        _widget<TaskComposer>(t).view.linked?.kind,
        TaskTargetKind.item,
      ),
    ),
    KnobCase(
      'linkedIndex',
      '1',
      (t) => expect(_widget<TaskComposer>(t).view.linked?.id, 'bathroom'),
      also: {'linkedKind': 'room'},
    ),
    KnobCase(
      'label',
      'Zed',
      (t) => expect(_widget<TaskComposer>(t).view.label, 'Zed'),
    ),
    KnobCase(
      'hint',
      'Zed',
      (t) => expect(_widget<TaskComposer>(t).view.hint, 'Zed'),
    ),
    KnobCase(
      'helperText',
      'Zed',
      (t) => expect(_widget<TaskComposer>(t).view.helperText, 'Zed'),
    ),
    KnobCase(
      'suggestionsLabel',
      'Zed',
      (t) => expect(_widget<TaskComposer>(t).view.suggestionsLabel, 'Zed'),
    ),
    KnobCase(
      'targetsLabel',
      'Zed',
      (t) => expect(_widget<TaskComposer>(t).view.targetsLabel, 'Zed'),
    ),
    KnobCase(
      'submitLabel',
      'Zed',
      (t) => expect(_widget<TaskComposer>(t).view.submitLabel, 'Zed'),
    ),
    KnobCase(
      'submitting',
      'true',
      (t) => expect(_widget<TaskComposer>(t).view.submitting, isTrue),
    ),
    KnobCase(
      'loadingLabel',
      'Zed',
      (t) => expect(_widget<TaskComposer>(t).view.loadingLabel, 'Zed'),
    ),
  ],
  'FloorplanMap': [
    KnobCase(
      'rooms',
      '3',
      (t) => expect(_widget<FloorplanMap>(t).view.rooms, hasLength(3)),
    ),
    KnobCase(
      'archivedRooms',
      '2',
      (t) => expect(
        _widget<FloorplanMap>(t).view.rooms.where((r) => r.archived),
        hasLength(2),
      ),
    ),
    KnobCase(
      'absences',
      '2',
      (t) => expect(_widget<FloorplanMap>(t).view.absences, hasLength(2)),
    ),
    KnobCase(
      'washerInUse',
      'false',
      (t) => expect(
        _widget<FloorplanMap>(t).view.rooms
            .firstWhere((r) => r.room.id == 'kitchen')
            .items
            .single
            .inUse,
        isFalse,
      ),
    ),
    KnobCase(
      'loading',
      'true',
      (t) => expect(_widget<FloorplanMap>(t).view.loading, isTrue),
    ),
    KnobCase(
      'firstRoomName',
      'Zed',
      (t) => expect(_widget<FloorplanMap>(t).view.rooms.first.room.name, 'Zed'),
    ),
    KnobCase(
      'firstRoomCaption',
      'Zed',
      (t) => expect(_widget<FloorplanMap>(t).view.rooms.first.caption, 'Zed'),
    ),
    KnobCase(
      'awayLabel',
      'Zed',
      (t) => expect(_widget<FloorplanMap>(t).view.awayLabel, 'Zed'),
    ),
    KnobCase(
      'emptyTitle',
      'Zed',
      (t) => expect(_widget<FloorplanMap>(t).view.emptyTitle, 'Zed'),
    ),
    KnobCase(
      'emptyBody',
      'Zed',
      (t) => expect(_widget<FloorplanMap>(t).view.emptyBody, 'Zed'),
    ),
    KnobCase(
      'loadingLabel',
      'Zed',
      (t) => expect(_widget<FloorplanMap>(t).view.loadingLabel, 'Zed'),
    ),
  ],
  'ItemSheet': [
    KnobCase(
      'mode',
      'start',
      (t) => expect(_widget<ItemSheet>(t).view.mode, ItemSheetMode.start),
    ),
    KnobCase(
      'title',
      'Zed',
      (t) => expect(_widget<ItemSheet>(t).view.title, 'Zed'),
    ),
    KnobCase(
      'message',
      'Zed',
      (t) => expect(_widget<ItemSheet>(t).view.message, 'Zed'),
    ),
    KnobCase(
      'confirmLabel',
      'Zed',
      (t) => expect(_widget<ItemSheet>(t).view.confirmLabel, 'Zed'),
    ),
    KnobCase(
      'closeLabel',
      'Zed',
      (t) => expect(_widget<ItemSheet>(t).view.closeLabel, 'Zed'),
    ),
    KnobCase(
      'memberIsYou',
      'true',
      (t) => expect(_widget<ItemSheet>(t).view.usage!.member.isYou, isTrue),
      also: {'mode': 'finish'},
    ),

    KnobCase(
      'memberName',
      'Zed',
      (t) => expect(_widget<ItemSheet>(t).view.usage!.member.name, 'Zed'),
    ),
    KnobCase(
      'memberJoinOrder',
      '5',
      (t) => expect(_widget<ItemSheet>(t).view.usage!.member.joinOrder, 5),
    ),
    KnobCase(
      'memberStatus',
      'away',
      (t) => expect(
        _widget<ItemSheet>(t).view.usage!.member.status,
        MemberStatus.away,
      ),
    ),
    KnobCase(
      'memberIsAdmin',
      'true',
      (t) => expect(_widget<ItemSheet>(t).view.usage!.member.isAdmin, isTrue),
    ),
    KnobCase(
      'memberSemanticLabel',
      'Zed',
      (t) =>
          expect(_widget<ItemSheet>(t).view.usage!.member.semanticLabel, 'Zed'),
    ),
    KnobCase(
      'usageSubtitle',
      'Zed',
      (t) => expect(_widget<ItemSheet>(t).view.usage!.subtitle, 'Zed'),
    ),
  ],
  'AppSheet': [
    KnobCase('title', 'Zed', (t) => expect(_widget<AppSheet>(t).title, 'Zed')),
    KnobCase(
      'closeLabel',
      'Zed',
      (t) => expect(_widget<AppSheet>(t).closeLabel, 'Zed'),
    ),
    KnobCase('bodyText', 'Zed', (t) {
      final body = _widget<AppSheet>(t).body as Column;
      expect((body.children.first as Text).data, 'Zed');
    }),
    KnobCase('bodyParagraphs', '3', (t) {
      expect((_widget<AppSheet>(t).body as Column).children, hasLength(3));
    }),
    KnobCase(
      'actions',
      '2',
      (t) => expect(_widget<AppSheet>(t).actions, hasLength(2)),
    ),
    KnobCase(
      'primaryLabel',
      'Zed',
      (t) => expect(_widget<AppSheet>(t).actions.first.label, 'Zed'),
    ),
    KnobCase('secondaryLabel', 'Zed', (t) {
      final actions = _widget<AppSheet>(t).actions;
      expect(actions, hasLength(2));
      expect(actions[1].label, 'Zed');
    }, also: {'actions': '2'}),
  ],
  'AppFormPage': [
    KnobCase(
      'title',
      'Zed',
      (t) => expect(_widget<AppFormPage>(t).title, 'Zed'),
    ),
    KnobCase(
      'backLabel',
      'Zed',
      (t) => expect(_widget<AppFormPage>(t).backLabel, 'Zed'),
    ),
    KnobCase(
      'fields',
      '5',
      (t) => expect(_widget<AppFormPage>(t).fields, hasLength(5)),
    ),
    KnobCase(
      'nameError',
      'Zed',
      (t) => expect(
        (_widget<AppFormPage>(t).fields.first as AppTextField).errorText,
        'Zed',
      ),
    ),
    KnobCase(
      'submitLabel',
      'Zed',
      (t) => expect(_widget<AppFormPage>(t).submitLabel, 'Zed'),
    ),
    KnobCase(
      'submitEnabled',
      'false',
      (t) => expect(_widget<AppFormPage>(t).onSubmit, isNull),
    ),
    KnobCase(
      'submitting',
      'true',
      (t) => expect(_widget<AppFormPage>(t).submitting, isTrue),
    ),
    KnobCase(
      'submittingLabel',
      'Zed',
      (t) => expect(_widget<AppFormPage>(t).submittingLabel, 'Zed'),
    ),
  ],
  'RoomDrawBoard': [
    KnobCase(
      'status',
      'applied',
      (t) =>
          expect(_widget<RoomDrawBoard>(t).view.status, RoomDrawStatus.applied),
    ),
    KnobCase(
      'statusLabel',
      'Zed',
      (t) => expect(_widget<RoomDrawBoard>(t).view.statusLabel, 'Zed'),
    ),
    KnobCase(
      'drawId',
      'Zed',
      (t) => expect(_widget<RoomDrawBoard>(t).view.drawId, 'Zed'),
    ),
    KnobCase(
      'bedrooms',
      '3',
      (t) => expect(_widget<RoomDrawBoard>(t).view.bedrooms.length, 3),
    ),
    KnobCase(
      'groupInFourth',
      '2',
      (t) => expect(
        _widget<RoomDrawBoard>(t).view.bedrooms.last.members.length,
        2,
      ),
    ),
    KnobCase(
      'firstCaption',
      'Zed',
      (t) =>
          expect(_widget<RoomDrawBoard>(t).view.bedrooms.first.caption, 'Zed'),
    ),
    KnobCase(
      'isAdmin',
      'false',
      (t) => expect(_widget<RoomDrawBoard>(t).view.isAdmin, isFalse),
    ),
    KnobCase(
      'drawAgainLabel',
      'Zed',
      (t) => expect(_widget<RoomDrawBoard>(t).view.drawAgainLabel, 'Zed'),
    ),
    KnobCase(
      'applyLabel',
      'Zed',
      (t) => expect(_widget<RoomDrawBoard>(t).view.applyLabel, 'Zed'),
    ),
    KnobCase(
      'readOnlyNote',
      'Zed',
      (t) => expect(_widget<RoomDrawBoard>(t).view.readOnlyNote, 'Zed'),
      also: {'isAdmin': 'false'},
    ),
    KnobCase(
      'canDrawAgain',
      'false',
      (t) => expect(_widget<RoomDrawBoard>(t).onDrawAgain, isNull),
    ),
    KnobCase(
      'canApply',
      'false',
      (t) => expect(_widget<RoomDrawBoard>(t).onApply, isNull),
    ),
  ],
  'RoomEditor': [
    KnobCase(
      'bedrooms',
      '1',
      (t) => expect(_widget<RoomEditor>(t).view.bedrooms.length, 1),
    ),
    KnobCase(
      'commonAreas',
      '1',
      (t) => expect(_widget<RoomEditor>(t).view.commonAreas.length, 1),
    ),
    KnobCase(
      'archived',
      '1',
      (t) => expect(_widget<RoomEditor>(t).view.archived.length, 1),
    ),
    KnobCase('occupants', '2', (t) {
      final first = _widget<RoomEditor>(t).view.bedrooms.first;
      expect(first.occupants.length, 2);
      expect(first.subtitle, 'Ana (you), Luis · 2 of 2 beds');
    }),
    KnobCase(
      'assignOptions',
      '1',
      (t) => expect(
        _widget<RoomEditor>(t).view.bedrooms.first.assignOptions.length,
        1,
      ),
    ),
    KnobCase(
      'bedroomsTitle',
      'Zed',
      (t) => expect(_widget<RoomEditor>(t).view.bedroomsTitle, 'Zed'),
    ),
    KnobCase(
      'commonAreasTitle',
      'Zed',
      (t) => expect(_widget<RoomEditor>(t).view.commonAreasTitle, 'Zed'),
    ),
    KnobCase(
      'addLabel',
      'Zed',
      (t) => expect(_widget<RoomEditor>(t).view.addLabel, 'Zed'),
    ),
    KnobCase(
      'assignLabel',
      'Zed',
      (t) => expect(_widget<RoomEditor>(t).view.assignLabel, 'Zed'),
    ),
    KnobCase(
      'limitMessage',
      'Zed',
      (t) => expect(_widget<RoomEditor>(t).view.limitMessage, 'Zed'),
    ),
    KnobCase(
      'archivedTitle',
      'Zed',
      (t) => expect(_widget<RoomEditor>(t).view.archivedTitle, 'Zed'),
      also: {'archived': '1'},
    ),
    KnobCase(
      'subtitle',
      'Zed',
      (t) => expect(_widget<RoomEditor>(t).view.bedrooms.first.subtitle, 'Zed'),
    ),
    KnobCase(
      'assignOpen',
      'true',
      (t) => expect(
        _widget<RoomEditor>(t).initialAssignOpen,
        contains('bedroom-1'),
      ),
    ),
    KnobCase(
      'editLabel',
      'Zed',
      (t) =>
          expect(_widget<RoomEditor>(t).view.bedrooms.first.editLabel, 'Zed'),
    ),
    KnobCase(
      'archiveLabel',
      'Zed',
      (t) => expect(
        _widget<RoomEditor>(t).view.bedrooms.first.archiveLabel,
        'Zed',
      ),
    ),
    KnobCase(
      'roomAssignLabel',
      'Zed',
      (t) => expect(
        _widget<RoomEditor>(t).view.bedrooms.first.assignLabel,
        'Assign Zed',
      ),
    ),
    KnobCase(
      'restoreLabel',
      'Zed',
      (t) => expect(
        _widget<RoomEditor>(t).view.archived.firstOrNull?.restoreLabel,
        'Zed',
      ),
      also: {'archived': '1'},
    ),
    KnobCase(
      'archivedSubtitle',
      'Zed',
      (t) => expect(
        _widget<RoomEditor>(t).view.archived.firstOrNull?.subtitle,
        'Zed',
      ),
      also: {'archived': '1'},
    ),
  ],
};

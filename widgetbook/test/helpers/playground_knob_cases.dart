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
};

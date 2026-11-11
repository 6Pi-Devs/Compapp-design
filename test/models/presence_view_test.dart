import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

PresenceEntry _entry(String id, {String? trailing = 'since 5 h'}) =>
    PresenceEntry(
      member: MemberView(
        id: id,
        name: id,
        initials: id.substring(0, 1),
        joinOrder: 1,
        semanticLabel: '$id, at home',
      ),
      subtitle: 'In the kitchen',
      trailing: trailing,
    );

const _broadcast = PresenceBroadcast(
  knockLabel: "Who's home?",
  hint: 'Once every 15 minutes per home',
);

PresenceView _view({
  List<PresenceEntry> home = const [],
  PresenceGroup? invited,
  PresenceBroadcast broadcast = _broadcast,
}) => PresenceView(
  home: PresenceGroup(title: 'At home', entries: home),
  away: const PresenceGroup(title: 'Away', entries: []),
  invited: invited,
  broadcast: broadcast,
);

void main() {
  group('PresenceEntry', () {
    test('equals an entry with the same member and texts', () {
      expect(_entry('ana'), _entry('ana'));
      expect(_entry('ana').hashCode, _entry('ana').hashCode);
      expect(_entry('ana'), isNot(_entry('bea')));
      expect(_entry('ana'), isNot(_entry('ana', trailing: 'since 6 h')));
    });
  });

  group('PresenceGroup', () {
    test('is shown with members, or with something to say in their place', () {
      expect(
        PresenceGroup(title: 'At home', entries: [_entry('ana')]).isShown,
        isTrue,
      );
      expect(
        const PresenceGroup(
          title: 'At home',
          entries: [],
          emptyLabel: 'Nobody is home',
        ).isShown,
        isTrue,
      );
      expect(
        const PresenceGroup(title: 'At home', entries: []).isShown,
        isFalse,
      );
      expect(
        const PresenceGroup(
          title: 'At home',
          entries: [],
          emptyLabel: '',
        ).isShown,
        isFalse,
      );
    });

    test('needs a title', () {
      expect(
        () => PresenceGroup(title: '', entries: const []),
        throwsAssertionError,
      );
    });

    test('equals a group with the same title, members and label', () {
      PresenceGroup group({String title = 'At home', String? label}) =>
          PresenceGroup(
            title: title,
            entries: [_entry('ana')],
            emptyLabel: label,
          );

      expect(group(), group());
      expect(group().hashCode, group().hashCode);
      expect(group(), isNot(group(title: 'Away')));
      expect(group(), isNot(group(label: 'Nobody')));
    });
  });

  group('PresenceBroadcast', () {
    test('needs a label for the button', () {
      expect(() => PresenceBroadcast(knockLabel: ''), throwsAssertionError);
    });

    test('equals a broadcast with the same words and wait', () {
      const cooldown = KnockCooldown(
        remaining: 0.5,
        label: 'Asked',
        remainingLabel: '7 min',
        semanticLabel: 'Asked. Ask again in 7 minutes',
      );
      const a = PresenceBroadcast(knockLabel: 'Ask', cooldown: cooldown);

      expect(a, const PresenceBroadcast(knockLabel: 'Ask', cooldown: cooldown));
      expect(
        a.hashCode,
        const PresenceBroadcast(knockLabel: 'Ask', cooldown: cooldown).hashCode,
      );
      expect(a, isNot(const PresenceBroadcast(knockLabel: 'Ask')));
      expect(
        a,
        isNot(
          const PresenceBroadcast(
            knockLabel: 'Ask',
            cooldown: cooldown,
            message: 'Carlos asked',
          ),
        ),
      );
    });
  });

  group('PresenceView', () {
    test('equals a view with the same groups and broadcast', () {
      expect(_view(home: [_entry('ana')]), _view(home: [_entry('ana')]));
      expect(
        _view(home: [_entry('ana')]).hashCode,
        _view(home: [_entry('ana')]).hashCode,
      );
      expect(_view(home: [_entry('ana')]), isNot(_view()));
      expect(
        _view(),
        isNot(
          _view(
            invited: const PresenceGroup(title: 'Invited', entries: []),
          ),
        ),
        reason: 'an invited group is part of the view',
      );
      expect(
        _view(),
        isNot(_view(broadcast: const PresenceBroadcast(knockLabel: 'Ask'))),
      );
    });
  });
}

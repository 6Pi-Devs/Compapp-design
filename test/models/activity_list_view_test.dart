import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityEntry _entry(String id, {String label = 'Carlos did it'}) =>
    ActivityEntry(
      view: ActivityView(
        id: id,
        icon: AppIcons.oven,
        text: const [ActivityText('Carlos did it')],
      ),
      semanticLabel: label,
    );

ActivityListView _view({
  List<ActivityEntry> unread = const [],
  List<ActivityEntry> earlier = const [],
  String emptyTitle = 'Nothing yet',
}) => ActivityListView(
  unread: unread,
  earlier: earlier,
  unreadTitle: 'New',
  unreadSemanticLabel: 'New, 1 unread',
  unreadPrefix: 'Unread',
  earlierTitle: 'Earlier',
  markAllReadLabel: 'Mark all as read',
  emptyTitle: emptyTitle,
  emptyBody: 'Come back later',
);

void main() {
  group('ActivityEntry', () {
    test('equals an entry with the same view and label', () {
      expect(_entry('a'), _entry('a'));
      expect(_entry('a').hashCode, _entry('a').hashCode);
      expect(_entry('a'), isNot(_entry('b')));
      expect(_entry('a'), isNot(_entry('a', label: 'Other')));
    });

    test('needs a spoken label', () {
      expect(() => _entry('a', label: ''), throwsAssertionError);
    });
  });

  group('ActivityListView', () {
    test('is empty only when both lists are', () {
      expect(_view().isEmpty, isTrue);
      expect(_view(unread: [_entry('a')]).isEmpty, isFalse);
      expect(_view(earlier: [_entry('a')]).isEmpty, isFalse);
    });

    test('equals a view with the same entries and words', () {
      expect(_view(unread: [_entry('a')]), _view(unread: [_entry('a')]));
      expect(
        _view(unread: [_entry('a')]).hashCode,
        _view(unread: [_entry('a')]).hashCode,
      );
      expect(_view(unread: [_entry('a')]), isNot(_view(unread: [_entry('b')])));
      expect(
        _view(earlier: [_entry('a')]),
        isNot(_view(unread: [_entry('a')])),
        reason: 'the list an entry is in matters',
      );
      expect(_view(), isNot(_view(emptyTitle: 'Other')));
    });

    test('can be built const', () {
      const view = ActivityListView(
        unread: [],
        earlier: [],
        unreadTitle: 'New',
        unreadSemanticLabel: 'New, 0 unread',
        unreadPrefix: 'Unread',
        earlierTitle: 'Earlier',
        markAllReadLabel: 'Mark all as read',
        emptyTitle: 'Nothing yet',
        emptyBody: 'Come back later',
      );

      expect(view.unreadCount, 0);
      expect(view.isEmpty, isTrue);
    });

    test('counts the entries listed unless the app says there are more', () {
      expect(_view(unread: [_entry('a'), _entry('b')]).unreadCount, 2);
      expect(
        ActivityListView(
          unread: [_entry('a')],
          earlier: const [],
          unreadCount: 7,
          unreadTitle: 'New',
          unreadSemanticLabel: 'New, 7 unread',
          unreadPrefix: 'Unread',
          earlierTitle: 'Earlier',
          markAllReadLabel: 'Mark all as read',
          emptyTitle: 'Nothing yet',
          emptyBody: 'Come back later',
        ).unreadCount,
        7,
      );
    });
  });
}

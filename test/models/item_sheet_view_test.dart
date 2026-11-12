import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

const _carlos = MemberView(
  id: 'carlos',
  name: 'Carlos',
  initials: 'C',
  joinOrder: 1,
  semanticLabel: 'Carlos, at home',
);

const _usage = ItemUsage(member: _carlos, subtitle: 'Started it 34 min ago');

ItemSheetView _view({
  ItemView item = const ItemView(
    id: 'washer',
    name: 'Washer',
    icon: AppIcons.washer,
  ),
  ItemSheetMode mode = ItemSheetMode.nudge,
  ItemUsage? usage = _usage,
  String title = 'Ask Carlos to free the washer?',
  String? message = 'Once every 15 minutes.',
  String confirmLabel = 'Send request',
  String closeLabel = 'Close',
}) => ItemSheetView(
  item: item,
  mode: mode,
  usage: usage,
  title: title,
  message: message,
  confirmLabel: confirmLabel,
  closeLabel: closeLabel,
);

void main() {
  test('two views with the same data are equal and hash alike', () {
    expect(_view(), _view());
    expect(_view().hashCode, _view().hashCode);
  });

  test('every field takes part in equality', () {
    for (final other in [
      _view(
        item: const ItemView(id: 'oven', name: 'Washer', icon: AppIcons.washer),
      ),
      _view(mode: ItemSheetMode.remind),
      _view(
        usage: const ItemUsage(member: _carlos, subtitle: 'Started it now'),
      ),
      _view(title: 'Other'),
      _view(message: 'Other'),
      _view(message: null),
      _view(confirmLabel: 'Other'),
      _view(closeLabel: 'Other'),
    ]) {
      expect(other, isNot(_view()));
      expect(other.hashCode, isNot(_view().hashCode));
    }
  });

  test('a usage is equal by its member and its subtitle', () {
    expect(
      _usage,
      const ItemUsage(member: _carlos, subtitle: 'Started it 34 min ago'),
    );
    expect(_usage.hashCode, _usage.hashCode);
    expect(_usage, isNot(const ItemUsage(member: _carlos, subtitle: 'Other')));
    expect(
      _usage,
      isNot(
        const ItemUsage(
          member: MemberView(
            id: 'ana',
            name: 'Ana',
            initials: 'A',
            joinOrder: 0,
            semanticLabel: 'Ana',
          ),
          subtitle: 'Started it 34 min ago',
        ),
      ),
    );
  });

  test('the five modes are the contract', () {
    expect(ItemSheetMode.values.map((mode) => mode.name), [
      'start',
      'finish',
      'nudge',
      'remind',
      'cooldown',
    ]);
  });
}

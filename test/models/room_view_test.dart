import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two views with the same data are equal and hash alike', () {
    const a = RoomView(id: 'a', name: 'A');
    const same = RoomView(id: 'a', name: 'A');

    expect(a, same);
    expect(a.hashCode, same.hashCode);
  });

  test('the id and the name take part in equality', () {
    const view = RoomView(id: 'a', name: 'A');

    expect(view, isNot(const RoomView(id: 'b', name: 'A')));
    expect(view, isNot(const RoomView(id: 'a', name: 'B')));
  });

  test('a tile state is one of home, away, occupied and free', () {
    expect(RoomTileState.values.map((state) => state.name), [
      'home',
      'away',
      'occupied',
      'free',
    ]);
  });
}

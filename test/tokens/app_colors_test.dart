import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors', () {
    test('copyWith replaces only the given fields', () {
      final copy = AppColors.light.copyWith(busy: Colors.red);

      expect(copy.busy, Colors.red);
      expect(copy.busySoft, AppColors.light.busySoft);
      expect(copy.presenceHome, AppColors.light.presenceHome);
      expect(copy.pebbles, AppColors.light.pebbles);
    });

    test('lerp hits both ends and blends in between', () {
      expect(
        AppColors.light.lerp(AppColors.dark, 0).busy,
        AppColors.light.busy,
      );
      expect(AppColors.light.lerp(AppColors.dark, 1).busy, AppColors.dark.busy);
      expect(
        AppColors.light.lerp(AppColors.dark, 0.5).busy,
        Color.lerp(AppColors.light.busy, AppColors.dark.busy, 0.5),
      );
      expect(AppColors.light.lerp(AppColors.dark, 0.5).pebbles, hasLength(6));
    });

    test('copyWith replaces onPebble and onPresenceAway', () {
      final copy = AppColors.light.copyWith(
        onPebble: Colors.red,
        onPresenceAway: Colors.blue,
      );

      expect(copy.onPebble, Colors.red);
      expect(copy.onPresenceAway, Colors.blue);
      expect(copy.busy, AppColors.light.busy);
      expect(
        AppColors.light.copyWith().onPresenceAway,
        AppColors.light.onPresenceAway,
      );
    });

    test('lerp blends onPebble and onPresenceAway', () {
      const light = AppColors.light;
      final other = light.copyWith(
        onPebble: const Color(0xFF000000),
        onPresenceAway: const Color(0xFF000000),
      );

      expect(light.lerp(other, 0).onPebble, light.onPebble);
      expect(light.lerp(other, 1).onPebble, other.onPebble);
      expect(
        light.lerp(other, 0.5).onPebble,
        Color.lerp(light.onPebble, other.onPebble, 0.5),
      );
      expect(
        light.lerp(other, 0.5).onPresenceAway,
        Color.lerp(light.onPresenceAway, other.onPresenceAway, 0.5),
      );
    });

    test('lerp ignores other theme extensions', () {
      expect(AppColors.light.lerp(null, 0.5), AppColors.light);
    });

    test('pebbleAt wraps around the palette', () {
      const colors = AppColors.light;

      expect(colors.pebbleAt(0), colors.pebbles.first);
      expect(colors.pebbleAt(5), colors.pebbles.last);
      expect(colors.pebbleAt(6), colors.pebbles.first);
      expect(colors.pebbleAt(13), colors.pebbles[1]);
    });
  });
}

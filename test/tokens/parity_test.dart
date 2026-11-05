import 'dart:convert';
import 'dart:io';

import 'package:compapp_design/src/tokens/app_colors.dart';
import 'package:compapp_design/src/tokens/app_motion.dart';
import 'package:compapp_design/src/tokens/app_palette.dart';
import 'package:compapp_design/src/tokens/app_progress.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_shadows.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_state_layers.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Json = Map<String, dynamic>;

/// Compares every JSON token with the `values` map of its Dart class, in both
/// directions: a token on one side only fails the test.
void main() {
  final tokens =
      jsonDecode(File('tokens/compapp.tokens.json').readAsStringSync()) as Json;

  Json section(String name) => tokens[name] as Json;
  Json child(Json node, String name) => node[name] as Json;
  Object? valueOf(Json node, String name) => child(node, name)[r'$value'];
  Json extensionsOf(Json node, String name) =>
      child(node, name)[r'$extensions'] as Json;
  Set<String> names(Json node) =>
      node.keys.where((key) => !key.startsWith(r'$')).toSet();

  test('the file only holds the groups the Dart tokens know', () {
    expect(tokens.keys, [
      'color',
      'pebble',
      'font',
      'space',
      'radius',
      'elevation',
      'motion',
      'target',
      'size',
      'state-layer',
      'progress',
    ]);
  });

  group('color', () {
    final colors = section('color');

    for (final (mode, palette, extras) in [
      ('light', AppPalette.light, AppColors.light),
      ('dark', AppPalette.dark, AppColors.dark),
    ]) {
      test('$mode values match AppPalette and AppColors', () {
        final dart = {...palette.values, ...extras.values};

        expect(dart.keys.toSet(), names(colors));
        for (final name in names(colors)) {
          final hex = mode == 'light'
              ? valueOf(colors, name)
              : (extensionsOf(colors, name)['mode'] as Json)['dark'];
          expect(dart[name], _hex(hex! as String), reason: 'color.$name');
        }
      });
    }

    test('pebbles match in name, order and value, in both themes', () {
      final pebbles = section('pebble');

      expect(AppColors.pebbleNames, names(pebbles).toList());
      for (final colors in [AppColors.light, AppColors.dark]) {
        expect(colors.pebbles, hasLength(AppColors.pebbleNames.length));
        for (final (i, name) in AppColors.pebbleNames.indexed) {
          expect(
            colors.pebbles[i],
            _hex(valueOf(pebbles, name)! as String),
            reason: 'pebble.$name',
          );
        }
      }
    });
  });

  test('typography matches AppTypography', () {
    final font = section('font');
    final optical = (font[r'$extensions'] as Json)['opticalSizing'] as Json;
    final opticalMin = (optical['min']! as num).toDouble();
    final opticalMax = (optical['max']! as num).toDouble();
    expect(AppTypography.opticalSizeMin, opticalMin);
    expect(AppTypography.opticalSizeMax, opticalMax);
    expect(optical['axis'], 'opsz');
    expect(optical['value'], 'fontSize');
    final tabular = (font[r'$extensions'] as Json)['tabularFigures'] as bool;

    expect(AppTypography.values.keys.toSet(), names(font));
    for (final name in names(font)) {
      final value = valueOf(font, name)! as Json;
      final style = AppTypography.values[name]!;
      final size = _px(value['fontSize']);
      final reason = 'font.$name';

      expect(
        style.fontFamily,
        'packages/compapp_design/${value['fontFamily']}',
        reason: reason,
      );
      expect(style.fontWeight?.value, value['fontWeight'], reason: reason);
      expect(style.fontSize, size, reason: reason);
      expect(
        style.height! * size,
        closeTo(_px(value['lineHeight']), 1e-9),
        reason: reason,
      );
      expect(
        style.letterSpacing,
        value.containsKey('letterSpacing') ? _px(value['letterSpacing']) : 0,
        reason: reason,
      );
      final variations = {
        for (final v in style.fontVariations ?? const <FontVariation>[])
          v.axis: v.value,
      };
      if (value['fontFamily'] == optical['family']) {
        expect(variations, {
          'opsz': size.clamp(opticalMin, opticalMax),
        }, reason: '$reason must carry only opsz, equal to its size');
      } else {
        expect(variations, isEmpty, reason: reason);
      }
      expect(
        style.fontFeatures?.contains(const FontFeature.tabularFigures()) ??
            false,
        tabular,
        reason: reason,
      );
    }
  });

  test('spacing matches AppSpacing', () {
    final space = section('space');

    expect(AppSpacing.values.keys.toSet(), names(space));
    for (final name in names(space)) {
      expect(
        AppSpacing.values[name],
        _px(valueOf(space, name)),
        reason: 'space.$name',
      );
    }
  });

  test('radius matches AppRadius', () {
    final radius = section('radius');

    expect(AppRadius.values.keys.toSet(), names(radius));
    for (final name in names(radius).difference({'pebble'})) {
      expect(
        AppRadius.values[name],
        _px(valueOf(radius, name)),
        reason: 'radius.$name',
      );
    }
    expect(AppRadius.values['pebble'], valueOf(radius, 'pebble'));
    expect(AppRadius.pebble(40), BorderRadius.circular(12));
  });

  test('elevation matches AppShadows and AppSizes.hairline', () {
    final elevation = section('elevation');
    final flat = valueOf(elevation, 'flat')! as Json;
    final value = valueOf(elevation, 'sheet')! as Json;
    final opacity = extensionsOf(elevation, 'sheet')['opacity']! as num;

    expect(names(elevation), {'flat', 'sheet'});
    expect(AppShadows.values.keys.toSet(), {'sheet'});
    expect(AppSizes.values['elevation.flat.width'], _px(flat['width']));
    expect(flat['color'], '{color.line}');

    final shadow = AppShadows.sheet.single;
    expect(AppShadows.sheet, hasLength(1));
    expect(shadow.offset, Offset(_px(value['offsetX']), _px(value['offsetY'])));
    expect(shadow.blurRadius, _px(value['blur']));
    expect(shadow.spreadRadius, _px(value['spread']));
    expect(shadow.color.withValues(alpha: 1), _hex(value['color']! as String));
    expect(shadow.color.a, closeTo(opacity, 1 / 255));
    expect(value['color'], valueOf(section('color'), 'ink'));
  });

  test('motion matches AppMotion', () {
    final motion = section('motion');

    expect(AppMotion.values.keys.toSet(), names(motion));
    expect(AppMotion.curves.keys.toSet(), names(motion));
    const curves = {
      'easeOut': Curves.easeOut,
      'easeInOut': Curves.easeInOut,
      'linear': Curves.linear,
    };
    for (final name in names(motion)) {
      expect(
        AppMotion.values[name],
        _ms(valueOf(motion, name)),
        reason: 'motion.$name',
      );
      expect(
        AppMotion.curves[name],
        curves[extensionsOf(motion, name)['curve']],
        reason: 'motion.$name curve',
      );
    }
    expect(extensionsOf(motion, 'in-use')['repeat'], isTrue);
    expect(extensionsOf(motion, 'spin')['repeat'], isTrue);
  });

  test('target and sizes match AppSizes', () {
    final target = section('target');
    final sizes = Map.of(AppSizes.values);

    expect(names(target), {'min'});
    expect(sizes.remove('target.min'), _px(valueOf(target, 'min')));
    expect(
      sizes.remove('target.min.drawn'),
      _px(extensionsOf(target, 'min')['drawn']),
    );
    expect(sizes.remove('elevation.flat.width'), isNotNull);

    final size = section('size');
    final sized = {
      for (final key in sizes.keys.toList())
        if (key.startsWith('size.')) key.substring(5): sizes.remove(key),
    };
    expect(sized.keys.toSet(), names(size));
    for (final name in names(size)) {
      expect(sized[name], _px(valueOf(size, name)), reason: 'size.$name');
    }
    expect(sizes, isEmpty, reason: 'AppSizes values without a JSON token');
  });

  test('state layers match AppStateLayers', () {
    final layers = section('state-layer');

    expect(AppStateLayers.values.keys.toSet(), names(layers));
    for (final name in names(layers)) {
      expect(
        AppStateLayers.values[name],
        valueOf(layers, name),
        reason: 'state-layer.$name',
      );
    }
  });

  test('progress matches AppProgress', () {
    final progress = section('progress');

    expect(AppProgress.values.keys.toSet(), names(progress));
    for (final name in names(progress)) {
      expect(
        AppProgress.values[name],
        valueOf(progress, name),
        reason: 'progress.$name',
      );
    }
  });
}

Color _hex(String hex) =>
    Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

double _px(Object? value) =>
    double.parse((value! as String).replaceAll('px', ''));

Duration _ms(Object? value) =>
    Duration(milliseconds: int.parse((value! as String).replaceAll('ms', '')));

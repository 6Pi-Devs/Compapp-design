import 'dart:convert';
import 'dart:io';

import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pubspec declares every family and weight AppTypography uses', () async {
    final manifest = jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    final declared = <String, Set<int>>{
      for (final family in manifest.cast<Map<String, dynamic>>())
        family['family'] as String: {
          for (final font
              in (family['fonts'] as List<dynamic>)
                  .cast<Map<String, dynamic>>())
            (font['weight'] as int?) ?? 400,
        },
    };

    const prefix = 'packages/compapp_design/';
    for (final MapEntry(key: token, value: style)
        in AppTypography.values.entries) {
      final family = style.fontFamily!.replaceFirst(prefix, '');
      expect(
        declared[family] ?? const <int>{},
        contains(style.fontWeight?.value ?? 400),
        reason: 'font.$token: $family ${style.fontWeight?.value}',
      );
    }
  });

  test('every declared font asset exists on disk', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'asset:\s*(\S+\.ttf)')
        .allMatches(pubspec)
        .map((match) => match.group(1)!)
        .toList();

    expect(assets, isNotEmpty);
    for (final asset in assets) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });
}

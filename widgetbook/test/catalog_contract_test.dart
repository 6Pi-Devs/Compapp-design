import 'dart:convert';
import 'dart:io';

import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:flutter_test/flutter_test.dart';

final _pathPattern = RegExp(
  '^(Atoms|Molecules|Organisms|Templates)/[A-Z][A-Za-z0-9]*'
  r'/[a-z0-9]+(-[a-z0-9]+)+$',
);

void main() {
  final stories = _manifestStories();
  final useCases = collectUseCases(buildCatalog()).keys.toSet();

  test('every manifest story has a use case', () {
    expect(
      stories.difference(useCases),
      isEmpty,
      reason: 'manifest stories without a use case in the Widgetbook tree',
    );
  });

  test('every use case is a manifest story', () {
    expect(
      useCases.difference(stories),
      isEmpty,
      reason: 'use cases in the Widgetbook tree missing from components.json',
    );
  });

  test('each entry has one story per variant x state, no more, no fewer', () {
    final mismatched = [
      for (final entry in _manifestEntries())
        if (!_sameSet(
          (entry['stories'] as List<dynamic>).cast<String>(),
          _expectedStories(entry),
        ))
          '${entry['id']}: expected ${_expectedStories(entry)}',
    ];
    expect(mismatched, isEmpty);
  });

  test('use case paths are <Level>/<Class>/<variant>-<state>', () {
    expect(useCases.where((path) => !_pathPattern.hasMatch(path)), isEmpty);
  });
}

List<Map<String, dynamic>> _manifestEntries() {
  final manifest = jsonDecode(
    File('../components.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (manifest['components'] as List<dynamic>).cast<Map<String, dynamic>>();
}

Set<String> _manifestStories() => {
  for (final entry in _manifestEntries())
    ...(entry['stories'] as List<dynamic>).cast<String>(),
};

/// `Atoms/AppIcon/gallery-default` for every variant x state of an entry.
Set<String> _expectedStories(Map<String, dynamic> entry) {
  final level = entry['level'] as String;
  final folder = '${level[0].toUpperCase()}${level.substring(1)}s';
  return {
    for (final variant in (entry['variants'] as List<dynamic>))
      for (final state in (entry['states'] as List<dynamic>))
        '$folder/${entry['class']}/$variant-$state',
  };
}

bool _sameSet(List<String> actual, Set<String> expected) =>
    actual.length == expected.length && actual.toSet().containsAll(expected);

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
  final useCases = collectFixedUseCases(buildCatalog()).keys.toSet();

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

  test('a story splits into one variant and one state, even with dashes', () {
    final ambiguous = [
      for (final entry in _manifestEntries())
        for (final story in (entry['stories'] as List<dynamic>).cast<String>())
          if (_splits(entry, story.split('/').last).length != 1)
            '$story: ${_splits(entry, story.split('/').last)}',
    ];
    expect(ambiguous, isEmpty);
  });

  group('playgrounds', () {
    final playgrounds = collectPlaygrounds(buildCatalog()).keys.toList();
    final declared = [
      for (final entry in _manifestEntries()) entry['playground'] as String,
    ];

    test('the tree has exactly the playgrounds the manifest declares', () {
      expect(playgrounds.toSet(), declared.toSet());
      expect(playgrounds.length, declared.length, reason: 'no duplicates');
    });

    test('every component has exactly one playground, and it is no story', () {
      final perComponent = <String, int>{};
      for (final path in playgrounds) {
        final component = path.split('/').take(2).join('/');
        perComponent[component] = (perComponent[component] ?? 0) + 1;
      }
      expect(perComponent, {
        for (final path in declared) path.split('/').take(2).join('/'): 1,
      });
      expect(stories.intersection(playgrounds.toSet()), isEmpty);
    });
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

/// The `(variant, state)` pairs of [entry] that spell [name], which is the
/// last segment of a story path. Variants may contain dashes, so the name is
/// matched against the declared variants and states, never split on a dash.
List<(String, String)> _splits(Map<String, dynamic> entry, String name) => [
  for (final variant in (entry['variants'] as List<dynamic>).cast<String>())
    for (final state in (entry['states'] as List<dynamic>).cast<String>())
      if ('$variant-$state' == name) (variant, state),
];

bool _sameSet(List<String> actual, Set<String> expected) =>
    actual.length == expected.length && actual.toSet().containsAll(expected);

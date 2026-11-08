import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _levels = ['atoms', 'molecules', 'organisms', 'templates'];
const _entryLevels = ['atom', 'molecule', 'organism', 'template'];
const _requiredFields = [
  'id',
  'level',
  'class',
  'playground',
  'path',
  'props',
  'variants',
  'states',
  'semantics',
  'key',
  'stories',
];

void main() {
  final entries = _loadEntries();

  test('declares schema version 1', () {
    final root = _readManifest();
    expect(root[r'$schema-version'], 1);
  });

  test('every entry points to an existing file', () {
    final missing = [
      for (final entry in entries)
        if (!File('lib/src/${entry['path']}').existsSync())
          '${entry['id']}: lib/src/${entry['path']}',
    ];
    expect(missing, isEmpty, reason: 'manifest paths without a file');
  });

  test('every entry sits under the folder of its level', () {
    final misplaced = [
      for (final entry in entries)
        if (!'${entry['path']}'.startsWith('${entry['level']}s/'))
          '${entry['id']}: level ${entry['level']}, path ${entry['path']}',
    ];
    expect(misplaced, isEmpty);
  });

  test('every widget file has a manifest entry', () {
    final declared = {for (final entry in entries) entry['path']};
    final undeclared = [
      for (final level in _levels)
        if (Directory('lib/src/$level').existsSync())
          for (final file in Directory(
            'lib/src/$level',
          ).listSync(recursive: true))
            if (file is File && file.path.endsWith('.dart'))
              file.path.replaceAll(r'\', '/').replaceFirst('lib/src/', ''),
    ].where((path) => !declared.contains(path)).toList();
    expect(
      undeclared,
      isEmpty,
      reason: 'widget files missing from components.json',
    );
  });

  test('every entry has the required fields', () {
    final incomplete = [
      for (final entry in entries)
        for (final field in _requiredFields)
          if (entry[field] == null) '${entry['id']}: $field',
    ];
    expect(incomplete, isEmpty);
  });

  test('every level is atom, molecule, organism or template', () {
    final invalid = [
      for (final entry in entries)
        if (!_entryLevels.contains(entry['level']))
          '${entry['id']}: ${entry['level']}',
    ];
    expect(invalid, isEmpty);
  });

  test('every entry class is declared in its file', () {
    final missing = [
      for (final entry in entries)
        if (File('lib/src/${entry['path']}').existsSync() &&
            !RegExp('\\b(class|enum|mixin)\\s+${entry['class']}\\b')
                .hasMatch(File('lib/src/${entry['path']}').readAsStringSync()))
          '${entry['id']}: ${entry['class']} not in ${entry['path']}',
    ];
    expect(missing, isEmpty);
  });

  test('every entry has one playground at <Level>/<Class>/playground', () {
    final wrong = [
      for (final entry in entries)
        if (entry['playground'] !=
            '${_folder(entry['level'] as String)}/${entry['class']}/playground')
          '${entry['id']}: ${entry['playground']}',
    ];
    expect(wrong, isEmpty);
  });

  test('playgrounds are unique and are not stories', () {
    final playgrounds = [for (final entry in entries) entry['playground']];
    final stories = {
      for (final entry in entries)
        ...(entry['stories'] as List<dynamic>).cast<String>(),
    };
    expect(playgrounds.toSet().length, playgrounds.length);
    expect(stories.intersection(playgrounds.toSet().cast<String>()), isEmpty);
  });

  test('ids, classes and paths are unique', () {
    final ids = [for (final entry in entries) entry['id']];
    final classes = [for (final entry in entries) entry['class']];
    final paths = [for (final entry in entries) entry['path']];
    expect(paths.toSet().length, paths.length, reason: 'duplicated paths');
    expect(ids.toSet().length, ids.length, reason: 'duplicated ids');
    expect(
      classes.toSet().length,
      classes.length,
      reason: 'duplicated classes',
    );
  });
}

String _folder(String level) =>
    '${level[0].toUpperCase()}${level.substring(1)}s';

Map<String, dynamic> _readManifest() {
  final decoded = jsonDecode(File('components.json').readAsStringSync());
  return decoded as Map<String, dynamic>;
}

List<Map<String, dynamic>> _loadEntries() {
  final components = _readManifest()['components'] as List<dynamic>;
  return components.cast<Map<String, dynamic>>();
}

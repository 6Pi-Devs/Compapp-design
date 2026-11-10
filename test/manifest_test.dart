import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _levels = ['atoms', 'molecules', 'organisms', 'templates'];

/// Internal folders under `lib/src/` that hold no component: they are not in
/// the manifest and the barrel does not export them.
const _internalFolders = ['foundation'];
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

  test('declares schema version 2', () {
    final root = _readManifest();
    expect(root[r'$schema-version'], 2);
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

  test('internal folders are not components and are not exported', () {
    final inManifest = [
      for (final entry in entries)
        for (final folder in _internalFolders)
          if ('${entry['path']}'.startsWith('$folder/'))
            '${entry['id']}: ${entry['path']}',
    ];
    final exported = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          for (final target in _exportTargets(
            file.path.replaceAll(r'\', '/'),
            file.readAsStringSync(),
          ))
            if (_internalFolders.any(
              (folder) => target.startsWith('lib/src/$folder/'),
            ))
              '${file.path}: $target',
    ];
    expect(inManifest, isEmpty, reason: 'internal files in components.json');
    expect(exported, isEmpty, reason: 'internal folders re-exported');
  });

  group('export targets', () {
    test('resolve package and relative URIs to a path under lib/', () {
      const source = '''
export 'package:compapp_design/src/foundation/equal_pair.dart';
export '../foundation/dashed_border.dart' show DashedBorder;
export "src/atoms/app_button.dart";
export 'package:other/foundation.dart';
// export 'src/foundation/commented.dart';
''';

      expect(_exportTargets('lib/src/molecules/a.dart', source), [
        'lib/src/foundation/equal_pair.dart',
        'lib/src/foundation/dashed_border.dart',
        'lib/src/molecules/src/atoms/app_button.dart',
        'package:other/foundation.dart',
      ]);
    });

    test('a folder that only shares the prefix is not an internal one', () {
      expect(
        _exportTargets(
          'lib/a.dart',
          "export 'src/foundation_extras/x.dart';",
        ).any((target) => target.startsWith('lib/src/foundation/')),
        isFalse,
      );
    });
  });

  test('notes, when present, are an array of non-empty strings', () {
    final invalid = [
      for (final entry in entries)
        if (entry.containsKey('notes') &&
            !(entry['notes'] is List &&
                (entry['notes'] as List).isNotEmpty &&
                (entry['notes'] as List).every(
                  (note) => note is String && note.trim().isNotEmpty,
                )))
          '${entry['id']}: ${entry['notes']}',
    ];
    expect(invalid, isEmpty, reason: 'notes must be a list of strings');
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

/// The files `export` directives in [source] (at [path]) point to: a path
/// under `lib/` for a `package:compapp_design/` or relative URI, the URI itself
/// for any other package.
List<String> _exportTargets(String path, String source) {
  const prefix = 'package:compapp_design/';
  return [
    for (final match in RegExp(
      r'''^\s*export\s+['"]([^'"]+)['"]''',
      multiLine: true,
    ).allMatches(source))
      switch (match.group(1)!) {
        final uri when uri.startsWith(prefix) =>
          'lib/${uri.substring(prefix.length)}',
        final uri when uri.startsWith('package:') || uri.startsWith('dart:') =>
          uri,
        final uri => Uri.parse(path).resolve(uri).path,
      },
  ];
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

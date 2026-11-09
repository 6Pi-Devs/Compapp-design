import 'dart:io';

import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase _useCase(String name) =>
    WidgetbookUseCase(name: name, builder: (_) => const SizedBox());

final _tree = [
  WidgetbookFolder(
    name: 'Atoms',
    children: [
      WidgetbookComponent(
        name: 'AppIcon',
        useCases: [_useCase('gallery-default'), _useCase('playground')],
      ),
    ],
  ),
];

void main() {
  test('isPlaygroundPath matches only a use case named playground', () {
    expect(isPlaygroundPath('Atoms/AppIcon/playground'), isTrue);
    expect(isPlaygroundPath('Atoms/AppIcon/gallery-default'), isFalse);
    expect(isPlaygroundPath('Atoms/Playground/gallery-default'), isFalse);
  });

  test('collectFixedUseCases leaves playgrounds out', () {
    expect(collectFixedUseCases(_tree).keys, ['Atoms/AppIcon/gallery-default']);
  });

  test('collectPlaygrounds keeps only playgrounds', () {
    expect(collectPlaygrounds(_tree).keys, ['Atoms/AppIcon/playground']);
  });

  test('a fixed and a playground partition the whole tree', () {
    expect({
      ...collectFixedUseCases(_tree).keys,
      ...collectPlaygrounds(_tree).keys,
    }, collectUseCases(_tree).keys.toSet());
  });

  // A playground reads knobs, so it only builds inside a Widgetbook app. The
  // goldens, semantics and layout tests must feed on fixed use cases only.
  test('golden, semantics and layout harnesses use fixed use cases only', () {
    for (final file in [
      'test/catalog_goldens_test.dart',
      'test/catalog_semantics_test.dart',
      'test/catalog_freshness_bar_layout_test.dart',
      'test/catalog_contract_test.dart',
      'test/catalog_text_contrast_test.dart',
    ]) {
      // Only code counts: a comment may name the function it warns about.
      final source = File(file)
          .readAsLinesSync()
          .map((line) => line.replaceFirst(RegExp('//.*'), ''))
          .join('\n');
      expect(source, contains('collectFixedUseCases('), reason: file);
      expect(
        RegExp(r'\bcollectUseCases\(').hasMatch(source),
        isFalse,
        reason: file,
      );
    }
  });
}

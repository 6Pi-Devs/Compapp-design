import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase _useCase(String name) =>
    WidgetbookUseCase(name: name, builder: (_) => const SizedBox());

void main() {
  test('joins folder, component and use case names with a slash', () {
    final useCases = collectUseCases([
      WidgetbookFolder(
        name: 'Atoms',
        children: [
          WidgetbookComponent(
            name: 'AppIcon',
            useCases: [_useCase('gallery-default')],
          ),
          WidgetbookComponent(
            name: 'AppChip',
            useCases: [_useCase('filled-default'), _useCase('filled-pressed')],
          ),
        ],
      ),
    ]);

    expect(useCases.keys, [
      'Atoms/AppIcon/gallery-default',
      'Atoms/AppChip/filled-default',
      'Atoms/AppChip/filled-pressed',
    ]);
  });

  test('is empty for an empty tree', () {
    expect(collectUseCases([]), isEmpty);
  });

  test('rejects two use cases with the same path', () {
    expect(
      () => collectUseCases([
        WidgetbookFolder(
          name: 'Atoms',
          children: [
            WidgetbookComponent(
              name: 'AppIcon',
              useCases: [_useCase('a-b'), _useCase('a-b')],
            ),
          ],
        ),
      ]),
      throwsStateError,
    );
  });
}

import 'package:widgetbook/widgetbook.dart';

/// Every use case under [directories] by its path, for example
/// `Atoms/AppIcon/gallery-default`: the names of the nodes from the first
/// folder down to the use case, joined with `/`.
///
/// Throws a [StateError] when two use cases share a path.
Map<String, WidgetbookUseCase> collectUseCases(
  List<WidgetbookNode> directories,
) {
  final root = WidgetbookRoot(children: directories);
  final useCases = <String, WidgetbookUseCase>{};
  for (final useCase in root.leaves.whereType<WidgetbookUseCase>()) {
    final path = useCase.nodesPath.skip(1).map((node) => node.name).join('/');
    if (useCases.containsKey(path)) {
      throw StateError('Duplicated use case path: $path');
    }
    useCases[path] = useCase;
  }
  return useCases;
}

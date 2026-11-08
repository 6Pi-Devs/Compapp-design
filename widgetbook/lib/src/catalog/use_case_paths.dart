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

/// The name of the one knob use case every component has. It is a playground
/// for interactive exploration, never an input of goldens or semantics tests.
const playgroundUseCaseName = 'playground';

/// Whether [path] (`Atoms/AppButton/playground`) is a playground.
bool isPlaygroundPath(String path) =>
    path.split('/').last == playgroundUseCaseName;

/// The fixed use cases under [directories]: every one that is not a
/// playground. They have no knobs, so they build outside Widgetbook, and they
/// are the only inputs of goldens, semantics tests and the manifest contract.
Map<String, WidgetbookUseCase> collectFixedUseCases(
  List<WidgetbookNode> directories,
) => {
  for (final entry in collectUseCases(directories).entries)
    if (!isPlaygroundPath(entry.key)) entry.key: entry.value,
};

/// The playgrounds under [directories]. They read knobs, so they only build
/// inside a Widgetbook app.
Map<String, WidgetbookUseCase> collectPlaygrounds(
  List<WidgetbookNode> directories,
) => {
  for (final entry in collectUseCases(directories).entries)
    if (isPlaygroundPath(entry.key)) entry.key: entry.value,
};

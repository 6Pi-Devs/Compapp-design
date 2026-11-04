import 'package:compapp_design_widgetbook/src/catalog/atoms.dart';
import 'package:widgetbook/widgetbook.dart';

/// The whole Widgetbook tree, written by hand. Every use case in it is also
/// a golden and a semantics test, and must match a manifest `stories` entry.
List<WidgetbookNode> buildCatalog() {
  final atoms = buildAtoms();
  return [
    if (atoms.isNotEmpty) WidgetbookFolder(name: 'Atoms', children: atoms),
  ];
}

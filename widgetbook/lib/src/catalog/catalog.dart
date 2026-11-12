import 'package:compapp_design_widgetbook/src/catalog/atoms.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules.dart';
import 'package:compapp_design_widgetbook/src/catalog/organisms.dart';
import 'package:compapp_design_widgetbook/src/catalog/templates.dart';
import 'package:widgetbook/widgetbook.dart';

/// The whole Widgetbook tree, written by hand. Every fixed use case in it is
/// also a golden and a semantics test, and must match a manifest `stories`
/// entry. Each component also has one `playground`, with knobs: it is neither
/// a golden nor a story, and the manifest names it in `playground`.
List<WidgetbookNode> buildCatalog() {
  final atoms = buildAtoms();
  final molecules = buildMolecules();
  final organisms = buildOrganisms();
  final templates = buildTemplates();
  return [
    if (atoms.isNotEmpty) WidgetbookFolder(name: 'Atoms', children: atoms),
    if (molecules.isNotEmpty)
      WidgetbookFolder(name: 'Molecules', children: molecules),
    if (organisms.isNotEmpty)
      WidgetbookFolder(name: 'Organisms', children: organisms),
    if (templates.isNotEmpty)
      WidgetbookFolder(name: 'Templates', children: templates),
  ];
}

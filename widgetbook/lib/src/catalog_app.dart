import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:widgetbook/widgetbook.dart';

class CatalogApp extends StatelessWidget {
  const new({this.initialRoute = '/', super.key});

  /// The route Widgetbook opens at: `/` for the catalog, or one with `path`,
  /// `preview` and `knobs` query parameters to open a use case with knob
  /// values, as the tests do.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      initialRoute: initialRoute,
      directories: buildCatalog(),
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: CompappTheme.light),
            WidgetbookTheme(name: 'Dark', data: CompappTheme.dark),
          ],
        ),
        LocalizationAddon(
          locales: const [Locale('en'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
        TextScaleAddon(),
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhone13,
          AndroidViewports.samsungGalaxyS20,
        ]),
      ],
    );
  }
}

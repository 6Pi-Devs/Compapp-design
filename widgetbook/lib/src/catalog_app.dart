import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:widgetbook/widgetbook.dart';

class CatalogApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
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

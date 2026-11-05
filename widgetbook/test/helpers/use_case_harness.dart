import 'package:alchemist/alchemist.dart';
import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

/// Width goldens give a use case, a narrow phone like the app's smallest
/// target. Wrapping content has to fit it at every text scale.
const goldenScenarioWidth = 360.0;

const _largeTextScale = 2.0;

typedef ThemeVariant = ({String name, ThemeData data});

final themeVariants = <ThemeVariant>[
  (name: 'light', data: CompappTheme.light),
  (name: 'dark', data: CompappTheme.dark),
];

/// A use case on the page of [theme], as the Widgetbook Material theme addon
/// shows it.
Widget themedUseCase(WidgetbookUseCase useCase, ThemeData theme) {
  return Theme(
    data: theme,
    child: ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!,
        child: Builder(builder: useCase.build),
      ),
    ),
  );
}

/// The four scenarios of a golden: light and dark, each at text scale 1.0 and
/// 2.0.
List<GoldenTestScenario> goldenScenarios(WidgetbookUseCase useCase) {
  return [
    for (final theme in themeVariants)
      for (final scale in const [1.0, _largeTextScale])
        GoldenTestScenario.withTextScaleFactor(
          name: '${theme.name} ${scale.toStringAsFixed(1)}x',
          textScaler: TextScaler.linear(scale),
          child: themedUseCase(useCase, theme.data),
        ),
  ];
}

const _hostWidth = 800.0;
const _probeHeight = 20000.0;
const _contentKey = Key('semantics-host.content');

/// An English-locale Material app around a use case, for semantics tests.
Widget semanticsHost(WidgetbookUseCase useCase, ThemeData theme) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(
      body: SingleChildScrollView(
        // flutter_test skips tap targets that touch the edge of a scrolling
        // ancestor, so the padding keeps small targets visible to the checks.
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: KeyedSubtree(
          key: _contentKey,
          child: Builder(builder: useCase.build),
        ),
      ),
    ),
  );
}

/// Pumps [semanticsHost] on a surface as tall as the content.
///
/// The default 800x600 surface hides whatever sits below the fold from the
/// tap target and contrast guidelines, so the surface is measured first and
/// resized to fit the whole use case.
Future<void> pumpUseCase(
  WidgetTester tester,
  WidgetbookUseCase useCase,
  ThemeData theme,
) async {
  final view = tester.view;
  addTearDown(view.reset);
  final ratio = view.devicePixelRatio;

  view.physicalSize = const Size(_hostWidth, _probeHeight) * ratio;
  await tester.pumpWidget(semanticsHost(useCase, theme));
  final contentHeight = tester.getSize(find.byKey(_contentKey)).height;

  view.physicalSize =
      Size(_hostWidth, contentHeight + AppSpacing.xl * 2) * ratio;
  await tester.pump();
}

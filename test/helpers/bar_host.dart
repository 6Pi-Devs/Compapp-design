import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'host.dart' show semanticsNodes;

/// Key of the `RepaintBoundary` around the widget under test, for reading
/// painted pixels.
const barBoundaryKey = Key('bar-boundary');

/// A `MaterialApp` for a bar: a full-width widget that reads the safe-area
/// insets of `MediaQuery`. It is not the molecule `host` of `host.dart`,
/// which pads the widget and gives it a narrow column.
///
/// It shows [child] at the top, at the given [width] (unbounded when null),
/// text scale and direction, in a [RepaintBoundary] keyed [barBoundaryKey], on
/// the page color of the theme.
Widget barHost(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  double? width = 360,
  bool disableAnimations = false,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    builder: (context, app) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
          padding: padding,
          viewPadding: padding,
        ),
        child: app!,
      ),
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: RepaintBoundary(key: barBoundaryKey, child: child),
        ),
      ),
    ),
  );
}

/// The nodes that carry a label.
List<SemanticsNode> labeledNodes(WidgetTester tester) => [
  for (final node in semanticsNodes(tester))
    if (node.label.isNotEmpty) node,
];

/// The light and dark theme under a readable name.
List<(String, ThemeData)> get themes => [
  ('light', CompappTheme.light),
  ('dark', CompappTheme.dark),
];

/// The rectangle of [finder] in the coordinates of the host boundary.
Rect inBarHost(WidgetTester tester, Finder finder) => tester
    .getRect(finder)
    .shift(-tester.getTopLeft(find.byKey(barBoundaryKey)));

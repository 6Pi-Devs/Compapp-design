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

/// The colors painted inside [rect] (in the coordinates of the host boundary),
/// read from the rendered pixels in one pass.
Future<List<Color>> paintedRegion(WidgetTester tester, Rect rect) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(barBoundaryKey),
  );
  final colors = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    final found = <Color>[];
    for (var y = rect.top.floor(); y < rect.bottom.ceil(); y++) {
      for (var x = rect.left.floor(); x < rect.right.ceil(); x++) {
        if (x < 0 || y < 0 || x >= image.width || y >= image.height) continue;
        final offset = (y * image.width + x) * 4;
        found.add(
          Color.fromARGB(
            data.getUint8(offset + 3),
            data.getUint8(offset),
            data.getUint8(offset + 1),
            data.getUint8(offset + 2),
          ),
        );
      }
    }
    return found;
  });
  return colors!;
}

/// How many of [colors] are [color].
int countColor(List<Color> colors, Color color) => colors
    .where((candidate) => isSameColorAs(color).matches(candidate, {}))
    .length;

/// The rectangle of [finder] in the coordinates of the host boundary.
Rect inBarHost(WidgetTester tester, Finder finder) => tester
    .getRect(finder)
    .shift(-tester.getTopLeft(find.byKey(barBoundaryKey)));

/// Fails when a word of the [Text] [finder] is wider than the text itself,
/// which is when a line has to break inside a word. The text is as wide as
/// its longest line, so every word fitting in it means no word was cut. It
/// measures with the text scale and style the text really has, so load the
/// bundled fonts first.
void expectNoMidWordBreaks(
  WidgetTester tester,
  Finder finder, {
  String reason = '',
}) {
  final element = tester.element(finder);
  final text = tester.widget<Text>(finder);
  final style = DefaultTextStyle.of(element).style.merge(text.style);
  final scaler = MediaQuery.textScalerOf(element);
  final width = tester.getSize(finder).width;
  final cut = <String>[];
  for (final word in text.data!.split(RegExp(r'\s+'))) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: Directionality.of(element),
      textScaler: scaler,
    )..layout();
    if (painter.width > width + 0.5) cut.add(word);
    painter.dispose();
  }
  expect(cut, isEmpty, reason: 'words cut in "${text.data}" $reason');
}

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The key of the [RepaintBoundary] [host] puts around the widget, for
/// `paintedColorAt`.
const hostBoundaryKey = Key('host-boundary');

/// The width [host] gives the widget, a narrow phone column.
const hostWidth = 320.0;

/// A themed app that shows [child] in a column of [width], in the reading
/// [direction], at [textScale].
///
/// [background] is what the widget sits on, so a molecule is judged on the
/// page, on a card and on a tinted surface.
Widget host(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  double width = hostWidth,
  Color? background,
}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    builder: (context, app) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
    ),
    home: Scaffold(
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: width,
            child: RepaintBoundary(
              key: hostBoundaryKey,
              child: ColoredBox(
                color: background ?? Colors.transparent,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Every semantics node under the scaffold, parents before children.
List<SemanticsNode> semanticsNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(Scaffold)));
  return nodes;
}

/// The labels of every node under the scaffold that has one.
List<String> semanticsLabels(WidgetTester tester) => [
  for (final node in semanticsNodes(tester))
    if (node.label.isNotEmpty) node.label,
];

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: CompappTheme.light,
      builder: (context, app) =>
          Directionality(textDirection: direction, child: app!),
      home: Scaffold(body: Center(child: child)),
    );

Finder get _paint => find.descendant(
  of: find.byType(AppIcon),
  matching: find.byType(CustomPaint),
);

/// The scale and the stroke the glyph is drawn with.
({double scale, Offset offset, Paint paint}) _drawn(WidgetTester tester) {
  Offset? offset;
  double? scale;
  Paint? paint;
  expect(
    tester.renderObject<RenderCustomPaint>(_paint),
    paints
      ..something((method, arguments) {
        if (method != #translate) return false;
        offset = Offset(arguments[0] as double, arguments[1] as double);
        return true;
      })
      ..something((method, arguments) {
        if (method != #scale) return false;
        scale = arguments[0] as double;
        return true;
      })
      ..something((method, arguments) {
        if (method != #drawPath) return false;
        paint = arguments[1] as Paint;
        return true;
      }),
  );
  return (scale: scale!, offset: offset!, paint: paint!);
}

bool _hasNode(WidgetTester tester, bool Function(SemanticsNode) test) {
  var found = false;
  void visit(SemanticsNode node) {
    if (test(node)) found = true;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(Scaffold)));
  return found;
}

void main() {
  group('AppIcon size', () {
    testWidgets('is the 24 px grid by default', (tester) async {
      await tester.pumpWidget(_host(const AppIcon(AppIcons.bell)));

      expect(
        tester.getSize(find.byType(AppIcon)),
        const Size.square(AppIcons.gridSize),
      );
      expect(_drawn(tester).scale, 1);
    });

    testWidgets('scales the glyph and keeps the stroke on the grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AppIcon(AppIcons.bell, size: AppSizes.minTarget)),
      );

      expect(
        tester.getSize(find.byType(AppIcon)),
        const Size.square(AppSizes.minTarget),
      );
      final drawn = _drawn(tester);
      expect(drawn.scale, 2);
      expect(drawn.paint.strokeWidth, AppIcons.strokeWidth);
    });

    testWidgets('scales down below the grid size', (tester) async {
      await tester.pumpWidget(_host(const AppIcon(AppIcons.bell, size: 12)));

      expect(_drawn(tester).scale, 0.5);
    });

    testWidgets('keeps its size inside a larger square and centers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox.square(
            dimension: AppSizes.minTarget,
            child: AppIcon(AppIcons.bell),
          ),
        ),
      );

      expect(_drawn(tester).scale, 1);
      expect(tester.getSize(_paint), const Size.square(AppIcons.gridSize));
      expect(
        tester.getCenter(_paint),
        tester.getCenter(find.byType(SizedBox).first),
      );
    });

    testWidgets('centers without overflow under tight non-square constraints', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: AppSizes.minTarget,
            height: AppIcons.gridSize,
            child: AppIcon(AppIcons.bell),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_drawn(tester).scale, 1);
      expect(tester.getSize(_paint), const Size.square(AppIcons.gridSize));
      expect(tester.getCenter(_paint), tester.getCenter(find.byType(AppIcon)));
    });

    testWidgets('fits the glyph in a tight box smaller than its size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 16,
            height: AppIcons.gridSize,
            child: AppIcon(AppIcons.bell),
          ),
        ),
      );

      final drawn = _drawn(tester);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_paint), const Size(16, AppIcons.gridSize));
      expect(drawn.scale, 16 / AppIcons.gridSize);
      expect(drawn.offset, const Offset(0, 4));
    });

    testWidgets('fits the glyph in a tight box shorter than its size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: AppIcons.gridSize,
            height: 16,
            child: AppIcon(AppIcons.bell),
          ),
        ),
      );

      final drawn = _drawn(tester);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_paint), const Size(AppIcons.gridSize, 16));
      expect(drawn.scale, 16 / AppIcons.gridSize);
      expect(drawn.offset, const Offset(4, 0));
    });

    testWidgets('takes the IconTheme size, and the prop wins over it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const IconTheme(
            data: IconThemeData(size: 36),
            child: AppIcon(AppIcons.bell),
          ),
        ),
      );
      expect(_drawn(tester).scale, 1.5);

      await tester.pumpWidget(
        _host(
          const IconTheme(
            data: IconThemeData(size: 36),
            child: AppIcon(AppIcons.bell, size: 12),
          ),
        ),
      );
      expect(_drawn(tester).scale, 0.5);
    });
  });

  group('AppIcon color', () {
    testWidgets('uses the theme icon color by default', (tester) async {
      await tester.pumpWidget(_host(const AppIcon(AppIcons.bell)));

      expect(
        _drawn(tester).paint.color,
        isSameColorAs(CompappTheme.light.colorScheme.onSurface),
      );
    });

    testWidgets('uses the IconTheme color and opacity', (tester) async {
      await tester.pumpWidget(
        _host(
          const IconTheme(
            data: IconThemeData(color: Colors.red, opacity: 0.5),
            child: AppIcon(AppIcons.bell),
          ),
        ),
      );

      expect(
        _drawn(tester).paint.color,
        isSameColorAs(Colors.red.withValues(alpha: 0.5)),
      );
    });

    testWidgets('prefers the color prop over the IconTheme', (tester) async {
      await tester.pumpWidget(
        _host(
          const IconTheme(
            data: IconThemeData(color: Colors.red),
            child: AppIcon(AppIcons.bell, color: Colors.blue),
          ),
        ),
      );

      expect(_drawn(tester).paint.color, isSameColorAs(Colors.blue));
    });
  });

  group('AppIcon text direction', () {
    bool flipped(WidgetTester tester) => tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(AppIcon),
            matching: find.byType(Transform),
          ),
        )
        .any((transform) => transform.transform.storage[0] == -1);

    testWidgets('mirrors a directional glyph in right-to-left text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AppIcon(AppIcons.back), direction: TextDirection.rtl),
      );

      expect(flipped(tester), isTrue);
    });

    testWidgets('does not mirror a directional glyph in left-to-right text', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppIcon(AppIcons.back)));

      expect(flipped(tester), isFalse);
    });

    testWidgets('never mirrors a glyph that is not directional', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AppIcon(AppIcons.bell), direction: TextDirection.rtl),
      );

      expect(flipped(tester), isFalse);
    });
  });

  group('AppIcon semantics', () {
    testWidgets('has no semantics node without a label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const AppIcon(AppIcons.bell)));

      expect(
        _hasNode(
          tester,
          (node) =>
              node.label.isNotEmpty ||
              node.getSemanticsData().flagsCollection.isImage,
        ),
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('treats an empty label like no label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AppIcon(AppIcons.bell, semanticLabel: '')),
      );

      expect(
        _hasNode(
          tester,
          (node) => node.getSemanticsData().flagsCollection.isImage,
        ),
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('is an image with the label when one is set', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AppIcon(AppIcons.bell, semanticLabel: 'Notifications')),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Notifications')),
        isSemantics(label: 'Notifications', isImage: true),
      );
      handle.dispose();
    });

    testWidgets('does not merge its image flag into an ancestor button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Semantics(
            button: true,
            label: 'Open',
            onTap: () {},
            child: const AppIcon(AppIcons.bell, semanticLabel: 'Bell'),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Open')),
        isSemantics(label: 'Open', isButton: true, isImage: false),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bell')),
        isSemantics(label: 'Bell', isImage: true),
      );
      handle.dispose();
    });
  });
}

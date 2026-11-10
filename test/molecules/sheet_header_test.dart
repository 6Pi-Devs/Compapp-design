import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bar_host.dart';
import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

SheetHeader _header({
  String title = 'Ask Carlos to free the washer?',
  VoidCallback? onClose,
}) => SheetHeader(title: title, onClose: onClose ?? () {}, closeLabel: 'Close');

final Finder _close = find.byKey(const Key('sheet.close'));
final Finder _handle = find.byKey(const Key('sheet.handle'));
final Finder _title = find.byKey(const Key('sheet.title'));

void main() {
  group('content', () {
    testWidgets('shows the handle, the title and the close button', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_header()));

      expect(find.text('Ask Carlos to free the washer?'), findsOneWidget);
      expect(_handle, findsOneWidget);
      expect(
        tester
            .widget<AppIcon>(
              find.descendant(of: _close, matching: find.byType(AppIcon)),
            )
            .icon,
        AppIcons.close,
      );
    });

    testWidgets('the handle is a 40 by 4 pill centered above the title', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_header()));

      final handle = tester.getRect(_handle);
      expect(handle.size, const Size(40, 4));
      expect(handle.center.dx, closeTo(180, 0.5));
      expect(handle.bottom, lessThan(tester.getRect(_title).top));
      final decoration =
          tester.widget<DecoratedBox>(_handle).decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(2));
    });

    testWidgets('close calls onClose', (tester) async {
      var closed = 0;
      await tester.pumpWidget(barHost(_header(onClose: () => closed++)));

      await tester.tap(_close);

      expect(closed, 1);
    });

    testWidgets('draws no surface of its own', (tester) async {
      await tester.pumpWidget(barHost(_header()));
      final origin = tester.getTopLeft(find.byKey(barBoundaryKey));
      final header = tester.getRect(find.byType(SheetHeader)).shift(-origin);

      final corner = await paintedColorAt(
        tester,
        barBoundaryKey,
        Offset(header.left + 1, header.top + 1),
      );

      expect(corner.a, 0, reason: 'nothing is painted behind the content');
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      testWidgets('the handle is painted in the outline color ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(barHost(_header(), theme: theme));
        await tester.pumpAndSettle();

        final color = await paintedColorAtCenter(
          tester,
          barBoundaryKey,
          _handle,
        );

        expect(color, isSameColorAs(theme.colorScheme.outline), reason: name);
      });

      testWidgets('title and close glyph use their theme colors ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(barHost(_header(), theme: theme));
        await tester.pumpAndSettle();

        expect(
          tester.widget<Text>(_title).style!.color,
          theme.colorScheme.onSurface,
        );
        final button = tester.widget<TextButton>(_close);
        expect(
          button.style!.foregroundColor!.resolve({}),
          theme.colorScheme.onSurfaceVariant,
        );
      });
    }
  });

  group('semantics', () {
    testWidgets('the title is a heading', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_header()));

      expect(
        tester.getSemantics(find.text('Ask Carlos to free the washer?')),
        isSemantics(label: 'Ask Carlos to free the washer?', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('close is one focusable button named by closeLabel', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_header()));

      expect(
        tester.getSemantics(_close),
        isSemantics(
          label: 'Close',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the handle is not in the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_header()));

      expect(
        labeledNodes(tester).map((node) => node.label).toList(),
        unorderedEquals(['Ask Carlos to free the washer?', 'Close']),
      );
      handle.dispose();
    });

    testWidgets('passes the Flutter tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_header()));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('semantics under a grouping parent', () {
    // A `Card`, a list item and a `Semantics(container: true)` all group what
    // is inside them. The header must keep its heading and its button apart.
    final parents = <String, Widget Function(Widget)>{
      'a Card': (header) => Card(child: header),
      'a ListView item': (header) =>
          SizedBox(height: 400, child: ListView(children: [header])),
      'a Semantics container': (header) =>
          Semantics(container: true, child: header),
      'a Column': (header) => Column(children: [header]),
    };

    for (final MapEntry(key: name, value: wrap) in parents.entries) {
      testWidgets('the title is a heading of its own and close is a button '
          'in $name', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(barHost(wrap(_header())));

        final heading = tester.getSemantics(_title);
        expect(heading.label, 'Ask Carlos to free the washer?');
        expect(heading.flagsCollection.isHeader, isTrue);
        expect(heading.childrenCount, 0);
        final close = tester.getSemantics(_close);
        expect(close.label, 'Close');
        expect(close.flagsCollection.isButton, isTrue);
        var ancestor = close.parent;
        while (ancestor != null) {
          expect(ancestor.flagsCollection.isHeader, isFalse);
          ancestor = ancestor.parent;
        }
        handle.dispose();
      });
    }

    testWidgets('the title is read before the close button', (tester) async {
      final handle = tester.ensureSemantics();
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(barHost(_header(), direction: direction));

        final group = tester.getSemantics(_title).parent!;
        final order = [
          for (final node in group.debugListChildrenInOrder(
            DebugSemanticsDumpOrder.traversalOrder,
          ))
            node.label,
        ];

        expect(order, [
          'Ask Carlos to free the washer?',
          'Close',
        ], reason: '$direction');
      }
      handle.dispose();
    });
  });

  group('asserts and layout', () {
    test('the close button needs a spoken label', () {
      expect(
        () => SheetHeader(title: 'T', onClose: () {}, closeLabel: ''),
        throwsAssertionError,
      );
    });

    testWidgets('the title is centered on the close button', (tester) async {
      await tester.pumpWidget(barHost(_header(title: 'Short')));

      expect(
        tester.getCenter(_title).dy,
        closeTo(tester.getCenter(_close).dy, 1),
      );
    });
  });

  group('targets', () {
    testWidgets('close is 44 drawn with a 48 hit area', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(barHost(_header()));

      // The button is padded to 48 for the hit area; the Material inside it
      // is the drawn shape.
      final drawn = tester.getSize(
        find.descendant(of: _close, matching: find.byType(Material)).first,
      );
      expect(drawn.width, greaterThanOrEqualTo(AppSizes.minDrawn));
      expect(drawn.height, greaterThanOrEqualTo(AppSizes.minDrawn));
      final hit = tester.getSemantics(_close).rect;
      expect(hit.width, greaterThanOrEqualTo(AppSizes.minTarget));
      expect(hit.height, greaterThanOrEqualTo(AppSizes.minTarget));
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      test('title and glyph 4.5:1, handle 3:1 on the sheet fill ($name)', () {
        final scheme = theme.colorScheme;
        final sheet = scheme.surfaceContainerLowest;
        expectContrast(
          {
            'title/sheet': (scheme.onSurface, sheet),
            'close glyph/sheet': (scheme.onSurfaceVariant, sheet),
          },
          minimum: 4.5,
          reason: name,
        );
        expectContrast(
          {'handle/sheet': (scheme.outline, sheet)},
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('right to left', () {
    testWidgets('the close button moves to the left and the handle stays '
        'centered', (tester) async {
      await tester.pumpWidget(barHost(_header()));
      expect(tester.getCenter(_close).dx, greaterThan(180));
      expect(tester.getRect(_title).left, lessThan(180));

      await tester.pumpWidget(barHost(_header(), direction: TextDirection.rtl));

      expect(tester.getCenter(_close).dx, lessThan(180));
      expect(tester.getRect(_title).right, greaterThan(180));
      expect(tester.getCenter(_handle).dx, closeTo(180, 0.5));
    });
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const long =
        '¿Pedirle a Carlos que libere la lavadora antes de la noche, '
        'cuando todos llegan a casa?';

    testWidgets('a long title wraps, the header grows and nothing clips', (
      tester,
    ) async {
      await tester.pumpWidget(barHost(_header(title: long)));
      final base = tester.getSize(find.byType(SheetHeader)).height;

      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          barHost(_header(title: long), textScale: 2, direction: direction),
        );

        expect(tester.takeException(), isNull, reason: '$direction');
        final header = tester.getRect(find.byType(SheetHeader));
        expect(header.height, greaterThan(base));
        final title = tester.getRect(_title);
        expect(header.contains(title.topLeft), isTrue);
        expect(header.contains(title.bottomRight), isTrue);
        expect(
          tester.renderObject<RenderParagraph>(_title).didExceedMaxLines,
          isFalse,
        );
        expect(
          tester.getRect(_close).overlaps(title),
          isFalse,
          reason: 'the close button never covers the title',
        );
        expect(
          tester.getRect(_close).top,
          lessThanOrEqualTo(title.top + AppSpacing.sm),
          reason: 'it stays at the top',
        );
      }
    });

    testWidgets('the title is never scaled down', (tester) async {
      await tester.pumpWidget(barHost(_header(title: 'Close')));
      final base = tester.getSize(_title).height;

      await tester.pumpWidget(
        barHost(_header(title: 'Close'), textScale: 2, width: 800),
      );

      expect(tester.getSize(_title).height, closeTo(base * 2, 1));
    });
  });
}

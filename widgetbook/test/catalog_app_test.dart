import 'package:compapp_design_widgetbook/src/catalog_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  testWidgets('the catalog app builds with its addons', (tester) async {
    await tester.pumpWidget(const CatalogApp());
    await tester.pump();

    expect(find.byType(Widgetbook), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

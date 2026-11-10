import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails when a word of the [Text] [finder] is wider than the text itself,
/// which is when a line has to break inside a word. The text is as wide as
/// its longest line, so every word fitting in it means no word was cut.
///
/// It measures with the text scale and style the text really has, so load the
/// bundled fonts first. [bold] measures every word at the semi-bold weight,
/// for a text that has a bold span.
void expectNoMidWordBreaks(
  WidgetTester tester,
  Finder finder, {
  bool bold = false,
  String reason = '',
}) {
  final element = tester.element(finder);
  final text = tester.widget<Text>(finder);
  final plain = text.data ?? text.textSpan!.toPlainText();
  var style = DefaultTextStyle.of(element).style.merge(text.style);
  if (bold) style = style.copyWith(fontWeight: FontWeight.w600);
  final scaler = MediaQuery.textScalerOf(element);
  final width = tester.getSize(finder).width;
  final cut = <String>[];
  for (final word in plain.split(RegExp(r'\s+'))) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: Directionality.of(element),
      textScaler: scaler,
    )..layout();
    if (painter.width > width + 0.5) cut.add(word);
    painter.dispose();
  }
  expect(cut, isEmpty, reason: 'words cut in "$plain" $reason');
}

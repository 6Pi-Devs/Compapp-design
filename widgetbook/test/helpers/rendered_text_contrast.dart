import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The least contrast ratio of rendered text (WCAG 1.4.3).
const textContrastMinimum = 4.5;

/// Below this opacity a text is judged as if it were fully opaque: it is
/// waiting to fade in (the hint of a field takes focus), and it must be
/// readable when it does.
const _invisible = 0.01;

/// How far outside a paragraph the background is sampled, in pixels.
const _sampleGap = 2.0;

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

String _hex(Color color) => color.toARGB32().toRadixString(16);

/// The color of one text run, or what is wrong with it.
typedef _Ink = ({Color? color, String? problem});

/// The text runs of [span], with the style of each run resolved over its
/// parents. A run is painted with `color` or with a `foreground` paint.
Iterable<_Ink> _inks(InlineSpan span, TextStyle? parent) sync* {
  final style = parent == null
      ? span.style
      : (span.style == null ? parent : parent.merge(span.style));
  if (span is TextSpan) {
    final text = span.text;
    if (text != null && text.trim().isNotEmpty) {
      final foreground = style?.foreground;
      if (foreground != null) {
        yield foreground.shader != null
            ? (color: null, problem: 'is painted with a shader')
            : (color: foreground.color, problem: null);
      } else if (style?.color != null) {
        yield (color: style!.color, problem: null);
      } else {
        yield (color: null, problem: 'has no text color');
      }
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _inks(child, style);
    }
  }
}

/// How much of the text shows through the opacity of its ancestors.
double _opacityAbove(RenderObject paragraph) {
  var opacity = 1.0;
  for (var node = paragraph.parent; node != null; node = node.parent) {
    if (node is RenderOpacity) opacity *= node.opacity;
    if (node is RenderAnimatedOpacity) opacity *= node.opacity.value;
  }
  return opacity;
}

/// What a render object paints behind its child: nothing, one color, or
/// something that is not one color.
sealed class _Fill {
  const new();
}

class _NoFill extends _Fill {
  const new();
}

class _Unknown extends _Fill {
  const new();
}

class _Solid extends _Fill {
  const new(this.color);

  final Color color;
}

_Fill _fillOf(RenderObject node) {
  if (node is RenderDecoratedBox &&
      node.position == DecorationPosition.background) {
    final decoration = node.decoration;
    if (decoration is BoxDecoration) {
      if (decoration.gradient != null || decoration.image != null) {
        return const _Unknown();
      }
      final color = decoration.color;
      return color == null ? const _NoFill() : _Solid(color);
    }
    if (decoration is ShapeDecoration) {
      if (decoration.gradient != null || decoration.image != null) {
        return const _Unknown();
      }
      final color = decoration.color;
      return color == null ? const _NoFill() : _Solid(color);
    }
    return const _Unknown();
  }
  if (node is RenderPhysicalModel) return _Solid(node.color);
  if (node is RenderPhysicalShape) return _Solid(node.color);
  if (node.runtimeType.toString() == '_RenderColoredBox') {
    return _Solid((node as dynamic).color as Color);
  }
  return const _NoFill();
}

/// The fill behind [paragraph], read from its render ancestors: the nearest
/// opaque color of a decorated box, a colored box or a material, with the
/// translucent ones above it blended in, or [page] when there is none. Null
/// when the nearest painting ancestor is a custom painter or something that
/// is not one color, which the tree cannot tell.
Color? _fillBehind(RenderObject paragraph, Color page) {
  final layers = <Color>[];
  Color? base;
  for (var node = paragraph.parent; node != null; node = node.parent) {
    if (node is RenderCustomPaint) return null;
    final fill = _fillOf(node);
    if (fill is _Unknown) return null;
    if (fill is _Solid) {
      if (fill.color.a >= 0.999) {
        base = fill.color;
        break;
      }
      layers.add(fill.color);
    }
  }
  var color = base ?? page;
  for (final layer in layers.reversed) {
    color = Color.alphaBlend(layer, color);
  }
  return color;
}

/// Every rendered text of the tree under [boundaryKey] whose resolved color
/// is below [minimum]:1 against what is painted behind it.
///
/// It reads the paragraphs of the render tree, not the semantics, so merged or
/// replaced labels cannot hide a text. The text color is the `color` or the
/// `foreground` paint of the run, with the opacity of its ancestors. The
/// background is the nearest opaque fill among the render ancestors (decorated
/// boxes, colored boxes, materials), or [page] when there is none. A fill can
/// also be painted by a sibling (a `Stack` over a colored box, the fill of a
/// text field drawn by a custom painter), which no ancestor says, so the
/// painted pixels just left and right of the paragraph, at mid height, are read
/// too, and the worst of the ancestor fill and of those samples decides.
///
/// Only when the nearest painting ancestor is a custom painter, whose fill the
/// tree cannot tell, the background is read from the pixels alone: the left
/// and the right sample, or the top, the bottom and the corners when neither
/// side is usable. A sample that lands on another text or outside the boundary
/// is not usable.
///
/// A text under a fully transparent ancestor is judged as if it were opaque:
/// it will be readable or not when it fades in. A text whose color or
/// background cannot be determined is reported, never skipped. [page] is also
/// blended under translucent pixels.
Future<List<String>> lowContrastTexts(
  WidgetTester tester,
  Key boundaryKey, {
  required Color page,
  double minimum = textContrastMinimum,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final origin = boundary.localToGlobal(Offset.zero);
  final size = boundary.size;

  final paragraphs = <RenderParagraph>[];
  for (final element in find.byType(RichText).evaluate()) {
    final render = element.renderObject;
    if (render is RenderParagraph &&
        render.attached &&
        !render.size.isEmpty &&
        render.text.toPlainText().trim().isNotEmpty) {
      paragraphs.add(render);
    }
  }

  final failures = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    Color? pixel(Offset point) {
      final px = point.dx.floor();
      final py = point.dy.floor();
      if (px < 0 || py < 0 || px >= image.width || py >= image.height) {
        return null;
      }
      final offset = (py * image.width + px) * 4;
      return Color.alphaBlend(
        Color.fromARGB(
          data.getUint8(offset + 3),
          data.getUint8(offset),
          data.getUint8(offset + 1),
          data.getUint8(offset + 2),
        ),
        page,
      );
    }

    final rects = [
      for (final paragraph in paragraphs)
        (paragraph.localToGlobal(Offset.zero) - origin) & paragraph.size,
    ];

    List<Color> usable(Rect rect, List<Offset> points) => [
      for (final point in points)
        if (!rects.any((other) => other != rect && other.contains(point)))
          ?pixel(point),
    ];

    List<Color> sideSamples(Rect rect) {
      final cy = rect.center.dy;
      return usable(rect, [
        Offset(rect.left - _sampleGap, cy),
        Offset(rect.right + _sampleGap, cy),
      ]);
    }

    List<Color> samplesAround(Rect rect) {
      final cx = rect.center.dx;
      final sides = sideSamples(rect);
      if (sides.isNotEmpty) return sides;
      return usable(rect, [
        Offset(cx, rect.top - _sampleGap),
        Offset(cx, rect.bottom + _sampleGap),
        Offset(rect.left - _sampleGap, rect.top - _sampleGap),
        Offset(rect.right + _sampleGap, rect.top - _sampleGap),
        Offset(rect.left - _sampleGap, rect.bottom + _sampleGap),
        Offset(rect.right + _sampleGap, rect.bottom + _sampleGap),
      ]);
    }

    final found = <String>[];
    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final rect = rects[i];
      if (rect.right <= 0 ||
          rect.bottom <= 0 ||
          rect.left >= size.width ||
          rect.top >= size.height) {
        continue;
      }
      final label = '"${paragraph.text.toPlainText()}"';
      var opacity = _opacityAbove(paragraph);
      if (opacity < _invisible) opacity = 1;

      final fill = _fillBehind(paragraph, page);
      final backgrounds = fill != null
          ? [fill, ...sideSamples(rect)]
          : samplesAround(rect);
      if (backgrounds.isEmpty) {
        found.add(
          '$label has no fill in the render tree and no usable pixel sample '
          'around it: its background cannot be determined',
        );
        continue;
      }

      for (final ink in _inks(paragraph.text, null)) {
        final color = ink.color;
        if (color == null) {
          found.add('$label ${ink.problem}: its color cannot be determined');
          continue;
        }
        final shown = color.withValues(alpha: color.a * opacity);
        // The worse of the backgrounds around the text decides.
        var worst = double.infinity;
        var worstIndex = 0;
        for (var b = 0; b < backgrounds.length; b++) {
          final ratio = _ratio(
            Color.alphaBlend(shown, backgrounds[b]),
            backgrounds[b],
          );
          if (ratio < worst) {
            worst = ratio;
            worstIndex = b;
          }
        }
        if (worst < minimum) {
          found.add(
            '$label ${worst.toStringAsFixed(2)}:1 '
            '(text ${_hex(shown)} on ${_hex(backgrounds[worstIndex])}, '
            '${fill != null && worstIndex == 0 ? 'fill' : 'pixels'})',
          );
        }
      }
    }
    image.dispose();
    return found;
  });
  return failures!;
}

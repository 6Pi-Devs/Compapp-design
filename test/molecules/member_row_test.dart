import 'dart:math';

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';
import '../helpers/word_breaks.dart';

MemberView _member({
  String id = 'ana',
  String name = 'Ana (you)',
  String initials = 'A',
  int joinOrder = 0,
  String label = 'Ana, you, at home',
  MemberStatus status = MemberStatus.home,
  bool isYou = false,
  bool isAdmin = false,
}) => MemberView(
  id: id,
  name: name,
  initials: initials,
  joinOrder: joinOrder,
  semanticLabel: label,
  status: status,
  isYou: isYou,
  isAdmin: isAdmin,
);

MemberRow _row({
  MemberView? member,
  String? subtitle = 'In Bedroom 1',
  String? trailing = 'since 3 h',
}) => MemberRow(
  member: member ?? _member(),
  subtitle: subtitle,
  trailing: trailing,
);

Finder _key(String id) => find.byKey(Key('member.$id'));
Finder get _pebble => find.byType(AppPebble);
Finder get _dot => find.byType(AppStatusDot);

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('shows the name, the subtitle and the trailing text', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row()));

      expect(find.text('Ana (you)'), findsOneWidget);
      expect(find.text('In Bedroom 1'), findsOneWidget);
      expect(find.text('since 3 h'), findsOneWidget);
    });

    testWidgets('leaves out a missing or empty subtitle and trailing', (
      tester,
    ) async {
      for (final (subtitle, trailing) in [(null, null), ('', ''), (null, '')]) {
        await tester.pumpWidget(
          host(_row(subtitle: subtitle, trailing: trailing)),
        );

        expect(
          find.byType(Text),
          findsNWidgets(2),
          reason: 'the initials and the name, nothing else ($subtitle)',
        );
        expect(_dot, findsNothing, reason: 'a dot never stands alone');
      }
    });

    testWidgets('is at least 64 tall and fills the width it is given', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row(subtitle: null, trailing: null)));
      expect(tester.getSize(_key('ana')), const Size(hostWidth, AppSizes.row));

      await tester.pumpWidget(host(_row(), width: 200));
      expect(tester.getSize(_key('ana')).width, 200);
    });

    testWidgets('the trailing text takes its own width and hugs the end edge', (
      tester,
    ) async {
      await tester.pumpWidget(host(_row(trailing: 'Now')));
      final row = tester.getRect(_key('ana'));
      final trailing = tester.getRect(find.text('Now'));

      expect(trailing.right, closeTo(row.right, 0.01));
      expect(
        trailing.width,
        lessThan(hostWidth / 3 - AppSpacing.sm - AppSizes.dot - AppSpacing.sm),
        reason: 'a short text is not stretched to a third of the row',
      );
      expect(
        tester.getRect(find.text('In Bedroom 1')).right,
        lessThan(trailing.left),
      );
    });

    testWidgets('the name takes the whole row when there is no trailing text', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _row(
            member: _member(name: 'A name as long as a whole line of text'),
            trailing: null,
          ),
        ),
      );

      expect(
        tester
            .getRect(find.text('A name as long as a whole line of text'))
            .right,
        greaterThan(hostWidth * 2 / 3),
      );
    });

    testWidgets('the key is built from the account id, not the position', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _row(
                member: _member(id: 'luis', label: 'Luis'),
              ),
              _row(),
            ],
          ),
        ),
      );

      expect(_key('luis'), findsOneWidget);
      expect(_key('ana'), findsOneWidget);
      expect(
        tester.getTopLeft(_key('luis')).dy,
        lessThan(tester.getTopLeft(_key('ana')).dy),
      );
    });
  });

  group('pebble', () {
    testWidgets('draws the member: initials, color order, you and admin', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _row(
            member: _member(
              initials: 'LM',
              joinOrder: 7,
              label: 'Luis Mora, you, admin',
              isYou: true,
              isAdmin: true,
            ),
          ),
        ),
      );

      final pebble = tester.widget<AppPebble>(_pebble);
      expect(pebble.initials, 'LM');
      expect(pebble.joinOrder, 7);
      expect(pebble.isYou, isTrue);
      expect(pebble.isAdmin, isTrue);
      expect(pebble.size, AppPebbleSize.s44);
      expect(
        find.byKey(const Key('pebble.badge.admin')),
        findsOneWidget,
        reason: 'the key badge is drawn on a 44 pebble',
      );
      expect(tester.getSize(_pebble), const Size.square(44));
    });

    testWidgets('a member that is home draws the plain pebble', (tester) async {
      await tester.pumpWidget(host(_row()));

      expect(tester.widget<AppPebble>(_pebble).status, AppPebbleStatus.home);
      expect(find.byKey(const Key('pebble.badge.away')), findsNothing);
      expect(find.byKey(const Key('pebble.badge.admin')), findsNothing);
    });

    testWidgets('away draws the moon badge and invited the dashed outline', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _row(
            member: _member(status: MemberStatus.away, label: 'Luis'),
          ),
        ),
      );
      expect(tester.widget<AppPebble>(_pebble).status, AppPebbleStatus.away);
      expect(find.byKey(const Key('pebble.badge.away')), findsOneWidget);

      await tester.pumpWidget(
        host(
          _row(
            member: _member(status: MemberStatus.invited, label: 'Marta'),
          ),
        ),
      );
      expect(tester.widget<AppPebble>(_pebble).status, AppPebbleStatus.invited);
      expect(find.byKey(const Key('pebble.badge.away')), findsNothing);
    });
  });

  group('status dot', () {
    testWidgets('follows the status and sits before the trailing text', (
      tester,
    ) async {
      for (final (status, dot) in [
        (MemberStatus.home, AppDotStatus.home),
        (MemberStatus.away, AppDotStatus.away),
      ]) {
        await tester.pumpWidget(
          host(
            _row(
              member: _member(status: status, label: 'Ana'),
            ),
          ),
        );

        expect(tester.widget<AppStatusDot>(_dot).status, dot);
        expect(
          tester.getTopRight(_dot).dx,
          lessThan(tester.getTopLeft(find.text('since 3 h')).dx),
          reason: 'the dot comes first in the reading order',
        );
        final text = tester.getRect(find.text('since 3 h'));
        expect(
          tester.getCenter(_dot).dy,
          inInclusiveRange(text.top, text.bottom),
          reason: 'and is level with the text',
        );
      }
    });

    testWidgets('an invited member has no dot, only the text', (tester) async {
      await tester.pumpWidget(
        host(
          _row(
            member: _member(status: MemberStatus.invited, label: 'Marta'),
          ),
        ),
      );

      expect(_dot, findsNothing);
      expect(find.text('since 3 h'), findsOneWidget);
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      testWidgets('name is ink, subtitle muted, trailing ink ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            _row(
              member: _member(name: 'Carlos', initials: 'C', label: 'Carlos'),
              subtitle: 'Kitchen',
              trailing: 'Soon',
            ),
            theme: theme,
            background: scheme.surface,
          ),
        );

        for (final (text, color) in [
          ('Carlos', scheme.onSurface),
          ('Kitchen', scheme.onSurfaceVariant),
          ('Soon', scheme.onSurface),
        ]) {
          expect(
            await paintedColorAtCenter(
              tester,
              hostBoundaryKey,
              find.text(text),
            ),
            isSameColorAs(color),
            reason: '$text on $name',
          );
        }
      });
    }

    testWidgets(
      'uses the label, caption and caption styles of the type scale',
      (tester) async {
        await tester.pumpWidget(host(_row()));

        TextStyle style(String text) =>
            tester.widget<Text>(find.text(text)).style!;
        expect(style('Ana (you)').fontSize, AppTypography.labelLg.fontSize);
        expect(style('Ana (you)').fontWeight, FontWeight.w600);
        expect(style('In Bedroom 1').fontSize, AppTypography.caption.fontSize);
        expect(style('since 3 h').fontSize, AppTypography.caption.fontSize);
      },
    );
  });

  group('right to left', () {
    testWidgets(
      'the pebble is at the right and the trailing text at the left',
      (tester) async {
        await tester.pumpWidget(host(_row(), direction: TextDirection.rtl));
        final row = tester.getRect(_key('ana'));

        expect(tester.getRect(_pebble).right, closeTo(row.right, 4));
        expect(
          tester.getRect(find.text('Ana (you)')).right,
          lessThan(tester.getRect(_pebble).left),
          reason: 'the name follows the pebble toward the left',
        );
        expect(
          tester.getRect(find.text('since 3 h')).left,
          lessThan(row.center.dx),
        );
        expect(
          tester.getRect(_dot).left,
          greaterThan(tester.getRect(find.text('since 3 h')).right),
          reason: 'the dot is still before its text in reading order',
        );
      },
    );

    testWidgets('keeps the badge on the trailing edge of the pebble', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _row(
            member: _member(status: MemberStatus.away, label: 'Luis'),
          ),
          direction: TextDirection.rtl,
        ),
      );

      expect(
        tester.getCenter(find.byKey(const Key('pebble.badge.away'))).dx,
        lessThan(tester.getCenter(_pebble).dx),
      );
    });
  });

  group('semantics', () {
    testWidgets('is one node: the spoken label, the subtitle, the trailing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_row()));

      final data = tester
          .getSemantics(find.text('In Bedroom 1'))
          .getSemanticsData();
      expect(data.label, 'Ana, you, at home\nIn Bedroom 1\nsince 3 h');
      expect(semanticsLabels(tester), [
        data.label,
      ], reason: 'one labeled node, nothing said twice');
      expect(data.flagsCollection.isImage, isFalse);
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('the visible name is not said again after the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_row()));

      final label = tester
          .getSemantics(find.text('In Bedroom 1'))
          .getSemanticsData()
          .label;
      expect('Ana'.allMatches(label).length, 1);
      expect(label, isNot(contains('Ana (you)')));
      handle.dispose();
    });

    testWidgets('without subtitle and trailing it reads only the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_row(subtitle: null, trailing: null)));

      expect(semanticsLabels(tester), ['Ana, you, at home']);
      handle.dispose();
    });

    testWidgets('the status dot adds nothing to the label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          _row(
            member: _member(status: MemberStatus.away, label: 'Luis, away'),
          ),
        ),
      );

      expect(
        semanticsLabels(tester).single,
        'Luis, away\nIn Bedroom 1\nsince 3 h',
      );
      handle.dispose();
    });

    testWidgets('needs a spoken label', (tester) async {
      expect(() => _member(label: ''), throwsAssertionError);
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;
      final backgrounds = {
        'page': scheme.surface,
        'card': scheme.surfaceContainerLowest,
      };

      test('text reaches 4.5:1 on the page and on a card ($name)', () {
        expectContrast(
          {
            for (final background in backgrounds.entries) ...{
              'name/${background.key}': (scheme.onSurface, background.value),
              'subtitle/${background.key}': (
                scheme.onSurfaceVariant,
                background.value,
              ),
              'trailing/${background.key}': (
                scheme.onSurface,
                background.value,
              ),
            },
          },
          minimum: 4.5,
          reason: name,
        );
      });

      test('the status dot reaches 3:1 on the page and on a card ($name)', () {
        expectContrast(
          {
            for (final background in backgrounds.entries) ...{
              'home/${background.key}': (scheme.primary, background.value),
              'away/${background.key}': (colors.presenceAway, background.value),
            },
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(loadBundledFonts);

    const longName = 'María de los Ángeles Fernández-Villalobos (tú)';
    const longSubtitle = 'Ausencia registrada en el calendario compartido';
    const longTrailing = 'hasta el viernes por la noche';

    MemberRow longRow() => _row(
      member: _member(
        name: longName,
        initials: 'MA',
        status: MemberStatus.away,
        isAdmin: true,
        label: 'María de los Ángeles, tú, administradora, fuera de casa',
      ),
      subtitle: longSubtitle,
      trailing: longTrailing,
    );

    testWidgets('wraps and grows at 1.5 and 2.0, nothing clips or overflows', (
      tester,
    ) async {
      await tester.pumpWidget(host(longRow()));
      final baseName = tester.getSize(find.text(longName));
      final baseSubtitle = tester.getSize(find.text(longSubtitle));

      for (final scale in [1.5, 2.0]) {
        await tester.pumpWidget(host(longRow(), textScale: scale));
        final reason = 'at ${scale}x';
        final row = tester.getRect(_key('ana'));
        final name = tester.getRect(find.text(longName));
        final subtitle = tester.getRect(find.text(longSubtitle));
        final trailing = tester.getRect(find.text(longTrailing));
        final pebble = tester.getRect(_pebble);

        expect(tester.takeException(), isNull, reason: reason);
        expect(row.height, greaterThanOrEqualTo(AppSizes.row), reason: reason);
        expect(
          name.height,
          greaterThanOrEqualTo(baseName.height * scale - 1),
          reason: '$reason: the text is scaled, never clamped',
        );
        expect(
          subtitle.height,
          greaterThanOrEqualTo(baseSubtitle.height * scale - 1),
          reason: reason,
        );
        for (final (label, box) in [
          ('name', name),
          ('subtitle', subtitle),
          ('trailing', trailing),
          ('pebble', pebble),
        ]) {
          expect(
            box.left,
            greaterThanOrEqualTo(row.left - 0.01),
            reason: '$reason: $label inside the row, left',
          );
          expect(
            box.right,
            lessThanOrEqualTo(row.right + 0.01),
            reason: '$reason: $label inside the row, right',
          );
          expect(
            box.top,
            greaterThanOrEqualTo(row.top - 0.01),
            reason: '$reason: $label inside the row, top',
          );
          expect(
            box.bottom,
            lessThanOrEqualTo(row.bottom + 0.01),
            reason: '$reason: $label inside the row, bottom',
          );
        }
        expect(name.left, greaterThanOrEqualTo(pebble.right), reason: reason);
        final beside = name.right <= trailing.left;
        final under = trailing.top >= subtitle.bottom - 0.01;
        expect(
          beside || under,
          isTrue,
          reason: '$reason: the trailing text is beside the texts or under',
        );
        if (beside) {
          expect(
            trailing.width,
            lessThanOrEqualTo(hostWidth / 3 + 0.01),
            reason: '$reason: beside, the trailing text wraps within a third',
          );
        }
        expect(
          name.height,
          greaterThan(baseName.height * scale),
          reason: '$reason: the long name really wrapped',
        );
      }
    });

    testWidgets('the pebble grows with the text and the row follows', (
      tester,
    ) async {
      await tester.pumpWidget(host(longRow(), textScale: 2));

      expect(
        tester.getRect(_key('ana')).height,
        greaterThanOrEqualTo(
          tester.getSize(_pebble).height + 2 * AppSpacing.sm,
        ),
      );
    });

    testWidgets('right to left wraps the same way', (tester) async {
      await tester.pumpWidget(
        host(longRow(), textScale: 2, direction: TextDirection.rtl),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text(longName)).right,
        lessThanOrEqualTo(tester.getRect(_pebble).left),
      );
    });
  });

  group('names stay whole', () {
    setUpAll(loadBundledFonts);

    const cases = [
      ('María Fernández', 'Habitación compartida', 'desde hace 3 h'),
      ('Guillermo Castellanos', 'Calendario compartido', 'hasta el viernes'),
      ('Cristina Fernández', 'Responsable de limpieza', 'en casa'),
      ('María de los Ángeles', 'Ausencia programada', 'vuelve mañana'),
    ];
    const scales = [1.0, 1.3, 1.5, 2.0];

    Finder rowLayout() => find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_MemberRowLayout',
    );

    for (final direction in TextDirection.values) {
      for (final width in [320.0, 360.0]) {
        testWidgets(
          'no word is cut at ${width.toInt()} wide, ${direction.name}',
          (tester) async {
            final handle = tester.ensureSemantics();
            for (final (name, subtitle, trailing) in cases) {
              for (final scale in scales) {
                await tester.pumpWidget(
                  host(
                    _row(
                      member: _member(
                        name: name,
                        initials: 'MF',
                        label: '$name, at home',
                      ),
                      subtitle: subtitle,
                      trailing: trailing,
                    ),
                    width: width,
                    textScale: scale,
                    direction: direction,
                  ),
                );
                final reason = '($name, $subtitle, $trailing at ${scale}x)';
                final row = tester.getRect(_key('ana'));

                expect(tester.takeException(), isNull, reason: reason);
                expectNoMidWordBreaks(
                  tester,
                  find.text(name),
                  bold: true,
                  reason: reason,
                );
                expectNoMidWordBreaks(
                  tester,
                  find.text(subtitle),
                  reason: reason,
                );
                expectNoMidWordBreaks(
                  tester,
                  find.text(trailing),
                  reason: reason,
                );
                for (final text in [name, subtitle, trailing]) {
                  final box = tester.getRect(find.text(text));
                  expect(box.left, greaterThanOrEqualTo(row.left - 0.01));
                  expect(box.right, lessThanOrEqualTo(row.right + 0.01));
                  expect(box.top, greaterThanOrEqualTo(row.top - 0.01));
                  expect(box.bottom, lessThanOrEqualTo(row.bottom + 0.01));
                }
                expect(_dot, findsOneWidget, reason: reason);
                expect(
                  semanticsLabels(tester).single,
                  '$name, at home\n$subtitle\n$trailing',
                  reason: 'the trailing text is still read $reason',
                );
              }
            }
            handle.dispose();
          },
        );
      }
    }

    testWidgets(
      'the dot is centered on its text, on its first line if stacked',
      (tester) async {
        const long = 'hasta el viernes por la noche';
        Future<void> pump(String name, String trailing, double scale) =>
            tester.pumpWidget(
              host(
                _row(
                  member: _member(name: name, label: name),
                  trailing: trailing,
                ),
                textScale: scale,
              ),
            );

        // Beside the texts the dot is centered on the whole text, as it always
        // was, so a text on two lines keeps its dot in the middle.
        await pump('Ana', 'since 3 h', 1);
        expect(
          tester.getCenter(_dot).dy,
          closeTo(tester.getCenter(find.text('since 3 h')).dy, 0.5),
        );
        await pump('Ana', long, 2);
        var text = tester.getRect(find.text(long));
        expect(text.height, greaterThan(16 * 2 * 1.5), reason: 'two lines');
        expect(tester.getCenter(_dot).dy, closeTo(text.center.dy, 0.5));

        // Stacked, it sits on the middle of the first line, like the unread dot
        // of an activity row.
        for (final trailing in ['since 3 h', long]) {
          await pump('Guillermo Castellanos', trailing, 2);
          text = tester.getRect(find.text(trailing));
          expect(
            tester.getRect(_dot).left,
            lessThan(tester.getRect(find.text('Guillermo Castellanos')).right),
            reason: 'stacked',
          );
          expect(
            tester.getCenter(_dot).dy,
            closeTo(text.top + 16, 0.5),
            reason: '"$trailing" at 2.0x',
          );
        }
      },
    );

    testWidgets('at 1.0 the trailing text stays beside the texts', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _row(
            member: _member(name: 'Guillermo Castellanos', label: 'Guillermo'),
            subtitle: 'Calendario compartido',
            trailing: 'hasta el viernes',
          ),
        ),
      );

      expect(
        tester.getRect(find.text('Guillermo Castellanos')).right,
        lessThanOrEqualTo(tester.getRect(find.text('hasta el viernes')).left),
      );
    });

    testWidgets('at 2.0 the trailing text goes under the texts', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            _row(
              member: _member(
                name: 'Guillermo Castellanos',
                label: 'Guillermo',
              ),
              subtitle: 'Calendario compartido',
              trailing: 'hasta el viernes',
            ),
            textScale: 2,
            direction: direction,
          ),
        );
        final ltr = direction == TextDirection.ltr;
        final name = tester.getRect(find.text('Guillermo Castellanos'));
        final subtitle = tester.getRect(find.text('Calendario compartido'));
        final trailing = tester.getRect(find.text('hasta el viernes'));
        final dot = tester.getRect(_dot);

        expect(
          trailing.top,
          greaterThanOrEqualTo(
            max(tester.getRect(_pebble).bottom, subtitle.bottom) +
                AppSpacing.xs -
                0.01,
          ),
          reason: 'under the texts and the pebble, with a small gap',
        );
        expect(
          trailing.bottom,
          lessThanOrEqualTo(tester.getRect(rowLayout()).bottom + 0.01),
          reason: 'the layout is as tall as what it holds, the gap included',
        );
        expect(
          ltr ? dot.left : dot.right,
          closeTo(ltr ? name.left : name.right, 0.01),
          reason: 'the dot lines up with the texts, at their start',
        );
        expect(
          ltr ? trailing.left : trailing.right,
          closeTo(
            ltr ? dot.right + AppSpacing.sm : dot.left - AppSpacing.sm,
            0.01,
          ),
          reason: 'the trailing text follows its dot, a small gap away',
        );
        expect(
          dot.center.dy,
          closeTo(trailing.center.dy, 1),
          reason: 'and is centered on its text',
        );
      }
    });

    testWidgets(
      'a word wider than the whole row wraps by letters, all visible',
      (tester) async {
        const name = 'Wickramasinghe';
        await tester.pumpWidget(
          host(
            _row(
              member: _member(name: name, label: '$name, at home'),
              subtitle: 'Kitchen',
              trailing: 'Now',
            ),
            width: 296,
            textScale: 2,
          ),
        );

        final row = tester.getRect(_key('ana'));
        final finder = find.text(name);
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        final box = tester.getRect(finder);
        expect(tester.takeException(), isNull);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.widget<Text>(finder).overflow, isNull);
        expect(box.left, greaterThanOrEqualTo(row.left - 0.01));
        expect(box.right, lessThanOrEqualTo(row.right + 0.01));
        expect(
          paragraph
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: name.length),
              )
              .length,
          greaterThan(1),
          reason: 'the word is on more than one line',
        );
        for (var i = 0; i < name.length; i++) {
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: i, extentOffset: i + 1),
          );
          expect(boxes, hasLength(1), reason: 'letter $i is painted');
          expect(boxes.single.left, greaterThanOrEqualTo(-0.01));
          expect(
            boxes.single.right,
            lessThanOrEqualTo(paragraph.size.width + 0.01),
            reason: 'letter $i is inside its box',
          );
        }
      },
    );

    group('where it stacks', () {
      double wordWidth(String word, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        final width = painter.width;
        painter.dispose();
        return width;
      }

      RenderBox layoutBox(WidgetTester tester) =>
          tester.renderObject<RenderBox>(
            find.byWidgetPredicate(
              (widget) => widget.runtimeType.toString() == '_MemberRowLayout',
            ),
          );

      Future<bool> stackedIn(
        WidgetTester tester, {
        required double width,
        required String name,
        required String subtitle,
        required String trailing,
      }) async {
        await tester.pumpWidget(
          host(
            _row(
              member: _member(name: name, label: name),
              subtitle: subtitle,
              trailing: trailing,
            ),
            width: width,
          ),
        );
        expect(tester.takeException(), isNull);
        // Beside, the dot is after the texts. Stacked, it is under them, at
        // their start.
        return tester.getRect(_dot).left <
            tester.getRect(find.text(name)).right;
      }

      testWidgets('when the longest word of the texts stops fitting beside', (
        tester,
      ) async {
        final word = wordWidth('Castellanos', AppTypography.labelLg);
        // The texts have two thirds of the row, less the pebble and its gap.
        double rowFor(double room) =>
            (room + AppSizes.pebbleMd + AppSpacing.md) * 3 / 2;

        for (final (delta, stacked) in [(0.5, false), (-0.5, true)]) {
          expect(
            await stackedIn(
              tester,
              width: rowFor(word + delta),
              name: 'Guillermo Castellanos',
              subtitle: 'En casa',
              trailing: 'en casa',
            ),
            stacked,
            reason: 'with ${delta.abs()} more or less than the word needs',
          );
        }
      });

      testWidgets('when the longest trailing word stops fitting its third', (
        tester,
      ) async {
        final word = wordWidth('compartido', AppTypography.caption);
        // The trailing text has a third of the row, less the gap to the texts,
        // and holds the dot, its gap and the word.
        double rowFor(double room) =>
            (AppSpacing.sm + AppSizes.dot + AppSpacing.sm + room) * 3;

        for (final (delta, stacked) in [(0.5, false), (-0.5, true)]) {
          expect(
            await stackedIn(
              tester,
              width: rowFor(word + delta),
              name: 'Ana Gil',
              subtitle: 'Cocina',
              trailing: 'compartido',
            ),
            stacked,
            reason: 'with ${delta.abs()} more or less than the word needs',
          );
        }
      });

      testWidgets('and the narrowest width keeps every word whole', (
        tester,
      ) async {
        for (final (name, subtitle, trailing) in [
          ('Guillermo Castellanos', 'En casa', 'en casa'),
          ('Ana Gil', 'Cocina', 'compartido'),
        ]) {
          Future<void> pumpAt(double width) => tester.pumpWidget(
            host(
              _row(
                member: _member(name: name, label: name),
                subtitle: subtitle,
                trailing: trailing,
              ),
              width: width,
            ),
          );
          void expectWhole() {
            for (final text in [name, subtitle, trailing]) {
              expectNoMidWordBreaks(tester, find.text(text));
            }
          }

          await pumpAt(320);
          final narrowest = layoutBox(tester)
              .getMinIntrinsicWidth(double.infinity);

          await pumpAt(narrowest);
          expectWhole();
          await pumpAt(narrowest - 1);
          expect(
            expectWhole,
            throwsA(isA<TestFailure>()),
            reason: 'a word is cut one pixel below the narrowest ($name)',
          );
        }
      });

      testWidgets('and the widest width is the content on one line', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            _row(
              member: _member(name: 'Guillermo Castellanos', label: 'G'),
              subtitle: 'En casa',
              trailing: 'hasta el viernes',
            ),
          ),
        );
        final trailing =
            AppSizes.dot +
            AppSpacing.sm +
            wordWidth('hasta el viernes', AppTypography.caption);
        final expected =
            AppSizes.pebbleMd +
            AppSpacing.md +
            max(
              wordWidth('Guillermo Castellanos', AppTypography.labelLg),
              wordWidth('En casa', AppTypography.caption),
            ) +
            AppSpacing.sm +
            trailing;

        expect(
          layoutBox(tester).getMaxIntrinsicWidth(double.infinity),
          closeTo(expected, 1),
        );
      });
    });

    testWidgets('a hyphenated name breaks at its hyphen, never inside a part', (
      tester,
    ) async {
      const name = "Siobhan O'Neill-García";
      for (final direction in TextDirection.values) {
        for (final scale in scales) {
          await tester.pumpWidget(
            host(
              _row(
                member: _member(name: name, label: name),
                subtitle: 'Calendario compartido',
                trailing: 'hasta el viernes',
              ),
              textScale: scale,
              direction: direction,
            ),
          );
          final finder = find.text(name);
          final element = tester.element(finder);
          final style = DefaultTextStyle.of(element).style
              .merge(tester.widget<Text>(finder).style);
          final width = tester.getSize(finder).width;
          for (final part in name.split(RegExp(r'(?<=-)|\s+'))) {
            final painter = TextPainter(
              text: TextSpan(text: part, style: style),
              textDirection: direction,
              textScaler: TextScaler.linear(scale),
            )..layout();
            expect(
              painter.width,
              lessThanOrEqualTo(width + 0.5),
              reason: '"$part" is cut at ${scale}x, $direction',
            );
            painter.dispose();
          }
        }
      }
    });

    testWidgets('every part of the row takes a tap', (tester) async {
      for (final scale in [1.0, 2.0]) {
        for (final direction in TextDirection.values) {
          var taps = 0;
          await tester.pumpWidget(
            host(
              GestureDetector(
                onTap: () => taps++,
                child: _row(
                  member: _member(name: 'Guillermo Castellanos', label: 'G'),
                  subtitle: 'Calendario compartido',
                  trailing: 'hasta el viernes',
                ),
              ),
              textScale: scale,
              direction: direction,
            ),
          );

          for (final text in [
            'A',
            'Guillermo Castellanos',
            'Calendario compartido',
            'hasta el viernes',
          ]) {
            await tester.tap(find.text(text));
          }
          expect(taps, 4, reason: 'at ${scale}x, $direction');
        }
      }
    });

    group('baseline', () {
      const refKey = Key('ref');

      Widget besideText(double scale) => host(
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('Ref', key: refKey, style: TextStyle(fontSize: 40)),
            Expanded(
              child: _row(
                member: _member(name: 'Ana', label: 'Ana'),
                subtitle: 'Cocina',
                trailing: 'ahora',
              ),
            ),
          ],
        ),
        textScale: scale,
      );

      double baselineOf(WidgetTester tester, Finder finder) {
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        return tester.getTopLeft(finder).dy +
            paragraph.getDryBaseline(
              paragraph.constraints,
              TextBaseline.alphabetic,
            )!;
      }

      testWidgets('the name lines up with the text beside the row', (
        tester,
      ) async {
        // On main the name, not the pebble, set the baseline of the row, so a
        // neighbor in a baseline Row lined up with it.
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(besideText(scale));

          expect(
            baselineOf(tester, find.text('Ana')),
            closeTo(baselineOf(tester, find.byKey(refKey)), 0.01),
            reason: 'at ${scale}x',
          );
        }
      });

      testWidgets('dry baseline is the real baseline', (tester) async {
        for (final scale in scales) {
          for (final width in [200.0, 320.0, 360.0]) {
            await tester.pumpWidget(
              host(
                _row(
                  member: _member(name: 'Guillermo Castellanos', label: 'G'),
                  subtitle: 'Calendario compartido',
                  trailing: 'hasta el viernes',
                ),
                width: width,
                textScale: scale,
              ),
            );
            final box = tester.renderObject<RenderBox>(rowLayout());
            final name = tester.renderObject<RenderParagraph>(
              find.text('Guillermo Castellanos'),
            );
            final real =
                tester.getTopLeft(find.text('Guillermo Castellanos')).dy -
                tester.getTopLeft(rowLayout()).dy +
                name.getDryBaseline(name.constraints, TextBaseline.alphabetic)!;

            expect(
              box.getDryBaseline(box.constraints, TextBaseline.alphabetic),
              closeTo(real, 0.01),
              reason: 'at ${scale}x in $width',
            );
          }
        }
      });
    });

    testWidgets('in a parent without a bounded width it is one line wide', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _row(
              member: _member(name: 'Guillermo Castellanos', label: 'G'),
              subtitle: 'Calendario compartido',
              trailing: 'hasta el viernes',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('Guillermo Castellanos')).right,
        lessThanOrEqualTo(tester.getRect(_dot).left),
      );
    });

    testWidgets('dry layout and intrinsics agree with the real layout', (
      tester,
    ) async {
      for (final scale in scales) {
        for (final width in [200.0, 320.0, 360.0]) {
          await tester.pumpWidget(
            host(
              _row(
                member: _member(name: 'Guillermo Castellanos', label: 'G'),
                subtitle: 'Calendario compartido',
                trailing: 'hasta el viernes',
              ),
              width: width,
              textScale: scale,
            ),
          );
          final box = tester.renderObject<RenderBox>(rowLayout());
          final reason = 'at ${scale}x in $width';

          expect(box.getDryLayout(box.constraints), box.size, reason: reason);
          final content = box
              .getDryLayout(BoxConstraints(maxWidth: width))
              .height;
          expect(box.getMinIntrinsicHeight(width), content, reason: reason);
          expect(box.getMaxIntrinsicHeight(width), content, reason: reason);
          expect(
            box.size.height,
            max(content, AppSizes.row - 2 * AppSpacing.sm),
            reason: '$reason: the real layout is the content, at least 48',
          );
          expect(
            box.getMinIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(box.getMaxIntrinsicWidth(double.infinity)),
            reason: reason,
          );
        }
      }
    });

    testWidgets('measures inside IntrinsicHeight and IntrinsicWidth', (
      tester,
    ) async {
      for (final scale in scales) {
        await tester.pumpWidget(
          host(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: _row())],
              ),
            ),
            textScale: scale,
          ),
        );
        expect(tester.takeException(), isNull, reason: 'at ${scale}x');
        expect(
          tester.getSize(_key('ana')).height,
          greaterThanOrEqualTo(AppSizes.row),
        );

        await tester.pumpWidget(
          host(
            Align(child: IntrinsicWidth(child: _row())),
            textScale: scale,
          ),
        );
        expect(tester.takeException(), isNull, reason: 'at ${scale}x');
        expect(tester.getSize(_key('ana')).width, lessThanOrEqualTo(hostWidth));
      }
    });
  });
}

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_color.dart';

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
        expect(
          tester.getCenter(_dot).dy,
          closeTo(tester.getCenter(find.text('since 3 h')).dy, 1),
          reason: 'and is centered on the text',
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
        expect(
          name.right,
          lessThanOrEqualTo(trailing.left),
          reason: '$reason: the name never runs under the trailing text',
        );
        expect(
          trailing.width,
          lessThanOrEqualTo(hostWidth / 3 + 0.01),
          reason: '$reason: the trailing text wraps within a third',
        );
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
}

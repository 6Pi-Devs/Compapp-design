import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per size and state. The states are the ones of the Atoms
/// board: plain (home), away (moon badge), invited (dashed outline), you
/// (inset dark ring) and admin (key badge).
///
/// Badges render only from s44 up. The s28 and s36 away and admin use cases
/// render the plain pebble on purpose: their goldens document that rule.
WidgetbookComponent buildAppPebble() {
  return WidgetbookComponent(
    name: 'AppPebble',
    useCases: [
      for (final size in AppPebbleSize.values)
        for (final state in _PebbleState.values)
          WidgetbookUseCase(
            name: '${size.name}-${state.name}',
            builder: (context) => useCaseFrame(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _pebble(context, size, state),
              ),
            ),
          ),
    ],
  );
}

enum _PebbleState { home, away, invited, you, admin }

Widget _pebble(BuildContext context, AppPebbleSize size, _PebbleState state) {
  final ana = context.sample(en: 'Ana', es: 'Ana');
  return switch (state) {
    _PebbleState.home => AppPebble(
      key: const Key('pebble.ana'),
      initials: 'A',
      joinOrder: 0,
      size: size,
      semanticLabel: ana,
    ),
    _PebbleState.away => AppPebble(
      key: const Key('pebble.luis'),
      initials: 'L',
      joinOrder: 2,
      size: size,
      status: AppPebbleStatus.away,
      semanticLabel: context.sample(en: 'Luis, away', es: 'Luis, ausente'),
    ),
    _PebbleState.invited => AppPebble(
      key: const Key('pebble.marta'),
      initials: 'M',
      joinOrder: 3,
      size: size,
      status: AppPebbleStatus.invited,
      semanticLabel: context.sample(
        en: 'Marta, invited',
        es: 'Marta, invitada',
      ),
    ),
    _PebbleState.you => AppPebble(
      key: const Key('pebble.ana'),
      initials: 'A',
      joinOrder: 0,
      size: size,
      isYou: true,
      semanticLabel: context.sample(en: 'Ana, you', es: 'Ana, tú'),
    ),
    _PebbleState.admin => AppPebble(
      key: const Key('pebble.ana'),
      initials: 'A',
      joinOrder: 0,
      size: size,
      isAdmin: true,
      semanticLabel: context.sample(
        en: 'Ana, admin',
        es: 'Ana, administradora',
      ),
    ),
  };
}

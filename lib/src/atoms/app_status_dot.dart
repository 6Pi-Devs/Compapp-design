import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:flutter/material.dart';

/// What a dot reports. [away] is drawn as a hollow ring and the others are
/// filled, but home, busy and unread differ only by color and size.
enum AppDotStatus { home, away, busy, unread }

/// A small decorative dot that sits next to the text that names its status.
///
/// `home` and `unread` are primary, `away` a hollow ring in the away color and
/// `busy` the in-use color. `unread` is a little larger. The dot has a fixed
/// size and does not follow the text scale.
///
/// The dot is never the only cue and must never stand alone: home and busy are
/// the same 8 px circle, apart only by hue, so the text beside it ("At home",
/// "Busy") is what tells them apart. For that reason the dot is excluded from
/// semantics and has no label of its own: assistive technology reads the text.
class AppStatusDot extends StatelessWidget {
  const new({required this.status, super.key});

  final AppDotStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final dimension = status == AppDotStatus.unread
        ? AppSizes.dotUnread
        : AppSizes.dot;
    final decoration = switch (status) {
      AppDotStatus.home || AppDotStatus.unread => BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
      ),
      AppDotStatus.busy => BoxDecoration(
        color: colors.busy,
        shape: BoxShape.circle,
      ),
      AppDotStatus.away => BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.presenceAway,
          width: AppSizes.borderEmphasis,
        ),
      ),
    };

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(decoration: decoration),
      ),
    );
  }
}

import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per status. The dot sits next to the text that names the
/// status, as on the Atoms board.
WidgetbookComponent buildAppStatusDot() {
  return WidgetbookComponent(
    name: 'AppStatusDot',
    useCases: [
      for (final status in AppDotStatus.values)
        WidgetbookUseCase(
          name: 'dot-${status.name}',
          builder: (context) => useCaseFrame(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppStatusDot(status: status),
                  const SizedBox(width: AppSpacing.sm),
                  Text(_label(context, status)),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

String _label(BuildContext context, AppDotStatus status) => switch (status) {
  AppDotStatus.home => context.sample(en: 'Home', es: 'En casa'),
  AppDotStatus.away => context.sample(en: 'Away', es: 'Fuera'),
  AppDotStatus.busy => context.sample(en: 'Busy', es: 'Ocupado'),
  AppDotStatus.unread => context.sample(en: 'Unread', es: 'Sin leer'),
};

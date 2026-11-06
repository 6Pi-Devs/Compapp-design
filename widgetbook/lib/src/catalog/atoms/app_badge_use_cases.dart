import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per form and tone: a count, a count past 99, and a label.
WidgetbookComponent buildAppBadge() {
  return WidgetbookComponent(
    name: 'AppBadge',
    useCases: [
      for (final form in _Form.values)
        for (final tone in AppBadgeTone.values)
          WidgetbookUseCase(
            name: '${form.name}-${tone.name}',
            builder: (context) => useCaseFrame(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _badge(context, form, tone),
              ),
            ),
          ),
    ],
  );
}

enum _Form { count, overflow, label }

Widget _badge(BuildContext context, _Form form, AppBadgeTone tone) {
  return switch (form) {
    _Form.count => AppBadge.count(3, tone: tone),
    _Form.overflow => AppBadge.count(120, tone: tone),
    _Form.label => AppBadge.label(switch (tone) {
      AppBadgeTone.primary => context.sample(en: 'New', es: 'Nuevo'),
      AppBadgeTone.busy => context.sample(
        en: 'Not applied yet',
        es: 'Sin aplicar',
      ),
      AppBadgeTone.soft => context.sample(en: 'Yours', es: 'Tuyo'),
    }, tone: tone),
  };
}

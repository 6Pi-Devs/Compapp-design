import 'package:compapp_design/src/tokens/app_colors.dart';
import 'package:flutter/material.dart';

extension AppColorsContext on BuildContext {
  /// The [AppColors] of the nearest theme. Requires `CompappTheme`.
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

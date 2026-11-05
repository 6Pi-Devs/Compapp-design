import 'package:compapp_design_widgetbook/src/catalog/atoms/app_badge_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/atoms/app_button_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/atoms/app_chip_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/atoms/app_code_input_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/atoms/app_icon_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/atoms/app_pebble_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/atoms/app_status_dot_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/atoms/app_switch_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/atoms/app_text_field_use_cases.dart';
import 'package:widgetbook/widgetbook.dart';

/// One component per atom in `components.json`, in manifest order.
List<WidgetbookComponent> buildAtoms() => [
  buildAppButton(),
  buildAppIcon(),
  buildAppChip(),
  buildAppSwitch(),
  buildAppTextField(),
  buildAppCodeInput(),
  buildAppPebble(),
  buildAppStatusDot(),
  buildAppBadge(),
];

import 'package:compapp_design_widgetbook/src/catalog/templates/app_form_page_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/templates/app_home_shell_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/templates/app_sheet_use_cases.dart';
import 'package:widgetbook/widgetbook.dart';

/// One component per template in `components.json`, in manifest order.
List<WidgetbookComponent> buildTemplates() => [
  buildAppSheet(),
  buildAppFormPage(),
  buildAppHomeShell(),
];

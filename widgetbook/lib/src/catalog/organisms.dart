import 'package:compapp_design_widgetbook/src/catalog/organisms/activity_list_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/organisms/calendar_strip_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/organisms/floorplan_map_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/organisms/item_sheet_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/organisms/presence_panel_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/organisms/task_composer_use_cases.dart';
import 'package:widgetbook/widgetbook.dart';

/// One component per organism in `components.json`, in manifest order.
List<WidgetbookComponent> buildOrganisms() => [
  buildActivityList(),
  buildPresencePanel(),
  buildCalendarStrip(),
  buildTaskComposer(),
  buildFloorplanMap(),
  buildItemSheet(),
];

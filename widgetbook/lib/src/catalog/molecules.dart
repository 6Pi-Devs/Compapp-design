import 'package:compapp_design_widgetbook/src/catalog/molecules/activity_row_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/app_empty_state_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/app_nav_bar_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/app_snackbar_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/app_top_bar_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/event_ribbon_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/item_beacon_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/member_row_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/room_tile_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/sheet_header_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/task_row_use_cases.dart';
import 'package:widgetbook/widgetbook.dart';

/// One component per molecule in `components.json`, in manifest order.
List<WidgetbookComponent> buildMolecules() => [
  buildMemberRow(),
  buildItemBeacon(),
  buildRoomTile(),
  buildTaskRow(),
  buildEventRibbon(),
  buildAppTopBar(),
  buildAppNavBar(),
  buildSheetHeader(),
  buildAppEmptyState(),
  buildAppSnackbar(),
  buildActivityRow(),
];

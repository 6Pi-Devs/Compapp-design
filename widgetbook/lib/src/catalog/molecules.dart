import 'package:compapp_design_widgetbook/src/catalog/molecules/item_beacon_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/member_row_use_cases.dart';
import 'package:compapp_design_widgetbook/src/catalog/molecules/room_tile_use_cases.dart';
import 'package:widgetbook/widgetbook.dart';

/// One component per molecule in `components.json`, in manifest order.
List<WidgetbookComponent> buildMolecules() => [
  buildMemberRow(),
  buildItemBeacon(),
  buildRoomTile(),
];

import 'package:flutter/widgets.dart';

import '../../controllers/dog_game_controller.dart';
import '../../models/day_phase.dart';
import '../../models/game_positions.dart';
import '../../widgets/dog_props.dart';
import '../girl/girl_layer.dart';
import 'living_room_keys.dart';
import 'living_room_props.dart';

/// The living room's animated props and the girl, each with the y used for
/// draw order (lower on the floor = in front).
List<(double, Widget)> livingRoomItems(DogGameController c, GameLayout layout, Anchored anchored) {
  double v(String key) => c.sceneValue(key);
  final doorWidth = layout.unit * GameSizes.door;
  final doorSize = Size(doorWidth, doorWidth / MailDoorPainter.aspect);
  final tableWidth = layout.unit * GameSizes.sideTable;
  final tableSize = Size(tableWidth, tableWidth / SideTableLampPainter.aspect);
  final lit = c.dayPhase.value == DayPhase.evening || c.dayPhase.value == DayPhase.night;
  return [
    (
      SceneMetrics.groundLine + 0.016,
      Positioned.fill(
        child: CustomPaint(painter: CurtainsPainter(unit: layout.unit)),
      ),
    ),
    (
      LivingRoomPositions.doorPosition.dy - 0.01,
      anchored(
        LivingRoomPositions.doorPosition,
        doorSize,
        0.5,
        CustomPaint(
          size: doorSize,
          painter: MailDoorPainter(envelope: v(LivingRoomKeys.mailEnvelope), knock: v(LivingRoomKeys.doorKnock)),
        ),
      ),
    ),
    (
      LivingRoomPositions.sideTablePosition.dy - 0.01,
      anchored(
        LivingRoomPositions.sideTablePosition,
        tableSize,
        0.5,
        CustomPaint(
          size: tableSize,
          painter: SideTableLampPainter(lit: lit),
        ),
      ),
    ),
    girlItem(c, layout, anchored, LivingRoomPositions.girlPosition),
  ];
}

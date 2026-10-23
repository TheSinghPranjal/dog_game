import 'package:flutter/widgets.dart';

import '../../controllers/dog_game_controller.dart';
import '../../models/game_positions.dart';
import '../../scripting/scene_state.dart';
import '../../widgets/dog_props.dart';
import '../girl/girl_layer.dart';

/// The garden's fire hydrant and the mound with a bone buried in it, each
/// with the y used for draw order.
List<(double, Widget)> outdoorItems(DogGameController c, GameLayout layout, Anchored anchored) {
  final moundWidth = layout.unit * GameSizes.mound;
  final moundSize = Size(moundWidth, moundWidth / DigMoundPainter.aspect);
  final hydrantWidth = layout.unit * GameSizes.hydrant;
  final hydrantSize = Size(hydrantWidth, hydrantWidth / HydrantPainter.aspect);
  return [
    (
      OutdoorPositions.hydrantPosition.dy,
      anchored(
        OutdoorPositions.hydrantPosition,
        hydrantSize,
        0.5,
        CustomPaint(size: hydrantSize, painter: const HydrantPainter()),
      ),
    ),
    (
      OutdoorPositions.moundPosition.dy - 0.03,
      anchored(
        OutdoorPositions.moundPosition,
        moundSize,
        0.5,
        CustomPaint(
          size: moundSize,
          painter: DigMoundPainter(dug: c.sceneValue(SceneKeys.moundDug)),
        ),
      ),
    ),
  ];
}

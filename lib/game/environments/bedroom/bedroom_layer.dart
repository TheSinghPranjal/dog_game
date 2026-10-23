import 'package:flutter/widgets.dart';

import '../../controllers/dog_game_controller.dart';
import '../../models/activity_definition.dart';
import '../../models/game_positions.dart';
import '../../widgets/dog_props.dart';
import 'bedroom_keys.dart';
import 'bedroom_props.dart';
import '../girl/girl_layer.dart';

/// The bedroom's animated props and the girl, each with the y used for draw
/// order (lower on the floor = in front).
List<(double, Widget)> bedroomItems(DogGameController c, GameLayout layout, Anchored anchored) {
  final unit = layout.unit;
  double v(String key) => c.sceneValue(key);

  final wardrobeWidth = unit * GameSizes.wardrobe;
  final wardrobeSize = Size(wardrobeWidth, wardrobeWidth / WardrobePainter.aspect);
  final pillowWidth = unit * GameSizes.pillow;
  final pillowSize = Size(pillowWidth, pillowWidth / DogPillowPainter.aspect);
  final slipperWidth = unit * GameSizes.slipper;
  final slipperSize = Size(slipperWidth, slipperWidth / SlipperPainter.aspect);
  return [
    (
      BedroomPositions.wardrobePosition.dy,
      anchored(
        BedroomPositions.wardrobePosition,
        wardrobeSize,
        0.5,
        CustomPaint(
          size: wardrobeSize,
          painter: WardrobePainter(
            door: v(BedroomKeys.wardrobeDoor),
            eyes: v(BedroomKeys.wardrobeEyes) > 0,
            tail: v(BedroomKeys.wardrobeTail) > 0,
            time: c.sceneTime,
          ),
        ),
      ),
    ),
    // His round pillow sits on the bed, behind anything standing on it.
    (
      BedroomPositions.pillowPosition.dy - 0.05,
      anchored(
        BedroomPositions.pillowPosition,
        pillowSize,
        0.5,
        CustomPaint(
          size: pillowSize,
          painter: DogPillowPainter(squish: v(BedroomKeys.pillowSquish)),
        ),
      ),
    ),
    // The resting slipper steps aside while the Slipper activity uses it.
    (
      BedroomPositions.slipperPosition.dy,
      anchored(
        BedroomPositions.slipperPosition,
        slipperSize,
        0.5,
        AnimatedOpacity(
          opacity: c.activeActivity == DogActivity.slipper ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: Transform.flip(
            flipX: true,
            child: CustomPaint(size: slipperSize, painter: SlipperPainter()),
          ),
        ),
      ),
    ),
    (
      BedroomPositions.cableRestPoint.dy,
      Positioned.fill(
        child: CustomPaint(painter: ChargerCablePainter(unit: unit)),
      ),
    ),
    girlItem(c, layout, anchored, BedroomPositions.girlPosition),
  ];
}

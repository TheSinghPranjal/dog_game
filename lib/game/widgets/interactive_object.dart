import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../models/dog_game_state.dart';
import '../models/game_positions.dart';
import '../environments/park/park_props.dart';
import 'critters.dart';
import 'dog_props.dart';
import 'food_bowl.dart';
import 'grooming_props.dart';
import 'kitchen_props.dart';
import 'toy_ball.dart';

/// Renders any [SpawnedObject] with the shared fade-out, at a size derived
/// from [GameSizes].
class InteractiveObject extends StatelessWidget {
  const InteractiveObject({super.key, required this.object, required this.unit});

  final SpawnedObject object;
  final double unit;

  /// Pixel size of the sprite box for [kind].
  static Size sizeOf(ObjectKind kind, double unit) {
    Size box(double widthFraction, double aspect) {
      final w = unit * widthFraction;
      return Size(w, w / aspect);
    }

    return switch (kind) {
      ObjectKind.bowl => box(GameSizes.bowl, FoodBowl.aspect),
      ObjectKind.ball => ToyBall.boxSize(unit * GameSizes.ball),
      ObjectKind.squirrel => box(GameSizes.squirrel, SquirrelPainter.aspect),
      ObjectKind.brush => box(GameSizes.brush, BrushPainter.aspect),
      ObjectKind.towel => box(GameSizes.towel, TowelPainter.aspect),
      ObjectKind.glass => box(GameSizes.glass, GlassPainter.aspect),
      ObjectKind.treat => box(GameSizes.treat, BoneTreatPainter.aspect),
      ObjectKind.drumstick => box(GameSizes.drumstick, DrumstickPainter.aspect),
      ObjectKind.plate => box(GameSizes.plate, DinnerPlatePainter.aspect),
      ObjectKind.duck => box(GameSizes.duck, DuckPainter.aspect),
      ObjectKind.pigeon => box(GameSizes.pigeon, BirdPainter.aspect),
      ObjectKind.frisbee => box(GameSizes.frisbee, FrisbeePainter.aspect),
      ObjectKind.slipper => box(GameSizes.slipper, SlipperPainter.aspect),
    };
  }

  /// Where the object's position sits horizontally inside its box (0..1).
  static double anchorX(ObjectKind kind) => kind == ObjectKind.ball ? ToyBall.ballCenterX : 0.5;

  @override
  Widget build(BuildContext context) {
    final o = object;
    final CustomPainter painter = switch (o.kind) {
      ObjectKind.bowl => FoodBowlPainter(fill: o.fill, appear: o.appear, pop: o.pop),
      ObjectKind.ball => ToyBallPainter(rotation: o.rotation, appear: o.appear, pop: o.pop),
      ObjectKind.squirrel => SquirrelPainter(
        phase: o.phase,
        moving: o.moving,
        facing: o.facing,
        appear: o.appear,
        pop: o.pop,
      ),
      ObjectKind.brush => BrushPainter(facing: o.facing, appear: o.appear, pop: o.pop),
      ObjectKind.towel => TowelPainter(appear: o.appear, pop: o.pop),
      ObjectKind.glass => GlassPainter(rotation: o.rotation, appear: o.appear, pop: o.pop),
      ObjectKind.treat => BoneTreatPainter(fill: o.fill, appear: o.appear, pop: o.pop),
      ObjectKind.drumstick => DrumstickPainter(progress: o.progress, appear: o.appear, pop: o.pop),
      ObjectKind.plate => DinnerPlatePainter(fill: o.fill, appear: o.appear, pop: o.pop),
      ObjectKind.duck => DuckPainter(
        phase: o.phase,
        facing: o.facing,
        appear: o.appear,
        pop: o.pop,
        quacking: o.progress > 0,
      ),
      ObjectKind.pigeon => BirdPainter(
        phase: o.phase,
        airborne: o.airborne,
        facing: o.facing,
        appear: o.appear,
        pop: o.pop,
        pigeon: true,
      ),
      ObjectKind.frisbee => FrisbeePainter(rotation: o.rotation, appear: o.appear, pop: o.pop),
      ObjectKind.slipper => SlipperPainter(appear: o.appear, pop: o.pop, shake: o.rotation),
    };
    return Opacity(
      opacity: ObjectAnimations.popOpacity(o.pop),
      child: CustomPaint(size: sizeOf(o.kind, unit), painter: painter),
    );
  }
}

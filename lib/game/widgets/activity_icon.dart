import 'package:flutter/widgets.dart';

import '../environments/bedroom/bedroom_props.dart';
import '../environments/park/park_props.dart';
import '../models/activity_definition.dart';
import 'critters.dart';
import 'dog_props.dart';
import 'food_bowl.dart';
import 'grooming_props.dart';
import 'kitchen_props.dart';
import 'toy_ball.dart';

/// Action-button icons, reusing the in-game sprites at rest so buttons and
/// scene always match.
class ActivityIcon extends StatelessWidget {
  const ActivityIcon(this.activity, {super.key});

  final DogActivity activity;

  @override
  Widget build(BuildContext context) {
    final (double aspect, CustomPainter painter) = switch (activity) {
      DogActivity.feed => (FoodBowl.aspect, FoodBowlPainter(biscuit: true)),
      DogActivity.fetch => (ToyBall.aspect, ToyBallPainter(rotation: 0.4, motionMarks: true)),
      DogActivity.chaseSquirrel => (SquirrelPainter.aspect, SquirrelPainter()),
      DogActivity.bathTime => (BathTubPainter.aspect, BathTubPainter(foam: 1, duck: true)),
      DogActivity.brushFur => (BrushPainter.aspect, BrushPainter()),
      DogActivity.towelDry => (TowelPainter.aspect, TowelPainter()),
      DogActivity.treeSquirrel => (SquirrelPainter.aspect, SquirrelPainter(hop: true)),
      DogActivity.dig => (DigMoundPainter.aspect, DigMoundPainter(tufts: true)),
      DogActivity.frisbee => (FrisbeePainter.aspect, FrisbeePainter(motionArc: true)),
      DogActivity.glassTrouble => (GlassPainter.aspect * 1.3, GlassPainter(motionMarks: true)),
      DogActivity.treatTime => (BoneTreatPainter.aspect, BoneTreatPainter()),
      DogActivity.dinner => (1.0, const DinnerIconPainter()),
      DogActivity.closetHide => (WardrobePainter.aspect * 1.25, WardrobePainter(door: 0.45, tail: true)),
      DogActivity.slipper => (SlipperPainter.aspect, SlipperPainter()),
      DogActivity.pillowJump => (DogPillowPainter.aspect, DogPillowPainter()),
      DogActivity.mail => (MailDoorPainter.aspect, MailDoorPainter(envelope: 0.6, nose: true)),
      DogActivity.wag => (1.0, const WagIconPainter()),
      DogActivity.windowWatch => (1.0, const SquirrelWindowIconPainter()),
      DogActivity.duckPond => (DuckPainter.aspect, DuckPainter(wake: true)),
      DogActivity.leafPile => (LeafPilePainter.aspect, LeafPilePainter(buriedDog: true)),
      DogActivity.benchPigeon => (BirdPainter.aspect, BirdPainter(pigeon: true)),
    };
    return AspectRatio(
      aspectRatio: aspect,
      child: CustomPaint(painter: painter),
    );
  }
}

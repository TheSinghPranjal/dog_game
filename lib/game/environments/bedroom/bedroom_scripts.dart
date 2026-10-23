import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../animations/dog_animations.dart';
import '../../dogs/dog_needs.dart';
import '../../models/dog_game_state.dart';
import '../../models/game_positions.dart';
import '../../scripting/scene_state.dart';
import '../../scripting/script_step.dart';
import 'bedroom_keys.dart';
import '../girl/girl_painter.dart';
import '../girl/girl_steps.dart';

/// The bedroom's three things: hide-and-peek in the closet, a proud shake
/// of the slipper, and a bounce on his own round pillow. The charging cable
/// stays untouched in the background.
abstract final class BedroomScripts {
  static ScriptStep _door(double to, double seconds) =>
      TweenValue(BedroomKeys.wardrobeDoor, to, seconds, curve: Curves.easeOut);

  static double _squish(double t) => math.sin(t * math.pi) * 0.8;

  static final closetHide = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.fun: 18, Need.affection: 6},
    steps: [
      // In he goes: the door swings open and he hops into the dark.
      const WalkTo(BedroomPositions.dogWardrobeFront, endFacing: -1, endPose: DogPose.lookUp),
      _door(1, 0.5),
      const Leap(BedroomPositions.dogInWardrobe, height: 12, seconds: 0.5),
      const SetValue(SceneKeys.dogHidden, 1),
      const SetValue(BedroomKeys.wardrobeTail, 1),
      // The door sits half open, a wagging tail giving him away.
      _door(0.55, 0.4),
      Girl.mood(GirlMood.searching),
      const Wait(1.2),

      // A peek: two eyes in the gap.
      const SetValue(BedroomKeys.wardrobeEyes, 1),
      const Wait(1.0),
      const SetValue(BedroomKeys.wardrobeEyes, 0),
      const Wait(0.5),

      // Boo! Out he pops.
      _door(1, 0.3),
      const SetValue(BedroomKeys.wardrobeTail, 0),
      const SetValue(SceneKeys.dogHidden, 0),
      Girl.mood(GirlMood.surprised),
      const Leap(BedroomPositions.dogWardrobeJumpOut, height: 16, seconds: 0.55),
      const Turn(-1),
      const Effect(EffectKind.sparkles, Offset(0, -0.1), nearDog: true, duration: 1.2),
      Parallel([
        const Pose(DogPose.happy, 1.2),
        Sequence([const Wait(0.3), Girl.mood(GirlMood.laughing)]),
      ]),

      const Phase(DogGameState.returningToIdle),
      Girl.mood(GirlMood.happy),
      Parallel([_door(0, 0.4), const WalkTo(BedroomPositions.returnPosition)]),
    ],
  );

  static void _shakeSlipper(SpawnedObject s, PropStart _, double t) => s.rotation = math.sin(t * math.pi * 6) * 0.35;

  static final slipper = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.fun: 14, Need.energy: -4},
    steps: [
      // The slipper on the rug... he sniffs it, grabs it...
      const Spawn('slipper', ObjectKind.slipper, BedroomPositions.slipperPosition, facing: -1, focus: true),
      const SetProp('slipper', fill: 1),
      const Appear('slipper'),
      const WalkTo(BedroomPositions.dogSlipperPosition, endFacing: -1, endPose: DogPose.sniff),
      const Wait(0.7),
      const Remove('slipper'),
      const Carry(DogCarry.slipper),

      // ...gives it a gentle shake, and looks very proud of himself.
      Pose(DogPose.shake, 1.0),
      const Pose(DogPose.wag),
      const Effect(EffectKind.sparkles, Offset(0, -0.1), nearDog: true, duration: 1.2),
      Girl.mood(GirlMood.laughing),
      const Wait(1.2),

      // Then he drops it back where it was.
      const Carry(DogCarry.none),
      const Spawn('slipper', ObjectKind.slipper, BedroomPositions.slipperPosition, facing: -1),
      const Appear('slipper'),
      PropAnim('slipper', 'settle', 0.3, _shakeSlipper),
      Girl.mood(GirlMood.happy),
      const Pose(DogPose.happy, 0.8),
      const PopAway('slipper'),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(BedroomPositions.returnPosition),
    ],
  );

  static final pillowJump = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.fun: 16, Need.energy: 6},
    steps: [
      // Up onto the bed and over to his round pillow.
      const WalkTo(BedroomPositions.dogBedFoot, endFacing: 1, endPose: DogPose.crouch),
      const Wait(0.5),
      const Leap(BedroomPositions.dogOnBed, height: 22, seconds: 0.6),
      const Pose(DogPose.idle),
      const WalkTo(BedroomPositions.dogBedMiddle, endFacing: 1, endPose: DogPose.crouch),
      const Wait(0.4),
      const Leap(BedroomPositions.dogOnPillow, height: 12, seconds: 0.45),

      // Boing! One bounce, then he settles with his chin on his paws.
      Parallel([
        const Pose(DogPose.happy),
        const MoveDog(BedroomPositions.dogOnPillow, 0.38, curve: Curves.linear, arc: 9),
        SceneValue(BedroomKeys.pillowSquish, 0.38, _squish),
      ]),
      const Turn(-1),
      const Pose(DogPose.lieDown, 2.4),
      Girl.mood(GirlMood.adoring),
      const Effect(EffectKind.hearts, Offset(0, -0.12), nearDog: true, duration: 1.4),
      const Wait(1.4),

      const Phase(DogGameState.returningToIdle),
      Girl.mood(GirlMood.happy),
      const Leap(BedroomPositions.dogBedJumpDown, height: 12, seconds: 0.55),
      const Pose(DogPose.idle),
      const WalkTo(BedroomPositions.returnPosition),
    ],
  );
}

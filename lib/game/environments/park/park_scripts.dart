import 'package:flutter/animation.dart';

import '../../animations/dog_animations.dart';
import '../../dogs/dog_needs.dart';
import '../../dogs/reaction.dart';
import '../../models/dog_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/script_step.dart';
import 'park_keys.dart';

/// The park's three things: a duck on the pond, a big leaf pile, and a
/// pigeon on the bench. Every bird paddles or flutters off safely, and he
/// never goes into the water.
abstract final class ParkScripts {
  static final duckPond = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.fun: 16},
    steps: [
      // He trots to the bank and stops right at the edge.
      const WalkTo(ParkPositions.dogAtPond, endFacing: 1, endPose: DogPose.sit),
      const Spawn('duck', ObjectKind.duck, ParkPositions.duckSpawn, facing: -1, focus: true),
      const Appear('duck'),
      const MoveProp('duck', ParkPositions.duckNear, 2.4, curve: Curves.easeOut),
      const Pose(DogPose.wag, 0.8),

      // QUACK! A little startled, but he stays on the bank.
      const SetProp('duck', progress: 1),
      const Effect(EffectKind.quack, ParkPositions.quackAt, duration: 0.9),
      const Parallel([React(1.0, outcome: ReactionOutcome.nope), Pose(DogPose.surprised, 1.0)]),
      const SetProp('duck', progress: 0),
      Pose(DogPose.bark, sec(GameTimings.bark)),

      // The duck paddles off, happy as anything.
      const MoveProp('duck', ParkPositions.duckExit, 2.2, curve: Curves.easeIn),
      const Remove('duck'),
      const Pose(DogPose.sit, 0.8),
      const Mark(DogMark.question, 0.8),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(ParkPositions.returnPosition),
    ],
  );

  static final leafPile = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.fun: 20, Need.cleanliness: -6},
    steps: [
      const WalkTo(ParkPositions.dogLeafRunStart, endFacing: -1, endPose: DogPose.crouch),
      const Pose(DogPose.crouch, 0.5),
      // A run-up and a big leap into the pile!
      const Pose(DogPose.walk),
      const MoveDog(ParkPositions.dogOutOfLeaves, 0.35),
      const Leap(ParkPositions.dogInLeaves, height: 22, seconds: 0.55),
      const SetValue(ParkKeys.leafScatter, 1),
      const Effect(EffectKind.leafBurst, Offset(0.15, 0.75), duration: 2.6),
      const Effect(EffectKind.sparkles, Offset(0, -0.1), nearDog: true, duration: 1.4),
      // He pops out with a stick, very pleased, and drops it.
      const Carry(DogCarry.stick),
      const Pose(DogPose.happy, 1.4),
      const Turn(1),
      const Leap(ParkPositions.dogOutOfLeaves, height: 12, seconds: 0.5),
      const WalkTo(ParkPositions.dogDropStick, endFacing: 1, endPose: DogPose.wag),
      const Wait(0.8),
      const Carry(DogCarry.none),
      Puff(ParkPositions.dogDropStick + const Offset(0.05, 0.01)),

      const Phase(DogGameState.returningToIdle),
      // The leaves settle back into a pile.
      const Parallel([TweenValue(ParkKeys.leafScatter, 0, 1.2), WalkTo(ParkPositions.returnPosition)]),
    ],
  );

  static final benchPigeon = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.fun: 16, Need.energy: -6},
    steps: [
      const Spawn('pigeon', ObjectKind.pigeon, ParkPositions.pigeonOnBench, focus: true),
      const Appear('pigeon'),
      // Sneaking up, low and slow...
      const WalkTo(ParkPositions.dogSneakStart, endFacing: -1, endPose: DogPose.crouch),
      const Wait(0.5),
      const MoveDog(ParkPositions.dogSneakEnd, 1.8, curve: Curves.easeInOutSine),
      const Wait(0.5),

      // A play bow... and a lunge onto the bench! The pigeon flutters up
      // to the top of the lamp post, safe.
      const Pose(DogPose.playBow, 0.7),
      Parallel([
        const Leap(ParkPositions.dogOnBench, height: 14, seconds: 0.55),
        after(
          0.2,
          const Sequence([
            SetProp('pigeon', airborne: true),
            MoveProp('pigeon', ParkPositions.pigeonOnLamp, 1.0, arc: 0.05, curve: Curves.easeOut),
            SetProp('pigeon', airborne: false),
          ]),
        ),
      ]),
      const Turn(1),
      const Pose(DogPose.lookUp, 1.0),
      Pose(DogPose.bark, sec(GameTimings.bark)),
      const Pose(DogPose.sit, 0.6),
      const Leap(ParkPositions.dogSneakEnd, height: 8, seconds: 0.45),
      const PopAway('pigeon'),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(ParkPositions.returnPosition),
    ],
  );
}

import 'package:flutter/animation.dart';

import '../../animations/dog_animations.dart';
import '../../dogs/dog_needs.dart';
import '../../models/dog_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/scene_state.dart';
import '../../scripting/script_step.dart';

/// The Outdoors garden: chase a squirrel up the tree (he never climbs), dig
/// up a bone, and catch a frisbee.
abstract final class OutdoorScripts {
  static final treeSquirrel = ActivityScript(
    firstPhase: DogGameState.chasingSquirrel,
    needs: const {Need.fun: 18, Need.energy: -8},
    steps: [
      const Spawn('squirrel', ObjectKind.squirrel, OutdoorPositions.squirrelSpawnPosition, facing: -1, focus: true),
      const Appear('squirrel'),
      const WalkTo(OutdoorPositions.dogSquirrelStartPosition, endFacing: 1, endPose: DogPose.crouch),
      const Mark(DogMark.exclaim, 0.6),

      // It darts off across the grass; he gives chase.
      const Parallel([
        MoveProp('squirrel', OutdoorPositions.squirrelDartPosition, 0.7),
        Sequence([Wait(0.15), Turn(-1)]),
      ]),
      const Parallel([
        MoveProp('squirrel', OutdoorPositions.squirrelTrunkBase, 0.8),
        WalkTo(OutdoorPositions.dogAtTrunk, endFacing: -1),
      ]),

      // Up the trunk it goes, onto a branch.
      const MoveProp('squirrel', OutdoorPositions.squirrelTrunkTop, 0.55, faceMovement: false),
      const MoveProp('squirrel', OutdoorPositions.squirrelOnBranch, 0.4),

      // He stands up with his paws on the trunk, looks up and wags.
      const Pose(DogPose.pawsUp, 1.6),
      Pose(DogPose.bark, sec(GameTimings.bark)),
      const MoveProp('squirrel', OutdoorPositions.squirrelHigh, 0.6, arc: 0.03),
      const Effect(EffectKind.leaves, Offset(0.26, 0.30), duration: 1.6),
      const PopAway('squirrel'),
      const Pose(DogPose.lookUp, 0.8),
      const Pose(DogPose.wag, 1.0),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(OutdoorPositions.dogSquirrelReturnPosition),
    ],
  );

  static double _dig(double t) => t;
  static double _refill(double t) => 1 - t;

  static final dig = ActivityScript(
    firstPhase: DogGameState.digging,
    needs: const {Need.fun: 20, Need.cleanliness: -8},
    steps: [
      const WalkTo(OutdoorPositions.dogDigPosition, endFacing: 1, endPose: DogPose.sniff),
      const Wait(0.8),
      const Mark(DogMark.exclaim, 0.5),

      // Dig, dig, dig: dirt flies back between his legs.
      const Pose(DogPose.dig),
      const Effect(EffectKind.dirt, OutdoorPositions.dirtPosition, id: 'dirt'),
      SceneValue(SceneKeys.moundDug, sec(GameTimings.dig), _dig),
      const RemoveEffects(ids: ['dirt']),
      const Puff(OutdoorPositions.moundPosition),

      // The bone! He parades it about, then drops it for later.
      const Carry(DogCarry.bone),
      const Pose(DogPose.happy, 0.8),
      const WalkTo(OutdoorPositions.dogParadeA, endFacing: -1),
      const WalkTo(OutdoorPositions.dogParadeB, endFacing: 1),
      Pose(DogPose.wag, sec(GameTimings.happy)),
      const Carry(DogCarry.none),
      Puff(OutdoorPositions.dogParadeB + const Offset(0.05, 0.01)),

      const Phase(DogGameState.returningToIdle),
      Parallel([SceneValue(SceneKeys.moundDug, 1.0, _refill), const WalkTo(OutdoorPositions.dogDigReturnPosition)]),
    ],
  );

  static void _spin(SpawnedObject disc, PropStart start, double t) => disc.rotation = start.rotation + t * 6;

  static final frisbee = ActivityScript(
    firstPhase: DogGameState.playing,
    needs: const {Need.fun: 22, Need.energy: -10},
    steps: [
      const WalkTo(OutdoorPositions.dogFrisbeeStartPosition, endFacing: -1, endPose: DogPose.playBow),
      const Spawn('frisbee', ObjectKind.frisbee, OutdoorPositions.frisbeeSpawnPosition, airborne: true, focus: true),
      const Appear('frisbee'),

      // It loops across the garden...
      Parallel([
        const MoveProp('frisbee', OutdoorPositions.frisbeeLoopA, 0.8, arc: 0.04, faceMovement: false),
        PropAnim('frisbee', 'spin', 0.8, _spin),
      ]),
      const Turn(1),
      Parallel([
        const MoveProp('frisbee', OutdoorPositions.frisbeeLoopB, 0.8, arc: 0.04, faceMovement: false),
        PropAnim('frisbee', 'spin', 0.8, _spin),
      ]),

      // ...first jump: just misses!
      Parallel([
        const MoveProp('frisbee', OutdoorPositions.frisbeeMissPosition, 0.5, faceMovement: false),
        after(0.1, const Leap(OutdoorPositions.dogFrisbeeCatchPosition, height: 20, seconds: 0.5)),
      ]),
      const Pose(DogPose.lookUp, 0.3),
      const Turn(-1),
      Parallel([
        const MoveProp('frisbee', OutdoorPositions.frisbeeLoopC, 0.5, faceMovement: false),
        PropAnim('frisbee', 'spin', 0.5, _spin),
      ]),

      // Second jump: got it!
      Parallel([
        const MoveProp('frisbee', OutdoorPositions.frisbeeCatchPosition, 0.45, faceMovement: false),
        after(0.05, const Leap(OutdoorPositions.dogFrisbeeStartPosition, height: 22, seconds: 0.45)),
      ]),
      const Remove('frisbee'),
      const Carry(DogCarry.frisbee),
      const Effect(EffectKind.sparkles, Offset(0, -0.1), nearDog: true, duration: 1.0),
      Pose(DogPose.wag, sec(GameTimings.happy)),

      // He drops it on the grass, where it lands safely.
      const Carry(DogCarry.none),
      const Spawn('frisbee', ObjectKind.frisbee, OutdoorPositions.frisbeeDropPosition),
      const SetProp('frisbee', airborne: false),
      const Appear('frisbee'),
      const Pose(DogPose.happy, 0.8),
      const PopAway('frisbee'),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(OutdoorPositions.dogFrisbeeReturnPosition),
    ],
  );
}

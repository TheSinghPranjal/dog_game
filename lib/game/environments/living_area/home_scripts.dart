import 'package:flutter/animation.dart';

import '../../animations/dog_animations.dart';
import '../../dogs/dog_needs.dart';
import '../../models/dog_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/script_step.dart';

/// Home: feed him, play fetch, chase the squirrel from the baseboard hole.
abstract final class HomeScripts {
  static void _eatFromBowl(SpawnedObject bowl, PropStart _, double t) => bowl.fill = 1 - 0.8 * t;

  static ScriptStep _rollBall(Offset to, Duration duration) => MoveProp(
    'ball',
    to,
    sec(duration),
    curve: Curves.easeOutCubic,
    faceMovement: false,
    rollRadius: GameSizes.ballRadiusNormalized,
  );

  static final feed = ActivityScript(
    firstPhase: DogGameState.walkingToFood,
    needs: const {Need.hunger: -35, Need.affection: 3},
    steps: [
      const Spawn('bowl', ObjectKind.bowl, HomePositions.bowlPosition),
      const Appear('bowl'),
      const WalkTo(HomePositions.feedingPosition, endFacing: -1),
      const Phase(DogGameState.eating),
      const Pose(DogPose.eat),
      PropAnim('bowl', 'eat', sec(GameTimings.eating), _eatFromBowl),
      // A last kibble pops out of the bowl, and the tail goes.
      Effect(EffectKind.sparkles, HomePositions.bowlPosition + const Offset(0, -0.04), duration: 0.8),
      const Pose(DogPose.wag),
      Parallel([Wait(sec(GameTimings.happy)), const PopAway('bowl')]),
      const Phase(DogGameState.returningFromFood),
      const WalkTo(HomePositions.returnPosition),
    ],
  );

  static final fetch = ActivityScript(
    firstPhase: DogGameState.walkingToToy,
    needs: const {Need.fun: 20, Need.energy: -5},
    steps: [
      const Spawn('ball', ObjectKind.ball, HomePositions.ballStartPosition, focus: true),
      const Appear('ball'),
      const WalkTo(HomePositions.playPosition, endFacing: 1, endPose: DogPose.playBow),
      const Phase(DogGameState.playing),
      const Wait(0.5),
      // 1. The ball rolls away while he holds his play bow.
      _rollBall(HomePositions.ballWaypoints[0], GameTimings.ballRollOut),
      // 2. He bounds after it.
      const WalkTo(HomePositions.chasePosition, endPose: DogPose.playBow),
      // 3. The ball rolls a little way back.
      _rollBall(HomePositions.ballWaypoints[1], GameTimings.ballRollBack),
      // 4. A swat sends it to its spot; he trots over and picks it up.
      const SwipePaw(),
      Parallel([const SwipePaw(), _rollBall(HomePositions.ballEndPosition, GameTimings.ballSettle)]),
      WalkTo(HomePositions.ballEndPosition + const Offset(-0.07, -0.02), endFacing: 1, endPose: DogPose.sniff),
      const Wait(0.3),
      const Remove('ball'),
      const Carry(DogCarry.ball),
      // 5. ...and brings it back, proud as anything.
      const Phase(DogGameState.returningFromPlay),
      const WalkTo(HomePositions.fetchReturnPosition, endFacing: 1, endPose: DogPose.wag),
      Wait(sec(GameTimings.happy)),
      const Carry(DogCarry.none),
      Puff(HomePositions.fetchReturnPosition + const Offset(0.06, 0)),
      Pose(DogPose.happy, sec(GameTimings.happy)),
      const WalkTo(HomePositions.returnPosition),
    ],
  );

  static final chaseSquirrel = ActivityScript(
    firstPhase: DogGameState.chasingSquirrel,
    needs: const {Need.fun: 20, Need.energy: -8},
    steps: [
      // The squirrel peeks out of its hole and sniffs around.
      const Spawn('squirrel', ObjectKind.squirrel, HomePositions.squirrelSpawnPosition, facing: -1, focus: true),
      const Puff(HomePositions.squirrelSpawnPosition),
      const Appear('squirrel'),
      Wait(sec(GameTimings.squirrelSniff)),

      // He creeps closer and crouches, tail going.
      const WalkTo(HomePositions.dogSquirrelApproachPosition, endFacing: 1, endPose: DogPose.crouch),
      const Wait(0.6),

      // The squirrel scurries A -> B -> C; he follows fixed pursuit spots.
      const MoveProp('squirrel', HomePositions.squirrelWaypointA, 0.5),
      Parallel([
        const MoveProp('squirrel', HomePositions.squirrelWaypointB, 0.55),
        WalkTo(HomePositions.dogSquirrelPursuitPositions[0], endFacing: 1, endPose: DogPose.crouch),
      ]),
      Parallel([
        const MoveProp('squirrel', HomePositions.squirrelWaypointC, 0.5),
        WalkTo(HomePositions.dogSquirrelPursuitPositions[1], endFacing: 1, endPose: DogPose.crouch),
      ]),
      const Wait(0.35),

      // Lunge! The squirrel darts home just in time. Nobody is hurt.
      Parallel([
        const Leap(HomePositions.dogSquirrelLungeTarget),
        after(0.12, const MoveProp('squirrel', HomePositions.squirrelFinalPosition, 0.4, curve: Curves.easeIn)),
      ]),
      const Puff(HomePositions.squirrelFinalPosition),
      const Pose(DogPose.surprised),
      const PopAway('squirrel'),

      // Where did it go? A look round and a woof at the hole.
      const Wait(0.3),
      const Turn(-1),
      const Wait(0.45),
      const Turn(1),
      Pose(DogPose.bark, sec(GameTimings.bark)),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(HomePositions.dogSquirrelReturnPosition),
    ],
  );
}

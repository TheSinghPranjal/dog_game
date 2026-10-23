import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../animations/dog_animations.dart';
import '../../dogs/dog_needs.dart';
import '../../dogs/reaction.dart';
import '../../models/dog_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/script_step.dart';
import '../girl/girl_painter.dart';
import '../girl/girl_steps.dart';
import 'living_room_keys.dart';

/// The living room's three things: woofing at the mail slot, a wag and a
/// pat from the girl, and watching a squirrel from the window sill.
abstract final class LivingRoomScripts {
  static double _knock(double t) => math.sin(t * math.pi);
  static double _envelopeIn(double t) => Curves.easeOut.transform(t);
  static double _envelopeOut(double t) => 1 - t;

  static final mail = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.fun: 14},
    steps: [
      // Knock knock! His ears go up.
      const Effect(EffectKind.knock, LivingRoomPositions.knockAt, duration: 1.2),
      SceneValue(LivingRoomKeys.doorKnock, 0.6, _knock),
      const Pose(DogPose.surprised, 0.6),

      // He trots over and woofs twice at the slot.
      const WalkTo(LivingRoomPositions.dogAtDoor, endFacing: 1),
      SceneValue(LivingRoomKeys.mailEnvelope, 0.5, _envelopeIn),
      Pose(DogPose.bark, sec(GameTimings.bark)),
      const Wait(0.3),
      Pose(DogPose.bark, sec(GameTimings.bark)),

      // The envelope stays outside; the mail carrier takes the hint.
      SceneValue(LivingRoomKeys.mailEnvelope, 0.5, _envelopeOut),
      Girl.mood(GirlMood.laughing),
      const Pose(DogPose.sit, 0.4),
      const Effect(EffectKind.sparkles, Offset(0, -0.1), nearDog: true, duration: 1.2),
      const Pose(DogPose.satisfied, 1.2),
      Girl.mood(GirlMood.happy),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(LivingRoomPositions.returnPosition),
    ],
  );

  static final wag = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.affection: 22},
    steps: [
      const WalkTo(LivingRoomPositions.dogByGirl, endFacing: -1),
      const Pose(DogPose.sit, 0.4),
      // A pat from the girl: hearts rise, his tail is a blur, he leans in.
      Girl.mood(GirlMood.adoring),
      const Effect(EffectKind.hearts, LivingRoomPositions.heartsAt, duration: 4.2),
      Parallel([
        const React(4.0, outcome: ReactionOutcome.lovesIt),
        Sequence([
          const Pose(DogPose.wag, 1.6),
          const MoveDog(LivingRoomPositions.dogLeanIn, 0.6, curve: Curves.easeInOutSine),
          const Pose(DogPose.wag, 1.2),
          const MoveDog(LivingRoomPositions.dogByGirl, 0.6, curve: Curves.easeInOutSine),
        ]),
      ]),
      const Pose(DogPose.happy, 1.0),
      Girl.mood(GirlMood.happy),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(LivingRoomPositions.returnPosition),
    ],
  );

  static final windowWatch = ActivityScript(
    firstPhase: DogGameState.busy,
    needs: const {Need.fun: 14, Need.energy: -6},
    steps: [
      // Up onto the sill to see what's outside.
      const WalkTo(LivingRoomPositions.dogBelowWindow, endFacing: -1, endPose: DogPose.lookUp),
      const Wait(0.4),
      const Leap(LivingRoomPositions.dogOnSill, height: 24, seconds: 0.6),
      const Pose(DogPose.sit, 0.6),

      // A squirrel scampers along the outside sill and sits there.
      const Spawn('squirrel', ObjectKind.squirrel, LivingRoomPositions.squirrelSillSpawn, focus: true),
      const Appear('squirrel'),
      const MoveProp('squirrel', LivingRoomPositions.squirrelOnSill, 1.0),
      const Mark(DogMark.exclaim, 0.6),

      // He watches, tail thumping away.
      const Pose(DogPose.wag, 2.4),
      Pose(DogPose.bark, sec(GameTimings.bark)),

      // Off it goes. A sigh, and he lies down on the sill.
      const MoveProp('squirrel', LivingRoomPositions.squirrelSillExit, 0.8, curve: Curves.easeIn),
      const Remove('squirrel'),
      const Pose(DogPose.lieDown, 1.8),

      const Phase(DogGameState.returningToIdle),
      const Turn(1),
      const Leap(LivingRoomPositions.dogJumpDown, height: 8, seconds: 0.5),
      const Pose(DogPose.idle),
      const WalkTo(LivingRoomPositions.returnPosition),
    ],
  );
}

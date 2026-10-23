import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../animations/dog_animations.dart';
import '../../dogs/dog_needs.dart';
import '../../models/dog_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/scene_state.dart';
import '../../scripting/script_step.dart';

/// The Kitchen: the glass on the counter, the treat cabinet, and dinner.
abstract final class KitchenScripts {
  static void _tapWobble(SpawnedObject glass, PropStart _, double t) => glass.rotation = math.sin(t * math.pi) * 0.25;
  static void _tipOver(SpawnedObject glass, PropStart _, double t) => glass.rotation = 0.35 * t;
  static void _tumble(SpawnedObject glass, PropStart _, double t) => glass.rotation = 0.35 + 1.2 * t;
  static void _land(SpawnedObject glass, PropStart _, double t) => glass.rotation = 1.55 + 0.05 * t;
  static void _eat(SpawnedObject food, PropStart _, double t) => food.fill = 1 - t;
  static void _cook(SpawnedObject dinner, PropStart _, double t) => dinner.progress = t;

  static double _rattle(double t) => math.sin(t * math.pi * 6).abs() * 0.04;
  static double _doorOpen(double t) => Curves.easeOut.transform(t);
  static double _doorClose(double t) => 1 - t;

  static final glassTrouble = () {
    final fall = sec(GameTimings.glassFall);
    final tap = sec(GameTimings.glassTap);
    return ActivityScript(
      firstPhase: DogGameState.glassTrouble,
      needs: const {Need.fun: 15},
      steps: [
        const Spawn('glass', ObjectKind.glass, KitchenPositions.glassSpawnPosition),

        // A. Notice the counter, trot over and look up.
        const TurnToward(KitchenPositions.glassCounterApproachPosition),
        const Pose(DogPose.lookUp),
        const Mark(DogMark.exclaim, 0.7),
        const WalkTo(KitchenPositions.glassCounterApproachPosition, endFacing: -1, endPose: DogPose.lookUp),
        const Wait(0.5),
        const Phase(DogGameState.glassClimbing),
        const Appear('glass'),
        const Focus('glass'),

        // B. Short legs take the stool up onto the counter; taller dogs just
        // stand up with their paws on the edge. Either way: tap, tap.
        ByBuild(
          shortLegs: Sequence([
            const Leap(KitchenPositions.glassOnStoolPosition, height: 8, seconds: 0.45),
            const Leap(KitchenPositions.glassCounterIdlePosition, height: 10, seconds: 0.5),
            const Turn(1),
            const Pose(DogPose.sniff, 0.8),
            const Pose(DogPose.paw),
            Parallel([const SwipePaw(), after(0.2, PropAnim('glass', 'wobble', tap, _tapWobble))]),
            Parallel([
              const SwipePaw(),
              after(0.2, MoveProp('glass', KitchenPositions.glassEdgePosition, tap, faceMovement: false)),
              after(0.2, PropAnim('glass', 'tip', tap, _tipOver)),
            ]),
          ]),
          tall: Sequence([
            const WalkTo(KitchenPositions.glassPawsUpPosition, endFacing: -1),
            const Pose(DogPose.pawsUp, 0.8),
            Parallel([const Pose(DogPose.pawsUp), after(0.2, PropAnim('glass', 'wobble', tap, _tapWobble))]),
            const Wait(0.3),
            Parallel([
              after(0.2, MoveProp('glass', KitchenPositions.glassEdgePosition, tap, faceMovement: false)),
              after(0.2, PropAnim('glass', 'tip', tap, _tipOver)),
            ]),
          ]),
        ),

        // D. Over the edge along a fixed path, a soft bonk, and a puff.
        const Phase(DogGameState.glassFalling),
        const Pose(DogPose.lookDown),
        MoveProp('glass', KitchenPositions.glassFallWaypointA, fall * 0.25, faceMovement: false),
        Parallel([
          MoveProp(
            'glass',
            KitchenPositions.glassFallWaypointB,
            fall * 0.35,
            curve: Curves.easeIn,
            faceMovement: false,
          ),
          PropAnim('glass', 'tumble', fall * 0.35, _tumble),
        ]),
        Parallel([
          MoveProp(
            'glass',
            KitchenPositions.glassLandingPosition,
            fall * 0.4,
            curve: Curves.easeIn,
            faceMovement: false,
          ),
          PropAnim('glass', 'land', fall * 0.4, _land),
        ]),
        const Effect(EffectKind.impact, KitchenPositions.glassLandingPosition, duration: 0.6),
        const Phase(DogGameState.glassReaction),
        const Pose(DogPose.surprised),
        // A harmless little bounce, then it vanishes in a puff (no shards).
        const MoveProp('glass', KitchenPositions.glassLandingPosition, 0.3, arc: 0.02, faceMovement: false),
        const Puff(KitchenPositions.glassLandingPosition),
        const PopAway('glass'),
        const Pose(DogPose.lookDown, 0.6),

        // E. Who, me?
        const Pose(DogPose.innocent, 1.6),
        const Phase(DogGameState.returningToIdle),
        ByBuild(
          shortLegs: Sequence([
            const Turn(-1),
            const Leap(KitchenPositions.glassOnStoolPosition, height: 6, seconds: 0.45),
            const Leap(KitchenPositions.glassHopDownPosition, height: 8, seconds: 0.45),
          ]),
          tall: const Sequence([]),
        ),
        const Pose(DogPose.idle),
        const WalkTo(KitchenPositions.glassDogReturnPosition),
      ],
    );
  }();

  static final treatTime = () {
    final door = sec(GameTimings.cabinetDoor);
    final satisfied = sec(GameTimings.satisfied);
    const scratchMarks = 'scratchMarks';
    return ActivityScript(
      firstPhase: DogGameState.treatTime,
      needs: const {Need.hunger: -15, Need.fun: 8},
      steps: [
        // A. Sniff out the right cabinet.
        const WalkTo(KitchenPositions.treatCabinetApproachPosition, endFacing: -1, endPose: DogPose.sniff),
        Effect(
          EffectKind.aroma,
          KitchenPositions.treatCabinetDoorPosition + const Offset(0.05, -0.07),
          duration: sec(GameTimings.sniff),
        ),
        Wait(sec(GameTimings.sniff)),
        const Pose(DogPose.idle),
        const Mark(DogMark.exclaim, 0.5),

        // B. Scratch, sniff, scratch; the cabinet rattles a little.
        const Phase(DogGameState.treatScratching),
        const WalkTo(KitchenPositions.treatScratchPosition, endFacing: -1),
        Repeat(
          GameTimings.scratchBursts,
          (i) => Sequence([
            const Pose(DogPose.scratch),
            Effect(
              EffectKind.scratches,
              KitchenPositions.treatCabinetDoorPosition + const Offset(0.02, -0.07),
              id: scratchMarks,
            ),
            SceneValue(SceneKeys.cabinetOpen, sec(GameTimings.scratchBurst), _rattle),
            const RemoveEffects(ids: [scratchMarks]),
            if (i < GameTimings.scratchBursts - 1) const Pose(DogPose.sniff, 0.5),
          ]),
        ),

        // C. The door creaks open and a treat pops out.
        const Phase(DogGameState.treatRevealing),
        const Pose(DogPose.idle),
        SceneValue(SceneKeys.cabinetOpen, door, _doorOpen),
        const Spawn('treat', ObjectKind.treat, KitchenPositions.treatSpawnPosition, layerBias: 0.02, focus: true),
        const Appear('treat'),
        const MoveProp('treat', KitchenPositions.treatRevealPosition, 0.5, arc: 0.03, faceMovement: false),
        Effect(EffectKind.sparkles, KitchenPositions.treatRevealPosition + const Offset(0, -0.02)),
        const Pose(DogPose.surprised),
        const Effect(EffectKind.hearts, Offset(0.02, -0.13), nearDog: true, duration: 1.0),
        const Wait(0.8),

        // D. Nom.
        const Phase(DogGameState.treatEating),
        const Parallel([
          WalkTo(KitchenPositions.treatEatingPosition, endFacing: -1),
          MoveProp('treat', KitchenPositions.treatServePosition, 0.5, faceMovement: false),
        ]),
        const Pose(DogPose.eat),
        PropAnim('treat', 'eat', sec(GameTimings.treatEating), _eat),
        const Remove('treat'),
        const RemoveEffects(all: true),
        const Pose(DogPose.satisfied),
        Effect(EffectKind.hearts, const Offset(0, -0.13), nearDog: true, duration: satisfied),
        Wait(satisfied),

        // E. Close up and head back.
        const Phase(DogGameState.returningToIdle),
        SceneValue(SceneKeys.cabinetOpen, door, _doorClose),
        const WalkTo(KitchenPositions.treatDogReturnPosition),
      ],
    );
  }();

  static final dinner = () {
    final sniff = sec(GameTimings.sniff);
    final cook = sec(GameTimings.dinnerCooking);
    final satisfied = sec(GameTimings.satisfied);
    return ActivityScript(
      firstPhase: DogGameState.dinnerTime,
      needs: const {Need.hunger: -30, Need.affection: 5},
      steps: [
        // A. Something smells good...
        const Phase(DogGameState.dinnerSniffing),
        const WalkTo(KitchenPositions.dinnerDogSniffPosition, endFacing: 1),
        const Effect(EffectKind.aroma, KitchenPositions.dinnerAromaPosition, id: 'aroma'),
        Pose(DogPose.sniff, sniff),
        const Pose(DogPose.lookUp),
        const Mark(DogMark.exclaim, 0.6),

        // B. Dinner goes on; he waits at a safe spot, well away from the
        // stove, and sits nicely.
        const Spawn('dinner', ObjectKind.drumstick, KitchenPositions.dinnerRawSpawnPosition, focus: true),
        const Parallel([
          Appear('dinner'),
          WalkTo(KitchenPositions.dinnerDogWatchPosition, endFacing: 1, endPose: DogPose.sit),
        ]),
        const MoveProp(
          'dinner',
          KitchenPositions.dinnerCookingPosition,
          0.5,
          curve: Curves.easeIn,
          faceMovement: false,
        ),

        // C. Roasting: steam, heat marks and a little timer; raw to golden.
        const Phase(DogGameState.dinnerCooking),
        const RemoveEffects(ids: ['aroma']),
        const Effect(EffectKind.steam, KitchenPositions.dinnerAromaPosition, id: 'steam'),
        const Effect(EffectKind.heat, KitchenPositions.stovePosition, id: 'heat'),
        Effect(EffectKind.timer, KitchenPositions.dinnerTimerPosition, id: 'timer', duration: cook + 0.3),
        Parallel([PropAnim('dinner', 'cook', cook, _cook), Pose(DogPose.beg, cook)]),
        const RemoveEffects(ids: ['heat', 'timer']),
        Effect(EffectKind.sparkles, KitchenPositions.dinnerCookingPosition + const Offset(0, -0.03)),
        const Pose(DogPose.wag, 0.8),

        // D. Onto a plate, and the plate onto the floor.
        const Phase(DogGameState.dinnerServing),
        const Spawn('plate', ObjectKind.plate, KitchenPositions.dinnerServingSpawnPosition, fill: 0),
        const Appear('plate'),
        const MoveProp('dinner', KitchenPositions.dinnerServingSpawnPosition, 0.6, arc: 0.06, faceMovement: false),
        const Remove('dinner'),
        const SetProp('plate', fill: 1), // The roasted drumstick now rides on the plate.
        const RemoveEffects(ids: ['steam'], kinds: [EffectKind.sparkles]),
        const Focus('plate'),
        const MoveProp('plate', KitchenPositions.dinnerServingMoveWaypoint, 0.45, faceMovement: false),
        const MoveProp('plate', KitchenPositions.dinnerServingPosition, 0.45, faceMovement: false),
        const Pose(DogPose.lookDown, 0.4),

        // E. Dinner.
        const Phase(DogGameState.dinnerEating),
        const WalkTo(KitchenPositions.dinnerDogEatingPosition, endFacing: -1),
        const Pose(DogPose.eat),
        PropAnim('plate', 'eat', sec(GameTimings.dinnerEating), _eat),
        const Pose(DogPose.satisfied),
        Effect(EffectKind.hearts, const Offset(0, -0.13), nearDog: true, duration: satisfied),
        Wait(satisfied),

        // F. One last sniff of the empty plate, a happy wag, and back.
        const Pose(DogPose.sniff, 0.8),
        const Pose(DogPose.happy),
        Parallel([Wait(sec(GameTimings.happy)), const PopAway('plate')]),
        const Phase(DogGameState.returningToIdle),
        const WalkTo(KitchenPositions.dinnerDogReturnPosition),
      ],
    );
  }();
}

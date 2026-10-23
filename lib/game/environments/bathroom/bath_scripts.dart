import 'dart:ui';

import '../../dogs/dog_needs.dart';
import '../../models/dog_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/scene_state.dart';
import '../../scripting/script_step.dart';

/// The Bath: a bubbly bath, a brush with the slicker brush, and a towel.
abstract final class BathScripts {
  static double _foamIn(double t) => t;
  static double _foamOut(double t) => 1 - t;

  static ScriptStep _hop(Offset to) => Leap(to, height: 20, seconds: sec(GameTimings.tubHop));

  static final bathTime = ActivityScript(
    firstPhase: DogGameState.walkingToBath,
    needs: const {Need.cleanliness: 35},
    steps: [
      const WalkTo(BathPositions.dogBathEntryPosition, endFacing: -1),

      const Phase(DogGameState.bathing),
      // The tub fills with foam, then the puppy hops in.
      const Puff(BathPositions.bathBubbleSpawnPosition),
      SceneValue(SceneKeys.tubFoam, sec(GameTimings.foam), _foamIn),
      _hop(BathPositions.dogBathPosition),

      const Pose(DogPose.relax),
      const Effect(EffectKind.bubbles, BathPositions.bathBubbleSpawnPosition),
      Effect(EffectKind.splash, BathPositions.dogBathPosition + const Offset(0, -0.05)),
      Wait(sec(GameTimings.bath)),

      // Bubbles pop, the puppy hops back out.
      const Puff(BathPositions.bathBubbleSpawnPosition),
      const FadeEffects(),
      const Turn(1),
      _hop(BathPositions.dogBathEntryPosition),
      const Pose(DogPose.idle),

      const Phase(DogGameState.returningToIdle),
      Parallel([
        SceneValue(SceneKeys.tubFoam, sec(GameTimings.foam), _foamOut),
        const WalkTo(BathPositions.dogBathReturnPosition),
      ]),
    ],
  );

  static final brushFur = ActivityScript(
    firstPhase: DogGameState.brushing,
    needs: const {Need.cleanliness: 15, Need.affection: 8},
    steps: [
      const Spawn('brush', ObjectKind.brush, BathPositions.brushSpawnPosition, facing: -1, layerBias: 0.1),
      const Appear('brush'),

      // The puppy settles facing the brush, which hops over to its back.
      const WalkTo(BathPositions.dogBrushPosition, endFacing: -1, endPose: DogPose.relax),
      const MoveProp('brush', BathPositions.brushStrokeStart, 0.6, arc: 0.06, faceMovement: false),

      const Effect(EffectKind.sparkles, BathPositions.brushSparklePosition),
      Repeat(
        GameTimings.brushStrokes,
        (i) => MoveProp(
          'brush',
          i.isEven ? BathPositions.brushStrokeEnd : BathPositions.brushStrokeStart,
          sec(GameTimings.brushStroke),
          faceMovement: false,
        ),
      ),

      const Parallel([PopAway('brush'), FadeEffects()]),
      Pose(DogPose.happy, sec(GameTimings.happy)),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(BathPositions.dogBrushReturnPosition),
    ],
  );

  static final towelDry = ActivityScript(
    firstPhase: DogGameState.drying,
    needs: const {Need.cleanliness: 10, Need.affection: 5},
    steps: [
      const WalkTo(BathPositions.dogDryPosition, endFacing: 1, endPose: DogPose.sit),
      const Spawn('towel', ObjectKind.towel, BathPositions.towelSpawnPosition, layerBias: 0.1),
      const Appear('towel'),

      // Rub-a-dub: the towel moves up and down over the puppy's head.
      const Pose(DogPose.relax),
      Repeat(
        GameTimings.towelRubs,
        (i) =>
            MoveProp('towel', BathPositions.towelRubPositions[i % 2], sec(GameTimings.towelRub), faceMovement: false),
      ),
      const MoveProp('towel', BathPositions.towelSpawnPosition, 0.3, faceMovement: false),

      // A big shake sends droplets flying.
      const Pose(DogPose.shake),
      Effect(EffectKind.droplets, BathPositions.dropletsPosition, duration: sec(GameTimings.shake)),
      Wait(sec(GameTimings.shake)),

      const PopAway('towel'),
      Pose(DogPose.happy, sec(GameTimings.happy)),

      const Phase(DogGameState.returningToIdle),
      const WalkTo(BathPositions.dogDryReturnPosition),
    ],
  );
}

import 'package:flutter/animation.dart';

import '../animations/dog_animations.dart';
import '../dogs/dog_needs.dart';
import '../dogs/reaction.dart';
import '../models/dog_game_state.dart';
import '../models/game_timings.dart';

/// Seconds in [d], for step durations taken from [GameTimings].
double sec(Duration d) => d.inMicroseconds / Duration.microsecondsPerSecond;

/// One instruction of an [ActivityScript], played by the `ActivityRunner`.
///
/// Steps are plain data. Props spawned by a script are referred to by a
/// script-local string id, so the same script can run any number of times.
sealed class ScriptStep {
  const ScriptStep();
}

/// A whole activity: the sub-state shown when it starts, its steps, and the
/// needs it changes when it plays through to the end.
class ActivityScript {
  const ActivityScript({required this.firstPhase, required this.steps, this.needs = const {}});

  final DogGameState firstPhase;
  final List<ScriptStep> steps;
  final Map<Need, double> needs;

  /// The steps as played, ending with [needs] applied.
  ScriptStep get body => Sequence([...steps, if (needs.isNotEmpty) ApplyNeeds(needs)]);
}

// -----------------------------------------------------------------------------
// Flow
// -----------------------------------------------------------------------------

/// Runs [steps] one after another; stops at the first cancelled one.
class Sequence extends ScriptStep {
  const Sequence(this.steps);

  final List<ScriptStep> steps;
}

/// Starts all [steps] at once and finishes when the slowest one does.
class Parallel extends ScriptStep {
  const Parallel(this.steps);

  final List<ScriptStep> steps;
}

/// Plays the step built by [builder] for i = 0 until [count].
class Repeat extends ScriptStep {
  const Repeat(this.count, this.builder);

  final int count;
  final ScriptStep Function(int i) builder;
}

/// [step], [seconds] later.
ScriptStep after(double seconds, ScriptStep step) => Sequence([Wait(seconds), step]);

class Wait extends ScriptStep {
  const Wait(this.seconds);

  final double seconds;
}

/// Switches the fine-grained [DogGameState] reported while busy.
class Phase extends ScriptStep {
  const Phase(this.state);

  final DogGameState state;
}

// -----------------------------------------------------------------------------
// The dog
// -----------------------------------------------------------------------------

/// Shows [pose], then holds it for [seconds] (0 = just switch).
class Pose extends ScriptStep {
  const Pose(this.pose, [this.seconds = 0]);

  final DogPose pose;
  final double seconds;
}

/// Walks to [target] (landing on it exactly), then turns to [endFacing].
class WalkTo extends ScriptStep {
  const WalkTo(this.target, {this.endFacing, this.endPose = DogPose.idle});

  final Offset target;
  final double? endFacing;
  final DogPose endPose;
}

class Turn extends ScriptStep {
  const Turn(this.facing);

  /// 1 = right, -1 = left.
  final double facing;
}

/// Turns to face [point], judged from where the dog is when the step runs.
class TurnToward extends ScriptStep {
  const TurnToward(this.point);

  final Offset point;
}

/// Moves the dog in its current pose; [arc] lifts it (dog units) mid-way.
class MoveDog extends ScriptStep {
  const MoveDog(this.target, this.seconds, {this.curve = Curves.easeInOut, this.arc = 0});

  final Offset target;
  final double seconds;
  final Curve curve;
  final double arc;
}

/// A playful leap to [target].
class Leap extends ScriptStep {
  const Leap(this.target, {this.height = 16, this.seconds});

  final Offset target;
  final double height;

  /// Defaults to [GameTimings.leap].
  final double? seconds;
}

/// One paw swipe (bat, swat).
class SwipePaw extends ScriptStep {
  const SwipePaw();
}

/// Puts [item] in the dog's mouth ([DogCarry.none] drops it).
class Carry extends ScriptStep {
  const Carry(this.item);

  final DogCarry item;
}

/// Plays [shortLegs] for low dogs (corgi, dachshund), [tall] for the rest.
class ByBuild extends ScriptStep {
  const ByBuild({required this.shortLegs, required this.tall});

  final ScriptStep shortLegs;
  final ScriptStep tall;
}

/// Shows [mark] over the dog's head for [seconds].
class Mark extends ScriptStep {
  const Mark(this.mark, this.seconds);

  final DogMark mark;
  final double seconds;
}

/// Shows how the dog feels about the activity for [seconds]. With no
/// [outcome] the runner asks the current dog's persona about [thingId].
class React extends ScriptStep {
  const React(this.seconds, {this.outcome, this.thingId});

  final double seconds;
  final ReactionOutcome? outcome;
  final String? thingId;
}

// -----------------------------------------------------------------------------
// Props
// -----------------------------------------------------------------------------

/// Adds a prop or critter to the scene under the script-local [id].
class Spawn extends ScriptStep {
  const Spawn(
    this.id,
    this.kind,
    this.at, {
    this.facing = 1,
    this.layerBias = 0,
    this.focus = false,
    this.fill = 1,
    this.airborne = false,
  });

  final String id;
  final ObjectKind kind;
  final Offset at;
  final double facing;
  final double layerBias;

  /// Whether the dog's eyes follow it from now on.
  final bool focus;
  final double fill;
  final bool airborne;
}

/// Plays the spawn-in animation.
class Appear extends ScriptStep {
  const Appear(this.id);

  final String id;
}

/// Pops and fades the prop out, then removes it.
class PopAway extends ScriptStep {
  const PopAway(this.id);

  final String id;
}

/// Removes the prop at once (it already left the stage).
class Remove extends ScriptStep {
  const Remove(this.id);

  final String id;
}

/// Points the dog's gaze at a prop, or straight ahead when [id] is null.
class Focus extends ScriptStep {
  const Focus(this.id);

  final String? id;
}

/// Changes a prop's flags at once.
class SetProp extends ScriptStep {
  const SetProp(this.id, {this.fill, this.airborne, this.progress});

  final String id;
  final double? fill;
  final bool? airborne;

  /// Generic 0..1 state (cooked, mid-quack...).
  final double? progress;
}

/// Moves a prop along a straight segment, optionally hopping ([arc]) or
/// bobbing ([wobble]), both in normalized height. With [rollRadius] it spins
/// like a ball rolling along the floor.
class MoveProp extends ScriptStep {
  const MoveProp(
    this.id,
    this.to,
    this.seconds, {
    this.curve = Curves.easeInOut,
    this.arc = 0,
    this.wobble = 0,
    this.faceMovement = true,
    this.rollRadius,
  });

  final String id;
  final Offset to;
  final double seconds;
  final Curve curve;
  final double arc;
  final double wobble;
  final bool faceMovement;
  final double? rollRadius;
}

/// What a prop looked like when a [PropAnim] started.
typedef PropStart = ({Offset position, double rotation});

/// A named, custom prop animation (fill draining, cooking, wobbling).
class PropAnim extends ScriptStep {
  const PropAnim(this.id, this.name, this.seconds, this.tween);

  final String id;
  final String name;
  final double seconds;
  final void Function(SpawnedObject prop, PropStart start, double t) tween;
}

/// Animates a named value of the scene's fixed furniture (tub foam, cabinet
/// door) as `value(t)` for t in 0..1.
class SceneValue extends ScriptStep {
  const SceneValue(this.key, this.seconds, this.value);

  final String key;
  final double seconds;
  final double Function(double t) value;
}

/// Sets a named scene value at once (a mood, which way someone faces).
class SetValue extends ScriptStep {
  const SetValue(this.key, this.value);

  final String key;
  final double value;
}

/// Tweens a named scene value from wherever it is now to [to].
class TweenValue extends ScriptStep {
  const TweenValue(this.key, this.to, this.seconds, {this.curve = Curves.easeInOut});

  final String key;
  final double to;
  final double seconds;
  final Curve curve;
}

// -----------------------------------------------------------------------------
// Effects
// -----------------------------------------------------------------------------

/// Adds a sketch effect at [anchor] (or at the dog plus [anchor] when
/// [nearDog]). [id] lets a later [RemoveEffects] take it away.
class Effect extends ScriptStep {
  const Effect(this.kind, this.anchor, {this.id, this.duration, this.nearDog = false});

  final EffectKind kind;
  final Offset anchor;
  final String? id;
  final double? duration;
  final bool nearDog;
}

/// A quick puff of dust.
class Puff extends ScriptStep {
  const Puff(this.at);

  final Offset at;
}

/// Removes effects at once: those named in [ids], of [kinds], or [all].
class RemoveEffects extends ScriptStep {
  const RemoveEffects({this.ids = const [], this.kinds = const [], this.all = false});

  final List<String> ids;
  final List<EffectKind> kinds;
  final bool all;
}

/// Fades every running effect out, then removes them.
class FadeEffects extends ScriptStep {
  const FadeEffects();
}

// -----------------------------------------------------------------------------
// Player and care
// -----------------------------------------------------------------------------

enum PlayerInputKind { tap, drag, hold }

/// Waits for the player to [kind] (sent to the runner by the UI), or for
/// [timeout] seconds, whichever comes first. Never blocks the script for
/// good: timing out simply carries on.
class PlayerInput extends ScriptStep {
  const PlayerInput(this.kind, {required this.timeout});

  final PlayerInputKind kind;
  final double timeout;
}

/// Changes the current dog's needs.
class ApplyNeeds extends ScriptStep {
  const ApplyNeeds(this.deltas);

  final Map<Need, double> deltas;
}

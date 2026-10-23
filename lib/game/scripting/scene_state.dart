import 'dart:math' as math;
import 'dart:ui';

import '../animations/dog_animations.dart';
import '../dogs/reaction.dart';
import '../models/dog_game_state.dart';

/// Keys of [SceneState.values] for the scenes' fixed, animated furniture.
abstract final class SceneKeys {
  static const tubFoam = 'bath.tubFoam';
  static const cabinetOpen = 'kitchen.cabinetOpen';

  /// 0..1 how far the garden mound has been dug out.
  static const moundDug = 'outdoors.moundDug';

  /// 1 while the dog is out of sight (e.g. inside the wardrobe).
  static const dogHidden = 'dog.hidden';
}

/// Everything on stage that scripts move: the dog, temporary props and
/// critters, effects, and animated furniture values.
///
/// It holds no timing of its own; the `ActivityRunner` changes it over time
/// and [advance] only updates the ambient bits (gaze, critter loops).
class SceneState {
  SceneState(this.dogPosition);

  Offset dogPosition;

  /// 1 = facing right, -1 = facing left; values between are mid-turn.
  double facing = 1;
  DogPose _pose = DogPose.idle;
  double time = 0;
  double poseTime = 0;
  double walkPhase = 0;
  double gaze = 0;
  double gazeY = 0;
  double swipe = 0;
  double lift = 0;
  DogMark mark = DogMark.none;
  DogCarry carry = DogCarry.none;
  ReactionOutcome? reaction;

  final objects = <SpawnedObject>[];
  final effects = <SceneEffect>[];
  final values = <String, double>{};
  final _props = <String, SpawnedObject>{};
  final _effectIds = <String, SceneEffect>{};

  /// What the dog's eyes follow.
  SpawnedObject? focus;

  DogPose get pose => _pose;

  void setPose(DogPose pose) {
    if (_pose != pose) poseTime = 0;
    _pose = pose;
    if (pose != DogPose.playBow && pose != DogPose.paw) swipe = 0;
  }

  double value(String key) => values[key] ?? 0;

  SpawnedObject? prop(String id) => _props[id];

  SpawnedObject spawn(String id, ObjectKind kind, Offset at, {double facing = 1, double layerBias = 0}) {
    final object = SpawnedObject(kind, at, facing: facing)..layerBias = layerBias;
    final old = _props[id];
    if (old != null) remove(old);
    _props[id] = object;
    objects.add(object);
    return object;
  }

  void remove(SpawnedObject object) {
    objects.remove(object);
    _props.removeWhere((_, o) => o == object);
    if (focus == object) focus = null;
  }

  SceneEffect addEffect(EffectKind kind, Offset anchor, {double? duration, String? id}) {
    final effect = SceneEffect(kind, anchor, duration: duration);
    effects.add(effect);
    if (id != null) _effectIds[id] = effect;
    return effect;
  }

  SceneEffect? effect(String id) => _effectIds[id];

  void removeEffects(bool Function(SceneEffect e) test) {
    effects.removeWhere(test);
    _effectIds.removeWhere((_, e) => !effects.contains(e));
  }

  /// Ambient per-frame updates, before any script step runs this frame.
  void advance(double dt, double walkStepRate) {
    time += dt;
    poseTime += dt;
    if (_pose == DogPose.walk) walkPhase += dt * walkStepRate;
    _updateGaze(dt);
    for (final o in objects) {
      o.phase += dt;
    }
    for (final e in effects) {
      e.time += dt;
    }
    removeEffects((e) => e.duration != null && e.time >= e.duration!);
  }

  void _updateGaze(double dt) {
    final f = focus;
    var gx = 0.0, gy = 0.0;
    if (f != null) {
      gx = ((f.position.dx - dogPosition.dx) * facing.sign / 0.18).clamp(-1.0, 1.0);
      gy = ((f.position.dy - (dogPosition.dy - 0.09)) / 0.12).clamp(-1.0, 1.0);
    }
    final k = math.min(1.0, dt * 10);
    gaze += (gx - gaze) * k;
    gazeY += (gy - gazeY) * k;
  }

  /// Removes every temporary object and effect and resets the pose.
  void clearTransient() {
    objects.clear();
    effects.clear();
    _props.clear();
    _effectIds.clear();
    values.clear();
    focus = null;
    swipe = 0;
    lift = 0;
    mark = DogMark.none;
    carry = DogCarry.none;
    reaction = null;
    setPose(DogPose.idle);
  }
}

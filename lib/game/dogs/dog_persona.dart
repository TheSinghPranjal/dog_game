import 'dart:ui' show lerpDouble;

import '../environments/environment_id.dart';
import 'reaction.dart';
import 'thing_tastes.dart';

/// The little habit a dog shows between walks.
enum IdleHabit { sniff, pantAndBlink, chinOnPaws, hideAndPeek, zoomies, softWoof, scratchEar }

/// A dog's personality, as data. Every behaviour difference between dogs
/// comes from these numbers, never from per-dog code.
class DogPersona {
  const DogPersona({
    required this.tag,
    required this.energy,
    required this.curiosity,
    required this.appetite,
    required this.tidiness,
    required this.cuddliness,
    required this.idleHabit,
    required this.favourite,
    this.tasteOverrides = const {},
  });

  /// Short handwritten tag, e.g. "Lazy foodie".
  final String tag;
  final double energy;
  final double curiosity;
  final double appetite;
  final double tidiness;
  final double cuddliness;
  final IdleHabit idleHabit;
  final EnvironmentId favourite;

  /// Fixed reactions that ignore the trait thresholds, by thing id.
  final Map<String, ReactionOutcome> tasteOverrides;

  double trait(Trait t) => switch (t) {
    Trait.energy => energy,
    Trait.curiosity => curiosity,
    Trait.appetite => appetite,
    Trait.tidiness => tidiness,
    Trait.cuddliness => cuddliness,
  };

  double _lerp(double a, double b, double t) => lerpDouble(a, b, t.clamp(0.0, 1.0))!;

  // Energy.
  /// Walk speed multiplier, 0.75x (sleepy) to 1.3x (bouncy).
  double get walkSpeedScale => _lerp(0.75, 1.3, energy);

  /// Multiplier for idle pauses; lively dogs rest less.
  double get idlePauseScale => _lerp(1.4, 0.7, energy);

  /// Chance per idle loop of a burst of zoomies.
  double get zoomiesChance => 0.35 * energy * energy;

  // Curiosity.
  /// Chance per idle loop of wandering over to inspect a prop.
  double get inspectChance => 0.5 * curiosity;

  /// Seconds before the dog notices something new.
  double get noticeDelay => _lerp(1.2, 0.3, curiosity);

  // Appetite.
  /// Hunger gained per minute of play.
  double get hungerPerMinute => _lerp(0.3, 1.0, appetite);

  /// Eating animation length multiplier (Biscuit eats twice as long).
  double get eatScale => 1 + 2 * (appetite - 0.5).clamp(0.0, 0.5);

  /// Whether the dog begs when near food props.
  bool get begsForFood => appetite >= 0.8;

  // Tidiness.
  /// Cleanliness lost per minute of play.
  double get dirtPerMinute => _lerp(1.0, 0.3, tidiness);

  /// Chance per idle loop of a quick ear scratch or paw clean.
  double get groomChance => 0.6 * tidiness;

  // Cuddliness.
  /// Affection gained per stroke.
  double get affectionPerPet => _lerp(1, 4, cuddliness);

  /// Whether the dog walks toward the player's finger.
  bool get seeksFinger => cuddliness >= 0.6;

  /// Whether petting shows heart marks and a faster wag.
  bool get showsHearts => cuddliness >= 0.5;

  /// How this dog feels about [thingId]: an override if there is one, else
  /// the thing's [ThingTaste] read against these traits.
  ReactionOutcome reactionTo(String thingId) => tasteOverrides[thingId] ?? ThingTastes.of(thingId).outcomeFor(trait);
}

/// The seven personas from the design table.
abstract final class DogPersonas {
  static const maple = DogPersona(
    tag: 'Curious explorer',
    energy: .7,
    curiosity: .9,
    appetite: .5,
    tidiness: .5,
    cuddliness: .6,
    idleHabit: IdleHabit.sniff,
    favourite: EnvironmentId.park,
  );

  static const buddy = DogPersona(
    tag: 'Sweet all-rounder',
    energy: .5,
    curiosity: .5,
    appetite: .5,
    tidiness: .5,
    cuddliness: .7,
    idleHabit: IdleHabit.pantAndBlink,
    favourite: EnvironmentId.livingArea,
  );

  static const biscuit = DogPersona(
    tag: 'Lazy foodie',
    energy: .2,
    curiosity: .4,
    appetite: 1.0,
    tidiness: .3,
    cuddliness: .8,
    idleHabit: IdleHabit.chinOnPaws,
    favourite: EnvironmentId.kitchen,
  );

  static const luna = DogPersona(
    tag: 'Quiet night dog',
    energy: .5,
    curiosity: .6,
    appetite: .4,
    tidiness: .7,
    cuddliness: .3,
    idleHabit: IdleHabit.hideAndPeek,
    favourite: EnvironmentId.livingRoom,
  );

  static const pepper = DogPersona(
    tag: 'Mischief zoomies',
    energy: .9,
    curiosity: .8,
    appetite: .6,
    tidiness: .2,
    cuddliness: .5,
    idleHabit: IdleHabit.zoomies,
    favourite: EnvironmentId.bedroom,
  );

  static const snowball = DogPersona(
    tag: 'Gentle cloud',
    energy: .3,
    curiosity: .3,
    appetite: .5,
    tidiness: 1.0,
    cuddliness: .4,
    idleHabit: IdleHabit.softWoof,
    favourite: EnvironmentId.bathroom,
  );

  static const ziggy = DogPersona(
    tag: 'Odd little rocket',
    energy: .8,
    curiosity: .7,
    appetite: .5,
    tidiness: .6,
    cuddliness: .9,
    idleHabit: IdleHabit.scratchEar,
    favourite: EnvironmentId.garden,
  );
}

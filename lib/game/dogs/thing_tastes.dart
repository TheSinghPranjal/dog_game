import 'reaction.dart';

/// Which trait decides each thing's reaction, by thing id. Things not
/// listed get a neutral taste (curiosity), so every dog is at least "fine".
abstract final class ThingTastes {
  static const _neutral = ThingTaste(Trait.curiosity, lovesAt: 2, nopeAt: -1);

  static const _tastes = <String, ThingTaste>{
    // Home.
    'feed': ThingTaste(Trait.appetite),
    'fetch': ThingTaste(Trait.energy),
    'chaseSquirrel': ThingTaste(Trait.curiosity),
    // Bathroom.
    'bathTime': ThingTaste(Trait.tidiness),
    'brushFur': ThingTaste(Trait.cuddliness),
    'towelDry': ThingTaste(Trait.tidiness),
    // Outdoors.
    'treeSquirrel': ThingTaste(Trait.curiosity),
    'dig': ThingTaste(Trait.tidiness, inverted: true),
    'frisbee': ThingTaste(Trait.energy),
    // Kitchen. Knocking a glass over delights the messiest dogs.
    'glassTrouble': ThingTaste(Trait.tidiness, inverted: true),
    'treatTime': ThingTaste(Trait.appetite),
    'dinner': ThingTaste(Trait.appetite),
    // Bedroom.
    'closetHide': ThingTaste(Trait.curiosity),
    'slipper': ThingTaste(Trait.tidiness, inverted: true),
    'pillowJump': ThingTaste(Trait.energy),
    // Living room.
    'mail': ThingTaste(Trait.curiosity),
    'wag': ThingTaste(Trait.cuddliness),
    'windowWatch': ThingTaste(Trait.curiosity),
    // Park.
    'duckPond': ThingTaste(Trait.curiosity),
    'leafPile': ThingTaste(Trait.energy),
    'benchPigeon': ThingTaste(Trait.energy),
    // The universal favourite.
    'cardboardBox': ThingTaste.universal(),
  };

  static ThingTaste of(String thingId) => _tastes[thingId] ?? _neutral;
}

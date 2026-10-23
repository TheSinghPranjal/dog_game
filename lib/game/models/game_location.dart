import 'dart:ui';

import 'activity_definition.dart';
import 'game_positions.dart';

enum GameLocation { home, kitchen, bath, outdoors, bedroom, livingRoom, park }

/// Everything that differs between locations, as data.
class LocationConfig {
  const LocationConfig({
    required this.location,
    required this.title,
    required this.greeting,
    required this.idlePositions,
    required this.walkArea,
    required this.activities,
    this.flourish = const WanderStep.habit(),
  });

  final GameLocation location;
  final String title;

  /// Small handwritten line shown at the top of the screen.
  final String greeting;

  /// Idle spots A, B and C. B is where the dog starts and returns to.
  final List<Offset> idlePositions;

  /// Region (normalized) that idle and start positions must stay inside.
  final Rect walkArea;
  final List<ActivityDefinition> activities;

  /// The little idle habit the puppy shows between walks (e.g. sniffing in
  /// the kitchen).
  final WanderStep flourish;

  Offset get startPosition => idlePositions[1];
  Offset get returnPosition => idlePositions[1];

  /// Deterministic idle routine; starts and restarts at [startPosition].
  List<WanderStep> get wanderRoutine => [
    const WanderStep.pause(2.2),
    const WanderStep.habit(),
    WanderStep.walk(idlePositions[0]),
    const WanderStep.pause(1.8),
    WanderStep.walk(idlePositions[1]),
    const WanderStep.pause(1.4),
    WanderStep.walk(idlePositions[2]),
    const WanderStep.pause(2.0),
    flourish,
    WanderStep.walk(idlePositions[1]),
  ];
}

abstract final class Locations {
  static const home = LocationConfig(
    location: GameLocation.home,
    title: 'Home',
    greeting: 'Hello, Buddy!',
    idlePositions: [HomePositions.idlePositionA, HomePositions.idlePositionB, HomePositions.idlePositionC],
    walkArea: Rect.fromLTRB(0.3, 0.70, 0.7, 0.78),
    activities: [
      ActivityDefinition(DogActivity.feed, 'Feed', 'Feed the dog'),
      ActivityDefinition(DogActivity.fetch, 'Fetch', 'Play fetch'),
      ActivityDefinition(DogActivity.chaseSquirrel, 'Squirrel', 'Chase the squirrel'),
    ],
  );

  static const kitchen = LocationConfig(
    location: GameLocation.kitchen,
    title: 'Kitchen',
    greeting: "What's cooking, Buddy?",
    idlePositions: [KitchenPositions.idlePositionA, KitchenPositions.idlePositionB, KitchenPositions.idlePositionC],
    walkArea: Rect.fromLTRB(0.28, 0.70, 0.62, 0.78),
    flourish: WanderStep.sniff(1.6),
    activities: [
      ActivityDefinition(DogActivity.glassTrouble, 'Glass', 'Glass trouble', accent: 0xFFE4ECFB),
      ActivityDefinition(DogActivity.treatTime, 'Treat', 'Treat time', accent: 0xFFFBD9D2),
      ActivityDefinition(DogActivity.dinner, 'Dinner', 'Dinner time', accent: 0xFFFDE6C8),
    ],
  );

  static const bath = LocationConfig(
    location: GameLocation.bath,
    title: 'Bath',
    greeting: 'Splish, splash!',
    idlePositions: [BathPositions.idlePositionA, BathPositions.idlePositionB, BathPositions.idlePositionC],
    walkArea: Rect.fromLTRB(0.48, 0.70, 0.82, 0.78),
    activities: [
      ActivityDefinition(DogActivity.bathTime, 'Bath', 'Bath time'),
      ActivityDefinition(DogActivity.brushFur, 'Brush', 'Brush his fur'),
      ActivityDefinition(DogActivity.towelDry, 'Towel', 'Towel dry'),
    ],
  );

  static const outdoors = LocationConfig(
    location: GameLocation.outdoors,
    title: 'Outdoors',
    greeting: "Let's explore!",
    idlePositions: [OutdoorPositions.idlePositionA, OutdoorPositions.idlePositionB, OutdoorPositions.idlePositionC],
    walkArea: Rect.fromLTRB(0.4, 0.70, 0.74, 0.78),
    activities: [
      ActivityDefinition(DogActivity.treeSquirrel, 'Squirrel', 'Chase the squirrel up the tree'),
      ActivityDefinition(DogActivity.dig, 'Dig', 'Dig up a bone'),
      ActivityDefinition(DogActivity.frisbee, 'Frisbee', 'Catch the frisbee'),
    ],
  );

  static const bedroom = LocationConfig(
    location: GameLocation.bedroom,
    title: 'Bedroom',
    greeting: 'Shh… it\'s his room!',
    idlePositions: [BedroomPositions.idlePositionA, BedroomPositions.idlePositionB, BedroomPositions.idlePositionC],
    walkArea: Rect.fromLTRB(0.28, 0.70, 0.66, 0.78),
    activities: [
      ActivityDefinition(DogActivity.closetHide, 'Closet', 'Hide in the closet', accent: 0xFFF3DDBF),
      ActivityDefinition(DogActivity.slipper, 'Slipper', 'Grab the slipper', accent: 0xFFFBD9E6),
      ActivityDefinition(DogActivity.pillowJump, 'Pillow', 'Jump on his pillow', accent: 0xFFDDEBFB),
    ],
  );

  static const livingRoom = LocationConfig(
    location: GameLocation.livingRoom,
    title: 'Living',
    greeting: 'Cozy time together!',
    idlePositions: [
      LivingRoomPositions.idlePositionA,
      LivingRoomPositions.idlePositionB,
      LivingRoomPositions.idlePositionC,
    ],
    walkArea: Rect.fromLTRB(0.38, 0.70, 0.68, 0.78),
    activities: [
      ActivityDefinition(DogActivity.mail, 'Mail', 'Woof at the mail slot', accent: 0xFFDDF0FB),
      ActivityDefinition(DogActivity.wag, 'Wag', 'Pet him and watch him wag', accent: 0xFFFBD9E6),
      ActivityDefinition(DogActivity.windowWatch, 'Window', 'Watch the squirrel out the window', accent: 0xFFE2F2EA),
    ],
  );

  static const park = LocationConfig(
    location: GameLocation.park,
    title: 'Park',
    greeting: 'A day at the park!',
    idlePositions: [ParkPositions.idlePositionA, ParkPositions.idlePositionB, ParkPositions.idlePositionC],
    walkArea: Rect.fromLTRB(0.28, 0.70, 0.58, 0.78),
    flourish: WanderStep.sniff(1.4),
    activities: [
      ActivityDefinition(DogActivity.duckPond, 'Ducks', 'Visit the ducks', accent: 0xFFDDF0FB),
      ActivityDefinition(DogActivity.leafPile, 'Leaves', 'Jump in the leaves', accent: 0xFFFDE6C8),
      ActivityDefinition(DogActivity.benchPigeon, 'Pigeon', 'Sneak up on the pigeon', accent: 0xFFE8E6F2),
    ],
  );

  static LocationConfig of(GameLocation location) => switch (location) {
    GameLocation.home => home,
    GameLocation.kitchen => kitchen,
    GameLocation.bath => bath,
    GameLocation.outdoors => outdoors,
    GameLocation.bedroom => bedroom,
    GameLocation.livingRoom => livingRoom,
    GameLocation.park => park,
  };
}

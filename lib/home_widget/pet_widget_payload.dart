import '../game/models/activity_definition.dart';
import '../game/models/game_location.dart';

/// The small amount of state the home-screen widget shows. The widget is a
/// presentation and launch surface, not a second game, so this is all it
/// gets: no per-frame animation state.
class PetWidgetPayload {
  const PetWidgetPayload({required this.pose, required this.location, required this.updatedAt, this.lastInteraction});

  /// Bump when the stored keys change; native readers ignore newer schemas.
  static const schemaVersion = 1;

  factory PetWidgetPayload.from({required GameLocation location, DogActivity? completed, DateTime? now}) =>
      PetWidgetPayload(
        pose: completed == null ? 'idle' : 'happy',
        location: Locations.of(location).title,
        lastInteraction: completed == null ? null : interactionLabel(completed),
        updatedAt: now ?? DateTime.now(),
      );

  /// Pose name matching the widget frame assets (`widget_puppy_<pose>`).
  final String pose;
  final String location;
  final String? lastInteraction;
  final DateTime updatedAt;

  static String interactionLabel(DogActivity activity) => switch (activity) {
    DogActivity.feed => 'Yum! Thanks for dinner!',
    DogActivity.fetch => 'Fetch is the best game!',
    DogActivity.chaseSquirrel => 'That squirrel was fast!',
    DogActivity.bathTime => 'Squeaky clean!',
    DogActivity.brushFur => 'So soft and fluffy!',
    DogActivity.towelDry => 'All dry and cozy!',
    DogActivity.treeSquirrel => 'Woof! Up the tree it went!',
    DogActivity.dig => 'I found a bone!',
    DogActivity.frisbee => 'I caught the frisbee!',
    DogActivity.glassTrouble => 'Oops... who, me?',
    DogActivity.treatTime => 'Found the secret treats!',
    DogActivity.dinner => 'Best dinner ever!',
    DogActivity.closetHide => 'Peekaboo! You found me!',
    DogActivity.slipper => 'I only borrowed the slipper!',
    DogActivity.pillowJump => 'Best. Pillow. Ever.',
    DogActivity.mail => 'Woof woof! I guarded the door!',
    DogActivity.wag => 'Wag wag... love you!',
    DogActivity.windowWatch => 'I watched the squirrel!',
    DogActivity.duckPond => 'Quack! So loud!',
    DogActivity.leafPile => 'Whee! I found a stick!',
    DogActivity.benchPigeon => 'The pigeon waved bye!',
  };

  Map<String, Object?> toMap() => {
    'schemaVersion': schemaVersion,
    'pose': pose,
    'location': location,
    'lastInteraction': lastInteraction,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };
}

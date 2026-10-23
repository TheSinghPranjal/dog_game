import '../dogs/dog_profile.dart';
import '../environments/environment_id.dart';

/// Unlocks once the player has earned [stars] friendship stars in total
/// (across every dog). Zero means unlocked from the start.
class UnlockRule {
  const UnlockRule(this.stars);

  static const always = UnlockRule(0);

  final int stars;

  bool isMet(int totalStars) => totalStars >= stars;
}

/// Every unlock threshold, in one place for easy tuning.
abstract final class UnlockThresholds {
  static const dogs = <DogId, UnlockRule>{
    DogId.maple: UnlockRule.always,
    DogId.buddy: UnlockRule.always,
    DogId.biscuit: UnlockRule.always,
    DogId.luna: UnlockRule.always,
    DogId.pepper: UnlockRule.always,
    DogId.snowball: UnlockRule(10),
    DogId.ziggy: UnlockRule(12),
  };

  static const environments = <EnvironmentId, UnlockRule>{
    EnvironmentId.livingArea: UnlockRule.always,
    EnvironmentId.kitchen: UnlockRule.always,
    EnvironmentId.bathroom: UnlockRule.always,
    EnvironmentId.bedroom: UnlockRule(1),
    EnvironmentId.park: UnlockRule(2),
    EnvironmentId.rooftop: UnlockRule(4),
    EnvironmentId.car: UnlockRule(6),
    EnvironmentId.garden: UnlockRule.always,
    EnvironmentId.livingRoom: UnlockRule.always,
  };

  static UnlockRule dog(DogId id) => dogs[id]!;

  static UnlockRule environment(EnvironmentId id) => environments[id]!;
}

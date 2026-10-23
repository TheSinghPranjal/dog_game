import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/dogs/dog_persona.dart';
import 'package:dog_game/game/dogs/dog_profile.dart';
import 'package:dog_game/game/dogs/selected_dog.dart';
import 'package:dog_game/game/environments/environment_id.dart';
import 'package:dog_game/game/models/dog_look.dart';
import 'package:dog_game/game/save/game_save.dart';
import 'package:dog_game/game/save/game_store.dart';

GameSave _withStars(int stars) {
  final save = GameSave();
  // Spread over two dogs to show stars count across every dog.
  save.dog(DogId.maple).friendship = (stars / 2).ceilToDouble().clamp(0, 5);
  save.dog(DogId.buddy).friendship = (stars - save.dog(DogId.maple).stars).toDouble().clamp(0, 5);
  return save;
}

void main() {
  test('dogs unlock at their thresholds', () {
    const starters = {DogId.maple, DogId.buddy, DogId.biscuit, DogId.luna, DogId.pepper};
    const expected = <int, Set<DogId>>{
      0: starters,
      9: starters,
      10: {...starters, DogId.snowball},
    };
    for (final MapEntry(key: stars, value: dogs) in expected.entries) {
      final save = _withStars(stars);
      expect(save.totalStars, stars);
      expect(DogId.values.where(save.isDogUnlocked).toSet(), dogs, reason: '$stars stars');
    }
    // Twelve stars need a third dog's friendship.
    final all = _withStars(10)..dog(DogId.biscuit).friendship = 2;
    expect(DogId.values.every(all.isDogUnlocked), isTrue);
  });

  test('environments unlock at their thresholds', () {
    const open = {
      EnvironmentId.livingArea,
      EnvironmentId.kitchen,
      EnvironmentId.bathroom,
      EnvironmentId.garden,
      EnvironmentId.livingRoom,
    };
    final expected = <int, Set<EnvironmentId>>{
      0: open,
      1: {...open, EnvironmentId.bedroom},
      2: {...open, EnvironmentId.bedroom, EnvironmentId.park},
      4: {...EnvironmentId.values}..remove(EnvironmentId.car),
      6: {...EnvironmentId.values},
    };
    for (final MapEntry(key: stars, value: places) in expected.entries) {
      expect(EnvironmentId.values.where(_withStars(stars).isEnvironmentUnlocked).toSet(), places, reason: '$stars');
    }
  });

  test('locked dogs cannot be selected', () {
    final store = GameStore();
    final selected = SelectedDog(store: store);
    // Buddy is unlocked from the start.
    expect(selected.select(DogProfiles.buddy), isTrue);
    expect(store.save.selectedDog, DogId.buddy);

    // A profile whose dog is still locked is refused.
    const locked = DogProfile(
      id: DogId.ziggy,
      name: 'Ziggy',
      look: DogLook.dachshund,
      persona: DogPersonas.ziggy,
      greetings: [],
    );
    expect(selected.select(locked), isFalse);
    expect(selected.value, DogProfiles.buddy);
    expect(store.save.selectedDog, DogId.buddy);
  });
}

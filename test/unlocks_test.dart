import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/dogs/dog_profile.dart';
import 'package:dog_game/game/dogs/selected_dog.dart';
import 'package:dog_game/game/environments/environment_id.dart';
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
  test('every dog is playable from the start', () {
    expect(DogId.values.every(GameSave().isDogUnlocked), isTrue);
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

  test('any dog can be selected', () {
    final store = GameStore();
    final selected = SelectedDog(store: store);
    for (final dog in DogProfiles.all) {
      expect(selected.select(dog), isTrue, reason: dog.name);
      expect(store.save.selectedDog, dog.id);
    }
  });
}

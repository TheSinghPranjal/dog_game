import 'package:flutter/foundation.dart';

import '../save/game_store.dart';
import 'dog_profile.dart';

/// The dog the player is caring for, shared across the app and saved.
final selectedDog = SelectedDog();

class SelectedDog extends ValueNotifier<DogProfile> {
  SelectedDog({GameStore? store}) : _store = store ?? GameStore.instance, super(DogProfiles.maple);

  final GameStore _store;

  /// Picks up the saved choice; call after [GameStore.load].
  void syncFromSave() {
    final saved = DogProfiles.byId(_store.save.selectedDog);
    if (saved != null) value = saved;
  }

  /// Selects [dog] unless she is still locked. Returns whether she is now
  /// the selected dog.
  bool select(DogProfile dog) {
    if (dog == value) return true;
    if (!_store.save.isDogUnlocked(dog.id)) return false;
    value = dog;
    _store.update((save) => save.selectedDog = dog.id);
    return true;
  }
}

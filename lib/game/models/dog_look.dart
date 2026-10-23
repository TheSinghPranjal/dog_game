import 'package:flutter/foundation.dart';

import '../dogs/dog_profile.dart';
import '../dogs/selected_dog.dart';

/// The dogs' drawing styles; each [DogProfile] has one.
enum DogLook {
  golden('Golden Retriever'),
  lab('Chocolate Lab'),
  corgi('Corgi'),
  husky('Husky'),
  terrier('Wire Terrier'),
  samoyed('Samoyed'),
  dachshund('Dachshund');

  const DogLook(this.label);

  final String label;

  /// Long and low on short legs: these dogs use the kitchen stool.
  bool get shortLegs => this == corgi || this == dachshund;
}

/// The selected dog's look, for painters and the look carousel. The
/// selected dog ([selectedDog]) is the source of truth and is what gets
/// saved; changing this picks the dog with that look.
final dogLook = DogLookSetting();

class DogLookSetting extends ValueNotifier<DogLook> {
  DogLookSetting() : super(selectedDog.value.look) {
    selectedDog.addListener(() => value = selectedDog.value.look);
    addListener(() {
      if (selectedDog.value.look == value) return;
      // A locked dog's look can't be chosen; snap back to the selected dog.
      if (!selectedDog.select(DogProfiles.forLook(value))) value = selectedDog.value.look;
    });
  }

  void select(DogLook look) => value = look;
}

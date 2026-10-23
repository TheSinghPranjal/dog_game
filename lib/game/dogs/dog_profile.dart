import '../environments/environment_id.dart';
import '../models/dog_look.dart';
import '../progression/unlock_thresholds.dart';
import 'dog_persona.dart';

/// The seven adoptable dogs. Saved by [name], so never rename.
enum DogId {
  maple,
  buddy,
  biscuit,
  luna,
  pepper,
  snowball,
  ziggy;

  static DogId? tryParse(Object? name) {
    for (final id in values) {
      if (id.name == name) return id;
    }
    return null;
  }
}

/// One adoptable dog: how she looks (a painter) plus who she is (data).
class DogProfile {
  const DogProfile({
    required this.id,
    required this.name,
    required this.look,
    required this.persona,
    required this.greetings,
  });

  final DogId id;
  final String name;
  final DogLook look;
  final DogPersona persona;

  /// Handwritten header lines, picked one at a time.
  final List<String> greetings;

  EnvironmentId get favouriteEnvironment => persona.favourite;
  UnlockRule get unlockRule => UnlockThresholds.dog(id);
}

/// All seven dogs, in swipe order.
abstract final class DogProfiles {
  static const maple = DogProfile(
    id: DogId.maple,
    name: 'Maple',
    look: DogLook.golden,
    persona: DogPersonas.maple,
    greetings: [
      'Ooh, what is that smell?',
      'Sniff sniff… new smells!',
      "Let's explore!",
      'Boof? What are we doing?',
      'Everything is so interesting!',
      'Can I see? Can I see?',
      'Adventure time!',
      'Hello, explorer!',
    ],
  );

  static const buddy = DogProfile(
    id: DogId.buddy,
    name: 'Buddy',
    look: DogLook.lab,
    persona: DogPersonas.buddy,
    greetings: [
      'Hello, friend!',
      'Wag wag… happy to see you.',
      "Nice day, isn't it?",
      'Slow blink. That means I love you.',
      'Shall we play?',
      'I saved you a spot.',
      'Woof!',
      'You came back!',
    ],
  );

  static const biscuit = DogProfile(
    id: DogId.biscuit,
    name: 'Biscuit',
    look: DogLook.corgi,
    persona: DogPersonas.biscuit,
    greetings: [
      "Is it snack o'clock?",
      'Yawn… hello there.',
      'I smell treats. Do you smell treats?',
      'Nap first, then food. Or food first.',
      'Belly rubs accepted.',
      'Is that a bone? Please say bone.',
      'Five more minutes…',
      'You look like someone with snacks.',
    ],
  );

  static const luna = DogProfile(
    id: DogId.luna,
    name: 'Luna',
    look: DogLook.husky,
    persona: DogPersonas.luna,
    greetings: [
      "…oh, it's you. Hi.",
      'Is it quiet here? Good.',
      'I like the stars best.',
      '*peeks* …hello.',
      'You can stay. I suppose.',
      "Shh. I'm listening to the night.",
      'Slow blink… (that means hi).',
      'Too bright. Is it evening yet?',
    ],
  );

  static const pepper = DogProfile(
    id: DogId.pepper,
    name: 'Pepper',
    look: DogLook.terrier,
    persona: DogPersonas.pepper,
    greetings: [
      'Zoom zoom zoom!',
      'What happens if I push this?',
      "It wasn't me. Probably.",
      'Catch me if you can!',
      'Everything is a toy!',
      'Oops! Ha, again!',
      "Let's make some mischief!",
      'Who left this shoe out?',
    ],
  );

  static const snowball = DogProfile(
    id: DogId.snowball,
    name: 'Snowball',
    look: DogLook.samoyed,
    persona: DogPersonas.snowball,
    greetings: [
      'Soft woof.',
      'Your lap looks nice.',
      'I brought the quiet with me.',
      'Pat the cloud, please.',
      'I am very fluffy. This is a fact.',
      'Hello, gently.',
      'Tail is wagging on the inside.',
      'Stay a while?',
    ],
  );

  static const ziggy = DogProfile(
    id: DogId.ziggy,
    name: 'Ziggy',
    look: DogLook.dachshund,
    persona: DogPersonas.ziggy,
    greetings: [
      'Short legs, big plans!',
      'I can reach that. Watch.',
      'Boof! Surprise!',
      'The floor is my highway.',
      "One ear up means I'm listening.",
      'Race you. I will win. Somehow.',
      "What's under there?",
      'Again! Again!',
    ],
  );

  static const all = [maple, buddy, biscuit, luna, pepper, snowball, ziggy];

  static DogProfile? byId(DogId id) {
    for (final dog in all) {
      if (dog.id == id) return dog;
    }
    return null;
  }

  static DogProfile forLook(DogLook look) => all.firstWhere((dog) => dog.look == look);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/animations/dog_animations.dart';
import 'package:dog_game/game/dogs/dog_persona.dart';
import 'package:dog_game/game/dogs/reaction.dart';
import 'package:dog_game/game/environments/environment_id.dart';

const _dogs = {
  'Maple': DogPersonas.maple,
  'Buddy': DogPersonas.buddy,
  'Biscuit': DogPersonas.biscuit,
  'Luna': DogPersonas.luna,
  'Pepper': DogPersonas.pepper,
  'Snowball': DogPersonas.snowball,
  'Ziggy': DogPersonas.ziggy,
};

const _loves = ReactionOutcome.lovesIt;
const _fine = ReactionOutcome.fine;
const _nope = ReactionOutcome.nope;

void main() {
  group('the same activity, different dogs', () {
    // thing id -> expected outcome per dog, in _dogs order.
    const table = <String, List<ReactionOutcome>>{
      //               Maple  Buddy  Biscuit Luna   Pepper Snowball Ziggy
      'bathTime': [_fine, _fine, _nope, _loves, _nope, _loves, _fine],
      'feed': [_fine, _fine, _loves, _fine, _fine, _fine, _fine],
      'frisbee': [_loves, _fine, _nope, _fine, _loves, _nope, _loves],
      'glassTrouble': [_fine, _fine, _loves, _nope, _loves, _nope, _fine],
      'brushFur': [_fine, _loves, _loves, _nope, _fine, _fine, _loves],
      'cardboardBox': [_loves, _loves, _loves, _loves, _loves, _loves, _loves],
      'somethingUnknown': [_fine, _fine, _fine, _fine, _fine, _fine, _fine],
    };

    for (final MapEntry(key: thing, value: expected) in table.entries) {
      test(thing, () {
        final actual = [for (final persona in _dogs.values) persona.reactionTo(thing)];
        expect(actual, expected, reason: _dogs.keys.join(', '));
      });
    }

    test('overrides beat the trait thresholds', () {
      const fussy = DogPersona(
        tag: 'Test',
        energy: .5,
        curiosity: .5,
        appetite: 1,
        tidiness: .5,
        cuddliness: .5,
        idleHabit: IdleHabit.sniff,
        favourite: EnvironmentId.livingArea,
        tasteOverrides: {'feed': ReactionOutcome.nope},
      );
      expect(fussy.reactionTo('feed'), _nope);
    });
  });

  group('traits drive behaviour numbers', () {
    test('energy scales walk speed between 0.75x and 1.3x', () {
      expect(DogPersonas.biscuit.walkSpeedScale, closeTo(0.86, 0.001));
      expect(DogPersonas.pepper.walkSpeedScale, closeTo(1.245, 0.001));
      for (final p in _dogs.values) {
        expect(p.walkSpeedScale, inInclusiveRange(0.75, 1.3));
      }
      expect(DogPersonas.pepper.idlePauseScale, lessThan(DogPersonas.biscuit.idlePauseScale));
      expect(DogPersonas.pepper.zoomiesChance, greaterThan(DogPersonas.biscuit.zoomiesChance));
    });

    test('appetite: Biscuit eats twice as long and begs', () {
      expect(DogPersonas.biscuit.eatScale, 2);
      expect(DogPersonas.buddy.eatScale, 1);
      expect(DogPersonas.biscuit.begsForFood, isTrue);
      expect(DogPersonas.luna.begsForFood, isFalse);
      expect(DogPersonas.biscuit.hungerPerMinute, greaterThan(DogPersonas.luna.hungerPerMinute));
    });

    test('tidiness and cuddliness', () {
      expect(DogPersonas.snowball.dirtPerMinute, lessThan(DogPersonas.pepper.dirtPerMinute));
      expect(DogPersonas.snowball.groomChance, greaterThan(DogPersonas.pepper.groomChance));
      expect(DogPersonas.ziggy.affectionPerPet, greaterThan(DogPersonas.luna.affectionPerPet));
      expect(DogPersonas.ziggy.seeksFinger, isTrue);
      expect(DogPersonas.luna.seeksFinger, isFalse);
      expect(DogPersonas.maple.inspectChance, greaterThan(DogPersonas.snowball.inspectChance));
    });
  });

  group('reactions are small frame modifiers', () {
    const base = DogFrame(sparkle: 0.1, eyeScale: 1);

    test('loves it: happy eyes and a sparkle', () {
      final f = base.withReaction(_loves);
      expect(f.happyEyes, isTrue);
      expect(f.sparkle, greaterThanOrEqualTo(0.8));
    });

    test('fine: unchanged', () {
      expect(identical(base.withReaction(_fine), base), isTrue);
      expect(identical(base.withReaction(null), base), isTrue);
    });

    test('nope: ears back, surprised, motion marks', () {
      final f = base.withReaction(_nope);
      expect(f.earTwitch, lessThan(0));
      expect(f.eyeScale, greaterThan(1));
      expect(f.mouth, DogMouth.open);
      expect(f.motionMarks, isTrue);
      expect(f.mark, DogMark.exclaim);
    });
  });
}

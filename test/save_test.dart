import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/dogs/dog_needs.dart';
import 'package:dog_game/game/dogs/dog_profile.dart';
import 'package:dog_game/game/environments/environment_id.dart';
import 'package:dog_game/game/save/game_save.dart';
import 'package:dog_game/game/save/game_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameSave JSON', () {
    test('round-trips everything', () {
      final save = GameSave(
        selectedDog: DogId.buddy,
        lastEnvironment: EnvironmentId.kitchen,
        settings: GameSettings(wander: false, sound: true),
        stickers: {'feed', 'bathTime'},
        unlocked: {'env:bedroom'},
        lastSeen: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      save.dog(DogId.buddy)
        ..needs = DogNeeds.initial.apply({Need.hunger: 50, Need.fun: -10})
        ..friendship = 2.5
        ..completed.addAll({'feed', 'play'});

      final copy = GameSave.fromJson(jsonDecode(jsonEncode(save.toJson())));
      expect(copy.toJson(), save.toJson());
      expect(copy.selectedDog, DogId.buddy);
      expect(copy.settings.wander, isFalse);
      expect(copy.dog(DogId.buddy).needs[Need.hunger], 80);
      expect(copy.dog(DogId.buddy).stars, 2);
      expect(copy.totalStars, 2);
      expect(copy.toJson()['schemaVersion'], GameSave.schemaVersion);
    });

    test('broken or out-of-range values fall back or clamp', () {
      final save = GameSave.fromJson({
        'schemaVersion': 1,
        'selectedDog': 'tiger',
        'lastEnvironment': 42,
        'settings': 'loud',
        'dogs': {
          'maple': {
            'needs': {'hunger': 500, 'fun': 'lots', 'energy': -3, 'cleanliness': double.nan},
            'friendship': 99,
            'completed': ['feed', 3, null],
          },
          'unknownDog': {'friendship': 5},
        },
        'stickers': 'not a list',
      });
      expect(save.selectedDog, DogId.maple);
      expect(save.lastEnvironment, EnvironmentId.livingArea);
      expect(save.settings.wander, isTrue);
      final maple = save.dog(DogId.maple);
      expect(maple.needs[Need.hunger], 100);
      expect(maple.needs[Need.fun], DogNeeds.initial[Need.fun]);
      expect(maple.needs[Need.energy], 0);
      expect(maple.needs[Need.cleanliness], DogNeeds.initial[Need.cleanliness]);
      expect(maple.friendship, DogSave.maxStars);
      expect(maple.completed, {'feed'});
      expect(save.dogs.keys, [DogId.maple]);
      expect(save.stickers, isEmpty);
    });

    test('a save without a schema version is migrated to the current one', () {
      final json = GameSave.migrate({'selectedDog': 'buddy'});
      expect(json['schemaVersion'], GameSave.schemaVersion);
      expect(GameSave.fromJson({'selectedDog': 'buddy'}).selectedDog, DogId.buddy);
    });

    test('a locked dog is never restored as the selected one', () {
      expect(GameSave.fromJson({'selectedDog': 'ziggy'}).selectedDog, DogId.maple);
      final rich = GameSave.fromJson({
        'selectedDog': 'biscuit',
        'dogs': {
          'maple': {'friendship': 2},
          'buddy': {'friendship': 1},
        },
      });
      expect(rich.selectedDog, DogId.biscuit);
    });
  });

  group('GameStore', () {
    test('migrates the 1.x look preference', () {
      expect(GameStore.decode(null, legacyLook: 'classic').selectedDog, DogId.buddy);
      expect(GameStore.decode(null, legacyLook: 'fluffy').selectedDog, DogId.maple);
      expect(GameStore.decode(null).selectedDog, DogId.maple);
    });

    test('corrupted JSON falls back to defaults (keeping the 1.x look)', () {
      for (final raw in ['{not json', '[1, 2]', '"text"', '{"dogs": {"1": 2}, "selectedDog": []}', '']) {
        final save = GameStore.decode(raw, legacyLook: 'classic');
        expect(save.selectedDog, anyOf(DogId.buddy, DogId.maple), reason: raw);
        expect(save.settings.wander, isTrue, reason: raw);
      }
      expect(GameStore.decode('{not json', legacyLook: 'classic').selectedDog, DogId.buddy);
    });

    test('loads the 1.x key from storage, then saves one debounced blob', () async {
      SharedPreferences.setMockInitialValues({GameStore.legacyLookKey: 'classic'});
      final store = GameStore(debounce: const Duration(milliseconds: 20));
      await store.load();
      expect(store.save.selectedDog, DogId.buddy);

      final prefs = await SharedPreferences.getInstance();
      store.applyNeeds(DogId.buddy, {Need.fun: 10});
      store.applyNeeds(DogId.buddy, {Need.fun: 5});
      expect(prefs.getString(GameStore.key), isNull, reason: 'debounced');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final saved = jsonDecode(prefs.getString(GameStore.key)!) as Map;
      expect(saved['selectedDog'], 'buddy');
      expect(saved['dogs']['buddy']['needs']['fun'], DogNeeds.initial[Need.fun] + 15);

      final reloaded = GameStore();
      await reloaded.load();
      expect(reloaded.save.toJson(), store.save.toJson());
    });

    test('flush writes at once (app paused)', () async {
      SharedPreferences.setMockInitialValues({});
      final store = GameStore(debounce: const Duration(hours: 1));
      await store.load();
      store.update((save) => save.settings.wander = false);
      await store.flush();
      final prefs = await SharedPreferences.getInstance();
      expect((jsonDecode(prefs.getString(GameStore.key)!) as Map)['settings'], {'wander': false, 'sound': false});
    });

    test('without storage it plays from memory and schedules nothing', () {
      final store = GameStore();
      store.applyNeeds(DogId.maple, {Need.fun: 1});
      expect(store.save.dog(DogId.maple).needs[Need.fun], DogNeeds.initial[Need.fun] + 1);
    });
  });
}

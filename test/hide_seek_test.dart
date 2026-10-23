import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/dog_game_screen.dart';
import 'package:dog_game/game/dogs/dog_profile.dart';
import 'package:dog_game/game/hide_seek/hide_seek_play_screen.dart';
import 'package:dog_game/game/hide_seek/hide_seek_screen.dart';
import 'package:dog_game/game/hide_seek/hide_seek_stages.dart';
import 'package:dog_game/game/save/game_save.dart';
import 'package:dog_game/game/save/game_store.dart';

const _frame = Duration(milliseconds: 16);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

Future<void> _pumpSeconds(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds; t += 0.016) {
    await tester.pump(_frame);
  }
}

void main() {
  setUp(GameStore.instance.reset);

  group('stages', () {
    test('there are twenty, hiding one to five of the game\'s own dogs', () {
      final counts = <int>{};
      for (var n = 1; n <= HideSeekStages.count; n++) {
        final stage = HideSeekStages.build(n);
        final dogs = stage.dogs.toList();
        expect(dogs, isNotEmpty);
        expect(dogs.length, lessThanOrEqualTo(5));
        expect(dogs.toSet().length, dogs.length, reason: 'stage $n hides a dog twice');
        expect(dogs.every(DogProfiles.all.contains), isTrue);
        expect(stage.dogCount, HideSeekStages.dogsIn(n));
        expect(stage.piles.length, greaterThan(stage.dogCount), reason: 'stage $n has no decoys');
        for (final pile in stage.piles) {
          expect(pile.items.first.kind.cover, isTrue, reason: 'stage $n: a pile must start with a cover');
          // The cover is big enough to hide a whole dog.
          expect(pile.items.first.width, greaterThan(HideSeekStages.dogWidth));
        }
        counts.add(stage.dogCount);
      }
      expect(counts, {1, 2, 3, 4, 5});
    });

    test('are the same every time', () {
      final a = HideSeekStages.build(7);
      final b = HideSeekStages.build(7);
      expect([for (final p in a.piles) p.position], [for (final p in b.piles) p.position]);
      expect(a.dogs.toList(), b.dogs.toList());
    });

    test('progress survives a save round trip', () {
      final save = GameSave(hideSeekCleared: 4);
      expect(GameSave.fromJson(save.toJson()).hideSeekCleared, 4);
      expect(GameSave.fromJson({'hideSeekCleared': 'x'}).hideSeekCleared, 0);
    });
  });

  testWidgets('the play button next to back opens the stage list', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MaterialApp(home: DogGameScreen()));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Play hide and seek'));
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(HideSeekScreen), findsOneWidget);
    // Only stage 1 is open at first.
    await tester.tap(find.byKey(const ValueKey('stage-2')));
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(HideSeekPlayScreen), findsNothing);
    await tester.tap(find.byKey(const ValueKey('stage-1')));
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(HideSeekPlayScreen), findsOneWidget);
  });

  testWidgets('clearing piles uncovers dogs; finding them all clears the stage', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MaterialApp(home: HideSeekPlayScreen(stageNumber: 3)));
    await tester.pump();
    final state = tester.state<HideSeekPlayScreenState>(find.byType(HideSeekPlayScreen));
    final stage = state.stage;
    for (final (i, pile) in stage.piles.indexed) {
      if (pile.dog != null) {
        // A hidden dog can't be found through the things on top of her.
        state.tapDog(i);
        expect(state.found, 0);
      }
      for (var j = 0; j < pile.items.length; j++) {
        state.tapPile(i);
        await _pumpSeconds(tester, 0.1);
      }
    }
    await _pumpSeconds(tester, 0.6);
    for (final (i, pile) in stage.piles.indexed) {
      if (pile.dog == null) continue;
      await tester.tap(find.byKey(ValueKey('dog-$i')));
      await tester.pump();
    }
    expect(state.found, stage.dogCount);
    expect(GameStore.instance.save.hideSeekCleared, 3);
    await _pumpSeconds(tester, 1.5);
    expect(find.text('Next stage'), findsOneWidget);
  });
}

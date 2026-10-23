import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/animations/dog_animations.dart';
import 'package:dog_game/game/dogs/dog_profile.dart';
import 'package:dog_game/game/dogs/selected_dog.dart';
import 'package:dog_game/game/models/dog_look.dart';
import 'package:dog_game/game/save/game_store.dart';
import 'package:dog_game/game/widgets/dog_character.dart';
import 'package:dog_game/screens/start_screen.dart';

Future<void> _pumpStart(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: StartScreen()));
  // Puppies animate forever, so step time rather than settling.
  await tester.pump();
}

void main() {
  setUp(() {
    GameStore.instance.reset();
    dogLook.value = DogLook.golden;
  });

  testWidgets('swiping the puppy switches the dog', (tester) async {
    await _pumpStart(tester);
    expect(find.text('Maple · Curious explorer'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(selectedDog.value, DogProfiles.buddy);
    expect(dogLook.value, DogLook.lab);
    expect(find.text('Buddy · Sweet all-rounder'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(dogLook.value, DogLook.golden);
  });

  testWidgets('the new dogs are in colour and can be picked right away', (tester) async {
    await _pumpStart(tester);
    await tester.tap(find.bySemanticsLabel('Next dog')); // Past Buddy.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    for (final (dog, label) in [
      (DogProfiles.biscuit, 'Biscuit · Lazy foodie'),
      (DogProfiles.luna, 'Luna · Quiet night dog'),
      (DogProfiles.pepper, 'Pepper · Mischief zoomies'),
    ]) {
      await tester.tap(find.bySemanticsLabel('Next dog'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(label), findsOneWidget);
      expect(selectedDog.value, dog);
      expect(dogLook.value, dog.look);
      expect(find.byType(ColorFiltered), findsNothing, reason: 'no silhouette');
    }
  });

  testWidgets('arrows step through every dog, wrapping around', (tester) async {
    await _pumpStart(tester);
    await tester.tap(find.bySemanticsLabel('Next dog'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(dogLook.value, DogLook.lab);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);

    // Snowball and Ziggy wait for friendship stars; the rest are playable.
    expect(GameStore.instance.save.isDogUnlocked(DogId.snowball), isFalse);
    expect(GameStore.instance.save.isDogUnlocked(DogId.ziggy), isFalse);

    for (var i = 1; i < DogProfiles.all.length; i++) {
      await tester.tap(find.bySemanticsLabel('Next dog'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 0, reason: 'wraps around');
    expect(dogLook.value, DogLook.golden);
  });

  testWidgets('locked dogs show as pencil silhouettes with their star count', (tester) async {
    await _pumpStart(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.bySemanticsLabel('Next dog'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.textContaining('Snowball'), findsOneWidget);
    expect(find.text('Unlock at 10 friendship stars'), findsOneWidget);
    expect(find.byType(ColorFiltered), findsWidgets);
    expect(selectedDog.value, DogProfiles.pepper, reason: 'a locked dog is not selected');
  });

  test('the seven dogs, in swipe order', () {
    expect(DogProfiles.all.map((d) => d.id), DogId.values);
    expect(DogProfiles.all.map((d) => d.name), ['Maple', 'Buddy', 'Biscuit', 'Luna', 'Pepper', 'Snowball', 'Ziggy']);
  });

  test('every dog has a look, a persona and eight greetings', () {
    expect(DogProfiles.all.map((c) => c.look).toSet(), hasLength(DogProfiles.all.length));
    for (final dog in DogProfiles.all) {
      expect(dog.greetings, hasLength(8), reason: dog.name);
      expect(DogProfiles.forLook(dog.look), dog);
    }
  });

  testWidgets('puppies without a fixed look follow the chosen one', (tester) async {
    await tester.pumpWidget(const DogCharacter(frame: DogFrame(), facing: 1, width: 100));
    DogPainter painter() => tester.widget<CustomPaint>(find.byType(CustomPaint)).painter! as DogPainter;
    expect(painter().look, DogLook.golden);
    dogLook.value = DogLook.lab;
    await tester.pump();
    expect(painter().look, DogLook.lab);
  });
}

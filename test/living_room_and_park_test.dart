import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/animations/dog_animations.dart';
import 'package:dog_game/game/dog_game_screen.dart';
import 'package:dog_game/game/controllers/dog_game_controller.dart';
import 'package:dog_game/game/environments/girl/girl_keys.dart';
import 'package:dog_game/game/environments/girl/girl_painter.dart';
import 'package:dog_game/game/environments/living_room/living_room_keys.dart';
import 'package:dog_game/game/environments/park/park_keys.dart';
import 'package:dog_game/game/models/activity_definition.dart';
import 'package:dog_game/game/models/dog_game_state.dart';
import 'package:dog_game/game/models/game_location.dart';
import 'package:dog_game/game/models/game_positions.dart';
import 'package:dog_game/game/save/game_store.dart';

const _frame = Duration(milliseconds: 16);

Future<DogGameController> _at(WidgetTester tester, GameLocation location) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: DogGameScreen()));
  await tester.pump();
  final c = tester.state<DogGameScreenState>(find.byType(DogGameScreen)).controller;
  c.goTo(location);
  await _until(tester, () => c.state == DogGameState.idle && c.location == location);
  return c;
}

Future<void> _until(WidgetTester tester, bool Function() done, {double maxSeconds = 40}) async {
  for (var t = 0.0; t < maxSeconds; t += 0.016) {
    if (done()) return;
    await tester.pump(_frame);
  }
  fail('Condition not met within ${maxSeconds}s');
}

void _expectClean(DogGameController c) {
  expect(c.dogHidden, isFalse);
  expect(c.objects, isEmpty);
  expect(c.effects, isEmpty);
  expect(c.sceneValue(GirlKeys.mood), 0, reason: 'the girl is happy again');
  expect(c.dogPosition, c.locationConfig.returnPosition);
}

void main() {
  setUp(GameStore.instance.reset);

  testWidgets('both new places are in the navigation with their things', (tester) async {
    await _at(tester, GameLocation.home);
    for (final label in ['Go to Living', 'Go to Park']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.bySemanticsLabel('Go to Living'));
    await tester.pump();
    final c = tester.state<DogGameScreenState>(find.byType(DogGameScreen)).controller;
    await _until(tester, () => c.state == DogGameState.idle);
    for (final label in ['Woof at the mail slot', 'Pet him and watch him wag', 'Watch the squirrel out the window']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('mail: a knock, two woofs at the slot, the envelope stays outside', (tester) async {
    final c = await _at(tester, GameLocation.livingRoom);
    c.startActivity(DogActivity.mail);
    await tester.pump();
    expect(c.effects.any((e) => e.kind == EffectKind.knock), isTrue);
    await _until(tester, () => c.dogPosition == LivingRoomPositions.dogAtDoor);
    await _until(tester, () => c.pose == DogPose.bark);
    await _until(tester, () => c.dogFrame.mark == DogMark.woof);
    expect(c.sceneValue(LivingRoomKeys.mailEnvelope), greaterThan(0.9));
    await _until(tester, () => c.pose == DogPose.satisfied);
    expect(c.sceneValue(LivingRoomKeys.mailEnvelope), 0, reason: 'it never came inside');
    await _until(tester, () => c.state == DogGameState.idle);
    _expectClean(c);
  });

  testWidgets('wag: a pat from the girl, hearts, a blur of a tail', (tester) async {
    final c = await _at(tester, GameLocation.livingRoom);
    c.startActivity(DogActivity.wag);
    await _until(tester, () => c.sceneValue(GirlKeys.mood) == GirlMood.adoring.index);
    expect(c.effects.any((e) => e.kind == EffectKind.hearts), isTrue);
    await _until(tester, () => c.pose == DogPose.wag);
    expect(c.dogFrame.tailBlur, isTrue);
    await _until(tester, () => c.dogPosition == LivingRoomPositions.dogLeanIn);
    await _until(tester, () => c.state == DogGameState.idle);
    _expectClean(c);
  });

  testWidgets('window: a squirrel on the sill, a thumping tail, then a sigh', (tester) async {
    final c = await _at(tester, GameLocation.livingRoom);
    c.startActivity(DogActivity.windowWatch);
    await _until(tester, () => c.dogPosition == LivingRoomPositions.dogOnSill);
    await _until(tester, () => c.objectOf(ObjectKind.squirrel)?.position == LivingRoomPositions.squirrelOnSill);
    await _until(tester, () => c.pose == DogPose.wag);
    await _until(tester, () => c.objectOf(ObjectKind.squirrel) == null);
    await _until(tester, () => c.pose == DogPose.lieDown);
    expect(c.dogPosition, LivingRoomPositions.dogOnSill);
    await _until(tester, () => c.state == DogGameState.idle);
    _expectClean(c);
  });

  testWidgets('ducks: he stops at the bank, the duck quacks and paddles off', (tester) async {
    final c = await _at(tester, GameLocation.park);
    c.startActivity(DogActivity.duckPond);
    await _until(tester, () => c.effects.any((e) => e.kind == EffectKind.quack));
    expect(c.dogPosition, ParkPositions.dogAtPond, reason: 'he stays on the bank');
    final duck = c.objectOf(ObjectKind.duck)!;
    // Never in the water.
    expect(c.dogPosition.dx, lessThan(ParkPositions.pondCenter.dx - ParkPositions.pondRadius.width));
    await _until(tester, () => c.objectOf(ObjectKind.duck) == null);
    expect(duck.position, ParkPositions.duckExit, reason: 'swam away safely');
    await _until(tester, () => c.state == DogGameState.idle);
    _expectClean(c);
  });

  testWidgets('leaves: a dive into the pile, out with a stick, the pile settles', (tester) async {
    final c = await _at(tester, GameLocation.park);
    c.startActivity(DogActivity.leafPile);
    await _until(tester, () => c.dogPosition == ParkPositions.dogInLeaves);
    await _until(tester, () => c.sceneValue(ParkKeys.leafScatter) == 1);
    expect(c.effects.any((e) => e.kind == EffectKind.leafBurst), isTrue);
    await _until(tester, () => c.dogFrame.carry == DogCarry.stick);
    await _until(tester, () => c.state == DogGameState.idle);
    expect(c.sceneValue(ParkKeys.leafScatter), 0);
    _expectClean(c);
  });

  testWidgets('pigeon: a sneak, a play bow, and the pigeon flutters to the lamp post', (tester) async {
    final c = await _at(tester, GameLocation.park);
    c.startActivity(DogActivity.benchPigeon);
    await tester.pump();
    final pigeon = c.objectOf(ObjectKind.pigeon)!;
    expect(pigeon.position, ParkPositions.pigeonOnBench);
    await _until(tester, () => c.dogPosition == ParkPositions.dogOnBench);
    await _until(tester, () => c.pose == DogPose.lookUp);
    expect(pigeon.position, ParkPositions.pigeonOnLamp);
    await _until(tester, () => c.objectOf(ObjectKind.pigeon) == null);
    await _until(tester, () => c.state == DogGameState.idle);
    _expectClean(c);
  });
}

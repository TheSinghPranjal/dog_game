import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/animations/dog_animations.dart';
import 'package:dog_game/game/dog_game_screen.dart';
import 'package:dog_game/game/controllers/dog_game_controller.dart';
import 'package:dog_game/game/environments/bedroom/bedroom_keys.dart';
import 'package:dog_game/game/environments/girl/girl_keys.dart';
import 'package:dog_game/game/environments/girl/girl_painter.dart';
import 'package:dog_game/game/models/activity_definition.dart';
import 'package:dog_game/game/models/dog_game_state.dart';
import 'package:dog_game/game/models/game_location.dart';
import 'package:dog_game/game/models/game_positions.dart';
import 'package:dog_game/game/save/game_store.dart';

const _frame = Duration(milliseconds: 16);

Future<DogGameController> _bedroom(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: DogGameScreen()));
  await tester.pump();
  final c = tester.state<DogGameScreenState>(find.byType(DogGameScreen)).controller;
  await tester.tap(find.bySemanticsLabel('Go to Bedroom'));
  await _until(tester, () => c.state == DogGameState.idle && c.location == GameLocation.bedroom);
  return c;
}

Future<void> _until(WidgetTester tester, bool Function() done, {double maxSeconds = 40}) async {
  for (var t = 0.0; t < maxSeconds; t += 0.016) {
    if (done()) return;
    await tester.pump(_frame);
  }
  fail('Condition not met within ${maxSeconds}s');
}

GirlMood _mood(DogGameController c) => GirlMood.values[c.sceneValue(GirlKeys.mood).round()];

/// Back to rest: girl home and happy, closet shut, dog visible, cable
/// untouched.
void _expectRoomAtRest(DogGameController c) {
  expect(c.sceneValue(GirlKeys.x), 0);
  expect(_mood(c), GirlMood.happy);
  expect(c.sceneValue(BedroomKeys.wardrobeDoor), 0);
  expect(c.sceneValue(BedroomKeys.wardrobeTail), 0);
  expect(c.dogHidden, isFalse);
  expect(c.dogPosition, BedroomPositions.returnPosition);
  expect(c.dogFrame.carry, DogCarry.none);
  expect(c.objects, isEmpty);
  expect(c.effects, isEmpty);
}

void main() {
  setUp(GameStore.instance.reset);

  testWidgets('the bedroom has its three things on cards', (tester) async {
    await _bedroom(tester);
    for (final label in ['Hide in the closet', 'Grab the slipper', 'Jump on his pillow']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('closet: he slips inside, his tail gives him away, he peeks and pops out', (tester) async {
    final c = await _bedroom(tester);
    await tester.tap(find.bySemanticsLabel('Hide in the closet'));
    await _until(tester, () => c.dogHidden);
    await _until(tester, () => c.sceneValue(BedroomKeys.wardrobeDoor) == 0.55);
    expect(c.sceneValue(BedroomKeys.wardrobeTail), 1, reason: 'a wagging tail pokes out');
    await _until(tester, () => c.sceneValue(BedroomKeys.wardrobeEyes) == 1);
    await _until(tester, () => !c.dogHidden);
    await _until(tester, () => c.dogPosition == BedroomPositions.dogWardrobeJumpOut);
    await _until(tester, () => _mood(c) == GirlMood.laughing);

    await _until(tester, () => c.state == DogGameState.idle);
    expect(c.lastCompletedActivity, DogActivity.closetHide);
    _expectRoomAtRest(c);
  });

  testWidgets('slipper: he grabs it, shakes it gently and drops it; the cable stays put', (tester) async {
    final c = await _bedroom(tester);
    c.startActivity(DogActivity.slipper);
    await _until(tester, () => c.dogFrame.carry == DogCarry.slipper);
    expect(c.dogPosition, BedroomPositions.dogSlipperPosition);
    expect(c.objectOf(ObjectKind.slipper), isNull);
    await _until(tester, () => c.pose == DogPose.shake);
    await _until(tester, () => c.objectOf(ObjectKind.slipper) != null);
    expect(c.dogFrame.carry, DogCarry.none);
    expect(c.objectOf(ObjectKind.slipper)!.position, BedroomPositions.slipperPosition);
    await _until(tester, () => c.state == DogGameState.idle);
    _expectRoomAtRest(c);
  });

  testWidgets('pillow: one bounce, then chin on paws', (tester) async {
    final c = await _bedroom(tester);
    c.startActivity(DogActivity.pillowJump);
    await _until(tester, () => c.dogPosition == BedroomPositions.dogOnPillow);
    await _until(tester, () => c.sceneValue(BedroomKeys.pillowSquish) > 0.5);
    await _until(tester, () => c.pose == DogPose.lieDown);
    expect(c.dogPosition, BedroomPositions.dogOnPillow);
    await _until(tester, () => c.dogPosition == BedroomPositions.dogBedJumpDown);
    await _until(tester, () => c.state == DogGameState.idle);
    _expectRoomAtRest(c);
  });

  testWidgets('leaving mid-hide brings the dog back out', (tester) async {
    final c = await _bedroom(tester);
    c.startActivity(DogActivity.closetHide);
    await _until(tester, () => c.dogHidden);
    // Backgrounding and resuming must not strand him in the closet.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _until(tester, () => c.state == DogGameState.idle);
    expect(c.dogHidden, isFalse);
  });
}

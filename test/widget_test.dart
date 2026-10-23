import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/dog_game_screen.dart';
import 'package:dog_game/game/controllers/dog_game_controller.dart';
import 'package:dog_game/game/models/activity_definition.dart';
import 'package:dog_game/game/models/dog_game_state.dart';
import 'package:dog_game/game/models/game_location.dart';
import 'package:dog_game/game/models/game_positions.dart';
import 'package:dog_game/game/animations/dog_animations.dart';
import 'package:dog_game/game/scripting/scene_state.dart';
import 'package:dog_game/main.dart';
import 'package:dog_game/screens/how_to_play_screen.dart';
import 'package:dog_game/screens/splash_screen.dart';
import 'package:dog_game/screens/start_screen.dart';

const _frame = Duration(milliseconds: 16);

Future<DogGameController> _launch(WidgetTester tester, {Size size = const Size(1080, 1920)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: DogGameScreen()));
  await tester.pump();
  return tester.state<DogGameScreenState>(find.byType(DogGameScreen)).controller;
}

/// Pumps frame by frame (the game clock clamps big jumps) until [done].
Future<void> _pumpUntil(WidgetTester tester, bool Function() done, {double maxSeconds = 25}) async {
  for (var t = 0.0; t < maxSeconds; t += 0.016) {
    if (done()) return;
    await tester.pump(_frame);
  }
  fail('Condition not met within ${maxSeconds}s');
}

Future<void> _pumpSeconds(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds; t += 0.016) {
    await tester.pump(_frame);
  }
}

Future<void> _goTo(WidgetTester tester, DogGameController c, GameLocation location) async {
  c.goTo(location);
  await _pumpUntil(tester, () => c.state == DogGameState.idle);
  expect(c.location, location);
  expect(c.dogPosition, Locations.of(location).startPosition);
}

/// Runs [activity] to completion and checks it ends cleanly.
Future<void> _runToEnd(WidgetTester tester, DogGameController c, DogActivity activity) async {
  c.startActivity(activity);
  await tester.pump();
  expect(c.isBusy, isTrue, reason: '$activity should start');
  await _pumpUntil(tester, () => c.state == DogGameState.idle);
  expect(c.dogPosition, c.locationConfig.returnPosition, reason: '$activity return');
  expect(c.objects, isEmpty, reason: '$activity leftovers');
  expect(c.effects, isEmpty, reason: '$activity effects');
  expect(c.tubFoam, 0);
  expect(c.pose, isNot(DogPose.pawsUp));
  expect(c.dogFrame.carry, DogCarry.none, reason: '$activity carry');
}

void main() {
  group('app flow', () {
    Future<void> openApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.7;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MyPetDogApp());
      expect(find.byType(SplashScreen), findsOneWidget);
      await _pumpSeconds(tester, 3);
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(StartScreen), findsOneWidget);
    }

    testWidgets('splash leads to the start screen with Play and How to Play', (tester) async {
      await openApp(tester);
      expect(find.bySemanticsLabel('Play'), findsOneWidget);
      expect(find.bySemanticsLabel('How to play'), findsOneWidget);
    });

    testWidgets('tapping the splash skips ahead', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.7;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MyPetDogApp());
      await _pumpSeconds(tester, 0.3);
      await tester.tapAt(const Offset(200, 300));
      await _pumpSeconds(tester, 0.5);
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('How to Play opens tips and Got it returns', (tester) async {
      await openApp(tester);
      await tester.tap(find.bySemanticsLabel('How to play'));
      await _pumpSeconds(tester, 0.5);
      expect(find.byType(HowToPlayScreen), findsOneWidget);
      expect(find.text('2. Pick an activity'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Got it'));
      await _pumpSeconds(tester, 0.5);
      expect(find.byType(HowToPlayScreen), findsNothing);
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('Play opens the game and the back button returns', (tester) async {
      await openApp(tester);
      await tester.tap(find.bySemanticsLabel('Play'));
      await _pumpSeconds(tester, 0.5);
      expect(find.byType(DogGameScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Feed the dog'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Feed the dog'));
      await _pumpSeconds(tester, 1);
      await tester.tap(find.bySemanticsLabel('Back to menu'));
      await _pumpSeconds(tester, 0.5);
      expect(find.byType(DogGameScreen), findsNothing);
      expect(find.byType(StartScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('launches at home with its three actions and the navigation', (tester) async {
    final c = await _launch(tester);
    expect(c.state, DogGameState.idle);
    expect(c.location, GameLocation.home);
    for (final label in [
      'Feed the dog',
      'Play fetch',
      'Chase the squirrel',
      'Go to Home',
      'Go to Bath',
      'Go to Outdoors',
      'Go to Kitchen',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('feed runs the full sequence and ignores extra taps', (tester) async {
    final c = await _launch(tester);
    await _pumpSeconds(tester, 6); // Wander away from the start spot first.

    await tester.tap(find.bySemanticsLabel('Feed the dog'));
    await tester.pump();
    expect(c.state, DogGameState.walkingToFood);
    expect(c.bowl!.position, HomePositions.bowlPosition);

    await tester.tap(find.bySemanticsLabel('Feed the dog'));
    await tester.tap(find.bySemanticsLabel('Play fetch'));
    await tester.tap(find.bySemanticsLabel('Go to Outdoors'));
    await tester.pump();
    expect(c.ball, isNull);
    expect(c.location, GameLocation.home);

    await _pumpUntil(tester, () => c.state == DogGameState.eating);
    expect(c.dogPosition, HomePositions.feedingPosition);
    expect(c.facing, -1);
    c.play();
    c.goTo(GameLocation.bath);
    expect(c.state, DogGameState.eating);

    await _pumpUntil(tester, () => c.state == DogGameState.returningFromFood);
    expect(c.bowl, isNull);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.dogPosition, HomePositions.returnPosition);
  });

  testWidgets('fetch follows the fixed ball path and brings the ball back', (tester) async {
    final c = await _launch(tester);
    c.play();
    await tester.pump();
    expect(c.ball!.position, HomePositions.ballStartPosition);
    await _pumpUntil(tester, () => c.state == DogGameState.playing);
    expect(c.dogPosition, HomePositions.playPosition);
    expect(c.pose, DogPose.playBow);
    await _pumpUntil(tester, () => c.dogFrame.carry == DogCarry.ball);
    expect(c.ball, isNull);
    await _pumpUntil(tester, () => c.state == DogGameState.returningFromPlay && c.pose == DogPose.wag);
    expect(c.dogPosition, HomePositions.fetchReturnPosition);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.dogFrame.carry, DogCarry.none);
    expect(c.dogPosition, HomePositions.returnPosition);
  });

  testWidgets('squirrel follows its waypoints and escapes into its hole', (tester) async {
    final c = await _launch(tester);
    await tester.tap(find.bySemanticsLabel('Chase the squirrel'));
    await tester.pump();
    expect(c.state, DogGameState.chasingSquirrel);
    final squirrel = c.objectOf(ObjectKind.squirrel)!;
    expect(squirrel.position, HomePositions.squirrelSpawnPosition);

    await _pumpUntil(tester, () => c.dogPosition == HomePositions.dogSquirrelApproachPosition);
    await _pumpUntil(tester, () => squirrel.position == HomePositions.squirrelWaypointC);
    await _pumpUntil(tester, () => c.pose == DogPose.surprised);
    expect(c.dogPosition, HomePositions.dogSquirrelLungeTarget);
    expect(squirrel.position, HomePositions.squirrelFinalPosition);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.objects, isEmpty);
    expect(c.dogPosition, HomePositions.dogSquirrelReturnPosition);
  });

  testWidgets('every activity in every location completes, twice, without drift', (tester) async {
    final c = await _launch(tester);
    for (final location in GameLocation.values) {
      if (location != c.location) await _goTo(tester, c, location);
      for (final def in Locations.of(location).activities) {
        await _runToEnd(tester, c, def.activity);
        await _runToEnd(tester, c, def.activity);
      }
    }
  });

  testWidgets('glass trouble: a tall dog stands up, fixed fall path, harmless puff', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.kitchen);
    await tester.tap(find.bySemanticsLabel('Glass trouble'));
    await tester.pump();
    expect(c.state, DogGameState.glassTrouble);
    final glass = c.objectOf(ObjectKind.glass)!;
    expect(glass.position, KitchenPositions.glassSpawnPosition);
    c.startActivity(DogActivity.glassTrouble); // Duplicate tap ignored.
    expect(c.objects.where((o) => o.kind == ObjectKind.glass), hasLength(1));

    await _pumpUntil(tester, () => c.pose == DogPose.pawsUp);
    expect(c.dogPosition, KitchenPositions.glassPawsUpPosition);
    await _pumpUntil(tester, () => c.state == DogGameState.glassReaction);
    expect(glass.position, KitchenPositions.glassLandingPosition);
    expect(c.effects.any((e) => e.kind == EffectKind.impact), isTrue);
    await _pumpUntil(tester, () => c.pose == DogPose.innocent);
    expect(c.objectOf(ObjectKind.glass), isNull);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.dogPosition, KitchenPositions.glassDogReturnPosition);
  });

  testWidgets('treat time: scratch, cabinet opens, treat eaten, cabinet closes', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.kitchen);
    c.startActivity(DogActivity.treatTime);
    await _pumpUntil(tester, () => c.state == DogGameState.treatScratching);
    await _pumpUntil(tester, () => c.pose == DogPose.scratch);
    expect(c.dogPosition, KitchenPositions.treatScratchPosition);
    await _pumpUntil(tester, () => c.objectOf(ObjectKind.treat) != null);
    expect(c.cabinetOpen, 1);
    expect(c.objectOf(ObjectKind.treat)!.position, KitchenPositions.treatSpawnPosition);
    await _pumpUntil(tester, () => c.state == DogGameState.treatEating && c.pose == DogPose.eat);
    expect(c.dogPosition, KitchenPositions.treatEatingPosition);
    await _pumpUntil(tester, () => c.pose == DogPose.satisfied);
    expect(c.objectOf(ObjectKind.treat), isNull);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.cabinetOpen, 0);
  });

  testWidgets('dinner: roasts fully, served on a plate away from the stove', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.kitchen);
    c.startActivity(DogActivity.dinner);
    await _pumpUntil(tester, () => c.state == DogGameState.dinnerCooking);
    final dinner = c.objectOf(ObjectKind.drumstick)!;
    expect(dinner.position, KitchenPositions.dinnerCookingPosition);
    expect(dinner.progress, lessThan(0.1));
    expect(c.dogPosition, KitchenPositions.dinnerDogWatchPosition);
    await _pumpUntil(tester, () => c.state == DogGameState.dinnerServing);
    expect(dinner.progress, 1);
    await _pumpUntil(tester, () => c.state == DogGameState.dinnerEating);
    expect(c.objectOf(ObjectKind.drumstick), isNull);
    final plate = c.objectOf(ObjectKind.plate)!;
    expect(plate.position, KitchenPositions.dinnerServingPosition);
    expect(plate.fill, 1);
    await _pumpUntil(tester, () => c.pose == DogPose.eat);
    expect(c.dogPosition, KitchenPositions.dinnerDogEatingPosition);
    await _pumpUntil(tester, () => c.state == DogGameState.idle, maxSeconds: 40);
    expect(c.objects, isEmpty);
    expect(c.dogPosition, KitchenPositions.dinnerDogReturnPosition);
  });

  testWidgets('the puppy never goes near the stove during dinner', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.kitchen);
    c.startActivity(DogActivity.dinner);
    await tester.pump();
    for (var t = 0.0; c.state != DogGameState.idle && t < 40; t += 0.016) {
      expect(c.dogPosition.dx, lessThan(KitchenPositions.stoveLeft - 0.05));
      await tester.pump(_frame);
    }
  });

  testWidgets('activities from another location are ignored', (tester) async {
    final c = await _launch(tester);
    c.startActivity(DogActivity.bathTime);
    c.startActivity(DogActivity.dig);
    expect(c.state, DogGameState.idle);
  });

  testWidgets('bath time puts the dog in the tub with foam', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.bath);
    await tester.tap(find.bySemanticsLabel('Bath time'));
    await tester.pump();
    expect(c.state, DogGameState.walkingToBath);
    await _pumpUntil(tester, () => c.pose == DogPose.relax);
    expect(c.dogPosition, BathPositions.dogBathPosition);
    expect(c.tubFoam, 1);
    expect(c.effects.any((e) => e.kind == EffectKind.bubbles), isTrue);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
  });

  testWidgets('tree squirrel: he never climbs, only paws up at the trunk', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.outdoors);
    c.startActivity(DogActivity.treeSquirrel);
    await tester.pump();
    final squirrel = c.objectOf(ObjectKind.squirrel)!;
    await _pumpUntil(tester, () => c.pose == DogPose.pawsUp);
    expect(c.dogPosition, OutdoorPositions.dogAtTrunk);
    expect(squirrel.position, OutdoorPositions.squirrelOnBranch);
    for (var t = 0.0; c.state != DogGameState.idle && t < 25; t += 0.016) {
      // Always on the ground.
      expect(c.dogPosition.dy, greaterThan(0.7));
      await tester.pump(_frame);
    }
    expect(c.dogPosition, OutdoorPositions.dogSquirrelReturnPosition);
  });

  testWidgets('dig turns up a bone he parades, and the mound refills', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.outdoors);
    c.startActivity(DogActivity.dig);
    await _pumpUntil(tester, () => c.pose == DogPose.dig);
    expect(c.dogPosition, OutdoorPositions.dogDigPosition);
    await _pumpUntil(tester, () => c.dogFrame.carry == DogCarry.bone);
    expect(c.sceneValue(SceneKeys.moundDug), 1);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.sceneValue(SceneKeys.moundDug), 0);
  });

  testWidgets('frisbee: he catches it on the second jump and it lands safely', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.outdoors);
    c.startActivity(DogActivity.frisbee);
    await _pumpUntil(tester, () => c.dogFrame.carry == DogCarry.frisbee);
    expect(c.objectOf(ObjectKind.frisbee), isNull);
    await _pumpUntil(tester, () => c.objectOf(ObjectKind.frisbee) != null);
    expect(c.objectOf(ObjectKind.frisbee)!.position, OutdoorPositions.frisbeeDropPosition);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.objects, isEmpty);
  });

  testWidgets('a short-legged dog climbs the stool for the glass', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);
    late DogGameController c;
    await tester.pumpWidget(
      MaterialApp(home: _ControllerHost(shortLegs: true, onReady: (controller) => c = controller)),
    );
    await tester.pump();
    await _goTo(tester, c, GameLocation.kitchen);
    c.startActivity(DogActivity.glassTrouble);
    await _pumpUntil(tester, () => c.dogPosition == KitchenPositions.glassOnStoolPosition);
    await _pumpUntil(tester, () => c.dogPosition == KitchenPositions.glassCounterIdlePosition);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.dogPosition, KitchenPositions.glassDogReturnPosition);
  });

  testWidgets('switching location fades and lands on the start spot', (tester) async {
    final c = await _launch(tester);
    await _pumpSeconds(tester, 6);
    await tester.tap(find.bySemanticsLabel('Go to Bath'));
    await tester.pump();
    expect(c.state, DogGameState.changingLocation);
    await _pumpSeconds(tester, 0.1);
    expect(c.sceneOpacity.value, lessThan(1));
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.location, GameLocation.bath);
    expect(c.sceneOpacity.value, 1);
    expect(find.bySemanticsLabel('Bath time'), findsOneWidget);
    expect(find.bySemanticsLabel('Feed the dog'), findsNothing);
  });

  test('start and idle positions are inside each walk area', () {
    for (final location in GameLocation.values) {
      final config = Locations.of(location);
      for (final p in config.idlePositions) {
        expect(config.walkArea.contains(p), isTrue, reason: '$location $p');
      }
    }
  });

  testWidgets('backgrounding freezes the sequence, resuming finishes it', (tester) async {
    final c = await _launch(tester);
    c.feed();
    await _pumpUntil(tester, () => c.state == DogGameState.eating);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _pumpSeconds(tester, 10);
    expect(c.state, DogGameState.eating);
    expect(c.bowl, isNotNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpUntil(tester, () => c.state == DogGameState.idle);
    expect(c.bowl, isNull);
  });

  testWidgets('works on a short wide screen too', (tester) async {
    final c = await _launch(tester, size: const Size(1200, 1600));
    await _goTo(tester, c, GameLocation.outdoors);
    await _runToEnd(tester, c, DogActivity.frisbee);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing mid-animation is safe', (tester) async {
    final c = await _launch(tester);
    c.feed();
    await _pumpSeconds(tester, 1);
    await tester.pumpWidget(const SizedBox());
    await _pumpSeconds(tester, 1);
    expect(tester.takeException(), isNull);
  });
}

/// Hosts a bare controller, for builds the game screen doesn't pick (a
/// short-legged dog).
class _ControllerHost extends StatefulWidget {
  const _ControllerHost({required this.shortLegs, required this.onReady});

  final bool shortLegs;
  final void Function(DogGameController controller) onReady;

  @override
  State<_ControllerHost> createState() => _ControllerHostState();
}

class _ControllerHostState extends State<_ControllerHost> with TickerProviderStateMixin {
  late final DogGameController controller = DogGameController(vsync: this, shortLegs: widget.shortLegs);

  @override
  void initState() {
    super.initState();
    widget.onReady(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

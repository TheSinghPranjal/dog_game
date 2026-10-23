import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/dog_game_screen.dart';
import 'package:dog_game/game/models/activity_definition.dart';
import 'package:dog_game/game/models/dog_game_state.dart';
import 'package:dog_game/game/models/game_location.dart';
import 'package:dog_game/home_widget/pet_home_widget_service.dart';
import 'package:dog_game/main.dart';
import 'package:dog_game/navigation/app_launch_router.dart';
import 'package:dog_game/navigation/widget_deep_link_handler.dart';
import 'package:dog_game/screens/splash_screen.dart';
import 'package:dog_game/screens/start_screen.dart';

const _frame = Duration(milliseconds: 16);
const _widgetLink = 'mypetdog://game/home?source=widget';

Future<void> _pumpSeconds(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds; t += 0.016) {
    await tester.pump(_frame);
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

void main() {
  group('AppLaunchRouter', () {
    test('only the exact widget link opens the game', () {
      expect(AppLaunchRouter.parse(_widgetLink), LaunchDestination.gameHome);
      expect(AppLaunchRouter.parse(AppLaunchRouter.widgetLink.toString()), LaunchDestination.gameHome);
      for (final link in [
        null,
        '',
        'not a uri ::',
        'mypetdog://game/home',
        'mypetdog://game/home?source=ad',
        'mypetdog://game/bath?source=widget',
        'mypetdog://shop/home?source=widget',
        'https://game/home?source=widget',
      ]) {
        expect(AppLaunchRouter.parse(link), LaunchDestination.normal, reason: '$link');
      }
    });
  });

  testWidgets('widget cold start goes straight to the playable Home scene', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MyPetDogApp(initialDestination: LaunchDestination.gameHome));
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(DogGameScreen), findsOneWidget);
    final game = tester.state<DogGameScreenState>(find.byType(DogGameScreen)).controller;
    expect(game.location, GameLocation.home);
    expect(game.state, DogGameState.idle);
    expect(find.bySemanticsLabel('Feed the dog'), findsOneWidget);
    expect(find.bySemanticsLabel('Chase the squirrel'), findsOneWidget);

    // Interactive right away.
    await tester.tap(find.bySemanticsLabel('Feed the dog'));
    await tester.pump();
    expect(game.state, DogGameState.walkingToFood);

    // Back leads to the menu, not out of the app.
    await tester.tap(find.bySemanticsLabel('Back to menu'));
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.byType(DogGameScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal launch keeps the splash and menu', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MyPetDogApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    await _pumpSeconds(tester, 3);
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.byType(DogGameScreen), findsNothing);
  });

  testWidgets('warm widget links open the game once and return to Home', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MyPetDogApp());
    await _pumpSeconds(tester, 0.5); // Still on the splash.
    final app = tester.state<MyPetDogAppState>(find.byType(MyPetDogApp));

    app.handleLink('mypetdog://evil/path');
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(DogGameScreen), findsNothing);

    app.handleLink(_widgetLink);
    await _pumpSeconds(tester, 0.6);
    expect(find.byType(DogGameScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    // The splash timer firing later must not navigate away.
    await _pumpSeconds(tester, 3);
    expect(find.byType(DogGameScreen), findsOneWidget);

    // Repeated taps: still a single game screen.
    app.handleLink(_widgetLink);
    app.handleLink(_widgetLink);
    await _pumpSeconds(tester, 0.6);
    expect(find.byType(DogGameScreen), findsOneWidget);

    // From the Bath, a widget tap brings the open game back to Home.
    final game = tester.state<DogGameScreenState>(find.byType(DogGameScreen)).controller;
    game.goTo(GameLocation.bath);
    await _pumpSeconds(tester, 0.6);
    expect(game.location, GameLocation.bath);
    app.handleLink(_widgetLink);
    await _pumpSeconds(tester, 0.6);
    expect(game.location, GameLocation.home);
    expect(find.byType(DogGameScreen), findsOneWidget);

    // Back still reaches the menu.
    await tester.tap(find.bySemanticsLabel('Back to menu'));
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(StartScreen), findsOneWidget);
  });

  group('native channels', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    test('initial link is taken from the launch channel', () async {
      const channel = MethodChannel('test/launch');
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'takeInitialLink');
        return _widgetLink;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      expect(await LaunchLinkChannel(channel: channel).takeInitialLink(), _widgetLink);
    });

    test('missing native side means a normal launch', () async {
      expect(await LaunchLinkChannel(channel: const MethodChannel('test/none')).takeInitialLink(), isNull);
    });

    test('warm links are delivered to the listener', () async {
      const channel = MethodChannel('test/launch_warm');
      final received = <String>[];
      LaunchLinkChannel(channel: channel).listen(received.add);
      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall('onLink', _widgetLink)),
        (_) {},
      );
      expect(received, [_widgetLink]);
    });

    test('widget payload is sent once on flush, with the interaction label', () async {
      const channel = MethodChannel('test/widget');
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final service = PetHomeWidgetService(channel: channel);

      await service.flush();
      expect(calls, isEmpty);

      service.record(location: GameLocation.home, completed: DogActivity.feed);
      service.record(location: GameLocation.bath); // Location change keeps the label.
      await service.flush();
      await service.flush();
      expect(calls, hasLength(1));
      final payload = calls.single.arguments as Map;
      expect(calls.single.method, 'updateWidget');
      expect(payload['schemaVersion'], 1);
      expect(payload['pose'], 'happy');
      expect(payload['location'], 'Bath');
      expect(payload['lastInteraction'], 'Yum! Thanks for dinner!');
    });
  });

  testWidgets('finishing an activity records it for the widget', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MaterialApp(home: DogGameScreen()));
    await tester.pump();
    final game = tester.state<DogGameScreenState>(find.byType(DogGameScreen)).controller;
    game.feed();
    for (var i = 0; i < 1500 && !(game.state == DogGameState.idle && game.lastCompletedActivity != null); i++) {
      await tester.pump(_frame);
    }
    expect(game.lastCompletedActivity, DogActivity.feed);
    expect(PetHomeWidgetService.instance.pending?.lastInteraction, 'Yum! Thanks for dinner!');
  });
}

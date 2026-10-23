# My Pet Dog

A hand-drawn notebook-doodle virtual puppy, built with Flutter only (no game
engine, no extra packages, fully offline).

## Screens

1. **Splash**: the puppy hops and wags while the title fades in, then the
   start screen fades in after 2.4 s (tap to skip). The Android launch theme
   uses the same paper color, so there's no white flash.
2. **Start screen**: the title ("a little notebook puppy"), a dog bowl, a
   tennis ball and the puppy on his rug. Swipe him to meet the other dogs;
   locked dogs are pencil silhouettes with the stars they need. **Play**,
   **How to Play**, and the "+ Add Puppy to your home screen" link.
3. **How to Play**: five illustrated tips and a "Got it!" button.
4. **Game**: the back arrow (top-left) returns to the start screen.

## Home-screen widget

A native widget (Android and iOS) shows the in-game puppy with his tennis ball.
Tapping anywhere on it opens `mypetdog://game/home?source=widget`, which skips
the splash and start screen and lands in the playable Home room. The start
screen sits underneath, so Back still reaches the menu. Normal launches from
the app icon are unchanged.

**How it works**

- **No extra Flutter packages.** Two small method channels:
  `my_pet_dog/launch` delivers launch links and `my_pet_dog/widget` sends a
  tiny payload. Flutter's built-in deep linking is switched off on both
  platforms, so a link can't open a second, duplicate route.
- **Dart:**
  - `lib/navigation/`: `AppLaunchRouter` validates links (anything except the
    exact widget link falls back to the normal start), plus the link channel
    and the named routes.
  - `main.dart` reads the cold-start link before the first frame and handles
    warm links without duplicating screens. A tap while the game is open just
    returns it to Home.
- **Widget payload** (`lib/home_widget/`): the last finished activity's label
  and the current location. It's recorded during play and sent only when the
  app goes to the background or the game closes, so widget reloads stay rare.
- **Android** (`android/app/src/main/kotlin/.../widget/`):
  - `RemoteViews` providers for small (2×2), medium (4×2) and large (4×4).
    Glance would need a Compose toolchain this project doesn't have.
  - The puppy animates through a `ViewFlipper` that the launcher cross-fades
    by itself every 1.8 s. The app is never woken to animate it, and
    `updatePeriodMillis` is 0.
  - `MainActivity` (`singleTop`) passes cold-start and new-intent links on to
    Dart. Android 12+ gets live preview layouts and the system corner radius.
- **iOS** (`ios/PetWidget/`):
  - A WidgetKit/SwiftUI extension with small, medium and large sizes. Its
    timeline shows a new pre-rendered pose roughly every 20 minutes, cross-
    fading on iOS 17+. iOS decides the exact timing.
  - `widgetURL` opens the app. `Runner/LaunchLinkPlugin.swift` receives the URL
    through Flutter's scene-lifecycle plugin hooks for both cold and warm
    starts.
  - The payload is shared through the App Group
    `group.com.thelazybearClub.myPetDog`.
- **Art** (`tool/widget_assets/`): the pose frames (idle, blink, tail up and
  down, looking at the ball, reaching, tapping, happy, resting), plus the
  paper, rug, bowl, ball and picker previews, are rendered from the
  game's own painters. Re-render with
  `flutter test tool/widget_assets/render_widget_assets_test.dart`.
- **Xcode target:** added by `tool/ios/add_widget_extension.rb`
  (idempotent; uses CocoaPods' bundled `xcodeproj` gem).

**Device setup (iOS):** in Xcode, make sure your team (`DU52BN5JF2`) can sign
both `Runner` and `PetWidget`. Then enable the App Groups capability with
`group.com.thelazybearClub.myPetDog` for both targets in the Apple Developer
portal. Without it the widget still works and launches the game, but shows
the default greeting instead of the last activity.

**Limits:** neither OS guarantees continuous widget animation.
- Some Android launchers pause the flipper while it's off screen.
- On iOS, poses change on the system's schedule, not at a fixed interval.

## App icon

The master artwork is `branding/app_icon_source.png`: the crayon "Dog Game:
Doodle Pup" puppy peeking over a bone banner, on black outside its rounded
border so `make_icons.py` can clear the corners. (The older painter-drawn icon
can still be rendered with `flutter test tool/app_icon/render_app_icon_test.dart`,
but that overwrites the source file.) To regenerate every platform's icons after
changing it, run `python3 branding/make_icons.py . /tmp/adaptive_preview.png`
(needs Pillow):

- **Android:** legacy icons, plus an adaptive icon on a paper background.
- **iOS:** opaque icons.
- **macOS, Windows and web:** transparent corners.

## The seven dogs

Saved by id (never rename). Each is one painter plus persona data; every
behaviour difference comes from five traits (energy, curiosity, appetite,
tidiness, cuddliness).

| Dog | Look | Tag | Idle habit | Favourite | Unlock |
| --- | --- | --- | --- | --- | --- |
| Maple | golden retriever, feathered ears and tail | Curious explorer | sniff | Park | always |
| Buddy | chocolate lab, white chest spot | Sweet all-rounder | pant and blink | Home | always |
| Biscuit | chubby corgi, long and low, fox ears | Lazy foodie | chin on paws | Kitchen | always |
| Luna | black-and-white husky, pale blue eyes | Quiet night dog | hide and peek | Living room | always |
| Pepper | wire-haired terrier, beard, short tail | Mischief zoomies | zoomies | Bedroom | always |
| Snowball | fluffy white samoyed, curled tail | Gentle cloud | soft woof | Bath | always |
| Ziggy | dapple dachshund, one ear up | Odd little rocket | scratch an ear | Outdoors | always |

## Places and activities

Switch places with the bottom bar (a 340 ms fade). Navigation and all action
buttons are disabled while an activity runs. Each card's icon is drawn with
the same painter as the prop in the scene.

| Place | Activities |
| --- | --- |
| **Home** | **Feed** (eat, a kibble pops, wag) · **Fetch** (play bow, chase, swat, bring the ball back in his mouth) · **Squirrel** (it scurries A→B→C, he lunges, it escapes into its hole) |
| **Kitchen** | **Glass** (corgi and dachshund climb the stool; taller dogs put their paws up; tap, tap, a soft bonk, "?") · **Treat** (scratch the cabinet, a bone biscuit pops out) · **Dinner** (a drumstick roasts from raw to golden while he waits well away from the stove) |
| **Bath** | **Bath** (foam, hop in with the rubber duck) · **Brush** (slicker brush strokes, sparkles) · **Towel** (rub, shake, droplets) |
| **Outdoors** | **Squirrel** (it shoots up the tree; he only paws at the trunk) · **Dig** (dirt flies, a bone pops out, he parades it) · **Frisbee** (a miss, then a catch) |
| **Bedroom** | **Closet** (tail and ear poke out, a peek, out he pops) · **Slipper** (a gentle shake, proud, dropped; the cable stays untouched) · **Pillow** (one bounce, chin on paws) |
| **Living room** | **Mail** (a knock, two woofs, the envelope stays outside) · **Wag** (a pat, hearts, a blur of a tail) · **Window** (a squirrel on the sill, tail thumps, a sigh) |
| **Park** | **Ducks** (he stops at the bank) · **Leaves** (dive in, out with a stick) · **Pigeon** (sneak, play bow, it flutters to the lamp post) |

Home also has resting props (kibble bowl, tennis ball, knotted rope) that
fade out while their own activity shows the animated version, so there are
never two of them.

## Hide and Seek

Twenty stages, each unlocked by clearing the one before. Dogs hide under big
opaque covers (box, wicker or laundry basket, blanket, leaf heap, grocery
bag, potted plant, a fire hydrant in the park) with small things heaped on
top (books, sun hat, rain boot, paw-print towel, dog pillow, bowl, plate,
tennis ball, rope, frisbee, slipper, rubber duck). Taps hit the drawn shape.
A hint shakes a pile and leaves a wagging tail sticking out.

## Art

All art is drawn procedurally with `CustomPainter` through a small sketch
toolkit (`lib/game/sketch/sketch.dart`): seeded wobbly double ink lines plus
colored-pencil hatching on warm paper. There are **no runtime image assets**.
The puppy is one painter (`DogAnatomy` in `widgets/dog_looks/`, with one
small subclass per breed) whose poses all share the same face, coat,
markings and bottom-centre anchor: idle, walk, pant, scratch an ear, eat,
play bow, happy hop, crouch, lunge, surprised (ears back), sit, lie down,
relax, shake, dig, look up, paws up, beg, roll over, bark (three "woof"
marks), wag, paw, sniff. He can carry a ball, stick, bone, slipper or
frisbee in his mouth.

Review every breed in key poses with
`flutter test tool/contact_sheet/render_contact_sheet_test.dart`
(writes `build/contact_sheet/dogs.png`).

## Structure

```
lib/game/
  dog_game_screen.dart          layers: paper, scene (background + playfield), controls
  controllers/                  the game clock, idle wandering, starting activities
  scripting/                    script steps, the runner, the scene state
  environments/                 each place's scripts, props, layers and keys
  models/                       locations, activities, positions, timings, state
  dogs/                         profiles, personas, needs, reactions
  hide_seek/                    stages, hiding items, screens
  animations/                   pose -> DogFrame, spawn/pop curves
  widgets/                      backgrounds, the dog, props, effects, buttons, navigation
lib/screens/                    splash, start, how-to-play, fade route, title
```

Tune a scene in `game_positions.dart` and `game_timings.dart`. Positions are
normalized (0..1) to the stage and anchored at each sprite's bottom-centre.

## How sequencing works

One `Ticker` drives a clamped game clock. Each activity is a list of script
steps (walk, move, leap, appear, move a prop, pop away, wait, effects) played
by one `ActivityRunner`. Each step resolves to `false` if a newer sequence or
disposal superseded it, so stale steps never touch newer state. A
`try/finally` always clears props and effects, and if anything fails it puts
the dog back on the floor, so he is never left in the air, in the tub or in
the closet. Stopping the ticker when the app is backgrounded freezes
everything, including waits. The dog always moves from his current rendered
position and snaps exactly onto fixed targets, so repeated activities never
drift.

## Tests

`flutter test` runs every activity twice in its place and checks for clean
endings and no drift. It also checks waypoints, the stool and paws-up paths,
that he never nears the stove, climbs the tree or goes into the pond,
location switching and locking, rejected cross-place actions,
background/resume, a short wide screen, and disposal mid-animation.

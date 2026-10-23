import 'dart:math' as math;
import 'dart:ui';

import '../dogs/dog_profile.dart';
import '../models/day_phase.dart';
import '../models/game_location.dart';
import 'hiding_items.dart';

/// One everyday item lying in a pile. [offset] is from the pile's anchor
/// (bottom-centre) in layout units, so piles keep their shape on any screen.
class PlacedItem {
  const PlacedItem({required this.kind, required this.offset, required this.seed, this.flip = false});

  final HidingItem kind;
  final Offset offset;
  final int seed;

  /// Drawn mirrored, so repeated items don't look stamped.
  final bool flip;

  double get width => kind.width;
  double get height => kind.width / kind.aspect;
}

/// A heap of everyday things on the floor, maybe with a dog under it.
class HidingPile {
  const HidingPile({required this.position, required this.items, this.dog});

  /// Bottom-centre of the pile, as a fraction of the stage.
  final Offset position;

  /// Bottom to top: the first item is the big cover, the rest sit on it.
  final List<PlacedItem> items;

  /// The dog hiding underneath, or null for a pile of plain clutter.
  final DogProfile? dog;
}

class HideSeekStage {
  const HideSeekStage({required this.number, required this.location, required this.phase, required this.piles});

  /// 1-based, as shown to the player.
  final int number;
  final GameLocation location;
  final DayPhase phase;

  /// Back to front (sorted by [HidingPile.position] y).
  final List<HidingPile> piles;

  Iterable<DogProfile> get dogs => piles.map((p) => p.dog).nonNulls;

  int get dogCount => piles.where((p) => p.dog != null).length;
}

/// The twenty hide-and-seek stages. Each is built from a fixed seed, so a
/// stage is the same every time it is played.
abstract final class HideSeekStages {
  static const count = 20;

  /// Size of a hiding dog, in layout units.
  static const dogWidth = 0.19;

  /// Dogs hiding in each stage: gently up from one to five.
  static const _dogs = [1, 1, 2, 2, 3, 2, 3, 3, 4, 3, 4, 4, 5, 4, 5, 4, 5, 5, 5, 5];

  static const _locations = [
    GameLocation.home,
    GameLocation.kitchen,
    GameLocation.livingRoom,
    GameLocation.bedroom,
    GameLocation.bath,
    GameLocation.outdoors,
    GameLocation.park,
  ];

  /// Where piles may stand: three rows across the floor and the rug.
  static const _columns = [0.17, 0.39, 0.61, 0.83];
  static const _rows = [0.69, 0.78, 0.87];

  static int dogsIn(int number) => _dogs[number - 1];

  static HideSeekStage build(int number) {
    assert(number >= 1 && number <= count);
    final i = number - 1;
    final rnd = math.Random(7919 * number + 13);
    final location = _locations[i % _locations.length];
    // Morning first, then brighter noon, warm evening and a dim night.
    final phase = DayPhase.values[i * 4 ~/ count];
    final theme = _Theme.of(location);

    final dogs = [...DogProfiles.all]..shuffle(rnd);
    final dogCount = _dogs[i];
    final decoys = math.min(_columns.length * _rows.length - dogCount, 2 + i ~/ 3);
    final maxToppers = 1 + i ~/ 8;

    // Deal slots row by row from the front, so even small stages spread
    // over the whole floor.
    final rows = [
      for (final y in _rows.reversed) [for (final x in _columns) Offset(x, y)]..shuffle(rnd),
    ];
    final slots = [
      for (var c = 0; c < _columns.length; c++)
        for (final row in rows) row[c],
    ];

    final piles = <HidingPile>[];
    for (var p = 0; p < dogCount + decoys; p++) {
      final slot = slots[p];
      final position = slot + Offset((rnd.nextDouble() - 0.5) * 0.05, (rnd.nextDouble() - 0.5) * 0.015);
      final cover = theme.covers[rnd.nextInt(theme.covers.length)];
      final items = [PlacedItem(kind: cover, offset: Offset.zero, seed: rnd.nextInt(1000), flip: rnd.nextBool())];
      // Small things heaped on top of the cover.
      var top = -cover.width / cover.aspect * 0.78;
      final toppers = rnd.nextInt(maxToppers + 1);
      for (var t = 0; t < toppers; t++) {
        final kind = theme.toppers[rnd.nextInt(theme.toppers.length)];
        final dx = (rnd.nextDouble() - 0.5) * (cover.width - kind.width) * 0.8;
        items.add(PlacedItem(kind: kind, offset: Offset(dx, top), seed: rnd.nextInt(1000), flip: rnd.nextBool()));
        top -= kind.width / kind.aspect * 0.62;
      }
      piles.add(HidingPile(position: position, items: items, dog: p < dogCount ? dogs[p] : null));
    }
    piles.sort((a, b) => a.position.dy.compareTo(b.position.dy));
    return HideSeekStage(number: number, location: location, phase: phase, piles: piles);
  }
}

/// Which everyday things belong in each place.
class _Theme {
  const _Theme(this.covers, this.toppers);

  final List<HidingItem> covers;
  final List<HidingItem> toppers;

  static _Theme of(GameLocation location) => switch (location) {
    GameLocation.home => const _Theme(
      [HidingItem.box, HidingItem.basket, HidingItem.blanket, HidingItem.plant],
      [HidingItem.bowl, HidingItem.books, HidingItem.rope, HidingItem.ball, HidingItem.pillow],
    ),
    GameLocation.kitchen => const _Theme(
      [HidingItem.bag, HidingItem.box, HidingItem.basket],
      [HidingItem.bowl, HidingItem.towel, HidingItem.plate, HidingItem.books],
    ),
    GameLocation.bath => const _Theme(
      [HidingItem.laundryBasket, HidingItem.blanket, HidingItem.box],
      [HidingItem.towel, HidingItem.duck, HidingItem.slipper],
    ),
    GameLocation.outdoors => const _Theme(
      [HidingItem.leafHeap, HidingItem.bag, HidingItem.box],
      [HidingItem.hat, HidingItem.boot, HidingItem.frisbee, HidingItem.ball],
    ),
    GameLocation.bedroom => const _Theme(
      [HidingItem.blanket, HidingItem.laundryBasket, HidingItem.box],
      [HidingItem.pillow, HidingItem.books, HidingItem.slipper, HidingItem.boot],
    ),
    GameLocation.livingRoom => const _Theme(
      [HidingItem.box, HidingItem.blanket, HidingItem.plant],
      [HidingItem.pillow, HidingItem.books, HidingItem.rope, HidingItem.ball],
    ),
    GameLocation.park => const _Theme(
      // Mostly leaf heaps; the odd fire hydrant.
      [HidingItem.leafHeap, HidingItem.leafHeap, HidingItem.basket, HidingItem.leafHeap, HidingItem.hydrant],
      [HidingItem.hat, HidingItem.frisbee, HidingItem.ball],
    ),
  };
}

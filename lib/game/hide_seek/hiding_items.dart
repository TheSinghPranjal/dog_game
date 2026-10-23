import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../sketch/sketch.dart';
import '../widgets/food_bowl.dart';
import '../widgets/grooming_props.dart';
import '../widgets/dog_props.dart';
import '../widgets/toy_ball.dart';

/// Everyday things dogs hide under. Covers are big and opaque enough to
/// hide a whole dog; the rest are small things heaped on top.
enum HidingItem {
  box(0.27, 100 / 80, cover: true),
  basket(0.29, 100 / 78, cover: true),
  laundryBasket(0.29, 100 / 78, cover: true),
  blanket(0.30, 100 / 72, cover: true),
  leafHeap(0.31, 100 / 70, cover: true),
  bag(0.24, 100 / 118, cover: true),
  plant(0.22, 100 / 120, cover: true),
  hydrant(0.21, HydrantPainter.aspect, cover: true),
  books(0.13, 100 / 62),
  hat(0.15, 100 / 60),
  boot(0.10, 100 / 110),
  towel(0.15, TowelPainter.aspect),
  pillow(0.18, DogPillowPainter.aspect),
  bowl(0.13, FoodBowl.aspect),
  plate(0.14, DinnerPlatePainter.aspect),
  ball(0.08, 1),
  rope(0.15, RopeToyPainter.aspect),
  frisbee(0.14, FrisbeePainter.aspect),
  slipper(0.13, SlipperPainter.aspect),
  duck(0.09, 1);

  const HidingItem(this.width, this.aspect, {this.cover = false});

  /// Width in layout units.
  final double width;

  /// Width / height of the drawing box.
  final double aspect;
  final bool cover;
}

/// Draws one [HidingItem] in its box (100 units wide), and only reports a
/// hit inside the drawn shape, so taps reach whatever shows through.
class HidingItemPainter extends CustomPainter {
  HidingItemPainter(this.kind, {this.seed = 0, this.flip = false});

  final HidingItem kind;
  final int seed;
  final bool flip;

  Size _size = Size.zero;

  double get _h => 100 / kind.aspect;

  @override
  void paint(Canvas canvas, Size size) {
    _size = size;
    canvas.save();
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    switch (kind) {
      case HidingItem.towel:
        TowelPainter().paint(canvas, size);
      case HidingItem.pillow:
        DogPillowPainter().paint(canvas, size);
      case HidingItem.bowl:
        FoodBowlPainter().paint(canvas, size);
      case HidingItem.plate:
        DinnerPlatePainter(fill: 0).paint(canvas, size);
      case HidingItem.hydrant:
        const HydrantPainter().paint(canvas, size);
      case HidingItem.rope:
        RopeToyPainter().paint(canvas, size);
      case HidingItem.frisbee:
        FrisbeePainter().paint(canvas, size);
      case HidingItem.slipper:
        SlipperPainter().paint(canvas, size);
      case HidingItem.duck:
        const RubberDuckIconPainter().paint(canvas, size);
      case HidingItem.ball:
        // The ball's own box is wider than the ball; centre it.
        final w = size.width / 0.565;
        canvas.translate(size.width / 2 - w * ToyBall.ballCenterX, size.height - w / ToyBall.aspect * 0.94);
        ToyBallPainter(rotation: seed * 0.7).paint(canvas, Size(w, w / ToyBall.aspect));
      default:
        final k = size.width / 100;
        final pen = SketchPen(canvas, pxPerUnit: k);
        canvas.scale(k);
        switch (kind) {
          case HidingItem.box:
            _box(pen);
          case HidingItem.basket:
            _basket(pen, laundry: false);
          case HidingItem.laundryBasket:
            _basket(pen, laundry: true);
          case HidingItem.plant:
            _plant(pen);
          case HidingItem.blanket:
            _blanket(pen);
          case HidingItem.leafHeap:
            _leafHeap(pen);
          case HidingItem.bag:
            _bag(pen);
          case HidingItem.books:
            _books(pen);
          case HidingItem.hat:
            _hat(pen);
          case HidingItem.boot:
            _boot(pen);
          default:
            break;
        }
    }
    canvas.restore();
  }

  @override
  bool hitTest(Offset position) {
    if (_size.isEmpty) return false;
    final k = _size.width / 100;
    final x = flip ? _size.width - position.dx : position.dx;
    return shape.contains(Offset(x / k, position.dy / k));
  }

  /// The item's silhouette in its 100-wide box.
  Path get shape => switch (kind) {
    HidingItem.box => _boxShape,
    HidingItem.basket =>
      Path()
        ..addPath(_basketBody, Offset.zero)
        ..addRect(const Rect.fromLTRB(2, 30, 98, 40)),
    HidingItem.laundryBasket =>
      Path()
        ..addPath(_basketBody, Offset.zero)
        ..addPath(_laundry, Offset.zero),
    HidingItem.plant =>
      Path()
        ..addOval(const Rect.fromLTRB(4, 2, 96, 76))
        ..addRect(const Rect.fromLTRB(20, 64, 80, 120)),
    HidingItem.hydrant => Path()..addRect(Rect.fromLTRB(4, 8, 96, _h)),
    HidingItem.blanket => _blanketShape,
    HidingItem.leafHeap => _heapShape,
    HidingItem.bag =>
      Path()
        ..addPath(_bagBody, Offset.zero)
        ..addRect(const Rect.fromLTRB(26, 2, 74, 30)),
    HidingItem.books => Path()..addRect(Rect.fromLTRB(4, 4, 96, _h)),
    HidingItem.hat =>
      Path()
        ..addOval(Rect.fromLTRB(2, 30, 98, _h))
        ..addOval(const Rect.fromLTRB(24, 4, 76, 50)),
    HidingItem.boot => Path()..addRect(const Rect.fromLTRB(10, 4, 92, 110)),
    _ => Path()..addOval(Rect.fromLTRB(3, 3, 97, _h - 1)),
  };

  // Cardboard box with its flaps open.

  static const _cardboard = Color(0xFFE2B57A);
  static const _cardboardDark = Color(0xFFB98444);

  static final _boxFront = rectPath(10, 28, 90, 80);
  static final _boxInside = polygon(const [Offset(10, 28), Offset(18, 16), Offset(82, 16), Offset(90, 28)]);
  static final _flapLeft = polygon(const [Offset(10, 28), Offset(0, 12), Offset(14, 4), Offset(18, 16)]);
  static final _flapRight = polygon(const [Offset(90, 28), Offset(100, 13), Offset(86, 5), Offset(82, 16)]);
  static final _boxShape = Path()
    ..addPath(_boxFront, Offset.zero)
    ..addPath(_boxInside, Offset.zero)
    ..addPath(_flapLeft, Offset.zero)
    ..addPath(_flapRight, Offset.zero);

  void _box(SketchPen pen) {
    pen.fill(_boxInside, _cardboardDark);
    pen.hatch(_boxInside, const Color(0xFF7A4E2A), spacing: 1.4, seed: seed);
    pen.stroke(_boxInside, SketchColors.ink, width: 1.1, seed: seed + 1);
    for (final flap in [_flapLeft, _flapRight]) {
      pen.fill(flap, _cardboard);
      pen.hatch(flap, _cardboardDark, spacing: 2.2, angle: 0.6, seed: seed + 2);
      pen.stroke(flap, SketchColors.ink, width: 1.1, seed: seed + 3);
    }
    pen.fill(_boxFront, _cardboard);
    pen.hatch(_boxFront, _cardboardDark, spacing: 2.4, seed: seed + 4);
    // Packing tape and a "this way up" doodle.
    final tape = rectPath(44, 28, 56, 80);
    pen.fill(tape, const Color(0xFFF3DDBF));
    pen.stroke(tape, _cardboardDark, width: 0.6, sketchy: false, seed: seed + 5);
    for (final x in const [22.0, 30.0]) {
      pen.line(Offset(x, 66), Offset(x, 54), SketchColors.ink, width: 1, seed: seed + 6);
      pen.line(Offset(x - 3, 57), Offset(x, 53), SketchColors.ink, width: 1, sketchy: false, seed: seed + 7);
      pen.line(Offset(x + 3, 57), Offset(x, 53), SketchColors.ink, width: 1, sketchy: false, seed: seed + 8);
    }
    pen.stroke(_boxFront, SketchColors.ink, width: 1.5, seed: seed + 9);
  }

  // Wicker basket, empty or heaped with laundry.

  static final _basketBody = polygon(const [Offset(5, 34), Offset(95, 34), Offset(87, 78), Offset(13, 78)]);
  static final _laundry = Path()
    ..moveTo(8, 36)
    ..cubicTo(4, 20, 18, 12, 30, 16)
    ..cubicTo(34, 4, 56, 2, 62, 14)
    ..cubicTo(76, 8, 96, 18, 92, 36)
    ..close();

  void _basket(SketchPen pen, {required bool laundry}) {
    if (laundry) _laundryHeap(pen);
    pen.fill(_basketBody, SketchColors.woodLight);
    pen.hatch(_basketBody, SketchColors.wood, spacing: 2.2, angle: 0.8, seed: seed + 5, cross: true);
    for (var y = 44.0; y < 78; y += 8) {
      pen.line(
        Offset(6 + (y - 34) * 0.17, y),
        Offset(94 - (y - 34) * 0.17, y),
        SketchColors.wood,
        width: 0.8,
        seed: seed + y.toInt(),
      );
    }
    final rim = Path()..addRRect(RRect.fromLTRBR(2, 30, 98, 40, const Radius.circular(4)));
    pen.fill(rim, SketchColors.wood);
    pen.stroke(rim, SketchColors.ink, width: 1.1, seed: seed + 6);
    pen.stroke(_basketBody, SketchColors.ink, width: 1.5, seed: seed + 7);
  }

  void _laundryHeap(SketchPen pen) {
    pen.fill(_laundry, const Color(0xFFBFCEF4));
    pen.hatch(_laundry, SketchColors.inkSoft, spacing: 2, angle: -0.5, seed: seed);
    // A pink shirt and a striped sock on the heap.
    final shirt = Path()
      ..moveTo(36, 30)
      ..cubicTo(34, 16, 50, 8, 62, 16)
      ..cubicTo(70, 20, 66, 30, 60, 34)
      ..close();
    pen.fill(shirt, SketchColors.coralLight);
    pen.hatch(shirt, SketchColors.coral, spacing: 1.8, angle: 0.7, seed: seed + 1);
    pen.stroke(shirt, SketchColors.ink, width: 0.8, seed: seed + 2);
    final sock = Path()
      ..moveTo(72, 30)
      ..cubicTo(74, 18, 80, 14, 88, 18)
      ..lineTo(90, 24)
      ..cubicTo(84, 24, 82, 28, 80, 34)
      ..close();
    pen.fill(sock, SketchColors.white);
    pen.canvas.save();
    pen.canvas.clipPath(sock);
    for (var y = 14.0; y < 36; y += 4) {
      pen.line(Offset(68, y), Offset(94, y - 3), SketchColors.leaf, width: 1.4, sketchy: false, wobble: 0);
    }
    pen.canvas.restore();
    pen.stroke(sock, SketchColors.ink, width: 0.8, seed: seed + 3);
    pen.stroke(_laundry, SketchColors.ink, width: 1.1, seed: seed + 4);
  }

  // A big leafy plant in a terracotta pot.

  void _plant(SketchPen pen) {
    final pot = polygon(const [Offset(22, 72), Offset(78, 72), Offset(70, 118), Offset(30, 118)]);
    final rnd = math.Random(seed);
    for (var i = 0; i < 9; i++) {
      final a = -math.pi * (0.1 + 0.8 * i / 8) + (rnd.nextDouble() - 0.5) * 0.2;
      final tip = Offset(50 + math.cos(a) * 46, 70 + math.sin(a) * 64);
      final mid = Offset.lerp(const Offset(50, 72), tip, 0.5)!;
      final n = Offset(-(tip.dy - 72), tip.dx - 50) * 0.18;
      final leaf = Path()
        ..moveTo(50, 72)
        ..quadraticBezierTo(mid.dx + n.dx, mid.dy + n.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(mid.dx - n.dx, mid.dy - n.dy, 50, 72)
        ..close();
      pen.fill(leaf, i.isEven ? const Color(0xFFBFE6B8) : const Color(0xFFA6D99E));
      pen.hatch(leaf, SketchColors.leaf, spacing: 2, angle: a, seed: seed + i);
      pen.stroke(leaf, SketchColors.leafDark, width: 1.1, seed: seed + i);
    }
    pen.fill(pot, SketchColors.coral);
    pen.hatch(pot, SketchColors.cherryDark, spacing: 2.4, angle: -0.6, seed: seed + 20);
    final rim = rectPath(18, 68, 82, 78);
    pen.fill(rim, SketchColors.coral);
    pen.stroke(rim, SketchColors.ink, width: 1.2, seed: seed + 21);
    pen.stroke(pot, SketchColors.ink, width: 1.4, seed: seed + 22);
  }

  // A rumpled patchwork quilt.

  static final _blanketShape = Path()
    ..moveTo(1, 72)
    ..cubicTo(2, 46, 8, 22, 26, 16)
    ..cubicTo(34, 4, 52, 2, 62, 12)
    ..cubicTo(80, 10, 96, 30, 99, 72)
    ..close();

  void _blanket(SketchPen pen) {
    const patches = [Color(0xFFFFE9A8), Color(0xFFFBD9D2), Color(0xFFD7F0D0), Color(0xFFDCE4FA)];
    pen.fill(_blanketShape, patches[0]);
    pen.canvas.save();
    pen.canvas.clipPath(_blanketShape);
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 7; col++) {
        final square = rectPath(col * 15.0 - 2, row * 13.0, col * 15.0 + 13, row * 13.0 + 13);
        pen.fill(square, patches[(row + col + seed) % patches.length]);
        pen.stroke(square, SketchColors.inkSoft.withValues(alpha: 0.5), width: 0.4, sketchy: false, wobble: 0.2);
      }
    }
    pen.hatch(_blanketShape, SketchColors.coral.withValues(alpha: 0.4), spacing: 2.6, angle: -0.7, seed: seed);
    pen.canvas.restore();
    // Folds.
    for (final (a, b, c) in const [
      (Offset(24, 20), Offset(30, 44), Offset(22, 70)),
      (Offset(62, 14), Offset(56, 40), Offset(64, 70)),
      (Offset(82, 30), Offset(78, 50), Offset(86, 70)),
    ]) {
      pen.stroke(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(b.dx, b.dy, c.dx, c.dy),
        SketchColors.ink.withValues(alpha: 0.6),
        width: 0.8,
        seed: seed,
      );
    }
    pen.stroke(_blanketShape, SketchColors.ink, width: 1.5, seed: seed + 1);
  }

  // A heap of autumn leaves.

  static final _heapShape = Path()
    ..moveTo(1, 70)
    ..cubicTo(4, 40, 22, 16, 50, 12)
    ..cubicTo(78, 16, 96, 40, 99, 70)
    ..close();

  void _leafHeap(SketchPen pen) {
    pen.fill(_heapShape, const Color(0xFFF3B060));
    pen.hatch(_heapShape, const Color(0xFFC8682A), spacing: 1.8, angle: -0.5, seed: seed);
    pen.stroke(_heapShape, const Color(0xFFA9551C), width: 1.2, seed: seed + 1);
    final rnd = math.Random(seed);
    const colors = [Color(0xFFE5553A), Color(0xFFF0A20F), Color(0xFFFFCB2E), SketchColors.leaf, Color(0xFFC8682A)];
    for (var i = 0; i < 26; i++) {
      final t = rnd.nextDouble();
      final x = 6 + t * 88;
      final top = 70 - 58 * math.sin(t * math.pi);
      final y = top + rnd.nextDouble() * (70 - top) * 0.85;
      final color = colors[rnd.nextInt(colors.length)];
      final angle = rnd.nextDouble() * math.pi;
      final leaf = ovalPath(
        Offset.zero,
        13,
        6.5,
      ).transform((Matrix4.translationValues(x, y, 0)..rotateZ(angle)).storage);
      pen.fill(leaf, color);
      pen.stroke(leaf, color.withValues(alpha: 0.9), width: 0.6, sketchy: false, wobble: 0.2, seed: i);
      final dir = Offset(math.cos(angle), math.sin(angle));
      pen.line(
        Offset(x, y) - dir * 5,
        Offset(x, y) + dir * 5,
        const Color(0xFF6E3E19).withValues(alpha: 0.6),
        width: 0.4,
        sketchy: false,
        wobble: 0,
      );
    }
  }

  // A paper grocery bag with bread and greens poking out.

  static final _bagBody = polygon(const [Offset(12, 30), Offset(88, 30), Offset(92, 118), Offset(8, 118)]);

  void _bag(SketchPen pen) {
    final bread = Path()..addRRect(RRect.fromLTRBR(28, 2, 46, 40, const Radius.circular(9)));
    pen.fill(bread, const Color(0xFFE7AE63));
    pen.hatch(bread, SketchColors.kibble, spacing: 1.8, seed: seed);
    for (var y = 10.0; y < 32; y += 7) {
      pen.line(Offset(31, y + 3), Offset(43, y), SketchColors.kibbleDark, width: 0.8, sketchy: false);
    }
    pen.stroke(bread, SketchColors.ink, width: 1, seed: seed + 1);
    for (var i = 0; i < 4; i++) {
      final leaf = ovalPath(
        Offset.zero,
        9,
        30,
      ).transform((Matrix4.translationValues(58.0 + i * 4, 18.0 + (i % 2) * 4, 0)..rotateZ(-0.35 + i * 0.25)).storage);
      pen.fill(leaf, i.isEven ? SketchColors.leaf : SketchColors.leafDark);
      pen.stroke(leaf, SketchColors.leafDark, width: 0.7, sketchy: false, seed: seed + i);
    }
    pen.fill(_bagBody, const Color(0xFFDDB27C));
    pen.hatch(_bagBody, const Color(0xFFB98444), spacing: 2.4, angle: -1.2, seed: seed + 2);
    // Folded rim with a zigzag edge, and a doodled heart label.
    final rim = Path()..moveTo(12, 30);
    for (var x = 12.0; x < 88; x += 8) {
      rim
        ..lineTo(x + 4, 36)
        ..lineTo(x + 8, 30);
    }
    pen.stroke(rim, SketchColors.ink.withValues(alpha: 0.7), width: 0.8, sketchy: false, seed: seed + 3);
    final heart = Path()
      ..moveTo(50, 84)
      ..cubicTo(38, 74, 42, 62, 50, 69)
      ..cubicTo(58, 62, 62, 74, 50, 84)
      ..close();
    pen.fill(heart, SketchColors.pink);
    pen.stroke(heart, SketchColors.pinkDeep, width: 0.9, sketchy: false, seed: seed + 4);
    pen.stroke(_bagBody, SketchColors.ink, width: 1.5, seed: seed + 5);
  }

  // A small stack of books.

  void _books(SketchPen pen) {
    const covers = [(Color(0xFF6E86DD), 6.0, 94.0), (Color(0xFFEE7766), 12.0, 88.0), (Color(0xFF45B24F), 4.0, 84.0)];
    for (final (i, (color, l, r)) in covers.indexed) {
      final bottom = 62.0 - i * 19;
      final book = Path()..addRRect(RRect.fromLTRBR(l, bottom - 18, r, bottom - 1, const Radius.circular(3)));
      pen.fill(book, color);
      pen.hatch(book, SketchColors.ink.withValues(alpha: 0.35), spacing: 2, seed: seed + i);
      final pages = rectPath(r - 14, bottom - 15, r - 3, bottom - 4);
      pen.fill(pages, SketchColors.white);
      for (var y = bottom - 13; y < bottom - 4; y += 2.5) {
        pen.line(Offset(r - 13, y), Offset(r - 4, y), SketchColors.graphite, width: 0.4, sketchy: false, wobble: 0);
      }
      pen.stroke(book, SketchColors.ink, width: 1.1, seed: seed + 10 + i);
    }
  }

  // A straw sun hat with a ribbon.

  void _hat(SketchPen pen) {
    final brim = ovalPath(const Offset(50, 46), 96, 26);
    pen.fill(brim, const Color(0xFFF6DD9A));
    pen.hatch(brim, SketchColors.sunEdge, spacing: 1.8, angle: 0.3, seed: seed);
    pen.stroke(brim, SketchColors.ink, width: 1.2, seed: seed + 1);
    final crown = Path()
      ..moveTo(25, 46)
      ..cubicTo(24, 14, 76, 14, 75, 46)
      ..close();
    pen.fill(crown, const Color(0xFFF6DD9A));
    pen.hatch(crown, SketchColors.sunEdge, spacing: 1.8, angle: -0.6, seed: seed + 2);
    final ribbon = Path()
      ..moveTo(25.5, 40)
      ..cubicTo(40, 44, 60, 44, 74.5, 40)
      ..lineTo(75, 46)
      ..cubicTo(60, 50, 40, 50, 25, 46)
      ..close();
    pen.fill(ribbon, SketchColors.pinkDeep);
    pen.stroke(crown, SketchColors.ink, width: 1.2, seed: seed + 3);
    final bow = polygon(const [Offset(66, 44), Offset(80, 38), Offset(80, 52)]);
    pen.fill(bow, SketchColors.pinkDeep);
    pen.stroke(bow, SketchColors.ink, width: 0.8, sketchy: false, seed: seed + 4);
  }

  // A yellow rain boot.

  void _boot(SketchPen pen) {
    final boot = Path()
      ..moveTo(18, 6)
      ..lineTo(62, 6)
      ..lineTo(64, 66)
      ..cubicTo(84, 70, 92, 80, 92, 104)
      ..lineTo(12, 104)
      ..close();
    pen.fill(boot, SketchColors.sun);
    pen.hatch(boot, SketchColors.sunEdge, spacing: 1.8, angle: -0.9, seed: seed);
    final sole = rectPath(10, 98, 94, 108);
    pen.fill(sole, SketchColors.kibbleDark);
    pen.stroke(sole, SketchColors.ink, width: 1, seed: seed + 1);
    final cuff = rectPath(16, 4, 64, 16);
    pen.fill(cuff, SketchColors.sunEdge);
    pen.stroke(boot, SketchColors.ink, width: 1.4, seed: seed + 2);
    pen.stroke(cuff, SketchColors.ink, width: 1, seed: seed + 3);
  }

  @override
  bool shouldRepaint(HidingItemPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.seed != seed || oldDelegate.flip != flip;
}

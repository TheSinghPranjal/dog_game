import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

// The dog's world: things a puppy chases, eats, digs up, chews or wears.
// Every sprite is drawn facing right in its own unit box and anchored
// bottom-centre, like the other props.

const _squirrelFur = Color(0xFFC9773A);
const _squirrelDark = Color(0xFF6E3A17);
const _squirrelBelly = Color(0xFFF6DCB8);
const _biscuit = Color(0xFFE2B077);
const _biscuitEdge = Color(0xFF9A6232);
const _dirt = Color(0xFFB98A5E);
const _dirtDark = Color(0xFF6E4B2C);
const _hydrant = Color(0xFFE2463F);
const _hydrantDark = Color(0xFF9E1F1B);
const _boneWhite = Color(0xFFFFF4DC);

/// A small standing squirrel with a big bushy tail (100x80 box, facing
/// right). Twitches its nose while still, hops while [moving], and holds a
/// stretched mid-hop shape when [hop] is set (the action button).
class SquirrelPainter extends CustomPainter {
  SquirrelPainter({
    this.phase = 0,
    this.moving = false,
    this.facing = 1,
    this.appear = 1,
    this.pop = 0,
    this.hop = false,
  });

  static const aspect = 100 / 80;

  final double phase;
  final bool moving;
  final double facing;
  final double appear;
  final double pop;
  final bool hop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      facing: facing,
      popCenter: const Offset(50, 45),
      popRadius: 40,
      popColor: _squirrelFur,
      draw: (pen) {
        final c = pen.canvas;
        final bounce = hop ? 10.0 : (moving ? (math.sin(phase * 22).abs() * 9) : 0.0);
        final twitch = moving || hop ? 0.0 : math.sin(phase * 18) * 0.8;
        c.save();
        c.translate(0, -bounce);
        if (hop) {
          c.translate(50, 60);
          c.rotate(-0.18);
          c.translate(-50, -60);
        }
        // The bushy S-shaped tail behind the body.
        final tail = Path()
          ..moveTo(30, 66)
          ..cubicTo(6, 64, 4, 36, 18, 24)
          ..cubicTo(28, 14, 44, 18, 38, 30)
          ..cubicTo(32, 40, 22, 36, 26, 28)
          ..cubicTo(18, 40, 22, 56, 40, 58)
          ..close();
        final fluff = pen.wobbly(tail, amplitude: 1.6, seed: 5);
        pen.fill(fluff, _squirrelFur);
        pen.hatch(fluff, _squirrelDark.withValues(alpha: 0.5), spacing: 3, angle: -0.8, width: 1.2, seed: 6);
        pen.stroke(fluff, _squirrelDark, width: 2.4, seed: 7);
        // Body and belly.
        final body = ovalPath(const Offset(50, 56), 34, 36);
        pen.fill(body, _squirrelFur);
        pen.fill(ovalPath(const Offset(56, 60), 16, 24), _squirrelBelly);
        pen.stroke(body, _squirrelDark, width: 2.4, seed: 8);
        // Back feet and the little front paws held up.
        final legs = hop ? 4.0 : 0.0;
        for (final (x, dx) in const [(38.0, -1.0), (54.0, 1.0)]) {
          final foot = ovalPath(Offset(x + dx * legs, 74 + legs * 0.3), 14, 6);
          pen.fill(foot, _squirrelFur);
          pen.stroke(foot, _squirrelDark, width: 2, seed: x.toInt());
        }
        pen.fill(ovalPath(const Offset(64, 50), 7, 6), _squirrelFur);
        pen.stroke(ovalPath(const Offset(64, 50), 7, 6), _squirrelDark, width: 1.8, sketchy: false);
        // Head with ears, eye and a twitching nose.
        final head = ovalPath(Offset(64 + twitch * 0.3, 32), 24, 20);
        pen.fill(head, _squirrelFur);
        for (final x in const [56.0, 64.0]) {
          final ear = polygon([Offset(x, 26), Offset(x + 2, 15), Offset(x + 6, 25)]);
          pen.fill(ear, _squirrelFur);
          pen.stroke(ear, _squirrelDark, width: 1.8, sketchy: false);
        }
        pen.stroke(head, _squirrelDark, width: 2.2, seed: 9);
        pen.fill(ovalPath(const Offset(68, 30), 4.4, 5), SketchColors.pencil);
        pen.fill(ovalPath(const Offset(67, 28.6), 1.6, 1.6), SketchColors.white);
        pen.fill(ovalPath(Offset(76 + twitch, 35), 3.6, 3), SketchColors.pinkDeep);
        c.restore();
        if (hop) {
          for (final (a, b) in const [(Offset(12, 74), Offset(2, 76)), (Offset(16, 80), Offset(6, 84))]) {
            pen.line(a, b, SketchColors.ink, width: 2.4, sketchy: false);
          }
        }
      },
    );
  }

  @override
  bool shouldRepaint(SquirrelPainter old) =>
      old.phase != phase ||
      old.moving != moving ||
      old.facing != facing ||
      old.appear != appear ||
      old.pop != pop ||
      old.hop != hop;
}

/// A bone-shaped dog biscuit, tan with a darker baked edge (100x50 box).
/// [fill] shrinks it while it's eaten.
class BoneTreatPainter extends CustomPainter {
  BoneTreatPainter({this.fill = 1, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 50;

  final double fill;
  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear * (0.35 + 0.65 * fill),
      pop: pop,
      popCenter: const Offset(50, 25),
      popRadius: 40,
      popColor: _biscuitEdge,
      draw: (pen) => drawBoneBiscuit(pen, const Offset(50, 25), 84, 22, seed: 4),
    );
  }

  @override
  bool shouldRepaint(BoneTreatPainter old) => old.fill != fill || old.appear != appear || old.pop != pop;
}

/// A baked bone biscuit centred on [c], [length] long and [thickness] thick.
void drawBoneBiscuit(SketchPen pen, Offset c, double length, double thickness, {int seed = 0}) {
  final bone = bonePath(c, length, thickness);
  pen.fill(bone, _biscuit);
  pen.hatch(
    bone,
    _biscuitEdge.withValues(alpha: 0.45),
    spacing: length / 28,
    angle: -0.7,
    width: length / 70,
    seed: seed,
  );
  // Little baked dots.
  for (final dx in const [-0.18, 0.0, 0.18]) {
    pen.fill(
      ovalPath(c + Offset(dx * length, (dx == 0 ? -0.1 : 0.12) * thickness), length / 30, length / 30),
      _biscuitEdge,
    );
  }
  pen.stroke(bone, _biscuitEdge, width: length / 32, seed: seed + 1);
}

/// A chicken drumstick (100x60 box): pale pink when raw, golden brown when
/// [progress] reaches 1, through a few in-between shades.
class DrumstickPainter extends CustomPainter {
  DrumstickPainter({this.progress = 0, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 60;

  final double progress;
  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      popCenter: const Offset(50, 30),
      popRadius: 40,
      draw: (pen) => drawDrumstick(pen, progress: progress),
    );
  }

  @override
  bool shouldRepaint(DrumstickPainter old) => old.progress != progress || old.appear != appear || old.pop != pop;
}

/// A drumstick in a 100x60 box, meat on the left and the bone on the right.
void drawDrumstick(SketchPen pen, {double progress = 1, double scale = 1}) {
  // Raw pink, then three steps to golden.
  const shades = [Color(0xFFF7C6C0), Color(0xFFF2C38A), Color(0xFFE2A04F), Color(0xFFC77A31)];
  final step = (progress * 3).clamp(0.0, 3.0);
  final i = step.floor().clamp(0, 2);
  final meatColor = Color.lerp(shades[i], shades[i + 1], step - i)!;
  final c = pen.canvas;
  c.save();
  c.translate(50, 30);
  c.scale(scale);
  c.translate(-50, -30);
  // The bone end, with its two knobs.
  final bone = Path.combine(
    PathOperation.union,
    rectPath(56, 26, 84, 34),
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(86, 25), radius: 6))
      ..addOval(Rect.fromCircle(center: const Offset(86, 35), radius: 6)),
  );
  pen.fill(bone, _boneWhite);
  pen.stroke(bone, SketchColors.kibbleDark, width: 2.2, seed: 11);
  // The meat.
  final meat = Path()
    ..moveTo(60, 24)
    ..cubicTo(44, 2, 6, 8, 8, 32)
    ..cubicTo(10, 56, 46, 58, 60, 36)
    ..close();
  pen.fill(meat, meatColor);
  pen.hatch(
    meat,
    Color.lerp(SketchColors.pinkDeep, SketchColors.kibbleDark, progress)!.withValues(alpha: 0.45),
    spacing: 3.2,
    angle: -0.8,
    width: 1.3,
    seed: 12,
  );
  if (progress > 0.66) {
    // Grill marks once it's golden.
    for (final x in const [24.0, 34.0, 44.0]) {
      pen.line(
        Offset(x, 16),
        Offset(x - 6, 46),
        SketchColors.kibbleDark.withValues(alpha: 0.7),
        width: 2,
        sketchy: false,
      );
    }
  }
  pen.stroke(meat, SketchColors.kibbleDark, width: 2.6, seed: 13);
  pen.fill(ovalPath(const Offset(24, 20), 10, 5), SketchColors.white.withValues(alpha: 0.5));
  c.restore();
}

/// A dinner plate (100x45 box) with a roasted drumstick on it; [fill]
/// shrinks the drumstick as it's eaten (0 = empty plate).
class DinnerPlatePainter extends CustomPainter {
  DinnerPlatePainter({this.fill = 1, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 45;

  final double fill;
  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      popCenter: const Offset(50, 30),
      popRadius: 46,
      draw: (pen) => drawDinnerPlate(pen, fill: fill),
    );
  }

  @override
  bool shouldRepaint(DinnerPlatePainter old) => old.fill != fill || old.appear != appear || old.pop != pop;
}

void drawDinnerPlate(SketchPen pen, {double fill = 1}) {
  final plate = ovalPath(const Offset(50, 36), 96, 16);
  pen.fill(plate, SketchColors.white);
  pen.hatch(plate, SketchColors.inkWash, spacing: 3, angle: -0.3, width: 1.2, seed: 21);
  pen.stroke(plate, SketchColors.ink, width: 2.6, seed: 22);
  pen.stroke(ovalPath(const Offset(50, 35), 70, 10), SketchColors.inkSoft, width: 1.4, sketchy: false);
  if (fill > 0.02) {
    final c = pen.canvas;
    c.save();
    c.translate(50, 34);
    c.scale(0.6 * (0.4 + 0.6 * fill));
    c.translate(-50, -44);
    drawDrumstick(pen);
    c.restore();
  }
}

/// Action-button icon: a plate with a roasted drumstick and three steam
/// curls (1:1).
class DinnerIconPainter extends CustomPainter {
  const DinnerIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    canvas.translate(0, 46);
    drawDinnerPlate(pen);
    canvas.translate(0, -46);
    for (final x in const [36.0, 50.0, 64.0]) {
      pen.stroke(
        Path()
          ..moveTo(x, 62)
          ..quadraticBezierTo(x - 6, 52, x, 44)
          ..quadraticBezierTo(x + 6, 36, x, 26),
        SketchColors.inkSoft,
        width: 3,
        sketchy: false,
        wobble: 0.4,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DinnerIconPainter oldDelegate) => false;
}

/// A red frisbee, tilted (100x45 box). With [motionArc] a dashed flight arc
/// trails behind it (the action button).
class FrisbeePainter extends CustomPainter {
  FrisbeePainter({this.rotation = 0, this.appear = 1, this.pop = 0, this.motionArc = false});

  static const aspect = 100 / 45;

  final double rotation;
  final double appear;
  final double pop;
  final bool motionArc;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      popCenter: const Offset(50, 24),
      popRadius: 40,
      popColor: SketchColors.cherry,
      draw: (pen) {
        final c = pen.canvas;
        if (motionArc) {
          for (var i = 0; i < 4; i++) {
            final a = math.pi * (1.1 + i * 0.12);
            pen.stroke(
              Path()..addArc(Rect.fromCircle(center: const Offset(56, 46), radius: 40), a, 0.07),
              SketchColors.inkSoft,
              width: 3,
              sketchy: false,
            );
          }
        }
        c.save();
        c.translate(motionArc ? 62 : 50, 26);
        c.rotate(-0.22 + math.sin(rotation) * 0.12);
        final disc = ovalPath(Offset.zero, 72, 26);
        pen.fill(disc, SketchColors.cherry);
        pen.hatch(
          disc,
          SketchColors.cherryDark.withValues(alpha: 0.5),
          spacing: 3.4,
          angle: -0.6,
          width: 1.2,
          seed: 31,
        );
        pen.stroke(ovalPath(const Offset(0, -2), 46, 13), SketchColors.cherryDark, width: 2, sketchy: false);
        pen.fill(ovalPath(const Offset(-14, -6), 14, 4), SketchColors.white.withValues(alpha: 0.6));
        pen.stroke(disc, SketchColors.cherryDark, width: 2.8, seed: 32);
        c.restore();
      },
    );
  }

  @override
  bool shouldRepaint(FrisbeePainter old) =>
      old.rotation != rotation || old.appear != appear || old.pop != pop || old.motionArc != motionArc;
}

/// A chewed pink house slipper with a bite mark and a loose thread (100x50
/// box, toe on the right).
class SlipperPainter extends CustomPainter {
  SlipperPainter({this.appear = 1, this.pop = 0, this.shake = 0});

  static const aspect = 100 / 50;

  final double appear;
  final double pop;

  /// Gentle side-to-side shake, in radians.
  final double shake;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      popCenter: const Offset(50, 28),
      popRadius: 42,
      popColor: SketchColors.pinkDeep,
      draw: (pen) => drawSlipper(pen, shake: shake),
    );
  }

  @override
  bool shouldRepaint(SlipperPainter old) => old.appear != appear || old.pop != pop || old.shake != shake;
}

void drawSlipper(SketchPen pen, {double shake = 0}) {
  final c = pen.canvas;
  c.save();
  c.translate(50, 44);
  c.rotate(shake);
  c.translate(-50, -44);
  final sole = Path()
    ..moveTo(10, 40)
    ..cubicTo(8, 30, 30, 28, 60, 30)
    ..cubicTo(88, 30, 98, 38, 92, 44)
    ..cubicTo(80, 48, 20, 48, 10, 40)
    ..close();
  pen.fill(sole, const Color(0xFFF7E6D6));
  pen.stroke(sole, SketchColors.kibbleDark, width: 2.2, seed: 41);
  // The fluffy upper over the toes, with a bite taken out of its edge.
  var upper = Path()
    ..moveTo(46, 32)
    ..cubicTo(50, 10, 86, 10, 92, 38)
    ..lineTo(46, 38)
    ..close();
  for (final x in const [56.0, 62.0]) {
    upper = Path.combine(
      PathOperation.difference,
      upper,
      Path()..addOval(Rect.fromCircle(center: Offset(x, 15), radius: 4)),
    );
  }
  pen.fill(upper, SketchColors.pink);
  pen.hatch(upper, SketchColors.pinkDeep, spacing: 3, angle: -0.7, width: 1.2, seed: 42);
  pen.stroke(upper, SketchColors.pinkDeep, width: 2.4, seed: 43);
  // A loose thread curling off the bite.
  pen.stroke(
    Path()
      ..moveTo(59, 17)
      ..quadraticBezierTo(58, 4, 66, 6)
      ..quadraticBezierTo(72, 8, 68, 2),
    SketchColors.pinkDeep,
    width: 1.6,
    sketchy: false,
  );
  c.restore();
}

/// A knotted rope toy, red-and-cream twist with a knot at each end (100x40
/// box).
class RopeToyPainter extends CustomPainter {
  RopeToyPainter({this.appear = 1, this.pop = 0});

  static const aspect = 100 / 40;

  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      popCenter: const Offset(50, 22),
      popRadius: 40,
      draw: (pen) => drawRopeToy(pen),
    );
  }

  @override
  bool shouldRepaint(RopeToyPainter old) => old.appear != appear || old.pop != pop;
}

void drawRopeToy(SketchPen pen) {
  final rope = Path()
    ..moveTo(18, 28)
    ..quadraticBezierTo(50, 14, 82, 28);
  pen.tube(rope, width: 9, outline: SketchColors.kibbleDark, fill: const Color(0xFFF7EBD6), lineWidth: 2, seed: 51);
  // The twist: red stripes slanting along the rope.
  final metric = rope.computeMetrics().first;
  for (var f = 0.12; f < 0.9; f += 0.1) {
    final t = metric.getTangentForOffset(metric.length * f)!;
    final n = Offset(-t.vector.dy, t.vector.dx);
    pen.line(
      t.position - n * 4 - t.vector * 2,
      t.position + n * 4 + t.vector * 2,
      SketchColors.cherry,
      width: 2.2,
      sketchy: false,
    );
  }
  for (final x in const [14.0, 86.0]) {
    final knot = ovalPath(Offset(x, 29), 16, 16);
    pen.fill(knot, const Color(0xFFF7EBD6));
    pen.hatch(knot, SketchColors.cherry, spacing: 3, angle: 0.8, width: 1.6, seed: x.toInt());
    pen.stroke(knot, SketchColors.kibbleDark, width: 2, seed: x.toInt() + 1);
    // Frayed ends.
    final dir = x < 50 ? -1.0 : 1.0;
    for (final dy in const [-4.0, 0.0, 4.0]) {
      pen.line(
        Offset(x + dir * 7, 29 + dy),
        Offset(x + dir * 12, 30 + dy * 1.4),
        SketchColors.kibbleDark,
        width: 1.2,
        sketchy: false,
      );
    }
  }
}

/// A dirt mound with a bone poking out (100x45 box). [dug] 0..1 digs it out:
/// the mound flattens into a hole and the bone is gone (he has it).
/// [tufts] adds two grass tufts (the action button).
class DigMoundPainter extends CustomPainter {
  DigMoundPainter({this.dug = 0, this.tufts = false});

  static const aspect = 100 / 45;

  final double dug;
  final bool tufts;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    final height = 26 * (1 - 0.75 * dug);
    if (dug > 0.3) {
      // The hole he dug, with loose dirt thrown either side.
      final hole = ovalPath(const Offset(50, 40), 40 * dug, 8 * dug);
      pen.fill(hole, _dirtDark);
      for (final x in const [14.0, 86.0]) {
        final heap = ovalPath(Offset(x, 40), 18, 8);
        pen.fill(heap, _dirt);
        pen.stroke(heap, _dirtDark, width: 1.6, sketchy: false);
      }
    }
    final mound = Path()
      ..moveTo(10, 42)
      ..cubicTo(22, 42 - height, 78, 42 - height, 90, 42)
      ..close();
    if (dug < 0.5) {
      // The bone, half buried, sticking up out of the top.
      final c = canvas;
      c.save();
      c.translate(56, 42 - height + 4);
      c.rotate(-0.7);
      final bone = bonePath(Offset.zero, 30, 7);
      pen.fill(bone, _boneWhite);
      pen.stroke(bone, SketchColors.kibbleDark, width: 1.8, sketchy: false, wobble: 0.2);
      c.restore();
    }
    pen.fill(mound, _dirt);
    pen.hatch(mound, _dirtDark.withValues(alpha: 0.6), spacing: 2.6, angle: -0.6, width: 1.1, seed: 61, cross: true);
    for (final (x, y) in const [(30.0, 36.0), (46.0, 30.0), (66.0, 34.0), (58.0, 39.0)]) {
      pen.fill(ovalPath(Offset(x, y + (26 - height) * 0.5), 3, 2), _dirtDark);
    }
    pen.stroke(mound, _dirtDark, width: 2.2, seed: 62);
    if (tufts) {
      for (final x in const [6.0, 94.0]) {
        for (final dx in const [-3.0, 0.0, 3.0]) {
          pen.line(Offset(x, 43), Offset(x + dx * 1.6, 33 + dx.abs()), SketchColors.leafDark, width: 2, sketchy: false);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DigMoundPainter old) => old.dug != dug || old.tufts != tufts;
}

/// A red fire hydrant (60x100 box).
class HydrantPainter extends CustomPainter {
  const HydrantPainter();

  static const aspect = 60 / 100;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    drawHydrant(pen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HydrantPainter oldDelegate) => false;
}

void drawHydrant(SketchPen pen) {
  final base = rectPath(10, 88, 50, 98);
  final body = Path()..addRRect(RRect.fromLTRBR(16, 34, 44, 90, const Radius.circular(4)));
  final dome = Path()
    ..moveTo(14, 36)
    ..cubicTo(14, 14, 46, 14, 46, 36)
    ..close();
  final cap = rectPath(26, 10, 34, 18);
  for (final part in [cap, dome, body, base]) {
    pen.fill(part, _hydrant);
  }
  pen.hatch(body, _hydrantDark.withValues(alpha: 0.5), spacing: 3, angle: -0.7, width: 1.2, seed: 71);
  // Side nozzles and the front cap.
  for (final x in const [4.0, 46.0]) {
    final nozzle = rectPath(x, 46, x + 10, 56);
    pen.fill(nozzle, _hydrant);
    pen.stroke(nozzle, _hydrantDark, width: 2, sketchy: false);
  }
  final front = ovalPath(const Offset(30, 58), 12, 12);
  pen.fill(front, _hydrantDark);
  for (final part in [cap, dome, body, base]) {
    pen.stroke(part, _hydrantDark, width: 2.4, seed: 72);
  }
  pen.line(const Offset(16, 40), const Offset(44, 40), SketchColors.sun, width: 3, sketchy: false);
  pen.fill(ovalPath(const Offset(22, 26), 6, 4), SketchColors.white.withValues(alpha: 0.55));
}

/// A front door with a brass mail slot (60x110 box). [envelope] 0..1 pokes
/// an envelope tip in through the slot (it never comes all the way in);
/// [knock] 0..1 rattles the door. With [nose] a puppy nose presses at the
/// gap (the action button).
class MailDoorPainter extends CustomPainter {
  MailDoorPainter({this.envelope = 0, this.knock = 0, this.nose = false});

  static const aspect = 60 / 110;

  final double envelope;
  final double knock;
  final bool nose;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    canvas.translate(math.sin(knock * math.pi * 6) * knock * 0.8, 0);
    final frame = rectPath(2, 2, 58, 110);
    pen.fill(frame, SketchColors.white);
    pen.stroke(frame, SketchColors.ink, width: 2, seed: 81);
    final door = rectPath(7, 7, 53, 110);
    pen.fill(door, const Color(0xFF8FB8E8));
    pen.hatch(door, SketchColors.ink.withValues(alpha: 0.35), spacing: 3, angle: -0.9, width: 1.1, seed: 82);
    for (final r in [rectPath(13, 14, 47, 42), rectPath(13, 72, 47, 102)]) {
      pen.stroke(r, SketchColors.ink.withValues(alpha: 0.8), width: 1.4, seed: 83);
    }
    pen.stroke(door, SketchColors.ink, width: 2.2, seed: 84);
    // The knob.
    pen.fill(ovalPath(const Offset(46, 60), 6, 6), SketchColors.sun);
    pen.stroke(ovalPath(const Offset(46, 60), 6, 6), SketchColors.sunEdge, width: 1.4, sketchy: false);
    // The mail slot, with an envelope tip poking through it.
    final slot = Path()..addRRect(RRect.fromLTRBR(18, 50, 40, 56, const Radius.circular(2)));
    pen.fill(slot, SketchColors.sun);
    pen.stroke(slot, SketchColors.sunEdge, width: 1.6, sketchy: false);
    pen.fill(rectPath(20, 52, 38, 54), SketchColors.eye);
    if (envelope > 0) {
      final drop = 9 * envelope;
      final env = rectPath(21, 53, 37, 53 + drop);
      pen.fill(env, SketchColors.white);
      pen.stroke(env, SketchColors.inkSoft, width: 1.2, sketchy: false);
      pen.line(const Offset(21, 53), Offset(29, 53 + drop * 0.6), SketchColors.inkSoft, width: 1, sketchy: false);
      pen.line(const Offset(37, 53), Offset(29, 53 + drop * 0.6), SketchColors.inkSoft, width: 1, sketchy: false);
    }
    if (nose) {
      // A puppy nose pressed right up to the gap, with a happy sniff mark.
      final snout = ovalPath(const Offset(29, 70), 20, 12);
      pen.fill(snout, const Color(0xFFE9B27A));
      pen.stroke(snout, SketchColors.kibbleDark, width: 1.8, sketchy: false);
      pen.fill(ovalPath(const Offset(29, 66.5), 10, 6.5), SketchColors.pencil);
      pen.fill(ovalPath(const Offset(27, 65.4), 3, 1.6), SketchColors.white.withValues(alpha: 0.7));
      for (final (a, b) in const [(Offset(16, 62), Offset(12, 58)), (Offset(42, 62), Offset(46, 58))]) {
        pen.line(a, b, SketchColors.ink, width: 1.8, sketchy: false);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MailDoorPainter old) => old.envelope != envelope || old.knock != knock || old.nose != nose;
}

/// A small side table with a lamp on it (40x60 box).
class SideTableLampPainter extends CustomPainter {
  SideTableLampPainter({this.lit = false});

  static const aspect = 40 / 60;

  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    if (lit) pen.fill(ovalPath(const Offset(20, 12), 34, 26), SketchColors.sun.withValues(alpha: 0.25));
    final shade = polygon(const [Offset(11, 4), Offset(29, 4), Offset(34, 18), Offset(6, 18)]);
    pen.fill(shade, const Color(0xFFFFF0C4));
    pen.hatch(shade, SketchColors.sunEdge, spacing: 1.6, angle: -0.6, width: 0.6, seed: 91);
    pen.stroke(shade, SketchColors.ink, width: 1.1, seed: 92);
    pen.line(const Offset(20, 18), const Offset(20, 28), SketchColors.ink, width: 1.4, sketchy: false);
    final base = ovalPath(const Offset(20, 29), 10, 3);
    pen.fill(base, SketchColors.coral);
    pen.stroke(base, SketchColors.ink, width: 0.8, sketchy: false);
    final top = rectPath(2, 30, 38, 34);
    pen.fill(top, SketchColors.wood);
    pen.stroke(top, SketchColors.ink, width: 1.0, seed: 93);
    for (final x in const [6.0, 32.0]) {
      final leg = rectPath(x, 34, x + 2.4, 60);
      pen.fill(leg, SketchColors.wood);
      pen.stroke(leg, SketchColors.ink, width: 0.8, seed: 94);
    }
    pen.line(const Offset(7, 50), const Offset(33, 50), SketchColors.ink, width: 0.8, sketchy: false);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SideTableLampPainter old) => old.lit != lit;
}

/// A round dog pillow with a paw print on it (50x24 box); [squish] 0..1
/// flattens it.
class DogPillowPainter extends CustomPainter {
  DogPillowPainter({this.squish = 0});

  static const aspect = 50 / 24;

  final double squish;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 50;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    final h = 18 * (1 - 0.35 * squish);
    final w = 46 * (1 + 0.06 * squish);
    final pillow = Path()..addRRect(RRect.fromLTRBR(25 - w / 2, 24 - h, 25 + w / 2, 24, Radius.circular(h / 2)));
    pen.fill(pillow, const Color(0xFFCFE4FA));
    pen.hatch(pillow, SketchColors.inkSoft.withValues(alpha: 0.6), spacing: 1.3, angle: -0.5, width: 0.45, seed: 95);
    // The piped edge round the middle.
    pen.stroke(
      Path()..addRRect(RRect.fromLTRBR(25 - w / 2 + 3, 24 - h + 3, 25 + w / 2 - 3, 21, Radius.circular(h / 2 - 3))),
      SketchColors.white,
      width: 0.8,
      sketchy: false,
    );
    pen.stroke(pillow, SketchColors.ink, width: 1.0, seed: 96);
    drawPawPrint(pen, Offset(25, 24 - h / 2), h * 0.42, SketchColors.ink.withValues(alpha: 0.85));
    canvas.restore();
  }

  @override
  bool shouldRepaint(DogPillowPainter old) => old.squish != squish;
}

/// A paw print: a big pad and four toe beans, [size] across, centred on [c].
void drawPawPrint(SketchPen pen, Offset c, double size, Color color) {
  pen.fill(ovalPath(c + Offset(0, size * 0.18), size * 0.62, size * 0.5), color);
  for (final (dx, dy) in const [(-0.38, -0.12), (-0.14, -0.36), (0.14, -0.36), (0.38, -0.12)]) {
    pen.fill(ovalPath(c + Offset(dx * size, dy * size), size * 0.22, size * 0.27), color);
  }
}

/// Action-button icon: a curved, wagging tail with three motion ticks and a
/// small heart (1:1).
class WagIconPainter extends CustomPainter {
  const WagIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    final tail = Path()
      ..moveTo(10, 36)
      ..quadraticBezierTo(8, 24, 14, 16)
      ..quadraticBezierTo(18, 10, 22, 12);
    pen.tube(
      tail,
      width: 6,
      outline: SketchColors.kibbleDark,
      fill: const Color(0xFFF2C277),
      lineWidth: 1.1,
      seed: 101,
    );
    for (final (a, b) in const [
      (Offset(26, 18), Offset(30, 20)),
      (Offset(25, 24), Offset(29.5, 27.5)),
      (Offset(22, 29), Offset(26, 33)),
    ]) {
      pen.line(a, b, SketchColors.ink, width: 1.2, sketchy: false);
    }
    final heart = Path()
      ..moveTo(30, 13)
      ..cubicTo(25, 9, 26, 3, 30, 5.5)
      ..cubicTo(34, 3, 35, 9, 30, 13)
      ..close();
    pen.fill(heart, SketchColors.pink);
    pen.stroke(heart, SketchColors.pinkDeep, width: 0.8, sketchy: false);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WagIconPainter oldDelegate) => false;
}

/// A four-pane window with a squirrel on the outside sill (1:1), for the
/// Window button and the Living room tab.
class SquirrelWindowIconPainter extends CustomPainter {
  const SquirrelWindowIconPainter({this.withSquirrel = true});

  final bool withSquirrel;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    final frame = rectPath(5, 4, 35, 32);
    pen.fill(frame, const Color(0xFFDCEBFB));
    pen.hatch(frame, SketchColors.inkSoft, spacing: 1.6, angle: -0.7, width: 0.4, seed: 111);
    pen.stroke(frame, SketchColors.ink, width: 1.3, seed: 112);
    pen.line(const Offset(20, 4), const Offset(20, 32), SketchColors.ink, width: 1.1, sketchy: false);
    pen.line(const Offset(5, 18), const Offset(35, 18), SketchColors.ink, width: 1.1, sketchy: false);
    final sill = rectPath(2, 32, 38, 35);
    pen.fill(sill, SketchColors.white);
    pen.stroke(sill, SketchColors.ink, width: 1.0, seed: 113);
    if (withSquirrel) {
      canvas.save();
      canvas.translate(17, 18);
      SquirrelPainter().paint(canvas, const Size(15, 12));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SquirrelWindowIconPainter old) => old.withSquirrel != withSquirrel;
}

/// Navigation glyph: a doghouse with a round door and a paw in the doorway.
class DoghouseIconPainter extends CustomPainter {
  const DoghouseIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    final walls = rectPath(9, 18, 31, 36);
    pen.fill(walls, SketchColors.woodLight);
    pen.hatch(walls, SketchColors.wood, spacing: 1.5, width: 0.5, seed: 121);
    pen.stroke(walls, SketchColors.ink, width: 1.2, seed: 122);
    final roof = polygon(const [Offset(5, 20), Offset(20, 6), Offset(35, 20)]);
    pen.fill(roof, SketchColors.coral);
    pen.hatch(roof, SketchColors.cherryDark, spacing: 1.4, angle: 0.6, width: 0.5, seed: 123);
    pen.stroke(roof, SketchColors.ink, width: 1.2, seed: 124);
    final door = Path()
      ..moveTo(15, 36)
      ..lineTo(15, 29)
      ..arcToPoint(const Offset(25, 29), radius: const Radius.circular(5))
      ..lineTo(25, 36)
      ..close();
    pen.fill(door, SketchColors.eye);
    pen.stroke(door, SketchColors.ink, width: 1.0, sketchy: false);
    // A little paw poking out of the doorway.
    final paw = ovalPath(const Offset(21, 35), 6, 3.6);
    pen.fill(paw, const Color(0xFFF2C277));
    pen.stroke(paw, SketchColors.kibbleDark, width: 0.8, sketchy: false);
    for (final dx in const [-1.2, 1.2]) {
      pen.line(Offset(21 + dx, 33.6), Offset(21 + dx, 35), SketchColors.kibbleDark, width: 0.5, sketchy: false);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DoghouseIconPainter oldDelegate) => false;
}

/// Navigation glyph: a bone (1:1).
class BoneIconPainter extends CustomPainter {
  const BoneIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    canvas.translate(20, 20);
    canvas.rotate(-0.5);
    final bone = bonePath(Offset.zero, 32, 8);
    pen.fill(bone, _boneWhite);
    pen.hatch(bone, SketchColors.kibble.withValues(alpha: 0.5), spacing: 1.4, angle: 0.4, width: 0.5, seed: 131);
    pen.stroke(bone, SketchColors.ink, width: 1.3, seed: 132);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BoneIconPainter oldDelegate) => false;
}

/// A yellow rubber duck (1:1), for the Bath tab.
class RubberDuckIconPainter extends CustomPainter {
  const RubberDuckIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    drawRubberDuck(pen, const Offset(20, 33), 1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RubberDuckIconPainter oldDelegate) => false;
}

/// A rubber duck sitting with its bottom at [base], about 30 units wide at
/// scale 1, facing right.
void drawRubberDuck(SketchPen pen, Offset base, double scale) {
  final c = pen.canvas;
  c.save();
  c.translate(base.dx, base.dy);
  c.scale(scale);
  final body = Path()
    ..moveTo(-14, -6)
    ..quadraticBezierTo(-16, 1, -6, 1)
    ..lineTo(9, 1)
    ..quadraticBezierTo(16, 0, 14, -9)
    ..quadraticBezierTo(4, -6, -2, -10)
    ..quadraticBezierTo(-8, -12, -14, -6)
    ..close();
  final head = ovalPath(const Offset(4, -16), 12, 11);
  pen.fill(body, SketchColors.sun);
  pen.fill(head, SketchColors.sun);
  pen.hatch(body, SketchColors.sunEdge, spacing: 1.4, angle: -0.6, width: 0.5, seed: 141);
  pen.stroke(body, SketchColors.sunEdge, width: 1.1, seed: 142);
  pen.stroke(head, SketchColors.sunEdge, width: 1.1, seed: 143);
  final beak = polygon(const [Offset(9, -17), Offset(15, -15.5), Offset(9, -13.5)]);
  pen.fill(beak, SketchColors.coral);
  pen.stroke(beak, SketchColors.cherryDark, width: 0.6, sketchy: false);
  pen.fill(ovalPath(const Offset(5.5, -18), 1.8, 1.8), SketchColors.pencil);
  pen.stroke(
    Path()
      ..moveTo(-6, -6)
      ..quadraticBezierTo(0, -2, 5, -6),
    SketchColors.sunEdge,
    width: 0.9,
    sketchy: false,
  );
  c.restore();
}

/// Navigation glyph: a fire hydrant (1:1).
class HydrantIconPainter extends CustomPainter {
  const HydrantIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    canvas.translate(9.5, 3);
    canvas.scale(0.35);
    drawHydrant(pen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HydrantIconPainter oldDelegate) => false;
}

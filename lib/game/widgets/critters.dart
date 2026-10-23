import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

/// Tiny blue bird (100x90 box, facing right). Flaps while [airborne].
class BirdPainter extends CustomPainter {
  BirdPainter({
    this.phase = 0,
    this.airborne = false,
    this.facing = 1,
    this.appear = 1,
    this.pop = 0,
    this.pigeon = false,
  });

  static const aspect = 100 / 90;

  final double phase;
  final bool airborne;
  final double facing;
  final double appear;
  final double pop;

  /// A soft grey park pigeon instead of a bluebird.
  final bool pigeon;

  Color get _tailColor => pigeon ? const Color(0xFF7D8090) : const Color(0xFF5E9BE0);
  Color get _bodyColor => pigeon ? const Color(0xFFC3C6D2) : const Color(0xFF9CCBF5);
  Color get _bellyColor => pigeon ? const Color(0xFFB9A3D8) : SketchColors.sun.withValues(alpha: 0.9);
  Color get _bellyEdge => pigeon ? const Color(0xFF6FAF8E) : SketchColors.sunEdge;
  Color get _wingColor => pigeon ? const Color(0xFF9EA2B0) : const Color(0xFF6FA8E8);

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      facing: facing,
      popCenter: const Offset(50, 50),
      popRadius: 42,
      draw: _bird,
    );
  }

  void _bird(SketchPen pen) {
    final canvas = pen.canvas;
    final flap = airborne ? math.sin(phase * 28) : (phase % 2.4 < 0.2 ? math.sin(phase * 40) * 0.3 : 0.0);

    if (!airborne) {
      for (final (a, b) in const [(Offset(46, 75), Offset(44, 87)), (Offset(56, 75), Offset(58, 87))]) {
        pen.line(a, b, SketchColors.sunEdge, width: 1.6, sketchy: false, wobble: 0);
        pen.line(b, b + const Offset(4, 0), SketchColors.sunEdge, width: 1.3, sketchy: false, wobble: 0);
      }
    }
    final tail = polygon(const [Offset(24, 46), Offset(4, 38), Offset(6, 56), Offset(26, 58)]);
    pen.fill(tail, _tailColor);
    pen.hatch(tail, SketchColors.ink, spacing: 1.6, seed: 1);
    pen.stroke(tail, SketchColors.ink, width: 1.1, seed: 1);

    final body = ovalPath(const Offset(50, 52), 54, 50);
    pen.fill(body, _bodyColor);
    canvas.save();
    canvas.clipPath(body);
    pen.hatch(body, SketchColors.ink.withValues(alpha: 0.45), spacing: 2.2, seed: 2);
    final belly = ovalPath(const Offset(58, 64), 32, 26);
    pen.fill(belly, _bellyColor);
    pen.hatch(belly, _bellyEdge, spacing: 1.4, seed: 3);
    canvas.restore();
    pen.stroke(body, SketchColors.ink, width: 1.3, seed: 4);

    canvas.save();
    canvas.translate(44, 48);
    canvas.rotate(flap * 0.9);
    final wing = ovalPath(const Offset(-6, 4), 30, 17);
    pen.fill(wing, _wingColor);
    pen.hatch(wing, SketchColors.ink, spacing: 1.5, angle: 0.4, seed: 5);
    pen.stroke(wing, SketchColors.ink, width: 1.1, seed: 5);
    canvas.restore();

    pen.fill(ovalPath(const Offset(64, 42), 6.5, 7.5), SketchColors.eye);
    pen.fill(ovalPath(const Offset(63, 40), 2.2, 2.2), SketchColors.white);
    pen.fill(ovalPath(const Offset(70, 53), 7, 4), SketchColors.pink.withValues(alpha: 0.7));
    final beak = polygon(const [Offset(75, 44), Offset(88, 49), Offset(75, 54)]);
    pen.fill(beak, SketchColors.sunEdge);
    pen.stroke(beak, SketchColors.kibbleDark, width: 0.8, sketchy: false, wobble: 0.1);
    pen.line(const Offset(52, 28), const Offset(49, 21), SketchColors.ink, width: 1.0, sketchy: false);
    pen.line(const Offset(56, 28), const Offset(57, 20), SketchColors.ink, width: 1.0, sketchy: false);
  }

  @override
  bool shouldRepaint(BirdPainter old) =>
      old.phase != phase ||
      old.airborne != airborne ||
      old.facing != facing ||
      old.appear != appear ||
      old.pop != pop ||
      old.pigeon != pigeon;
}

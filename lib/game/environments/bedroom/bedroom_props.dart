import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/game_positions.dart';
import '../../sketch/sketch.dart';

/// The closet: two doors over a drawer. The right door swings open on its
/// hinge ([door] 0..1) onto a dark inside with clothes on hangers, where a
/// hiding dog's eyes shine ([eyes]); with [tail] a wagging tail and one
/// floppy ear poke out of the gap.
class WardrobePainter extends CustomPainter {
  WardrobePainter({this.door = 0, this.eyes = false, this.tail = false, this.time = 0});

  /// Drawn in a 54x120 unit box, anchored bottom-centre.
  static const aspect = 54 / 120;

  final double door;
  final bool eyes;
  final bool tail;
  final double time;

  static const _dark = Color(0xFF2E2838);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 54;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);

    for (final x in const [6.0, 44.0]) {
      final foot = rectPath(x, 113, x + 4, 120);
      pen.fill(foot, SketchColors.wood);
      pen.stroke(foot, SketchColors.ink, width: 0.6, sketchy: false, wobble: 0.1);
    }
    final body = rectPath(2, 7, 52, 115);
    pen.fill(body, SketchColors.woodLight);
    pen.hatch(body, SketchColors.wood.withValues(alpha: 0.55), spacing: 1.5, angle: -1.3, seed: 301);
    pen.stroke(body, SketchColors.ink, width: 1.0, seed: 302);
    final crown = Path()..addRRect(RRect.fromLTRBR(0, 2, 54, 8, const Radius.circular(1.5)));
    pen.fill(crown, SketchColors.wood);
    pen.hatch(crown, SketchColors.kibbleDark.withValues(alpha: 0.5), spacing: 1.0, seed: 303);
    pen.stroke(crown, SketchColors.ink, width: 0.9, seed: 304);
    final drawer = rectPath(6, 103, 48, 111);
    pen.fill(drawer, SketchColors.woodLight);
    pen.stroke(drawer, SketchColors.ink, width: 0.8, seed: 305);
    pen.fill(ovalPath(const Offset(27, 107), 4, 2.2), SketchColors.sunEdge);

    _leftDoor(pen);
    _inside(pen);
    _rightDoor(pen);
    if (tail && door > 0) _giveaway(pen);
    canvas.restore();
  }

  /// A wagging tail low in the gap and a floppy ear higher up.
  void _giveaway(SketchPen pen) {
    final x = _freeEdge - 1;
    final wag = math.sin(time * 12) * 3;
    pen.tube(
      Path()
        ..moveTo(x - 4, 92)
        ..quadraticBezierTo(x + 4, 90, x + 7 + wag * 0.4, 82 + wag),
      width: 3.4,
      outline: SketchColors.kibbleDark,
      fill: const Color(0xFFE3A355),
      lineWidth: 0.6,
      seed: 321,
    );
    for (final (a, b) in [
      (Offset(x + 10, 80 + wag), Offset(x + 13, 79 + wag)),
      (Offset(x + 9, 85 + wag), Offset(x + 12, 86 + wag)),
    ]) {
      pen.line(a, b, SketchColors.graphite, width: 0.6, sketchy: false, wobble: 0);
    }
    final ear = Path()
      ..moveTo(x - 2, 62)
      ..quadraticBezierTo(x + 6, 60, x + 5, 70)
      ..quadraticBezierTo(x + 3, 74, x - 1, 70)
      ..close();
    pen.fill(ear, const Color(0xFFC98A45));
    pen.stroke(ear, SketchColors.kibbleDark, width: 0.6, sketchy: false, wobble: 0.1);
  }

  void _leftDoor(SketchPen pen) {
    final panel = rectPath(6, 11, 27, 100);
    pen.stroke(panel, SketchColors.ink, width: 0.8, seed: 306);
    final inset = Path()..addRRect(RRect.fromLTRBR(9, 15, 24, 96, const Radius.circular(2)));
    pen.stroke(inset, SketchColors.wood, width: 0.7, sketchy: false, wobble: 0.15);
    // A little heart sticker.
    final heart = Path()
      ..moveTo(16.5, 33)
      ..cubicTo(13, 30.5, 14.2, 27, 16.5, 28.8)
      ..cubicTo(18.8, 27, 20, 30.5, 16.5, 33)
      ..close();
    pen.fill(heart, SketchColors.pink);
    pen.stroke(heart, SketchColors.pinkDeep, width: 0.5, sketchy: false);
    pen.fill(ovalPath(const Offset(24.2, 58), 2, 3.4), SketchColors.sunEdge);
  }

  /// Angle of the right door, 0 (shut) to about 83 degrees.
  double get _angle => door.clamp(0.0, 1.0) * 1.45;

  /// x of the right door's free edge as it swings out.
  double get _freeEdge => 48 - 21 * math.cos(_angle);

  void _inside(SketchPen pen) {
    if (door <= 0) return;
    final inside = rectPath(27, 11, 48, 100);
    pen.fill(inside, _dark);
    final canvas = pen.canvas;
    canvas.save();
    canvas.clipPath(inside);
    pen.line(const Offset(27, 17), const Offset(48, 17), SketchColors.graphite, width: 0.8, sketchy: false);
    // A pink dress and a striped top on their hangers.
    for (final (i, (x, color, edge)) in const [
      (33.0, SketchColors.pink, SketchColors.pinkDeep),
      (42.0, SketchColors.inkWash, SketchColors.inkSoft),
    ].indexed) {
      pen.stroke(
        Path()
          ..moveTo(x - 4, 22)
          ..lineTo(x, 18.5)
          ..lineTo(x + 4, 22),
        SketchColors.graphite,
        width: 0.6,
        sketchy: false,
      );
      final cloth = Path()
        ..moveTo(x - 3.5, 22)
        ..lineTo(x + 3.5, 22)
        ..lineTo(x + (i == 0 ? 6.5 : 4.5), i == 0 ? 50 : 40)
        ..lineTo(x - (i == 0 ? 6.5 : 4.5), i == 0 ? 50 : 40)
        ..close();
      pen.fill(cloth, color.withValues(alpha: 0.75));
      pen.hatch(cloth, edge.withValues(alpha: 0.6), spacing: 1.2, angle: i == 0 ? -1.0 : 0, seed: 307 + i);
    }
    if (eyes) {
      // Two glowing eyes in the gap, with an occasional blink.
      final cx = (27 + _freeEdge) / 2;
      final blink = (time % 2.6) < 0.14 ? 0.15 : 1.0;
      for (final dx in const [-1.6, 1.6]) {
        final eye = ovalPath(Offset(cx + dx, 76), 2.6, 2.6 * blink);
        pen.fill(eye, const Color(0xFFF2D9A6));
        pen.fill(ovalPath(Offset(cx + dx, 76), 1.6, 1.6 * blink), SketchColors.eye);
        pen.fill(ovalPath(Offset(cx + dx - 0.5, 75.4), 0.6, 0.6 * blink), SketchColors.white);
      }
    }
    canvas.restore();
  }

  void _rightDoor(SketchPen pen) {
    final a = _angle;
    final xf = _freeEdge;
    final grow = 3.5 * math.sin(a);
    final panel = polygon([Offset(xf, 11 - grow), const Offset(48, 11), const Offset(48, 100), Offset(xf, 100 + grow)]);
    pen.fill(panel, SketchColors.woodLight);
    pen.hatch(
      panel,
      SketchColors.wood.withValues(alpha: 0.4 + 0.4 * door),
      spacing: 1.5 - 0.5 * door,
      angle: -1.3,
      seed: 309,
    );
    pen.stroke(panel, SketchColors.ink, width: 0.8, seed: 310);
    final knobX = xf + (48 - xf) * 0.12;
    pen.fill(ovalPath(Offset(knobX + 1, 58), 2 * math.max(0.4, math.cos(a)), 3.4), SketchColors.sunEdge);
  }

  @override
  bool shouldRepaint(WardrobePainter oldDelegate) =>
      oldDelegate.door != door ||
      oldDelegate.eyes != eyes ||
      oldDelegate.tail != tail ||
      ((eyes || tail) && oldDelegate.time != time);
}

/// The phone charger: a plug in the wall socket, the cable along the floor,
/// and the phone charging at its end. Paints over the whole stage, in stage
/// coordinates. The dog leaves it alone.
class ChargerCablePainter extends CustomPainter {
  ChargerCablePainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final k = unit / 100;
    final pen = SketchPen(canvas, pxPerUnit: k);
    Offset at(Offset n) => Offset(n.dx * size.width / k, n.dy * size.height / k);
    canvas.save();
    canvas.scale(k);

    final plug = at(BedroomPositions.socketPosition);
    final floor = at(Offset(BedroomPositions.socketPosition.dx + 0.01, 0.646));
    final mid = at(BedroomPositions.cableRestPoint);
    final phone = at(BedroomPositions.phonePosition);
    final cable = Path()
      ..moveTo(plug.dx, plug.dy + 2)
      ..quadraticBezierTo(plug.dx - 1, floor.dy - 2, floor.dx, floor.dy)
      ..quadraticBezierTo(floor.dx + 1, mid.dy - 1, mid.dx, mid.dy)
      ..quadraticBezierTo(mid.dx + 5, mid.dy + 0.6, phone.dx - 2.2, phone.dy - 0.6);
    pen.tube(cable, width: 1.4, outline: SketchColors.graphite, fill: SketchColors.white, lineWidth: 0.4, seed: 330);
    // The plug.
    final head = Path()
      ..addRRect(
        RRect.fromLTRBR(plug.dx - 1.6, plug.dy - 1.4, plug.dx + 1.6, plug.dy + 2.4, const Radius.circular(0.6)),
      );
    pen.fill(head, SketchColors.white);
    pen.stroke(head, SketchColors.ink, width: 0.5, sketchy: false, wobble: 0.1);

    // The phone, propped on the floor, charging.
    canvas.save();
    canvas.translate(phone.dx, phone.dy);
    canvas.rotate(-0.22);
    canvas.scale(0.6);
    final body = Path()..addRRect(RRect.fromLTRBR(-3.6, -7.5, 3.6, 0, const Radius.circular(1.2)));
    pen.fill(body, SketchColors.pencil);
    pen.stroke(body, SketchColors.ink, width: 0.5, sketchy: false, wobble: 0.1);
    final screen = rectPath(-2.8, -6.6, 2.8, -0.9);
    pen.fill(screen, SketchColors.inkWash);
    final battery = rectPath(-1.4, -4.6, 1.4, -2.6);
    pen.stroke(battery, SketchColors.leafDark, width: 0.35, sketchy: false, wobble: 0);
    pen.fill(rectPath(-1.4, -4.6, 0.6, -2.6), SketchColors.leaf);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChargerCablePainter oldDelegate) => oldDelegate.unit != unit;
}

/// Navigation icon: a little bed.
class BedIconPainter extends CustomPainter {
  const BedIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final frame = Path()
      ..moveTo(3, 8)
      ..lineTo(3, 35)
      ..moveTo(3, 27)
      ..lineTo(37, 27)
      ..lineTo(37, 35);
    final mattress = Path()..addRRect(RRect.fromLTRBR(4, 19, 37, 27, const Radius.circular(2.5)));
    pen.fill(mattress, color.withValues(alpha: 0.85));
    final pillow = Path()..addRRect(RRect.fromLTRBR(5.5, 13, 16, 19.5, const Radius.circular(3)));
    pen.fill(pillow, SketchColors.white);
    pen.stroke(pillow, color, width: 1.2, wobble: 0.3, seed: 351);
    pen.stroke(mattress, color, width: 1.4, wobble: 0.3, seed: 352);
    pen.stroke(frame, color, width: 2.0, sketchy: false, wobble: 0.2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BedIconPainter oldDelegate) => oldDelegate.color != color;
}

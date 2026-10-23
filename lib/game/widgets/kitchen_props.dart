import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

/// Small drinking glass (100x140 box). [rotation] tips it around its base.
class GlassPainter extends CustomPainter {
  GlassPainter({this.rotation = 0, this.appear = 1, this.pop = 0, this.motionMarks = false});

  static const aspect = 100 / 140;

  final double rotation;
  final double appear;
  final double pop;

  /// Two little "wobble" marks, used on the action button.
  final bool motionMarks;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      popCenter: const Offset(50, 80),
      popRadius: 50,
      draw: (pen) {
        final c = pen.canvas;
        c.save();
        c.translate(50, 136);
        c.rotate(rotation);
        c.translate(-50, -136);
        final glass = Path()
          ..moveTo(18, 14)
          ..lineTo(82, 14)
          ..lineTo(74, 132)
          ..quadraticBezierTo(50, 138, 26, 132)
          ..close();
        pen.fill(glass, const Color(0xFFF3F7FF));
        final water = Path()
          ..moveTo(23.5, 62)
          ..quadraticBezierTo(50, 68, 77, 62)
          ..lineTo(74, 132)
          ..quadraticBezierTo(50, 138, 26, 132)
          ..close();
        pen.fill(water, SketchColors.inkWash.withValues(alpha: 0.7));
        pen.hatch(water, SketchColors.inkSoft, spacing: 5, angle: -0.6, width: 1.4, seed: 1);
        pen.line(const Offset(30, 24), const Offset(34, 120), SketchColors.white, width: 6, sketchy: false, wobble: 0);
        pen.stroke(glass, SketchColors.ink, width: 3.4, seed: 2);
        pen.stroke(ovalPath(const Offset(50, 14), 64, 9), SketchColors.ink, width: 2.6, seed: 3);
        c.restore();
        if (motionMarks) {
          for (final (a, b) in const [(Offset(90, 40), Offset(98, 30)), (Offset(92, 60), Offset(100, 56))]) {
            pen.line(a, b, SketchColors.ink, width: 3.4, sketchy: false);
          }
        }
      },
    );
  }

  @override
  bool shouldRepaint(GlassPainter old) =>
      old.rotation != rotation || old.appear != appear || old.pop != pop || old.motionMarks != motionMarks;
}

/// The treat cabinet's door as it opens. Drawn over the static door in the
/// background at exactly the same rect: the dark inside with a treat jar,
/// and the door panel swinging toward its left hinge.
class CabinetDoorPainter extends CustomPainter {
  CabinetDoorPainter({required this.open});

  /// 0 closed (nothing drawn), small values rattle, 1 fully open.
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    if (open <= 0) return;
    final pen = SketchPen(canvas, pxPerUnit: size.width / 30);
    final w = size.width, h = size.height;
    final inside = rectPath(0, 0, w, h);
    pen.fill(inside, const Color(0xFF3B3F63));
    pen.hatch(inside, SketchColors.ink, spacing: w / 14, seed: 1, cross: true);
    // Treat jar on the shelf inside.
    final jar = Path()..addRRect(RRect.fromLTRBR(w * 0.52, h * 0.38, w * 0.86, h * 0.8, Radius.circular(w * 0.05)));
    pen.fill(jar, const Color(0xFFFDE6C8));
    pen.stroke(jar, SketchColors.coral, width: w / 60, seed: 2);
    pen.line(Offset(0, h * 0.82), Offset(w, h * 0.82), SketchColors.inkWash, width: w / 50, sketchy: false);

    // Door panel: shrinks toward the left hinge as it swings open.
    final panelWidth = w * (1 - 0.85 * open.clamp(0.0, 1.0));
    final panel = rectPath(0, 0, panelWidth, h);
    pen.fill(panel, SketchColors.white);
    pen.hatch(panel, SketchColors.woodLight, spacing: w / 18, angle: -1.3, width: w / 120, seed: 3);
    pen.stroke(panel, SketchColors.ink, width: w / 45, seed: 4);
    pen.fill(ovalPath(Offset(panelWidth * 0.82, h * 0.5), w * 0.07, w * 0.07), SketchColors.ink);
  }

  @override
  bool shouldRepaint(CabinetDoorPainter old) => old.open != open;
}

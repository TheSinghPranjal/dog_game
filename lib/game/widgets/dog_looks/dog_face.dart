part of 'dog_anatomy.dart';

/// Head, ears, collar and face of [DogAnatomy].
extension _DogFace on DogAnatomy {
  /// Head outline: a soft round dome, wider at the cheeks; fluffy dogs get
  /// cheek tufts.
  Path _headPath(Offset hc) {
    final path = Path();
    const n = 160;
    final cheeks = _chubby ? 1.6 : 0.0;
    for (var i = 0; i <= n; i++) {
      final t = i / n * math.pi * 2;
      final sin = math.sin(t), cos = math.cos(t);
      // Wider below the eyes than across the crown.
      final rx = 20.5 + cheeks + (2.0 + cheeks) * math.max(0, sin), ry = sin < 0 ? 17.5 : 16.0;
      var extra = 0.0;
      if (wiry) {
        // Scruffy wire hair all round.
        extra = 0.9 * math.sin(t * 34) * (sin > -0.3 ? 1 : 0.6);
      }
      if (fluffy) {
        // Cheek fluff on both sides, below the eyes.
        for (final (from, to) in const [(0.05, 1.05), (2.09, 3.09)]) {
          if (t > from && t < to) {
            final u = (t - from) / (to - from) * 4;
            final saw = u - u.floorToDouble();
            extra = 3.0 * (1 - (2 * saw - 1).abs()) * math.sin(math.pi * u / 4);
          }
        }
      }
      final x = (rx + extra) * cos;
      final y = (ry + extra) * sin + 1;
      if (i == 0) {
        path.moveTo(hc.dx + x, hc.dy + y);
      } else {
        path.lineTo(hc.dx + x, hc.dy + y);
      }
    }
    return path..close();
  }

  /// Draws the head and returns its center (before tilt).
  Offset _head(SketchPen pen) {
    final hc = Offset(70, 35 + _drop * 0.85) + frame.headOffset;
    final pivot = Offset(62, 53 + _drop) + frame.headOffset;
    final canvas = pen.canvas;
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(frame.headTilt);
    canvas.translate(-pivot.dx, -pivot.dy);
    // A slightly bigger head than body, puppy proportions.
    canvas.translate(hc.dx, hc.dy + 8);
    canvas.scale(1.08);
    canvas.translate(-hc.dx, -hc.dy - 8);

    // Upright ears go behind the head; pinned back when surprised.
    final back = frame.earsBack ? 0.45 : 0.0;
    if (earStyle == EarStyle.pointed) _pointedEarAt(pen, hc, -1, -back, 31);
    if (earStyle == EarStyle.pointed || earStyle == EarStyle.mixed) {
      _pointedEarAt(pen, hc, 1, frame.earTwitch + back, 32, cocked: earStyle == EarStyle.mixed);
    }
    _collar(pen, hc);

    final head = _headPath(hc);
    pen.fill(head, coat.fur);
    canvas.save();
    canvas.clipPath(head);
    pen.hatch(
      rectPath(hc.dx - 23, hc.dy - 19, hc.dx + 23, hc.dy - 10),
      coat.shade.withValues(alpha: coat.headShade),
      spacing: 1.4,
      angle: -0.8,
      width: 0.4,
      seed: 8,
    );
    paintHeadInside(pen, hc);
    // The snout patch.
    final muzzle = ovalPath(hc + const Offset(0, 9.6), 20, 12.5);
    pen.fill(muzzle, coat.muzzle);
    canvas.restore();
    // A soft line over the top of the snout, so it reads as a muzzle.
    pen.stroke(
      Path()..addArc(
        Rect.fromCenter(center: hc + const Offset(0, 9.8), width: 20, height: 12.5),
        math.pi * 1.1,
        math.pi * 0.8,
      ),
      coat.line.withValues(alpha: 0.45),
      width: 0.6,
      sketchy: false,
      wobble: 0.1,
    );
    paintHeadMarks(pen, hc);
    pen.stroke(head, coat.line, width: _line, wobble: 0.15, seed: 33);
    if (fluffy) {
      // Crown wisp.
      for (final (a, b) in const [
        (Offset(-1.5, -16.8), Offset(-2.6, -19.6)),
        (Offset(0, -17), Offset(0.4, -20.4)),
        (Offset(1.5, -16.8), Offset(3, -19.3)),
      ]) {
        pen.line(hc + a, hc + b, coat.line, width: 0.65, sketchy: false, wobble: 0.05);
      }
    }

    // Floppy ears hang over the sides of the head; flung up when surprised.
    final fling = frame.earsBack ? 0.7 : 0.0;
    if (earStyle == EarStyle.floppy || earStyle == EarStyle.mixed) _floppyEar(pen, hc, -1, fling, 31);
    if (earStyle == EarStyle.floppy) _floppyEar(pen, hc, 1, frame.earTwitch * 1.4 + fling, 32);
    if (wiry) _eyebrows(pen, hc);

    for (final side in const [-1.0, 1.0]) {
      final cheek = ovalPath(hc + Offset(14 * side, 8), 7, 4);
      pen.fill(cheek, SketchColors.pink.withValues(alpha: coat.blush));
      pen.hatch(cheek, SketchColors.pinkDeep, spacing: 0.8, angle: -0.4, width: 0.4, seed: 9);
    }
    _eye(pen, hc + const Offset(-8.2, 0.2));
    _eye(pen, hc + const Offset(8.2, 0.2));
    _mouth(pen, hc);
    if (wiry) _beard(pen, hc);
    _muzzleDots(pen, hc);
    _carried(pen, hc);
    _tag(pen, hc);
    paintAccessories(pen, hc);

    canvas.restore();
    return hc;
  }

  /// A long soft ear hanging beside the face on [side] (-1 left, 1 right),
  /// flapped outward by [flap] radians from its root.
  void _floppyEar(SketchPen pen, Offset hc, int side, double flap, int seed) {
    final k = earScale;
    Offset p(double x, double y) => hc + Offset((9.5 + (x - 9.5) * k) * side, -15.5 + (y + 15.5) * k);
    final ear = Path()
      ..moveTo(p(9.5, -15.5).dx, p(9.5, -15.5).dy)
      ..quadraticBezierTo(p(18, -19.5).dx, p(18, -19.5).dy, p(22, -10).dx, p(22, -10).dy)
      ..cubicTo(p(26, -3).dx, p(26, -3).dy, p(26.5, 6).dx, p(26.5, 6).dy, p(23, 11).dx, p(23, 11).dy)
      ..quadraticBezierTo(p(19.5, 15.5).dx, p(19.5, 15.5).dy, p(16, 10.5).dx, p(16, 10.5).dy)
      ..cubicTo(p(14.5, 4).dx, p(14.5, 4).dy, p(14, -6).dx, p(14, -6).dy, p(9.5, -15.5).dx, p(9.5, -15.5).dy)
      ..close();
    final canvas = pen.canvas;
    canvas.save();
    final root = p(13, -14);
    canvas.translate(root.dx, root.dy);
    canvas.rotate(-flap * side);
    canvas.translate(-root.dx, -root.dy);
    pen.fill(ear, coat.ear);
    canvas.save();
    canvas.clipPath(ear);
    // Shade on the inner edge, where the ear curls toward the face.
    pen.hatch(
      ovalPath(p(15, 2), 8, 26),
      coat.shade.withValues(alpha: coat.headShade + 0.1),
      spacing: 1.2,
      angle: 0.9 * side,
      width: 0.4,
      seed: seed,
    );
    paintEarMarks(pen, ear, side);
    canvas.restore();
    pen.stroke(ear, coat.line, width: _line, wobble: 0.12, seed: seed);
    if (featheredEars) {
      // Silky fringe wisps along the bottom of the ear.
      for (final (x, y) in const [(16.5, 11.0), (19.5, 13.6), (22.5, 12.4), (24.6, 8.0)]) {
        pen.stroke(
          Path()
            ..moveTo(p(x, y - 1.5).dx, p(x, y - 1.5).dy)
            ..quadraticBezierTo(
              p(x + 0.6, y + 1).dx,
              p(x + 0.6, y + 1).dy,
              p(x - 0.4, y + 2.6).dx,
              p(x - 0.4, y + 2.6).dy,
            ),
          coat.line,
          width: 0.6,
          sketchy: false,
          wobble: 0,
        );
      }
    }
    canvas.restore();
  }

  /// An upright ear on [side] (-1 far, 1 near), tilted by [tilt]. A
  /// [cocked] ear stands up halfway and its tip folds forward.
  void _pointedEarAt(SketchPen pen, Offset hc, int side, double tilt, int seed, {bool cocked = false}) {
    final k = earScale * (cocked ? 0.8 : 1);
    Offset p(double x, double y) => hc + Offset(x * side, y);
    final base = p(11, -11);
    final canvas = pen.canvas;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(tilt * side);
    canvas.translate(-base.dx, -base.dy);
    final tipY = -15 - 16 * k;
    _pointedEar(pen, [p(21, -5), p(18.5, tipY), p(6, -15.5)], seed);
    if (cocked) {
      // The tip flops forward over a crease.
      final a = Offset.lerp(p(21, -5), p(18.5, tipY), 0.62)!;
      final b = Offset.lerp(p(6, -15.5), p(18.5, tipY), 0.62)!;
      final flap = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(p(16, tipY + 13).dx, p(16, tipY + 13).dy, b.dx, b.dy)
        ..close();
      pen.fill(flap, coat.ear);
      pen.stroke(flap, coat.line, width: _line, wobble: 0.1, seed: seed + 1);
    }
    canvas.restore();
  }

  /// Bushy terrier eyebrows.
  void _eyebrows(SketchPen pen, Offset hc) {
    for (final side in const [-1.0, 1.0]) {
      for (final (a, b) in const [
        (Offset(4.5, -6.5), Offset(9, -8.6)),
        (Offset(6.5, -6.3), Offset(11.5, -8.0)),
        (Offset(8.5, -6.0), Offset(13, -7.0)),
      ]) {
        pen.line(
          hc + Offset(a.dx * side, a.dy),
          hc + Offset(b.dx * side, b.dy),
          coat.line,
          width: 0.8,
          sketchy: false,
          wobble: 0.1,
        );
      }
    }
  }

  /// A scruffy beard under the muzzle.
  void _beard(SketchPen pen, Offset hc) {
    final beard = Path()..moveTo(hc.dx - 7, hc.dy + 12);
    for (var i = 0; i <= 7; i++) {
      final x = hc.dx - 7 + i * 2;
      beard.lineTo(x + 1, hc.dy + 17.5 + (i.isEven ? 1.6 : 0) - (i - 3.5).abs() * 0.5);
      beard.lineTo(x + 2, hc.dy + 14.5);
    }
    beard.lineTo(hc.dx + 7, hc.dy + 12);
    pen.fill(beard, coat.muzzle);
    pen.stroke(beard, coat.line, width: 0.6, sketchy: false, wobble: 0.1);
  }

  /// Whatever he is carrying, held across the mouth.
  void _carried(SketchPen pen, Offset hc) {
    final at = hc + const Offset(2, 12.5);
    switch (frame.carry) {
      case DogCarry.none:
        return;
      case DogCarry.ball:
        final ball = ovalPath(at + const Offset(2, 1), 9, 9);
        pen.fill(ball, const Color(0xFFD4E43A));
        pen.stroke(
          Path()
            ..moveTo(at.dx - 1, at.dy - 3.2)
            ..quadraticBezierTo(at.dx + 3, at.dy + 1, at.dx - 1, at.dy + 5),
          SketchColors.white,
          width: 1.1,
          sketchy: false,
          wobble: 0,
        );
        pen.stroke(ball, const Color(0xFF6E7C12), width: 0.8, sketchy: false, wobble: 0.1);
      case DogCarry.stick:
        pen.tube(
          Path()
            ..moveTo(at.dx - 13, at.dy - 1)
            ..lineTo(at.dx + 14, at.dy + 1.5),
          width: 2.4,
          outline: SketchColors.kibbleDark,
          fill: SketchColors.wood,
          lineWidth: 0.6,
          seed: 71,
        );
        pen.line(
          at + const Offset(8, 1),
          at + const Offset(11, -2.5),
          SketchColors.kibbleDark,
          width: 1.0,
          sketchy: false,
        );
      case DogCarry.bone:
        final bone = bonePath(at + const Offset(1, 0.5), 16, 4);
        pen.fill(bone, const Color(0xFFFFF4DC));
        pen.stroke(bone, coat.line, width: 0.7, sketchy: false, wobble: 0.1);
      case DogCarry.slipper:
        final slipper = ovalPath(at + const Offset(3, 3), 16, 7);
        pen.fill(slipper, SketchColors.pink);
        pen.hatch(slipper, SketchColors.pinkDeep, spacing: 1.1, angle: -0.5, width: 0.4, seed: 72);
        pen.stroke(slipper, coat.line, width: 0.7, sketchy: false, wobble: 0.1);
      case DogCarry.frisbee:
        final disc = ovalPath(at + const Offset(4, 1), 18, 6);
        pen.fill(disc, SketchColors.cherry);
        pen.stroke(disc, SketchColors.cherryDark, width: 0.9, sketchy: false, wobble: 0.1);
        pen.stroke(
          ovalPath(at + const Offset(4, 0.6), 11, 3),
          SketchColors.cherryDark,
          width: 0.5,
          sketchy: false,
          wobble: 0,
        );
    }
  }

  /// An upright ear from its base corners and tip: broad at the base with
  /// a soft rounded tip, and a warm furry inside.
  void _pointedEar(SketchPen pen, List<Offset> p, int seed) {
    Path earPath(List<Offset> q) => Path()
      ..moveTo(q[0].dx, q[0].dy)
      ..quadraticBezierTo(
        Offset.lerp(q[0], q[1], 0.5)!.dx + (q[0].dx - q[2].dx) * 0.08,
        Offset.lerp(q[0], q[1], 0.5)!.dy,
        Offset.lerp(q[0], q[1], 0.78)!.dx,
        Offset.lerp(q[0], q[1], 0.78)!.dy,
      )
      ..quadraticBezierTo(q[1].dx, q[1].dy - 1.5, Offset.lerp(q[1], q[2], 0.24)!.dx, Offset.lerp(q[1], q[2], 0.24)!.dy)
      ..quadraticBezierTo(
        Offset.lerp(q[1], q[2], 0.55)!.dx + (q[2].dx - q[0].dx) * 0.08,
        Offset.lerp(q[1], q[2], 0.55)!.dy,
        q[2].dx,
        q[2].dy,
      )
      ..close();
    final outer = earPath(p);
    pen.fill(outer, coat.ear);
    final c = (p[0] + p[1] + p[2]) / 3;
    final inner = earPath([for (final q in p) c + (q - c) * 0.6 + const Offset(0, 1.8)]);
    pen.fill(inner, const Color(0xFFF6D9C8));
    pen.hatch(inner, const Color(0xFFD9A58C), spacing: 0.9, angle: 0.6, width: 0.4, seed: seed);
    pen.stroke(outer, coat.line, width: _line, seed: seed);
  }

  /// The collar band, peeking out under the chin.
  void _collar(SketchPen pen, Offset hc) {
    pen.tube(
      Path()
        ..moveTo(hc.dx - 13, hc.dy + 12)
        ..quadraticBezierTo(hc.dx, hc.dy + 27, hc.dx + 13, hc.dy + 12),
      width: 3.2,
      outline: coat.line,
      fill: coat.collar,
      lineWidth: 0.7,
      wobble: 0.1,
      seed: 51,
    );
  }

  /// The round name tag hanging from the collar.
  void _tag(SketchPen pen, Offset hc) {
    final tag = ovalPath(hc + const Offset(0.6, 22.2), 4.6, 4.6);
    pen.fill(tag, coat.tag);
    pen.stroke(tag, coat.line, width: 0.6, wobble: 0.05, sketchy: false);
    pen.fill(ovalPath(hc + const Offset(-0.2, 21.4), 1.3, 1.3), SketchColors.white.withValues(alpha: 0.8));
  }

  void _eye(SketchPen pen, Offset c) {
    final line = coat.faceLine;
    if (frame.happyEyes) {
      pen.stroke(
        Path()
          ..moveTo(c.dx - 4, c.dy + 1.5)
          ..quadraticBezierTo(c.dx, c.dy - 4, c.dx + 4, c.dy + 1.5),
        line,
        width: 1.4,
        wobble: 0.15,
        sketchy: false,
      );
      return;
    }
    final open = frame.eyeOpen;
    if (open < 0.25) {
      pen.stroke(
        Path()
          ..moveTo(c.dx - 4, c.dy + 0.5)
          ..quadraticBezierTo(c.dx, c.dy + 3, c.dx + 4, c.dy + 0.5),
        line,
        width: 1.3,
        wobble: 0.1,
        sketchy: false,
      );
      return;
    }
    final eye = ovalPath(c, 9 * frame.eyeScale, 10 * open * frame.eyeScale);
    final canvas = pen.canvas;
    pen.fill(eye, SketchColors.eye);
    canvas.save();
    canvas.clipPath(eye);
    final look = Offset(frame.gaze * 1.3, frame.gazeY * 1.5);
    // Warm iris glowing up from the bottom of the eye.
    pen.fill(ovalPath(c + look + Offset(0, 2.6 * open), 7.6, 6.4 * open), eyes.iris.withValues(alpha: 0.9));
    pen.fill(ovalPath(c + look + Offset(0, 3.4 * open), 5, 3.2 * open), eyes.glow.withValues(alpha: 0.85));
    pen.fill(ovalPath(c + look + const Offset(0, 0.3), 4.6, 5 * open), SketchColors.eye);
    pen.fill(ovalPath(c + look + const Offset(-1.6, -2), 3.6, 3.6 * open), SketchColors.white);
    pen.fill(ovalPath(c + look + const Offset(1.8, 2.1), 1.5, 1.5 * open), SketchColors.white);
    canvas.restore();
    pen.stroke(eye, line, width: 0.8, wobble: 0.15, sketchy: false);
  }

  void _mouth(SketchPen pen, Offset hc) {
    final line = coat.mouthLine;

    if (frame.mouth == DogMouth.open || frame.mouth == DogMouth.chew) {
      final depth = frame.mouth == DogMouth.chew ? 14.5 : 18.0;
      final open = Path()
        ..moveTo(hc.dx - 3.8, hc.dy + 11)
        ..quadraticBezierTo(hc.dx, hc.dy + 10.2, hc.dx + 3.8, hc.dy + 11)
        ..cubicTo(hc.dx + 3.6, hc.dy + depth - 1, hc.dx - 3.6, hc.dy + depth - 1, hc.dx - 3.8, hc.dy + 11)
        ..close();
      pen.fill(open, SketchColors.mouth);
      pen.canvas.save();
      pen.canvas.clipPath(open);
      pen.fill(ovalPath(hc + Offset(0, depth - 2.6), 5.4, 3.8), SketchColors.pink);
      pen.canvas.restore();
      pen.stroke(open, line, width: 0.7, wobble: 0.1, sketchy: false);
    } else if (frame.mouth == DogMouth.tongue) {
      // A happy tongue lolling out.
      final tongue = Path()
        ..moveTo(hc.dx - 2.4, hc.dy + 10.8)
        ..lineTo(hc.dx - 2.6, hc.dy + 14.5)
        ..quadraticBezierTo(hc.dx + 0.3, hc.dy + 18.5, hc.dx + 3, hc.dy + 14.5)
        ..lineTo(hc.dx + 2.8, hc.dy + 10.8)
        ..close();
      pen.fill(tongue, SketchColors.pink);
      pen.stroke(tongue, line, width: 0.6, wobble: 0.1, sketchy: false);
      pen.line(
        hc + const Offset(0.2, 12),
        hc + const Offset(0.3, 15),
        SketchColors.pinkDeep,
        width: 0.5,
        sketchy: false,
        wobble: 0,
      );
    }

    // Nose to mouth, and the little "w" of the smile.
    pen.line(hc + const Offset(0, 8.6), hc + const Offset(0, 10.6), line, width: 0.8, sketchy: false, wobble: 0);
    pen.stroke(
      Path()
        ..moveTo(hc.dx - 4.6, hc.dy + 10)
        ..quadraticBezierTo(hc.dx - 2.3, hc.dy + 12.6, hc.dx, hc.dy + 10.4)
        ..quadraticBezierTo(hc.dx + 2.3, hc.dy + 12.6, hc.dx + 4.6, hc.dy + 10),
      line,
      width: 0.8,
      wobble: 0.1,
      sketchy: false,
    );

    // The big round button nose, with a shine.
    final nose = Path()
      ..moveTo(hc.dx - 3.8, hc.dy + 5.4)
      ..quadraticBezierTo(hc.dx, hc.dy + 4.2, hc.dx + 3.8, hc.dy + 5.4)
      ..quadraticBezierTo(hc.dx + 3.6, hc.dy + 8.4, hc.dx, hc.dy + 9)
      ..quadraticBezierTo(hc.dx - 3.6, hc.dy + 8.4, hc.dx - 3.8, hc.dy + 5.4)
      ..close();
    pen.fill(nose, coat.nose);
    pen.fill(ovalPath(hc + const Offset(-1.3, 5.6), 2, 1.1), SketchColors.white.withValues(alpha: 0.75));
  }

  /// Little freckle dots on the snout.
  void _muzzleDots(SketchPen pen, Offset hc) {
    final dot = coat.line.withValues(alpha: 0.55);
    for (final side in const [-1.0, 1.0]) {
      for (final o in const [Offset(6.4, 7.4), Offset(8.2, 8.8), Offset(6.6, 9.9)]) {
        pen.fill(ovalPath(hc + Offset(o.dx * side, o.dy), 0.9, 0.9), dot);
      }
    }
  }

  void _extras(SketchPen pen, Offset hc) {
    if (frame.motionMarks) {
      for (final o in const [Offset(17, 72), Offset(23, 79), Offset(86, 76)]) {
        pen.stroke(
          Path()
            ..moveTo(o.dx, o.dy)
            ..quadraticBezierTo(o.dx - 2, o.dy + 3, o.dx, o.dy + 6),
          SketchColors.graphite,
          width: 0.8,
          sketchy: false,
          wobble: 0,
        );
      }
    }
    if (frame.eatMarks > 0) {
      final color = SketchColors.ink.withValues(alpha: frame.eatMarks);
      pen.line(hc + const Offset(27, -4), hc + const Offset(31, -7), color, width: 0.9, sketchy: false);
      pen.line(hc + const Offset(28.5, 1), hc + const Offset(33, 0.5), color, width: 0.9, sketchy: false);
      pen.line(hc + const Offset(-27, -4), hc + const Offset(-31, -7), color, width: 0.9, sketchy: false);
    }
    if (frame.mark == DogMark.exclaim) {
      final top = hc + const Offset(0, -34);
      pen.line(top, top + const Offset(0.6, 7), SketchColors.ink, width: 1.8, sketchy: false, wobble: 0.1);
      pen.fill(ovalPath(top + const Offset(0.8, 10), 2, 2), SketchColors.ink);
      pen.line(top + const Offset(-5, 2), top + const Offset(-7.5, 0), SketchColors.ink, width: 0.9, sketchy: false);
      pen.line(top + const Offset(5, 2), top + const Offset(7.5, 0), SketchColors.ink, width: 0.9, sketchy: false);
    }
    if (frame.mark == DogMark.woof) {
      // Three little "woof" sound ticks fanning out from the mouth.
      final o = hc + const Offset(24, 10);
      for (final (i, a) in const [-0.5, 0.0, 0.5].indexed) {
        final r = 4.0 + i * 0.6;
        pen.stroke(
          Path()
            ..moveTo(o.dx + math.cos(a - 0.3) * r, o.dy + math.sin(a - 0.3) * r)
            ..quadraticBezierTo(
              o.dx + math.cos(a) * (r + 1.4),
              o.dy + math.sin(a) * (r + 1.4),
              o.dx + math.cos(a + 0.3) * r,
              o.dy + math.sin(a + 0.3) * r,
            ),
          SketchColors.ink,
          width: 1.1,
          sketchy: false,
          wobble: 0,
        );
        pen.line(
          o + Offset(math.cos(a), math.sin(a)) * (r + 2.5),
          o + Offset(math.cos(a), math.sin(a)) * (r + 5.5),
          SketchColors.ink,
          width: 1.1,
          sketchy: false,
          wobble: 0,
        );
      }
    }
    if (frame.mark == DogMark.question) {
      final top = hc + const Offset(1, -38);
      pen.stroke(
        Path()
          ..moveTo(top.dx - 3.5, top.dy)
          ..quadraticBezierTo(top.dx - 3, top.dy - 5, top.dx + 0.5, top.dy - 5)
          ..quadraticBezierTo(top.dx + 4.5, top.dy - 4.5, top.dx + 3.5, top.dy - 1)
          ..quadraticBezierTo(top.dx + 2.5, top.dy + 1.5, top.dx, top.dy + 2.5)
          ..lineTo(top.dx, top.dy + 4.5),
        SketchColors.ink,
        width: 1.6,
        sketchy: false,
        wobble: 0.1,
      );
      pen.fill(ovalPath(top + const Offset(0, 8), 2, 2), SketchColors.ink);
    }
    if (frame.sparkle > 0) {
      final pulse = (math.sin(frame.sparkle * 9) + 1) / 2;
      pen.star(const Offset(90, 13), 2 + pulse * 2, SketchColors.sunEdge, width: 1.1);
      pen.star(const Offset(16, 17), 3 - pulse * 1.5, SketchColors.ink, width: 1.0);
      pen.star(const Offset(96, 30), 1.5 + pulse, SketchColors.pinkDeep, width: 0.9);
    }
  }
}

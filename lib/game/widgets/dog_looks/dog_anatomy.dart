import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../animations/dog_animations.dart';
import '../../sketch/sketch.dart';

part 'dog_face.dart';

/// Fur and line colours of one look.
class DogCoat {
  const DogCoat({
    this.fur = SketchColors.white,
    this.farFur = const Color(0xFFEDEDF0),
    this.line = const Color(0xFF3A3A42),
    Color? faceLine,
    Color? mouthLine,
    this.shade = SketchColors.graphite,
    this.bodyShade = 0.35,
    this.headShade = 0.28,
    this.blush = 0.35,
    Color? tuft,
    Color? muzzle,
    Color? ear,
    this.nose = const Color(0xFF26262B),
    this.collar = SketchColors.cherry,
    this.tag = SketchColors.sun,
  }) : faceLine = faceLine ?? line,
       mouthLine = mouthLine ?? line,
       tuft = tuft ?? fur,
       muzzle = muzzle ?? fur,
       ear = ear ?? fur;

  /// Near-side fur, and the slightly shaded far-side legs.
  final Color fur;
  final Color farFur;

  /// Outlines of body, head, legs, ears and tufts.
  final Color line;

  /// Eye outlines and closed or happy eye arcs.
  final Color faceLine;
  final Color mouthLine;

  /// Form hatching across the back and crown (lighter than the fur on dark
  /// dogs, so light still comes from the top left).
  final Color shade;
  final double bodyShade;
  final double headShade;

  /// Strength of the pink cheek blush.
  final double blush;

  /// Fill of the chest and belly fur tufts.
  final Color tuft;

  /// The snout patch around the nose and mouth.
  final Color muzzle;

  /// Fill of the ears (floppy ears are often darker than the head).
  final Color ear;
  final Color nose;

  /// Collar band and the little round name tag hanging from it.
  final Color collar;
  final Color tag;
}

/// Iris colours (the glow is the lighter crescent low in the iris).
class DogEyes {
  const DogEyes({required this.iris, required this.glow});

  static const brown = DogEyes(iris: Color(0xFF7A4A26), glow: Color(0xFFC08A52));

  final Color iris;
  final Color glow;
}

/// Body proportions. Every build keeps the same paw anchors; a [long] dog
/// (corgi, dachshund) has a longer, lower body on short legs.
enum DogBuild { puppy, chubby, long }

/// Long ears hanging beside the face, upright ones (corgi, husky), or one
/// of each (a floppy far ear and a cocked near ear).
enum EarStyle { floppy, pointed, mixed }

/// A long wagging tail, a curled fluffy plume, or a short stub.
enum TailStyle { wag, plume, stub }

/// The shared dog skeleton: every look draws the same body, legs, tail,
/// head and face from one [DogFrame] in the 100x85 box (facing right,
/// anchored bottom-centre at the paws), and only changes colours,
/// proportions and markings through the hooks below.
abstract class DogAnatomy extends CustomPainter {
  DogAnatomy({required this.frame, required this.facing});

  final DogFrame frame;
  final double facing;

  // Hips and resting feet: far back, near back, far front, near front.
  static const _hips = [Offset(34, 65), Offset(40, 67), Offset(57, 65), Offset(63, 67)];
  static const _feet = [Offset(32, 81), Offset(40, 83.5), Offset(58, 81), nearFrontPawRest];
  static const _lineWidth = 0.75;

  // ---------------------------------------------------------------------------
  // Hooks
  // ---------------------------------------------------------------------------

  DogCoat get coat;
  DogEyes get eyes => DogEyes.brown;
  DogBuild get build => DogBuild.puppy;
  EarStyle get earStyle => EarStyle.floppy;
  TailStyle get tailStyle => TailStyle.wag;

  /// A fluffy head outline (cheek fluff and a crown wisp) and chest tufts.
  bool get fluffy => false;

  /// Wiry, scruffy fur: a ragged outline, eyebrows and a beard (terriers).
  bool get wiry => false;

  /// Long silky fringes on the ears (retrievers).
  bool get featheredEars => false;

  /// Size of the ears (1 = puppy size).
  double get earScale => 1;

  /// Outline weight multiplier (the spotty pup has a bolder pen).
  double get lineScale => 1;

  /// Fill of leg [i] (0 far back, 1 near back, 2 far front, 3 near front).
  Color legFur(int i, {required bool far}) => far ? coat.farFur : coat.fur;

  /// Fill of paw [i]; white socks and cream toes go here.
  Color pawFur(int i, {required bool far}) => legFur(i, far: far);

  /// Markings inside the body, clipped to it.
  void paintBodyMarks(SketchPen pen, Rect body) {}

  /// Markings inside the head, clipped to it (masks, blazes, patches).
  void paintHeadInside(SketchPen pen, Offset hc) {}

  /// Markings over the head, unclipped, under the outline.
  void paintHeadMarks(SketchPen pen, Offset hc) {}

  /// Markings inside the ear, clipped to it.
  void paintEarMarks(SketchPen pen, Path ear, int side) {}

  void paintTailMarks(SketchPen pen, Path tail) {}

  void paintLegMarks(SketchPen pen, int i, Offset hip, Offset foot, {required bool far}) {}

  /// Bows and the like, over the finished head.
  void paintAccessories(SketchPen pen, Offset hc) {}

  // ---------------------------------------------------------------------------
  // Drawing
  // ---------------------------------------------------------------------------

  bool get _chubby => build == DogBuild.chubby;
  bool get _long => build == DogBuild.long;

  /// How much lower a short-legged dog's body and head sit.
  double get _drop => _long ? 5 : 0;
  double get _line => _lineWidth * lineScale;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final pen = SketchPen(canvas, pxPerUnit: s);
    // Squash through the middle of a turn instead of flipping instantly.
    final flip = facing.abs() < 0.14 ? (facing < 0 ? -0.14 : 0.14) : facing;

    canvas.save();
    canvas.translate(size.width / 2, 0);
    canvas.scale(flip * s, s);
    canvas.translate(-50, 0);

    if (frame.shadow) _shadow(pen);
    canvas.translate(0, frame.bodyLift);
    if (frame.bodyRotation != 0) {
      canvas.translate(48, 62);
      canvas.rotate(frame.bodyRotation);
      canvas.translate(-48, -62);
    }
    _tail(pen);
    _leg(pen, 0, far: true);
    _leg(pen, 2, far: true);
    _body(pen);
    if (frame.hindPaw == null) _leg(pen, 1, far: false);
    if (frame.raisedPaw == null) _leg(pen, 3, far: false);
    final headCenter = _head(pen);
    if (frame.raisedPaw != null) _raisedPaw(pen, frame.raisedPaw!);
    if (frame.hindPaw != null) _hindPaw(pen, frame.hindPaw!);
    _extras(pen, headCenter);

    canvas.restore();
  }

  void _shadow(SketchPen pen) {
    final width = (_chubby || _long ? 60 : 52) + frame.bodyLift * 1.5;
    pen.hatch(
      ovalPath(const Offset(48, 84), width, 6),
      SketchColors.ink.withValues(alpha: 0.75),
      spacing: 0.9,
      angle: -0.2,
      width: 0.5,
      seed: 3,
    );
  }

  /// The tail's centreline from the rump, rotated by the frame's wag.
  Path _tailLine() {
    final base = Offset(_long ? 22 : 30, 58 + _drop);
    final a = frame.tailAngle * 1.3;
    Offset r(double x, double y) => base + Offset(x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a));
    final path = Path()..moveTo(base.dx, base.dy);
    switch (tailStyle) {
      case TailStyle.wag:
        final c1 = r(-7, -1), c2 = r(-13, -9), end = r(-14, -21);
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
      case TailStyle.plume:
        final c1 = r(-9, -3), c2 = r(-16, -16), end = r(-8, -24);
        final curl = r(-2, -27), tip = r(1, -21);
        path
          ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy)
          ..quadraticBezierTo(curl.dx, curl.dy, tip.dx, tip.dy);
      case TailStyle.stub:
        final c = r(-5, -1), end = r(-8, -6);
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
    }
    return path;
  }

  /// An outline around [centre] that narrows from [from] to [to] wide and
  /// ends in a round tip.
  Path _taper(Path centre, double from, double to) {
    final metric = centre.computeMetrics().first;
    const n = 24;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final t = metric.getTangentForOffset(metric.length * i / n)!;
      final w = (from + (to - from) * i / n) / 2;
      final normal = Offset(-t.vector.dy, t.vector.dx) * w;
      left.add(t.position + normal);
      right.add(t.position - normal);
    }
    final end = metric.getTangentForOffset(metric.length)!;
    final tip = end.position + end.vector * (to / 2);
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.quadraticBezierTo(tip.dx, tip.dy, right.last.dx, right.last.dy);
    for (final p in right.reversed.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  void _tail(SketchPen pen) {
    final centre = _tailLine();
    final (from, to) = switch (tailStyle) {
      TailStyle.wag => (_chubby ? 6.6 : 6.0, 2.6),
      TailStyle.plume => (8.4, 5.6),
      TailStyle.stub => (7.0, 5.0),
    };
    final shape = pen.wobbly(_taper(centre, from, to), amplitude: wiry ? 0.7 : 0.2, seed: 41);
    pen.fill(shape, coat.fur);
    pen.canvas.save();
    pen.canvas.clipPath(shape);
    paintTailMarks(pen, centre);
    pen.canvas.restore();
    pen.stroke(shape, coat.line, width: 0.8 * lineScale, wobble: 0.1, seed: 41);
    if (tailStyle == TailStyle.plume) {
      // Feathery fur along the plume.
      final metric = centre.computeMetrics().first;
      for (final f in const [0.35, 0.5, 0.65, 0.8]) {
        final t = metric.getTangentForOffset(metric.length * f)!;
        final out = Offset(-t.vector.dy, t.vector.dx);
        final w = 3.5 - f * 1.2;
        pen.line(
          t.position - out * w,
          t.position - out * (w + 1.8) - t.vector * 1.2,
          coat.line,
          width: 0.6,
          sketchy: false,
          wobble: 0,
        );
      }
    }
    if (frame.tailBlur) {
      // Wagging so fast it blurs: little ticks either side of the tip.
      final metric = centre.computeMetrics().first;
      final tip = metric.getTangentForOffset(metric.length)!;
      final n = Offset(-tip.vector.dy, tip.vector.dx);
      for (final side in const [-1.0, 1.0]) {
        for (final k in const [4.5, 7.0]) {
          final at = tip.position + n * side * k;
          pen.stroke(
            Path()
              ..moveTo((at - tip.vector * 2.5).dx, (at - tip.vector * 2.5).dy)
              ..quadraticBezierTo(
                (at + n * side).dx,
                (at + n * side).dy,
                (at + tip.vector * 2.5).dx,
                (at + tip.vector * 2.5).dy,
              ),
            SketchColors.graphite,
            width: 0.6,
            sketchy: false,
            wobble: 0,
          );
        }
      }
    }
  }

  Offset _hip(int i) => _hips[i] + Offset(_long ? (i < 2 ? -8 : 2) : 0, _drop);

  void _leg(SketchPen pen, int i, {required bool far}) {
    final hip = _hip(i);
    final foot = _feet[i] + frame.feet[i];
    pen.tube(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(foot.dx, foot.dy - 2),
      width: _chubby ? 7.6 : 6.6,
      outline: coat.line,
      fill: legFur(i, far: far),
      lineWidth: 0.8 * lineScale,
      seed: 11 + i,
    );
    _paw(pen, foot, pawFur(i, far: far), 20 + i);
    paintLegMarks(pen, i, hip, foot, far: far);
  }

  void _paw(SketchPen pen, Offset foot, Color fur, int seed) {
    final paw = ovalPath(foot + const Offset(1, -1.8), _chubby ? 9.4 : 8.6, 5.4);
    pen.fill(paw, fur);
    pen.stroke(paw, coat.line, width: 0.8 * lineScale, wobble: 0.2, seed: seed);
    for (final dx in const [0.6, 3.0]) {
      pen.line(
        foot + Offset(dx, -2.2),
        foot + Offset(dx + 0.2, -0.5),
        coat.line,
        width: 0.5,
        sketchy: false,
        wobble: 0,
      );
    }
    // Small dark nails at the front of the paw.
    for (final dy in const [-2.6, -1.0]) {
      pen.line(foot + Offset(5.2, dy), foot + Offset(6.2, dy + 0.3), coat.line, width: 0.55, sketchy: false, wobble: 0);
    }
  }

  /// The body oval; a chubby dog is longer, lower and her belly hangs a
  /// little.
  Rect _bodyRect() {
    final h = 25 * frame.breath;
    if (_chubby) return Rect.fromLTRB(19, 76.5 - h * 1.3, 72, 76.5);
    if (_long) return Rect.fromLTRB(15, 74.5 - h * 0.84, 72, 74.5);
    return Rect.fromLTRB(26, 72 - h, 68, 72);
  }

  void _body(SketchPen pen) {
    final rect = _bodyRect();
    final h = rect.height;
    final body = Path()..addOval(rect);
    pen.fill(body, coat.fur);
    pen.canvas.save();
    pen.canvas.clipPath(body);
    pen.hatch(
      rectPath(20, rect.top, 72, rect.top + h * 0.4),
      coat.shade.withValues(alpha: coat.bodyShade),
      spacing: 1.3,
      angle: -1.0,
      width: 0.4,
      seed: 5,
    );
    paintBodyMarks(pen, rect);
    pen.canvas.restore();
    pen.stroke(body, coat.line, width: _line, seed: 21);
    if (wiry) {
      // Scruffy wire-hair tufts along the back and belly.
      for (final f in const [0.25, 0.45, 0.65]) {
        _tuft(pen, Offset(rect.left + rect.width * f, rect.top + 0.6), 3, 1.6, -math.pi / 2, 63);
      }
      _tuft(pen, Offset(rect.center.dx + 4, rect.bottom - 0.4), 4, 1.7, math.pi / 2, 64);
    }
    if (fluffy) {
      // Fluffy chest and belly tufts over the outline.
      _tuft(pen, Offset(rect.right - 2.5, rect.top + h * 0.55), 4, 1.9, 0.35, 61);
      _tuft(pen, Offset(48, rect.bottom - 0.4), 4, 1.5, math.pi / 2, 62);
    }
  }

  /// A small row of fur spikes poking out from an outline at [at], pointing
  /// in [direction] (radians).
  void _tuft(SketchPen pen, Offset at, int spikes, double length, double direction, int seed) {
    final out = Offset(math.cos(direction), math.sin(direction));
    final along = Offset(-out.dy, out.dx);
    const gap = 1.7;
    final start = at - along * (gap * spikes / 2);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < spikes; i++) {
      final tip = start + along * (gap * (i + 0.5)) + out * length + along * 0.4;
      final next = start + along * (gap * (i + 1));
      path
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(next.dx, next.dy);
    }
    final fill = Path.from(path)..close();
    pen.fill(fill, coat.tuft);
    pen.stroke(path, coat.line, width: 0.75, wobble: 0.05, sketchy: false, seed: seed);
  }

  /// The near hind leg lifted up to scratch behind the ear, kicking fast.
  void _hindPaw(SketchPen pen, Offset paw) {
    final hip = _hip(1);
    final knee = Offset((hip.dx + paw.dx) / 2 - 6, math.max(hip.dy, paw.dy) + 2);
    pen.tube(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..quadraticBezierTo(knee.dx, knee.dy, paw.dx, paw.dy),
      width: _chubby ? 7.6 : 6.6,
      outline: coat.line,
      fill: legFur(1, far: false),
      lineWidth: 0.8 * lineScale,
      seed: 15,
    );
    final pad = ovalPath(paw, 7.4, 5.6);
    pen.fill(pad, pawFur(1, far: false));
    pen.stroke(pad, coat.line, width: 0.8 * lineScale, wobble: 0.2, seed: 16);
    for (final (a, b) in const [(Offset(-5, -4), Offset(-8, -6)), (Offset(-5, 1), Offset(-8.5, 1.5))]) {
      pen.line(paw + a, paw + b, SketchColors.graphite, width: 0.7, sketchy: false, wobble: 0);
    }
  }

  void _raisedPaw(SketchPen pen, Offset paw) {
    final shoulder = Offset(63, 65 + _drop);
    final control = Offset((shoulder.dx + paw.dx) / 2 + 3, math.max(shoulder.dy, paw.dy) + 2);
    pen.tube(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(control.dx, control.dy, paw.dx, paw.dy + 1),
      width: _chubby ? 7.6 : 6.6,
      outline: coat.line,
      fill: legFur(3, far: false),
      lineWidth: lineScale,
      seed: 17,
    );
    final pad = ovalPath(paw, 8.5, 6.5);
    pen.fill(pad, pawFur(3, far: false));
    pen.stroke(pad, coat.line, width: 0.95 * lineScale, wobble: 0.2, seed: 18);
    // A dark paw pad with three toe beans.
    const bean = Color(0xFF5A4A4E);
    pen.fill(ovalPath(paw + const Offset(0.4, 1.2), 3.4, 2.4), bean.withValues(alpha: 0.75));
    for (final dx in const [-2.0, 0.4, 2.8]) {
      pen.fill(ovalPath(paw + Offset(dx, -1.4), 1.4, 1.3), bean.withValues(alpha: 0.75));
    }
  }

  @override
  bool shouldRepaint(DogAnatomy oldDelegate) =>
      oldDelegate.runtimeType != runtimeType || oldDelegate.frame != frame || oldDelegate.facing != facing;
}

/// Round spots scattered over the body, legs, tail and head, in
/// [spotColor]. Same spots every frame.
mixin SpotMarkings on DogAnatomy {
  Color get spotColor;

  void _spot(SketchPen pen, Offset c, double w, double h, int seed) {
    pen.fill(pen.wobbly(ovalPath(c, w, h), amplitude: 0.5, seed: seed), spotColor);
  }

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    for (final (fx, fy, w, h, seed) in const [
      (0.18, 0.3, 5.0, 4.2, 91),
      (0.36, 0.14, 4.0, 3.4, 92),
      (0.55, 0.32, 5.6, 4.6, 93),
      (0.75, 0.16, 3.4, 3.0, 94),
      (0.3, 0.58, 3.2, 2.8, 95),
      (0.68, 0.6, 4.2, 3.4, 96),
      (0.9, 0.42, 3.0, 2.6, 97),
      (0.46, 0.8, 2.6, 2.2, 98),
    ]) {
      _spot(pen, Offset(body.left + body.width * fx, body.top + body.height * fy), w, h, seed);
    }
  }

  @override
  void paintTailMarks(SketchPen pen, Path tail) {
    final metric = tail.computeMetrics().first;
    for (final (f, size) in const [(0.3, 2.6), (0.62, 2.2), (0.9, 1.8)]) {
      _spot(pen, metric.getTangentForOffset(metric.length * f)!.position, size, size, (f * 100).toInt());
    }
  }

  @override
  void paintLegMarks(SketchPen pen, int i, Offset hip, Offset foot, {required bool far}) {
    if (far) return;
    _spot(pen, Offset.lerp(hip, foot, i == 1 ? 0.35 : 0.55)!, 2.6, 2.4, 70 + i);
  }

  @override
  void paintHeadInside(SketchPen pen, Offset hc) {
    for (final (o, w, h, seed) in const [
      (Offset(-13, -9), 3.6, 3.2, 101),
      (Offset(6, -13), 3.0, 2.6, 102),
      (Offset(14, -5), 2.6, 2.4, 103),
      (Offset(-4, -15), 2.2, 2.0, 104),
    ]) {
      _spot(pen, hc + o, w, h, seed);
    }
  }
}

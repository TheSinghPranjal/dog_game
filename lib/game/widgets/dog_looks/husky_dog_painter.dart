import 'dart:ui';

import '../../sketch/sketch.dart';
import 'dog_anatomy.dart';

/// Luna: a black-and-white husky puppy with upright ears, a white mask,
/// pale blue eyes and a thick curled tail. Dark fur takes lighter graphite
/// hatching and a light outline so she reads on the paper.
class HuskyDogPainter extends DogAnatomy {
  HuskyDogPainter({required super.frame, required super.facing});

  static const _white = Color(0xFFFBFBFD);
  static const _whiteShade = Color(0xFFE2E2EA);

  static const _coat = DogCoat(
    fur: Color(0xFF3A3D48),
    farFur: Color(0xFF2E313B),
    line: Color(0xFF7C7C90),
    faceLine: Color(0xFF55586A),
    mouthLine: Color(0xFF3A3A42),
    shade: Color(0xFF9A9AB2),
    bodyShade: 0.5,
    headShade: 0.45,
    blush: 0.25,
    tuft: _white,
    muzzle: _white,
    nose: Color(0xFF111116),
    collar: Color(0xFFE77FB0),
  );

  @override
  DogCoat get coat => _coat;

  @override
  DogEyes get eyes => const DogEyes(iris: Color(0xFF8CC8EE), glow: Color(0xFFD6F0FF));

  @override
  EarStyle get earStyle => EarStyle.pointed;

  @override
  double get earScale => 0.85;

  @override
  TailStyle get tailStyle => TailStyle.plume;

  @override
  Color legFur(int i, {required bool far}) => far ? _whiteShade : _white;

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    // White underside from chest to belly.
    final belly = ovalPath(Offset(body.center.dx + 4, body.bottom), body.width * 0.85, body.height * 0.75);
    pen.fill(belly, _white);
    pen.fill(ovalPath(Offset(body.right - 4, body.center.dy + 3), 13, body.height * 0.9), _white);
    pen.hatch(belly, _whiteShade, spacing: 1.3, angle: -0.6, width: 0.4, seed: 72);
  }

  @override
  void paintHeadInside(SketchPen pen, Offset hc) {
    // The husky mask: white face below the brows, a dark cap and a stripe
    // down the forehead.
    final mask = Path()
      ..moveTo(hc.dx - 21, hc.dy + 2)
      ..quadraticBezierTo(hc.dx - 14, hc.dy - 6, hc.dx - 3, hc.dy - 3)
      ..lineTo(hc.dx, hc.dy - 6)
      ..lineTo(hc.dx + 3, hc.dy - 3)
      ..quadraticBezierTo(hc.dx + 14, hc.dy - 6, hc.dx + 21, hc.dy + 2)
      ..lineTo(hc.dx + 21, hc.dy + 20)
      ..lineTo(hc.dx - 21, hc.dy + 20)
      ..close();
    pen.fill(mask, _white);
    // Pale "eyebrow" spots.
    for (final side in const [-1.0, 1.0]) {
      pen.fill(ovalPath(hc + Offset(7.5 * side, -8), 4, 2.6), _white);
    }
  }

  @override
  void paintTailMarks(SketchPen pen, Path tail) {
    // A white underside and tip to the plume.
    final metric = tail.computeMetrics().first;
    pen.fill(ovalPath(metric.getTangentForOffset(metric.length * 0.95)!.position, 6, 6), _white);
  }
}

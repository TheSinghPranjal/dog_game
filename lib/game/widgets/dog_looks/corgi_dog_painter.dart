import 'dart:ui';

import '../../sketch/sketch.dart';
import 'dog_anatomy.dart';

/// Biscuit: a chubby tan-and-white corgi with a long body, short legs, big
/// fox ears and a little stub of a tail.
class CorgiDogPainter extends DogAnatomy {
  CorgiDogPainter({required super.frame, required super.facing});

  static const _cream = Color(0xFFFFF4E2);
  static const _creamShade = Color(0xFFF2DEC0);

  static const _coat = DogCoat(
    fur: Color(0xFFE9A15A),
    farFur: Color(0xFFDA8F48),
    line: Color(0xFF4A3B33),
    shade: Color(0xFFB8641E),
    bodyShade: 0.4,
    headShade: 0.32,
    tuft: _cream,
    muzzle: _cream,
    collar: Color(0xFF3F9E5A),
  );

  @override
  DogCoat get coat => _coat;

  @override
  DogEyes get eyes => const DogEyes(iris: Color(0xFF8A5528), glow: Color(0xFFD9A066));

  @override
  DogBuild get build => DogBuild.long;

  @override
  EarStyle get earStyle => EarStyle.pointed;

  @override
  double get earScale => 1.05;

  @override
  TailStyle get tailStyle => TailStyle.stub;

  @override
  Color legFur(int i, {required bool far}) => far ? _creamShade : _cream;

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    // White belly and chest.
    final belly = ovalPath(Offset(body.center.dx + 3, body.bottom - 1), body.width * 0.7, body.height * 0.6);
    pen.fill(belly, _cream);
    pen.hatch(belly, _creamShade, spacing: 1.2, angle: -0.6, width: 0.4, seed: 71);
    pen.fill(ovalPath(Offset(body.right - 4, body.center.dy + 2), 12, body.height * 0.85), _cream);
  }

  @override
  void paintHeadInside(SketchPen pen, Offset hc) {
    // A white blaze up between the eyes and a white chin.
    pen.fill(
      Path()
        ..moveTo(hc.dx - 3, hc.dy + 6)
        ..quadraticBezierTo(hc.dx - 1.5, hc.dy - 8, hc.dx, hc.dy - 16)
        ..quadraticBezierTo(hc.dx + 1.5, hc.dy - 8, hc.dx + 3, hc.dy + 6)
        ..close(),
      _cream,
    );
    pen.fill(ovalPath(hc + const Offset(0, 16), 26, 8), _cream);
  }
}

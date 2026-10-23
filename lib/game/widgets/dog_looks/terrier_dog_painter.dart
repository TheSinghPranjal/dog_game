import 'package:flutter/widgets.dart';

import '../../sketch/sketch.dart';
import 'dog_anatomy.dart';

/// Pepper: a scruffy wire-haired terrier, tan with a black saddle, bushy
/// brows, a beard and a short upright tail.
class TerrierDogPainter extends DogAnatomy {
  TerrierDogPainter({required super.frame, required super.facing});

  static const _saddle = Color(0xFF3A3436);

  static const _coat = DogCoat(
    fur: Color(0xFFC9935C),
    farFur: Color(0xFFB98350),
    line: Color(0xFF3B2C24),
    shade: Color(0xFF8A5A30),
    bodyShade: 0.45,
    headShade: 0.3,
    muzzle: Color(0xFFE2C29A),
    ear: Color(0xFF8A5A30),
    collar: Color(0xFFF0A20F),
  );

  @override
  DogCoat get coat => _coat;

  @override
  bool get wiry => true;

  @override
  double get earScale => 0.7;

  @override
  TailStyle get tailStyle => TailStyle.stub;

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    // The black saddle over his back, with a few wiry flecks.
    final saddle = ovalPath(Offset(body.center.dx - 3, body.top + 5), body.width * 0.82, 15);
    pen.fill(pen.wobbly(saddle, amplitude: 1.3, seed: 82), _saddle);
    for (final (x, y) in const [(0.2, 0.55), (0.5, 0.62), (0.75, 0.5)]) {
      pen.line(
        Offset(body.left + body.width * x, body.top + body.height * y),
        Offset(body.left + body.width * x + 1.8, body.top + body.height * y + 1.6),
        _saddle,
        width: 0.7,
        sketchy: false,
      );
    }
  }

  @override
  void paintHeadInside(SketchPen pen, Offset hc) {
    // A dark cap over the crown.
    pen.fill(pen.wobbly(ovalPath(hc + const Offset(0, -15), 30, 10), amplitude: 0.8, seed: 83), _saddle);
  }

  @override
  void paintTailMarks(SketchPen pen, Path tail) {
    pen.tube(tail, width: 9, outline: _saddle, fill: _saddle, lineWidth: 0);
  }
}

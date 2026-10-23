import 'package:flutter/widgets.dart';

import '../../sketch/sketch.dart';
import 'dog_anatomy.dart';

/// Snowball: a fluffy white samoyed, all cloud, with small upright ears, a
/// tail curled over his back, a smiling muzzle and a small black nose.
class SamoyedDogPainter extends DogAnatomy {
  SamoyedDogPainter({required super.frame, required super.facing});

  static const _coat = DogCoat(
    fur: Color(0xFFFFFEFB),
    farFur: Color(0xFFEFEDE8),
    line: Color(0xFF6B6B78),
    shade: Color(0xFFB4B4C0),
    bodyShade: 0.3,
    headShade: 0.22,
    ear: Color(0xFFFFFEFB),
    collar: Color(0xFF6FC3C8),
  );

  @override
  DogCoat get coat => _coat;

  @override
  bool get fluffy => true;

  @override
  EarStyle get earStyle => EarStyle.pointed;

  @override
  double get earScale => 0.55;

  @override
  TailStyle get tailStyle => TailStyle.plume;

  @override
  void paintHeadMarks(SketchPen pen, Offset hc) {
    // The famous samoyed smile: the corners of the mouth curl up.
    for (final side in const [-1.0, 1.0]) {
      pen.stroke(
        Path()
          ..moveTo(hc.dx + 4.6 * side, hc.dy + 10)
          ..quadraticBezierTo(hc.dx + 6.4 * side, hc.dy + 10, hc.dx + 7 * side, hc.dy + 8.2),
        coat.line,
        width: 0.7,
        sketchy: false,
        wobble: 0,
      );
    }
  }
}

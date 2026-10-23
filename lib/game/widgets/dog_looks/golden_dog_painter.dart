import 'package:flutter/widgets.dart';

import '../../sketch/sketch.dart';
import 'dog_anatomy.dart';

/// Maple: a fluffy golden retriever puppy with feathered ears and tail and
/// a cream chest.
class GoldenDogPainter extends DogAnatomy {
  GoldenDogPainter({required super.frame, required super.facing});

  static const _cream = Color(0xFFFFF1D2);

  static const _coat = DogCoat(
    fur: Color(0xFFF2C277),
    farFur: Color(0xFFE5AE5E),
    line: Color(0xFF5A4030),
    shade: Color(0xFFC0843A),
    bodyShade: 0.4,
    headShade: 0.3,
    tuft: _cream,
    muzzle: _cream,
    ear: Color(0xFFE3A355),
    collar: Color(0xFF4F7BE0),
  );

  @override
  DogCoat get coat => _coat;

  @override
  bool get fluffy => true;

  @override
  bool get featheredEars => true;

  @override
  TailStyle get tailStyle => TailStyle.plume;

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    // A soft cream chest.
    final chest = ovalPath(Offset(body.right - 6, body.center.dy + 3), 15, body.height * 0.85);
    pen.fill(pen.wobbly(chest, amplitude: 0.6, seed: 73), _cream);
  }
}

import 'package:flutter/widgets.dart';

import '../../sketch/sketch.dart';
import 'dog_anatomy.dart';

/// Buddy: a classic short-coat chocolate lab puppy with soft floppy ears
/// and a little white spot on his chest.
class LabDogPainter extends DogAnatomy {
  LabDogPainter({required super.frame, required super.facing});

  static const _coat = DogCoat(
    fur: Color(0xFFA9714A),
    farFur: Color(0xFF94603C),
    line: Color(0xFF3E2A1E),
    shade: Color(0xFF6E4429),
    bodyShade: 0.45,
    headShade: 0.35,
    blush: 0.3,
    muzzle: Color(0xFFBC8660),
    ear: Color(0xFF8E5A37),
    nose: Color(0xFF3B2418),
    collar: SketchColors.cherry,
  );

  @override
  DogCoat get coat => _coat;

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    // The white chest spot.
    pen.fill(
      pen.wobbly(ovalPath(Offset(body.right - 6, body.top + body.height * 0.45), 7, 6), amplitude: 0.5, seed: 74),
      const Color(0xFFFFF8EE),
    );
  }
}

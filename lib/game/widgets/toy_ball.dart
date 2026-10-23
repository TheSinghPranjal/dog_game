import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

/// Colored-pencil tennis ball, the puppy's favourite toy.
///
/// The drawing box is 170x110 units; the ball (diameter 100) sits with its
/// center at [ballCenterX], leaving room on the right for its roll.
class ToyBall extends StatelessWidget {
  const ToyBall({super.key, required this.ballDiameter, this.rotation = 0, this.appear = 1, this.pop = 0});

  static const aspect = 170 / 110;

  /// Horizontal position of the ball center as a fraction of the box width.
  static const ballCenterX = 60 / 170;

  final double ballDiameter;
  final double rotation;
  final double appear;
  final double pop;

  static Size boxSize(double ballDiameter) => Size(ballDiameter * 1.7, ballDiameter * 1.1);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: boxSize(ballDiameter),
      painter: ToyBallPainter(rotation: rotation, appear: appear, pop: pop),
    );
  }
}

class ToyBallPainter extends CustomPainter {
  ToyBallPainter({this.rotation = 0, this.appear = 1, this.pop = 0, this.motionMarks = false});

  /// Little "it's rolling" marks, used on the Play button.
  final bool motionMarks;
  final double rotation;
  final double appear;
  final double pop;

  static const _center = Offset(60, 55);
  static const _radius = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 170;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);

    final scale = ObjectAnimations.appearScale(appear) * ObjectAnimations.popScale(pop);
    if (scale > 0.01) {
      canvas.save();
      canvas.translate(_center.dx, 105 + ObjectAnimations.appearLift(appear) * 100);
      canvas.scale(scale);
      canvas.translate(-_center.dx, -105);
      _ball(pen);
      canvas.restore();
    }
    if (motionMarks) {
      for (final (i, y) in const [38.0, 55.0, 72.0].indexed) {
        pen.stroke(
          Path()
            ..moveTo(6, y)
            ..quadraticBezierTo(2, y + 5, 6, y + 10),
          SketchColors.ink,
          width: 2.6,
          sketchy: false,
          seed: i,
        );
      }
    }
    pen.popMarks(_center, 62, pop, _felt, width: 2.6);
    canvas.restore();
  }

  static const _felt = Color(0xFFD4E43A);
  static const _feltDark = Color(0xFF9DB01E);

  void _ball(SketchPen pen) {
    final canvas = pen.canvas;
    pen.hatch(
      ovalPath(const Offset(64, 105), 96, 9),
      SketchColors.inkSoft,
      spacing: 2.2,
      angle: -0.2,
      width: 0.9,
      seed: 1,
    );

    final ball = Path()..addOval(Rect.fromCircle(center: _center, radius: _radius));
    pen.fill(ball, _felt);
    pen.hatch(ball, _feltDark.withValues(alpha: 0.45), spacing: 3.4, angle: -0.7, width: 1.2, seed: 5, cross: true);

    canvas.save();
    canvas.clipPath(ball);
    // Shade on the lower right, away from the light.
    pen.hatch(
      ovalPath(_center + const Offset(18, 20), 80, 70),
      _feltDark.withValues(alpha: 0.6),
      spacing: 2.4,
      angle: -0.7,
      width: 1.2,
      seed: 6,
    );
    canvas.translate(_center.dx, _center.dy);
    canvas.rotate(rotation);
    // The two white seams, curving in from opposite sides; they spin with
    // the ball.
    for (final side in const [-1.0, 1.0]) {
      final seam = Path()
        ..moveTo(side * _radius * 0.3, -_radius * 0.96)
        ..quadraticBezierTo(side * _radius * 1.0, 0, side * _radius * 0.3, _radius * 0.96);
      pen.stroke(seam, SketchColors.white, width: 5, wobble: 0.4, sketchy: false, seed: 7);
      pen.stroke(seam, _feltDark.withValues(alpha: 0.5), width: 1, wobble: 0.4, sketchy: false, seed: 8);
    }
    canvas.restore();

    // A soft shine on the upper left.
    pen.fill(ovalPath(_center + const Offset(-20, -22), 16, 10), SketchColors.white.withValues(alpha: 0.45));
    pen.stroke(ball, const Color(0xFF6E7C12), width: 3, wobble: 0.8, seed: 9);
  }

  @override
  bool shouldRepaint(ToyBallPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.appear != appear ||
      oldDelegate.pop != pop ||
      oldDelegate.motionMarks != motionMarks;
}

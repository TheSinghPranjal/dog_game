import 'package:flutter/widgets.dart';

import '../../models/game_positions.dart';
import '../../sketch/sketch.dart';

const _sage = Color(0xFFCDEBDD);
const _sageDeep = Color(0xFF5FA88F);

/// The two long sage curtains by the window, painted over the whole stage in
/// stage coordinates.
class CurtainsPainter extends CustomPainter {
  CurtainsPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final k = unit / 100;
    final pen = SketchPen(canvas, pxPerUnit: k);
    final w = size.width / k, h = size.height / k;
    canvas.save();
    canvas.scale(k);
    final top = LivingRoomPositions.curtainTop * h;
    final floor = SceneMetrics.groundLine * h + 1;
    _panel(pen, -1, w * 0.085, top, floor, 0, 511);
    _panel(pen, w * LivingRoomPositions.curtainLeft, w * LivingRoomPositions.curtainRight, top, floor, 0, 512);
    canvas.restore();
  }

  void _panel(SketchPen pen, double left, double right, double top, double floor, double bulge, int seed) {
    final panel = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(right, floor * 0.88)
      ..quadraticBezierTo(right + bulge * 2.2, floor - 4, right + bulge * 0.6, floor)
      ..lineTo(left - bulge * 0.3, floor)
      ..quadraticBezierTo(left - bulge, floor - 4, left, floor * 0.88)
      ..close();
    pen.fill(panel, _sage);
    pen.hatch(panel, _sageDeep.withValues(alpha: 0.55), spacing: 1.3, angle: 1.45, width: 0.4, seed: seed);
    for (var x = left + 2.5; x < right - 1; x += 3) {
      pen.line(
        Offset(x, top + 1),
        Offset(x + bulge * 0.3, floor - 1),
        _sageDeep,
        width: 0.45,
        sketchy: false,
        wobble: 0.15,
      );
    }
    pen.stroke(panel, SketchColors.ink, width: 0.8, seed: seed + 10);
  }

  @override
  bool shouldRepaint(CurtainsPainter oldDelegate) => oldDelegate.unit != unit;
}

/// Navigation icon: a little sofa.
class SofaIconPainter extends CustomPainter {
  const SofaIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final back = Path()..addRRect(RRect.fromLTRBR(7, 10, 33, 24, const Radius.circular(4)));
    final seat = Path()..addRRect(RRect.fromLTRBR(5, 22, 35, 31, const Radius.circular(3)));
    pen.fill(back, color.withValues(alpha: 0.85));
    pen.stroke(back, color, width: 1.4, wobble: 0.3, seed: 541);
    pen.fill(seat, color.withValues(alpha: 0.85));
    pen.stroke(seat, color, width: 1.4, wobble: 0.3, seed: 542);
    for (final x in const [3.0, 33.0]) {
      final arm = Path()..addRRect(RRect.fromLTRBR(x, 17, x + 5, 31, const Radius.circular(2.5)));
      pen.fill(arm, SketchColors.white);
      pen.stroke(arm, color, width: 1.3, wobble: 0.3, seed: 543);
    }
    for (final x in const [8.0, 31.0]) {
      pen.line(Offset(x, 31), Offset(x, 35), color, width: 1.8, sketchy: false);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SofaIconPainter oldDelegate) => oldDelegate.color != color;
}

import 'package:flutter/widgets.dart';

import '../animations/dog_animations.dart';
import '../models/dog_look.dart';
import 'dog_looks/corgi_dog_painter.dart';
import 'dog_looks/dachshund_dog_painter.dart';
import 'dog_looks/golden_dog_painter.dart';
import 'dog_looks/husky_dog_painter.dart';
import 'dog_looks/lab_dog_painter.dart';
import 'dog_looks/samoyed_dog_painter.dart';
import 'dog_looks/terrier_dog_painter.dart';

/// The puppy, drawn procedurally so every pose shares the exact same face,
/// proportions, stripes and anchor (bottom-center of the paws).
class DogCharacter extends StatelessWidget {
  const DogCharacter({super.key, required this.frame, required this.facing, required this.width, this.look});

  /// Width / height of the dog's drawing box.
  static const aspect = 100 / 85;

  final DogFrame frame;
  final double facing;
  final double width;

  /// Drawing style; follows the player's choice ([dogLook]) when null.
  final DogLook? look;

  @override
  Widget build(BuildContext context) {
    Widget draw(DogLook look) => CustomPaint(
      size: Size(width, width / aspect),
      painter: DogPainter(frame: frame, facing: facing, look: look),
    );
    final fixed = look;
    if (fixed != null) return draw(fixed);
    return ValueListenableBuilder(valueListenable: dogLook, builder: (_, look, _) => draw(look));
  }
}

/// Paints one [DogFrame] in the given [look]. Every look shares the same
/// 100x85 drawing box and anchors, so poses and animations work for all.
class DogPainter extends CustomPainter {
  DogPainter({required this.frame, required this.facing, this.look = DogLook.golden});

  final DogFrame frame;
  final double facing;
  final DogLook look;

  @override
  void paint(Canvas canvas, Size size) => switch (look) {
    DogLook.golden => GoldenDogPainter(frame: frame, facing: facing),
    DogLook.lab => LabDogPainter(frame: frame, facing: facing),
    DogLook.corgi => CorgiDogPainter(frame: frame, facing: facing),
    DogLook.husky => HuskyDogPainter(frame: frame, facing: facing),
    DogLook.terrier => TerrierDogPainter(frame: frame, facing: facing),
    DogLook.samoyed => SamoyedDogPainter(frame: frame, facing: facing),
    DogLook.dachshund => DachshundDogPainter(frame: frame, facing: facing),
  }.paint(canvas, size);

  @override
  bool shouldRepaint(DogPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.facing != facing || oldDelegate.look != look;
}

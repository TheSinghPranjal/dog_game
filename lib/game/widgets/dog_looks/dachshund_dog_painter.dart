import 'package:flutter/widgets.dart';

import 'dog_anatomy.dart';

/// Ziggy: a dapple dachshund, long and low, with one floppy ear and one
/// cocked ear.
class DachshundDogPainter extends DogAnatomy with SpotMarkings {
  DachshundDogPainter({required super.frame, required super.facing});

  static const _coat = DogCoat(
    fur: Color(0xFFB0683A),
    farFur: Color(0xFF9C5A30),
    line: Color(0xFF3E2618),
    shade: Color(0xFF6E3A1C),
    bodyShade: 0.4,
    headShade: 0.3,
    muzzle: Color(0xFFC8875A),
    ear: Color(0xFF8C4E28),
    collar: Color(0xFF7A5BD0),
  );

  @override
  DogCoat get coat => _coat;

  @override
  DogBuild get build => DogBuild.long;

  @override
  EarStyle get earStyle => EarStyle.mixed;

  @override
  Color get spotColor => const Color(0xFFD9A77C);
}

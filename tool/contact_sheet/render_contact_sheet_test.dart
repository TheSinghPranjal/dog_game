// Renders a contact sheet of every dog look in six key poses, for visual
// review of the dog painters:
//
//   flutter test tool/contact_sheet/render_contact_sheet_test.dart
//
// Writes build/contact_sheet/dogs.png: one row per DogLook (in enum order),
// one column per pose in [poses] order, on notebook paper.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/animations/dog_animations.dart';
import 'package:dog_game/game/models/dog_game_state.dart';
import 'package:dog_game/game/models/dog_look.dart';
import 'package:dog_game/game/sketch/sketch.dart';
import 'package:dog_game/game/widgets/dog_character.dart';

const _outDir = 'build/contact_sheet';

/// Pose and the moment of it to capture.
const poses = <(DogPose, double)>[
  (DogPose.idle, 0.4),
  (DogPose.walk, 0.5),
  (DogPose.sit, 1.0),
  (DogPose.pant, 0.6),
  (DogPose.eat, 0.6),
  (DogPose.playBow, 0.5),
  (DogPose.happy, 0.5),
  (DogPose.surprised, 0.3),
  (DogPose.lieDown, 1.0),
  (DogPose.dig, 0.4),
  (DogPose.beg, 0.5),
  (DogPose.bark, 0.1),
  (DogPose.scratchEar, 1.0),
  (DogPose.pawsUp, 0.5),
];

const _cell = Size(240, 200);
const _dogWidth = 200.0;

DogFrame _frame(DogPose pose, double t) =>
    dogFrameFor(pose: pose, time: 1.3 + t, poseTime: t, walkPhase: t * 11, gaze: 0.3, swipe: 0);

Future<void> _write(String name, Size size, void Function(Canvas canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(size.width.round(), size.height.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  Directory(_outDir).createSync(recursive: true);
  File('$_outDir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('dog contact sheet', () async {
    final size = Size(_cell.width * poses.length, _cell.height * DogLook.values.length);
    await _write('dogs.png', size, (canvas) {
      canvas.drawRect(Offset.zero & size, Paint()..color = SketchColors.paper);
      final grid = Paint()
        ..color = SketchColors.grid
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 20) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (var y = 0.0; y < size.height; y += 20) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
      for (final (row, look) in DogLook.values.indexed) {
        for (final (col, (pose, t)) in poses.indexed) {
          final origin = Offset(col * _cell.width, row * _cell.height);
          final floor = origin.dy + _cell.height - 22;
          canvas.drawLine(
            Offset(origin.dx + 14, floor),
            Offset(origin.dx + _cell.width - 14, floor),
            Paint()
              ..color = SketchColors.inkSoft
              ..strokeWidth = 1.2,
          );
          final dogSize = Size(_dogWidth, _dogWidth / DogCharacter.aspect);
          canvas.save();
          canvas.translate(origin.dx + (_cell.width - dogSize.width) / 2, floor - dogSize.height);
          DogPainter(
            frame: _frame(pose, t).holding(pose == DogPose.walk ? DogCarry.ball : DogCarry.none),
            facing: 1,
            look: look,
          ).paint(canvas, dogSize);
          canvas.restore();
        }
      }
    });
  });
}

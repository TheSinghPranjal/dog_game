// Renders the master app icon, branding/app_icon_source.png, from the game's
// own painters: a rounded notebook page with a sitting puppy (one ear
// flopped, tongue out, tail curled), a tennis ball in front of him, a bone
// at the lower left and a paw print at the lower right.
//
//   flutter test tool/app_icon/render_app_icon_test.dart
//   python3 branding/make_icons.py . /tmp/adaptive_preview.png
//
// The page sits on black so make_icons.py can clear the corners.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_game/game/animations/dog_animations.dart';
import 'package:dog_game/game/models/dog_game_state.dart';
import 'package:dog_game/game/models/dog_look.dart';
import 'package:dog_game/game/sketch/sketch.dart';
import 'package:dog_game/game/widgets/dog_character.dart';
import 'package:dog_game/game/widgets/dog_props.dart';
import 'package:dog_game/game/widgets/toy_ball.dart';

const _size = 1254.0;

void _icon(Canvas canvas) {
  const page = Rect.fromLTRB(22, 22, _size - 22, _size - 22);
  final rrect = RRect.fromRectAndRadius(page, const Radius.circular(200));
  canvas.drawRect(const Rect.fromLTWH(0, 0, _size, _size), Paint()..color = const Color(0xFF000000));
  canvas.save();
  canvas.clipRRect(rrect);
  canvas.drawRect(page, Paint()..color = SketchColors.paper);
  final grid = Paint()
    ..color = SketchColors.grid
    ..strokeWidth = 2;
  for (var v = 0.0; v < _size; v += 38) {
    canvas.drawLine(Offset(v, 0), Offset(v, _size), grid);
    canvas.drawLine(Offset(0, v), Offset(_size, v), grid);
  }
  canvas.restore();

  final pen = SketchPen(canvas, pxPerUnit: 12);
  canvas.save();
  canvas.scale(12);
  // Blue ink outline round the page.
  pen.stroke(
    Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(22 / 12, 22 / 12, (_size - 22) / 12, (_size - 22) / 12),
        const Radius.circular(200 / 12),
      ),
    ),
    SketchColors.ink,
    width: 1.8,
    wobble: 0.08,
    sketchy: false,
    seed: 1,
  );
  // A bone at the lower left, a paw print at the lower right.
  canvas.save();
  canvas.translate(22, 86);
  canvas.rotate(-0.35);
  final bone = bonePath(Offset.zero, 24, 6.5);
  pen.fill(bone, const Color(0xFFFFF4DC));
  pen.hatch(bone, SketchColors.kibble.withValues(alpha: 0.5), spacing: 1.1, angle: 0.4, width: 0.4, seed: 2);
  pen.stroke(bone, SketchColors.ink, width: 1.0, wobble: 0.05, sketchy: false, seed: 3);
  canvas.restore();
  canvas.save();
  canvas.translate(83, 86);
  canvas.rotate(0.3);
  drawPawPrint(pen, Offset.zero, 13, SketchColors.ink);
  canvas.restore();
  // A few sparkles.
  pen.star(const Offset(18, 22), 2.6, SketchColors.sunEdge, width: 0.8);
  pen.star(const Offset(86, 26), 2.0, SketchColors.pinkDeep, width: 0.8);
  canvas.restore();

  // The sitting puppy, one ear flopped out, tongue out, tail curled.
  final frame = dogFrameFor(
    pose: DogPose.sit,
    time: 1.2,
    poseTime: 1,
    walkPhase: 0,
    gaze: 0,
    swipe: 0,
  ).copyWith(mouth: DogMouth.tongue, earTwitch: 0.55);
  const dogSize = Size(1060, 1060 / DogCharacter.aspect);
  canvas.save();
  canvas.translate((_size - dogSize.width) / 2 - 30, 150);
  DogPainter(frame: frame, facing: 1, look: DogLook.golden).paint(canvas, dogSize);
  canvas.restore();

  // The yellow tennis ball in front of him.
  const ball = Size(400, 400 / ToyBall.aspect);
  canvas.save();
  canvas.translate(_size / 2 - ball.width * ToyBall.ballCenterX + 170, 905);
  ToyBallPainter(rotation: 0.5).paint(canvas, ball);
  canvas.restore();
}

void main() {
  test('render the app icon', () async {
    final recorder = ui.PictureRecorder();
    _icon(Canvas(recorder));
    final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('branding/app_icon_source.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

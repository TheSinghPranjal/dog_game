import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../screens/fade_route.dart';
import '../models/dog_game_state.dart';
import '../save/game_store.dart';
import '../sketch/sketch.dart';
import '../widgets/game_action_button.dart';
import '../widgets/idle_puppy.dart';
import '../widgets/scene_background.dart';
import 'hide_seek_play_screen.dart';
import 'hide_seek_stages.dart';
import 'hiding_items.dart';

/// Hide & Seek: pick one of twenty stages. Each stage unlocks once the one
/// before it is cleared.
class HideSeekScreen extends StatelessWidget {
  const HideSeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SketchColors.paper,
      body: LayoutBuilder(
        builder: (context, screen) {
          final gridUnit = math.min(screen.maxWidth, screen.maxHeight * 9 / 16);
          return Stack(
            children: [
              Positioned.fill(child: GraphPaper(spacing: gridUnit / 22)),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, area) {
                    final width = math.min(area.maxWidth, area.maxHeight * 0.75);
                    final unit = math.min(width, area.maxHeight * 9 / 16);
                    final corner = unit * 0.11;
                    final inset = unit * 0.03;
                    return Center(
                      child: SizedBox(
                        width: width,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(inset),
                              child: SizedBox(
                                height: corner,
                                child: Row(
                                  children: [
                                    SizedBox.square(
                                      dimension: corner,
                                      child: SketchIconButton(
                                        glyph: SketchGlyph.back,
                                        semanticLabel: 'Back to your dog',
                                        onPressed: () => Navigator.of(context).maybePop(),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Hide & Seek',
                                          style: TextStyle(
                                            color: SketchColors.ink,
                                            fontSize: corner * 0.45,
                                            fontWeight: FontWeight.w800,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: corner),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              'Move things out of the way to find the hiding dogs!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: SketchColors.inkSoft,
                                fontSize: unit * 0.038,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: unit * 0.01),
                            _PeekingDog(unit: unit),
                            Expanded(
                              child: ListenableBuilder(
                                listenable: GameStore.instance,
                                builder: (context, _) =>
                                    _StageGrid(unit: unit, cleared: GameStore.instance.save.hideSeekCleared),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A puppy peeking over a cardboard box, as a header doodle.
class _PeekingDog extends StatelessWidget {
  const _PeekingDog({required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    final box = HidingItem.box;
    final boxWidth = unit * 0.3;
    final boxHeight = boxWidth / box.aspect;
    final dogWidth = unit * 0.22;
    return SizedBox(
      width: boxWidth,
      height: boxHeight + dogWidth * 0.3,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (boxWidth - dogWidth) / 2,
            top: 0,
            child: IdlePuppy(width: dogWidth, pose: DogPose.sit),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: CustomPaint(size: Size(boxWidth, boxHeight), painter: HidingItemPainter(box, seed: 3)),
          ),
        ],
      ),
    );
  }
}

class _StageGrid extends StatelessWidget {
  const _StageGrid({required this.unit, required this.cleared});

  final double unit;
  final int cleared;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(unit * 0.05, unit * 0.03, unit * 0.05, unit * 0.06),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: unit * 0.035,
        crossAxisSpacing: unit * 0.035,
      ),
      itemCount: HideSeekStages.count,
      itemBuilder: (context, i) {
        final number = i + 1;
        final done = number <= cleared;
        final open = number <= cleared + 1;
        return SketchPressable(
          key: ValueKey('stage-$number'),
          enabled: open,
          semanticLabel: open ? 'Stage $number${done ? ', cleared' : ''}' : 'Stage $number, locked',
          onPressed: () => Navigator.of(context).push(fadeRoute(HideSeekPlayScreen(stageNumber: number))),
          child: CustomPaint(
            painter: SketchFramePainter(
              radius: 0.24,
              seed: number,
              emphasis: done,
              fill: done ? SketchColors.coralLight : SketchColors.white,
            ),
            child: LayoutBuilder(
              builder: (context, tile) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      color: SketchColors.ink,
                      fontSize: tile.maxHeight * 0.34,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: tile.maxHeight * 0.06),
                  SizedBox(
                    height: tile.maxHeight * 0.18,
                    width: tile.maxWidth * 0.8,
                    child: CustomPaint(
                      painter: open ? _PawsPainter(HideSeekStages.dogsIn(number), filled: done) : const _LockPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One paw print per hiding dog; filled in once the stage is cleared.
class _PawsPainter extends CustomPainter {
  const _PawsPainter(this.count, {required this.filled});

  final int count;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final gap = r * 2.3;
    final start = size.width / 2 - gap * (count - 1) / 2;
    final paint = Paint()..color = filled ? SketchColors.pinkDeep : SketchColors.inkSoft.withValues(alpha: 0.6);
    for (var i = 0; i < count; i++) {
      final c = Offset(start + gap * i, size.height * 0.6);
      canvas.drawOval(Rect.fromCenter(center: c, width: r * 1.1, height: r * 0.9), paint);
      for (final dx in const [-0.55, 0.0, 0.55]) {
        canvas.drawCircle(c + Offset(dx * r, -r * (dx == 0 ? 0.85 : 0.65)), r * 0.25, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PawsPainter oldDelegate) => oldDelegate.count != count || oldDelegate.filled != filled;
}

class _LockPainter extends CustomPainter {
  const _LockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final pen = SketchPen(canvas, pxPerUnit: h / 10);
    final c = Offset(size.width / 2, h / 2);
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c + Offset(0, h * 0.15), width: h * 0.9, height: h * 0.7),
          Radius.circular(h * 0.12),
        ),
      );
    pen.stroke(
      Path()
        ..addArc(Rect.fromCenter(center: c - Offset(0, h * 0.15), width: h * 0.55, height: h * 0.6), math.pi, math.pi),
      SketchColors.graphite,
      width: h * 0.12,
      sketchy: false,
    );
    pen.fill(body, SketchColors.graphite);
  }

  @override
  bool shouldRepaint(_LockPainter oldDelegate) => false;
}

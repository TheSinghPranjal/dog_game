import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../screens/fade_route.dart';
import '../animations/dog_animations.dart';
import '../dogs/dog_profile.dart';
import '../models/dog_game_state.dart';
import '../models/day_phase.dart';
import '../models/dog_look.dart';
import '../models/game_location.dart';
import '../models/game_positions.dart';
import '../save/game_store.dart';
import '../sketch/sketch.dart';
import '../widgets/dog_character.dart';
import '../widgets/game_action_button.dart';
import '../widgets/idle_puppy.dart';
import '../widgets/scene_background.dart';
import 'hide_seek_stages.dart';
import 'hiding_items.dart';

enum _DogState { hidden, revealed, found }

/// One hide-and-seek stage: tap the heaps of everyday things to clear them
/// away, then tap each dog you uncover.
class HideSeekPlayScreen extends StatefulWidget {
  const HideSeekPlayScreen({super.key, required this.stageNumber});

  final int stageNumber;

  @override
  State<HideSeekPlayScreen> createState() => HideSeekPlayScreenState();
}

class HideSeekPlayScreenState extends State<HideSeekPlayScreen> with SingleTickerProviderStateMixin {
  static const _removeSeconds = 0.5;
  static const _hintsPerStage = 3;

  late final HideSeekStage stage = HideSeekStages.build(widget.stageNumber);
  late final Ticker _ticker;
  double _time = 0;

  /// Painters are kept, so their hit shapes know the size they last drew at.
  late final List<List<HidingItemPainter>> _painters = [
    for (final pile in stage.piles)
      [for (final item in pile.items) HidingItemPainter(item.kind, seed: item.seed, flip: item.flip)],
  ];

  /// Items still lying on each pile (the top ones go first).
  late final List<int> _remaining = [for (final pile in stage.piles) pile.items.length];

  /// When each item was swept away, and to which side.
  final _removed = <(int, int), (double, double)>{};

  late final List<_DogState> _dogs = List.filled(stage.piles.length, _DogState.hidden);
  late final List<double> _dogSince = List.filled(stage.piles.length, 0);
  final _effects = <_Effect>[];
  int _hintsLeft = _hintsPerStage;
  (int, double)? _shake;

  /// Piles given away by a hint: a wagging tail pokes out of the cover.
  final _hinted = <int>{};
  double? _completedAt;

  @visibleForTesting
  int get found => _dogs.where((c) => c == _DogState.found).length;

  bool get _complete => _completedAt != null;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMicroseconds / Duration.microsecondsPerSecond);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Sweeps the top item off pile [i]; the dog underneath peeks out once
  /// the pile is gone.
  @visibleForTesting
  void tapPile(int i) {
    if (_complete || _remaining[i] == 0) return;
    HapticFeedback.lightImpact();
    final item = --_remaining[i];
    final side = stage.piles[i].position.dx < 0.5 ? -1.0 : 1.0;
    final pile = stage.piles[i];
    setState(() {
      _removed[(i, item)] = (_time, side);
      final placed = pile.items[item];
      _effects.add(
        _Effect(
          pile.position,
          placed.offset + Offset(0, -placed.height / 2),
          placed.width * 0.45,
          _time,
          SketchColors.graphite,
        ),
      );
      if (_remaining[i] == 0 && pile.dog != null) {
        _dogs[i] = _DogState.revealed;
        _dogSince[i] = _time;
      }
    });
  }

  @visibleForTesting
  void tapDog(int i) {
    if (_dogs[i] != _DogState.revealed) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _dogs[i] = _DogState.found;
      _dogSince[i] = _time;
      _effects.add(
        _Effect(
          stage.piles[i].position,
          const Offset(0, -HideSeekStages.dogWidth * 0.45),
          HideSeekStages.dogWidth * 0.6,
          _time,
          SketchColors.pinkDeep,
        ),
      );
      if (found == stage.dogCount) {
        _completedAt = _time;
        final number = stage.number;
        GameStore.instance.update((save) => save.hideSeekCleared = math.max(save.hideSeekCleared, number));
      }
    });
  }

  void _hint() {
    if (_hintsLeft == 0 || _complete) return;
    var target = -1;
    for (var i = 0; i < stage.piles.length && target < 0; i++) {
      if (_dogs[i] == _DogState.hidden) target = i;
    }
    for (var i = 0; i < stage.piles.length && target < 0; i++) {
      if (_dogs[i] == _DogState.revealed) target = i;
    }
    if (target < 0) return;
    setState(() {
      _hintsLeft--;
      _shake = (target, _time);
      _hinted.add(target);
      _effects.add(_Effect(stage.piles[target].position, const Offset(0, -0.1), 0.16, _time, SketchColors.sunEdge));
    });
  }

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
                    final stageSize = Size(math.min(area.maxWidth, area.maxHeight * 0.75), area.maxHeight);
                    final layout = GameLayout(stageSize);
                    return Center(
                      child: SizedBox.fromSize(
                        size: stageSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: GameBackground(location: stage.location, unit: layout.unit, phase: stage.phase),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _RugPainter(location: stage.location, unit: layout.unit),
                                ),
                              ),
                            ),
                            ..._playfield(layout),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: switch (stage.phase) {
                                  DayPhase.evening => const ColoredBox(color: Color(0x10FF8E6E)),
                                  DayPhase.night => const ColoredBox(color: Color(0x2E131840)),
                                  _ => const SizedBox.shrink(),
                                },
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _EffectsPainter(effects: _effects, time: _time, layout: layout),
                                ),
                              ),
                            ),
                            ..._labels(layout),
                            ..._hud(layout),
                            if (_completedAt case final at? when _time - at > 1.2)
                              Positioned.fill(child: _completeCard(layout)),
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

  List<Widget> _playfield(GameLayout layout) {
    final unit = layout.unit;
    final children = <Widget>[];
    for (final (i, pile) in stage.piles.indexed) {
      final anchor = layout.toPixels(pile.position);
      final dog = pile.dog;
      if (dog != null) children.add(_dog(i, dog, anchor, unit));
      if (dog != null && _hinted.contains(i) && _dogs[i] == _DogState.hidden) {
        final cover = pile.items.first;
        final side = cover.flip ? -1.0 : 1.0;
        final tail = Size(unit * 0.07, unit * 0.07);
        children.add(
          Positioned(
            left: anchor.dx + side * cover.width * unit * 0.42 - tail.width / 2,
            top: anchor.dy - tail.height,
            width: tail.width,
            height: tail.height,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HintTailPainter(time: _time, look: dog.look, flip: side < 0),
              ),
            ),
          ),
        );
      }
      final shake = _shake;
      final shakeT = shake != null && shake.$1 == i ? _time - shake.$2 : 1.0;
      for (final (j, item) in pile.items.indexed) {
        var opacity = 1.0;
        var offset = Offset.zero;
        var angle = 0.0;
        if (_removed[(i, j)] case (final start, final side)) {
          final t = (_time - start) / _removeSeconds;
          if (t >= 1) continue;
          offset = Offset(side * unit * 0.5 * t, unit * (-0.3 * t + 0.4 * t * t));
          angle = side * 1.3 * t;
          opacity = 1 - t * t;
        } else if (shakeT < 0.9) {
          angle = math.sin(shakeT * 40) * 0.07 * (1 - shakeT / 0.9);
        }
        final size = Size(item.width * unit, item.height * unit);
        final bottom = anchor + item.offset * unit;
        children.add(
          Positioned(
            left: bottom.dx - size.width / 2,
            top: bottom.dy - size.height,
            width: size.width,
            height: size.height,
            child: IgnorePointer(
              ignoring: _removed.containsKey((i, j)),
              child: Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: opacity,
                    child: Semantics(
                      button: true,
                      label: 'Move the ${item.kind.name}',
                      child: GestureDetector(
                        key: ValueKey('pile-$i-item-$j'),
                        behavior: HitTestBehavior.deferToChild,
                        onTap: () => tapPile(i),
                        child: RepaintBoundary(
                          child: CustomPaint(size: size, painter: _painters[i][j]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return children;
  }

  Widget _dog(int i, DogProfile dog, Offset anchor, double unit) {
    final width = HideSeekStages.dogWidth * unit;
    final height = width / DogCharacter.aspect;
    final state = _dogs[i];
    final since = _time - _dogSince[i];
    final facing = stage.piles[i].items.first.seed.isEven ? 1.0 : -1.0;
    final frame = switch (state) {
      _DogState.hidden => dogFrameFor(
        pose: DogPose.sit,
        time: _time + i,
        poseTime: _time,
        walkPhase: 0,
        gaze: 0,
        swipe: 0,
      ),
      _DogState.revealed => dogFrameFor(
        pose: DogPose.surprised,
        time: _time + i,
        poseTime: since,
        walkPhase: 0,
        gaze: 0,
        swipe: 0,
        mark: DogMark.exclaim,
      ),
      _DogState.found => dogFrameFor(
        pose: since < 1.6 ? DogPose.happy : DogPose.idle,
        time: _time + i,
        poseTime: since,
        walkPhase: 0,
        gaze: 0,
        swipe: 0,
      ),
    };
    return Positioned(
      left: anchor.dx - width / 2,
      top: anchor.dy - height - unit * 0.012,
      width: width,
      height: height,
      child: IgnorePointer(
        ignoring: state != _DogState.revealed,
        child: Semantics(
          button: state == _DogState.revealed,
          label: state == _DogState.hidden ? null : dog.name,
          child: GestureDetector(
            key: ValueKey('dog-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => tapDog(i),
            child: DogCharacter(frame: frame, facing: facing, width: width, look: dog.look),
          ),
        ),
      ),
    );
  }

  /// "Maple!" floating up over each dog as she is found.
  List<Widget> _labels(GameLayout layout) => [
    for (final (i, pile) in stage.piles.indexed)
      if (pile.dog case final dog? when _dogs[i] == _DogState.found && _time - _dogSince[i] < 1.8)
        Builder(
          builder: (context) {
            final t = (_time - _dogSince[i]) / 1.8;
            final anchor = layout.toPixels(pile.position);
            final rise = layout.unit * (HideSeekStages.dogWidth * 0.9 + 0.06 * t);
            return Positioned(
              left: anchor.dx - layout.unit * 0.2,
              width: layout.unit * 0.4,
              top: anchor.dy - rise - layout.unit * 0.06,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Text(
                    '${dog.name}!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SketchColors.pinkDeep,
                      fontSize: layout.unit * 0.055,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      shadows: const [Shadow(color: SketchColors.white, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
  ];

  List<Widget> _hud(GameLayout layout) {
    final corner = layout.unit * GameSizes.cornerButton;
    final inset = layout.unit * 0.03;
    final night = stage.phase == DayPhase.night;
    final dogs = [
      for (final (i, pile) in stage.piles.indexed)
        if (pile.dog case final dog?) (dog, _dogs[i] == _DogState.found),
    ];
    final trayHeight = layout.unit * 0.12;
    final slot = trayHeight * 0.95;
    return [
      Positioned(
        left: inset,
        top: inset,
        width: corner,
        height: corner,
        child: SketchIconButton(
          glyph: SketchGlyph.back,
          semanticLabel: 'Back to stages',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      Positioned(
        left: inset + corner,
        right: inset + corner,
        top: inset,
        height: corner,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Stage ${stage.number} · ${Locations.of(stage.location).title}',
              style: TextStyle(
                color: night ? const Color(0xFFFFF0B3) : SketchColors.ink,
                shadows: night ? const [Shadow(color: Color(0xCC131840), blurRadius: 4)] : null,
                fontSize: corner * 0.36,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        right: inset,
        top: inset,
        width: corner,
        height: corner,
        child: Opacity(
          opacity: _hintsLeft == 0 ? 0.45 : 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: SketchIconButton(
                  glyph: SketchGlyph.hint,
                  semanticLabel: 'Hint, $_hintsLeft left',
                  onPressed: _hint,
                ),
              ),
              Positioned(
                right: -corner * 0.12,
                bottom: -corner * 0.12,
                width: corner * 0.42,
                height: corner * 0.42,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: SketchColors.coral,
                      shape: BoxShape.circle,
                      border: Border.all(color: SketchColors.ink, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$_hintsLeft',
                        style: TextStyle(
                          color: SketchColors.white,
                          fontSize: corner * 0.24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // The tray of dogs to find; each lights up when found.
      Positioned(
        left: 0,
        right: 0,
        bottom: inset,
        height: trayHeight,
        child: Center(
          child: CustomPaint(
            painter: const SketchFramePainter(radius: 0.32, seed: 12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: slot * 0.3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$found/${dogs.length}',
                    style: TextStyle(color: SketchColors.ink, fontSize: slot * 0.3, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: slot * 0.15),
                  for (final (dog, done) in dogs)
                    SizedBox(
                      key: ValueKey('tray-${dog.id.name}'),
                      width: slot,
                      child: Opacity(
                        opacity: done ? 1 : 0.3,
                        child: ColorFiltered(
                          colorFilter: done
                              ? const ColorFilter.mode(Color(0x00000000), BlendMode.dst)
                              : const ColorFilter.matrix([
                                  0.33, 0.33, 0.33, 0, 0, //
                                  0.33, 0.33, 0.33, 0, 0,
                                  0.33, 0.33, 0.33, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]),
                          child: DogCharacter(frame: _trayFrame, facing: 1, width: slot * 0.9, look: dog.look),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  static final _trayFrame = dogFrameFor(pose: DogPose.sit, time: 1, poseTime: 1, walkPhase: 0, gaze: 0, swipe: 0);

  Widget _completeCard(GameLayout layout) {
    final unit = layout.unit;
    final last = stage.number == HideSeekStages.count;
    final dogs = stage.dogs.toList();
    return ColoredBox(
      color: SketchColors.paper.withValues(alpha: 0.55),
      child: Center(
        child: SizedBox(
          width: unit * 0.84,
          child: CustomPaint(
            painter: const SketchFramePainter(radius: 0.12, seed: 21, emphasis: true),
            child: Padding(
              padding: EdgeInsets.all(unit * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    last ? 'You found every dog!' : 'Stage ${stage.number} done!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SketchColors.ink,
                      fontSize: unit * 0.07,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: unit * 0.015),
                  Text(
                    dogs.length == 1 ? '${dogs.first.name} was hiding!' : 'All ${dogs.length} dogs found.',
                    style: TextStyle(color: SketchColors.inkSoft, fontSize: unit * 0.045, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: unit * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final (i, dog) in dogs.indexed)
                        IdlePuppy(
                          width: unit * math.min(0.2, 0.7 / dogs.length),
                          pose: DogPose.happy,
                          loopSeconds: 1.4 + i * 0.13,
                          facing: i.isEven ? 1 : -1,
                          look: dog.look,
                        ),
                    ],
                  ),
                  SizedBox(height: unit * 0.04),
                  Row(
                    children: [
                      Expanded(
                        child: _PaperButton(
                          label: 'Stages',
                          height: unit * 0.13,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      if (!last) ...[
                        SizedBox(width: unit * 0.04),
                        Expanded(
                          child: _PaperButton(
                            label: 'Next stage',
                            height: unit * 0.13,
                            accent: SketchColors.coralLight,
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacement(fadeRoute(HideSeekPlayScreen(stageNumber: stage.number + 1))),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A big rug (or picnic blanket outdoors) under the front rows of piles.
class _RugPainter extends CustomPainter {
  _RugPainter({required this.location, required this.unit});

  final GameLocation location;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = SketchPen(canvas, pxPerUnit: unit / 100, weight: 0.6);
    final outdoors = location == GameLocation.outdoors || location == GameLocation.park;
    final (fill, hatch, edge) = switch (location) {
      GameLocation.outdoors || GameLocation.park => (const Color(0xFFFCE6EC), SketchColors.coral, SketchColors.cherry),
      GameLocation.bath => (SketchColors.inkWash, SketchColors.inkSoft, SketchColors.ink),
      _ => (SketchColors.coralLight, SketchColors.inkSoft, SketchColors.coral),
    };
    final rect = Rect.fromLTRB(size.width * 0.02, size.height * 0.755, size.width * 0.98, size.height * 0.915);
    final rug = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height * (outdoors ? 0.08 : 0.5))));
    pen.fill(rug, fill);
    if (outdoors) {
      // Gingham checks.
      canvas.save();
      canvas.clipPath(rug);
      final step = unit * 0.06;
      for (var x = rect.left; x < rect.right; x += step * 2) {
        pen.fill(rectPath(x, rect.top, x + step, rect.bottom), hatch.withValues(alpha: 0.35));
      }
      for (var y = rect.top; y < rect.bottom; y += step * 2) {
        pen.fill(rectPath(rect.left, y, rect.right, y + step), hatch.withValues(alpha: 0.35));
      }
      canvas.restore();
    } else {
      pen.hatch(rug, hatch.withValues(alpha: 0.5), spacing: unit * 0.018, cross: true, seed: 5);
      final inner = Path()
        ..addRRect(RRect.fromRectAndRadius(rect.deflate(unit * 0.03), Radius.circular(rect.height * 0.4)));
      pen.stroke(inner, edge.withValues(alpha: 0.6), width: unit * 0.006, sketchy: false, seed: 6);
    }
    pen.stroke(rug, edge, width: unit * 0.009, wobble: unit * 0.002, seed: 7);
  }

  @override
  bool shouldRepaint(_RugPainter oldDelegate) => oldDelegate.location != location || oldDelegate.unit != unit;
}

/// A pen burst at [offset] (layout units) from a pile's anchor.
class _Effect {
  const _Effect(this.pile, this.offset, this.radius, this.start, this.color);

  final Offset pile;
  final Offset offset;
  final double radius;
  final double start;
  final Color color;
}

/// Pen bursts when something is swept away, a dog is found, or for a hint.
class _EffectsPainter extends CustomPainter {
  _EffectsPainter({required this.effects, required this.time, required this.layout});

  final List<_Effect> effects;
  final double time;
  final GameLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = SketchPen(canvas, pxPerUnit: layout.unit / 100);
    for (final e in effects) {
      final t = (time - e.start) / 0.6;
      if (t <= 0 || t >= 1) continue;
      final center = layout.toPixels(e.pile) + e.offset * layout.unit;
      pen.popMarks(center, e.radius * layout.unit, t, e.color, width: layout.unit * 0.008);
    }
  }

  @override
  bool shouldRepaint(_EffectsPainter oldDelegate) => true;
}

/// A rounded paper card button with a handwritten label.
class _PaperButton extends StatelessWidget {
  const _PaperButton({required this.label, required this.height, required this.onPressed, this.accent});

  final String label;
  final double height;
  final VoidCallback onPressed;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SketchPressable(
        enabled: true,
        onPressed: onPressed,
        semanticLabel: label,
        child: CustomPaint(
          painter: SketchFramePainter(radius: 0.4, fill: accent ?? SketchColors.white),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: height * 0.25),
                child: Text(
                  label,
                  style: TextStyle(color: SketchColors.ink, fontSize: height * 0.32, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A wagging tail sticking out from under a cover: the hint.
class _HintTailPainter extends CustomPainter {
  _HintTailPainter({required this.time, required this.look, required this.flip});

  final double time;
  final DogLook look;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 20;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.scale(k);
    final wag = math.sin(time * 14) * 3;
    final tail = Path()
      ..moveTo(2, 19)
      ..quadraticBezierTo(10, 18, 13 + wag * 0.4, 8 + wag);
    final fur = switch (look) {
      DogLook.husky => const Color(0xFF3A3D48),
      DogLook.samoyed => SketchColors.white,
      DogLook.lab || DogLook.dachshund => const Color(0xFFA9714A),
      _ => const Color(0xFFE9A15A),
    };
    pen.tube(tail, width: 4, outline: SketchColors.kibbleDark, fill: fur, lineWidth: 0.8, seed: 7);
    for (final (a, b) in [
      (Offset(16, 6 + wag), Offset(19, 5 + wag)),
      (Offset(15.5, 11 + wag), Offset(18.5, 12 + wag)),
    ]) {
      pen.line(a, b, SketchColors.graphite, width: 0.8, sketchy: false, wobble: 0);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HintTailPainter old) => old.time != time || old.look != look || old.flip != flip;
}

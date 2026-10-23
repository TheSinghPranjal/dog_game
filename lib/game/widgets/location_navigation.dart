import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/game_location.dart';
import '../sketch/sketch.dart';
import 'dog_props.dart';
import 'game_action_button.dart';
import 'toy_ball.dart';

/// Persistent bottom bar for switching between the places.
class LocationNavigation extends StatelessWidget {
  const LocationNavigation({super.key, required this.selected, required this.enabled, required this.onSelected});

  final GameLocation selected;
  final bool enabled;
  final ValueChanged<GameLocation> onSelected;

  /// Smallest comfortable touch target for one place.
  static const minItemWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const SketchFramePainter(radius: 0.45, seed: 7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
        child: LayoutBuilder(
          builder: (context, box) {
            const places = GameLocation.values;
            final itemWidth = math.max(minItemWidth, box.maxWidth / places.length);
            final row = Row(
              children: [for (final location in places) SizedBox(width: itemWidth, child: _item(location))],
            );
            // With many places on a narrow phone, the strip scrolls sideways.
            if (itemWidth * places.length <= box.maxWidth + 0.5) return row;
            return _ScrollingStrip(
              initialOffset: math.max(0, (places.indexOf(selected) + 1) * itemWidth - box.maxWidth),
              child: row,
            );
          },
        ),
      ),
    );
  }

  Widget _item(GameLocation location) => SketchPressable(
    enabled: enabled,
    selected: location == selected,
    semanticLabel: 'Go to ${Locations.of(location).title}',
    onPressed: () => onSelected(location),
    child: LayoutBuilder(
      builder: (context, box) => Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _NavIconPainter(location, selected: location == selected),
              child: const SizedBox.expand(),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Locations.of(location).title,
              style: TextStyle(
                color: location == selected ? SketchColors.ink : SketchColors.inkSoft,
                fontSize: box.maxHeight * 0.22,
                fontWeight: location == selected ? FontWeight.w800 : FontWeight.w600,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A sideways-scrolling strip that starts with the selected place in view.
class _ScrollingStrip extends StatefulWidget {
  const _ScrollingStrip({required this.initialOffset, required this.child});

  final double initialOffset;
  final Widget child;

  @override
  State<_ScrollingStrip> createState() => _ScrollingStripState();
}

class _ScrollingStripState extends State<_ScrollingStrip> {
  late final _controller = ScrollController(initialScrollOffset: widget.initialOffset);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(scrollDirection: Axis.horizontal, controller: _controller, child: widget.child);
}

class _NavIconPainter extends CustomPainter {
  _NavIconPainter(this.location, {required this.selected});

  final GameLocation location;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final k = side / 40;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.scale(k);
    if (selected) {
      // Pale-blue disc with a quick hand-drawn circle around it.
      final disc = ovalPath(const Offset(20, 20), 37, 37);
      pen.fill(disc, SketchColors.inkWash.withValues(alpha: 0.55));
      pen.hatch(disc, SketchColors.inkSoft.withValues(alpha: 0.5), spacing: 2.2, seed: 8);
      pen.stroke(
        // Skia wraps sweeps over 360 degrees, so the overlap is a second arc.
        Path()
          ..addArc(Rect.fromCircle(center: const Offset(20, 20), radius: 18.5), -1.9, math.pi * 1.97)
          ..addArc(Rect.fromCircle(center: const Offset(20, 20), radius: 19.6), -2.2, 0.75),
        SketchColors.ink,
        width: 1.7,
        wobble: 0.7,
        seed: 9,
      );
    }
    // Dog things, one per place; full ink when selected, pencil-faded
    // otherwise.
    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, 40, 40),
      Paint()..color = Color.fromRGBO(255, 255, 255, selected ? 1 : 0.55),
    );
    canvas.translate(5, 5);
    const icon = Size(30, 30);
    switch (location) {
      case GameLocation.home:
        const DoghouseIconPainter().paint(canvas, icon);
      case GameLocation.kitchen:
        const BoneIconPainter().paint(canvas, icon);
      case GameLocation.bath:
        const RubberDuckIconPainter().paint(canvas, icon);
      case GameLocation.outdoors:
        const HydrantIconPainter().paint(canvas, icon);
      case GameLocation.bedroom:
        canvas.translate(0, 8);
        DogPillowPainter().paint(canvas, const Size(30, 30 / 50 * 24));
      case GameLocation.livingRoom:
        const SquirrelWindowIconPainter().paint(canvas, icon);
      case GameLocation.park:
        canvas.translate(0, 6);
        ToyBallPainter(rotation: 0.4).paint(canvas, Size(30, 30 / ToyBall.aspect));
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NavIconPainter oldDelegate) =>
      oldDelegate.location != location || oldDelegate.selected != selected;
}

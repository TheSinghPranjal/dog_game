import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models/dog_game_state.dart';
import '../game/sketch/sketch.dart';
import '../game/widgets/idle_puppy.dart';
import '../game/widgets/scene_background.dart';
import '../navigation/app_routes.dart';
import 'notebook_title.dart';

/// Opening page: the puppy hops happily while the title draws in, then the
/// start screen fades in. The Lazy Bear Club credit sits along the bottom.
/// Tap anywhere to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 2400);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: SplashScreen.duration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _continue();
    })
    ..forward();
  bool _left = false;

  void _continue() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(AppRoutes.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SketchColors.paper,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: LayoutBuilder(
          builder: (context, box) {
            final unit = math.min(box.maxWidth, box.maxHeight * 9 / 16);
            // Keep the title group on its original center. Nudge it up only
            // when a short screen would otherwise slide it under the credit.
            final media = MediaQuery.of(context);
            final bylineHeight = _LazyBearByline.blockHeight(
              unit,
              textScale: media.textScaler.scale(16) / 16,
              safeBottom: media.padding.bottom,
            );
            final heroHeight = unit * 0.92;
            final roomBelow = (box.maxHeight - heroHeight) / 2 - bylineHeight;
            final lift = roomBelow < 12 ? (12 - roomBelow) * 2 : 0.0;
            return Stack(
              children: [
                Positioned.fill(child: GraphPaper(spacing: unit / 22)),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: math.max(0, lift)),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IdlePuppy(width: unit * 0.5, pose: DogPose.happy, loopSeconds: 1.6),
                            SizedBox(height: unit * 0.08),
                            FadeTransition(
                              opacity: CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.45)),
                              child: SizedBox(
                                width: unit * 0.9,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: NotebookTitle(fontSize: unit * 0.13, subtitle: 'a little notebook puppy'),
                                ),
                              ),
                            ),
                            SizedBox(height: unit * 0.1),
                            _LoadingDots(animation: _controller, size: unit * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: _LazyBearByline(unit: unit),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "by / The Lazy Bear Club" with the studio icon, pinned under the title.
///
/// Colors are the notebook inks, not theme-on-surface colors, so the credit
/// stays readable on the paper splash in light and dark themes.
class _LazyBearByline extends StatelessWidget {
  const _LazyBearByline({required this.unit});

  final double unit;

  static const asset = 'assets/branding/lazy_bear_club.png';

  static double iconSize(double unit) => (unit * 0.115).clamp(40.0, 56.0);

  static double byFont(double unit) => (unit * 0.034).clamp(13.0, 16.0);

  static double nameFont(double unit) => (unit * 0.046).clamp(15.0, 20.0);

  /// Height occupied at the bottom of the splash, including the safe-area
  /// padding the credit is wrapped in. Ignores the row's scale-down, so the
  /// title is only nudged when the credit might actually cover it.
  static double blockHeight(double unit, {required double textScale, required double safeBottom}) {
    final icon = iconSize(unit);
    final by = byFont(unit) * textScale;
    final name = nameFont(unit) * textScale;
    final textHeight = by + by * 0.15 + name;
    final bottomPad = math.max(16.0, safeBottom);
    return 4 + math.max(icon, textHeight) + bottomPad;
  }

  @override
  Widget build(BuildContext context) {
    final icon = iconSize(unit);
    final bySize = byFont(unit);
    final nameSize = nameFont(unit);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(icon * 0.22),
            child: Image.asset(
              asset,
              width: icon,
              height: icon,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
          ),
          SizedBox(width: icon * 0.32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'by',
                style: TextStyle(
                  color: SketchColors.pencil,
                  fontSize: bySize,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1.0,
                ),
              ),
              SizedBox(height: bySize * 0.15),
              Text(
                'The Lazy Bear Club',
                style: TextStyle(
                  color: SketchColors.ink,
                  fontSize: nameSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Three pencil dots that fill in one after another.
class _LoadingDots extends AnimatedWidget {
  const _LoadingDots({required Animation<double> animation, required this.size}) : super(listenable: animation);

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.5),
            child: CustomPaint(
              size: Size.square(size),
              painter: _DotPainter(filled: ((t * 6) % 3) >= i),
            ),
          ),
      ],
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = SketchPen(canvas);
    final dot = ovalPath(size.center(Offset.zero), size.width, size.height);
    if (filled) pen.fill(dot, SketchColors.coral);
    pen.stroke(dot, SketchColors.ink, width: 1.4, wobble: 0.4, sketchy: false);
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) => oldDelegate.filled != filled;
}

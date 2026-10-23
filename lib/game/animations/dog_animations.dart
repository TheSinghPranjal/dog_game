import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../models/dog_game_state.dart';
import '../models/game_timings.dart';

enum DogMouth { smile, open, chew, tongue }

/// Marks over or beside the head; [woof] is three little sound ticks by
/// the mouth.
enum DogMark { none, exclaim, question, woof }

/// What the dog holds in his mouth, if anything.
enum DogCarry { none, ball, stick, bone, slipper, frisbee }

/// Everything the dog painter needs for one frame, in the dog's own 100x85
/// drawing units (facing right; the painter mirrors it for left).
class DogFrame {
  const DogFrame({
    this.breath = 1,
    this.bodyLift = 0,
    this.bodyRotation = 0,
    this.headOffset = Offset.zero,
    this.headTilt = 0,
    this.feet = _still,
    this.raisedPaw,
    this.hindPaw,
    this.tailAngle = 0,
    this.tailBlur = false,
    this.eyeOpen = 1,
    this.eyeScale = 1,
    this.happyEyes = false,
    this.mouth = DogMouth.smile,
    this.gaze = 0,
    this.gazeY = 0,
    this.motionMarks = false,
    this.eatMarks = 0,
    this.sparkle = 0,
    this.mark = DogMark.none,
    this.shadow = true,
    this.earTwitch = 0,
    this.earsBack = false,
    this.carry = DogCarry.none,
  });

  static const _still = [Offset.zero, Offset.zero, Offset.zero, Offset.zero];

  /// Vertical scale of the body (breathing).
  final double breath;

  /// Vertical offset of everything except the shadow; negative is up.
  final double bodyLift;

  /// Whole-body rotation (radians, negative = nose up), used for begging,
  /// paws-up and rolling over.
  final double bodyRotation;
  final Offset headOffset;
  final double headTilt;

  /// Foot offsets: far back, near back, far front, near front.
  final List<Offset> feet;

  /// When set, the near front paw is lifted to this point.
  final Offset? raisedPaw;

  /// When set, the near hind paw is lifted to this point (ear scratching).
  final Offset? hindPaw;
  final double tailAngle;

  /// Wagging so fast it blurs: little motion ticks around the tail.
  final bool tailBlur;
  final double eyeOpen;
  final double eyeScale;
  final bool happyEyes;
  final DogMouth mouth;

  /// -1..1, where the pupils look (positive = the way the dog faces / down).
  final double gaze;
  final double gazeY;
  final bool motionMarks;
  final double eatMarks;
  final double sparkle;
  final DogMark mark;
  final bool shadow;

  /// Small rotation (radians) of one ear for a gentle flap.
  final double earTwitch;

  /// Ears pinned back (surprised).
  final bool earsBack;
  final DogCarry carry;

  DogFrame copyWith({
    double? earTwitch,
    double? eyeScale,
    bool? happyEyes,
    DogMouth? mouth,
    bool? motionMarks,
    double? sparkle,
    DogMark? mark,
    DogCarry? carry,
  }) => DogFrame(
    breath: breath,
    bodyLift: bodyLift,
    bodyRotation: bodyRotation,
    headOffset: headOffset,
    headTilt: headTilt,
    feet: feet,
    raisedPaw: raisedPaw,
    hindPaw: hindPaw,
    tailAngle: tailAngle,
    tailBlur: tailBlur,
    eyeOpen: eyeOpen,
    eyeScale: eyeScale ?? this.eyeScale,
    happyEyes: happyEyes ?? this.happyEyes,
    mouth: mouth ?? this.mouth,
    gaze: gaze,
    gazeY: gazeY,
    motionMarks: motionMarks ?? this.motionMarks,
    eatMarks: eatMarks,
    sparkle: sparkle ?? this.sparkle,
    mark: mark ?? this.mark,
    shadow: shadow,
    earTwitch: earTwitch ?? this.earTwitch,
    earsBack: earsBack,
    carry: carry ?? this.carry,
  );

  /// The same frame with a different mark above the head.
  DogFrame withMark(DogMark value) => copyWith(mark: value);

  /// The same frame holding [item] in the mouth (closed around it).
  DogFrame holding(DogCarry item) => item == DogCarry.none
      ? this
      : copyWith(carry: item, mouth: mouth == DogMouth.chew ? DogMouth.chew : DogMouth.smile);
}

/// Resting spot of the near front paw, matching the painter's leg layout.
const nearFrontPawRest = Offset(65, 83.5);

double _ease(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

double _seconds(Duration d) => d.inMicroseconds / Duration.microsecondsPerSecond;

List<Offset> _tucked(double d) => [Offset(0, -d), Offset(0, -d), Offset(0, -d), Offset(0, -d)];

const _sitFeet = [Offset(-3, -5), Offset(-3, -5), Offset(-1, -5), Offset(-1, -5)];

/// Builds the dog's frame from the current pose and the game clock.
///
/// Ambient life (breathing, blinking, tail wags) is derived from [time] so
/// it never needs its own timers. [lift] is the extra air height of a hop.
DogFrame dogFrameFor({
  required DogPose pose,
  required double time,
  required double poseTime,
  required double walkPhase,
  required double gaze,
  double gazeY = 0,
  required double swipe,
  double lift = 0,
  DogMark mark = DogMark.none,
  DogCarry carry = DogCarry.none,
}) {
  var frame = _poseFrame(pose, time, poseTime, walkPhase, gaze, gazeY, swipe, lift);
  if (mark != DogMark.none) frame = frame.withMark(mark);
  return frame.holding(carry);
}

DogFrame _poseFrame(
  DogPose pose,
  double time,
  double poseTime,
  double walkPhase,
  double gaze,
  double gazeY,
  double swipe,
  double lift,
) {
  final breath = 1 + 0.022 * math.sin(time * 2.6);
  final blinkT = time % 3.8;
  final eyeOpen = blinkT < 0.16 ? 1 - math.sin(blinkT / 0.16 * math.pi) : 1.0;
  final flickT = time % 5.5;
  final flick = flickT < 0.6 ? math.sin(flickT / 0.6 * math.pi * 2) * 0.35 : 0.0;
  // A happy little wag, with a bigger swish now and then.
  final tail = math.sin(time * 7.5) * 0.16 + flick;
  final earT = time % 4.6;
  final ear = earT < 0.35 ? math.sin(earT / 0.35 * math.pi * 2) * 0.18 : 0.0;

  switch (pose) {
    case DogPose.idle:
      return DogFrame(
        earTwitch: ear,
        breath: breath,
        bodyLift: -lift,
        headTilt: math.sin(time * 0.7) * 0.03,
        tailAngle: tail,
        eyeOpen: eyeOpen,
        gaze: gaze,
        gazeY: gazeY,
      );

    case DogPose.walk:
      final s = math.sin(walkPhase);
      final c = math.cos(walkPhase);
      final a = Offset(s * 4.5, -math.max(0, c) * 3);
      final b = Offset(-s * 4.5, -math.max(0, -c) * 3);
      return DogFrame(
        breath: breath,
        bodyLift: -(1 - math.cos(walkPhase * 2)) * 0.6,
        headOffset: Offset(0, s.abs() * 0.6),
        feet: [a, b, b, a],
        // The tail swings side to side with every step.
        tailAngle: math.sin(walkPhase) * 0.3 + 0.1,
        eyeOpen: eyeOpen,
        mouth: DogMouth.tongue,
        gaze: gaze,
        gazeY: gazeY,
        motionMarks: true,
      );

    case DogPose.pant:
      final huff = math.sin(time * 11);
      return DogFrame(
        earTwitch: ear,
        breath: 1 + 0.045 * huff,
        headOffset: Offset(0, huff * 0.5),
        tailAngle: tail,
        eyeOpen: eyeOpen,
        mouth: DogMouth.tongue,
        gaze: gaze,
        gazeY: gazeY,
      );

    case DogPose.scratchEar:
      final total = _seconds(GameTimings.scratchEar);
      final raise = _ease(math.min(poseTime / 0.35, (total - poseTime) / 0.35));
      final kick = math.sin(poseTime * 26);
      return DogFrame(
        breath: breath,
        bodyLift: 5,
        feet: const [Offset(-3, -5), Offset(-3, -5), Offset(-1, -5), Offset(-1, -5)],
        headOffset: Offset(-3, 1) * raise,
        headTilt: 0.28 * raise,
        hindPaw: raise > 0.05 ? Offset.lerp(const Offset(40, 78), Offset(56, 46 + kick * 2.5), raise)! : null,
        tailAngle: -0.2 + math.sin(time * 3) * 0.1,
        eyeOpen: eyeOpen,
        happyEyes: raise > 0.5,
        mouth: raise > 0.5 ? DogMouth.tongue : DogMouth.smile,
        motionMarks: raise > 0.5,
      );

    case DogPose.eat:
      final dip = _ease(poseTime / 0.4);
      final chew = math.sin(poseTime * 13);
      return DogFrame(
        breath: breath,
        headOffset: Offset(6 * dip, 18 * dip + chew * 1.0 * dip),
        headTilt: 0.22 * dip,
        tailAngle: math.sin(time * 9) * 0.25,
        happyEyes: dip > 0.5,
        mouth: chew > 0 ? DogMouth.chew : DogMouth.smile,
        eatMarks: dip * ((poseTime * 2) % 1 < 0.5 ? 1 : 0),
      );

    case DogPose.playBow:
      // Front end down, rump and tail up, ready to spring.
      return DogFrame(
        breath: breath,
        bodyRotation: 0.22,
        bodyLift: 1,
        feet: const [Offset(1, 3.5), Offset(1, 3.5), Offset(3, -7), Offset(3, -7)],
        headOffset: const Offset(3, 2),
        raisedPaw: swipe > 0.01 ? Offset.lerp(nearFrontPawRest, const Offset(86, 67), swipe)! : null,
        tailAngle: 0.45 + math.sin(time * 14) * 0.3,
        tailBlur: true,
        eyeOpen: eyeOpen,
        mouth: DogMouth.tongue,
        gaze: gaze,
        gazeY: gazeY,
      );

    case DogPose.happy:
      final hop = math.sin(poseTime * 8).abs() * 5 * math.max(0, 1 - poseTime / 1.2);
      return DogFrame(
        breath: breath,
        bodyLift: -hop,
        tailAngle: 0.35 + math.sin(poseTime * 16) * 0.3,
        tailBlur: true,
        happyEyes: true,
        mouth: DogMouth.tongue,
        sparkle: poseTime,
      );

    case DogPose.crouch:
      return DogFrame(
        earTwitch: ear,
        breath: breath,
        bodyLift: 4,
        feet: _tucked(4),
        headOffset: const Offset(2, 3),
        tailAngle: math.sin(time * 6) * 0.12 - 0.2,
        eyeOpen: eyeOpen,
        eyeScale: 1.08,
        gaze: gaze,
        gazeY: gazeY,
      );

    case DogPose.lunge:
      final p = (poseTime / _seconds(GameTimings.leap)).clamp(0.0, 1.0);
      final stretch = math.sin(p * math.pi);
      return DogFrame(
        breath: breath,
        bodyLift: -lift,
        bodyRotation: -0.3 * (1 - 2 * p) * stretch,
        feet: [
          Offset(-5 * stretch, -2 * stretch),
          Offset(-5 * stretch, -2 * stretch),
          Offset(5 * stretch, -4 * stretch),
          Offset(5 * stretch, -4 * stretch),
        ],
        tailAngle: 0.3 * stretch,
        mouth: DogMouth.open,
        eyeScale: 1.08,
        gaze: gaze,
        gazeY: gazeY,
        motionMarks: true,
      );

    case DogPose.surprised:
      return DogFrame(
        breath: breath,
        headOffset: const Offset(0, -1),
        tailAngle: 0.4,
        eyeOpen: eyeOpen,
        eyeScale: 1.18,
        mouth: DogMouth.open,
        earsBack: true,
        mark: poseTime < 1.4 ? DogMark.exclaim : DogMark.none,
      );

    case DogPose.sit:
      return DogFrame(
        earTwitch: ear,
        breath: breath,
        bodyLift: 5,
        feet: _sitFeet,
        headOffset: const Offset(-2, -1),
        headTilt: math.sin(time * 0.8) * 0.04,
        tailAngle: -0.3 + math.sin(time * 4) * 0.12,
        eyeOpen: eyeOpen,
        gaze: gaze,
        gazeY: gazeY,
      );

    case DogPose.lieDown:
      // Lying flat, chin resting on the front paws.
      return DogFrame(
        earTwitch: ear,
        breath: 1 + 0.03 * math.sin(time * 1.8),
        bodyLift: 9,
        feet: const [Offset(-4, -9), Offset(-4, -9), Offset(6, -2.5), Offset(7, -2.5)],
        headOffset: const Offset(5, 12),
        headTilt: 0.12,
        tailAngle: -0.9 + math.sin(time * 2) * 0.08,
        eyeOpen: math.min(eyeOpen, 0.75),
        gaze: gaze,
        gazeY: gazeY,
      );

    case DogPose.relax:
      // Flopped down, eyes closed, a slow happy wag.
      return DogFrame(
        earTwitch: ear,
        breath: 1 + 0.035 * math.sin(time * 1.6),
        bodyLift: 9,
        feet: const [Offset(-4, -9), Offset(-4, -9), Offset(6, -2.5), Offset(7, -2.5)],
        headOffset: const Offset(4, 10),
        headTilt: 0.3,
        tailAngle: -0.8 + math.sin(time * 2.4) * 0.15,
        happyEyes: true,
      );

    case DogPose.shake:
      // A full-body shake, standing, from the nose to the tail.
      final s = math.sin(poseTime * 30);
      final env = math.sin(math.min(1, poseTime / _seconds(GameTimings.shake)) * math.pi);
      return DogFrame(
        breath: breath,
        bodyRotation: s * 0.05 * env,
        headOffset: Offset(s * 3 * env, -1),
        headTilt: s * 0.22 * env,
        tailAngle: -s * 0.4 * env,
        earTwitch: s * 0.5 * env,
        happyEyes: true,
        motionMarks: env > 0.3,
      );

    case DogPose.dig:
      final paddle = math.sin(poseTime * 18);
      return DogFrame(
        breath: breath,
        bodyRotation: 0.12,
        bodyLift: 1.5,
        feet: [
          Offset.zero,
          Offset.zero,
          Offset(paddle * 4, -3 + paddle.abs() * -2),
          Offset(-paddle * 4, -3 - paddle.abs() * 2),
        ],
        headOffset: const Offset(4, 7),
        headTilt: 0.2,
        tailAngle: 0.5 + math.sin(time * 12) * 0.25,
        eyeOpen: eyeOpen,
        mouth: DogMouth.tongue,
        motionMarks: true,
      );

    case DogPose.lookUp:
      return DogFrame(
        earTwitch: ear,
        breath: breath,
        headOffset: const Offset(0, -1),
        headTilt: -0.22,
        tailAngle: tail,
        eyeOpen: eyeOpen,
        gaze: gaze,
        gazeY: -1,
      );

    case DogPose.pawsUp:
      // Standing up on the hind legs, front paws on a counter or a trunk.
      return DogFrame(
        breath: breath,
        bodyRotation: -0.7,
        feet: const [Offset(3, 0), Offset(3, 0), Offset(0, -2), Offset(0, -2)],
        headOffset: const Offset(2, 2),
        headTilt: 0.35,
        tailAngle: math.sin(time * 12) * 0.3 + 0.2,
        tailBlur: true,
        eyeOpen: eyeOpen,
        gaze: 0.6,
        gazeY: -1,
        mouth: DogMouth.tongue,
      );

    case DogPose.beg:
      // Sitting up on the hind legs, both front paws tucked up.
      final bob = math.sin(poseTime * 5) * 1.2;
      return DogFrame(
        breath: breath,
        bodyRotation: -0.5,
        bodyLift: 4 + bob,
        feet: const [Offset(-2, -4), Offset(-2, -4), Offset(-4, -9), Offset(0, 0)],
        raisedPaw: Offset(74, 50 + bob),
        headOffset: const Offset(1, 3),
        headTilt: 0.4,
        tailAngle: math.sin(time * 14) * 0.3,
        tailBlur: true,
        eyeOpen: eyeOpen,
        eyeScale: 1.15,
        mouth: DogMouth.tongue,
      );

    case DogPose.rollOver:
      final p = (poseTime / _seconds(GameTimings.rollOver)).clamp(0.0, 1.0);
      final turn = Curves.easeInOut.transform(p);
      return DogFrame(
        breath: breath,
        bodyRotation: turn * math.pi * 2,
        bodyLift: -math.sin(p * math.pi) * 8,
        feet: _tucked(5 * math.sin(p * math.pi)),
        tailAngle: tail,
        happyEyes: true,
        mouth: DogMouth.tongue,
        motionMarks: p > 0.1 && p < 0.9,
      );

    case DogPose.bark:
      // Woof! Woof! The mouth snaps open on each bark.
      final open = math.sin(poseTime * 11) > 0;
      return DogFrame(
        breath: breath,
        headOffset: Offset(0, open ? -1.5 : 0),
        headTilt: open ? -0.1 : 0,
        tailAngle: 0.4 + math.sin(time * 12) * 0.2,
        eyeOpen: eyeOpen,
        mouth: open ? DogMouth.open : DogMouth.smile,
        mark: open ? DogMark.woof : DogMark.none,
      );

    case DogPose.wag:
      // Sitting pretty, tail wagging so fast it blurs.
      return DogFrame(
        earTwitch: ear,
        breath: breath,
        bodyLift: 5,
        feet: _sitFeet,
        headOffset: const Offset(-2, -1),
        headTilt: math.sin(time * 2) * 0.06,
        tailAngle: math.sin(time * 22) * 0.45,
        tailBlur: true,
        happyEyes: true,
        mouth: DogMouth.tongue,
      );

    case DogPose.sniff:
      final twitch = math.sin(poseTime * 16);
      return DogFrame(
        breath: breath,
        headOffset: Offset(3.5 + twitch * 0.8, 6),
        headTilt: 0.12,
        tailAngle: 0.2 + math.sin(time * 6) * 0.15,
        eyeOpen: math.max(0.55, eyeOpen),
        earTwitch: 0.12,
        gaze: gaze,
        gazeY: 0.6,
      );

    case DogPose.scratch:
      // Up on the hind legs, scrabbling at a door with a front paw.
      final stroke = math.sin(poseTime * 12);
      return DogFrame(
        breath: breath,
        bodyRotation: -0.85,
        feet: const [Offset(2, 0), Offset(2, 0), Offset(0, -3), Offset(0, -3)],
        raisedPaw: Offset(84, 48 + stroke * 8),
        headOffset: const Offset(1, 2),
        tailAngle: math.sin(time * 8) * 0.3 - 0.2,
        eyeScale: 1.1,
        mouth: DogMouth.open,
        motionMarks: true,
      );

    case DogPose.lookDown:
      return DogFrame(
        breath: breath,
        headOffset: const Offset(3, 3),
        headTilt: 0.25,
        tailAngle: 0.1,
        eyeOpen: eyeOpen,
        eyeScale: 1.15,
        earTwitch: 0.15,
        gaze: 0.6,
        gazeY: 1,
      );

    case DogPose.innocent:
      return DogFrame(
        breath: breath,
        bodyLift: 5,
        feet: _sitFeet,
        headOffset: const Offset(-2, -1),
        headTilt: 0.14,
        tailAngle: -0.2 + math.sin(time * 1.4) * 0.1,
        eyeOpen: eyeOpen,
        eyeScale: 1.2,
        mark: poseTime < 1.6 ? DogMark.question : DogMark.none,
      );

    case DogPose.satisfied:
      final lipLick = math.sin(poseTime * 9) > 0.2;
      return DogFrame(
        breath: breath,
        bodyLift: 5,
        feet: _sitFeet,
        headOffset: const Offset(-2, -1),
        tailAngle: 0.3 + math.sin(poseTime * 14) * 0.25,
        tailBlur: true,
        happyEyes: true,
        mouth: lipLick ? DogMouth.tongue : DogMouth.smile,
        sparkle: poseTime,
      );

    case DogPose.paw:
      return DogFrame(
        breath: breath,
        bodyLift: 1.5,
        headOffset: const Offset(1, 0),
        headTilt: -0.15,
        raisedPaw: Offset.lerp(nearFrontPawRest, const Offset(82, 46), swipe)!,
        tailAngle: math.sin(time * 12) * 0.3,
        eyeOpen: eyeOpen,
        mouth: DogMouth.open,
        gaze: gaze,
        gazeY: -0.8,
      );
  }
}

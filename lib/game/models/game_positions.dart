import 'dart:math' as math;
import 'dart:ui';

/// Every gameplay coordinate lives in this file so scenes can be tuned
/// without touching the animation logic.
///
/// All values are normalized to the game stage: x is a fraction of the stage
/// width, y a fraction of the stage height. Character and prop positions are
/// the bottom-center (feet / base) of the sprite.
abstract final class SceneMetrics {
  /// y of the ground baseline shared by all locations.
  static const groundLine = 0.63;

  /// Bottom of the shaded floor / grass area.
  static const groundBottom = 0.795;

  /// Top of the control panel (action buttons and navigation).
  static const controlsTop = 0.815;
  static const actionRowY = 0.858;
  static const navBarY = 0.952;
}

abstract final class HomePositions {
  static const idlePositionA = Offset(0.34, 0.715);
  static const idlePositionB = Offset(0.52, 0.725);
  static const idlePositionC = Offset(0.66, 0.715);
  static const returnPosition = idlePositionB;

  // Feed.
  static const feedingPosition = Offset(0.37, 0.725);
  static const bowlPosition = Offset(0.29, 0.755);

  // Fetch.
  static const playPosition = Offset(0.40, 0.725);
  static const chasePosition = Offset(0.47, 0.725);
  static const ballStartPosition = Offset(0.60, 0.755);
  static const ballWaypoints = [Offset(0.75, 0.755), Offset(0.635, 0.755)];
  static const ballEndPosition = Offset(0.70, 0.755);

  /// Where he trots back with the ball in his mouth.
  static const fetchReturnPosition = Offset(0.52, 0.735);

  // Squirrel. It pops out of the hole in the baseboard beside the sofa and
  // darts back in.
  static const squirrelHolePosition = Offset(0.675, SceneMetrics.groundLine);
  static const squirrelSpawnPosition = Offset(0.645, 0.672);
  static const dogSquirrelApproachPosition = Offset(0.34, 0.725);
  static const squirrelWaypointA = Offset(0.55, 0.745);
  static const squirrelWaypointB = Offset(0.66, 0.772);
  static const squirrelWaypointC = Offset(0.57, 0.775);
  static const dogSquirrelPursuitPositions = [Offset(0.38, 0.73), Offset(0.41, 0.735)];
  static const dogSquirrelLungeTarget = Offset(0.50, 0.745);
  static const squirrelFinalPosition = Offset(0.675, 0.636);
  static const dogSquirrelReturnPosition = idlePositionB;

  // Resting props: part of the room, hidden while their activity runs.
  static const restingBowlPosition = Offset(0.12, 0.775);
  static const restingBallPosition = Offset(0.86, 0.787);
  static const restingRopePosition = Offset(0.885, 0.712);
}

abstract final class KitchenPositions {
  // Static furniture, shared with the kitchen painter so props line up with
  // the drawing exactly.
  static const counterTop = 0.44;
  static const counterRight = 0.50;
  static const counterFrontBottom = 0.465;
  static const cabinetDoors = [
    Rect.fromLTRB(0.015, 0.477, 0.165, 0.615),
    Rect.fromLTRB(0.18, 0.477, 0.33, 0.615),
    Rect.fromLTRB(0.345, 0.477, 0.49, 0.615),
  ];
  static const stoveLeft = 0.51;
  static const stoveRight = 0.73;
  static const fridgeLeft = 0.76;
  static const stovePosition = Offset(0.62, counterTop);

  /// The low step stool by the counter, for short-legged dogs.
  static const stoolPosition = Offset(0.215, 0.70);
  static const stoolTopY = 0.615;

  static const idlePositionA = Offset(0.30, 0.715);
  static const idlePositionB = Offset(0.44, 0.728);
  static const idlePositionC = Offset(0.60, 0.715);

  // Glass trouble. Short-legged dogs climb the stool onto the counter; taller
  // dogs stand up with their front paws on the counter's edge.
  static const glassDogStartPosition = idlePositionB;
  static const glassCounterApproachPosition = Offset(0.30, 0.73);
  static const glassOnStoolPosition = Offset(0.215, stoolTopY);
  static const glassCounterIdlePosition = Offset(0.17, counterTop - 0.002);
  static const glassPawsUpPosition = Offset(0.37, 0.70);
  static const glassSpawnPosition = Offset(0.29, counterTop);
  static const glassPawReachPosition = Offset(0.305, counterTop);
  static const glassEdgePosition = Offset(0.33, counterTop);
  static const glassFallWaypointA = Offset(0.355, 0.47);
  static const glassFallWaypointB = Offset(0.375, 0.62);
  static const glassLandingPosition = Offset(0.385, 0.765);
  static const glassDogReactionPosition = glassCounterIdlePosition;
  static const glassHopDownPosition = Offset(0.26, 0.735);
  static const glassDogReturnPosition = idlePositionB;

  // Treat time: scratch the right-hand cabinet until it opens.
  static const treatDogStartPosition = idlePositionB;
  static const treatCabinetDoorRect = Rect.fromLTRB(0.345, 0.477, 0.49, 0.615);
  static const treatCabinetDoorPosition = Offset(0.4175, 0.615);
  static const treatCabinetApproachPosition = Offset(0.53, 0.735);
  static const treatScratchPosition = Offset(0.49, 0.735);
  static const treatSpawnPosition = Offset(0.41, 0.605);
  static const treatRevealPosition = Offset(0.365, 0.668);
  static const treatEatingPosition = Offset(0.47, 0.735);
  static const treatServePosition = Offset(0.395, 0.752);
  static const treatDogReturnPosition = idlePositionB;

  // Dinner: smell it, watch it roast from a safe spot well away from the
  // stove, then eat it from a plate on the floor.
  static const dinnerDogStartPosition = idlePositionB;
  static const dinnerDogSniffPosition = Offset(0.40, 0.73);
  static const dinnerDogWatchPosition = Offset(0.34, 0.732);
  static const dinnerRawSpawnPosition = Offset(0.62, 0.36);
  static const dinnerCookingPosition = Offset(0.62, counterTop - 0.003);
  static const dinnerAromaPosition = Offset(0.62, 0.415);
  static const dinnerTimerPosition = Offset(0.70, 0.355);
  static const dinnerServingSpawnPosition = Offset(0.44, counterTop);
  static const dinnerServingMoveWaypoint = Offset(0.38, 0.60);
  static const dinnerServingPosition = Offset(0.24, 0.765);
  static const dinnerDogEatingPosition = Offset(0.33, 0.738);
  static const dinnerDogReturnPosition = idlePositionB;
}

abstract final class BathPositions {
  static const idlePositionA = Offset(0.52, 0.725);
  static const idlePositionB = Offset(0.64, 0.735);
  static const idlePositionC = Offset(0.78, 0.725);

  // Bath time. The tub is a scene prop drawn in front of the dog.
  static const bathTubPosition = Offset(0.23, 0.70);
  static const dogBathEntryPosition = Offset(0.50, 0.73);
  static const dogBathPosition = Offset(0.24, 0.642);
  static const bathBubbleSpawnPosition = Offset(0.24, 0.575);
  static const dogBathReturnPosition = idlePositionB;

  // Brush fur. The dog faces left; its back is on the right.
  static const brushSpawnPosition = Offset(0.46, 0.70);
  static const dogBrushPosition = Offset(0.64, 0.735);
  static const brushStrokeStart = Offset(0.735, 0.694);
  static const brushStrokeEnd = Offset(0.69, 0.69);
  static const brushSparklePosition = Offset(0.70, 0.665);
  static const dogBrushReturnPosition = idlePositionB;

  // Towel dry. The dog faces right; the towel rubs over its head.
  static const dogDryPosition = Offset(0.64, 0.735);
  static const towelSpawnPosition = Offset(0.68, 0.60);
  static const towelRubPositions = [Offset(0.685, 0.668), Offset(0.675, 0.69)];
  static const dropletsPosition = Offset(0.66, 0.68);
  static const dogDryReturnPosition = idlePositionB;
}

abstract final class OutdoorPositions {
  static const idlePositionA = Offset(0.44, 0.715);
  static const idlePositionB = Offset(0.58, 0.725);
  static const idlePositionC = Offset(0.70, 0.715);

  // Tree geometry, shared with the garden painter.
  static const trunkLeft = 0.08;
  static const trunkRight = 0.20;
  static const lowBranchStart = Offset(0.19, 0.505);
  static const lowBranchEnd = Offset(0.45, 0.49);
  static const highBranchStart = Offset(0.18, 0.375);
  static const highBranchEnd = Offset(0.41, 0.36);

  /// The fire hydrant by the fence, and the mound with a bone buried in it.
  static const hydrantPosition = Offset(0.90, 0.70);
  static const moundPosition = Offset(0.66, 0.775);

  // Squirrel: it darts across the grass and shoots up the tree; he only
  // puts his paws on the trunk and looks up.
  static const squirrelSpawnPosition = Offset(0.86, 0.745);
  static const squirrelDartPosition = Offset(0.55, 0.755);
  static const squirrelTrunkBase = Offset(0.20, 0.73);
  static const squirrelTrunkTop = Offset(0.19, 0.52);
  static const squirrelOnBranch = Offset(0.33, 0.495);
  static const squirrelHigh = Offset(0.30, 0.36);
  static const dogSquirrelStartPosition = Offset(0.62, 0.73);
  static const dogAtTrunk = Offset(0.29, 0.73);
  static const dogSquirrelReturnPosition = idlePositionB;

  // Dig: front paws going, dirt flying, a bone pops out.
  static const dogDigPosition = Offset(0.56, 0.745);
  static const dirtPosition = Offset(0.58, 0.73);
  static const dogParadeA = Offset(0.40, 0.735);
  static const dogParadeB = Offset(0.52, 0.735);
  static const dogDigReturnPosition = idlePositionB;

  // Frisbee: it loops across, he jumps twice and catches it on the second.
  static const frisbeeSpawnPosition = Offset(-0.08, 0.42);
  static const frisbeeLoopA = Offset(0.40, 0.48);
  static const frisbeeLoopB = Offset(0.78, 0.44);
  static const frisbeeLoopC = Offset(0.62, 0.56);
  static const frisbeeMissPosition = Offset(0.66, 0.52);
  static const frisbeeCatchPosition = Offset(0.56, 0.60);
  static const dogFrisbeeStartPosition = Offset(0.50, 0.735);
  static const dogFrisbeeCatchPosition = Offset(0.55, 0.735);
  static const frisbeeDropPosition = Offset(0.53, 0.745);
  static const dogFrisbeeReturnPosition = idlePositionB;
}

abstract final class BedroomPositions {
  static const idlePositionA = Offset(0.32, 0.715);
  static const idlePositionB = Offset(0.48, 0.725);
  static const idlePositionC = Offset(0.62, 0.715);
  static const returnPosition = idlePositionB;

  // Furniture: the wardrobe stands on the left, the bed on the right.
  static const wardrobePosition = Offset(0.165, 0.638);
  static const pillowPosition = Offset(0.875, 0.578);
  static const socketPosition = Offset(0.515, 0.6);
  static const phonePosition = Offset(0.665, 0.692);

  /// Where the charging cable lies on the floor (he leaves it alone).
  static const cableRestPoint = Offset(0.59, 0.688);

  /// The girl stands by the back wall; scripts move her sideways by
  /// fractions of the stage width from here.
  static const girlPosition = Offset(0.44, 0.65);
  static const girlAtBed = 0.22;
  static const girlAtWardrobe = -0.09;

  // Closet hide-and-peek.
  static const dogWardrobeFront = Offset(0.27, 0.715);
  static const dogInWardrobe = Offset(0.20, 0.62);
  static const dogWardrobeJumpOut = Offset(0.34, 0.73);

  // Slipper: it lies on the rug, well away from the charger cable.
  static const slipperPosition = Offset(0.37, 0.77);
  static const dogSlipperPosition = Offset(0.46, 0.745);

  // Bed and his round dog pillow.
  static const dogBedFoot = Offset(0.60, 0.72);
  static const dogOnBed = Offset(0.68, 0.572);
  static const dogBedMiddle = Offset(0.76, 0.571);
  static const dogOnPillow = Offset(0.86, 0.558);
  static const dogBedJumpDown = Offset(0.70, 0.75);
}

abstract final class LivingRoomPositions {
  static const idlePositionA = Offset(0.42, 0.715);
  static const idlePositionB = Offset(0.52, 0.725);
  static const idlePositionC = Offset(0.64, 0.715);
  static const returnPosition = idlePositionB;

  /// The big window on the left: its glass, and the sill the dog sits on.
  static const windowGlass = Rect.fromLTRB(0.07, 0.17, 0.33, 0.455);
  static const sillY = 0.476;

  /// The long curtain right of the window, which the dog hides behind.
  static const curtainLeft = 0.325;
  static const curtainRight = 0.42;
  static const curtainTop = 0.14;

  /// The girl stands in the middle of the room.
  static const girlPosition = Offset(0.58, 0.65);

  /// The front door with its mail slot, on the right; the side table and
  /// lamp by the curtain.
  static const doorPosition = Offset(0.905, SceneMetrics.groundLine);
  static const sideTablePosition = Offset(0.465, SceneMetrics.groundLine);

  // Mail.
  static const dogAtDoor = Offset(0.76, 0.73);
  static const knockAt = Offset(0.97, 0.50);

  // Wag: he sits by the girl and she pets him.
  static const dogByGirl = Offset(0.66, 0.725);
  static const dogLeanIn = Offset(0.635, 0.725);
  static const heartsAt = Offset(0.64, 0.56);

  // Window.
  static const dogBelowWindow = Offset(0.40, 0.72);
  static const dogOnSill = Offset(0.22, 0.476);
  static const dogJumpDown = Offset(0.42, 0.72);
  static const squirrelOnSill = Offset(0.13, 0.455);
  static const squirrelSillSpawn = Offset(-0.06, 0.455);
  static const squirrelSillExit = Offset(-0.1, 0.455);
}

abstract final class ParkPositions {
  static const idlePositionA = Offset(0.32, 0.725);
  static const idlePositionB = Offset(0.42, 0.73);
  static const idlePositionC = Offset(0.52, 0.72);
  static const returnPosition = idlePositionB;

  /// The pond on the right (centre, and half-width / half-height).
  static const pondCenter = Offset(0.80, 0.712);
  static const pondRadius = Size(0.2, 0.045);

  /// The bench at the back, and the leaf pile at the front left.
  static const benchLeft = 0.24;
  static const benchRight = 0.52;
  static const benchSeatY = 0.585;
  static const leafPilePosition = Offset(0.15, 0.768);
  static const lampPosition = Offset(0.58, 0.632);

  // Ducks.
  static const dogAtPond = Offset(0.56, 0.725);
  static const dogStartled = Offset(0.44, 0.73);
  static const duckSpawn = Offset(1.06, 0.705);
  static const duckNear = Offset(0.67, 0.708);
  static const duckExit = Offset(1.08, 0.715);
  static const quackAt = Offset(0.64, 0.66);

  // Leaf pile.
  static const dogLeafRunStart = Offset(0.38, 0.73);
  static const dogInLeaves = Offset(0.16, 0.762);
  static const dogOutOfLeaves = Offset(0.28, 0.73);
  static const dogDropStick = Offset(0.36, 0.735);

  // Pigeon on the bench.
  static const pigeonOnBench = Offset(0.40, 0.585);
  static const pigeonOnLamp = Offset(0.58, 0.405);
  static const dogSneakStart = Offset(0.56, 0.725);
  static const dogSneakEnd = Offset(0.46, 0.72);
  static const dogOnBench = Offset(0.36, 0.586);
}

/// Sprite sizes (widths) as fractions of [GameLayout.unit].
abstract final class GameSizes {
  static const dog = 0.25;
  static const bowl = 0.17;
  static const ball = 0.085;
  static const squirrel = 0.10;
  static const frisbee = 0.12;
  static const slipper = 0.11;
  static const rope = 0.12;
  static const mound = 0.2;
  static const hydrant = 0.08;
  static const door = 0.16;
  static const sideTable = 0.10;
  static const brush = 0.13;
  static const towel = 0.21;
  static const tub = 0.42;
  static const glass = 0.05;
  static const treat = 0.065;
  static const drumstick = 0.11;
  static const plate = 0.15;
  static const wardrobe = 0.27;
  static const pillow = 0.14;
  static const girl = 0.21;
  static const duck = 0.11;
  static const pigeon = 0.085;
  static const leafPile = 0.22;
  static const actionButtonWidth = 0.29;
  static const actionButtonHeight = 0.14;
  static const navBarHeight = 0.145;
  static const navBarWidth = 0.88;
  static const cornerButton = 0.11;

  /// Ball radius in normalized stage-width units, used to derive spin from
  /// distance rolled (exact on a 9:16 stage, close enough elsewhere).
  static const ballRadiusNormalized = ball / 2;
}

/// Maps the normalized coordinates onto the pixels of the current stage.
class GameLayout {
  GameLayout(this.size) : unit = math.min(size.width, size.height * 9 / 16);

  final Size size;

  /// Scale reference: the width of an ideal 9:16 stage that fits. Sizes use
  /// this so nothing stretches on unusual aspect ratios.
  final double unit;

  Offset toPixels(Offset normalized) => Offset(normalized.dx * size.width, normalized.dy * size.height);
}

enum WanderAction { pause, habit, walk, sniff }

class WanderStep {
  const WanderStep.pause(this.seconds) : action = WanderAction.pause, target = null;

  /// The dog's own idle habit (pant, scratch an ear, chin on paws...).
  const WanderStep.habit() : action = WanderAction.habit, seconds = 0, target = null;
  const WanderStep.sniff(this.seconds) : action = WanderAction.sniff, target = null;
  const WanderStep.walk(Offset this.target) : action = WanderAction.walk, seconds = 0;

  final WanderAction action;
  final double seconds;
  final Offset? target;
}

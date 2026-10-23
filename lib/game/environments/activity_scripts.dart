import '../models/activity_definition.dart';
import '../scripting/script_step.dart';
import 'bathroom/bath_scripts.dart';
import 'bedroom/bedroom_scripts.dart';
import 'kitchen/kitchen_scripts.dart';
import 'living_room/living_room_scripts.dart';
import 'living_area/home_scripts.dart';
import 'outdoors/outdoor_scripts.dart';
import 'park/park_scripts.dart';

/// The script each activity plays.
abstract final class ActivityScripts {
  static ActivityScript of(DogActivity activity) => switch (activity) {
    DogActivity.feed => HomeScripts.feed,
    DogActivity.fetch => HomeScripts.fetch,
    DogActivity.chaseSquirrel => HomeScripts.chaseSquirrel,
    DogActivity.bathTime => BathScripts.bathTime,
    DogActivity.brushFur => BathScripts.brushFur,
    DogActivity.towelDry => BathScripts.towelDry,
    DogActivity.treeSquirrel => OutdoorScripts.treeSquirrel,
    DogActivity.dig => OutdoorScripts.dig,
    DogActivity.frisbee => OutdoorScripts.frisbee,
    DogActivity.glassTrouble => KitchenScripts.glassTrouble,
    DogActivity.treatTime => KitchenScripts.treatTime,
    DogActivity.dinner => KitchenScripts.dinner,
    DogActivity.closetHide => BedroomScripts.closetHide,
    DogActivity.slipper => BedroomScripts.slipper,
    DogActivity.pillowJump => BedroomScripts.pillowJump,
    DogActivity.mail => LivingRoomScripts.mail,
    DogActivity.wag => LivingRoomScripts.wag,
    DogActivity.windowWatch => LivingRoomScripts.windowWatch,
    DogActivity.duckPond => ParkScripts.duckPond,
    DogActivity.leafPile => ParkScripts.leafPile,
    DogActivity.benchPigeon => ParkScripts.benchPigeon,
  };
}

/// Scene values of the bedroom's animated furniture. They all default to 0,
/// the room at rest: closet shut, pillow plump. The girl uses the shared
/// GirlKeys.
abstract final class BedroomKeys {
  /// 0 shut .. 1 wide open.
  static const wardrobeDoor = 'bedroom.wardrobeDoor';

  /// 1 while eyes peek out of the dark closet.
  static const wardrobeEyes = 'bedroom.wardrobeEyes';

  /// 1 while a wagging tail and one ear poke out of the closet door.
  static const wardrobeTail = 'bedroom.wardrobeTail';

  /// 0..1 how flat the pillow is squashed.
  static const pillowSquish = 'bedroom.pillowSquish';
}

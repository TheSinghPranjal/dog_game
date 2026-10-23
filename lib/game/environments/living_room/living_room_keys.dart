/// Scene values of the living room's animated props. All default to 0: the
/// door still, the mail slot empty, the curtains hanging straight.
abstract final class LivingRoomKeys {
  /// 0..1: the front door rattling under a knock.
  static const doorKnock = 'living.doorKnock';

  /// 0..1: how far an envelope pokes in through the mail slot.
  static const mailEnvelope = 'living.mailEnvelope';
}

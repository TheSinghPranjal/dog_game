enum DogActivity {
  feed,
  fetch,
  chaseSquirrel,
  bathTime,
  brushFur,
  towelDry,
  treeSquirrel,
  dig,
  frisbee,
  glassTrouble,
  treatTime,
  dinner,
  closetHide,
  slipper,
  pillowJump,
  mail,
  wag,
  windowWatch,
  duckPond,
  leafPile,
  benchPigeon,
}

/// One contextual action button.
class ActivityDefinition {
  const ActivityDefinition(this.activity, this.label, this.semanticLabel, {this.accent});

  final DogActivity activity;
  final String label;
  final String semanticLabel;

  /// Optional paper tint for the button (ARGB); plain white when null.
  final int? accent;
}

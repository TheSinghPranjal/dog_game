/// A dog's light needs. Each is 0..100. [hunger] rises when the dog is
/// hungry; for every other need, higher is better.
enum Need {
  hunger,
  energy,
  fun,
  cleanliness,
  affection;

  bool get lowerIsBetter => this == hunger;
}

/// One dog's needs, always clamped to 0..100. Values never reach a fail
/// state: low needs only nudge the dog's hints and idle routine.
class DogNeeds {
  const DogNeeds._(this._values);

  static const min = 0.0;
  static const max = 100.0;

  /// A comfortable start: a little peckish, otherwise content.
  static const initial = DogNeeds._({
    Need.hunger: 30,
    Need.energy: 70,
    Need.fun: 60,
    Need.cleanliness: 80,
    Need.affection: 60,
  });

  final Map<Need, double> _values;

  double operator [](Need need) => _values[need] ?? initial._values[need]!;

  /// How content this need is, 0..1 (hunger is inverted).
  double satisfaction(Need need) {
    final v = this[need] / max;
    return need.lowerIsBetter ? 1 - v : v;
  }

  /// Overall mood 0..1: the average satisfaction of every need.
  double get mood => Need.values.map(satisfaction).reduce((a, b) => a + b) / Need.values.length;

  DogNeeds apply(Map<Need, double> deltas) =>
      DogNeeds._({for (final need in Need.values) need: (this[need] + (deltas[need] ?? 0)).clamp(min, max).toDouble()});

  Map<String, double> toJson() => {for (final need in Need.values) need.name: this[need]};

  /// Reads saved needs; unknown keys are ignored and missing or broken ones
  /// fall back to [initial].
  factory DogNeeds.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return DogNeeds._({
      for (final need in Need.values)
        need: switch (map[need.name]) {
          final num v when v.isFinite => v.toDouble().clamp(min, max),
          _ => initial[need],
        },
    });
  }

  @override
  bool operator ==(Object other) => other is DogNeeds && Need.values.every((need) => other[need] == this[need]);

  @override
  int get hashCode => Object.hashAll(Need.values.map((need) => this[need]));

  @override
  String toString() => 'DogNeeds(${toJson()})';
}

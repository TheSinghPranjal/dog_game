import '../dogs/dog_needs.dart';
import '../dogs/dog_profile.dart';
import '../environments/environment_id.dart';
import '../progression/unlock_thresholds.dart';

/// Player settings.
class GameSettings {
  GameSettings({this.wander = true, this.sound = false});

  /// "Let your pup wander around".
  bool wander;

  /// Optional sound effects; off by default.
  bool sound;

  Map<String, Object?> toJson() => {'wander': wander, 'sound': sound};

  factory GameSettings.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return GameSettings(
      wander: map['wander'] is bool ? map['wander'] as bool : true,
      sound: map['sound'] is bool ? map['sound'] as bool : false,
    );
  }
}

/// Progress with one dog.
class DogSave {
  DogSave({this.needs = DogNeeds.initial, this.friendship = 0, Set<String>? completed}) : completed = completed ?? {};

  static const maxStars = 5.0;

  DogNeeds needs;

  /// Friendship in stars, 0..5; whole stars count toward unlocks.
  double friendship;

  /// Thing ids this dog has done at least once.
  final Set<String> completed;

  int get stars => friendship.floor();

  Map<String, Object?> toJson() => {
    'needs': needs.toJson(),
    'friendship': friendship,
    'completed': completed.toList()..sort(),
  };

  factory DogSave.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    final friendship = map['friendship'];
    return DogSave(
      needs: DogNeeds.fromJson(map['needs']),
      friendship: friendship is num && friendship.isFinite ? friendship.toDouble().clamp(0, maxStars) : 0,
      completed: _strings(map['completed']),
    );
  }
}

/// Everything the game remembers, stored as one JSON blob.
///
/// Parsing is forgiving: anything missing, unknown or of the wrong type
/// falls back to its default, so a damaged save never stops the game.
class GameSave {
  GameSave({
    this.selectedDog = DogId.maple,
    this.lastEnvironment = EnvironmentId.livingArea,
    GameSettings? settings,
    Map<DogId, DogSave>? dogs,
    Set<String>? stickers,
    Set<String>? unlocked,
    this.lastSeen,
    this.hideSeekCleared = 0,
  }) : settings = settings ?? GameSettings(),
       dogs = dogs ?? {},
       stickers = stickers ?? {},
       unlocked = unlocked ?? {};

  /// Bump when the JSON layout changes, and add a step to [migrate].
  static const schemaVersion = 1;

  DogId selectedDog;
  EnvironmentId lastEnvironment;
  final GameSettings settings;
  final Map<DogId, DogSave> dogs;

  /// Thing ids whose sticker is in the sticker book.
  final Set<String> stickers;

  /// Ids ("dog:luna", "env:park") whose unlock page has been shown.
  final Set<String> unlocked;

  /// When the game was last open, for the capped offline drift of needs.
  DateTime? lastSeen;

  /// Hide-and-seek stages cleared, in order; the next one is playable.
  int hideSeekCleared;

  DogSave dog(DogId id) => dogs.putIfAbsent(id, DogSave.new);

  int get totalStars => dogs.values.fold(0, (sum, c) => sum + c.stars);

  bool isDogUnlocked(DogId id) => UnlockThresholds.dog(id).isMet(totalStars);

  bool isEnvironmentUnlocked(EnvironmentId id) => UnlockThresholds.environment(id).isMet(totalStars);

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'selectedDog': selectedDog.name,
    'lastEnvironment': lastEnvironment.name,
    'settings': settings.toJson(),
    'dogs': {for (final MapEntry(:key, :value) in dogs.entries) key.name: value.toJson()},
    'stickers': stickers.toList()..sort(),
    'unlocked': unlocked.toList()..sort(),
    'lastSeen': lastSeen?.millisecondsSinceEpoch,
    'hideSeekCleared': hideSeekCleared,
  };

  factory GameSave.fromJson(Object? raw) {
    final json = migrate(raw is Map ? Map<String, Object?>.from(raw) : {});
    final dogs = <DogId, DogSave>{};
    if (json['dogs'] case final Map map) {
      for (final MapEntry(:key, :value) in map.entries) {
        final id = DogId.tryParse(key);
        if (id != null) dogs[id] = DogSave.fromJson(value);
      }
    }
    final lastSeen = json['lastSeen'];
    final cleared = json['hideSeekCleared'];
    return GameSave(
      selectedDog: _unlockedOrDefault(DogId.tryParse(json['selectedDog']), dogs),
      lastEnvironment: EnvironmentId.tryParse(json['lastEnvironment']) ?? EnvironmentId.livingArea,
      settings: GameSettings.fromJson(json['settings']),
      dogs: dogs,
      stickers: _strings(json['stickers']),
      unlocked: _strings(json['unlocked']),
      lastSeen: lastSeen is int ? DateTime.fromMillisecondsSinceEpoch(lastSeen) : null,
      hideSeekCleared: cleared is int && cleared > 0 ? cleared : 0,
    );
  }

  /// Upgrades older layouts step by step to [schemaVersion]. Saves from a
  /// newer app are read as-is, keeping whatever this version understands.
  static Map<String, Object?> migrate(Map<String, Object?> json) {
    var version = json['schemaVersion'] is int ? json['schemaVersion'] as int : 0;
    if (version < 1) {
      // v0: nothing was saved but the look; the 1.x key is migrated by the
      // store before parsing, so there is nothing to move here.
      version = 1;
    }
    return json..['schemaVersion'] = version;
  }

  /// A locked dog can never be the selected one.
  static DogId _unlockedOrDefault(DogId? id, Map<DogId, DogSave> dogs) {
    if (id == null) return DogId.maple;
    final stars = dogs.values.fold(0, (sum, c) => sum + c.stars);
    return UnlockThresholds.dog(id).isMet(stars) ? id : DogId.maple;
  }
}

Set<String> _strings(Object? json) => json is List ? json.whereType<String>().toSet() : <String>{};

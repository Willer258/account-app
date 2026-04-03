import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound feedback service for Revolut-style interactions.
///
/// Provides a framework for sound effects with user preference support.
/// In MVP, actual audio playback uses system sounds via HapticFeedback
/// (actual sound files would require audioplayers or similar package).
///
/// The service respects user preferences via [SoundPreferences].
///
/// Covers: US-009 — Haptic & Sound
class SoundService {
  SoundService._();

  static SoundService? _instance;

  static SoundService get instance {
    _instance ??= SoundService._();
    return _instance!;
  }

  bool _soundEnabled = true;

  /// Whether sound effects are enabled.
  bool get soundEnabled => _soundEnabled;

  /// Initialize — loads user preference from storage.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_kSoundEnabledKey) ?? true;
    } catch (e) {
      debugPrint('[SoundService] Failed to load preferences: $e');
    }
  }

  /// Toggle sound on/off and persist the preference.
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSoundEnabledKey, enabled);
    } catch (e) {
      debugPrint('[SoundService] Failed to save preference: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Sound Events
  //
  // In MVP: these log intent. With audioplayers, you'd call
  // AudioPlayer().play(AssetSource('sounds/xxx.mp3'))
  // ─────────────────────────────────────────────────────────────

  /// Plays the transaction saved sound (satisfying "ding").
  Future<void> playTransactionSaved() async {
    if (!_soundEnabled) return;
    _log('transaction_saved');
    // TODO(post-MVP): await _player.play(AssetSource('sounds/transaction_saved.mp3'));
  }

  /// Plays the key press sound (soft click).
  Future<void> playKeyPress() async {
    if (!_soundEnabled) return;
    _log('key_press');
  }

  /// Plays the success sound (upward chime).
  Future<void> playSuccess() async {
    if (!_soundEnabled) return;
    _log('success');
  }

  /// Plays the error sound (low buzz).
  Future<void> playError() async {
    if (!_soundEnabled) return;
    _log('error');
  }

  /// Plays the celebration sound (fanfare).
  Future<void> playCelebration() async {
    if (!_soundEnabled) return;
    _log('celebration');
  }

  /// Plays the budget warning sound (soft alert tone).
  Future<void> playBudgetWarning() async {
    if (!_soundEnabled) return;
    _log('budget_warning');
  }

  void _log(String event) {
    debugPrint('[SoundService] 🔊 $event');
  }

  static const _kSoundEnabledKey = 'revolut_sound_enabled';
}

/// User preferences for haptics and sound.
class SoundPreferences {
  const SoundPreferences({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.intensityLevel = HapticIntensity.medium,
  });

  final bool soundEnabled;
  final bool hapticsEnabled;
  final HapticIntensity intensityLevel;

  SoundPreferences copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    HapticIntensity? intensityLevel,
  }) {
    return SoundPreferences(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      intensityLevel: intensityLevel ?? this.intensityLevel,
    );
  }
}

enum HapticIntensity { off, light, medium, heavy }

extension HapticIntensityExt on HapticIntensity {
  String get label {
    switch (this) {
      case HapticIntensity.off:
        return 'Désactivé';
      case HapticIntensity.light:
        return 'Léger';
      case HapticIntensity.medium:
        return 'Moyen';
      case HapticIntensity.heavy:
        return 'Fort';
    }
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the short answer feedback sounds. Each effect is backed by a small
/// pool of low-latency players so the *same* effect can overlap itself —
/// rapid taps fire each on a free player and play to their full length
/// instead of cutting the previous one short.
///
/// Drop your files at `assets/sounds/correct.mp3` and `assets/sounds/wrong.mp3`
/// (mp3/wav/ogg all work — just match the filename below). If a file is
/// missing playback silently no-ops so the game keeps running.
class SoundService extends ChangeNotifier {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _correctAsset = 'sounds/notification.mp3';
  static const _wrongAsset = 'sounds/wrong.mp3';
  static const _tapAsset = 'sounds/bubble-pop.mp3';
  static const _letterAsset = 'sounds/click-letter.mp3';
  static const _backspaceAsset = 'sounds/click-backspace.mp3';
  static const _enterAsset = 'sounds/click-enter.mp3';

  /// Players each effect rotates through. Enough voices to cover rapid-fire
  /// taps without clipping; the oldest voice is reused once all are busy.
  static const _poolSize = 4;

  /// Tap is a subtle UI click, kept well below the correct/wrong cues.
  static const _tapVolume = 0.35;

  /// Correct cue is loud at source; dial it down to sit with the others.
  static const _correctVolume = 1.0;

  late final _SoundPool _correct = _SoundPool(
    _correctAsset,
    volume: _correctVolume,
  );
  late final _SoundPool _wrong = _SoundPool(_wrongAsset);
  late final _SoundPool _tap = _SoundPool(_tapAsset, volume: _tapVolume);
  late final _SoundPool _letter = _SoundPool(_letterAsset);
  late final _SoundPool _backspace = _SoundPool(_backspaceAsset);
  late final _SoundPool _enter = _SoundPool(_enterAsset);

  late final List<_SoundPool> _pools = [
    _correct,
    _wrong,
    _tap,
    _letter,
    _backspace,
    _enter,
  ];

  bool _muted = false;
  bool get muted => _muted;

  void toggleMute() {
    _muted = !_muted;
    notifyListeners();
  }

  void playCorrect() => _play(_correct);
  void playWrong() => _play(_wrong);

  /// Tap cue for buttons and cards (not quiz answer options).
  void playTap() => _play(_tap);

  /// Letter key press on the hard-mode keyboard.
  void playLetter() => _play(_letter);

  /// Backspace key press on the hard-mode keyboard.
  void playBackspace() => _play(_backspace);

  /// Submit (تأیید) key press on the hard-mode keyboard.
  void playEnter() => _play(_enter);

  void _play(_SoundPool pool) {
    if (muted) return;
    pool.play();
  }

  @override
  void dispose() {
    for (final pool in _pools) {
      pool.dispose();
    }
    super.dispose();
  }
}

/// Round-robin pool of low-latency players for one asset. Each [play] grabs
/// the next voice and starts it from the top without stopping the others, so
/// overlapping triggers don't trim each other.
class _SoundPool {
  _SoundPool(this._asset, {double? volume}) {
    for (var i = 0; i < SoundService._poolSize; i++) {
      final player = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      if (volume != null) player.setVolume(volume);
      _players.add(player);
    }
  }

  final String _asset;
  final List<AudioPlayer> _players = [];
  int _next = 0;

  void play() {
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    // Restart this voice from the top; ignore failures (e.g. asset not bundled).
    player.stop().then((_) => player.play(AssetSource(_asset))).catchError((e) {
      debugPrint('SoundService: failed to play $_asset — $e');
    });
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
  }
}

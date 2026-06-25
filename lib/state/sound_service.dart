import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the short answer feedback sounds. Each effect is backed by a small
/// pool of low-latency players so the *same* effect can overlap itself —
/// rapid taps fire each on a free player and play to their full length
/// instead of cutting the previous one short.
///
/// Assets live under `assets/sounds/` (see the `_*Asset` constants below;
/// mp3/wav/ogg all work — just match the filename). If a file is missing
/// playback silently no-ops so the game keeps running.
class SoundService extends ChangeNotifier {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _correctAsset = 'sounds/notification.mp3';
  static const _wrongAsset = 'sounds/wrong.mp3';
  static const _tapAsset = 'sounds/bubble-pop.mp3';
  static const _letterAsset = 'sounds/click-letter.mp3';
  static const _backspaceAsset = 'sounds/click-backspace.mp3';
  static const _enterAsset = 'sounds/click-enter.mp3';

  /// Tap is a subtle UI click, kept well below the correct/wrong cues.
  static const _tapVolume = 0.35;

  /// Correct cue is loud at source; dial it down to sit with the others.
  static const _correctVolume = 1.0;

  // Voice counts are sized per effect: only the fast-repeating typing cues need
  // overlap headroom. The answer/submit cues fire one at a time, so a single
  // voice is plenty. Players are created lazily on first play (see [_SoundPool])
  // so an unplayed effect costs no platform audio channel.
  late final _SoundPool _correct = _SoundPool(
    _correctAsset,
    voices: 1,
    volume: _correctVolume,
  );
  late final _SoundPool _wrong = _SoundPool(_wrongAsset, voices: 1);
  late final _SoundPool _tap = _SoundPool(_tapAsset, voices: 3, volume: _tapVolume);
  late final _SoundPool _letter = _SoundPool(_letterAsset, voices: 3);
  late final _SoundPool _backspace = _SoundPool(_backspaceAsset, voices: 2);
  late final _SoundPool _enter = _SoundPool(_enterAsset, voices: 1);

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

/// Round-robin pool of up to [_voices] low-latency players for one asset.
/// Players are created lazily — the first [play] grows the pool one voice at a
/// time up to the cap, so an effect that is never triggered holds no platform
/// audio channel. Each [play] grabs the next voice and starts it from the top
/// without stopping the others, so overlapping triggers don't trim each other.
class _SoundPool {
  _SoundPool(this._asset, {required int voices, double? volume})
      : _voices = voices,
        _volume = volume;

  final String _asset;
  final int _voices;
  final double? _volume;
  final List<AudioPlayer> _players = [];
  int _next = 0;

  void play() {
    // Grow toward the voice cap on demand; once full, reuse round-robin.
    final AudioPlayer player;
    if (_players.length < _voices) {
      player = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      if (_volume != null) player.setVolume(_volume);
      _players.add(player);
      _next = _players.length % _voices;
    } else {
      player = _players[_next];
      _next = (_next + 1) % _voices;
    }
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

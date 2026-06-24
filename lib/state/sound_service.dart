import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the short answer feedback sounds. One dedicated low-latency player
/// per effect so a correct/wrong cue can fire instantly and overlap a tail.
///
/// Drop your files at `assets/sounds/correct.mp3` and `assets/sounds/wrong.mp3`
/// (mp3/wav/ogg all work — just match the filename below). If a file is
/// missing playback silently no-ops so the game keeps running.
class SoundService extends ChangeNotifier {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _correctAsset = 'sounds/correct.mp3';
  static const _wrongAsset = 'sounds/wrong.mp3';

  final AudioPlayer _correct = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  final AudioPlayer _wrong = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);

  bool _muted = false;
  bool get muted => _muted;

  void toggleMute() {
    _muted = !_muted;
    notifyListeners();
  }

  void playCorrect() => _play(_correct, _correctAsset);
  void playWrong() => _play(_wrong, _wrongAsset);

  void _play(AudioPlayer player, String asset) {
    if (muted) return;
    // Restart from the top each tap; ignore failures (e.g. asset not bundled).
    player.stop().then((_) => player.play(AssetSource(asset))).catchError((e) {
      debugPrint('SoundService: failed to play $asset — $e');
    });
  }

  @override
  void dispose() {
    _correct.dispose();
    _wrong.dispose();
    super.dispose();
  }
}

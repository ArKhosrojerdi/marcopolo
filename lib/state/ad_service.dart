import 'package:adivery/adivery.dart';
import 'package:flutter/foundation.dart';

/// Owns the Adivery interstitial lifecycle: SDK init, preload, cooldown-gated
/// show, and reload-after-close. Singleton, mirroring [SoundService] so the
/// game logic can fire an ad with one call and stay free of the ad SDK.
///
/// Wiring: call [initialize] once at app start (before runApp). The quiz calls
/// [onWrongAnswer] on every wrong answer; the cooldown decides whether an ad
/// actually shows, so the call site stays dumb.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _appId = '59c36ce3-7125-40a7-bd34-144e6906c796';
  static const _interstitialPlacement = 'd3d19c2a-142c-4551-92f1-1d2c38aea3ec';

  /// Minimum gap between two interstitials. Picked to avoid hammering the
  /// player (and to stay within Adivery/store frequency expectations).
  static const _cooldown = Duration(seconds: 90);

  /// Set once [initialize] has run. Guards every call so a missing/blocked SDK
  /// silently no-ops instead of throwing into the game loop.
  bool _ready = false;

  /// Timestamp of the last shown ad. Null until the first show.
  DateTime? _lastShown;

  /// Init the SDK and preload the first interstitial. Safe to call once.
  Future<void> initialize() async {
    try {
      // TODO(adivery): verify signature against the installed package version.
      await Adivery.initialize(_appId);
      _ready = true;
      _preload();
    } catch (e) {
      debugPrint('AdService: init failed — $e');
    }
  }

  /// Fired on every wrong answer. Shows an interstitial only if the SDK is
  /// ready, an ad is loaded, and the cooldown has elapsed. Otherwise no-ops
  /// (and makes sure another ad is preloading for next time).
  void onWrongAnswer() {
    if (!_ready) return;
    if (!_cooldownElapsed) return;
    _showIfLoaded();
  }

  bool get _cooldownElapsed {
    final last = _lastShown;
    return last == null || DateTime.now().difference(last) >= _cooldown;
  }

  Future<void> _showIfLoaded() async {
    try {
      // TODO(adivery): verify isLoaded/showAd names against the package.
      final loaded = await Adivery.isLoaded(_interstitialPlacement);
      if (loaded != true) {
        _preload(); // not ready yet — warm it up for the next wrong answer
        return;
      }
      _lastShown = DateTime.now();
      Adivery.showAd(_interstitialPlacement);
      // Preload the next one so the following eligible wrong answer has an ad.
      _preload();
    } catch (e) {
      debugPrint('AdService: show failed — $e');
    }
  }

  void _preload() {
    try {
      // TODO(adivery): verify prepareInterstitialAd name against the package.
      Adivery.prepareInterstitialAd(_interstitialPlacement);
    } catch (e) {
      debugPrint('AdService: preload failed — $e');
    }
  }
}

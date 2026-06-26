import 'package:flutter/foundation.dart';

import 'package:adivery/adivery.dart';

/// Thin wrapper over the Adivery interstitial ad. Keeps SDK calls out of the
/// game logic and UI: one ad is kept loaded in the background and shown on
/// demand; after it closes (or fails) the next one is preloaded.
///
/// Adivery exposes a single global listener keyed by placement id rather than
/// a per-ad object, so all wiring lives here in one place.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // static const String _appId = 'ec109c5a-aa80-4c2d-b384-6f13dc5cd59d';
  // static const String _interstitialPlacement =
  //     'bd94eebe-60b1-4365-81ad-ca0cf0a82f8a';
  static const String _appId = '59c36ce3-7125-40a7-bd34-144e6906c796';
  static const String _interstitialPlacement =
      'd3d19c2a-142c-4551-92f1-1d2c38aea3ec';

  /// Configure the SDK, register listeners, and warm the first interstitial.
  /// Call once at startup.
  void init() {
    AdiveryPlugin.initialize(_appId);
    AdiveryPlugin.setLoggingEnabled(kDebugMode);
    AdiveryPlugin.addListener(
      onInterstitialLoaded: (p) =>
          debugPrint('Adivery: interstitial loaded ($p)'),
      // Preload the next interstitial once the current one is gone or failed.
      onInterstitialClosed: _reloadInterstitial,
      onError: (placement, reason) {
        debugPrint('Adivery error ($placement): $reason');
        _reloadInterstitial(placement);
      },
    );
    AdiveryPlugin.prepareInterstitialAd(_interstitialPlacement);
  }

  void _reloadInterstitial(String placement) {
    if (placement == _interstitialPlacement) {
      AdiveryPlugin.prepareInterstitialAd(_interstitialPlacement);
    }
  }

  /// Show the interstitial if one is loaded. No-op otherwise so gameplay is
  /// never blocked waiting on an ad.
  Future<void> showInterstitial() async {
    final loaded = await AdiveryPlugin.isLoaded(_interstitialPlacement);
    debugPrint('Adivery: showInterstitial requested, loaded=$loaded');
    if (loaded == true) AdiveryPlugin.show(_interstitialPlacement);
  }
}

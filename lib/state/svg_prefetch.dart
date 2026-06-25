import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Warms flutter_svg's picture cache for an asset off the render path.
///
/// [SvgPicture.asset] decodes + parses the SVG on first mount, which shows a
/// placeholder spinner for a frame. Calling [warm] when the question is chosen
/// (before the widget builds) primes `svg.cache` with the *same* cache key the
/// widget uses, so the picture is ready by the time it mounts — no flash.
///
/// Fire-and-forget and idempotent: `loadBytes` is a `putIfAbsent`, so a warm
/// that loses the race to the widget simply no-ops. A null context resolves to
/// `rootBundle`, so this works from the controller with no `BuildContext`.
class SvgPrefetch {
  SvgPrefetch._();

  static void warm(String assetPath) {
    // Fire-and-forget; swallow failures (e.g. asset not bundled) so a missing
    // file never crashes the game — the widget falls back to its placeholder.
    unawaited(
      SvgAssetLoader(assetPath).loadBytes(null).then(
        (_) {},
        onError: (Object e) =>
            debugPrint('SvgPrefetch: failed to warm $assetPath — $e'),
      ),
    );
  }
}

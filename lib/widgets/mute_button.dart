import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'press_sink.dart';

/// Circular mute/unmute toggle — same sticker look & size as [BackStickerButton],
/// press behavior owned by [PressSink]. Icon only: speaker-on when sound is
/// active, speaker-off when muted.
class MuteStickerButton extends StatelessWidget {
  const MuteStickerButton({super.key, required this.muted, required this.onTap});
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      onTap: onTap,
      shape: BoxShape.circle,
      borderWidth: 1.8,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: Icon(
        muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        size: 22,
        color: AppColors.ink,
      ),
    );
  }
}

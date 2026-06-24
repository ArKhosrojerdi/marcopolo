import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker_card.dart';

/// Stub for the map mode until a border-outline SVG source is added.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('نقشه کشور', style: AppTheme.handSize(34)),
                  const SizedBox(height: 8),
                  Text(
                    'به‌زودی',
                    style: AppTheme.handSize(26, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'این حالت نیاز به تصاویرِ مرز کشورها دارد که هنوز اضافه نشده‌اند.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.sans,
                      fontSize: 12,
                      height: 1.7,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  StickerCard(
                    onTap: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 11,
                    ),
                    radius: 24,
                    child: const Text(
                      '‹ بازگشت',
                      style: TextStyle(fontFamily: AppTheme.sans, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

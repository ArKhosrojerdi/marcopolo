import 'package:flutter/material.dart';

/// Colors + text styles extracted from the wireframe
/// (Country Quiz Wireframes.dc.html). Paper / hand-drawn "doodle" look.
class AppColors {
  static const paper = Color(0xFFFFFDF7);
  static const ink = Color(0xFF2B2B2B);
  static const muted = Color(0xFF7A6F58);
  static const faint = Color(0xFF9A8F78);
  static const highlight = Color(0xFFFFFBE9);
  static const postit = Color(0xFFFEF4A8);
  static const postitBorder = Color(0xFFE0B400);
  static const card = Colors.white;

  static const correct = Color(0xFF2F7D4F);
  static const correctBg = Color(0xFFEEF7EF);
  static const wrong = Color(0xFFC0392B);
  static const wrongBg = Color(0xFFF9ECEA);
  static const dimBorder = Color(0xFFCABFA8);
  static const dimText = Color(0xFFA99F88);

  static const dashed = Color(0xFFC7BCA3);
}

class AppTheme {
  static const sans = 'Vazirmatn';
  static const hand = 'Lalezar';

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: sans,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.correct,
        surface: AppColors.paper,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
        fontFamily: sans,
      ),
    );
  }

  /// The signature "sticker" decoration: dark border + hard offset shadow.
  static BoxDecoration sticker({
    Color background = AppColors.card,
    Color border = AppColors.ink,
    double borderWidth = 1.6,
    double radius = 4,
    Color? shadow,
    double shadowOffset = 3.2,
  }) {
    return BoxDecoration(
      color: background,
      border: Border.all(color: border, width: borderWidth),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadow ?? border,
          offset: Offset(0, shadowOffset),
          blurRadius: 0,
        ),
      ],
    );
  }

  static const handStyle = TextStyle(fontFamily: hand, color: AppColors.ink);
  static TextStyle handSize(double size, {Color? color}) => TextStyle(
    fontFamily: hand,
    fontSize: size,
    color: color ?? AppColors.ink,
  );
}

/// Convert Latin digits in a string to Persian digits (for streak/record display).
String toPersianDigits(Object value) {
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return value.toString().split('').map((ch) {
    final code = ch.codeUnitAt(0);
    if (code >= 0x30 && code <= 0x39) return fa[code - 0x30];
    return ch;
  }).join();
}

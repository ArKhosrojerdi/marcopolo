import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom Persian keyboard for hard mode. No native keyboard involved.
/// Fires [onChar], [onBackspace], [onSubmit] callbacks.
class HardKeyboard extends StatelessWidget {
  const HardKeyboard({
    super.key,
    required this.onChar,
    required this.onBackspace,
    required this.onSubmit,
    required this.onSkip,
    this.submitEnabled = false,
    this.disabled = false,
  });

  final ValueChanged<String> onChar;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;
  final bool submitEnabled;
  final bool disabled;

  static const _rows = [
    ['چ', 'ج', 'ح', 'خ', 'ه', 'ع', 'غ', 'ف', 'ق', 'ث', 'ص', 'ض'],
    ['گ', 'ک', 'م', 'ن', 'ت', 'ا', 'ل', 'ب', 'ی', 'س', 'ش'],
    ['ؤ', 'ئ', 'آ', 'پ', 'ژ', 'و', 'د', 'ذ', 'ر', 'ز', 'ط', 'ظ'],
  ];

  static const _maxKeys = 12;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyWidth =
              (constraints.maxWidth - _gap * (_maxKeys - 1)) / _maxKeys;
          return _buildContent(keyWidth);
        },
      ),
    );
  }

  Widget _buildContent(double keyWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows) ...[
          _KeyRow(
            keys: row,
            keyWidth: keyWidth,
            maxKeys: _maxKeys,
            onTap: disabled ? null : onChar,
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: _ActionKey(
                label: '⌫',
                onTap: disabled ? null : onBackspace,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _ActionKey(
                label: 'تأیید',
                onTap: (disabled || !submitEnabled) ? null : onSubmit,
                highlight: submitEnabled && !disabled,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ActionKey(
                label: 'بعدی',
                onTap: disabled ? null : onSkip,
                error: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.keyWidth,
    required this.maxKeys,
    this.onTap,
  });
  final List<String> keys;
  final double keyWidth;
  final int maxKeys;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final missing = maxKeys - keys.length;
    final halfMissing = missing / 2;
    return Row(
      children: [
        // left phantom space
        SizedBox(width: halfMissing * (keyWidth + _gap)),
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          SizedBox(
            width: keyWidth,
            child: _CharKey(char: keys[i], onTap: onTap),
          ),
        ],
        // right phantom space
        SizedBox(width: halfMissing * (keyWidth + _gap)),
      ],
    );
  }
}

const _gap = 4.0;

class _CharKey extends StatefulWidget {
  const _CharKey({required this.char, this.onTap});
  final String char;
  final ValueChanged<String>? onTap;

  @override
  State<_CharKey> createState() => _CharKeyState();
}

class _CharKeyState extends State<_CharKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!(widget.char);
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 80),
        offset: _pressed && enabled ? const Offset(0, 0.04) : Offset.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.ink.withValues(alpha: 0.08)
                : AppColors.card,
            border: Border.all(
              color: enabled ? AppColors.ink : AppColors.dimBorder,
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _pressed || !enabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.ink,
                      offset: const Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Text(
            widget.char,
            style: TextStyle(
              fontFamily: AppTheme.sans,
              fontSize: 14,
              color: enabled ? AppColors.ink : AppColors.dimText,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatefulWidget {
  const _ActionKey({
    required this.label,
    this.onTap,
    this.highlight = false,
    this.error = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool highlight;
  final bool error;

  @override
  State<_ActionKey> createState() => _ActionKeyState();
}

class _ActionKeyState extends State<_ActionKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final accent = widget.error ? AppColors.wrong : AppColors.ink;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 80),
        offset: _pressed && enabled ? const Offset(0, 0.04) : Offset.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.highlight
                ? (AppColors.ink.withValues(alpha: _pressed ? 0.85 : 1.0))
                : (_pressed ? accent.withValues(alpha: 0.08) : AppColors.card),
            border: Border.all(
              color: enabled ? accent : AppColors.dimBorder,
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _pressed || !enabled
                ? null
                : [
                    BoxShadow(
                      color: accent,
                      offset: const Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppTheme.sans,
              fontSize: 15,
              color: widget.highlight
                  ? Colors.white
                  : (enabled ? accent : AppColors.dimText),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

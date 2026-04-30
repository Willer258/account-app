import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/pockii_colors.dart';
import '../utils/fcfa_formatter.dart';

/// A tappable amount display that opens a keypad bottom sheet.
///
/// Replaces inline TextFields for money input — no overflow, no keyboard issues.
/// Usage:
/// ```dart
/// MoneyInputField(
///   value: 150000,
///   onChanged: (amount) => setState(() => _amount = amount),
///   label: 'Montant',
/// )
/// ```
class MoneyInputField extends StatelessWidget {
  const MoneyInputField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.accentColor,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String? label;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.revolutBlue;
    final hasValue = value > 0;

    return GestureDetector(
      onTap: () => _openKeypad(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.pockii.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  label!,
                  style: AppTypography.revolutMicro.copyWith(
                    color: context.pockii.onSurfaceMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hasValue
                          ? FcfaFormatter.formatCompact(value)
                          : 'Appuyer pour saisir',
                      style: AppTypography.revolutSubtitle.copyWith(
                        color: hasValue
                            ? context.pockii.onSurface
                            : context.pockii.onSurfaceMuted,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  FcfaFormatter.symbol,
                  style: AppTypography.revolutBody.copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openKeypad(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.pockii.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MoneyKeypadSheet(
        initialValue: value,
        label: label,
        accentColor: accentColor,
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}

/// Bottom sheet with amount display + numeric keypad.
class _MoneyKeypadSheet extends StatefulWidget {
  const _MoneyKeypadSheet({
    required this.initialValue,
    this.label,
    this.accentColor,
  });

  final int initialValue;
  final String? label;
  final Color? accentColor;

  @override
  State<_MoneyKeypadSheet> createState() => _MoneyKeypadSheetState();
}

class _MoneyKeypadSheetState extends State<_MoneyKeypadSheet> {
  late int _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialValue;
  }

  void _appendDigit(int digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amount == 0) {
        _amount = digit;
      } else if (_amount.toString().length < 9) {
        _amount = _amount * 10 + digit;
      }
    });
  }

  void _appendZeros(int count) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amount == 0) return;
      final newStr = '$_amount${'0' * count}';
      if (newStr.length <= 9) {
        _amount = int.parse(newStr);
      }
    });
  }

  void _deleteDigit() {
    HapticFeedback.selectionClick();
    setState(() {
      _amount = _amount ~/ 10;
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_amount);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? AppColors.revolutBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),

        // Label
        if (widget.label != null)
          Text(
            widget.label!,
            style: AppTypography.revolutBody.copyWith(
              color: context.pockii.onSurfaceMuted,
              fontSize: 14,
            ),
          ),

        const SizedBox(height: 16),

        // Amount display
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _amount > 0
                      ? FcfaFormatter.formatCompact(_amount)
                      : '0',
                  style: AppTypography.revolutDisplay.copyWith(
                    color: _amount > 0
                        ? context.pockii.onSurface
                        : context.pockii.onSurfaceMuted,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  FcfaFormatter.symbol,
                  style: AppTypography.revolutSubtitle.copyWith(
                    color: color,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Keypad
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildRow([1, 2, 3]),
              _buildRow([4, 5, 6]),
              _buildRow([7, 8, 9]),
              Row(
                children: [
                  _buildSpecialKey('000', onTap: () => _appendZeros(3)),
                  _buildDigitKey(0),
                  _buildIconKey(
                    Icons.backspace_outlined,
                    onTap: _deleteDigit,
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _amount = 0);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Confirm button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Confirmer',
                style: AppTypography.revolutLabel.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<int> digits) {
    return Row(children: digits.map(_buildDigitKey).toList());
  }

  Widget _buildDigitKey(int digit) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _appendDigit(digit),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Text(
            digit.toString(),
            style: AppTypography.revolutSubtitle.copyWith(
              color: context.pockii.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(String label, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.revolutLabel.copyWith(
              color: context.pockii.onSurfaceMuted,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconKey(
    IconData icon, {
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: context.pockii.onSurfaceMuted,
            size: 24,
          ),
        ),
      ),
    );
  }
}

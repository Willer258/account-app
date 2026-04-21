import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';

/// Bottom sheet for editing the monthly budget amount.
///
/// Displays a large amount with numeric keypad in a Revolut-style dark sheet.
/// Returns the new amount if confirmed, null if cancelled.
class BudgetEditDialog extends StatefulWidget {
  const BudgetEditDialog({
    required this.currentBudget,
    super.key,
  });

  /// Current budget amount to pre-fill.
  final int currentBudget;

  /// Shows the bottom sheet and returns the new budget amount.
  static Future<int?> show(BuildContext context, int currentBudget) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.revolutSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BudgetEditDialog(currentBudget: currentBudget),
    );
  }

  @override
  State<BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends State<BudgetEditDialog> {
  late int _amount;
  bool _hasEdited = false;

  @override
  void initState() {
    super.initState();
    _amount = widget.currentBudget;
  }

  void _appendDigit(int digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_hasEdited) {
        _amount = digit;
        _hasEdited = true;
      } else if (_amount.toString().length < 9) {
        _amount = _amount * 10 + digit;
      }
    });
  }

  void _appendZeros(int count) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_hasEdited) return;
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
      _hasEdited = true;
    });
  }

  void _confirm() {
    if (_amount <= 0) return;
    Navigator.of(context).pop(_amount);
  }

  @override
  Widget build(BuildContext context) {
    final diff = _amount - widget.currentBudget;
    final hasDiff = _hasEdited && diff != 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const SizedBox(height: 20),

          // Title
          Text(
            'Budget mensuel',
            style: AppTypography.revolutSubtitle.copyWith(
              color: AppColors.revolutOnDark,
            ),
          ),
          const SizedBox(height: 4),
          if (_amount != widget.currentBudget && _hasEdited)
            Text(
              'Actuel: ${FcfaFormatter.format(widget.currentBudget)}',
              style: AppTypography.revolutMicro.copyWith(
                color: AppColors.revolutOnDarkMuted,
                fontSize: 12,
              ),
            ),

          const SizedBox(height: 24),

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
                    FcfaFormatter.formatCompact(_amount),
                    style: AppTypography.revolutDisplay.copyWith(
                      color: _amount > 0
                          ? AppColors.revolutOnDark
                          : AppColors.revolutOnDarkMuted,
                      fontSize: 52,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    FcfaFormatter.symbol,
                    style: AppTypography.revolutSubtitle.copyWith(
                      color: AppColors.revolutOnDarkMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Diff indicator
          const SizedBox(height: 8),
          if (hasDiff)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: diff > 0
                    ? AppColors.revolutGreen.withValues(alpha: 0.12)
                    : AppColors.revolutRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${diff > 0 ? '+' : ''}${FcfaFormatter.format(diff)}',
                style: AppTypography.revolutLabel.copyWith(
                  color: diff > 0
                      ? AppColors.revolutGreen
                      : AppColors.revolutRed,
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Info note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.revolutOnDarkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Appliqué au mois en cours',
                  style: AppTypography.revolutMicro.copyWith(
                    color: AppColors.revolutOnDarkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Numeric keypad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildRow([1, 2, 3]),
                _buildRow([4, 5, 6]),
                _buildRow([7, 8, 9]),
                Row(
                  children: [
                    _buildSpecialKey(
                      '000',
                      onTap: () => _appendZeros(3),
                    ),
                    _buildDigitKey(0),
                    _buildIconKey(
                      Icons.backspace_outlined,
                      onTap: _deleteDigit,
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _amount = 0;
                          _hasEdited = true;
                        });
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
                onPressed: _amount > 0 ? _confirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.revolutBlue,
                  disabledBackgroundColor: AppColors.revolutBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Enregistrer',
                  style: AppTypography.revolutLabel.copyWith(
                    color: AppColors.revolutOnDark,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<int> digits) {
    return Row(
      children: digits.map(_buildDigitKey).toList(),
    );
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
              color: AppColors.revolutOnDark,
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
              color: AppColors.revolutOnDarkMuted,
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
            color: AppColors.revolutOnDarkMuted,
            size: 24,
          ),
        ),
      ),
    );
  }
}

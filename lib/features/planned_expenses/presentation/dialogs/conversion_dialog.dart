import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/planned_expense_model.dart';

/// Result of the conversion dialog.
class ConversionDialogResult {
  const ConversionDialogResult({
    required this.confirmed,
    required this.adjustedAmount,
  });

  final bool confirmed;
  final int adjustedAmount;
}

/// Bottom sheet for confirming planned expense payment with amount adjustment.
class ConversionDialog extends StatefulWidget {
  const ConversionDialog({
    required this.expense,
    super.key,
  });

  final PlannedExpenseModel expense;

  /// Shows the conversion bottom sheet and returns the result.
  static Future<ConversionDialogResult?> show(
    BuildContext context,
    PlannedExpenseModel expense,
  ) {
    return showModalBottomSheet<ConversionDialogResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.revolutSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConversionDialog(expense: expense),
    );
  }

  @override
  State<ConversionDialog> createState() => _ConversionDialogState();
}

class _ConversionDialogState extends State<ConversionDialog> {
  late int _adjustedAmount;
  bool _isAdjusting = false;

  @override
  void initState() {
    super.initState();
    _adjustedAmount = widget.expense.amountFcfa;
  }

  void _appendDigit(int digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_adjustedAmount.toString().length < 9) {
        _adjustedAmount = _adjustedAmount * 10 + digit;
      }
    });
  }

  void _appendZeros(int count) {
    HapticFeedback.selectionClick();
    setState(() {
      final newStr = '$_adjustedAmount${'0' * count}';
      if (newStr.length <= 9) {
        _adjustedAmount = int.parse(newStr);
      }
    });
  }

  void _deleteDigit() {
    HapticFeedback.selectionClick();
    setState(() {
      _adjustedAmount = _adjustedAmount ~/ 10;
    });
  }

  void _toggleAdjusting() {
    setState(() {
      _isAdjusting = !_isAdjusting;
      if (_isAdjusting) {
        _adjustedAmount = 0;
      } else {
        _adjustedAmount = widget.expense.amountFcfa;
      }
    });
  }

  void _confirm() {
    if (_adjustedAmount <= 0) return;
    Navigator.of(context).pop(
      ConversionDialogResult(confirmed: true, adjustedAmount: _adjustedAmount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diff = _adjustedAmount - widget.expense.amountFcfa;
    final hasDiff = diff != 0 && _isAdjusting;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),

          // Title
          Text(
            'Valider le paiement',
            style: AppTypography.revolutSubtitle.copyWith(
              color: AppColors.revolutOnDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.expense.description,
            style: AppTypography.revolutBody.copyWith(
              color: AppColors.revolutOnDarkMuted,
              fontSize: 14,
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
                    FcfaFormatter.formatCompact(_adjustedAmount),
                    style: AppTypography.revolutDisplay.copyWith(
                      color: _adjustedAmount > 0
                          ? AppColors.revolutOnDark
                          : AppColors.revolutOnDarkMuted,
                      fontSize: 44,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'FCFA',
                    style: AppTypography.revolutSubtitle.copyWith(
                      color: AppColors.revolutOnDarkMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Diff badge or adjust button
          if (hasDiff)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: diff > 0
                    ? AppColors.revolutRed.withValues(alpha: 0.12)
                    : AppColors.revolutGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Prévu: ${FcfaFormatter.format(widget.expense.amountFcfa)} (${diff > 0 ? '+' : ''}${FcfaFormatter.format(diff)})',
                style: AppTypography.revolutMicro.copyWith(
                  color: diff > 0
                      ? AppColors.revolutRed
                      : AppColors.revolutGreen,
                  fontSize: 12,
                ),
              ),
            )
          else if (!_isAdjusting)
            GestureDetector(
              onTap: _toggleAdjusting,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    color: AppColors.revolutBlue,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ajuster le montant',
                    style: AppTypography.revolutLabel.copyWith(
                      color: AppColors.revolutBlue,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Keypad (only when adjusting)
          if (_isAdjusting) ...[
            const SizedBox(height: 20),
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
                          setState(() => _adjustedAmount = 0);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _toggleAdjusting,
              child: Text(
                'Montant prévu',
                style: AppTypography.revolutLabel.copyWith(
                  color: AppColors.revolutOnDarkMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _adjustedAmount > 0 ? _confirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.revolutGreen,
                  disabledBackgroundColor: AppColors.revolutBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Confirmer le paiement',
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
    return Row(children: digits.map(_buildDigitKey).toList());
  }

  Widget _buildDigitKey(int digit) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _appendDigit(digit),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Text(
            digit.toString(),
            style: AppTypography.revolutSubtitle.copyWith(
              color: AppColors.revolutOnDark,
              fontSize: 22,
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
          height: 52,
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.revolutLabel.copyWith(
              color: AppColors.revolutOnDarkMuted,
              fontSize: 16,
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
          height: 52,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.revolutOnDarkMuted, size: 22),
        ),
      ),
    );
  }
}

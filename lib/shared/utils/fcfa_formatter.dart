import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/currency_preference.dart';

/// Utility class for formatting and parsing FCFA (Franc CFA) amounts.
///
/// CRITICAL ARCHITECTURE RULE: All monetary values in this app are
/// stored and handled as integers. NEVER use double for money.
///
/// The FCFA has no decimal subdivisions (unlike EUR cents or USD cents),
/// so integer representation is both accurate and appropriate.
class FcfaFormatter {
  FcfaFormatter._();

  /// Current currency symbol — updated by the provider.
  static String _symbol = 'FCFA';

  /// Update the currency symbol from the provider.
  static void setSymbol(String symbol) {
    _symbol = symbol;
  }

  /// Formats an integer amount with the currency suffix.
  ///
  /// Examples:
  /// - format(350000) => "350 000 FCFA" (or "350 000 XOF" etc.)
  static String format(int amountFcfa) {
    final isNegative = amountFcfa < 0;
    final absAmount = amountFcfa.abs();

    final formatted = _formatNumber(absAmount);
    final prefix = isNegative ? '-' : '';
    return '$prefix$formatted $_symbol';
  }

  /// Formats without the currency suffix.
  ///
  /// Examples:
  /// - formatCompact(350000) => "350 000"
  static String formatCompact(int amountFcfa) {
    final isNegative = amountFcfa < 0;
    final absAmount = amountFcfa.abs();

    final formatted = _formatNumber(absAmount);
    return isNegative ? '-$formatted' : formatted;
  }

  /// Returns just the current currency symbol.
  static String get symbol => _symbol;

  /// Parses a string to extract the amount as an integer.
  static int parse(String input) {
    if (input.isEmpty) return 0;

    final isNegative = input.trimLeft().startsWith('-');
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return 0;

    final value = int.tryParse(digits) ?? 0;
    return isNegative ? -value : value;
  }

  /// Validates that the input string represents a valid amount.
  static bool isValid(String input) {
    if (input.isEmpty) return false;
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    return digits.isNotEmpty && int.tryParse(digits) != null;
  }

  /// Formats amount with sign indicator.
  static String formatWithSign(int amountFcfa) {
    if (amountFcfa == 0) return format(0);
    final prefix = amountFcfa > 0 ? '+' : '';
    return '$prefix${format(amountFcfa)}';
  }

  static String _formatNumber(int absAmount) {
    return absAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }
}

/// Widget-level provider that syncs the currency symbol to the formatter.
/// Watch this in PockiiApp to keep the static symbol in sync.
final currencySymbolSyncProvider = Provider<String>((ref) {
  final format = ref.watch(currencyFormatProvider);
  FcfaFormatter.setSymbol(format.symbol);
  return format.symbol;
});

import 'package:flutter/services.dart';

/// TextInputFormatter that formats numbers with space separators.
///
/// Input: "150000" → Display: "150 000"
/// The underlying value (for onChanged) contains the formatted string,
/// use [parse] to extract the raw integer.
class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digits
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format with spaces
    final formatted = _formatWithSpaces(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Formats a digit string with space separators.
  static String _formatWithSpaces(String digits) {
    return digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  /// Parse a formatted string back to int.
  static int parse(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }
}

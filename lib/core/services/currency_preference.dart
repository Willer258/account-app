import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Currency display formats available.
enum CurrencyFormat {
  /// "350 000 FCFA"
  fcfa('FCFA'),

  /// "350 000 XOF"
  xof('XOF'),

  /// "350 000 F"
  f('F'),

  /// "350 000 CFA"
  cfa('CFA');

  const CurrencyFormat(this.symbol);

  final String symbol;
}

/// Notifier for currency display preference.
class CurrencyFormatNotifier extends StateNotifier<CurrencyFormat> {
  CurrencyFormatNotifier() : super(CurrencyFormat.fcfa) {
    _load();
  }

  static const _key = 'currency_format';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = CurrencyFormat.values.firstWhere(
        (e) => e.name == value,
        orElse: () => CurrencyFormat.fcfa,
      );
    }
  }

  Future<void> setFormat(CurrencyFormat format) async {
    state = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, format.name);
  }
}

/// Provider for currency display format.
final currencyFormatProvider =
    StateNotifierProvider<CurrencyFormatNotifier, CurrencyFormat>((ref) {
  return CurrencyFormatNotifier();
});

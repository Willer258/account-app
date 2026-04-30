import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../providers/onboarding_provider.dart';
import '../../../../shared/utils/money_input_formatter.dart';

/// The budget setup page (screen 3) of onboarding.
///
/// Allows user to enter their monthly budget amount in FCFA.
class BudgetSetupPage extends ConsumerStatefulWidget {
  const BudgetSetupPage({super.key});

  @override
  ConsumerState<BudgetSetupPage> createState() => _BudgetSetupPageState();
}

class _BudgetSetupPageState extends ConsumerState<BudgetSetupPage> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    // Remove all non-digit characters
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanValue.isEmpty) {
      ref.read(onboardingStateProvider.notifier).setBudgetAmount(0);
      return;
    }

    final amount = int.tryParse(cleanValue) ?? 0;
    ref.read(onboardingStateProvider.notifier).setBudgetAmount(amount);

    // Format with spaces and update controller using FcfaFormatter
    final formatted = FcfaFormatter.formatCompact(amount);
    if (_controller.text != formatted) {
      final cursorPosition = formatted.length;
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: cursorPosition),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingStateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            'Ton budget mensuel',
            style: AppTypography.headline.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            'Combien peux-tu dépenser ce mois-ci ?',
            style: AppTypography.body.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Amount input
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTypography.hero.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 40,
            ),
            inputFormatters: [
              MoneyInputFormatter(),
              LengthLimitingTextInputFormatter(12), // Max 999 999 999 999
            ],
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: AppTypography.hero.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 40,
              ),
              suffixText: FcfaFormatter.symbol,
              suffixStyle: AppTypography.title.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorText: state.hasError ? state.error : null,
            ),
            onChanged: _onAmountChanged,
          ),
          const SizedBox(height: AppSpacing.md),

          // Helper text
          Text(
            'Tu pourras modifier ce montant plus tard',
            style: AppTypography.caption.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/subscription_repository.dart';
import '../../domain/models/subscription_frequency.dart';
import '../../domain/models/subscription_model.dart';
import '../providers/subscription_form_provider.dart';
import '../widgets/subscription_category_row.dart';

/// Screen for adding or editing a subscription.
///
/// Provides a form with name, amount, category, frequency, and due day fields.
/// In edit mode, allows deactivating the subscription.
class SubscriptionFormScreen extends ConsumerStatefulWidget {
  /// Creates a SubscriptionFormScreen.
  ///
  /// If [subscription] is provided, the form opens in edit mode.
  const SubscriptionFormScreen({
    this.subscription,
    super.key,
  });

  /// The subscription to edit, or null for creating a new one.
  final SubscriptionModel? subscription;

  /// Whether this screen is in edit mode.
  bool get isEditMode => subscription != null;

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState
    extends ConsumerState<SubscriptionFormScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // In edit mode, initialize the form with existing data
    if (widget.isEditMode) {
      final sub = widget.subscription!;
      _nameController.text = sub.name;
      _amountController.text = sub.amountFcfa > 0 ? sub.amountFcfa.toString() : '';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final formNotifier = ref.read(subscriptionFormProvider.notifier);
        formNotifier.initializeForEdit(sub);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final formState = ref.read(subscriptionFormProvider);

    // Mark as interacted to show validation errors
    ref.read(subscriptionFormProvider.notifier).markInteracted();

    if (!formState.isValid) {
      // Focus on name field if name is empty
      if (formState.name.trim().isEmpty) {
        _nameFocusNode.requestFocus();
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final category = formState.category ?? 'other';

      if (widget.isEditMode) {
        // Update existing subscription
        final updated = widget.subscription!.copyWith(
          name: formState.name.trim(),
          amountFcfa: formState.amountFcfa,
          category: category,
          frequency: formState.frequency,
          dueDay: formState.dueDay,
          isActive: formState.isActive,
          updatedAt: DateTime.now(),
        );
        await repository.updateSubscription(updated);
      } else {
        // Create new subscription
        await repository.createSubscription(
          name: formState.name.trim(),
          amountFcfa: formState.amountFcfa,
          category: category,
          frequency: formState.frequency,
          dueDay: formState.dueDay,
        );
      }

      // Haptic feedback on success
      await HapticFeedback.mediumImpact();

      // Navigate back
      if (mounted) {
        Navigator.of(context).pop(true); // true indicates success

        // Show success snackbar
        final message = widget.isEditMode
            ? 'Abonnement modifié'
            : 'Abonnement ajouté';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.revolutRed,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(subscriptionFormProvider);
    final formNotifier = ref.read(subscriptionFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode
            ? 'Modifier l\'abonnement'
            : 'Nouvel abonnement'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Name field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'abonnement',
                    hintText: 'Ex: Netflix, Tontine famille...',
                    border: const OutlineInputBorder(),
                    errorText: formState.showNameError ? 'Nom requis' : null,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onChanged: formNotifier.setName,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Amount input with system keyboard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Montant',
                    hintText: '0',
                    suffixText: 'FCFA',
                    border: const OutlineInputBorder(),
                    errorText: formState.showAmountError ? 'Montant requis' : null,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    final amount = int.tryParse(value) ?? 0;
                    formNotifier.setAmount(amount);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Category selection
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Text(
                  'Catégorie',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.revolutOnDarkMuted,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SubscriptionCategoryRow(
                selectedCategory: formState.category,
                onCategorySelected: formNotifier.setCategory,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Frequency selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fréquence',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.revolutOnDarkMuted,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<SubscriptionFrequency>(
                      segments: SubscriptionFrequency.values.map((freq) {
                        return ButtonSegment(
                          value: freq,
                          label: Text(freq.displayName),
                        );
                      }).toList(),
                      selected: {formState.frequency},
                      onSelectionChanged: (selected) {
                        HapticFeedback.selectionClick();
                        formNotifier.setFrequency(selected.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Due day selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDueDayLabel(formState.frequency),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.revolutOnDarkMuted,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: formState.dueDay.toDouble(),
                            min: 1,
                            max: formState.maxDueDay.toDouble(),
                            divisions: formState.maxDueDay - 1,
                            label: _formatDueDay(
                              formState.dueDay,
                              formState.frequency,
                            ),
                            onChanged: (value) {
                              formNotifier.setDueDay(value.round());
                            },
                          ),
                        ),
                        Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            _formatDueDay(
                              formState.dueDay,
                              formState.frequency,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active toggle (only in edit mode)
              if (widget.isEditMode) ...[
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SwitchListTile(
                    title: const Text('Actif'),
                    subtitle: Text(
                      formState.isActive
                          ? 'Cet abonnement est pris en compte dans le budget'
                          : 'Cet abonnement est désactivé',
                    ),
                    value: formState.isActive,
                    onChanged: formNotifier.setIsActive,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Submit button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: FilledButton(
                  onPressed: formState.isValid && !_isSubmitting
                      ? _handleSubmit
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
                    backgroundColor: AppColors.revolutBlue,
                    disabledBackgroundColor: AppColors.revolutBorder,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Text(
                          widget.isEditMode ? 'Modifier' : 'Ajouter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  String _getDueDayLabel(SubscriptionFrequency frequency) {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return 'Jour de la semaine';
      case SubscriptionFrequency.monthly:
      case SubscriptionFrequency.quarterly:
      case SubscriptionFrequency.biannual:
      case SubscriptionFrequency.yearly:
        return 'Jour du mois';
    }
  }

  String _formatDueDay(int day, SubscriptionFrequency frequency) {
    if (frequency == SubscriptionFrequency.weekly) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[day - 1];
    }
    return '$day';
  }
}

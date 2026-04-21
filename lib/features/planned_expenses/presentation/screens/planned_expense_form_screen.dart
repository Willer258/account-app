import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/planned_expense_model.dart';
import '../providers/planned_expense_form_provider.dart';

/// Bottom sheet for adding or editing a planned expense.
class PlannedExpenseFormScreen extends ConsumerStatefulWidget {
  const PlannedExpenseFormScreen({
    this.expense,
    super.key,
  });

  final PlannedExpenseModel? expense;

  @override
  ConsumerState<PlannedExpenseFormScreen> createState() =>
      _PlannedExpenseFormScreenState();
}

class _PlannedExpenseFormScreenState
    extends ConsumerState<PlannedExpenseFormScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(plannedExpenseFormProvider.notifier);
      if (widget.expense != null) {
        notifier.initForEdit(widget.expense!);
        _descriptionController.text = widget.expense!.description;
        if (widget.expense!.amountFcfa > 0) {
          _amountController.text = widget.expense!.amountFcfa.toString();
        }
      } else {
        final clock = ref.read(clockProvider);
        final tomorrow = clock.now().add(const Duration(days: 1));
        notifier.initForCreate(defaultDate: tomorrow);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(plannedExpenseFormProvider);
    final isEditing = widget.expense != null;
    final dateFormat = DateFormat('EEE d MMM yyyy', 'fr_FR');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // Title
            Text(
              isEditing ? 'Modifier la dépense' : 'Planifier une dépense',
              style: AppTypography.revolutSubtitle.copyWith(
                color: AppColors.revolutOnDark,
              ),
            ),
            const SizedBox(height: 20),

            // Description
            TextField(
              controller: _descriptionController,
              onChanged: (value) {
                ref
                    .read(plannedExpenseFormProvider.notifier)
                    .setDescription(value);
              },
              style: TextStyle(color: AppColors.revolutOnDark),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: AppColors.revolutOnDarkMuted),
                hintText: 'Ex: Nouveau téléphone',
                hintStyle: TextStyle(color: AppColors.revolutOnDarkMuted),
                filled: true,
                fillColor: AppColors.revolutSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: TextStyle(
                  color: AppColors.revolutOnDarkMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: AppColors.revolutOnDark,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final amount = int.tryParse(value) ?? 0;
                ref
                    .read(plannedExpenseFormProvider.notifier)
                    .setAmount(amount);
              },
              decoration: InputDecoration(
                labelText: 'Montant',
                labelStyle: TextStyle(color: AppColors.revolutOnDarkMuted),
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.revolutOnDarkMuted),
                suffixText: 'FCFA',
                suffixStyle: TextStyle(
                  color: AppColors.revolutOnDarkMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.revolutSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date picker
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.revolutSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.revolutBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date prévue',
                            style: AppTypography.revolutMicro.copyWith(
                              color: AppColors.revolutOnDarkMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formState.expectedDate != null
                                ? dateFormat.format(formState.expectedDate!)
                                : 'Choisir une date',
                            style: AppTypography.revolutBody.copyWith(
                              color: formState.expectedDate != null
                                  ? AppColors.revolutOnDark
                                  : AppColors.revolutOnDarkMuted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (formState.expectedDate != null) ...[
                      _DaysBadge(expectedDate: formState.expectedDate!),
                    ],
                  ],
                ),
              ),
            ),

            // Error
            if (formState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                formState.errorMessage!,
                style: AppTypography.revolutMicro.copyWith(
                  color: AppColors.revolutRed,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: formState.isValid && !formState.isSaving
                    ? _onSubmit
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.revolutBlue,
                  disabledBackgroundColor: AppColors.revolutBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: formState.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.revolutOnDark,
                        ),
                      )
                    : Text(
                        isEditing ? 'Modifier' : 'Planifier',
                        style: AppTypography.revolutLabel.copyWith(
                          color: AppColors.revolutOnDark,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final clock = ref.read(clockProvider);
    final now = clock.now();
    final formState = ref.read(plannedExpenseFormProvider);

    final picked = await showDatePicker(
      context: context,
      initialDate: formState.expectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      ref.read(plannedExpenseFormProvider.notifier).setExpectedDate(picked);
    }
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();

    final clock = ref.read(clockProvider);
    final success = await ref
        .read(plannedExpenseFormProvider.notifier)
        .save(clock.now());

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

/// Small badge showing days until due.
class _DaysBadge extends ConsumerWidget {
  const _DaysBadge({required this.expectedDate});

  final DateTime expectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(clockProvider);
    final now = clock.now();
    final days = expectedDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    final isUrgent = days <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.revolutAmber.withValues(alpha: 0.12)
            : AppColors.revolutBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        days == 0
            ? 'Aujourd\'hui'
            : days == 1
                ? 'Demain'
                : 'Dans $days j',
        style: AppTypography.revolutLabel.copyWith(
          color: isUrgent ? AppColors.revolutAmber : AppColors.revolutBlue,
          fontSize: 11,
        ),
      ),
    );
  }
}

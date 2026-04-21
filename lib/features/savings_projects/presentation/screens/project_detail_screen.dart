import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../data/savings_project_repository.dart';
import '../../domain/models/project_contribution_model.dart';
import '../../domain/models/savings_project_model.dart';
import '../providers/savings_projects_provider.dart';

/// Screen displaying details of a savings project.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    final contributionsAsync = ref.watch(projectContributionsProvider(projectId));

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Projet')),
            body: const Center(child: Text('Projet non trouvé')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero header
              _ProjectHeader(project: project),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress section
                      _ProgressSection(project: project),
                      const SizedBox(height: AppSpacing.lg),

                      // Quick actions
                      _QuickActions(
                        project: project,
                        onDeposit: () => _showDepositDialog(context, ref, project),
                        onWithdraw: () => _showWithdrawDialog(context, ref, project),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Auto-contribution info
                      if (project.autoContributionEnabled)
                        _AutoContributionCard(project: project),
                      if (project.autoContributionEnabled)
                        const SizedBox(height: AppSpacing.lg),

                      // Contributions history
                      Text(
                        'Historique',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.revolutOnDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),

              // Contributions list
              contributionsAsync.when(
                data: (contributions) {
                  if (contributions.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.revolutSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 32,
                                color: AppColors.revolutOnDarkMuted,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Aucune cotisation',
                                style: TextStyle(
                                  color: AppColors.revolutOnDarkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ContributionTile(
                          contribution: contributions[index],
                          color: project.color,
                        ),
                        childCount: contributions.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: Center(child: Text('Erreur de chargement')),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(child: Text('Erreur: $error')),
      ),
    );
  }

  void _showDepositDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsProjectModel project,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContributionBottomSheet(
        project: project,
        isDeposit: true,
        onConfirm: (amount, note) async {
          final repository = ref.read(savingsProjectRepositoryProvider);
          await repository.addDeposit(
            projectId: project.id,
            amountFcfa: amount,
            note: note,
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${FcfaFormatter.formatCompact(amount)} ajoutés!'),
                backgroundColor: AppColors.revolutGreen,
              ),
            );
          }
        },
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsProjectModel project,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContributionBottomSheet(
        project: project,
        isDeposit: false,
        onConfirm: (amount, note) async {
          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmer le retrait'),
              content: Text(
                'Tu es sur le point de retirer ${FcfaFormatter.format(amount)} de ton projet "${project.name}".\n\nCette action est irréversible.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.revolutRed,
                  ),
                  child: const Text('Retirer'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            final repository = ref.read(savingsProjectRepositoryProvider);
            await repository.withdraw(
              projectId: project.id,
              amountFcfa: amount,
              note: note,
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${FcfaFormatter.formatCompact(amount)} retirés'),
                  backgroundColor: AppColors.revolutRed,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

/// Hero header with project info.
class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final SavingsProjectModel project;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: project.color,
      foregroundColor: project.textOnColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.push('/projects/${project.id}/edit'),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive),
                  SizedBox(width: 8),
                  Text('Archiver'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                project.color,
                project.color.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  project.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  project.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: project.textOnColor,
                  ),
                ),
                Text(
                  project.category.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: project.textOnColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    // TODO: Implement archive and delete actions
  }
}

/// Progress section with race track style.
class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.project});

  final SavingsProjectModel project;

  @override
  Widget build(BuildContext context) {
    final progress = project.progress.clamp(0.0, 1.0);
    final isGoalReached = project.isGoalReached;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: project.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: project.borderColor),
      ),
      child: Column(
        children: [
          // Compact amounts row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FcfaFormatter.formatCompact(project.currentAmountFcfa),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: project.color,
                    ),
                  ),
                  Text(
                    'épargné',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                ],
              ),
              // Percentage badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isGoalReached
                      ? AppColors.revolutGreen
                      : project.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isGoalReached ? '🎉 Atteint!' : '${project.progressPercentage}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isGoalReached ? Colors.white : project.color,
                  ),
                ),
              ),
              // Target amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FcfaFormatter.formatCompact(project.targetAmountFcfa),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'objectif',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Race track progress
          SizedBox(
            height: 40,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final runnerPosition = trackWidth * progress;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Track background
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 16,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.revolutBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Track progress
                    Positioned(
                      left: 0,
                      top: 16,
                      child: Container(
                        width: runnerPosition,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isGoalReached ? AppColors.revolutGreen : project.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Start flag
                    const Positioned(
                      left: 0,
                      top: 0,
                      child: Icon(Icons.flag_rounded, size: 16, color: AppColors.revolutBlue),
                    ),
                    // Finish flag
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(Icons.flag_circle_rounded, size: 16, color: AppColors.revolutGreen),
                    ),
                    // Runner (flipped to face right)
                    Positioned(
                      left: (runnerPosition - 12).clamp(0, trackWidth - 24),
                      top: 0,
                      child: Transform.flip(
                        flipX: true,
                        child: Text(
                          isGoalReached ? '🏆' : '🏃',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Remaining info
          if (!isGoalReached) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Plus que ${FcfaFormatter.formatCompact(project.remainingAmountFcfa)} !',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.revolutOnDarkMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick action buttons.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.project,
    required this.onDeposit,
    required this.onWithdraw,
  });

  final SavingsProjectModel project;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onDeposit,
            icon: const Icon(Icons.add),
            label: const Text('Cotiser'),
            style: FilledButton.styleFrom(
              backgroundColor: project.color,
              foregroundColor: project.textOnColor,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: project.currentAmountFcfa > 0 ? onWithdraw : null,
            icon: const Icon(Icons.remove),
            label: const Text('Retirer'),
          ),
        ),
      ],
    );
  }
}

/// Auto-contribution info card.
class _AutoContributionCard extends StatelessWidget {
  const _AutoContributionCard({required this.project});

  final SavingsProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.revolutBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: project.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.autorenew,
              color: project.color,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cotisation automatique',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.revolutOnDark,
                  ),
                ),
                Text(
                  '${FcfaFormatter.formatCompact(project.autoContributionAmountFcfa)} / ${project.autoContributionFrequency?.displayName.toLowerCase() ?? 'mois'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.revolutOnDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (project.nextContributionDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Prochain',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.revolutOnDarkMuted,
                  ),
                ),
                Text(
                  _formatShortDate(project.nextContributionDate!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: project.color,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

/// Single contribution tile.
class _ContributionTile extends StatelessWidget {
  const _ContributionTile({
    required this.contribution,
    required this.color,
  });

  final ProjectContributionModel contribution;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDeposit = contribution.isDeposit;
    final isFailed = contribution.isFailed;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isFailed
                  ? AppColors.revolutRed.withValues(alpha: 0.1)
                  : isDeposit
                      ? AppColors.revolutGreen.withValues(alpha: 0.1)
                      : AppColors.revolutRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isFailed
                  ? Icons.warning
                  : isDeposit
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
              size: 16,
              color: isFailed
                  ? AppColors.revolutRed
                  : isDeposit
                      ? AppColors.revolutGreen
                      : AppColors.revolutRed,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contribution.type.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.revolutOnDark,
                  ),
                ),
                if (contribution.note != null)
                  Text(
                    contribution.note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.revolutOnDarkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Amount and date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isFailed)
                Text(
                  '${isDeposit ? '+' : '-'}${FcfaFormatter.formatCompact(contribution.absoluteAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDeposit ? AppColors.revolutGreen : AppColors.revolutRed,
                  ),
                ),
              Text(
                _formatDate(contribution.date),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.revolutOnDarkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Bottom sheet for adding contributions.
class _ContributionBottomSheet extends StatefulWidget {
  const _ContributionBottomSheet({
    required this.project,
    required this.isDeposit,
    required this.onConfirm,
  });

  final SavingsProjectModel project;
  final bool isDeposit;
  final Future<void> Function(int amount, String? note) onConfirm;

  @override
  State<_ContributionBottomSheet> createState() => _ContributionBottomSheetState();
}

class _ContributionBottomSheetState extends State<_ContributionBottomSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.project.color;
    final maxWithdraw = widget.project.currentAmountFcfa;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.project.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isDeposit ? 'Cotiser' : 'Retirer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.revolutOnDark,
                          ),
                        ),
                        Text(
                          widget.project.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.revolutOnDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount field
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Montant',
                  suffixText: 'FCFA',
                  helperText: widget.isDeposit
                      ? null
                      : 'Maximum: ${FcfaFormatter.format(maxWithdraw)}',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),

              // Note field
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optionnel)',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.isDeposit ? color : AppColors.revolutRed,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isDeposit ? 'Cotiser' : 'Retirer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }

    if (!widget.isDeposit && amount > widget.project.currentAmountFcfa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant supérieur au solde')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final note = _noteController.text.trim();
      await widget.onConfirm(amount, note.isEmpty ? null : note);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../data/savings_project_repository.dart';
import '../../domain/enums/contribution_frequency.dart';
import '../../domain/enums/project_category.dart';
import '../../domain/models/savings_project_model.dart';
import '../widgets/project_color_picker.dart';
import '../../../../shared/utils/money_input_formatter.dart';

/// Screen for creating or editing a savings project.
class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({
    super.key,
    this.projectToEdit,
  });

  /// If provided, the screen is in edit mode.
  final SavingsProjectModel? projectToEdit;

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _autoAmountController = TextEditingController();

  late ProjectCategory _selectedCategory;
  late String _selectedEmoji;
  late Color _selectedColor;
  DateTime? _targetDate;
  bool _autoContributionEnabled = false;
  ContributionFrequency _autoFrequency = ContributionFrequency.monthly;

  bool _isLoading = false;
  bool get _isEditMode => widget.projectToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final project = widget.projectToEdit!;
      _nameController.text = project.name;
      _targetAmountController.text = project.targetAmountFcfa.toString();
      _selectedCategory = project.category;
      _selectedEmoji = project.emoji;
      _selectedColor = project.color;
      _targetDate = project.targetDate;
      _autoContributionEnabled = project.autoContributionEnabled;
      _autoFrequency = project.autoContributionFrequency ?? ContributionFrequency.monthly;
      if (project.autoContributionAmountFcfa > 0) {
        _autoAmountController.text = project.autoContributionAmountFcfa.toString();
      }
    } else {
      _selectedCategory = ProjectCategory.other;
      _selectedEmoji = _selectedCategory.defaultEmoji;
      _selectedColor = _selectedCategory.defaultColor;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _autoAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier le projet' : 'Nouveau projet'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Category selection
            _buildCategorySection(),
            const SizedBox(height: AppSpacing.lg),

            // Project name
            _buildNameField(),
            const SizedBox(height: AppSpacing.lg),

            // Target amount
            _buildAmountField(),
            const SizedBox(height: AppSpacing.lg),

            // Emoji selection
            _buildEmojiSection(),
            const SizedBox(height: AppSpacing.lg),

            // Color picker
            ProjectColorPicker(
              selectedColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Target date (optional)
            _buildTargetDateSection(),
            const SizedBox(height: AppSpacing.lg),

            // Auto-contribution
            _buildAutoContributionSection(),
            const SizedBox(height: AppSpacing.xl),

            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _saveProject,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditMode ? 'Enregistrer' : 'Créer le projet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.revolutOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: ProjectCategory.allCategories.map((category) {
            final isSelected = category == _selectedCategory;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.defaultEmoji),
                  const SizedBox(width: 4),
                  Text(
                    category.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.revolutOnDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: AppColors.revolutBlue,
              backgroundColor: AppColors.revolutSurface,
              side: BorderSide(
                color: isSelected
                    ? AppColors.revolutBlue
                    : AppColors.revolutBorder,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                    // Update emoji and color if not customized
                    if (_selectedEmoji == _selectedCategory.defaultEmoji ||
                        _selectedEmoji == category.defaultEmoji) {
                      _selectedEmoji = category.defaultEmoji;
                    }
                    if (!_isEditMode) {
                      _selectedColor = category.defaultColor;
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nom du projet',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.revolutOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Ex: Voyage à Dubaï',
            prefixIcon: Container(
              width: 48,
              alignment: Alignment.center,
              child: Text(
                _selectedEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom est requis';
            }
            if (value.length > 100) {
              return 'Le nom est trop long (max 100 caractères)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectif',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.revolutOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _targetAmountController,
          decoration: InputDecoration(
            hintText: 'Montant en ${FcfaFormatter.symbol}',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [MoneyInputFormatter()],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le montant est requis';
            }
            final amount = MoneyInputFormatter.parse(value);
            if (amount <= 0) {
              return 'Montant invalide';
            }
            if (amount < 1000) {
              return 'Minimum 1 000 FCFA';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmojiSection() {
    const emojis = ['🎯', '🏖️', '📱', '🎁', '🚗', '🏠', '🎓', '💍', '✈️', '💻', '🎮', '👗', '💎', '🎸', '📸', '🌴'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icône',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.revolutOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: emojis.map((emoji) {
            final isSelected = emoji == _selectedEmoji;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEmoji = emoji;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _selectedColor.withValues(alpha: 0.2)
                      : AppColors.revolutSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? _selectedColor
                        : AppColors.revolutBorder.withValues(alpha: 0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTargetDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Date cible (optionnel)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.revolutOnDark,
              ),
            ),
            if (_targetDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _targetDate = null;
                  });
                },
                child: const Text('Effacer'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: _selectTargetDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
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
                Icon(
                  Icons.calendar_today,
                  color: _targetDate != null
                      ? _selectedColor
                      : AppColors.revolutOnDarkMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _targetDate != null
                      ? _formatDate(_targetDate!)
                      : 'Choisir une date',
                  style: TextStyle(
                    color: _targetDate != null
                        ? AppColors.revolutOnDark
                        : AppColors.revolutOnDarkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoContributionSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _autoContributionEnabled
              ? _selectedColor.withValues(alpha: 0.5)
              : AppColors.revolutBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
          Row(
            children: [
              Icon(
                Icons.autorenew,
                color: _autoContributionEnabled
                    ? _selectedColor
                    : AppColors.revolutOnDarkMuted,
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
                      'Prélèvement régulier sur ton budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.revolutOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoContributionEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoContributionEnabled = value;
                  });
                },
              ),
            ],
          ),

          // Auto-contribution settings
          if (_autoContributionEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Amount
            TextFormField(
              controller: _autoAmountController,
              decoration: InputDecoration(
                labelText: 'Montant en ${FcfaFormatter.symbol}',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [MoneyInputFormatter()],
              validator: (value) {
                if (_autoContributionEnabled) {
                  if (value == null || value.isEmpty) {
                    return 'Le montant est requis';
                  }
                  final amount = MoneyInputFormatter.parse(value);
                  if (amount <= 0) {
                    return 'Montant invalide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Frequency
            Text(
              'Fréquence',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.revolutOnDarkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: ContributionFrequency.allFrequencies.map((freq) {
                final isSelected = freq == _autoFrequency;
                return ChoiceChip(
                  label: Text(
                    freq.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.revolutOnDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.revolutBlue,
                  backgroundColor: AppColors.revolutSurface,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.revolutBlue
                        : AppColors.revolutBorder,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _autoFrequency = freq;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectTargetDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (selected != null) {
      setState(() {
        _targetDate = selected;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(savingsProjectRepositoryProvider);
      final targetAmount = int.parse(_targetAmountController.text);
      final autoAmount = _autoContributionEnabled
          ? int.parse(_autoAmountController.text)
          : 0;

      if (_isEditMode) {
        final updatedProject = widget.projectToEdit!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          targetAmountFcfa: targetAmount,
          emoji: _selectedEmoji,
          color: _selectedColor,
          targetDate: _targetDate,
          autoContributionEnabled: _autoContributionEnabled,
          autoContributionAmountFcfa: autoAmount,
          autoContributionFrequency: _autoContributionEnabled ? _autoFrequency : null,
        );
        await repository.updateProject(updatedProject);
      } else {
        await repository.createProject(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          targetAmountFcfa: targetAmount,
          emoji: _selectedEmoji,
          color: _selectedColor,
          targetDate: _targetDate,
          autoContributionEnabled: _autoContributionEnabled,
          autoContributionAmountFcfa: autoAmount,
          autoContributionFrequency: _autoContributionEnabled ? _autoFrequency : null,
        );
      }

      if (mounted) {
        context.pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.revolutRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

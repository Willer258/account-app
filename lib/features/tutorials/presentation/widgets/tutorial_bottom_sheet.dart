import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../tutorial_content.dart';

/// Bottom sheet widget for displaying feature tutorials.
class TutorialBottomSheet extends StatefulWidget {
  const TutorialBottomSheet({
    required this.tutorial,
    super.key,
  });

  final FeatureTutorial tutorial;

  /// Show the tutorial bottom sheet.
  static Future<void> show(BuildContext context, FeatureTutorial tutorial) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TutorialBottomSheet(tutorial: tutorial),
    );
  }

  @override
  State<TutorialBottomSheet> createState() => _TutorialBottomSheetState();
}

class _TutorialBottomSheetState extends State<TutorialBottomSheet> {
  int _currentSection = 0;

  @override
  Widget build(BuildContext context) {
    final section = widget.tutorial.sections[_currentSection];
    final isFirst = _currentSection == 0;
    final isLast = _currentSection == widget.tutorial.sections.length - 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.revolutDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      widget.tutorial.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tutorial.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Guide d\'utilisation',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.revolutOnDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.tutorial.sections.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentSection ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentSection
                          ? AppColors.revolutBlue
                          : AppColors.revolutBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.revolutSurface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          section.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.revolutBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Section content with markdown-like formatting
                      _FormattedContent(content: section.content),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.revolutSurface,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.revolutBorder,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (!isFirst)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _currentSection--);
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Précédent'),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          if (isLast) {
                            Navigator.pop(context);
                          } else {
                            setState(() => _currentSection++);
                          }
                        },
                        icon: Icon(
                          isLast ? Icons.check : Icons.arrow_forward,
                          size: 18,
                        ),
                        label: Text(isLast ? 'Compris!' : 'Suivant'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget to format tutorial content with basic markdown-like styling.
class _FormattedContent extends StatelessWidget {
  const _FormattedContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final lines = content.trim().split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check for bullet points
      if (line.trim().startsWith('•') || line.trim().startsWith('-') || line.trim().startsWith('✅')) {
        widgets.add(_buildBulletPoint(line.trim()));
      } else {
        widgets.add(_buildParagraph(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              text.startsWith('✅') ? '✅' : '•',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.revolutBlue,
              ),
            ),
          ),
          Expanded(
            child: _buildStyledText(
              text.replaceFirst(RegExp(r'^[•\-✅]\s*'), ''),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _buildStyledText(text),
    );
  }

  Widget _buildStyledText(String text) {
    // Simple bold text support with **text**
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');

    var lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(fontSize: 14, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(fontSize: 14, height: 1.5),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AppColors.revolutOnDark,
          fontSize: 14,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}

/// Help button widget that shows a tutorial.
class TutorialHelpButton extends StatelessWidget {
  const TutorialHelpButton({
    required this.tutorial,
    this.size = 20,
    super.key,
  });

  final FeatureTutorial tutorial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => TutorialBottomSheet.show(context, tutorial),
      icon: Icon(
        Icons.help_outline,
        size: size,
        color: AppColors.revolutBlue,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: size + 8,
        minHeight: size + 8,
      ),
      tooltip: 'Comment ça marche?',
    );
  }
}

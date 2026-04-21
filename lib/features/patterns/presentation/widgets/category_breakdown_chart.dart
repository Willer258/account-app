import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/services/pattern_analysis_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Colors for category segments in the chart.
const List<Color> _categoryColors = [
  Color(0xFF2196F3), // Blue
  Color(0xFF4CAF50), // Green
  Color(0xFFFF9800), // Orange
  Color(0xFF9C27B0), // Purple
  Color(0xFFE91E63), // Pink
  Color(0xFF00BCD4), // Cyan
  Color(0xFFFF5722), // Deep Orange
  Color(0xFF795548), // Brown
];

/// A donut chart showing category spending breakdown.
///
/// Displays spending distribution by category with:
/// - Animated donut chart
/// - Category legend with amounts and percentages
/// - Tap interaction for category details
///
/// Covers: FR19, UX-9
class CategoryBreakdownChart extends StatefulWidget {
  /// Creates a CategoryBreakdownChart.
  const CategoryBreakdownChart({
    required this.categories,
    required this.onCategoryTap,
    super.key,
  });

  /// List of category spending data.
  final List<CategorySpending> categories;

  /// Callback when a category is tapped.
  final ValueChanged<String> onCategoryTap;

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorForIndex(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return _EmptyState();
    }

    return Column(
      children: [
        // Donut chart
        SizedBox(
          height: 200,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return GestureDetector(
                onTapUp: (details) => _handleChartTap(details, context),
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _DonutChartPainter(
                    categories: widget.categories,
                    animationValue: _animation.value,
                    selectedIndex: _selectedIndex,
                    getColor: _getColorForIndex,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Legend
        _CategoryLegend(
          categories: widget.categories,
          getColor: _getColorForIndex,
          selectedIndex: _selectedIndex,
          onCategoryTap: (index) {
            setState(() {
              _selectedIndex = _selectedIndex == index ? null : index;
            });
            widget.onCategoryTap(widget.categories[index].categoryId);
          },
        ),
      ],
    );
  }

  void _handleChartTap(TapUpDetails details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final center = Offset(box.size.width / 2, 100);
    final tapPosition = details.localPosition;
    final distance = (tapPosition - center).distance;

    // Check if tap is within the donut (between inner and outer radius)
    const outerRadius = 90.0;
    const innerRadius = 55.0;

    if (distance < innerRadius || distance > outerRadius) return;

    // Calculate angle
    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    var angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2) % (2 * math.pi); // Adjust to start from top

    // Find which segment was tapped
    var currentAngle = 0.0;
    for (var i = 0; i < widget.categories.length; i++) {
      final sweepAngle = widget.categories[i].percentage * 2 * math.pi;
      if (angle >= currentAngle && angle < currentAngle + sweepAngle) {
        setState(() {
          _selectedIndex = _selectedIndex == i ? null : i;
        });
        widget.onCategoryTap(widget.categories[i].categoryId);
        return;
      }
      currentAngle += sweepAngle;
    }
  }
}

/// Custom painter for the donut chart.
class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.categories,
    required this.animationValue,
    required this.selectedIndex,
    required this.getColor,
  });

  final List<CategorySpending> categories;
  final double animationValue;
  final int? selectedIndex;
  final Color Function(int) getColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const outerRadius = 90.0;
    const innerRadius = 55.0;

    // Draw segments
    var startAngle = -math.pi / 2; // Start from top

    for (var i = 0; i < categories.length; i++) {
      final sweepAngle = categories[i].percentage * 2 * math.pi * animationValue;
      final isSelected = selectedIndex == i;
      final radius = isSelected ? outerRadius + 5 : outerRadius;

      final paint = Paint()
        ..color = getColor(i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius;

      final rect = Rect.fromCircle(
        center: center,
        radius: (radius + innerRadius) / 2,
      );

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Draw center circle (creates donut hole)
    final centerPaint = Paint()
      ..color = AppColors.revolutDark
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius - 2, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.categories != categories;
  }
}

/// Legend showing category names, amounts, and percentages.
class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.categories,
    required this.getColor,
    required this.selectedIndex,
    required this.onCategoryTap,
  });

  final List<CategorySpending> categories;
  final Color Function(int) getColor;
  final int? selectedIndex;
  final ValueChanged<int> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        categories.length,
        (index) => _LegendItem(
          category: categories[index],
          color: getColor(index),
          isSelected: selectedIndex == index,
          onTap: () => onCategoryTap(index),
        ),
      ),
    );
  }
}

/// Individual legend item.
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.category,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final CategorySpending category;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withOpacity( 0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Icon
              Icon(
                category.categoryIcon,
                size: 20,
                color: AppColors.revolutOnDarkMuted,
              ),

              const SizedBox(width: AppSpacing.sm),

              // Category name
              Expanded(
                child: Text(
                  category.categoryLabel,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.revolutOnDark,
                  ),
                ),
              ),

              // Amount
              Text(
                _formatAmount(category.totalAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.revolutOnDark,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Percentage
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity( 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(category.percentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$amount';
  }
}

/// Empty state when no spending data exists.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: AppColors.revolutOnDarkMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pas encore de dépenses',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.revolutOnDarkMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ajoute des dépenses pour voir la répartition par catégorie',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.revolutOnDarkMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

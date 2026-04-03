import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../budget_rules/domain/enums/expense_category.dart';
import '../../../transactions/domain/models/transaction_model.dart';

/// Donut chart for spending by category using CustomPaint.
class SpendingDonutChart extends StatefulWidget {
  const SpendingDonutChart({
    super.key,
    required this.categoryTotals,
    required this.total,
  });

  final Map<ExpenseCategory, int> categoryTotals;
  final int total;

  @override
  State<SpendingDonutChart> createState() => _SpendingDonutChartState();
}

class _SpendingDonutChartState extends State<SpendingDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForCategory(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.needs:
        return AppColors.revolutBlue;
      case ExpenseCategory.wants:
        return AppColors.revolutAmber;
      case ExpenseCategory.savings:
        return AppColors.revolutGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Donut chart
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) => CustomPaint(
            size: const Size(200, 200),
            painter: _DonutPainter(
              categoryTotals: widget.categoryTotals,
              total: widget.total,
              progress: _animation.value,
              colorForCategory: _colorForCategory,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.categoryTotals.entries.where((e) => e.value > 0).map(
            (entry) {
              final pct = widget.total > 0
                  ? (entry.value / widget.total * 100).round()
                  : 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colorForCategory(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key.displayName} $pct%',
                    style: AppTypography.revolutMicro.copyWith(
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                ],
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.categoryTotals,
    required this.total,
    required this.progress,
    required this.colorForCategory,
  });

  final Map<ExpenseCategory, int> categoryTotals;
  final int total;
  final double progress;
  final Color Function(ExpenseCategory) colorForCategory;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 36.0;
    final innerRadius = radius - strokeWidth;

    // Draw track
    final trackPaint = Paint()
      ..color = AppColors.revolutBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    // Draw segments
    double startAngle = -math.pi / 2;

    for (final entry in categoryTotals.entries) {
      if (entry.value <= 0) continue;
      final sweep = (entry.value / total) * 2 * math.pi * progress;

      final paint = Paint()
        ..color = colorForCategory(entry.key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep - 0.04, // Small gap between segments
        false,
        paint,
      );

      startAngle += sweep;
    }

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: FcfaFormatter.formatCompact(total),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.revolutOnDark,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height),
    );

    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'FCFA',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.revolutOnDarkMuted,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(canvas, center - Offset(subPainter.width / 2, -4));
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.total != total;
}

// ─────────────────────────────────────────────────────────────
// Daily Spending Bar Chart
// ─────────────────────────────────────────────────────────────

/// Bar chart for daily spending using CustomPaint.
class DailySpendingChart extends StatefulWidget {
  const DailySpendingChart({super.key, required this.transactions});

  final List<TransactionModel> transactions;

  @override
  State<DailySpendingChart> createState() => _DailySpendingChartState();
}

class _DailySpendingChartState extends State<DailySpendingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<int, int> _getDailyTotals() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final totals = <int, int>{};
    for (var d = 1; d <= daysInMonth; d++) {
      totals[d] = 0;
    }
    for (final t in widget.transactions) {
      totals[t.date.day] = (totals[t.date.day] ?? 0) + t.amountFcfa;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Aucune dépense ce mois',
            style: AppTypography.revolutBody.copyWith(
              color: AppColors.revolutOnDarkMuted,
            ),
          ),
        ),
      );
    }

    final dailyTotals = _getDailyTotals();
    final maxAmount = dailyTotals.values.fold<int>(0, (m, v) => v > m ? v : m);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => SizedBox(
        height: 120,
        child: CustomPaint(
          painter: _BarChartPainter(
            dailyTotals: dailyTotals,
            maxAmount: maxAmount,
            progress: _animation.value,
            today: DateTime.now().day,
          ),
          size: const Size(double.infinity, 120),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.dailyTotals,
    required this.maxAmount,
    required this.progress,
    required this.today,
  });

  final Map<int, int> dailyTotals;
  final int maxAmount;
  final double progress;
  final int today;

  @override
  void paint(Canvas canvas, Size size) {
    if (maxAmount <= 0) return;

    final days = dailyTotals.keys.toList()..sort();
    final barWidth = size.width / days.length;
    const barPadding = 1.5;
    const maxBarHeight = 90.0;

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final amount = dailyTotals[day] ?? 0;
      final barHeight = amount > 0
          ? (amount / maxAmount) * maxBarHeight * progress
          : 2.0;

      final isToday = day == today;
      final color = isToday
          ? AppColors.revolutBlue
          : (amount > 0
                ? AppColors.revolutBlue.withOpacity(0.5)
                : AppColors.revolutBorder);

      final rect = Rect.fromLTWH(
        i * barWidth + barPadding,
        size.height - barHeight - 20,
        barWidth - barPadding * 2,
        barHeight,
      );

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
    }

    // Day labels (every 5 days)
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      if (day % 5 != 0 && day != 1) continue;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$day',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: AppColors.revolutOnDarkMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          i * barWidth + barWidth / 2 - textPainter.width / 2,
          size.height - 14,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.progress != progress;
}

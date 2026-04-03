import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A smooth animated progress bar with Revolut-style aesthetics.
///
/// Supports gradient fills, animated value changes, and optional labels.
///
/// Usage:
/// ```dart
/// SmoothProgressBar(value: 0.65, label: 'Budget used')
/// ```
class SmoothProgressBar extends StatefulWidget {
  const SmoothProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.borderRadius = 100,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.label,
    this.showPercentage = false,
  }) : assert(
         value >= 0.0 && value <= 1.0,
         'value must be between 0.0 and 1.0',
       );

  /// Progress value between 0.0 and 1.0.
  final double value;

  /// Height of the progress bar track.
  final double height;

  /// Corner radius of the progress bar.
  final double borderRadius;

  /// Background track color. Defaults to a dark track.
  final Color? backgroundColor;

  /// Foreground fill color. Overridden by [gradient] if provided.
  final Color? foregroundColor;

  /// Optional gradient for the filled portion.
  final Gradient? gradient;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Optional label displayed below the bar.
  final String? label;

  /// If true, shows percentage text on the right.
  final bool showPercentage;

  @override
  State<SmoothProgressBar> createState() => _SmoothProgressBarState();
}

class _SmoothProgressBarState extends State<SmoothProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _controller.forward();
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(SmoothProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller
        ..duration = widget.duration
        ..forward(from: 0);
      _previousValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.backgroundColor ?? AppColors.revolutBorder;
    final fill = widget.foregroundColor ?? AppColors.revolutBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.revolutOnDarkMuted,
                  ),
                ),
              if (widget.showPercentage)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (_, __) => Text(
                    '${(_animation.value * 100).round()}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.revolutOnDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: SizedBox(
                height: widget.height,
                child: CustomPaint(
                  painter: _ProgressPainter(
                    value: _animation.value,
                    trackColor: track,
                    fillColor: fill,
                    gradient: widget.gradient,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({
    required this.value,
    required this.trackColor,
    required this.fillColor,
    this.gradient,
  });

  final double value;
  final Color trackColor;
  final Color fillColor;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), trackPaint);

    final fillWidth = size.width * value.clamp(0.0, 1.0);
    if (fillWidth <= 0) return;

    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    if (gradient != null) {
      fillPaint.shader = gradient!.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    } else {
      fillPaint.color = fillColor;
    }

    canvas.drawRect(fillRect, fillPaint);
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor ||
      old.gradient != gradient;
}

/// A circular progress indicator with Revolut styling.
class RevolutCircularProgress extends StatelessWidget {
  const RevolutCircularProgress({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 6,
    this.color,
    this.backgroundColor,
    this.child,
  }) : assert(value >= 0.0 && value <= 1.0);

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? AppColors.revolutBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.revolutBlue,
            ),
            strokeCap: StrokeCap.round,
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

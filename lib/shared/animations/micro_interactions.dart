import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Micro-interaction utilities for Revolut-style animations.
///
/// Provides reusable animated widgets and transition helpers
/// without requiring Lottie assets (pure Flutter animations).
///
/// Covers: US-006 — Micro-interactions

// ─────────────────────────────────────────────────────────────
// Success Burst Animation
// ─────────────────────────────────────────────────────────────

/// Animated success checkmark with particle burst effect.
///
/// Usage:
/// ```dart
/// SuccessBurst(onComplete: () => Navigator.pop(context))
/// ```
class SuccessBurst extends StatefulWidget {
  const SuccessBurst({super.key, this.onComplete, this.color});

  final VoidCallback? onComplete;
  final Color? color;

  @override
  State<SuccessBurst> createState() => _SuccessBurstState();
}

class _SuccessBurstState extends State<SuccessBurst>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _burstController;

  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _burstScale;
  late Animation<double> _burstOpacity;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    _burstScale = Tween<double>(
      begin: 0.8,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _burstController, curve: Curves.easeOut));
    _burstOpacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _burstController, curve: Curves.easeOut));

    _runAnimation();
  }

  Future<void> _runAnimation() async {
    HapticFeedback.mediumImpact();
    await _checkController.forward();
    _burstController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF00C97B);

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Burst ring
          AnimatedBuilder(
            animation: _burstController,
            builder: (_, __) => Transform.scale(
              scale: _burstScale.value,
              child: Opacity(
                opacity: _burstOpacity.value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                  ),
                ),
              ),
            ),
          ),
          // Checkmark
          AnimatedBuilder(
            animation: _checkController,
            builder: (_, __) => Transform.scale(
              scale: _checkScale.value,
              child: Opacity(
                opacity: _checkOpacity.value,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(Icons.check_rounded, color: color, size: 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pulsing Dot (loading indicator)
// ─────────────────────────────────────────────────────────────

/// Three pulsing dots for loading states.
class PulsingDots extends StatefulWidget {
  const PulsingDots({super.key, this.color, this.size = 8});

  final Color? color;
  final double size;

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0.4,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();

    // Stagger the animations
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF0075EB);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Opacity(
              opacity: _animations[i].value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bounce Button
// ─────────────────────────────────────────────────────────────

/// A button that bounces on press (elastic scale animation).
class BounceButton extends StatefulWidget {
  const BounceButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.93,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Slide Up Transition
// ─────────────────────────────────────────────────────────────

/// Widget that slides up into view with fade.
class SlideUpTransition extends StatefulWidget {
  const SlideUpTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<SlideUpTransition> createState() => _SlideUpTransitionState();
}

class _SlideUpTransitionState extends State<SlideUpTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeIn),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => SlideTransition(
        position: _slide,
        child: FadeTransition(opacity: _opacity, child: child),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shimmer Loading
// ─────────────────────────────────────────────────────────────

/// Shimmer placeholder for loading states.
class ShimmerPlaceholder extends StatefulWidget {
  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFF1E1E1E),
                Color(0xFF2A2A2A),
                Color(0xFF1E1E1E),
              ],
            ),
          ),
        );
      },
    );
  }
}

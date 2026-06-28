// ============================================================
// lib/widgets/wave_animation.dart
// Ses dalgası animasyonu — mikrofon dinlerken gösterilir.
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WaveAnimation extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double height;

  const WaveAnimation({
    super.key,
    required this.isActive,
    this.color = AppColors.primary,
    this.height = 60,
  });

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(WaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
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
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WavePainter(
            progress: _controller.value,
            color: widget.color,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isActive;

  _WavePainter({
    required this.progress,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 24;
    final barWidth = size.width / (barCount * 2);
    final maxHeight = size.height;

    for (int i = 0; i < barCount; i++) {
      final x = (i * 2 + 0.5) * barWidth;
      double heightFraction;

      if (isActive) {
        heightFraction = 0.3 +
            0.7 * sin((progress * 2 * pi) + (i * 0.4)).abs();
      } else {
        heightFraction = 0.1;
      }

      final barHeight = maxHeight * heightFraction;
      final top = (maxHeight - barHeight) / 2;

      final paint = Paint()
        ..color = color.withOpacity(0.4 + 0.6 * heightFraction)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, barHeight),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress || old.isActive != isActive;
}

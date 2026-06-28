import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final double size;

  const MicButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.size = 80,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              Container(
                width: widget.size * _pulseAnimation.value * 1.5,
                height: widget.size * _pulseAnimation.value * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
            if (widget.isListening)
              Container(
                width: widget.size * _pulseAnimation.value * 1.2,
                height: widget.size * _pulseAnimation.value * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
            GestureDetector(
              onTap: widget.onTap,
              onLongPressStart: widget.onLongPressStart != null
                  ? (_) => widget.onLongPressStart!()
                  : null,
              onLongPressEnd: widget.onLongPressEnd != null
                  ? (_) => widget.onLongPressEnd!()
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isListening
                      ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        )
                      : AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isListening
                              ? AppColors.danger
                              : AppColors.primary)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isProcessing
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          widget.isListening
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: AppColors.white,
                          size: widget.size * 0.4,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
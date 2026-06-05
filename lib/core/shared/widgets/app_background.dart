import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';

/// Subtle ambient background glow for main screens.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: _GlowOrb(
            size: 220,
            color: AppColors.containerColor.withValues(alpha: 0.45),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -80,
          child: _GlowOrb(
            size: 180,
            color: AppColors.selectedColor.withValues(alpha: 0.06),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

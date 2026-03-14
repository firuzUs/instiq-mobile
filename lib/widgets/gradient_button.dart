import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Primary кнопка с градиентом и glow по MOBILE_UI_SPEC 4.2.
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    this.onPressed,
    required this.child,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: AppColors.gradientPrimaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
            child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                color: AppColors.backgroundDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

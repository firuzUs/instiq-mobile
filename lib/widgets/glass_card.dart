import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Glass Card по MOBILE_UI_SPEC 4.1: card фон, граница, скругление 12px, тень.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.cardDark.withValues(alpha: 0.8)
        : AppColors.cardLight;
    final borderColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.5)
        : AppColors.borderLight.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

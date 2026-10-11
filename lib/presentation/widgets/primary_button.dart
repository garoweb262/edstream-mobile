import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.useGradient = true,
    this.icon,
    this.color,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool useGradient;
  final Widget? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final hasCustomColor = color != null;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: (useGradient && !hasCustomColor && onPressed != null && !isLoading)
            ? AppColors.primaryGradient
            : null,
        color: (hasCustomColor && onPressed != null && !isLoading)
            ? effectiveColor
            : (!useGradient && onPressed != null && !isLoading)
                ? effectiveColor
                : (onPressed == null || isLoading ? AppColors.color4Light : effectiveColor),
        borderRadius: BorderRadius.circular(14),
        boxShadow: (onPressed != null && !isLoading)
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 10),
                      ],
                      Text(
                        text,
                        style: AppTypography.button,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

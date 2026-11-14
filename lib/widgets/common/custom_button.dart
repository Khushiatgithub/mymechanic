import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum ButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 20);

    Widget child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.outlined
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: AppTypography.labelLarge.copyWith(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: child,
        );
        break;

      case ButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: child,
        );
        break;

      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: child,
        );
        break;

      case ButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: child,
        );
        break;
    }

    if (height != null) {
      button = SizedBox(
        height: height,
        width: isFullWidth ? double.infinity : null,
        child: button,
      );
    } else if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.outlined:
      case ButtonVariant.ghost:
        return AppColors.primary;
    }
  }
}

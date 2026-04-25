import 'package:flutter/material.dart';

enum AppButtonVariant { primary, outline, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  Widget _buildChild(Color spinnerColor) {
    if (isLoading) {
      return SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: spinnerColor,
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: callback,
          child: _buildChild(Colors.white),
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: callback,
          child: _buildChild(Theme.of(context).colorScheme.primary),
        ),
      AppButtonVariant.text => TextButton(
          onPressed: callback,
          child: _buildChild(Theme.of(context).colorScheme.primary),
        ),
    };
  }
}

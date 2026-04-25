import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BadgeType { primary, success, warning, error, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.type = BadgeType.primary,
    super.key,
  });

  final String label;
  final BadgeType type;

  Color get _background => switch (type) {
        BadgeType.primary => AppColors.primary.withAlpha(25),
        BadgeType.success => AppColors.success.withAlpha(25),
        BadgeType.warning => AppColors.warning.withAlpha(25),
        BadgeType.error => AppColors.error.withAlpha(25),
        BadgeType.neutral => AppColors.border,
      };

  Color get _foreground => switch (type) {
        BadgeType.primary => AppColors.primaryDark,
        BadgeType.success => const Color(0xFF065F46),
        BadgeType.warning => const Color(0xFF92400E),
        BadgeType.error => const Color(0xFF991B1B),
        BadgeType.neutral => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

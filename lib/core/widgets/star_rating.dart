import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    super.key,
  });

  final double rating;
  final int maxRating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final filled = index < rating.floor();
        final partial = !filled && index < rating;
        return Icon(
          partial
              ? Icons.star_half
              : (filled ? Icons.star : Icons.star_border),
          size: size,
          color: AppColors.warning,
        );
      }),
    );
  }
}

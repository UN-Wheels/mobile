import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen dark background matching the web's AuthLayout:
/// navy gradient + dot-grid pattern + ambient teal glow.
class AuthBackground extends StatelessWidget {
  const AuthBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.authBg1, AppColors.authBg2, AppColors.authBg3],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _DotGridPainter()),
        ),
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 440,
            height: 440,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withAlpha(30),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withAlpha(20)
      ..style = PaintingStyle.fill;

    const spacing = 26.0;
    const radius = 1.4;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

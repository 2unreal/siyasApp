import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Temporary Development Branding Logo for House of SIYA's
/// Renders an elegant monogram (HS) with premium bridal gold styling
/// and configurable wordmark subtitle.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color monogramColor;
  final Color textColor;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showWordmark = true,
    this.monogramColor = AppColors.goldAccent,
    this.textColor = AppColors.primaryWine,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primaryWine,
            shape: BoxShape.circle,
            border: Border.all(color: monogramColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryWine.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'HS',
              style: TextStyle(
                color: monogramColor,
                fontSize: size * 0.44,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontFamily: 'serif',
              ),
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "House of SIYA's",
                style: TextStyle(
                  color: textColor,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  fontFamily: 'serif',
                ),
              ),
              Text(
                'BRIDAL & TAILORING STUDIO',
                style: TextStyle(
                  color: AppColors.goldDark,
                  fontSize: size * 0.20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
        ],
      ),
    );
  }
}

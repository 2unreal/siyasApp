import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_logo.dart';

class PlaceholderHubView extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderHubView({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.goldAccent),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(
              size: 64,
              monogramColor: AppColors.goldAccent,
              textColor: AppColors.primaryWine,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryWine,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Foundation Ready',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

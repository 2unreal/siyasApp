import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_environment.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/pin_lock_screen.dart';

class HouseOfSiyasApp extends ConsumerWidget {
  const HouseOfSiyasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp.router(
      title: AppConfig.current.appTitle,
      debugShowCheckedModeBanner: AppConfig.current.isDev,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
            if (auth.isAppLocked)
              const Positioned.fill(
                child: PinLockScreen(),
              ),
          ],
        );
      },
    );
  }
}

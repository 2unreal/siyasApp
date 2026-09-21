import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/core/config/app_environment.dart';
import 'package:siyas_app/core/config/business_defaults.dart';
import 'package:siyas_app/core/theme/app_colors.dart';
import 'package:siyas_app/core/theme/app_theme.dart';
import 'package:siyas_app/firebase_options/firebase_options_dev.dart';
import 'package:siyas_app/firebase_options/firebase_options_prod.dart';
import 'package:siyas_app/main.dart';
import 'package:siyas_app/presentation/providers/auth_provider.dart';
import 'package:siyas_app/domain/models/user_model.dart';
import 'package:siyas_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:siyas_app/presentation/widgets/app_logo.dart';

void main() {
  setUp(() {
    AppConfig.initialize(AppEnvironment.dev);
  });

  group('Milestone 3 — Environment Configuration & Isolation', () {
    test('Development environment is configured correctly', () {
      AppConfig.initialize(AppEnvironment.dev);
      expect(AppConfig.current.isDev, isTrue);
      expect(AppConfig.current.isProd, isFalse);
      expect(AppConfig.current.projectId, 'siyasapp-dev-509309');
      expect(AppConfig.current.storageBucket, 'siyasapp-dev-509309.firebasestorage.app');
      expect(AppConfig.current.appTitle, contains('[DEV]'));
      expect(DevFirebaseOptions.android.projectId, 'siyasapp-dev-509309');
      expect(DevFirebaseOptions.web.projectId, 'siyasapp-dev-509309');
    });

    test('Production environment is configured and isolated', () {
      AppConfig.initialize(AppEnvironment.prod);
      expect(AppConfig.current.isProd, isTrue);
      expect(AppConfig.current.isDev, isFalse);
      expect(AppConfig.current.projectId, 'siyasapp-509309');
      expect(AppConfig.current.storageBucket, 'siyasapp-509309.firebasestorage.app');
      expect(AppConfig.current.appTitle, "House of SIYA's");
      expect(ProdFirebaseOptions.android.projectId, 'siyasapp-509309');
      expect(ProdFirebaseOptions.web.projectId, 'siyasapp-509309');
    });

    test('Business defaults contain correct studio profile and prefixes', () {
      expect(BusinessDefaults.businessName, "House of SIYA's");
      expect(BusinessDefaults.whatsappNumber, '6385876999');
      expect(BusinessDefaults.cityWithPincode, 'Chennai 600128');
      expect(BusinessDefaults.prefixOrder, 'HS-ORD-');
      expect(BusinessDefaults.prefixCustomer, 'CUS-');
    });
  });

  group('Milestone 3 — Design System, Theme & Branding', () {
    test('AppColors brand hex values match design specification', () {
      expect(AppColors.primaryWine.toARGB32(), 0xFF58111A);
      expect(AppColors.goldAccent.toARGB32(), 0xFFD4AF37);
      expect(AppColors.ivoryBackground.toARGB32(), 0xFFFFFDF8);
    });

    test('AppTheme lightTheme matches Material 3 boutique styling', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primaryWine);
      expect(theme.colorScheme.secondary, AppColors.goldAccent);
      expect(theme.scaffoldBackgroundColor, AppColors.ivoryBackground);
    });

    testWidgets('AppLogo renders monogram and brand wordmark', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(size: 60, showWordmark: true),
          ),
        ),
      );

      expect(find.text('HS'), findsOneWidget);
      expect(find.text("House of SIYA's"), findsOneWidget);
      expect(find.text('BRIDAL & TAILORING STUDIO'), findsOneWidget);
    });
  });

  group('Milestone 3 — Application Launch & Riverpod Foundation', () {
    testWidgets('App launches independently without Milestone 4+ dependencies', (WidgetTester tester) async {
      AppConfig.initialize(AppEnvironment.dev);

      // Launch application foundation cleanly with NO repository or stream overrides
      await tester.pumpWidget(
        const ProviderScope(
          child: HouseOfSiyasApp(),
        ),
      );
      await tester.pump();

      // Initial route lands on Dashboard hub
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Studio Dashboard'), findsOneWidget);
    });
  });

  group('Milestone 3 — Responsive Shell & RBAC Navigation Foundation', () {
    testWidgets('Tablet/Web (wide): Manager view hides restricted areas (Classes, Reports, Settings)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.manager);
              return notifier;
            }),
          ],
          child: const HouseOfSiyasApp(),
        ),
      );
      await tester.pump();

      // Manager navigation items should NOT contain Classes, Reports, Settings
      expect(find.text('Classes'), findsNothing);
      expect(find.text('Reports'), findsNothing);
      expect(find.text('Settings'), findsNothing);

      // Operational hubs should be visible in NavigationRail
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Customers'), findsWidgets);
      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Payments'), findsWidgets);
      expect(find.text('Rentals'), findsWidgets);
      expect(find.text('Alterations'), findsWidgets);
    });

    testWidgets('Tablet/Web (wide): Owner view includes all 9 hubs in NavigationRail', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.owner);
              return notifier;
            }),
          ],
          child: const HouseOfSiyasApp(),
        ),
      );
      await tester.pump();

      // Owner should see all hubs including restricted administrative areas
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Customers'), findsWidgets);
      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Payments'), findsWidgets);
      expect(find.text('Rentals'), findsWidgets);
      expect(find.text('Alterations'), findsWidgets);
      expect(find.text('Classes'), findsWidgets);
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('Mobile (compact): Shows bottom bar with primary hubs and More button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.manager);
              return notifier;
            }),
          ],
          child: const HouseOfSiyasApp(),
        ),
      );
      await tester.pump();

      // BottomNavigationBar displays primary items + More
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Customers'), findsWidgets);
      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Payments'), findsWidgets);
      expect(find.text('More'), findsOneWidget);

      // Tap 'More' to open modal bottom sheet
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // For Manager, More sheet shows Rentals and Alterations, but NOT Classes, Reports, or Settings
      expect(find.text('Rentals'), findsOneWidget);
      expect(find.text('Alterations'), findsOneWidget);
      expect(find.text('Classes'), findsNothing);
      expect(find.text('Reports'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('Mobile (compact): Owner sees Classes, Reports, and Settings in More sheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.owner);
              return notifier;
            }),
          ],
          child: const HouseOfSiyasApp(),
        ),
      );
      await tester.pump();

      // Tap 'More' to open modal bottom sheet
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // For Owner, More sheet shows all extended hubs
      expect(find.text('Rentals'), findsOneWidget);
      expect(find.text('Alterations'), findsOneWidget);
      expect(find.text('Classes'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}

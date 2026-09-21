import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/core/config/app_environment.dart';
import 'package:siyas_app/core/config/business_defaults.dart';
import 'package:siyas_app/core/theme/app_colors.dart';
import 'package:siyas_app/firebase_options/firebase_options_dev.dart';
import 'package:siyas_app/firebase_options/firebase_options_prod.dart';

void main() {
  group('Milestone 18 — Production Readiness & Release Configuration Tests', () {
    test('Environment Configuration isolation: DEV and PROD are strictly decoupled', () {
      // 1. Verify Development Profile
      AppConfig.initialize(AppEnvironment.dev);
      expect(AppConfig.current.isDev, isTrue);
      expect(AppConfig.current.isProd, isFalse);
      expect(AppConfig.current.projectId, 'siyasapp-dev-509309');
      expect(AppConfig.current.storageBucket, 'siyasapp-dev-509309.firebasestorage.app');
      expect(AppConfig.current.appTitle, contains('[DEV]'));
      expect(DevFirebaseOptions.android.projectId, 'siyasapp-dev-509309');
      expect(DevFirebaseOptions.web.projectId, 'siyasapp-dev-509309');

      // 2. Verify Production Profile
      AppConfig.initialize(AppEnvironment.prod);
      expect(AppConfig.current.isProd, isTrue);
      expect(AppConfig.current.isDev, isFalse);
      expect(AppConfig.current.projectId, 'siyasapp-509309');
      expect(AppConfig.current.storageBucket, 'siyasapp-509309.firebasestorage.app');
      expect(AppConfig.current.appTitle, 'House of SIYA\'s');
      expect(ProdFirebaseOptions.android.projectId, 'siyasapp-509309');
      expect(ProdFirebaseOptions.web.projectId, 'siyasapp-509309');
    });

    test('Brand Identity & Design System verification', () {
      expect(AppColors.primaryWine.toARGB32(), BusinessDefaults.primaryWine);
      expect(AppColors.goldAccent.toARGB32(), BusinessDefaults.accentGold);
      expect(BusinessDefaults.businessName, 'House of SIYA\'s');
      expect(BusinessDefaults.contactPhone, '6385876999');
      expect(BusinessDefaults.whatsappNumber, '6385876999');
      expect(BusinessDefaults.fullAddress, contains('Chennai 600128'));
    });

    test('Sequential Numbering Prefix Specifications match approved architecture', () {
      expect(BusinessDefaults.prefixCustomer, 'CUS-');
      expect(BusinessDefaults.prefixOrder, 'HS-ORD-');
      expect(BusinessDefaults.prefixInvoice, 'HS-INV-');
      expect(BusinessDefaults.prefixPaymentReceipt, 'HS-REC-');
      expect(BusinessDefaults.prefixRental, 'HS-REN-');
      expect(BusinessDefaults.prefixAlteration, 'HS-ALT-');
      expect(BusinessDefaults.prefixClass, 'HS-CLS-');
    });
  });
}

import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/settings_model.dart';

class SettingsNotifier extends StateNotifier<StudioSettings> {
  SettingsNotifier() : super(StudioSettings.defaultSettings());

  void updateSettings(StudioSettings newSettings) {
    state = newSettings;
  }

  void updateStudioProfile({
    String? studioName,
    String? phone,
    String? whatsapp,
    String? address,
    String? taxGst,
  }) {
    state = state.copyWith(
      studioName: studioName,
      phone: phone,
      whatsapp: whatsapp,
      address: address,
      taxGst: taxGst,
      updatedAt: DateTime.now(),
    );
  }

  void updatePrefixes({
    String? orderPrefix,
    String? invoicePrefix,
    String? receiptPrefix,
    String? rentalPrefix,
    String? alterationPrefix,
    String? classPrefix,
  }) {
    state = state.copyWith(
      orderPrefix: orderPrefix,
      invoicePrefix: invoicePrefix,
      receiptPrefix: receiptPrefix,
      rentalPrefix: rentalPrefix,
      alterationPrefix: alterationPrefix,
      classPrefix: classPrefix,
      updatedAt: DateTime.now(),
    );
  }

  void resetToDefaults() {
    state = StudioSettings.defaultSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, StudioSettings>((ref) {
  return SettingsNotifier();
});

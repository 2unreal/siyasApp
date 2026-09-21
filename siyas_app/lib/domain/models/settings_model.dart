import '../../core/config/business_defaults.dart';

class StudioSettings {
  final String studioName;
  final String phone;
  final String whatsapp;
  final String address;
  final String taxGst;
  final String orderPrefix;
  final String invoicePrefix;
  final String receiptPrefix;
  final String rentalPrefix;
  final String alterationPrefix;
  final String classPrefix;
  final String currencySymbol;
  final DateTime updatedAt;
  final String updatedBy;

  const StudioSettings({
    required this.studioName,
    required this.phone,
    required this.whatsapp,
    required this.address,
    required this.taxGst,
    required this.orderPrefix,
    required this.invoicePrefix,
    required this.receiptPrefix,
    required this.rentalPrefix,
    required this.alterationPrefix,
    required this.classPrefix,
    this.currencySymbol = '₹',
    required this.updatedAt,
    required this.updatedBy,
  });

  factory StudioSettings.defaultSettings() {
    return StudioSettings(
      studioName: BusinessDefaults.businessName,
      phone: BusinessDefaults.contactPhone,
      whatsapp: BusinessDefaults.whatsappNumber,
      address: BusinessDefaults.fullAddress,
      taxGst: '',
      orderPrefix: BusinessDefaults.prefixOrder,
      invoicePrefix: BusinessDefaults.prefixInvoice,
      receiptPrefix: BusinessDefaults.prefixPaymentReceipt,
      rentalPrefix: BusinessDefaults.prefixRental,
      alterationPrefix: BusinessDefaults.prefixAlteration,
      classPrefix: BusinessDefaults.prefixClass,
      currencySymbol: '₹',
      updatedAt: DateTime.now(),
      updatedBy: 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studioName': studioName,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
      'taxGst': taxGst,
      'orderPrefix': orderPrefix,
      'invoicePrefix': invoicePrefix,
      'receiptPrefix': receiptPrefix,
      'rentalPrefix': rentalPrefix,
      'alterationPrefix': alterationPrefix,
      'classPrefix': classPrefix,
      'currencySymbol': currencySymbol,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  factory StudioSettings.fromMap(Map<String, dynamic> map) {
    return StudioSettings(
      studioName: map['studioName'] as String? ?? BusinessDefaults.businessName,
      phone: map['phone'] as String? ?? BusinessDefaults.contactPhone,
      whatsapp: map['whatsapp'] as String? ?? BusinessDefaults.whatsappNumber,
      address: map['address'] as String? ?? BusinessDefaults.fullAddress,
      taxGst: map['taxGst'] as String? ?? '',
      orderPrefix: map['orderPrefix'] as String? ?? BusinessDefaults.prefixOrder,
      invoicePrefix: map['invoicePrefix'] as String? ?? BusinessDefaults.prefixInvoice,
      receiptPrefix: map['receiptPrefix'] as String? ?? BusinessDefaults.prefixPaymentReceipt,
      rentalPrefix: map['rentalPrefix'] as String? ?? BusinessDefaults.prefixRental,
      alterationPrefix: map['alterationPrefix'] as String? ?? BusinessDefaults.prefixAlteration,
      classPrefix: map['classPrefix'] as String? ?? BusinessDefaults.prefixClass,
      currencySymbol: map['currencySymbol'] as String? ?? '₹',
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedBy: map['updatedBy'] as String? ?? 'system',
    );
  }

  StudioSettings copyWith({
    String? studioName,
    String? phone,
    String? whatsapp,
    String? address,
    String? taxGst,
    String? orderPrefix,
    String? invoicePrefix,
    String? receiptPrefix,
    String? rentalPrefix,
    String? alterationPrefix,
    String? classPrefix,
    String? currencySymbol,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return StudioSettings(
      studioName: studioName ?? this.studioName,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      taxGst: taxGst ?? this.taxGst,
      orderPrefix: orderPrefix ?? this.orderPrefix,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      rentalPrefix: rentalPrefix ?? this.rentalPrefix,
      alterationPrefix: alterationPrefix ?? this.alterationPrefix,
      classPrefix: classPrefix ?? this.classPrefix,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

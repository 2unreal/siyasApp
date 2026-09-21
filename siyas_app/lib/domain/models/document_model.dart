import '../../core/config/business_defaults.dart';

enum DocumentType {
  invoice,
  paymentReceipt,
  rentalInvoice,
  classReceipt,
  alterationReceipt;

  static DocumentType fromString(String? val) {
    switch (val) {
      case 'invoice':
        return DocumentType.invoice;
      case 'paymentReceipt':
      case 'payment':
        return DocumentType.paymentReceipt;
      case 'rentalInvoice':
      case 'rental':
        return DocumentType.rentalInvoice;
      case 'classReceipt':
      case 'class':
        return DocumentType.classReceipt;
      case 'alterationReceipt':
      case 'alteration':
        return DocumentType.alterationReceipt;
      default:
        return DocumentType.invoice;
    }
  }

  String toDbString() => name;

  String get displayName {
    switch (this) {
      case DocumentType.invoice:
        return 'Tax Invoice / Bill';
      case DocumentType.paymentReceipt:
        return 'Payment Receipt';
      case DocumentType.rentalInvoice:
        return 'Rental Invoice';
      case DocumentType.classReceipt:
        return 'Class Fee Receipt';
      case DocumentType.alterationReceipt:
        return 'Alteration Receipt';
    }
  }

  String get defaultPrefix {
    switch (this) {
      case DocumentType.invoice:
        return BusinessDefaults.prefixInvoice;
      case DocumentType.paymentReceipt:
        return BusinessDefaults.prefixPaymentReceipt;
      case DocumentType.rentalInvoice:
        return BusinessDefaults.prefixRental;
      case DocumentType.classReceipt:
        return BusinessDefaults.prefixClass;
      case DocumentType.alterationReceipt:
        return BusinessDefaults.prefixAlteration;
    }
  }
}

class DocumentRecord {
  final String id;
  final DocumentType documentType;
  final String documentNumber; // e.g. "HS-INV-0001" or "PENDING-INV-a1b2c3d4"
  final String entityType; // 'order' | 'payment' | 'rental' | 'class' | 'alteration'
  final String entityId;
  final String? customerId;
  final String? customerName;
  final String? customerMobile;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String generatedBy;
  final DateTime generatedAt;
  final String? notes;
  final bool isPendingSync;
  final String? pdfStoragePath;

  const DocumentRecord({
    required this.id,
    required this.documentType,
    required this.documentNumber,
    required this.entityType,
    required this.entityId,
    this.customerId,
    this.customerName,
    this.customerMobile,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    required this.generatedBy,
    required this.generatedAt,
    this.notes,
    this.isPendingSync = false,
    this.pdfStoragePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentType': documentType.toDbString(),
      'documentNumber': documentNumber,
      'entityType': entityType,
      'entityId': entityId,
      'customerId': customerId,
      'customerName': customerName,
      'customerMobile': customerMobile,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'generatedBy': generatedBy,
      'generatedAt': generatedAt.toIso8601String(),
      'notes': notes,
      'isPendingSync': isPendingSync,
      'pdfStoragePath': pdfStoragePath,
    };
  }

  factory DocumentRecord.fromMap(Map<String, dynamic> map, String id) {
    return DocumentRecord(
      id: id,
      documentType: DocumentType.fromString(map['documentType'] as String?),
      documentNumber: map['documentNumber'] as String? ?? '',
      entityType: map['entityType'] as String? ?? 'order',
      entityId: map['entityId'] as String? ?? '',
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String?,
      customerMobile: map['customerMobile'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      generatedBy: map['generatedBy'] as String? ?? '',
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes'] as String?,
      isPendingSync: map['isPendingSync'] as bool? ?? false,
      pdfStoragePath: map['pdfStoragePath'] as String?,
    );
  }
}

class DocumentBrandingConfig {
  final String businessName;
  final String fullAddress;
  final String phone;
  final String whatsapp;
  final int primaryColorHex;
  final int accentColorHex;
  final String thankYouNote;
  final String termsAndConditions;

  const DocumentBrandingConfig({
    this.businessName = BusinessDefaults.businessName,
    this.fullAddress = BusinessDefaults.fullAddress,
    this.phone = BusinessDefaults.contactPhone,
    this.whatsapp = BusinessDefaults.whatsappNumber,
    this.primaryColorHex = BusinessDefaults.primaryWine,
    this.accentColorHex = BusinessDefaults.accentGold,
    this.thankYouNote = 'Thank you for choosing House of SIYA\'s! We craft your special moments.',
    this.termsAndConditions =
        '1. Delivery dates are subject to customer trials.\n2. Orders once confirmed cannot be cancelled after fabric cutting.\n3. Dry clean only for bridal and embroidered garments.\n4. Balances must be cleared upon delivery.',
  });
}

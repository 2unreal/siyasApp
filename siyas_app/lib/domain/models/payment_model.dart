class Payment {
  final String id; // Client UUID
  final String entityType; // 'order' | 'class'
  final String entityId; // orderId or studentId
  final String? customerId;
  final String? studentId;
  final double amount;
  final String method; // 'cash' | 'upi'
  final String? receiptNumber; // e.g. "HS-REC-0001" or null
  final DateTime paymentDate;
  final String recordedBy;
  final String? notes;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.customerId,
    this.studentId,
    required this.amount,
    required this.method,
    this.receiptNumber,
    required this.paymentDate,
    required this.recordedBy,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'customerId': customerId,
      'studentId': studentId,
      'amount': amount,
      'method': method,
      'receiptNumber': receiptNumber,
      'paymentDate': paymentDate.toIso8601String(),
      'recordedBy': recordedBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      entityType: map['entityType'] as String? ?? 'order',
      entityId: map['entityId'] as String? ?? '',
      customerId: map['customerId'] as String?,
      studentId: map['studentId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: map['method'] as String? ?? 'cash',
      receiptNumber: map['receiptNumber'] as String?,
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      recordedBy: map['recordedBy'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Refund {
  final String id;
  final String entityType; // 'order' | 'class'
  final String entityId;
  final String? originalPaymentId;
  final double amount;
  final String method; // 'cash' | 'upi'
  final String reason;
  final String recordedBy;
  final DateTime refundDate;
  final DateTime createdAt;

  const Refund({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.originalPaymentId,
    required this.amount,
    required this.method,
    required this.reason,
    required this.recordedBy,
    required this.refundDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'originalPaymentId': originalPaymentId,
      'amount': amount,
      'method': method,
      'reason': reason,
      'recordedBy': recordedBy,
      'refundDate': refundDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Refund.fromMap(Map<String, dynamic> map, String id) {
    return Refund(
      id: id,
      entityType: map['entityType'] as String? ?? 'order',
      entityId: map['entityId'] as String? ?? '',
      originalPaymentId: map['originalPaymentId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: map['method'] as String? ?? 'cash',
      reason: map['reason'] as String? ?? '',
      recordedBy: map['recordedBy'] as String? ?? '',
      refundDate: map['refundDate'] != null
          ? DateTime.tryParse(map['refundDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class CustomerCredit {
  final String id;
  final String customerId;
  final String? orderId;
  final double amount;
  final String reason;
  final DateTime createdAt;
  final String createdBy;

  const CustomerCredit({
    required this.id,
    required this.customerId,
    this.orderId,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'orderId': orderId,
      'amount': amount,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory CustomerCredit.fromMap(Map<String, dynamic> map, String id) {
    return CustomerCredit(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      orderId: map['orderId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }
}

class PaymentResult {
  final bool success;
  final String paymentId;
  final double amountRecorded;
  final double newBalance;
  final double creditAmount;

  const PaymentResult({
    required this.success,
    required this.paymentId,
    required this.amountRecorded,
    required this.newBalance,
    required this.creditAmount,
  });

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
      success: map['success'] as bool? ?? false,
      paymentId: map['paymentId'] as String? ?? '',
      amountRecorded: (map['amountRecorded'] as num?)?.toDouble() ?? 0.0,
      newBalance: (map['newBalance'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (map['creditAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RefundResult {
  final bool success;
  final String refundId;
  final double newBalance;
  final double newTotalPaid;

  const RefundResult({
    required this.success,
    required this.refundId,
    required this.newBalance,
    required this.newTotalPaid,
  });

  factory RefundResult.fromMap(Map<String, dynamic> map) {
    return RefundResult(
      success: map['success'] as bool? ?? false,
      refundId: map['refundId'] as String? ?? '',
      newBalance: (map['newBalance'] as num?)?.toDouble() ?? 0.0,
      newTotalPaid: (map['newTotalPaid'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


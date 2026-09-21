enum OrderStatus {
  enquiry,
  confirmed,
  inProgress,
  readyForTrial,
  alteration,
  ready,
  delivered,
  closed,
  cancelled;

  static OrderStatus fromString(String? val) {
    switch (val) {
      case 'enquiry':
        return OrderStatus.enquiry;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'in_progress':
      case 'inProgress':
        return OrderStatus.inProgress;
      case 'ready_for_trial':
      case 'readyForTrial':
        return OrderStatus.readyForTrial;
      case 'alteration':
        return OrderStatus.alteration;
      case 'ready':
        return OrderStatus.ready;
      case 'delivered':
        return OrderStatus.delivered;
      case 'closed':
        return OrderStatus.closed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.confirmed;
    }
  }

  String toDbString() {
    switch (this) {
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.readyForTrial:
        return 'ready_for_trial';
      default:
        return name;
    }
  }
}

class OrderItem {
  final String id;
  final String serviceName;
  final String description;
  final int quantity;
  final double unitRate;
  final double lineTotal;

  const OrderItem({
    required this.id,
    required this.serviceName,
    required this.description,
    this.quantity = 1,
    required this.unitRate,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'description': description,
      'quantity': quantity,
      'unitRate': unitRate,
      'lineTotal': lineTotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map, String id) {
    return OrderItem(
      id: id,
      serviceName: map['serviceName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      unitRate: (map['unitRate'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Operational Order Document: Accessible by Manager and Owner.
/// Note: Contains NO running payment totals, balance, or credit fields!
class Order {
  final String id;
  final String orderNumber; // e.g. "HS-ORD-0001"
  final String customerId;
  final String customerName;
  final String? customerMobile;
  final String? measurementSetId;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final OrderStatus status;
  final bool isUrgent;
  final DateTime deliveryDate;
  final List<String> photoUrls;
  final List<String> localPhotoPaths;
  final String? generalNote;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.customerName = '',
    this.customerMobile,
    this.measurementSetId,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.totalAmount,
    this.status = OrderStatus.confirmed,
    this.isUrgent = false,
    required this.deliveryDate,
    this.photoUrls = const [],
    this.localPhotoPaths = const [],
    this.generalNote,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerMobile': customerMobile,
      'measurementSetId': measurementSetId,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'status': status.toDbString(),
      'isUrgent': isUrgent,
      'deliveryDate': deliveryDate.toIso8601String(),
      'photoUrls': photoUrls,
      'localPhotoPaths': localPhotoPaths,
      'generalNote': generalNote,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      orderNumber: map['orderNumber'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerMobile: map['customerMobile'] as String?,
      measurementSetId: map['measurementSetId'] as String?,
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>, ''))
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(map['status'] as String?),
      isUrgent: map['isUrgent'] as bool? ?? false,
      deliveryDate: map['deliveryDate'] != null
          ? DateTime.tryParse(map['deliveryDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      photoUrls: List<String>.from(map['photoUrls'] as List<dynamic>? ?? []),
      localPhotoPaths: List<String>.from(map['localPhotoPaths'] as List<dynamic>? ?? []),
      generalNote: map['generalNote'] as String?,
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      updatedBy: map['updatedBy'] as String? ?? '',
    );
  }
}

/// Protected Financial Summary Document (orders/{id}/financials/summary)
/// Strictly OWNER READ ONLY.
class OrderFinancialSummary {
  final String orderId;
  final double orderTotal;
  final double totalPaid;
  final double balanceAmount;
  final double creditAmount;
  final DateTime updatedAt;

  const OrderFinancialSummary({
    required this.orderId,
    required this.orderTotal,
    required this.totalPaid,
    required this.balanceAmount,
    required this.creditAmount,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderTotal': orderTotal,
      'totalPaid': totalPaid,
      'balanceAmount': balanceAmount,
      'creditAmount': creditAmount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OrderFinancialSummary.fromMap(Map<String, dynamic> map, String id) {
    return OrderFinancialSummary(
      orderId: id,
      orderTotal: (map['orderTotal'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (map['creditAmount'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

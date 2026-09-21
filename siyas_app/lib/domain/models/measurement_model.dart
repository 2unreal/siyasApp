class MeasurementField {
  final String id;
  final String label;
  final String defaultUnit; // 'inches' | 'cm'
  final int sortOrder;
  final String? instructions;

  const MeasurementField({
    required this.id,
    required this.label,
    this.defaultUnit = 'inches',
    required this.sortOrder,
    this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'defaultUnit': defaultUnit,
      'sortOrder': sortOrder,
      'instructions': instructions,
    };
  }

  factory MeasurementField.fromMap(Map<String, dynamic> map) {
    return MeasurementField(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      defaultUnit: map['defaultUnit'] as String? ?? 'inches',
      sortOrder: map['sortOrder'] as int? ?? 0,
      instructions: map['instructions'] as String?,
    );
  }
}

class MeasurementTemplate {
  final String id;
  final String garmentType; // 'Blouse', 'Bridal Blouse', 'Dress', 'Churidar'
  final List<MeasurementField> fields;
  final bool isActive;

  const MeasurementTemplate({
    required this.id,
    required this.garmentType,
    required this.fields,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'garmentType': garmentType,
      'fields': fields.map((f) => f.toMap()).toList(),
      'isActive': isActive,
    };
  }

  factory MeasurementTemplate.fromMap(Map<String, dynamic> map, String id) {
    return MeasurementTemplate(
      id: id,
      garmentType: map['garmentType'] as String? ?? '',
      fields: (map['fields'] as List<dynamic>?)
              ?.map((item) => MeasurementField.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

class MeasurementSet {
  final String id;
  final String customerId;
  final String templateId;
  final String garmentType;
  final Map<String, double> values; // Field ID -> Numeric value
  final String unit; // 'inches' | 'cm'
  final String? notes;
  final List<String> photoUrls;
  final DateTime createdAt;
  final String createdBy;

  const MeasurementSet({
    required this.id,
    required this.customerId,
    required this.templateId,
    required this.garmentType,
    required this.values,
    this.unit = 'inches',
    this.notes,
    this.photoUrls = const [],
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'templateId': templateId,
      'garmentType': garmentType,
      'values': values,
      'unit': unit,
      'notes': notes,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory MeasurementSet.fromMap(Map<String, dynamic> map, String id) {
    return MeasurementSet(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      templateId: map['templateId'] as String? ?? '',
      garmentType: map['garmentType'] as String? ?? '',
      values: (map['values'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      unit: map['unit'] as String? ?? 'inches',
      notes: map['notes'] as String?,
      photoUrls: List<String>.from(map['photoUrls'] as List<dynamic>? ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }
}

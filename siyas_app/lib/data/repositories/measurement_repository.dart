import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/measurement_model.dart';

class MeasurementUnitConverter {
  MeasurementUnitConverter._();

  static const double cmPerInch = 2.54;

  /// Converts inches to centimetres rounded to 1 decimal place
  static double inchesToCm(double inches) {
    return double.parse((inches * cmPerInch).toStringAsFixed(1));
  }

  /// Converts centimetres to inches rounded to 2 decimal places (or half-inches)
  static double cmToInches(double cm) {
    return double.parse((cm / cmPerInch).toStringAsFixed(2));
  }
}

class MeasurementRepository {
  final FirebaseFirestore _firestore;
  final String businessId;

  MeasurementRepository({
    FirebaseFirestore? firestore,
    this.businessId = 'house_of_siyas',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _templatesRef =>
      _firestore.collection('businesses').doc(businessId).collection('measurementTemplates');

  CollectionReference<Map<String, dynamic>> get _measurementSetsRef =>
      _firestore.collection('businesses').doc(businessId).collection('measurementSets');

  /// Standard default templates seeded for tailoring & bridal studios
  static List<MeasurementTemplate> get standardTemplates => [
        const MeasurementTemplate(
          id: 'blouse',
          garmentType: 'Blouse',
          fields: [
            MeasurementField(id: 'length', label: 'Blouse Length', defaultUnit: 'inches', sortOrder: 1),
            MeasurementField(id: 'bust_round', label: 'Bust Round', defaultUnit: 'inches', sortOrder: 2),
            MeasurementField(id: 'waist_round', label: 'Waist Round', defaultUnit: 'inches', sortOrder: 3),
            MeasurementField(id: 'shoulder', label: 'Shoulder Width', defaultUnit: 'inches', sortOrder: 4),
            MeasurementField(id: 'front_neck', label: 'Front Neck Depth', defaultUnit: 'inches', sortOrder: 5),
            MeasurementField(id: 'back_neck', label: 'Back Neck Depth', defaultUnit: 'inches', sortOrder: 6),
            MeasurementField(id: 'sleeve_length', label: 'Sleeve Length', defaultUnit: 'inches', sortOrder: 7),
            MeasurementField(id: 'sleeve_round', label: 'Sleeve Round / Muscle', defaultUnit: 'inches', sortOrder: 8),
            MeasurementField(id: 'armhole', label: 'Armhole Round', defaultUnit: 'inches', sortOrder: 9),
          ],
        ),
        const MeasurementTemplate(
          id: 'bridal_blouse',
          garmentType: 'Bridal Blouse',
          fields: [
            MeasurementField(id: 'length', label: 'Blouse Length', defaultUnit: 'inches', sortOrder: 1),
            MeasurementField(id: 'upper_bust', label: 'Upper Bust Round', defaultUnit: 'inches', sortOrder: 2),
            MeasurementField(id: 'bust_round', label: 'Bust Round', defaultUnit: 'inches', sortOrder: 3),
            MeasurementField(id: 'under_bust', label: 'Under Bust Round', defaultUnit: 'inches', sortOrder: 4),
            MeasurementField(id: 'waist_round', label: 'Waist Round', defaultUnit: 'inches', sortOrder: 5),
            MeasurementField(id: 'shoulder', label: 'Shoulder Width', defaultUnit: 'inches', sortOrder: 6),
            MeasurementField(id: 'front_neck', label: 'Front Neck Depth', defaultUnit: 'inches', sortOrder: 7),
            MeasurementField(id: 'back_neck', label: 'Back Neck Depth', defaultUnit: 'inches', sortOrder: 8),
            MeasurementField(id: 'sleeve_length', label: 'Sleeve Length', defaultUnit: 'inches', sortOrder: 9),
            MeasurementField(id: 'sleeve_round', label: 'Sleeve Round', defaultUnit: 'inches', sortOrder: 10),
            MeasurementField(id: 'armhole', label: 'Armhole', defaultUnit: 'inches', sortOrder: 11),
            MeasurementField(id: 'padding_point', label: 'Apex / Padding Distance', defaultUnit: 'inches', sortOrder: 12),
          ],
        ),
        const MeasurementTemplate(
          id: 'dress',
          garmentType: 'Dress / Kurti',
          fields: [
            MeasurementField(id: 'full_length', label: 'Full Dress Length', defaultUnit: 'inches', sortOrder: 1),
            MeasurementField(id: 'shoulder', label: 'Shoulder Width', defaultUnit: 'inches', sortOrder: 2),
            MeasurementField(id: 'chest', label: 'Chest Round', defaultUnit: 'inches', sortOrder: 3),
            MeasurementField(id: 'waist', label: 'Waist Round', defaultUnit: 'inches', sortOrder: 4),
            MeasurementField(id: 'hip', label: 'Hip Round', defaultUnit: 'inches', sortOrder: 5),
            MeasurementField(id: 'slit_length', label: 'Slit Length', defaultUnit: 'inches', sortOrder: 6),
            MeasurementField(id: 'sleeve_length', label: 'Sleeve Length', defaultUnit: 'inches', sortOrder: 7),
            MeasurementField(id: 'bottom_width', label: 'Bottom Flare / Width', defaultUnit: 'inches', sortOrder: 8),
          ],
        ),
        const MeasurementTemplate(
          id: 'churidar',
          garmentType: 'Churidar / Pant',
          fields: [
            MeasurementField(id: 'pant_length', label: 'Pant Length', defaultUnit: 'inches', sortOrder: 1),
            MeasurementField(id: 'waist', label: 'Waist Round', defaultUnit: 'inches', sortOrder: 2),
            MeasurementField(id: 'hip', label: 'Hip Round', defaultUnit: 'inches', sortOrder: 3),
            MeasurementField(id: 'thigh', label: 'Thigh Round', defaultUnit: 'inches', sortOrder: 4),
            MeasurementField(id: 'knee', label: 'Knee Round', defaultUnit: 'inches', sortOrder: 5),
            MeasurementField(id: 'bottom_opening', label: 'Ankle / Bottom Opening', defaultUnit: 'inches', sortOrder: 6),
          ],
        ),
      ];

  /// Stream all active garment measurement templates
  Stream<List<MeasurementTemplate>> streamTemplates() {
    return _templatesRef.where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Return default standard templates if database is fresh
        return standardTemplates;
      }
      return snapshot.docs
          .map((doc) => MeasurementTemplate.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream immutable historical measurement sets for a customer (latest first)
  Stream<List<MeasurementSet>> streamCustomerMeasurements(String customerId) {
    return _measurementSetsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MeasurementSet.fromMap(doc.data(), doc.id))
          .toList();
      // Sort chronologically descending (never overwrite historical sets)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Save a new historical measurement set (Never overwrites historical data)
  Future<void> createMeasurementSet(MeasurementSet measurementSet) async {
    await _measurementSetsRef.doc(measurementSet.id).set(measurementSet.toMap());
  }

  /// Owner: Save or update a measurement template configuration
  Future<void> saveTemplate(MeasurementTemplate template) async {
    await _templatesRef.doc(template.id).set(template.toMap(), SetOptions(merge: true));
  }
}

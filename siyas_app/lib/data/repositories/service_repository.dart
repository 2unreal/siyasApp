import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItem {
  final String id;
  final String name;
  final double defaultPrice;
  final String? description;
  final bool isActive;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.defaultPrice,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'defaultPrice': defaultPrice,
      'description': description,
      'isActive': isActive,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map, String id) {
    return ServiceItem(
      id: id,
      name: map['name'] as String? ?? '',
      defaultPrice: (map['defaultPrice'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

class ServiceRepository {
  final FirebaseFirestore _firestore;
  final String businessId;

  ServiceRepository({
    FirebaseFirestore? firestore,
    this.businessId = 'house_of_siyas',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _servicesRef =>
      _firestore.collection('businesses').doc(businessId).collection('services');

  static List<ServiceItem> get initialServices => const [
        ServiceItem(id: 'tailoring', name: 'Tailoring', defaultPrice: 650.0, description: 'Standard blouse & dress stitching'),
        ServiceItem(id: 'aari_embroidery', name: 'Aari Embroidery', defaultPrice: 2500.0, description: 'Handcrafted bridal embroidery work'),
        ServiceItem(id: 'bridal_blouse', name: 'Bridal Blouse', defaultPrice: 3500.0, description: 'Custom bridal cut with padding & heavy work'),
        ServiceItem(id: 'bridal_dress', name: 'Bridal Dress', defaultPrice: 8500.0, description: 'Full bespoke bridal gown / lehenga'),
        ServiceItem(id: 'customised_dress', name: 'Customised Dress', defaultPrice: 2800.0, description: 'Custom styled designer dress'),
        ServiceItem(id: 'saree_draping', name: 'Saree Pre-pleating & Draping', defaultPrice: 500.0, description: 'Box folding and styling'),
        ServiceItem(id: 'fabric_painting', name: 'Fabric Painting', defaultPrice: 1200.0, description: 'Custom hand painting on fabric'),
      ];

  Stream<List<ServiceItem>> streamServices() {
    return _servicesRef.where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return initialServices;
      }
      return snapshot.docs.map((doc) => ServiceItem.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> saveService(ServiceItem service) async {
    await _servicesRef.doc(service.id).set(service.toMap(), SetOptions(merge: true));
  }
}

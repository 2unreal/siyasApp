import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/allocation_model.dart';
import '../../domain/models/document_model.dart';

class NumberingService {
  final FirebaseFirestore? firestore;
  final String businessId;
  final String deviceId;

  // Local cache of active device allocations per document type
  final Map<AllocationDocumentType, DeviceNumberAllocation> _activeAllocations = {};

  NumberingService({
    this.firestore,
    this.businessId = 'house_of_siyas',
    String? deviceId,
  }) : deviceId = deviceId ?? 'device_primary';

  /// Get remaining count for a document type
  int getRemainingCount(AllocationDocumentType type) {
    final alloc = _activeAllocations[type];
    if (alloc == null) return 0;
    return alloc.remainingCount;
  }

  /// Manually set or restore an allocation (useful for local cache restoration & testing)
  void setAllocation(DeviceNumberAllocation allocation) {
    _activeAllocations[allocation.documentType] = allocation;
  }

  DeviceNumberAllocation? getAllocation(AllocationDocumentType type) {
    return _activeAllocations[type];
  }

  /// Reserve a new block of 50 numbers from Firestore.
  /// Uses a transaction to increment the global sequence counter by blockSize.
  Future<DeviceNumberAllocation> reserveRangeOnline(
    AllocationDocumentType type, {
    int blockSize = 50,
  }) async {
    if (firestore == null) {
      // Offline / standalone fallback reservation
      final currentStart = (_activeAllocations[type]?.rangeEnd ?? 0) + 1;
      final newAlloc = DeviceNumberAllocation(
        deviceId: deviceId,
        documentType: type,
        rangeStart: currentStart,
        rangeEnd: currentStart + blockSize - 1,
        currentAllocated: currentStart,
        reservedAt: DateTime.now(),
      );
      _activeAllocations[type] = newAlloc;
      return newAlloc;
    }

    final counterRef = firestore!.collection('businesses').doc(businessId).collection('numberingCounters').doc(type.toDbString());
    final allocDocRef = firestore!.collection('businesses').doc(businessId).collection('numberingAllocations').doc('${deviceId}_${type.toDbString()}');

    return await firestore!.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      int lastGlobalIndex = 0;
      if (counterSnapshot.exists && counterSnapshot.data() != null) {
        lastGlobalIndex = (counterSnapshot.data()!['lastIndex'] as int?) ?? 0;
      }

      final newRangeStart = lastGlobalIndex + 1;
      final newRangeEnd = lastGlobalIndex + blockSize;

      // Update global counter
      transaction.set(
        counterRef,
        {'lastIndex': newRangeEnd, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      final allocation = DeviceNumberAllocation(
        deviceId: deviceId,
        documentType: type,
        rangeStart: newRangeStart,
        rangeEnd: newRangeEnd,
        currentAllocated: newRangeStart,
        reservedAt: DateTime.now(),
      );

      // Save device allocation
      transaction.set(allocDocRef, allocation.toMap());

      _activeAllocations[type] = allocation;
      return allocation;
    });
  }

  /// Consumes the next sequence number strictly upon document save/confirmation.
  /// If reserved range is exhausted and offline, returns a PENDING- format number.
  Future<String> consumeNextDocumentNumber({
    required DocumentType docType,
    bool isOnline = true,
  }) async {
    final allocType = _mapDocTypeToAllocType(docType);
    final prefix = docType.defaultPrefix;

    var currentAlloc = _activeAllocations[allocType];

    // If no active range exists or current is exhausted:
    if (currentAlloc == null || currentAlloc.isExhausted) {
      if (isOnline && firestore != null) {
        try {
          currentAlloc = await reserveRangeOnline(allocType);
        } catch (_) {
          // If network reservation fails, proceed to offline fallback
          currentAlloc = null;
        }
      }
    }

    // If we have a valid non-exhausted allocation:
    if (currentAlloc != null && !currentAlloc.isExhausted) {
      final allocatedNumber = currentAlloc.currentAllocated;
      final padded = allocatedNumber.toString().padLeft(4, '0');

      // Increment allocation and update cache
      final updatedAlloc = DeviceNumberAllocation(
        deviceId: currentAlloc.deviceId,
        documentType: currentAlloc.documentType,
        rangeStart: currentAlloc.rangeStart,
        rangeEnd: currentAlloc.rangeEnd,
        currentAllocated: allocatedNumber + 1,
        reservedAt: currentAlloc.reservedAt,
      );
      _activeAllocations[allocType] = updatedAlloc;

      // Unused numbers in an expired range are never reused!
      return '$prefix$padded';
    }

    // Exhaustion Fallback: Generate PENDING status sequence
    final randomSuffix = _generateShortUuid();
    final cleanPrefix = prefix.replaceAll('-', '').replaceAll('HS', '');
    return 'PENDING-$cleanPrefix-$randomSuffix';
  }

  AllocationDocumentType _mapDocTypeToAllocType(DocumentType docType) {
    switch (docType) {
      case DocumentType.invoice:
        return AllocationDocumentType.invoice;
      case DocumentType.paymentReceipt:
        return AllocationDocumentType.payment;
      case DocumentType.rentalInvoice:
        return AllocationDocumentType.rental;
      case DocumentType.classReceipt:
        return AllocationDocumentType.classDoc;
      case DocumentType.alterationReceipt:
        return AllocationDocumentType.alteration;
    }
  }

  String _generateShortUuid() {
    final rnd = Random();
    const chars = 'abcdef0123456789';
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}

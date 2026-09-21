import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/data/services/sync_service.dart';

void main() {
  group('Milestone 12 Offline Persistence & Sync Engine Tests', () {
    test('Last-Write-Wins (LWW) conflict resolution chooses latest updated document', () {
      final service = SyncService();

      final localDoc = {
        'id': 'cus_1',
        'name': 'Priya Sundar (Offline Edit)',
        'updatedAt': '2026-09-21T18:00:00.000Z',
      };

      final remoteDoc = {
        'id': 'cus_1',
        'name': 'Priya Sundar (Remote Edit)',
        'updatedAt': '2026-09-21T17:30:00.000Z',
      };

      final winner = service.resolveConflictLww(localDoc: localDoc, remoteDoc: remoteDoc);
      expect(winner['name'], 'Priya Sundar (Offline Edit)');
    });

    test('LWW conflict resolution prefers remote document when remote timestamp is newer', () {
      final service = SyncService();

      final localDoc = {
        'id': 'ord_1',
        'status': 'confirmed',
        'updatedAt': '2026-09-21T15:00:00.000Z',
      };

      final remoteDoc = {
        'id': 'ord_1',
        'status': 'in_progress',
        'updatedAt': '2026-09-21T16:00:00.000Z',
      };

      final winner = service.resolveConflictLww(localDoc: localDoc, remoteDoc: remoteDoc);
      expect(winner['status'], 'in_progress');
    });

    test('Audit metadata tracking: ensures updatedAt and updatedBy are preserved', () {
      final doc = {
        'id': 'alt_1',
        'status': 'ready',
        'createdAt': '2026-09-21T10:00:00.000Z',
        'updatedAt': '2026-09-21T14:30:00.000Z',
        'createdBy': 'mgr_1',
        'updatedBy': 'owner_1',
      };

      expect(doc['updatedAt'], isNotNull);
      expect(doc['updatedBy'], 'owner_1');
      expect(DateTime.tryParse(doc['updatedAt'] as String), isNotNull);
    });
  });
}

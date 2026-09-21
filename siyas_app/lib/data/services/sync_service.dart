import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus {
  online,
  offline,
  syncing,
}

class SyncService {
  final FirebaseFirestore? firestore;

  SyncService({this.firestore});

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  /// Stream Firestore metadata changes to monitor synchronization status.
  /// When hasPendingWrites is true, changes exist locally that are not yet committed to the server.
  Stream<bool> streamPendingWrites(String collectionPath) {
    if (kIsWeb && firestore == null) {
      return Stream.value(false);
    }
    return _db.collection(collectionPath).snapshots(includeMetadataChanges: true).map((snap) {
      return snap.metadata.hasPendingWrites;
    });
  }

  /// Enables or disables offline network connectivity explicitly
  Future<void> setNetworkEnabled(bool enabled) async {
    if (kIsWeb && firestore == null) return;
    if (enabled) {
      await _db.enableNetwork();
    } else {
      await _db.disableNetwork();
    }
  }

  /// Clears local cached data on user logout to prevent unauthorized local record exposure.
  Future<void> clearLocalCache() async {
    if (kIsWeb) return;
    try {
      await _db.clearPersistence();
    } catch (e) {
      debugPrint('Notice on clearing Firestore persistence: $e');
    }
  }

  /// Resolves conflicts using Last-Write-Wins (LWW) based on updatedAt timestamp.
  /// Returns the winning document snapshot data.
  Map<String, dynamic> resolveConflictLww({
    required Map<String, dynamic> localDoc,
    required Map<String, dynamic> remoteDoc,
  }) {
    final localTime = DateTime.tryParse(localDoc['updatedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final remoteTime = DateTime.tryParse(remoteDoc['updatedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    if (localTime.isAfter(remoteTime)) {
      return localDoc;
    }
    return remoteDoc;
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

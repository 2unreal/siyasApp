class AuditEvent {
  final String id;
  final String action;
  final String actorUid;
  final String actorRole;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  const AuditEvent({
    required this.id,
    required this.action,
    required this.actorUid,
    required this.actorRole,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'actorUid': actorUid,
      'actorRole': actorRole,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditEvent.fromMap(Map<String, dynamic> map) {
    return AuditEvent(
      id: map['id'] as String? ?? '',
      action: map['action'] as String? ?? '',
      actorUid: map['actorUid'] as String? ?? '',
      actorRole: map['actorRole'] as String? ?? '',
      details: Map<String, dynamic>.from(map['details'] as Map? ?? {}),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Append-Only Audit Logging Service
/// Strictly append-only: No deletion or modification permitted.
class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final List<AuditEvent> _inMemoryLogs = [];

  List<AuditEvent> get logs => List.unmodifiable(_inMemoryLogs);

  Future<AuditEvent> logEvent({
    required String action,
    required String actorUid,
    required String actorRole,
    Map<String, dynamic>? details,
  }) async {
    final event = AuditEvent(
      id: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}-${_inMemoryLogs.length + 1}',
      action: action,
      actorUid: actorUid,
      actorRole: actorRole,
      details: details ?? {},
      timestamp: DateTime.now(),
    );

    _inMemoryLogs.add(event);
    return event;
  }

  List<AuditEvent> getLogsForActor(String actorUid) {
    return _inMemoryLogs.where((e) => e.actorUid == actorUid).toList();
  }

  List<AuditEvent> getLogsByAction(String action) {
    return _inMemoryLogs.where((e) => e.action == action).toList();
  }
}

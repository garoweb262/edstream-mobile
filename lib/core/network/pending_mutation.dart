/// Represents a single queued write mutation made while offline.
/// Replayed verbatim against https://api.edstream.ng/api/v1 once connectivity returns.
class PendingMutation {
  const PendingMutation({
    required this.localId,
    required this.feature,
    required this.operation,
    required this.method,
    required this.path,
    required this.displaySnapshot,
    this.payload,
    this.entityId,
    required this.createdAt,
  });

  final String localId;

  /// E.g. 'scoresheet' | 'attendance' | 'complaints' | 'profile'
  final String feature;

  /// E.g. 'saveGrades' | 'markAttendance' | 'fileComplaint' | 'updatePassword'
  final String operation;

  /// 'POST' | 'PUT' | 'PATCH' | 'DELETE'
  final String method;

  /// API path relative to base URL (e.g. 'staff/score-sheet', 'complain')
  final String path;

  /// Request body payload
  final Map<String, dynamic>? payload;

  /// Optional server entity ID
  final String? entityId;

  /// Optimistic snapshot to display locally before server acknowledges
  final Map<String, dynamic> displaySnapshot;

  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'localId': localId,
    'feature': feature,
    'operation': operation,
    'method': method,
    'path': path,
    'payload': payload,
    'entityId': entityId,
    'displaySnapshot': displaySnapshot,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingMutation.fromMap(Map<String, dynamic> map) {
    return PendingMutation(
      localId: map['localId'] as String,
      feature: map['feature'] as String,
      operation: map['operation'] as String,
      method: map['method'] as String,
      path: map['path'] as String,
      payload: (map['payload'] as Map?)?.cast<String, dynamic>(),
      entityId: map['entityId'] as String?,
      displaySnapshot: Map<String, dynamic>.from(map['displaySnapshot'] as Map? ?? {}),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

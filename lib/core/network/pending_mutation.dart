/// Represents a single queued write mutation made while offline.
/// Replayed verbatim against the API once connectivity returns. When the
/// server rejects it, [errorMessage] is set and it waits for the user to
/// retry or discard it.
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
    this.errorMessage,
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

  /// Set when the server rejected this change.
  final String? errorMessage;

  bool get isFailed => errorMessage != null;

  PendingMutation copyWith({String? errorMessage, bool clearError = false}) => PendingMutation(
        localId: localId,
        feature: feature,
        operation: operation,
        method: method,
        path: path,
        payload: payload,
        entityId: entityId,
        displaySnapshot: displaySnapshot,
        createdAt: createdAt,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

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
    'errorMessage': errorMessage,
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
      errorMessage: map['errorMessage'] as String?,
    );
  }
}

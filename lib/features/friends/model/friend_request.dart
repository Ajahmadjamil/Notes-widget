class FriendRequest {
  final String friendshipId;
  final String fromUid;
  final String toUid;
  final String status;
  final int sentAt;
  final String? fromUsername;
  final String? fromDisplayName;

  const FriendRequest({
    required this.friendshipId,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.sentAt,
    this.fromUsername,
    this.fromDisplayName,
  });

  factory FriendRequest.fromRow(
    Map<String, dynamic> row, {
    String? fromUsername,
    String? fromDisplayName,
  }) {
    return FriendRequest(
      friendshipId: row['id'] as String,
      fromUid: row['user_id'] as String,
      toUid: row['friend_id'] as String,
      status: row['status'] as String? ?? 'pending',
      sentAt: _timestampMillis(row['created_at']) ?? 0,
      fromUsername: fromUsername,
      fromDisplayName: fromDisplayName,
    );
  }

  static int? _timestampMillis(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch;
    }
    return null;
  }
}

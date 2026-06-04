class FriendRequest {
  final String fromUid;
  final String toUid;
  final String status;
  final int sentAt;
  final String? fromUsername;
  final String? fromDisplayName;

  const FriendRequest({
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.sentAt,
    this.fromUsername,
    this.fromDisplayName,
  });

  factory FriendRequest.fromSnapshot(
    String fromUid,
    String toUid,
    Map<dynamic, dynamic> data,
  ) {
    return FriendRequest(
      fromUid: data['fromUid'] as String? ?? fromUid,
      toUid: data['toUid'] as String? ?? toUid,
      status: data['status'] as String? ?? 'pending',
      sentAt: _asInt(data['sentAt']) ?? 0,
      fromUsername: data['fromUsername'] as String?,
      fromDisplayName: data['fromDisplayName'] as String?,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

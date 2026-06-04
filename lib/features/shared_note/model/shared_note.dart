class SharedNote {
  final String sharedNoteId;
  final String friendshipId;
  final String user1;
  final String user2;
  final String title;
  final String body;
  final int createdAt;
  final int updatedAt;
  final String updatedBy;

  const SharedNote({
    required this.sharedNoteId,
    required this.friendshipId,
    required this.user1,
    required this.user2,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SharedNote.fromRow(Map<String, dynamic> row) {
    final friendship = row['friendships'];
    String user1 = '';
    String user2 = '';
    String friendshipId = row['friendship_id'] as String? ?? '';

    if (friendship is Map) {
      user1 = friendship['user_id'] as String? ?? '';
      user2 = friendship['friend_id'] as String? ?? '';
      friendshipId = friendship['id'] as String? ?? friendshipId;
    }

    return SharedNote(
      sharedNoteId: row['id'] as String,
      friendshipId: friendshipId,
      user1: user1,
      user2: user2,
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      createdAt: _timestampMillis(row['created_at']) ?? 0,
      updatedAt: _timestampMillis(row['updated_at']) ?? 0,
      updatedBy: row['updated_by'] as String? ?? '',
    );
  }

  bool involvesUser(String uid) => user1 == uid || user2 == uid;

  static int _timestampMillis(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }
}

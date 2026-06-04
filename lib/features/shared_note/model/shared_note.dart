class SharedNote {
  final String sharedNoteId;
  final String user1;
  final String user2;
  final String title;
  final String body;
  final int createdAt;
  final int updatedAt;
  final String updatedBy;

  const SharedNote({
    required this.sharedNoteId,
    required this.user1,
    required this.user2,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SharedNote.fromSnapshot(
    String sharedNoteId,
    Map<dynamic, dynamic> data,
  ) {
    return SharedNote(
      sharedNoteId: data['sharedNoteId'] as String? ?? sharedNoteId,
      user1: data['user1'] as String? ?? '',
      user2: data['user2'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: _asInt(data['createdAt']) ?? 0,
      updatedAt: _asInt(data['updatedAt']) ?? 0,
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }

  bool involvesUser(String uid) => user1 == uid || user2 == uid;

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

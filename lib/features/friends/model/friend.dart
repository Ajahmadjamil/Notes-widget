import 'package:noteswidgetapp/features/profile/model/user_profile.dart';

class Friend {
  final String friendUid;
  final String friendshipId;
  final int since;
  final String sharedNoteId;
  final UserProfile? profile;

  const Friend({
    required this.friendUid,
    required this.friendshipId,
    required this.since,
    required this.sharedNoteId,
    this.profile,
  });

  String get displayLabel =>
      profile?.username != null ? '@${profile!.username}' : friendUid;

  String get subtitle =>
      profile?.displayName ?? profile?.email ?? 'Friend';

  factory Friend.fromRow(
    String myUid,
    Map<String, dynamic> row, {
    UserProfile? profile,
  }) {
    final userId = row['user_id'] as String;
    final friendId = row['friend_id'] as String;
    final otherUid = userId == myUid ? friendId : userId;

    final sharedNotes = row['shared_notes'];
    String noteId = '';
    if (sharedNotes is Map) {
      noteId = sharedNotes['id'] as String? ?? '';
    } else if (sharedNotes is List && sharedNotes.isNotEmpty) {
      noteId = (sharedNotes.first as Map)['id'] as String? ?? '';
    }

    return Friend(
      friendUid: otherUid,
      friendshipId: row['id'] as String,
      since: _timestampMillis(row['accepted_at'] ?? row['created_at']) ?? 0,
      sharedNoteId: noteId,
      profile: profile,
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

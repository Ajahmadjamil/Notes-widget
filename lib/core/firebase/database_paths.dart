import 'dart:convert';

/// Firebase Realtime Database path helpers (used from Module 2 onward).
class DatabasePaths {
  DatabasePaths._();

  static String user(String uid) => 'users/$uid';
  static String usernameIndex(String normalizedUsername) =>
      'usernames/$normalizedUsername';

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  /// RTDB keys cannot contain `.`, `#`, `$`, `[`, or `]`.
  static String encodeEmailKey(String normalizedEmail) {
    return base64Url.encode(utf8.encode(normalizedEmail)).replaceAll('=', '');
  }

  static String emailIndex(String normalizedEmail) =>
      'emails/${encodeEmailKey(normalizedEmail)}';
  static String notes(String uid) => 'notes/$uid';
  static String note(String uid, String noteId) => 'notes/$uid/$noteId';
  static String friendRequest(String toUid, String fromUid) =>
      'friendRequests/$toUid/$fromUid';
  static String friend(String uid, String friendUid) => 'friends/$uid/$friendUid';
  static String sharedNote(String sharedNoteId) => 'sharedNotes/$sharedNoteId';

  static String sharedNoteIdForPair(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}

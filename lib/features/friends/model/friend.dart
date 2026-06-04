import 'package:noteswidgetapp/features/profile/model/user_profile.dart';

class Friend {
  final String friendUid;
  final int since;
  final String sharedNoteId;
  final UserProfile? profile;

  const Friend({
    required this.friendUid,
    required this.since,
    required this.sharedNoteId,
    this.profile,
  });

  String get displayLabel =>
      profile?.username != null ? '@${profile!.username}' : friendUid;

  String get subtitle =>
      profile?.displayName ?? profile?.email ?? 'Friend';

  factory Friend.fromSnapshot(
    String friendUid,
    Map<dynamic, dynamic> data, {
    UserProfile? profile,
  }) {
    return Friend(
      friendUid: friendUid,
      since: _asInt(data['since']) ?? 0,
      sharedNoteId: data['sharedNoteId'] as String? ?? '',
      profile: profile,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

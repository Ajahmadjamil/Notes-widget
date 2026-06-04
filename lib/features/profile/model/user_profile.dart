class UserProfile {
  final String uid;
  final String? email;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final int? createdAt;
  final int? updatedAt;

  const UserProfile({
    required this.uid,
    this.email,
    this.username,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasUsername => username != null && username!.trim().isNotEmpty;

  factory UserProfile.fromRow(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] as String?,
      username: data['username'] as String?,
      displayName: data['display_name'] as String?,
      photoUrl: data['photo_url'] as String?,
      createdAt: _timestampMillis(data['created_at']),
      updatedAt: _timestampMillis(data['updated_at']),
    );
  }

  static int? _timestampMillis(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final dt = DateTime.tryParse(value);
      return dt?.millisecondsSinceEpoch;
    }
    return null;
  }
}

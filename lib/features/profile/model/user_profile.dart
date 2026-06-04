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

  factory UserProfile.fromSnapshot(String uid, Map<dynamic, dynamic>? data) {
    if (data == null) {
      return UserProfile(uid: uid);
    }
    return UserProfile(
      uid: uid,
      email: data['email'] as String?,
      username: data['username'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: _asInt(data['createdAt']),
      updatedAt: _asInt(data['updatedAt']),
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

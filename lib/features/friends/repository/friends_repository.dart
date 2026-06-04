import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/firebase/database_paths.dart';
import 'package:noteswidgetapp/core/firebase/firebase_database_service.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';
import 'package:noteswidgetapp/features/friends/model/friend_request.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';

class UserNotFoundException implements Exception {
  const UserNotFoundException();
}

class FriendsRepository {
  final UserProfileRepository _profiles = UserProfileRepository();
  DatabaseReference get _root => FirebaseDatabaseService.rootRef();

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  Future<UserProfile?> searchUser(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    String? uid;

    if (q.contains('@')) {
      final email = DatabasePaths.normalizeEmail(q);
      uid = await _lookupUidFromIndex(DatabasePaths.emailIndex(email));
      uid ??= await _lookupUidByUserField('email', email);
    } else {
      final rawUsername = q.replaceFirst(RegExp(r'^@'), '').trim();
      final normalized = UserProfileRepository.normalizeUsername(rawUsername);
      uid = await _lookupUidFromIndex(DatabasePaths.usernameIndex(normalized));
      uid ??= await _lookupUidByUserField('username', rawUsername);
      uid ??= await _lookupUidByUserField(
        'username',
        normalized,
        caseInsensitive: true,
      );
    }

    if (uid == null) return null;
    return _profiles.fetchProfile(uid);
  }

  Future<String?> _lookupUidFromIndex(String path) async {
    final snap = await _root.child(path).get();
    if (snap.exists && snap.value != null) {
      return snap.value.toString();
    }
    return null;
  }

  /// Fallback when /usernames or /emails index was never written.
  Future<String?> _lookupUidByUserField(
    String field,
    String value, {
    bool caseInsensitive = false,
  }) async {
    try {
      final snap = await _root
          .child('users')
          .orderByChild(field)
          .equalTo(caseInsensitive ? value.toLowerCase() : value)
          .limitToFirst(1)
          .get();

      if (!snap.exists || snap.children.isEmpty) return null;
      return snap.children.first.key;
    } catch (e) {
      if (kDebugMode) {
        print('search fallback orderByChild($field) failed: $e');
      }
      return null;
    }
  }

  Future<bool> isFriend(String otherUid) async {
    final uid = _myUid;
    if (uid == null) return false;
    final snap = await _root.child(DatabasePaths.friend(uid, otherUid)).get();
    return snap.exists;
  }

  Future<FriendRequest?> getOutgoingRequest(String toUid) async {
    final uid = _myUid;
    if (uid == null) return null;
    final snap = await _root.child(DatabasePaths.friendRequest(toUid, uid)).get();
    if (!snap.exists || snap.value == null) return null;
    final data = Map<dynamic, dynamic>.from(snap.value as Map);
    if (data['status'] != 'pending') return null;
    return FriendRequest.fromSnapshot(uid, toUid, data);
  }

  Future<FriendRequest?> getIncomingRequest(String fromUid) async {
    final uid = _myUid;
    if (uid == null) return null;
    final snap = await _root.child(DatabasePaths.friendRequest(uid, fromUid)).get();
    if (!snap.exists || snap.value == null) return null;
    final data = Map<dynamic, dynamic>.from(snap.value as Map);
    if (data['status'] != 'pending') return null;
    return FriendRequest.fromSnapshot(fromUid, uid, data);
  }

  Future<void> sendFriendRequest(String toUid) async {
    final uid = _myUid;
    if (uid == null) throw StateError('Not signed in');
    if (uid == toUid) throw StateError('Cannot add yourself');

    if (await isFriend(toUid)) {
      throw StateError('Already friends');
    }

    final incoming = await getIncomingRequest(toUid);
    if (incoming != null) {
      throw StateError('This user already sent you a request — check Requests');
    }

    final existing = await getOutgoingRequest(toUid);
    if (existing != null) {
      throw StateError('Friend request already sent');
    }

    final myProfile = await _profiles.fetchProfile(uid);
    final now = DateTime.now().millisecondsSinceEpoch;

    await _root.child(DatabasePaths.friendRequest(toUid, uid)).set({
      'fromUid': uid,
      'toUid': toUid,
      'status': 'pending',
      'sentAt': now,
      'fromUsername': myProfile?.username ?? '',
      'fromDisplayName': myProfile?.displayName ?? myProfile?.username ?? 'User',
    });
  }

  Future<List<FriendRequest>> fetchIncomingRequests() async {
    final uid = _myUid;
    if (uid == null) return [];

    final snap = await _root.child('friendRequests/$uid').get();
    if (!snap.exists || snap.value == null) return [];

    final raw = Map<dynamic, dynamic>.from(snap.value as Map);
    final list = <FriendRequest>[];

    for (final entry in raw.entries) {
      final fromUid = entry.key as String;
      final data = Map<dynamic, dynamic>.from(entry.value as Map);
      if (data['status'] == 'pending') {
        list.add(FriendRequest.fromSnapshot(fromUid, uid, data));
      }
    }

    list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return list;
  }

  Future<List<Friend>> fetchFriends() async {
    final uid = _myUid;
    if (uid == null) return [];

    final snap = await _root.child('friends/$uid').get();
    if (!snap.exists || snap.value == null) return [];

    final raw = Map<dynamic, dynamic>.from(snap.value as Map);
    final friends = <Friend>[];

    for (final entry in raw.entries) {
      final friendUid = entry.key as String;
      final data = Map<dynamic, dynamic>.from(entry.value as Map);
      final profile = await _profiles.fetchProfile(friendUid);
      friends.add(Friend.fromSnapshot(friendUid, data, profile: profile));
    }

    friends.sort((a, b) => a.displayLabel.compareTo(b.displayLabel));
    return friends;
  }

  Future<void> acceptRequest(String fromUid) async {
    final myUid = _myUid;
    if (myUid == null) throw StateError('Not signed in');

    final requestSnap =
        await _root.child(DatabasePaths.friendRequest(myUid, fromUid)).get();
    if (!requestSnap.exists) {
      throw StateError('Request not found');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final sharedNoteId = DatabasePaths.sharedNoteIdForPair(myUid, fromUid);
    final sorted = [myUid, fromUid]..sort();

    final updates = <String, dynamic>{
      DatabasePaths.friend(myUid, fromUid): {
        'friendUid': fromUid,
        'since': now,
        'sharedNoteId': sharedNoteId,
      },
      DatabasePaths.friend(fromUid, myUid): {
        'friendUid': myUid,
        'since': now,
        'sharedNoteId': sharedNoteId,
      },
      DatabasePaths.sharedNote(sharedNoteId): {
        'sharedNoteId': sharedNoteId,
        'user1': sorted[0],
        'user2': sorted[1],
        'title': 'Shared note',
        'body': '',
        'createdAt': now,
        'updatedAt': now,
        'updatedBy': myUid,
      },
    };

    await _root.update(updates);
    await _root.child(DatabasePaths.friendRequest(myUid, fromUid)).remove();
  }

  Future<void> declineRequest(String fromUid) async {
    final myUid = _myUid;
    if (myUid == null) throw StateError('Not signed in');
    await _root.child(DatabasePaths.friendRequest(myUid, fromUid)).remove();
  }

  Stream<List<FriendRequest>> watchIncomingRequests() {
    final uid = _myUid;
    if (uid == null) return Stream.value([]);

    return _root.child('friendRequests/$uid').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <FriendRequest>[];
      }
      final raw = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final list = <FriendRequest>[];
      for (final entry in raw.entries) {
        final fromUid = entry.key as String;
        final data = Map<dynamic, dynamic>.from(entry.value as Map);
        if (data['status'] == 'pending') {
          list.add(FriendRequest.fromSnapshot(fromUid, uid, data));
        }
      }
      list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return list;
    });
  }
}

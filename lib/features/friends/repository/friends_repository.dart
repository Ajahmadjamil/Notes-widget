import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';
import 'package:noteswidgetapp/features/friends/model/friend_request.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';

class UserNotFoundException implements Exception {
  const UserNotFoundException();
}

class FriendsRepository {
  final UserProfileRepository _profiles = UserProfileRepository();
  SupabaseClient get _client => AppSupabase.client;

  String? get _myUid => AppSupabase.currentUserId;

  Future<UserProfile?> searchUser(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    try {
      final rows = await _client.rpc(
        'search_profile',
        params: {'p_query': q},
      );
      if (rows is! List || rows.isEmpty) return null;
      final data = Map<String, dynamic>.from(rows.first as Map);
      final uid = data['id'] as String;
      return UserProfile.fromRow(uid, data);
    } catch (e) {
      if (kDebugMode) print('search_profile failed: $e');
      return null;
    }
  }

  Future<bool> isFriend(String otherUid) async {
    final uid = _myUid;
    if (uid == null) return false;

    final row = await _client
        .from('friendships')
        .select('id')
        .eq('status', 'accepted')
        .or('and(user_id.eq.$uid,friend_id.eq.$otherUid),and(user_id.eq.$otherUid,friend_id.eq.$uid)')
        .maybeSingle();

    return row != null;
  }

  Future<FriendRequest?> getOutgoingRequest(String toUid) async {
    final uid = _myUid;
    if (uid == null) return null;

    final row = await _client
        .from('friendships')
        .select()
        .eq('user_id', uid)
        .eq('friend_id', toUid)
        .eq('status', 'pending')
        .maybeSingle();

    if (row == null) return null;
    return FriendRequest.fromRow(Map<String, dynamic>.from(row));
  }

  Future<FriendRequest?> getIncomingRequest(String fromUid) async {
    final uid = _myUid;
    if (uid == null) return null;

    final row = await _client
        .from('friendships')
        .select()
        .eq('user_id', fromUid)
        .eq('friend_id', uid)
        .eq('status', 'pending')
        .maybeSingle();

    if (row == null) return null;
    final profile = await _profiles.fetchProfile(fromUid);
    return FriendRequest.fromRow(
      Map<String, dynamic>.from(row),
      fromUsername: profile?.username,
      fromDisplayName: profile?.displayName ?? profile?.username,
    );
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

    await _client.from('friendships').insert({
      'user_id': uid,
      'friend_id': toUid,
      'status': 'pending',
    });
  }

  Future<List<FriendRequest>> fetchIncomingRequests() async {
    final uid = _myUid;
    if (uid == null) return [];

    final rows = await _client
        .from('friendships')
        .select()
        .eq('friend_id', uid)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final list = <FriendRequest>[];
    for (final raw in rows as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final fromUid = row['user_id'] as String;
      final profile = await _profiles.fetchProfile(fromUid);
      list.add(FriendRequest.fromRow(
        row,
        fromUsername: profile?.username,
        fromDisplayName: profile?.displayName ?? profile?.username,
      ));
    }
    return list;
  }

  Future<List<Friend>> fetchFriends() async {
    final uid = _myUid;
    if (uid == null) return [];

    final rows = await _client
        .from('friendships')
        .select('id, user_id, friend_id, accepted_at, created_at, shared_notes(id)')
        .eq('status', 'accepted')
        .or('user_id.eq.$uid,friend_id.eq.$uid');

    final friends = <Friend>[];
    for (final raw in rows as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final friendUid =
          row['user_id'] == uid ? row['friend_id'] as String : row['user_id'] as String;
      final profile = await _profiles.fetchProfile(friendUid);
      friends.add(Friend.fromRow(uid, row, profile: profile));
    }

    friends.sort((a, b) => a.displayLabel.compareTo(b.displayLabel));
    return friends;
  }

  Future<void> acceptRequest(String fromUid) async {
    final myUid = _myUid;
    if (myUid == null) throw StateError('Not signed in');

    final row = await _client
        .from('friendships')
        .select('id')
        .eq('user_id', fromUid)
        .eq('friend_id', myUid)
        .eq('status', 'pending')
        .maybeSingle();

    if (row == null) {
      throw StateError('Request not found');
    }

    final friendshipId = row['id'] as String;
    await _client.rpc(
      'accept_friend_request',
      params: {'p_friendship_id': friendshipId},
    );
  }

  Future<void> declineRequest(String fromUid) async {
    final myUid = _myUid;
    if (myUid == null) throw StateError('Not signed in');

    await _client
        .from('friendships')
        .delete()
        .eq('user_id', fromUid)
        .eq('friend_id', myUid)
        .eq('status', 'pending');
  }

  Stream<List<FriendRequest>> watchIncomingRequests() {
    final uid = _myUid;
    if (uid == null) return Stream.value([]);

    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .map((rows) async {
          final pending = rows
              .where((r) =>
                  r['friend_id'] == uid && r['status'] == 'pending')
              .toList();

          final list = <FriendRequest>[];
          for (final raw in pending) {
            final row = Map<String, dynamic>.from(raw);
            final fromUid = row['user_id'] as String;
            final profile = await _profiles.fetchProfile(fromUid);
            list.add(FriendRequest.fromRow(
              row,
              fromUsername: profile?.username,
              fromDisplayName: profile?.displayName ?? profile?.username,
            ));
          }
          list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          return list;
        })
        .asyncMap((event) => event);
  }
}

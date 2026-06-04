import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';
import 'package:noteswidgetapp/features/friends/model/friend_request.dart';
import 'package:noteswidgetapp/features/friends/repository/friends_repository.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';

class MyFriendsController with ChangeNotifier {
  final FriendsRepository _repo = FriendsRepository();

  final searchController = TextEditingController();

  List<Friend> friends = [];
  List<FriendRequest> incomingRequests = [];
  UserProfile? searchResult;
  String? searchStatusMessage;
  bool isLoading = false;
  bool isSearching = false;

  StreamSubscription<List<FriendRequest>>? _requestsSub;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void init() {
    loadAll();
    _requestsSub = _repo.watchIncomingRequests().listen((requests) {
      if (_disposed) return;
      incomingRequests = requests;
      _notify();
    });
  }

  Future<void> loadAll() async {
    if (_disposed) return;
    isLoading = true;
    _notify();

    try {
      friends = await _repo.fetchFriends();
      if (_disposed) return;
      incomingRequests = await _repo.fetchIncomingRequests();
    } catch (e) {
      if (!_disposed) AppConstants.showToast('Could not load friends');
    } finally {
      if (_disposed) return;
      isLoading = false;
      _notify();
    }
  }

  Future<void> searchUser() async {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      AppConstants.showToast('Enter a username or email');
      return;
    }

    isSearching = true;
    searchResult = null;
    searchStatusMessage = null;
    _notify();

    try {
      final user = await _repo.searchUser(query);
      if (user == null) {
        searchStatusMessage = 'No user found';
        searchResult = null;
      } else if (user.uid == FirebaseAuth.instance.currentUser?.uid) {
        searchResult = null;
        searchStatusMessage = 'That is your account';
      } else {
        searchResult = user;
        searchStatusMessage = null;

        if (await _repo.isFriend(user.uid)) {
          searchStatusMessage = 'Already friends';
        } else if (await _repo.getOutgoingRequest(user.uid) != null) {
          searchStatusMessage = 'Friend request already sent';
        } else if (await _repo.getIncomingRequest(user.uid) != null) {
          searchStatusMessage = 'They sent you a request — see Requests below';
        }
      }
    } catch (e) {
      AppConstants.showToast('Search failed');
    } finally {
      if (_disposed) return;
      isSearching = false;
      _notify();
    }
  }

  Future<void> sendRequestToSearchResult() async {
    if (searchResult == null) return;

    try {
      await _repo.sendFriendRequest(searchResult!.uid);
      searchStatusMessage = 'Friend request sent';
      AppConstants.showToast('Request sent');
      _notify();
    } on StateError catch (e) {
      searchStatusMessage = e.message;
      AppConstants.showToast(e.message);
      _notify();
    } catch (e) {
      AppConstants.showToast('Could not send request');
    }
  }

  Future<void> acceptRequest(FriendRequest request) async {
    try {
      await _repo.acceptRequest(request.fromUid);
      await loadAll();
      AppConstants.showToast('Friend added');
    } catch (e) {
      AppConstants.showToast('Could not accept request');
    }
  }

  Future<void> declineRequest(FriendRequest request) async {
    try {
      await _repo.declineRequest(request.fromUid);
      incomingRequests =
          incomingRequests.where((r) => r.fromUid != request.fromUid).toList();
      _notify();
    } catch (e) {
      AppConstants.showToast('Could not decline request');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestsSub?.cancel();
    searchController.dispose();
    super.dispose();
  }
}

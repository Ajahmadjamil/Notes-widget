import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/foundation.dart';

import 'package:noteswidgetapp/core/firebase/database_paths.dart';

import 'package:noteswidgetapp/core/firebase/firebase_database_service.dart';

import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';

import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';



class SharedNoteAccessDeniedException implements Exception {

  const SharedNoteAccessDeniedException();

}



class SharedNoteRepository {

  DatabaseReference get _root => FirebaseDatabaseService.rootRef();

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;



  /// Loads the latest note from RTDB, resolving ID from friend link if needed.

  Future<SharedNote?> resolveAndFetch({

    required String preferredId,

    String? friendUid,

  }) async {

    final ids = await _candidateNoteIds(preferredId: preferredId, friendUid: friendUid);



    for (final id in ids) {

      try {

        final note = await fetchOnce(id);

        if (note != null) return note;

      } on SharedNoteAccessDeniedException {

        if (kDebugMode) print('Shared note access denied for $id');

      }

    }



    if (friendUid != null && _myUid != null) {
      final fallbackId = ids.isNotEmpty
          ? ids.first
          : DatabasePaths.sharedNoteIdForPair(_myUid!, friendUid);
      return _ensureSharedNoteForFriend(_myUid!, friendUid, fallbackId);
    }



    return null;

  }



  Future<List<String>> _candidateNoteIds({

    required String preferredId,

    String? friendUid,

  }) async {

    final uid = _myUid;

    final ids = <String>[];

    // Prefer canonical pair id for this friend so we never load another friend's note.
    if (uid != null && friendUid != null) {
      ids.add(DatabasePaths.sharedNoteIdForPair(uid, friendUid));

      final friendSnap = await _root.child(DatabasePaths.friend(uid, friendUid)).get();
      if (friendSnap.exists && friendSnap.value != null) {
        final data = Map<dynamic, dynamic>.from(friendSnap.value as Map);
        final fromFriend = data['sharedNoteId'] as String? ?? '';
        if (fromFriend.isNotEmpty) ids.add(fromFriend);
      }
    }

    if (preferredId.isNotEmpty) ids.add(preferredId);

    return ids.toSet().toList();

  }



  Future<SharedNote?> _ensureSharedNoteForFriend(

    String myUid,

    String friendUid,

    String sharedNoteId,

  ) async {

    final friendSnap = await _root.child(DatabasePaths.friend(myUid, friendUid)).get();

    if (!friendSnap.exists) return null;



    final existing = await _root.child(DatabasePaths.sharedNote(sharedNoteId)).get();

    if (existing.exists && existing.value != null) {

      return fetchOnce(sharedNoteId);

    }



    final now = DateTime.now().millisecondsSinceEpoch;

    final sorted = [myUid, friendUid]..sort();

    final data = <String, dynamic>{

      'sharedNoteId': sharedNoteId,

      'user1': sorted[0],

      'user2': sorted[1],

      'title': 'Shared note',

      'body': '',

      'createdAt': now,

      'updatedAt': now,

      'updatedBy': myUid,

    };



    await _root.child(DatabasePaths.sharedNote(sharedNoteId)).set(data);



    final updates = <String, dynamic>{

      '${DatabasePaths.friend(myUid, friendUid)}/sharedNoteId': sharedNoteId,

      '${DatabasePaths.friend(friendUid, myUid)}/sharedNoteId': sharedNoteId,

    };

    await _root.update(updates);



    if (kDebugMode) print('Created missing shared note at $sharedNoteId');

    return SharedNote.fromSnapshot(sharedNoteId, data);

  }



  Future<SharedNote?> fetchOnce(String sharedNoteId) async {

    final snap = await _root.child(DatabasePaths.sharedNote(sharedNoteId)).get();

    if (!snap.exists || snap.value == null) return null;

    final note = SharedNote.fromSnapshot(

      sharedNoteId,

      Map<dynamic, dynamic>.from(snap.value as Map),

    );

    _assertAccess(note);

    return note;

  }



  Stream<SharedNote?> watch(String sharedNoteId) {

    return _root.child(DatabasePaths.sharedNote(sharedNoteId)).onValue.map((event) {

      if (!event.snapshot.exists || event.snapshot.value == null) {

        return null;

      }

      final note = SharedNote.fromSnapshot(

        sharedNoteId,

        Map<dynamic, dynamic>.from(event.snapshot.value as Map),

      );

      try {

        _assertAccess(note);

      } on SharedNoteAccessDeniedException {

        return null;

      }

      return note;

    });

  }



  Future<void> save({

    required String sharedNoteId,

    required String title,

    required String body,

  }) async {

    final uid = _myUid;

    if (uid == null) throw StateError('Not signed in');



    final snap = await _root.child(DatabasePaths.sharedNote(sharedNoteId)).get();

    if (!snap.exists || snap.value == null) {

      throw StateError('Shared note not found');

    }



    final existing = SharedNote.fromSnapshot(

      sharedNoteId,

      Map<dynamic, dynamic>.from(snap.value as Map),

    );

    _assertAccess(existing);



    final now = DateTime.now().millisecondsSinceEpoch;

    final trimmedTitle = title.trim().isEmpty ? 'Shared note' : title.trim();



    await _root.child(DatabasePaths.sharedNote(sharedNoteId)).update({

      'title': trimmedTitle,

      'body': body,

      'updatedAt': now,

      'updatedBy': uid,

    });



    await SharedNoteWidgetCache.update(

      sharedNoteId: sharedNoteId,

      title: trimmedTitle,

      body: body,

      updatedAt: now,

    );

  }



  void _assertAccess(SharedNote note) {

    final uid = _myUid;

    if (uid == null || !note.involvesUser(uid)) {

      throw const SharedNoteAccessDeniedException();

    }

  }

}


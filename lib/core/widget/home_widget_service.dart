import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/features/friends/repository/friends_repository.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const String titleKey = 'shared_note_title';
  static const String bodyKey = 'shared_note_body';
  static const String noteIdKey = 'active_shared_note_id';
  static const String friendLabelKey = 'active_friend_label';

  static const String androidProviderName = 'SharedNoteWidgetProvider';
  static const String qualifiedAndroidName =
      'com.ahmadjamil.noteswidgetapp.SharedNoteWidgetProvider';

  static const int _maxBodyLength = 280;

  static Future<void> updateDisplay({
    required String title,
    required String body,
    String? sharedNoteId,
    String? friendLabel,
  }) async {
    final displayTitle = title.trim().isEmpty ? 'Shared note' : title.trim();
    var displayBody = body.trim();
    if (displayBody.isEmpty) {
      displayBody = 'Open the app to write together';
    } else if (displayBody.length > _maxBodyLength) {
      displayBody = '${displayBody.substring(0, _maxBodyLength)}…';
    }

    await HomeWidget.saveWidgetData<String>(titleKey, displayTitle);
    await HomeWidget.saveWidgetData<String>(bodyKey, displayBody);
    if (sharedNoteId != null && sharedNoteId.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>(noteIdKey, sharedNoteId);
    }
    if (friendLabel != null && friendLabel.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>(friendLabelKey, friendLabel);
    }

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
        name: androidProviderName,
        qualifiedAndroidName: qualifiedAndroidName,
      );
    }
  }

  static Future<void> syncFromCache() async {
    final cached = await SharedNoteWidgetCache.read();
    if (cached == null) {
      await updateDisplay(
        title: 'Notes Widget',
        body: 'Sign in and add a friend to see your shared note here',
      );
      return;
    }
    await updateDisplay(
      title: cached['title'] as String? ?? '',
      body: cached['body'] as String? ?? '',
      sharedNoteId: cached['sharedNoteId'] as String?,
      friendLabel: cached['friendLabel'] as String?,
    );
  }

  static Future<void> syncOnAppLaunch() async {
    final cached = await SharedNoteWidgetCache.read();
    if (cached != null) {
      await syncFromCache();
      return;
    }

    try {
      final friends = await FriendsRepository().fetchFriends();
      if (friends.isEmpty || friends.first.sharedNoteId.isEmpty) {
        await updateDisplay(
          title: 'Notes Widget',
          body: 'Add a friend to show your shared note on the widget',
        );
        return;
      }

      final f = friends.first;
      final note = await SharedNoteRepository().fetchOnce(f.sharedNoteId);
      if (note == null) {
        await syncFromCache();
        return;
      }

      await ActiveWidgetNoteService.setActiveFriendNote(
        sharedNoteId: note.sharedNoteId,
        friendLabel: f.displayLabel,
      );
    } catch (e) {
      if (kDebugMode) print('HomeWidget syncOnAppLaunch: $e');
      await updateDisplay(
        title: 'Notes Widget',
        body: 'Open the app to load your shared note',
      );
    }
  }

  static Future<bool> isPinSupported() async {
    if (!Platform.isAndroid) return false;
    return await HomeWidget.isRequestPinWidgetSupported() ?? false;
  }

  /// Shows the system "add to home screen" sheet (user must confirm once on Android).
  static Future<void> requestPinWidget() async {
    if (!Platform.isAndroid) return;
    await syncFromCache();
    await HomeWidget.requestPinWidget(
      name: androidProviderName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _refreshAllWidgets();
  }

  static Future<void> _refreshAllWidgets() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.updateWidget(
      name: androidProviderName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }
}

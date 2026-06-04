import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/firebase/database_paths.dart';
import 'package:noteswidgetapp/core/firebase/firebase_database_service.dart';
import 'package:noteswidgetapp/core/sync/widget_push_handler.dart';
import 'package:noteswidgetapp/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

/// FCM: token → RTDB, visible shared-note notifications, widget sync.
class FirebaseNotificationService {
  FirebaseNotificationService._();

  static const String _widgetSyncType = WidgetPushHandler.dataType;
  static const String _sharedNoteChannelId = 'notes_shared_note_updates';
  static const String _sharedNoteChannelName = 'Shared note updates';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<String>? _tokenRefreshSub;
  static bool _foregroundListenersAttached = false;
  static bool _localNotificationsReady = false;

  @pragma('vm:entry-point')
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _ensureLocalNotifications();
    await _handleRemoteMessage(message, isBackground: true);
  }

  static Future<void> initialize() async {
    await _requestPermissions();
    await _ensureLocalNotifications();

    if (!_foregroundListenersAttached) {
      _foregroundListenersAttached = true;

      _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

      FirebaseMessaging.onMessage.listen((message) async {
        await _handleRemoteMessage(message, isBackground: false);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        if (kDebugMode) print('Notification opened app: ${message.data}');
        await WidgetPushHandler.applyFromData(message.data);
      });
    }

    await _messaging.setAutoInitEnabled(true);
    await syncTokenToDatabase();
  }

  static Future<void> syncTokenToDatabase() async {
    try {
      final token = await _messaging.getToken();
      AppConstants.deviceToken = token ?? '';
      if (token != null) {
        await _saveTokenToDatabase(token);
      } else if (kDebugMode) {
        print('FCM: getToken returned null');
      }
    } catch (e) {
      AppConstants.deviceToken = '';
      if (kDebugMode) print('FCM getToken error: $e');
    }
  }

  static Future<void> clearTokenOnSignOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseDatabaseService.rootRef().child(DatabasePaths.user(uid)).update({
          'fcmToken': null,
          'fcmUpdatedAt': null,
        });
      } catch (e) {
        if (kDebugMode) print('FCM token clear failed: $e');
      }
    }
    try {
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) print('FCM deleteToken: $e');
    }
    AppConstants.deviceToken = '';
  }

  static Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('Notification permission: ${settings.authorizationStatus}');
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _ensureLocalNotifications() async {
    if (_localNotificationsReady) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _sharedNoteChannelId,
          _sharedNoteChannelName,
          description: 'When a friend updates your shared note',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }

    _localNotificationsReady = true;
  }

  static Future<void> _handleRemoteMessage(
    RemoteMessage message, {
    required bool isBackground,
  }) async {
    if (kDebugMode) {
      print('FCM ${isBackground ? "background" : "foreground"}: ${message.data}');
    }

    if (message.data['type'] == _widgetSyncType) {
      await WidgetPushHandler.applyFromData(message.data);

      final title = message.notification?.title ??
          message.data['notificationTitle'] as String? ??
          'Shared note updated';
      final body = message.notification?.body ??
          message.data['notificationBody'] as String? ??
          _previewFromData(message.data);

      // Foreground: FCM does not always show a banner — use local notification.
      // Background with data-only: show local; with notification payload OS shows it too.
      if (!isBackground || message.notification == null) {
        await _showSharedNoteNotification(title, body);
      }
      return;
    }

    if (message.notification != null) {
      await _showSharedNoteNotification(
        message.notification!.title,
        message.notification!.body,
      );
      return;
    }

    final title = message.data['notificationTitle'] as String?;
    final body = message.data['notificationBody'] as String?;
    if (title != null || body != null) {
      await _showSharedNoteNotification(title, body);
    }
  }

  static String _previewFromData(Map<String, dynamic> data) {
    final noteBody = (data['body'] as String? ?? '').trim();
    if (noteBody.isEmpty) return 'Your friend updated the shared note';
    if (noteBody.length > 80) return '${noteBody.substring(0, 80)}…';
    return noteBody;
  }

  static Future<void> _showSharedNoteNotification(String? title, String? body) async {
    await _ensureLocalNotifications();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _sharedNoteChannelId,
        _sharedNoteChannelName,
        channelDescription: 'When a friend updates your shared note',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title ?? 'Shared note updated',
      body ?? 'Your friend updated the shared note',
      details,
    );
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseDatabaseService.rootRef().child(DatabasePaths.user(uid)).update({
        'fcmToken': token,
        'fcmUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      if (kDebugMode) print('FCM token saved for $uid');
    } catch (e) {
      if (kDebugMode) print('FCM token write failed: $e');
    }
  }
}

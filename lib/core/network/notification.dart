import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/sync/widget_push_handler.dart';
import 'package:noteswidgetapp/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

/// Silent FCM — widget sync only, no visible notifications.
class PushNotificationService {
  PushNotificationService._();

  static const String _widgetSyncType = WidgetPushHandler.dataType;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenRefreshSub;
  static bool _foregroundListenersAttached = false;
  static bool _initialized = false;
  static bool _firebaseReady = false;

  @pragma('vm:entry-point')
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    await _ensureFirebaseInitialized();
    try {
      await AppSupabase.initialize();
    } catch (e) {
      if (kDebugMode) print('Background Supabase init: $e');
    }
    await _handleRemoteMessage(message, isBackground: true);
  }

  static Future<void> initialize() async {
    if (_initialized) {
      await syncTokenToDatabase();
      return;
    }
    _initialized = true;

    await _ensureFirebaseInitialized();
    await _requestPermissions();

    if (!_foregroundListenersAttached) {
      _foregroundListenersAttached = true;

      _tokenRefreshSub ??=
          _messaging.onTokenRefresh.listen(_saveTokenToSupabase);

      FirebaseMessaging.onMessage.listen((message) async {
        await _handleRemoteMessage(message, isBackground: false);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        if (kDebugMode) print('FCM opened app: ${message.data}');
        await WidgetPushHandler.applyFromData(message.data);
      });
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) print('FCM initial message: ${initialMessage.data}');
      await WidgetPushHandler.applyFromData(initialMessage.data);
    }

    await _messaging.setAutoInitEnabled(true);
    await syncTokenToDatabase();
  }

  static Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseReady) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _firebaseReady = true;
  }

  static Future<void> syncTokenToDatabase() async {
    if (AppSupabase.currentUserId == null) return;

    try {
      final token = await _messaging.getToken();
      AppConstants.deviceToken = token ?? '';
      if (token != null) {
        await _saveTokenToSupabase(token);
      } else if (kDebugMode) {
        print('FCM: getToken returned null');
      }
    } catch (e) {
      AppConstants.deviceToken = '';
      if (kDebugMode) print('FCM getToken error: $e');
    }
  }

  static Future<void> clearTokenOnSignOut() async {
    final uid = AppSupabase.currentUserId;
    if (uid != null) {
      try {
        await AppSupabase.client.from('profiles').update({
          'fcm_token': null,
          'fcm_token_updated_at': null,
        }).eq('id', uid);
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
      alert: false,
      badge: false,
      sound: false,
    );

    if (kDebugMode) {
      print('FCM permission (silent): ${settings.authorizationStatus}');
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
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
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final uid = AppSupabase.currentUserId;
    if (uid == null) return;

    try {
      await AppSupabase.client.from('profiles').update({
        'fcm_token': token,
        'fcm_token_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);
      if (kDebugMode) print('FCM token saved for $uid');
    } catch (e) {
      if (kDebugMode) print('FCM token write failed: $e');
    }
  }
}

typedef FirebaseNotificationService = PushNotificationService;

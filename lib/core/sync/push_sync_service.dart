import 'package:noteswidgetapp/core/network/notification.dart';

class PushSyncService {
  PushSyncService._();

  static Future<void> ensureInitialized() =>
      PushNotificationService.initialize();

  static Future<void> syncFcmTokenForCurrentUser() =>
      PushNotificationService.syncTokenToDatabase();

  static Future<void> clearTokenOnSignOut() =>
      PushNotificationService.clearTokenOnSignOut();

  static Future<void> dispose() => PushNotificationService.dispose();
}

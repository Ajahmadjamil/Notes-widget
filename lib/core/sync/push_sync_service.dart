import 'package:noteswidgetapp/core/network/notification.dart';

/// Delegates to [FirebaseNotificationService] (initialized from main).
class PushSyncService {
  PushSyncService._();

  static Future<void> initialize() => FirebaseNotificationService.initialize();

  static Future<void> syncFcmTokenForCurrentUser() =>
      FirebaseNotificationService.syncTokenToDatabase();

  static Future<void> clearTokenOnSignOut() =>
      FirebaseNotificationService.clearTokenOnSignOut();

  static Future<void> dispose() => FirebaseNotificationService.dispose();
}

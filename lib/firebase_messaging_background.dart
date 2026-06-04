import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:noteswidgetapp/core/network/notification.dart';

/// Top-level background handler (required by Firebase Messaging).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) {
  return PushNotificationService.backgroundMessageHandler(message);
}

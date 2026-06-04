import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:noteswidgetapp/core/firebase/google_auth_config.dart';
import 'package:noteswidgetapp/firebase_options.dart';

class AppFirebase {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await GoogleSignIn.instance.initialize(
      serverClientId: GoogleAuthConfig.webClientId,
    );
    _initialized = true;
  }
}

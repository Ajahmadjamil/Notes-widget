import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseDatabaseService {
  FirebaseDatabaseService._();

  static const String databaseUrl =
      'https://noteswidget-debc2-default-rtdb.firebaseio.com';

  static FirebaseDatabase? _database;

  static FirebaseDatabase get instance {
    _database ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
    return _database!;
  }

  static DatabaseReference rootRef() => instance.ref();
}

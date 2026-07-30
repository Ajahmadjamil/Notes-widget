import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:noteswidgetapp/core/navigation/deep_link_handler.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/theme/app_theme.dart';
import 'package:noteswidgetapp/core/theme/theme_provider.dart';
import 'package:noteswidgetapp/features/splash/controller.dart';
import 'package:noteswidgetapp/features/splash/view.dart';
import 'package:noteswidgetapp/firebase_messaging_background.dart';
import 'package:noteswidgetapp/firebase_options.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppThemeProvider.instance.initialize();

  await AppSupabase.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await DeepLinkHandler.captureWidgetLaunchUri();

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final palette = AppThemeProvider.instance.palette;
    final overlay = systemOverlayForPalette(palette);
    SystemChrome.setSystemUIOverlayStyle(overlay);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashController()),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Notes Widget',
          theme: buildAppTheme(palette),
          builder: (context, child) {
            return ColoredBox(
              color: palette.background,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

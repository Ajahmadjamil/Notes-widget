import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteswidgetapp/core/firebase/app_firebase.dart';
import 'package:noteswidgetapp/core/navigation/deep_link_handler.dart';
import 'package:noteswidgetapp/core/network/notification.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/features/splash/controller.dart';
import 'package:noteswidgetapp/features/splash/view.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFirebase.initialize();

  FirebaseMessaging.onBackgroundMessage(
    FirebaseNotificationService.backgroundMessageHandler,
  );

  await FirebaseNotificationService.initialize();
  await DeepLinkHandler.captureWidgetLaunchUri();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Notes Widget',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: AppColors.bgColor,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.bgColor,
            foregroundColor: AppColors.textColor,
            elevation: 0,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor,
            brightness: Brightness.light,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

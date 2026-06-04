import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/navigation/deep_link_handler.dart';
import 'package:noteswidgetapp/core/sync/push_sync_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_realtime_service.dart';
import 'package:noteswidgetapp/core/widget/home_widget_service.dart';
import 'package:noteswidgetapp/core/widget/widget_setup_helper.dart';
import 'package:noteswidgetapp/features/authentication/signin/repository.dart';
import 'package:noteswidgetapp/features/authentication/signin/view.dart';
import 'package:noteswidgetapp/features/friends/my_friends/view.dart';
import 'package:noteswidgetapp/features/notes/my_notes/view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await PushSyncService.initialize();
    await HomeWidgetService.syncOnAppLaunch();
    await SharedNoteRealtimeService.instance.start();
    WidgetSetupHelper.requestPinIfNeeded();

    if (!mounted) return;
    DeepLinkHandler.listenForWidgetClicks(context);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await DeepLinkHandler.openPendingSharedNote(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PushSyncService.syncFcmTokenForCurrentUser();
      SharedNoteRealtimeService.instance.refresh();
      HomeWidgetService.syncFromCache();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SharedNoteRealtimeService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notes Widget'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Notes'),
              Tab(text: 'My Friends'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => WidgetSetupHelper.addWidgetToHomeScreen(context),
              child: const Text('Add widget'),
            ),
            TextButton(
              onPressed: () => _signOut(context),
              child: const Text('Sign out'),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            MyNotesTab(),
            MyFriendsTab(),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await SharedNoteRealtimeService.instance.stop();
    await PushSyncService.clearTokenOnSignOut();
    await PushSyncService.dispose();
    await SignInRepository().signOut();
    if (!context.mounted) return;
    AppConstants.showToast('Signed out');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

typedef HomePlaceholderScreen = HomeScreen;

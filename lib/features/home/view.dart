import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteswidgetapp/core/navigation/deep_link_handler.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_background.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_bottom_nav.dart';
import 'package:noteswidgetapp/core/shared/widgets/glass_confirm_dialog.dart';
import 'package:noteswidgetapp/core/sync/push_sync_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_inbound_sync.dart';
import 'package:noteswidgetapp/core/sync/shared_note_poll_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_realtime_service.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/widget/home_widget_service.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';
import 'package:noteswidgetapp/features/friends/my_friends/view.dart';
import 'package:noteswidgetapp/features/home/home_tab_view.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/navigation/note_editor_launcher.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_type_picker_sheet.dart';
import 'package:noteswidgetapp/features/profile/profile_tab/view.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _navIndex = 0;
  late final MyFriendsController _friendsController;
  late final MyNotesController _notesController;
  final GlobalKey<HomeTabViewState> _homeTabKey = GlobalKey();
  bool _exitDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _friendsController = MyFriendsController()..init();
    _notesController = MyNotesController()..loadNotes();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await PushSyncService.ensureInitialized();
    await HomeWidgetService.syncOnAppLaunch();
    await SharedNoteRealtimeService.instance.start();
    SharedNotePollService.instance.start();

    if (!mounted) return;
    DeepLinkHandler.listenForWidgetClicks(context);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await DeepLinkHandler.openPendingSharedNote(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        SharedNotePollService.instance.resume();
        PushSyncService.syncFcmTokenForCurrentUser();
        SharedNoteRealtimeService.instance.refresh();
        SharedNoteInboundSync.syncActiveWidgetNote();
        HomeWidgetService.syncFromCache();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        SharedNotePollService.instance.pause();
        break;
      case AppLifecycleState.detached:
        SharedNotePollService.instance.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SharedNoteRealtimeService.instance.stop();
    _friendsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _showFab =>
      _navIndex == 0 &&
      (_homeTabKey.currentState?.isMineSelected ?? true) &&
      !_notesController.selectionMode;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmExitApp();
      },
      child: ChangeNotifierProvider.value(
        value: _friendsController,
        child: Scaffold(
          backgroundColor: AppColors.bgColor,
          resizeToAvoidBottomInset: true,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 20, color: AppColors.selectedColor),
                const SizedBox(width: 8),
                Text('SyncNotes', style: getBoldStyle(fontSize: 18, color: AppColors.textColor)),
              ],
            ),
          ),
          body: AppBackground(
            child: IndexedStack(
              index: _navIndex,
              children: [
                HomeTabView(
                  key: _homeTabKey,
                  notesController: _notesController,
                  onSegmentChanged: () => setState(() {}),
                ),
                MyFriendsTab(controller: _friendsController),
                const ProfileTab(),
              ],
            ),
          ),
          floatingActionButton: ListenableBuilder(
            listenable: _notesController,
            builder: (context, _) {
              if (!_showFab) return const SizedBox.shrink();
              return FloatingActionButton(
                onPressed: _createNote,
                backgroundColor: AppColors.primaryColor,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: ListenableBuilder(
            listenable: _friendsController,
            builder: (context, _) => AppBottomNav(
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
              badgeIndex: 1,
              badgeCount: _friendsController.incomingRequests.length,
              iconOnly: true,
              items: const [
                AppBottomNavItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Home',
                ),
                AppBottomNavItem(
                  icon: Icons.rocket_launch_outlined,
                  activeIcon: Icons.rocket_launch_rounded,
                  label: 'Shared',
                ),
                AppBottomNavItem(
                  icon: Icons.fingerprint_outlined,
                  activeIcon: Icons.fingerprint_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExitApp() async {
    if (_exitDialogOpen || !mounted) return;
    _exitDialogOpen = true;
    try {
      final shouldExit = await GlassConfirmDialog.show(
        context,
        title: 'Close SyncNotes?',
        message: 'Are you sure you want to exit the app?',
        confirmLabel: 'Exit',
        cancelLabel: 'Stay',
        icon: Icons.logout_rounded,
        confirmColor: AppColors.primaryColor,
      );
      if (shouldExit && mounted) {
        SystemNavigator.pop();
      }
    } finally {
      _exitDialogOpen = false;
    }
  }

  Future<void> _createNote() async {
    final type = await NoteTypePickerSheet.show(context);
    if (!mounted || type == null) return;

    if (type == NoteType.drawing && !SchemaCapabilities.drawingNotesSupported) {
      AppConstants.showToast(
        'Run RUN_IN_SUPABASE_SQL_EDITOR.sql in Supabase to enable handwriting sync',
      );
    }
    if (type == NoteType.document &&
        !SchemaCapabilities.documentNotesSupported) {
      AppConstants.showToast(
        'Run RUN_DOCUMENT_NOTES_SQL.sql in Supabase to enable document sync',
      );
    }

    final note = await _notesController.createNote(noteType: type);
    if (!mounted) return;
    await NoteEditorLauncher.openPersonal(context, note);
    await _notesController.loadNotes();
  }
}

typedef HomePlaceholderScreen = HomeScreen;

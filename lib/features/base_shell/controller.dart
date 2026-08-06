import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/navigation/deep_link_handler.dart';
import 'package:noteswidgetapp/core/navigation/note_editor_launcher.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_type_picker_sheet.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:noteswidgetapp/core/sync/push_sync_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_inbound_sync.dart';
import 'package:noteswidgetapp/core/sync/shared_note_poll_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_realtime_service.dart';
import 'package:noteswidgetapp/core/widget/home_widget_service.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';
import 'package:noteswidgetapp/features/home/controller.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';

/// Owns bottom-nav index, tab controllers, sync bootstrap, and create-note flow.
class BaseShellController with ChangeNotifier, WidgetsBindingObserver {
  BaseShellController() {
    friendsController = MyFriendsController()..init();
    notesController = MyNotesController()..loadNotes();
    homeTabController = HomeTabController()..init();
    notesController.addListener(_onChildChanged);
    friendsController.addListener(_onChildChanged);
    homeTabController.addListener(_onChildChanged);
  }

  late final MyFriendsController friendsController;
  late final MyNotesController notesController;
  late final HomeTabController homeTabController;

  int navIndex = 0;
  bool exitDialogOpen = false;
  bool _disposed = false;

  bool get showFab =>
      navIndex == 0 &&
      homeTabController.isMineSelected &&
      !notesController.selectionMode;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    bootstrap();
  }

  Future<void> bootstrap() async {
    await PushSyncService.ensureInitialized();
    await HomeWidgetService.syncOnAppLaunch();
    await SharedNoteRealtimeService.instance.start();
    SharedNotePollService.instance.start();
  }

  /// Deep links need a [BuildContext]; call after first frame from the view.
  Future<void> handleDeepLinks(BuildContext context) async {
    DeepLinkHandler.listenForWidgetClicks(context);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    await DeepLinkHandler.openPendingSharedNote(context);
  }

  void setNavIndex(int index) {
    if (navIndex == index) return;
    navIndex = index;
    _notify();
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

  Future<void> createNote(BuildContext context) async {
    final type = await NoteTypePickerSheet.show(context);
    if (!context.mounted || type == null) return;

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

    final note = await notesController.createNote(noteType: type);
    if (!context.mounted) return;
    await NoteEditorLauncher.openPersonal(context, note);
    await notesController.loadNotes();
  }

  void _onChildChanged() => _notify();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    SharedNoteRealtimeService.instance.stop();
    notesController.removeListener(_onChildChanged);
    friendsController.removeListener(_onChildChanged);
    homeTabController.removeListener(_onChildChanged);
    friendsController.dispose();
    notesController.dispose();
    homeTabController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_background.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_bottom_nav.dart';
import 'package:noteswidgetapp/core/shared/widgets/glass_confirm_dialog.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/base_shell/controller.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';
import 'package:noteswidgetapp/features/friends/my_friends/view.dart';
import 'package:noteswidgetapp/features/home/controller.dart';
import 'package:noteswidgetapp/features/home/view.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';
import 'package:noteswidgetapp/features/profile/profile_tab/view.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// App shell: app bar, tab stack, FAB, and bottom navigation.
class BaseShellScreen extends StatefulWidget {
  const BaseShellScreen({super.key});

  @override
  State<BaseShellScreen> createState() => _BaseShellScreenState();
}

class _BaseShellScreenState extends State<BaseShellScreen> {
  late final BaseShellController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BaseShellController()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.handleDeepLinks(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BaseShellController>.value(value: _controller),
        ChangeNotifierProvider<MyFriendsController>.value(
          value: _controller.friendsController,
        ),
        ChangeNotifierProvider<MyNotesController>.value(
          value: _controller.notesController,
        ),
        ChangeNotifierProvider<HomeTabController>.value(
          value: _controller.homeTabController,
        ),
      ],
      child: const _BaseShellBody(),
    );
  }
}

class _BaseShellBody extends StatelessWidget {
  const _BaseShellBody();

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<BaseShellController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmExitApp(context, shell);
      },
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
              Icon(
                Icons.grid_view_rounded,
                size: 20,
                color: AppColors.selectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                'SyncNotes',
                style: getBoldStyle(fontSize: 18, color: AppColors.textColor),
              ),
            ],
          ),
        ),
        body: AppBackground(
          child: IndexedStack(
            index: shell.navIndex,
            children: [
              HomeTabView(notesController: shell.notesController),
              MyFriendsTab(controller: shell.friendsController),
              const ProfileTab(),
            ],
          ),
        ),
        floatingActionButton: shell.showFab
            ? FloatingActionButton(
                onPressed: () => shell.createNote(context),
                backgroundColor: AppColors.primaryColor,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AppBottomNav(
          currentIndex: shell.navIndex,
          onTap: shell.setNavIndex,
          badgeIndex: 1,
          badgeCount: shell.friendsController.incomingRequests.length,
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
    );
  }

  Future<void> _confirmExitApp(
    BuildContext context,
    BaseShellController shell,
  ) async {
    if (shell.exitDialogOpen || !context.mounted) return;
    shell.exitDialogOpen = true;
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
      if (shouldExit && context.mounted) {
        SystemNavigator.pop();
      }
    } finally {
      shell.exitDialogOpen = false;
    }
  }
}

/// Backward-compatible alias used by auth / onboarding navigation.
typedef HomeScreen = BaseShellScreen;
typedef HomePlaceholderScreen = BaseShellScreen;

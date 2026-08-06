import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/segment_toggle.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/home/controller.dart';
import 'package:noteswidgetapp/features/home/widgets/mine_panel.dart';
import 'package:noteswidgetapp/features/home/widgets/shared_notes_panel.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';
import 'package:provider/provider.dart';

class HomeTabView extends StatelessWidget {
  final MyNotesController notesController;

  const HomeTabView({
    super.key,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final homeTab = context.watch<HomeTabController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: getBoldStyle(
                      fontSize: 28,
                      color: AppColors.textColor,
                    ),
                    children: [
                      const TextSpan(text: 'Welcome '),
                      TextSpan(
                        text: homeTab.userName.isEmpty ? '…' : homeTab.userName,
                        style: getBoldStyle(
                          fontSize: 28,
                          color: AppColors.selectedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "What's in your mind",
                  style: getRegularStyle(
                    fontSize: 12,
                    color: AppColors.textColor2,
                  ).copyWith(letterSpacing: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentToggle(
            selectedIndex: homeTab.segment,
            onChanged: homeTab.setSegment,
            labels: const ['MINE', 'SHARED'],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: homeTab.isMineSelected
                ? MinePanel(
                    controller: notesController,
                    key: const ValueKey('mine'),
                  )
                : const SharedNotesPanel(key: ValueKey('shared')),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';

class EmptySearch extends StatelessWidget {
  const EmptySearch({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: AppContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.textColor2,
            ),
            const SizedBox(height: 12),
            Text(
              'No matching notes',
              style: getSemiBoldStyle(color: AppColors.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term.',
              textAlign: TextAlign.center,
              style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyMine extends StatelessWidget {
  final bool isOffline;

  const EmptyMine({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: AppContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 40,
              color: AppColors.textColor2,
            ),
            const SizedBox(height: 12),
            Text(
              'No notes yet',
              style: getSemiBoldStyle(color: AppColors.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              isOffline
                  ? 'Offline — new notes sync when online.'
                  : 'Tap + to create your first note.',
              textAlign: TextAlign.center,
              style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
            ),
          ],
        ),
      ),
    );
  }
}

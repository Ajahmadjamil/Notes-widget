import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';

class NoteTypePickerSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const NoteTypePickerSheet({
    super.key,
    this.title = 'Create new',
    this.subtitle = 'Choose how you want to capture this note',
  });

  static Future<NoteType?> show(
    BuildContext context, {
    String title = 'Create new',
    String subtitle = 'Choose how you want to capture this note',
  }) {
    return showModalBottomSheet<NoteType>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.secondaryColor.withValues(alpha: 0.35),
      builder: (_) => NoteTypePickerSheet(title: title, subtitle: subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      slideOffset: 32,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppContainer(
              borderRadius: 28,
              enableGlass: false,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: getBoldStyle(
                      fontSize: 20,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: getRegularStyle(
                      fontSize: 13,
                      color: AppColors.textColor2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _OptionCard(
                    icon: Icons.notes_rounded,
                    title: 'Text',
                    subtitle: 'Type with keyboard — like you do now',
                    onTap: () => Navigator.pop(context, NoteType.text),
                  ),
                  const SizedBox(height: 10),
                  _OptionCard(
                    icon: Icons.draw_rounded,
                    title: 'Note',
                    subtitle: 'Handwrite on a canvas with your finger',
                    isPrimary: true,
                    onTap: () => Navigator.pop(context, NoteType.drawing),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AppContainer(
        borderRadius: 18,
        isHighlighted: isPrimary,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPrimary ? AppColors.selectedColor : AppColors.textColor2,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: getSemiBoldStyle(
                      fontSize: 15,
                      color: AppColors.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: getRegularStyle(
                      fontSize: 12,
                      color: AppColors.textColor2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textColor2,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

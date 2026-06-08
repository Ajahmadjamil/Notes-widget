import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/app_theme_palette.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/theme/theme_provider.dart';

/// Bottom sheet for one-tap theme selection with Phoenix restart.
class ThemePickerSheet extends StatelessWidget {
  final BuildContext parentContext;

  const ThemePickerSheet({super.key, required this.parentContext});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemePickerSheet(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = AppThemeProvider.instance.themeId;

    return AppContainer(
      borderRadius: 24,
      enableGlass: false,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textColor2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Change App Theme',
              style: getBoldStyle(fontSize: 18, color: AppColors.textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a theme to apply instantly',
              style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.6,
              ),
              itemCount: AppThemeId.values.length,
              itemBuilder: (context, index) {
                final id = AppThemeId.values[index];
                final palette = AppThemePalettes.forId(id);
                final isSelected = id == current;

                return _ThemeOptionTile(
                  palette: palette,
                  isSelected: isSelected,
                  onTap: () async {
                    Navigator.pop(context);
                    await AppThemeProvider.instance.selectThemeAndRestart(
                      parentContext,
                      id,
                    );
                  },
                );
              },
            ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final AppThemePalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      borderRadius: 16,
      isSelected: isSelected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _ThemePreview(palette: palette),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              palette.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getSemiBoldStyle(
                fontSize: 13,
                color: AppColors.textColor,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.selectedColor,
            ),
        ],
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final AppThemePalette palette;

  const _ThemePreview({required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 8,
            child: _ColorDot(color: palette.previewSecondary, size: 22),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _ColorDot(color: palette.previewPrimary, size: 26),
          ),
          Positioned(
            left: 6,
            bottom: 0,
            child: _ColorDot(color: palette.background, size: 16),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

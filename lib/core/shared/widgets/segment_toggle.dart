import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';

/// Pill toggle — e.g. MINE / SHARED.
class SegmentToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;
  final List<int>? badgeCounts;

  const SegmentToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.labels,
    this.badgeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.selectedColor.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getSemiBoldStyle(
                          fontSize: 11,
                          color: isActive ? AppColors.textColor1 : AppColors.textColor,
                        ).copyWith(letterSpacing: 0.8),
                      ),
                    ),
                    if (badgeCounts != null &&
                        index < badgeCounts!.length &&
                        badgeCounts![index] > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.textColor1.withValues(alpha: 0.2)
                              : AppColors.selectedColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeCounts![index] > 9 ? '9+' : '${badgeCounts![index]}',
                          style: getBoldStyle(
                            fontSize: 9,
                            color: isActive ? AppColors.textColor1 : AppColors.selectedColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

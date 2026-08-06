import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/app_dimensions.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';

class MineNotesToolbar extends StatefulWidget {
  final MyNotesController controller;

  const MineNotesToolbar({super.key, required this.controller});

  @override
  State<MineNotesToolbar> createState() => _MineNotesToolbarState();
}

class _MineNotesToolbarState extends State<MineNotesToolbar> {
  bool _searchExpanded = false;
  late final FocusNode _searchFocus;

  MyNotesController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode()
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _ctrl.clearSearch();
    setState(() => _searchExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: AppDimensions.inputFieldHeight,
        child: Row(
          children: [
            Expanded(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.hardEdge,
                child: _searchExpanded
                    ? AppContainer(
                        height: 40,
                        borderRadius: 12,
                        isFocused: _searchFocus.hasFocus,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 24,
                              color: AppColors.iconColorGrey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                focusNode: _searchFocus,
                                controller: _ctrl.searchController,
                                onChanged: _ctrl.setSearchQuery,
                                textInputAction: TextInputAction.search,
                                style: getRegularStyle(
                                  color: AppColors.textFieldTextColor,
                                  fontSize: 14,
                                ),
                                cursorColor: AppColors.selectedColor,
                                decoration: InputDecoration.collapsed(
                                  hintText: 'Search title or body…',
                                  hintStyle: getRegularStyle(
                                    color: AppColors.textFieldHintColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (_ctrl.hasActiveSearch)
                              GestureDetector(
                                onTap: _ctrl.clearSearch,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textColor2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchExpanded
                  ? ToolbarIconButton(
                      key: const ValueKey('close'),
                      icon: Icons.close_rounded,
                      tooltip: 'Close search',
                      onTap: _closeSearch,
                    )
                  : Row(
                      key: const ValueKey('actions'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ToolbarIconButton(
                          icon: Icons.search_rounded,
                          tooltip: 'Search notes',
                          onTap: _openSearch,
                        ),
                        const SizedBox(width: 4),
                        SortButton(controller: _ctrl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const ToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AppContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Icon(icon, size: 20, color: AppColors.selectedColor),
      ),
    );
  }
}

class SortButton extends StatelessWidget {
  final MyNotesController controller;

  const SortButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NoteSortOption>(
      offset: const Offset(0, 44),
      tooltip: 'Sort notes',
      color: AppColors.containerColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: controller.setSortOption,
      itemBuilder: (context) => NoteSortOption.values
          .map(
            (option) => PopupMenuItem<NoteSortOption>(
              value: option,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style: getRegularStyle(
                        fontSize: 14,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                  if (controller.sortOption == option)
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.selectedColor,
                    ),
                ],
              ),
            ),
          )
          .toList(),
      child: AppContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(10),
        child: Icon(
          Icons.sort_rounded,
          size: 20,
          color: AppColors.selectedColor,
        ),
      ),
    );
  }
}

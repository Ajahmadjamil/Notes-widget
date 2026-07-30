import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/drawing_data.dart';
import 'package:noteswidgetapp/core/shared/widgets/handwriting_canvas.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';

class NoteGridCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool selectionMode;

  const NoteGridCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.selectionMode = false,
  });

  Color _cardTint() {
    if (isSelected) {
      return AppColors.containerColor.withValues(alpha: 0.55);
    }
    final hash = note.noteId.hashCode.abs() % 4;
    switch (hash) {
      case 0:
        return AppColors.containerColor.withValues(alpha: 0.7);
      case 1:
        return AppColors.containerColor.withValues(alpha: 0.5);
      case 2:
        return AppColors.glassFill;
      default:
        return AppColors.bgColor.withValues(alpha: 0.85);
    }
  }

  int _bodyLines() {
    final len = note.body.length;
    if (len > 120) return 6;
    if (len > 60) return 4;
    if (len > 20) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final hasTitle = note.title.trim().isNotEmpty;
    final title = hasTitle ? note.title : 'Untitled';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.selectedColor.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            color: _cardTint(),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.selectedColor.withValues(alpha: 0.45)
                  : AppColors.glassBorder,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.selectedColor.withValues(
                  alpha: isSelected ? 0.12 : 0.06,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectionMode) ...[
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: isSelected
                            ? AppColors.selectedColor
                            : AppColors.textColor2,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: getSemiBoldStyle(
                          fontSize: 16,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    if (note.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.push_pin_rounded,
                          size: 14,
                          color: AppColors.selectedColor.withValues(alpha: 0.7),
                        ),
                      ),
                    if (note.hasPendingSync)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 14,
                          color: AppColors.textColor2,
                        ),
                      ),
                  ],
                ),
                if (note.isDrawing) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: DrawingPreview(
                      data: DrawingData.decode(note.drawingData),
                      height: 72,
                    ),
                  ),
                ] else if (note.isDocument) ...[
                  const SizedBox(height: 8),
                  _DocumentPreview(note: note),
                ] else if (note.body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note.body,
                    maxLines: _bodyLines(),
                    overflow: TextOverflow.ellipsis,
                    style: getRegularStyle(
                      fontSize: 14,
                      color: AppColors.textColor2,
                    ).copyWith(height: 1.35),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  width: 28,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.selectedColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final Note note;

  const _DocumentPreview({required this.note});

  @override
  Widget build(BuildContext context) {
    final doc = note.document;
    final preview = doc.previewText;
    final chips = <Widget>[
      if (doc.imageCount > 0)
        _chip(Icons.image_outlined, '${doc.imageCount}'),
      if (doc.audioCount > 0)
        _chip(Icons.mic_none_rounded, '${doc.audioCount}'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preview.isNotEmpty)
          Text(
            preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: getRegularStyle(
              fontSize: 14,
              color: AppColors.textColor2,
            ).copyWith(height: 1.35),
          ),
        if (chips.isNotEmpty) ...[
          if (preview.isNotEmpty) const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: chips),
        ],
        if (preview.isEmpty && chips.isEmpty)
          Text(
            'Empty document',
            style: getRegularStyle(
              fontSize: 13,
              color: AppColors.textColor2,
            ),
          ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.selectedColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: getRegularStyle(fontSize: 12, color: AppColors.textColor2),
        ),
      ],
    );
  }
}

/// Keep-style two-column masonry grid for notes.
class NotesMasonryGrid extends StatelessWidget {
  final List<Note> notes;
  final void Function(Note note) onTap;
  final void Function(Note note) onLongPress;
  final bool selectionMode;
  final bool Function(String noteId) isSelected;

  const NotesMasonryGrid({
    super.key,
    required this.notes,
    required this.onTap,
    required this.onLongPress,
    this.selectionMode = false,
    this.isSelected = _neverSelected,
  });

  static bool _neverSelected(String _) => false;

  @override
  Widget build(BuildContext context) {
    final left = <Note>[];
    final right = <Note>[];

    for (var i = 0; i < notes.length; i++) {
      if (i.isEven) {
        left.add(notes[i]);
      } else {
        right.add(notes[i]);
      }
    }

    Widget column(List<Note> columnNotes) {
      return Column(
        children: columnNotes.map((note) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NoteGridCard(
              note: note,
              selectionMode: selectionMode,
              isSelected: isSelected(note.noteId),
              onTap: () => onTap(note),
              onLongPress: () => onLongPress(note),
            ),
          );
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(left)),
        const SizedBox(width: 10),
        Expanded(child: column(right)),
      ],
    );
  }
}

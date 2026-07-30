import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';

class Note {
  final String noteId;
  final String ownerId;
  final String title;
  final String body;
  final int createdAt;
  final int updatedAt;
  final String? pendingSync;
  final bool isDeleted;
  final bool isPinned;
  final NoteType noteType;
  final String drawingData;
  final String documentData;

  const Note({
    required this.noteId,
    required this.ownerId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync,
    this.isDeleted = false,
    this.isPinned = false,
    this.noteType = NoteType.text,
    this.drawingData = '',
    this.documentData = '',
  });

  bool get hasPendingSync => pendingSync != null && pendingSync!.isNotEmpty;
  bool get isDrawing => noteType == NoteType.drawing;
  bool get isDocument => noteType == NoteType.document;

  DocumentData get document => DocumentData.decode(documentData);

  Note copyWith({
    String? title,
    String? body,
    int? updatedAt,
    String? pendingSync,
    bool clearPendingSync = false,
    bool? isDeleted,
    bool? isPinned,
    NoteType? noteType,
    String? drawingData,
    String? documentData,
  }) {
    return Note(
      noteId: noteId,
      ownerId: ownerId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: clearPendingSync ? null : (pendingSync ?? this.pendingSync),
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
      noteType: noteType ?? this.noteType,
      drawingData: drawingData ?? this.drawingData,
      documentData: documentData ?? this.documentData,
    );
  }

  factory Note.fromSupabase(String noteId, Map<String, dynamic> data) {
    return Note(
      noteId: noteId,
      ownerId: data['user_id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: _asInt(data['created_at']) ?? 0,
      updatedAt: _asInt(data['updated_at']) ?? 0,
      noteType: NoteType.fromString(data['note_type'] as String?),
      drawingData: data['drawing_data'] as String? ?? '',
      documentData: data['document_data'] as String? ?? '',
    );
  }

  factory Note.fromLocalMap(Map<String, dynamic> row) {
    return Note(
      noteId: row['note_id'] as String,
      ownerId: row['owner_id'] as String,
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      createdAt: row['created_at'] as int,
      updatedAt: row['updated_at'] as int,
      pendingSync: row['pending_sync'] as String?,
      isDeleted: (row['is_deleted'] as int? ?? 0) == 1,
      isPinned: (row['is_pinned'] as int? ?? 0) == 1,
      noteType: NoteType.fromString(row['note_type'] as String?),
      drawingData: row['drawing_data'] as String? ?? '',
      documentData: row['document_data'] as String? ?? '',
    );
  }

  Map<String, dynamic> toLocalMap() => {
        'note_id': noteId,
        'owner_id': ownerId,
        'title': title,
        'body': body,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'pending_sync': pendingSync,
        'is_deleted': isDeleted ? 1 : 0,
        'is_pinned': isPinned ? 1 : 0,
        'note_type': noteType.value,
        'drawing_data': drawingData,
        'document_data': documentData,
      };

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

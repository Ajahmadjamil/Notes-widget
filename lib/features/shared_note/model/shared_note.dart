import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';

class SharedNote {
  final String sharedNoteId;
  final String friendshipId;
  final String user1;
  final String user2;
  final String title;
  final String body;
  final int createdAt;
  final int updatedAt;
  final String updatedBy;
  final NoteType noteType;
  final String drawingData;
  final String documentData;

  const SharedNote({
    required this.sharedNoteId,
    required this.friendshipId,
    required this.user1,
    required this.user2,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.noteType = NoteType.text,
    this.drawingData = '',
    this.documentData = '',
  });

  bool get isDrawing => noteType == NoteType.drawing;
  bool get isDocument => noteType == NoteType.document;

  DocumentData get document {
    final parsed = DocumentData.decode(documentData);
    if (parsed.blocks.isNotEmpty) return parsed;
    if (body.trim().isNotEmpty && noteType != NoteType.drawing) {
      return DocumentData.fromLegacyBody(body, authorId: updatedBy);
    }
    return const DocumentData();
  }

  bool get isUnset =>
      title == 'Shared note' &&
      body.isEmpty &&
      drawingData.isEmpty &&
      documentData.isEmpty &&
      noteType == NoteType.text;

  SharedNote copyWith({
    String? title,
    String? body,
    int? updatedAt,
    String? updatedBy,
    NoteType? noteType,
    String? drawingData,
    String? documentData,
  }) {
    return SharedNote(
      sharedNoteId: sharedNoteId,
      friendshipId: friendshipId,
      user1: user1,
      user2: user2,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      noteType: noteType ?? this.noteType,
      drawingData: drawingData ?? this.drawingData,
      documentData: documentData ?? this.documentData,
    );
  }

  factory SharedNote.fromRow(Map<String, dynamic> row) {
    final friendship = row['friendships'];
    String user1 = '';
    String user2 = '';
    String friendshipId = row['friendship_id'] as String? ?? '';

    if (friendship is Map) {
      user1 = friendship['user_id'] as String? ?? '';
      user2 = friendship['friend_id'] as String? ?? '';
      friendshipId = friendship['id'] as String? ?? friendshipId;
    }

    return SharedNote(
      sharedNoteId: row['id'] as String,
      friendshipId: friendshipId,
      user1: user1,
      user2: user2,
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      createdAt: _timestampMillis(row['created_at']),
      updatedAt: _timestampMillis(row['updated_at']),
      updatedBy: row['updated_by'] as String? ?? '',
      noteType: NoteType.fromString(row['note_type'] as String?),
      drawingData: row['drawing_data'] as String? ?? '',
      documentData: row['document_data'] as String? ?? '',
    );
  }

  bool involvesUser(String uid) => user1 == uid || user2 == uid;

  static int _timestampMillis(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }
}

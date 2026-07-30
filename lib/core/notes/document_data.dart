import 'dart:convert';

enum DocumentBlockType { text, image, audio }

class DocumentBlock {
  final String id;
  final DocumentBlockType type;
  final String content;
  /// Local absolute path (offline / before upload).
  final String localPath;
  /// Supabase Storage object path: `{uid}/{noteId}/{file}` or `shared/{noteId}/{file}`.
  final String storagePath;
  final String mimeType;
  /// Audio duration in milliseconds (optional).
  final int durationMs;
  /// Author of this block (shared notes).
  final String authorId;
  final String authorName;

  const DocumentBlock({
    required this.id,
    required this.type,
    this.content = '',
    this.localPath = '',
    this.storagePath = '',
    this.mimeType = '',
    this.durationMs = 0,
    this.authorId = '',
    this.authorName = '',
  });

  bool get hasLocalFile => localPath.isNotEmpty;
  bool get hasRemoteFile => storagePath.isNotEmpty;
  bool get needsUpload =>
      (type == DocumentBlockType.image || type == DocumentBlockType.audio) &&
      hasLocalFile &&
      !hasRemoteFile;

  /// Display title for audio blocks (`content` stores the custom name).
  String get audioTitle {
    final t = content.trim();
    return t.isEmpty ? 'Voice note' : t;
  }

  String get authorLabel {
    final n = authorName.trim();
    if (n.isNotEmpty) return n;
    if (authorId.isNotEmpty) return 'User';
    return '';
  }

  DocumentBlock copyWith({
    String? content,
    String? localPath,
    String? storagePath,
    String? mimeType,
    int? durationMs,
    String? authorId,
    String? authorName,
  }) {
    return DocumentBlock(
      id: id,
      type: type,
      content: content ?? this.content,
      localPath: localPath ?? this.localPath,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      durationMs: durationMs ?? this.durationMs,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'localPath': localPath,
        'storagePath': storagePath,
        'mimeType': mimeType,
        'durationMs': durationMs,
        'authorId': authorId,
        'authorName': authorName,
      };

  factory DocumentBlock.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'text';
    final type = DocumentBlockType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => DocumentBlockType.text,
    );
    return DocumentBlock(
      id: json['id'] as String? ?? '',
      type: type,
      content: json['content'] as String? ?? '',
      localPath: json['localPath'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
    );
  }
}

class DocumentData {
  static const int version = 1;
  final List<DocumentBlock> blocks;

  const DocumentData({this.blocks = const []});

  bool get isEmpty => blocks.isEmpty;

  String get previewText {
    final texts = blocks
        .where((b) => b.type == DocumentBlockType.text && b.content.trim().isNotEmpty)
        .map((b) => b.content.trim());
    return texts.join('\n');
  }

  int get imageCount =>
      blocks.where((b) => b.type == DocumentBlockType.image).length;

  int get audioCount =>
      blocks.where((b) => b.type == DocumentBlockType.audio).length;

  bool get hasMeaningfulContent {
    if (imageCount > 0 || audioCount > 0) return true;
    return blocks.any(
      (b) => b.type == DocumentBlockType.text && b.content.trim().isNotEmpty,
    );
  }

  DocumentData copyWith({List<DocumentBlock>? blocks}) =>
      DocumentData(blocks: blocks ?? this.blocks);

  String encode() => jsonEncode({
        'version': version,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      });

  static DocumentData decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const DocumentData();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = (map['blocks'] as List? ?? [])
          .map((e) => DocumentBlock.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return DocumentData(blocks: list);
    } catch (_) {
      return const DocumentData();
    }
  }

  /// Legacy shared plain-text body → single authored text block.
  static DocumentData fromLegacyBody(String body, {String authorId = '', String authorName = ''}) {
    if (body.trim().isEmpty) return const DocumentData();
    return DocumentData(
      blocks: [
        DocumentBlock(
          id: 'legacy',
          type: DocumentBlockType.text,
          content: body,
          authorId: authorId,
          authorName: authorName,
        ),
      ],
    );
  }
}

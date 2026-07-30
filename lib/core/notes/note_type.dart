enum NoteType {
  text,
  drawing,
  document;

  String get value => name;

  static NoteType fromString(String? raw) {
    if (raw == NoteType.drawing.name) return NoteType.drawing;
    if (raw == NoteType.document.name) return NoteType.document;
    return NoteType.text;
  }
}

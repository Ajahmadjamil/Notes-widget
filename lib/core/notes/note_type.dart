enum NoteType {
  text,
  drawing;

  String get value => name;

  static NoteType fromString(String? raw) {
    if (raw == NoteType.drawing.name) return NoteType.drawing;
    return NoteType.text;
  }
}

import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class NotesLocalDb {
  NotesLocalDb._();
  static final NotesLocalDb instance = NotesLocalDb._();

  static const _dbName = 'noteswidgetapp_notes.db';
  static const _dbVersion = 1;
  static const tableNotes = 'notes';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableNotes (
            note_id TEXT PRIMARY KEY,
            owner_id TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            pending_sync TEXT,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<List<Note>> getActiveNotes(String ownerId) async {
    final db = await database;
    final rows = await db.query(
      tableNotes,
      where: 'owner_id = ? AND is_deleted = 0',
      whereArgs: [ownerId],
      orderBy: 'updated_at DESC',
    );
    return rows.map((r) => Note.fromLocalMap(r)).toList();
  }

  Future<Note?> getNote(String noteId) async {
    final db = await database;
    final rows = await db.query(
      tableNotes,
      where: 'note_id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromLocalMap(rows.first);
  }

  Future<List<Note>> getPendingNotes(String ownerId) async {
    final db = await database;
    final rows = await db.query(
      tableNotes,
      where: 'owner_id = ? AND pending_sync IS NOT NULL',
      whereArgs: [ownerId],
    );
    return rows.map((r) => Note.fromLocalMap(r)).toList();
  }

  Future<void> upsert(Note note) async {
    final db = await database;
    await db.insert(
      tableNotes,
      note.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePermanently(String noteId) async {
    final db = await database;
    await db.delete(
      tableNotes,
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }

  Future<void> clearPendingSync(String noteId) async {
    final db = await database;
    await db.update(
      tableNotes,
      {'pending_sync': null},
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }
}

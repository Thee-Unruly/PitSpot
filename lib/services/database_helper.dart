import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('amanda_pitspot.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE sermons (
        id $idType,
        title $textType,
        date $textType,
        preacher $textType,
        audio_path $textNullable,
        status $textType,
        theme_summary $textNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE transcript_segments (
        id $idType,
        sermon_id $textType,
        start_time $textType,
        end_time $textType,
        speaker $textType,
        text $textType,
        tags $textType,
        verse_ids $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE scripture_mentions (
        id $idType,
        sermon_id $textType,
        citation $textType,
        verse_text $textType,
        timestamp $textNullable,
        type $textNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE sermon_notes (
        id $idType,
        sermon_id $textType,
        summary $textType,
        main_points $textType,
        quotable_lines $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE devotional_days (
        id $idType,
        sermon_id $textType,
        day_number $intType,
        title $textType,
        reflection_text $textType,
        prompt_question $textType,
        linked_verses $textType,
        user_prayer_response $textNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book $textType,
        chapter $intType,
        verse $intType,
        text $textType,
        translation $textType
      )
    ''');

    await _seedInitialBibleData(db);
  }

  Future<void> _seedInitialBibleData(Database db) async {
    final verses = [
      {'book': 'Romans', 'chapter': 8, 'verse': 28, 'text': 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.', 'translation': 'NIV'},
      {'book': 'Romans', 'chapter': 8, 'verse': 28, 'text': 'And we know that all things work together for good to them that love God, to them who are the called according to his purpose.', 'translation': 'KJV'},
      {'book': 'Philippians', 'chapter': 4, 'verse': 13, 'text': 'I can do all things through Christ who strengthens me.', 'translation': 'KJV'},
      {'book': 'Jeremiah', 'chapter': 29, 'verse': 11, 'text': 'For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future.', 'translation': 'NIV'},
      {'book': 'John', 'chapter': 3, 'verse': 16, 'text': 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.', 'translation': 'NIV'},
      {'book': 'Psalms', 'chapter': 23, 'verse': 1, 'text': 'The LORD is my shepherd; I shall not want.', 'translation': 'KJV'},
      {'book': 'Proverbs', 'chapter': 3, 'verse': 5, 'text': 'Trust in the LORD with all your heart and lean not on your own understanding;', 'translation': 'NIV'},
      {'book': 'Proverbs', 'chapter': 3, 'verse': 6, 'text': 'in all your ways submit to him, and he will make your paths straight.', 'translation': 'NIV'},
      {'book': 'Isaiah', 'chapter': 40, 'verse': 31, 'text': 'But those who hope in the LORD will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.', 'translation': 'NIV'},
      {'book': 'Matthew', 'chapter': 28, 'verse': 19, 'text': 'Therefore go and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit,', 'translation': 'NIV'},
      {'book': 'Yohana', 'chapter': 3, 'verse': 16, 'text': 'Kwa maana jinsi hii Mungu aliupenda ulimwengu, hata akamtoa Mwanawe pekee, ili kila mtu amwaminiye asipotee, bali awe na uzima wa milele.', 'translation': 'SUV'},
      {'book': 'Warumi', 'chapter': 8, 'verse': 28, 'text': 'Nasi twajua ya kuwa katika mambo yote Mungu hufanya kazi pamoja na wale wampendao katika kuwapatia mema, yaani, wale walioitwa kwa kusudi lake.', 'translation': 'SUV'},
    ];

    for (var v in verses) {
      await db.insert('verses', v);
    }
  }

  // Sermon CRUD
  Future<void> insertSermon(Sermon sermon) async {
    final db = await instance.database;
    await db.insert('sermons', sermon.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Sermon>> getSermons() async {
    final db = await instance.database;
    final maps = await db.query('sermons', orderBy: 'date DESC');
    return maps.map((m) => Sermon.fromMap(m)).toList();
  }

  Future<Sermon?> getSermon(String id) async {
    final db = await instance.database;
    final maps = await db.query('sermons', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Sermon.fromMap(maps.first);
    }
    return null;
  }

  // Transcript segments
  Future<void> insertTranscriptSegments(List<TranscriptSegment> segments) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var seg in segments) {
      batch.insert('transcript_segments', seg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<TranscriptSegment>> getTranscriptSegments(String sermonId) async {
    final db = await instance.database;
    final maps = await db.query('transcript_segments', where: 'sermon_id = ?', whereArgs: [sermonId], orderBy: 'start_time ASC');
    return maps.map((m) => TranscriptSegment.fromMap(m)).toList();
  }

  // Notes & Scripture mentions
  Future<void> saveSermonNotes(SermonNotes notes) async {
    final db = await instance.database;
    await db.insert('sermon_notes', notes.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    final batch = db.batch();
    for (var s in notes.scriptures) {
      batch.insert('scripture_mentions', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<SermonNotes?> getSermonNotes(String sermonId) async {
    final db = await instance.database;
    final maps = await db.query('sermon_notes', where: 'sermon_id = ?', whereArgs: [sermonId]);
    if (maps.isEmpty) return null;

    final scriptMaps = await db.query('scripture_mentions', where: 'sermon_id = ?', whereArgs: [sermonId]);
    final scriptures = scriptMaps.map((m) => ScriptureMention.fromMap(m)).toList();

    return SermonNotes.fromMap(maps.first, scriptures: scriptures);
  }

  // Devotionals
  Future<void> saveDevotionalDays(List<DevotionalDay> days) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var day in days) {
      batch.insert('devotional_days', day.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<DevotionalDay>> getDevotionalDays(String sermonId) async {
    final db = await instance.database;
    final maps = await db.query('devotional_days', where: 'sermon_id = ?', whereArgs: [sermonId], orderBy: 'day_number ASC');
    return maps.map((m) => DevotionalDay.fromMap(m)).toList();
  }

  Future<void> updatePrayerResponse(String dayId, String response) async {
    final db = await instance.database;
    await db.update('devotional_days', {'user_prayer_response': response}, where: 'id = ?', whereArgs: [dayId]);
  }

  // Bible search & lookup
  Future<List<BibleVerse>> searchBible(String query, {String translation = 'NIV'}) async {
    final db = await instance.database;
    final maps = await db.query(
      'verses',
      where: '(text LIKE ? OR book LIKE ?) AND (translation = ? OR translation = ?)',
      whereArgs: ['%$query%', '%$query%', translation, 'KJV'],
    );
    return maps.map((m) => BibleVerse.fromMap(m)).toList();
  }

  Future<BibleVerse?> lookupVerse(String book, int chapter, int verse, {String translation = 'NIV'}) async {
    final db = await instance.database;
    final maps = await db.query(
      'verses',
      where: 'book LIKE ? AND chapter = ? AND verse = ?',
      whereArgs: ['%$book%', chapter, verse],
    );
    if (maps.isNotEmpty) {
      return BibleVerse.fromMap(maps.first);
    }
    return null;
  }
}

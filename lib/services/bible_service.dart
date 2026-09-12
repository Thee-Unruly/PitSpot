import '../models/models.dart';
import 'database_helper.dart';

class BibleService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<BibleVerse>> searchVerses(String query, {String translation = 'NIV'}) async {
    return await _dbHelper.searchBible(query, translation: translation);
  }

  Future<BibleVerse?> getVerse(String book, int chapter, int verse, {String translation = 'NIV'}) async {
    return await _dbHelper.lookupVerse(book, chapter, verse, translation: translation);
  }

  Future<BibleVerse> fetchVerseText(String citation) async {
    // E.g. citation = "Romans 8:28"
    final parts = citation.trim().split(' ');
    if (parts.length >= 2) {
      final book = parts.sublist(0, parts.length - 1).join(' ');
      final chapVerse = parts.last.split(':');
      if (chapVerse.length == 2) {
        final chapter = int.tryParse(chapVerse[0]) ?? 1;
        final verseNum = int.tryParse(chapVerse[1]) ?? 1;

        final found = await getVerse(book, chapter, verseNum);
        if (found != null) {
          return found;
        }
      }
    }

    return BibleVerse(
      id: 0,
      book: citation,
      chapter: 1,
      verse: 1,
      text: 'For God so loved the world that He gave His only begotten Son, that whoever believes in Him should not perish but have everlasting life.',
      translation: 'NIV',
    );
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

class BibleTranslationData {
  final String name;
  final String shortName;
  final List<BibleVerse> verses;
  // Lookup key: "lowercasebook:chapter:verse" -> BibleVerse
  final Map<String, BibleVerse> verseIndex;
  // Lookup key: "lowercasebook:chapter" -> List<BibleVerse>
  final Map<String, List<BibleVerse>> chapterIndex;

  BibleTranslationData({
    required this.name,
    required this.shortName,
    required this.verses,
    required this.verseIndex,
    required this.chapterIndex,
  });
}

class BibleService {
  static final BibleService instance = BibleService._internal();
  factory BibleService() => instance;
  BibleService._internal();

  final Map<String, BibleTranslationData> _cache = {};
  final Map<String, Future<BibleTranslationData>> _loadingFutures = {};

  static const Map<String, String> availableTranslations = {
    'English (KJV)': 'EN-English/bible.csv',
  };

  /// Preload the default English CSV Bible.
  Future<void> init({String defaultTranslation = 'English (KJV)'}) async {
    await _loadTranslation(defaultTranslation);
  }

  Future<BibleTranslationData> _loadTranslation(String translationKey) async {
    var key = translationKey;
    if (!availableTranslations.containsKey(key)) {
      // Find case-insensitive match or fallback to English (CSV)
      key = availableTranslations.keys.firstWhere(
        (k) => k.toLowerCase() == translationKey.toLowerCase() ||
               k.toLowerCase().startsWith(translationKey.toLowerCase()),
        orElse: () => 'English (CSV)',
      );
    }

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    if (_loadingFutures.containsKey(key)) {
      return await _loadingFutures[key]!;
    }

    final assetPath = availableTranslations[key] ?? 'EN-English/bible.csv';

    final future = _parseBibleAsset(assetPath, key);
    _loadingFutures[key] = future;

    try {
      final data = await future;
      _cache[key] = data;
      return data;
    } finally {
      _loadingFutures.remove(key);
    }
  }

  static Future<BibleTranslationData> _parseBibleAsset(String assetPath, String shortName) async {
    if (assetPath.endsWith('.csv')) {
      return await _parseBibleCsv(assetPath, shortName);
    } else {
      return await _parseBibleJson(assetPath, shortName);
    }
  }

  static Future<BibleTranslationData> _parseBibleCsv(String assetPath, String shortName) async {
    final csvStr = await rootBundle.loadString(assetPath);
    final rows = _fastCsvSplit(csvStr);

    final verses = <BibleVerse>[];
    final verseIndex = <String, BibleVerse>{};
    final chapterIndex = <String, List<BibleVerse>>{};

    if (rows.isEmpty) {
      return BibleTranslationData(
        name: 'English Bible',
        shortName: shortName,
        verses: verses,
        verseIndex: verseIndex,
        chapterIndex: chapterIndex,
      );
    }

    // Default indices for Citation,Book,Chapter,Verse,Text
    int bookIdx = 1;
    int chapterIdx = 2;
    int verseIdx = 3;
    int textIdx = 4;

    final header = rows.first;
    for (int i = 0; i < header.length; i++) {
      final col = header[i].trim().toLowerCase();
      if (col == 'book') bookIdx = i;
      if (col == 'chapter') chapterIdx = i;
      if (col == 'verse') verseIdx = i;
      if (col == 'text') textIdx = i;
    }

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= textIdx) continue;

      final bookName = row[bookIdx].trim();
      if (bookName.isEmpty) continue;

      final chapter = int.tryParse(row[chapterIdx].trim()) ?? 1;
      final verseNum = int.tryParse(row[verseIdx].trim()) ?? 1;
      var text = row[textIdx].trim();

      // Clean leading/trailing quotes and newlines
      if (text.startsWith('"') && text.endsWith('"') && text.length >= 2) {
        text = text.substring(1, text.length - 1).trim();
      }
      text = text.replaceAll('¶', '').trim();

      final verseObj = BibleVerse(
        id: i,
        book: bookName,
        chapter: chapter,
        verse: verseNum,
        text: text,
        translation: 'English',
      );

      verses.add(verseObj);

      final bookNorm = _normalizeBookName(bookName);
      final vKey = '$bookNorm:$chapter:$verseNum';
      verseIndex[vKey] = verseObj;

      final cKey = '$bookNorm:$chapter';
      chapterIndex.putIfAbsent(cKey, () => []).add(verseObj);
    }

    return BibleTranslationData(
      name: 'Holy Bible (English)',
      shortName: 'English',
      verses: verses,
      verseIndex: verseIndex,
      chapterIndex: chapterIndex,
    );
  }

  static Future<BibleTranslationData> _parseBibleJson(String assetPath, String shortName) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonStr);

    final meta = data['metadata'] as Map<String, dynamic>? ?? {};
    final fullName = meta['name'] ?? shortName;
    final short = meta['shortname'] ?? shortName;
    final rawVerses = (data['verses'] as List? ?? []);

    final verses = <BibleVerse>[];
    final verseIndex = <String, BibleVerse>{};
    final chapterIndex = <String, List<BibleVerse>>{};

    for (int i = 0; i < rawVerses.length; i++) {
      final v = rawVerses[i];
      final bookName = v['book_name']?.toString() ?? '';
      final chapter = v['chapter'] is int ? v['chapter'] as int : int.tryParse(v['chapter'].toString()) ?? 1;
      final verseNum = v['verse'] is int ? v['verse'] as int : int.tryParse(v['verse'].toString()) ?? 1;
      final text = v['text']?.toString().replaceAll('¶', '').trim() ?? '';

      final verseObj = BibleVerse(
        id: i + 1,
        book: bookName,
        chapter: chapter,
        verse: verseNum,
        text: text,
        translation: short,
      );

      verses.add(verseObj);

      final bookNorm = _normalizeBookName(bookName);
      final vKey = '$bookNorm:$chapter:$verseNum';
      verseIndex[vKey] = verseObj;

      final cKey = '$bookNorm:$chapter';
      chapterIndex.putIfAbsent(cKey, () => []).add(verseObj);
    }

    return BibleTranslationData(
      name: fullName,
      shortName: short,
      verses: verses,
      verseIndex: verseIndex,
      chapterIndex: chapterIndex,
    );
  }

  static List<List<String>> _fastCsvSplit(String input) {
    final rows = <List<String>>[];
    final currentField = StringBuffer();
    final currentRow = <String>[];
    var inQuotes = false;
    final length = input.length;

    for (int i = 0; i < length; i++) {
      final char = input[i];

      if (char == '"') {
        if (inQuotes && i + 1 < length && input[i + 1] == '"') {
          currentField.write('"');
          i++; // Skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentField.toString());
        currentField.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < length && input[i + 1] == '\n') {
          i++;
        }
        currentRow.add(currentField.toString());
        currentField.clear();
        if (currentRow.isNotEmpty && (currentRow.length > 1 || currentRow[0].trim().isNotEmpty)) {
          rows.add(List.from(currentRow));
        }
        currentRow.clear();
      } else {
        currentField.write(char);
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      if (currentRow.length > 1 || currentRow[0].trim().isNotEmpty) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  /// Look up a specific verse by book, chapter, and verse number.
  Future<BibleVerse?> getVerse(
    String book,
    int chapter,
    int verse, {
    String translation = 'English (CSV)',
  }) async {
    final data = await _loadTranslation(translation);
    final normBook = _normalizeBookName(book);
    final key = '$normBook:$chapter:$verse';
    return data.verseIndex[key];
  }

  /// Get all verses for a book and chapter (e.g. Romans 8).
  Future<List<BibleVerse>> getChapter(
    String book,
    int chapter, {
    String translation = 'English (CSV)',
  }) async {
    final data = await _loadTranslation(translation);
    final normBook = _normalizeBookName(book);
    final key = '$normBook:$chapter';
    return data.chapterIndex[key] ?? [];
  }

  /// Fetch verse text from any citation string (e.g., "Romans 8:28", "John 3:16", "Genesis 1:1-3").
  Future<BibleVerse> fetchVerseText(
    String citation, {
    String translation = 'English (CSV)',
  }) async {
    final data = await _loadTranslation(translation);
    final parsed = _parseCitation(citation);

    if (parsed != null) {
      final key = '${parsed.normalizedBook}:${parsed.chapter}:${parsed.verseStart}';
      final found = data.verseIndex[key];
      if (found != null) {
        if (parsed.verseEnd != null && parsed.verseEnd! > parsed.verseStart) {
          // Range query e.g. Romans 8:28-30
          final chapterVerses = data.chapterIndex['${parsed.normalizedBook}:${parsed.chapter}'] ?? [];
          final rangeVerses = chapterVerses.where(
            (v) => v.verse >= parsed.verseStart && v.verse <= parsed.verseEnd!,
          );
          if (rangeVerses.isNotEmpty) {
            final combinedText = rangeVerses.map((v) => '${v.verse}. ${v.text}').join(' ');
            return BibleVerse(
              id: found.id,
              book: found.book,
              chapter: found.chapter,
              verse: found.verse,
              text: combinedText,
              translation: data.shortName,
            );
          }
        }
        return found;
      }
    }

    // Fallback search by query text if direct lookup didn't match
    final searchMatches = await searchVerses(citation, translation: translation);
    if (searchMatches.isNotEmpty) {
      return searchMatches.first;
    }

    return BibleVerse(
      id: 0,
      book: citation,
      chapter: 1,
      verse: 1,
      text: 'Verse not found in $translation.',
      translation: data.shortName,
    );
  }

  /// Search across the entire Bible by keyword or citation.
  Future<List<BibleVerse>> searchVerses(
    String query, {
    String translation = 'English (CSV)',
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final data = await _loadTranslation(translation);

    // 1. Check if query is a citation (e.g. "Romans 8:28" or "Romans 8")
    final parsed = _parseCitation(trimmed);
    if (parsed != null) {
      if (parsed.verseStart > 0) {
        final key = '${parsed.normalizedBook}:${parsed.chapter}:${parsed.verseStart}';
        final v = data.verseIndex[key];
        if (v != null) return [v];
      }
      // Return whole chapter if verse is not specified or 0
      final chapterKey = '${parsed.normalizedBook}:${parsed.chapter}';
      final chapterVerses = data.chapterIndex[chapterKey];
      if (chapterVerses != null && chapterVerses.isNotEmpty) {
        return chapterVerses;
      }
    }

    // 2. Full text search across all verses
    final lowerQuery = trimmed.toLowerCase();
    final results = <BibleVerse>[];

    for (final v in data.verses) {
      if (v.text.toLowerCase().contains(lowerQuery) ||
          v.book.toLowerCase().contains(lowerQuery)) {
        results.add(v);
        if (results.length >= limit) break;
      }
    }

    return results;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static _ParsedCitation? _parseCitation(String input) {
    final clean = input.trim();
    // Pattern: e.g. "1 Corinthians 13:4-7", "Romans 8:28", "Psalm 23:1", "John 3"
    final regex = RegExp(
      r'^((?:\d\s+)?[a-zA-Z\s]+?)\s+(\d{1,3})(?::(\d{1,3})(?:-(\d{1,3}))?)?$',
    );
    final match = regex.firstMatch(clean);
    if (match == null) return null;

    final book = match.group(1)!.trim();
    final chapter = int.tryParse(match.group(2)!) ?? 1;
    final verseStart = match.group(3) != null ? int.tryParse(match.group(3)!) ?? 1 : 0;
    final verseEnd = match.group(4) != null ? int.tryParse(match.group(4)!) : null;

    return _ParsedCitation(
      rawBook: book,
      normalizedBook: _normalizeBookName(book),
      chapter: chapter,
      verseStart: verseStart,
      verseEnd: verseEnd,
    );
  }

  static String _normalizeBookName(String name) {
    var s = name.trim().toLowerCase().replaceAll('.', '');
    // Standardize variations & abbreviations
    switch (s) {
      case 'psalm':
      case 'ps':
        return 'psalms';
      case 'rom':
        return 'romans';
      case 'phil':
      case 'philipp':
        return 'philippians';
      case 'gen':
        return 'genesis';
      case 'ex':
      case 'exod':
        return 'exodus';
      case 'lev':
        return 'leviticus';
      case 'num':
        return 'numbers';
      case 'deut':
        return 'deuteronomy';
      case 'josh':
        return 'joshua';
      case 'judg':
        return 'judges';
      case '1 cor':
      case '1cor':
      case '1st corinthians':
        return '1 corinthians';
      case '2 cor':
      case '2cor':
      case '2nd corinthians':
        return '2 corinthians';
      case '1 thess':
      case '1thess':
        return '1 thessalonians';
      case '2 thess':
      case '2thess':
        return '2 thessalonians';
      case '1 tim':
      case '1tim':
        return '1 timothy';
      case '2 tim':
      case '2tim':
        return '2 timothy';
      case '1 pet':
      case '1pet':
        return '1 peter';
      case '2 pet':
      case '2pet':
        return '2 peter';
      case '1 jn':
      case '1jn':
      case '1 john':
        return '1 john';
      case '2 jn':
      case '2jn':
      case '2 john':
        return '2 john';
      case '3 jn':
      case '3jn':
      case '3 john':
        return '3 john';
      case 'matt':
      case 'mt':
        return 'matthew';
      case 'mk':
        return 'mark';
      case 'lk':
        return 'luke';
      case 'jn':
        return 'john';
      case 'acts':
      case 'ac':
        return 'acts';
      case 'gal':
        return 'galatians';
      case 'eph':
        return 'ephesians';
      case 'col':
        return 'colossians';
      case 'heb':
        return 'hebrews';
      case 'jas':
      case 'jam':
        return 'james';
      case 'rev':
      case 'revelation':
      case 'revelations':
        return 'revelation';
      case 'jer':
        return 'jeremiah';
      case 'isa':
        return 'isaiah';
      case 'prov':
        return 'proverbs';
      default:
        return s;
    }
  }
}

class _ParsedCitation {
  final String rawBook;
  final String normalizedBook;
  final int chapter;
  final int verseStart;
  final int? verseEnd;

  _ParsedCitation({
    required this.rawBook,
    required this.normalizedBook,
    required this.chapter,
    required this.verseStart,
    this.verseEnd,
  });
}

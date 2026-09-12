/// Production-grade Bible scripture reference detector.
///
/// Uses regex pattern matching to identify scripture citations in transcribed
/// text, covering all 66 books of the Bible (full names and common
/// abbreviations), plus Swahili book names for SUV translation support.
class ScriptureDetectorService {
  late final RegExp _referencePattern;

  /// Book names ordered longest-first for correct regex alternation priority.
  /// The regex engine tries alternatives left-to-right, so longer/more-specific
  /// names must appear before shorter abbreviations.
  static const List<String> _bookNames = [
    // ── Multi-word & numbered books (longest first) ──
    'Song of Solomon', 'Song of Songs',
    '1 Thessalonians', '2 Thessalonians',
    '1 Corinthians', '2 Corinthians',
    '1 Chronicles', '2 Chronicles',
    '1 Timothy', '2 Timothy',
    '1 Samuel', '2 Samuel',
    '1 Kings', '2 Kings',
    '1 Peter', '2 Peter',
    '1 John', '2 John', '3 John',

    // ── Old Testament ──
    'Deuteronomy', 'Ecclesiastes', 'Lamentations',
    'Genesis', 'Exodus', 'Leviticus', 'Numbers',
    'Joshua', 'Judges', 'Ruth',
    'Ezra', 'Nehemiah', 'Esther',
    'Job', 'Psalms', 'Psalm', 'Proverbs',
    'Isaiah', 'Jeremiah', 'Ezekiel', 'Daniel',
    'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
    'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',

    // ── New Testament ──
    'Philippians', 'Colossians', 'Revelation',
    'Galatians', 'Ephesians',
    'Matthew', 'Mark', 'Luke', 'John',
    'Philemon', 'Hebrews',
    'Acts', 'Romans',
    'Titus', 'James', 'Jude',

    // ── Abbreviations (longer first) ──
    '1 Thess', '2 Thess',
    '1 Cor', '2 Cor',
    '1 Sam', '2 Sam',
    '1 Kgs', '2 Kgs',
    '1 Chr', '2 Chr',
    '1 Tim', '2 Tim',
    '1 Pet', '2 Pet',
    '1 Jn', '2 Jn', '3 Jn',
    'Deut', 'Josh', 'Judg',
    'Eccl', 'Prov',
    'Gen', 'Exod', 'Lev', 'Num',
    'Neh', 'Est',
    'Ps', 'Isa', 'Jer', 'Lam', 'Ezek', 'Dan',
    'Hos', 'Ob', 'Mic', 'Nah', 'Hab', 'Zeph', 'Hag', 'Zech', 'Mal',
    'Matt', 'Mk', 'Lk', 'Jn',
    'Rom', 'Gal', 'Eph', 'Phil', 'Col',
    'Tit', 'Phlm', 'Heb', 'Jas', 'Rev',

    // ── Swahili book names (SUV) ──
    'Wafilipi', 'Wakolosai', 'Waefeso', 'Wagalatia',
    'Warumi', 'Matayo', 'Marko', 'Luka', 'Yohana',
    'Mwanzo', 'Kutoka', 'Walawi', 'Hesabu', 'Kumbukumbu',
    'Yoshua', 'Waamuzi', 'Ruthu',
    'Zaburi', 'Mithali', 'Mhubiri',
    'Isaya', 'Yeremia', 'Maombolezo', 'Ezekieli', 'Danieli',
    'Ufunuo',
  ];

  ScriptureDetectorService() {
    final escapedNames = _bookNames.map((n) => RegExp.escape(n)).join('|');
    // Matches patterns like: "Romans 8:28", "1 Corinthians 13:4-7", "Psalm 23"
    _referencePattern = RegExp(
      r'\b(' +
          escapedNames +
          r')\.?\s+(\d{1,3})\s*(?::\s*(\d{1,3})(?:\s*[-\u2013]\s*(\d{1,3}))?)?',
      caseSensitive: false,
    );
  }

  static final RegExp _turnToCue = RegExp(
    r'\b(turn(?:\s+with\s+me)?(?:\s+in\s+your\s+bibles?)?\s+to|open(?:\s+your)?(?:\s+bibles?)?\s+to|look\s+at|read\s+with\s+me|fungua|soma)\b',
    caseSensitive: false,
  );

  static final RegExp _quoteCue = RegExp(
    r'\b(says?|written|promises?|reads?|anasema|imeandikwa)\b',
    caseSensitive: false,
  );

  /// Detect all unique Bible references in [text] with simple string citations.
  List<String> detectReferences(String text) {
    return detectDetailedReferences(text).map((d) => d.citation).toList();
  }

  /// Detect all unique Bible references with classification type ('reference', 'turn_to', 'quote').
  List<DetectedScripture> detectDetailedReferences(String text) {
    if (text.trim().isEmpty) return [];

    final matches = _referencePattern.allMatches(text);
    final seen = <String>{};
    final refs = <DetectedScripture>[];

    for (final match in matches) {
      final book = _normalizeCase(match.group(1)!.trim());
      final chapter = match.group(2)!;
      final verse = match.group(3);
      final endVerse = match.group(4);

      final buf = StringBuffer('$book $chapter');
      if (verse != null) {
        buf.write(':$verse');
        if (endVerse != null) {
          buf.write('-$endVerse');
        }
      }

      final ref = buf.toString();
      final key = ref.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);

        // Analyze surrounding text (window of 60 chars before match) for cues
        final startPos = match.start;
        final windowStart = (startPos - 60).clamp(0, text.length);
        final contextPrefix = text.substring(windowStart, startPos);

        String type = 'reference';
        if (_turnToCue.hasMatch(contextPrefix)) {
          type = 'turn_to';
        } else if (_quoteCue.hasMatch(contextPrefix)) {
          type = 'quote';
        }

        refs.add(DetectedScripture(citation: ref, type: type));
      }
    }

    return refs;
  }

  /// Capitalize each word for consistent display (e.g. "romans" → "Romans").
  String _normalizeCase(String book) {
    return book.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (RegExp(r'^\d+$').hasMatch(word)) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Rich detection result containing citation and classification type.
class DetectedScripture {
  final String citation;
  final String type; // 'reference', 'turn_to', 'quote', 'suggestion'

  const DetectedScripture({
    required this.citation,
    this.type = 'reference',
  });
}


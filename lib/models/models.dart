import 'dart:convert';

class Sermon {
  final String id;
  final String title;
  final String date;
  final String preacher;
  final String? audioPath;
  final String status; // 'recording', 'processing', 'ready'
  final String? themeSummary;

  Sermon({
    required this.id,
    required this.title,
    required this.date,
    required this.preacher,
    this.audioPath,
    required this.status,
    this.themeSummary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'preacher': preacher,
      'audio_path': audioPath,
      'status': status,
      'theme_summary': themeSummary,
    };
  }

  factory Sermon.fromMap(Map<String, dynamic> map) {
    return Sermon(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      preacher: map['preacher'],
      audioPath: map['audio_path'],
      status: map['status'] ?? 'ready',
      themeSummary: map['theme_summary'],
    );
  }
}

class TranscriptSegment {
  final String id;
  final String sermonId;
  final String start;
  final String end;
  final String speaker;
  final String text;
  final List<String> tags; // e.g., 'key_point', 'scripture_reference', 'joke', 'altar_call', 'quotable'
  final List<String> verseIds;

  TranscriptSegment({
    required this.id,
    required this.sermonId,
    required this.start,
    required this.end,
    required this.speaker,
    required this.text,
    required this.tags,
    required this.verseIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sermon_id': sermonId,
      'start_time': start,
      'end_time': end,
      'speaker': speaker,
      'text': text,
      'tags': jsonEncode(tags),
      'verse_ids': jsonEncode(verseIds),
    };
  }

  factory TranscriptSegment.fromMap(Map<String, dynamic> map) {
    return TranscriptSegment(
      id: map['id'],
      sermonId: map['sermon_id'],
      start: map['start_time'],
      end: map['end_time'],
      speaker: map['speaker'] ?? 'Preacher',
      text: map['text'],
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'])) : [],
      verseIds: map['verse_ids'] != null ? List<String>.from(jsonDecode(map['verse_ids'])) : [],
    );
  }
}

enum ScriptureDetectionType {
  reference, // Explicit scripture citation e.g. "Romans 8:28"
  turnTo, // Preacher prompt e.g. "Turn with me to..."
  quote, // Direct recitation of verse text
  suggestion, // Contextual AI allusion
}

class ScriptureMention {
  final String id;
  final String sermonId;
  final String citation; // e.g. "Romans 8:28"
  final String verseText;
  final String? timestamp;
  final String type; // 'reference', 'turn_to', 'quote', 'suggestion'

  ScriptureMention({
    required this.id,
    required this.sermonId,
    required this.citation,
    required this.verseText,
    this.timestamp,
    this.type = 'reference',
  });

  String get typeLabel {
    switch (type) {
      case 'turn_to':
        return 'Turn-To';
      case 'quote':
        return 'Quote';
      case 'suggestion':
        return 'Suggestion';
      case 'reference':
      default:
        return 'Reference';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sermon_id': sermonId,
      'citation': citation,
      'verse_text': verseText,
      'timestamp': timestamp,
      'type': type,
    };
  }

  factory ScriptureMention.fromMap(Map<String, dynamic> map) {
    return ScriptureMention(
      id: map['id'],
      sermonId: map['sermon_id'],
      citation: map['citation'],
      verseText: map['verse_text'],
      timestamp: map['timestamp'],
      type: map['type'] ?? 'reference',
    );
  }
}

class SermonNotes {
  final String id;
  final String sermonId;
  final String summary;
  final List<String> mainPoints;
  final List<String> quotableLines;
  final List<ScriptureMention> scriptures;

  SermonNotes({
    required this.id,
    required this.sermonId,
    required this.summary,
    required this.mainPoints,
    required this.quotableLines,
    required this.scriptures,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sermon_id': sermonId,
      'summary': summary,
      'main_points': jsonEncode(mainPoints),
      'quotable_lines': jsonEncode(quotableLines),
    };
  }

  factory SermonNotes.fromMap(Map<String, dynamic> map, {List<ScriptureMention>? scriptures}) {
    return SermonNotes(
      id: map['id'],
      sermonId: map['sermon_id'],
      summary: map['summary'],
      mainPoints: map['main_points'] != null ? List<String>.from(jsonDecode(map['main_points'])) : [],
      quotableLines: map['quotable_lines'] != null ? List<String>.from(jsonDecode(map['quotable_lines'])) : [],
      scriptures: scriptures ?? [],
    );
  }
}

class DevotionalDay {
  final String id;
  final String sermonId;
  final int dayNumber;
  final String title;
  final String reflectionText;
  final String promptQuestion;
  final List<String> linkedVerses;
  final String? userPrayerResponse;

  DevotionalDay({
    required this.id,
    required this.sermonId,
    required this.dayNumber,
    required this.title,
    required this.reflectionText,
    required this.promptQuestion,
    required this.linkedVerses,
    this.userPrayerResponse,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sermon_id': sermonId,
      'day_number': dayNumber,
      'title': title,
      'reflection_text': reflectionText,
      'prompt_question': promptQuestion,
      'linked_verses': jsonEncode(linkedVerses),
      'user_prayer_response': userPrayerResponse,
    };
  }

  factory DevotionalDay.fromMap(Map<String, dynamic> map) {
    return DevotionalDay(
      id: map['id'],
      sermonId: map['sermon_id'],
      dayNumber: map['day_number'],
      title: map['title'],
      reflectionText: map['reflection_text'],
      promptQuestion: map['prompt_question'],
      linkedVerses: map['linked_verses'] != null ? List<String>.from(jsonDecode(map['linked_verses'])) : [],
      userPrayerResponse: map['user_prayer_response'],
    );
  }
}

class BibleVerse {
  final int id;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String translation;

  BibleVerse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.translation,
  });

  String get reference => '$book $chapter:$verse';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'translation': translation,
    };
  }

  factory BibleVerse.fromMap(Map<String, dynamic> map) {
    return BibleVerse(
      id: map['id'] ?? 0,
      book: map['book'],
      chapter: map['chapter'],
      verse: map['verse'],
      text: map['text'],
      translation: map['translation'] ?? 'KJV',
    );
  }
}

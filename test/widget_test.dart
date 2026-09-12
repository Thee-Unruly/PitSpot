import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/models.dart';
import 'package:untitled/services/scripture_detector_service.dart';

void main() {
  test('Sermon model serialization and deserialization test', () {
    final sermon = Sermon(
      id: 'sermon_123',
      title: 'Sunday Pitstop Sermon',
      date: '2026-09-12',
      preacher: 'Pastor John',
      status: 'ready',
      themeSummary: 'Surrender over perfection',
    );

    final map = sermon.toMap();
    expect(map['id'], 'sermon_123');
    expect(map['title'], 'Sunday Pitstop Sermon');
    expect(map['preacher'], 'Pastor John');

    final deserialized = Sermon.fromMap(map);
    expect(deserialized.id, sermon.id);
    expect(deserialized.title, sermon.title);
    expect(deserialized.preacher, sermon.preacher);
  });

  test('ScriptureMention model with type test', () {
    final mention = ScriptureMention(
      id: 'sc_1',
      sermonId: 'sermon_123',
      citation: 'Romans 8:28',
      verseText: 'All things work together for good.',
      timestamp: '00:04:12',
      type: 'turn_to',
    );

    final map = mention.toMap();
    expect(map['citation'], 'Romans 8:28');
    expect(map['type'], 'turn_to');

    final deserialized = ScriptureMention.fromMap(map);
    expect(deserialized.citation, 'Romans 8:28');
    expect(deserialized.type, 'turn_to');
    expect(deserialized.typeLabel, 'Turn-To');
  });

  test('ScriptureDetectorService detects various scripture formats and cues', () {
    final detector = ScriptureDetectorService();

    final text1 = 'Please turn in your Bibles to Romans 8:28 and also Philippians 4:13.';
    final detected1 = detector.detectReferences(text1);
    expect(detected1, contains('Romans 8:28'));
    expect(detected1, contains('Philippians 4:13'));

    final detailed = detector.detectDetailedReferences(text1);
    expect(detailed.first.citation, 'Romans 8:28');
    expect(detailed.first.type, 'turn_to');

    final text2 = 'As we read in 1 Corinthians 13:4-7 and Psalm 23...';
    final detected2 = detector.detectReferences(text2);
    expect(detected2, contains('1 Corinthians 13:4-7'));
    expect(detected2, contains('Psalm 23'));

    final text3 = 'Katika kitabu cha Yohana 3:16 na Warumi 8:28...';
    final detected3 = detector.detectReferences(text3);
    expect(detected3, contains('Yohana 3:16'));
    expect(detected3, contains('Warumi 8:28'));

    // Empty text
    expect(detector.detectReferences(''), isEmpty);
  });
}


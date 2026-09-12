import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/models.dart';

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

  test('ScriptureMention model test', () {
    final mention = ScriptureMention(
      id: 'sc_1',
      sermonId: 'sermon_123',
      citation: 'Romans 8:28',
      verseText: 'All things work together for good.',
      timestamp: '00:04:12',
    );

    final map = mention.toMap();
    expect(map['citation'], 'Romans 8:28');

    final deserialized = ScriptureMention.fromMap(map);
    expect(deserialized.citation, 'Romans 8:28');
    expect(deserialized.timestamp, '00:04:12');
  });
}

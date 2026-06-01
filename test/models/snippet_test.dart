import 'package:code_buddy/shared/models/snippet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Snippet', () {
    test('toMap -> fromMap preserves all fields', () {
      final now = DateTime.utc(2026, 5, 24, 10, 0);
      final s = Snippet(
        id: 'abc',
        title: 'Quicksort',
        language: 'Dart',
        code: 'void quicksort() {}',
        category: 'Algorithms',
        isFavorite: true,
        updatedAt: now,
      );
      final round = Snippet.fromMap(s.toMap());
      expect(round.id, s.id);
      expect(round.title, s.title);
      expect(round.language, s.language);
      expect(round.code, s.code);
      expect(round.category, s.category);
      expect(round.isFavorite, s.isFavorite);
      expect(round.updatedAt, s.updatedAt);
    });

    test('fromMap with missing fields fills defaults', () {
      final s = Snippet.fromMap(<String, dynamic>{'title': 'X'});
      expect(s.title, 'X');
      expect(s.language, 'Dart');
      expect(s.code, '');
      expect(s.category, 'General');
      expect(s.isFavorite, false);
      // updatedAt falls back to DateTime.now() — just sanity check it's recent.
      expect(s.updatedAt.isAfter(DateTime(2020)), isTrue);
    });

    test('copyWith preserves id and untouched fields', () {
      final s = Snippet(title: 'A', language: 'Dart', code: 'x', category: 'G');
      final updated = s.copyWith(title: 'B', isFavorite: true);
      expect(updated.id, s.id);
      expect(updated.title, 'B');
      expect(updated.language, s.language);
      expect(updated.code, s.code);
      expect(updated.category, s.category);
      expect(updated.isFavorite, isTrue);
    });

    test('default constructor generates a unique uuid per snippet', () {
      final a = Snippet(title: 'a', language: 'Dart', code: '', category: 'g');
      final b = Snippet(title: 'b', language: 'Dart', code: '', category: 'g');
      expect(a.id, isNot(b.id));
      expect(a.id, isNotEmpty);
    });
  });
}

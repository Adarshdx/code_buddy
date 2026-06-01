import 'package:code_buddy/shared/models/problem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Problem.fromMap', () {
    test('parses statement, examples, constraints, starters, tests', () {
      final p = Problem.fromMap(<String, dynamic>{
        'id': 'two-sum',
        'title': 'Two Sum',
        'difficulty': 'Easy',
        'tags': ['array', 'hash-table'],
        'statement': 'Find two indices...',
        'examples': [
          {'input': 'a', 'output': 'b', 'explanation': 'why'},
          {'input': 'c', 'output': 'd'},
        ],
        'constraints': ['n <= 1000'],
        'hint': 'Use a map.',
        'starters': {'Dart': 'void main() {}', 'Python': 'print()'},
        'pythonTests': 'assert True\nprint("${Problem.passSentinel}")',
      });

      expect(p.id, 'two-sum');
      expect(p.title, 'Two Sum');
      expect(p.difficulty, 'Easy');
      expect(p.tags, ['array', 'hash-table']);
      expect(p.statement, 'Find two indices...');
      expect(p.examples.length, 2);
      expect(p.examples.first.input, 'a');
      expect(p.examples.first.explanation, 'why');
      expect(p.examples[1].explanation, isNull);
      expect(p.constraints, ['n <= 1000']);
      expect(p.starters.keys, containsAll(['Dart', 'Python']));
      expect(p.hasPythonTests, isTrue);
      expect(p.pythonTests, contains(Problem.passSentinel));
    });

    test('fileNameFor maps each language to the right extension', () {
      final p = Problem.fromMap(<String, dynamic>{
        'id': 'foo-bar',
        'title': 'Foo',
        'starters': {'Dart': 'x', 'Python': 'y', 'Java': 'z', 'C++': 'w', 'JavaScript': 'v'},
      });
      expect(p.fileNameFor('Dart'), 'foo_bar.dart');
      expect(p.fileNameFor('Python'), 'foo_bar.py');
      expect(p.fileNameFor('Java'), 'foo_bar.java');
      expect(p.fileNameFor('C++'), 'foo_bar.cpp');
      expect(p.fileNameFor('JavaScript'), 'foo_bar.js');
    });

    test('defaultLanguage prefers Dart, falls back to first starter', () {
      final dartOnly = Problem.fromMap(<String, dynamic>{
        'id': 'x',
        'title': 'X',
        'starters': {'Dart': '...', 'Python': '...'},
      });
      expect(dartOnly.defaultLanguage, 'Dart');

      final pythonOnly = Problem.fromMap(<String, dynamic>{
        'id': 'y',
        'title': 'Y',
        'starters': {'Python': '...'},
      });
      expect(pythonOnly.defaultLanguage, 'Python');
    });

    test('hasPythonTests is false when the field is missing or empty', () {
      final missing = Problem.fromMap(<String, dynamic>{'id': 'a', 'title': 'A'});
      expect(missing.hasPythonTests, isFalse);

      final empty = Problem.fromMap(<String, dynamic>{
        'id': 'a',
        'title': 'A',
        'pythonTests': '',
      });
      expect(empty.hasPythonTests, isFalse);
    });
  });

  group('ProblemProgress', () {
    test('round-trips through toMap/fromMap', () {
      final p = ProblemProgress(
        problemId: 'two-sum',
        status: ProgressStatus.solved,
        updatedAt: DateTime.utc(2026, 5, 24),
      );
      final round = ProblemProgress.fromMap(p.toMap());
      expect(round.problemId, p.problemId);
      expect(round.status, p.status);
      expect(round.updatedAt, p.updatedAt);
    });

    test('falls back to untouched when status name is unknown', () {
      final p = ProblemProgress.fromMap(<String, dynamic>{
        'problemId': 'x',
        'status': 'whatever',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      expect(p.status, ProgressStatus.untouched);
    });
  });
}

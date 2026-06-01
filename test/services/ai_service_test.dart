import 'package:code_buddy/core/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiService mock path', () {
    final service = AiService();

    test('mock-tutor model returns markdown headers', () async {
      final chunks = <String>[];
      await for (final c in service.debugCodeStream(
        code: 'def foo(): pass',
        language: 'Python',
        model: 'mock-tutor',
      )) {
        chunks.add(c);
      }
      final body = chunks.join();
      expect(body, contains('### Beginner-friendly review'));
      expect(body, contains('Python'));
      expect(body, contains('```Python'));
    });

    test('no serverEndpoint + non-mock model still falls back to mock', () async {
      final result = await service.debugCode(
        code: 'x',
        language: 'Dart',
        model: 'gpt-4o-mini',
        // serverEndpoint not set → mock path.
      );
      expect(result, contains('### Beginner-friendly review'));
    });

    test('mock surfaces a stub message when code is empty', () async {
      final result = await service.debugCode(
        code: '',
        language: 'Dart',
        model: 'mock-tutor',
      );
      expect(result, contains('Paste code into the editor'));
    });
  });
}

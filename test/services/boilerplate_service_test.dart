import 'package:code_buddy/core/services/boilerplate_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoilerplateService', () {
    final service = BoilerplateService();

    test('exposes a non-empty list of templates', () {
      expect(service.templates, isNotEmpty);
    });

    test('every template has a title, description, and non-empty code body', () {
      for (final t in service.templates) {
        expect(t.title, isNotEmpty, reason: 'Template missing title');
        expect(t.description, isNotEmpty, reason: '"${t.title}" missing description');
        expect(t.code.trim(), isNotEmpty, reason: '"${t.title}" missing code');
      }
    });

    test('contains the documented starter set', () {
      final titles = service.templates.map((t) => t.title).toSet();
      expect(titles, containsAll(['Login Screen', 'Riverpod Setup', 'API Service']));
    });
  });
}

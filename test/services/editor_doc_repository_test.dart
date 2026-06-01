import 'package:code_buddy/core/services/editor_doc_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../helpers/hive_setup.dart';

void main() {
  late HiveTestEnv env;

  setUpAll(() async {
    env = await bootstrapHive();
  });

  tearDownAll(() async {
    await shutdownHive(env);
  });

  setUp(() async {
    await Hive.box('editor_docs').clear();
  });

  group('EditorDocRepository', () {
    test('load returns null on an empty box', () {
      final repo = EditorDocRepository(Hive.box('editor_docs'));
      expect(repo.load(), isNull);
    });

    test('save then load returns the stored docs + activeIndex', () async {
      final repo = EditorDocRepository(Hive.box('editor_docs'));
      const state = EditorState(
        activeIndex: 1,
        docs: [
          StoredEditorDoc(fileName: 'main.dart', language: 'Dart', text: 'void main(){}'),
          StoredEditorDoc(fileName: 'solution.py', language: 'Python', text: 'print(1)'),
        ],
      );
      await repo.save(state);

      final loaded = repo.load();
      expect(loaded, isNotNull);
      expect(loaded!.activeIndex, 1);
      expect(loaded.docs, hasLength(2));
      expect(loaded.docs[0].fileName, 'main.dart');
      expect(loaded.docs[1].language, 'Python');
      expect(loaded.docs[1].text, 'print(1)');
    });

    test('activeIndex is clamped to a valid range on load', () async {
      final repo = EditorDocRepository(Hive.box('editor_docs'));
      await Hive.box('editor_docs').put('state', {
        'docs': [
          {'fileName': 'a.dart', 'language': 'Dart', 'text': ''},
        ],
        'activeIndex': 99,
      });
      final loaded = repo.load();
      expect(loaded, isNotNull);
      expect(loaded!.activeIndex, 0);
    });

    test('load returns null when docs is empty or malformed', () async {
      final box = Hive.box('editor_docs');
      await box.put('state', {'docs': [], 'activeIndex': 0});
      expect(EditorDocRepository(box).load(), isNull);

      await box.put('state', 'garbage');
      expect(EditorDocRepository(box).load(), isNull);
    });
  });
}

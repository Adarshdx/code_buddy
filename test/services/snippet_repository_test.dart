import 'package:code_buddy/core/services/snippet_repository.dart';
import 'package:code_buddy/core/services/sync_status.dart';
import 'package:code_buddy/shared/models/snippet.dart';
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
    await Hive.box<Map>('snippets').clear();
  });

  group('SnippetRepository.localOnly', () {
    test('starts with no snippets and localOnly status', () {
      final repo = SnippetRepository.localOnly(Hive.box<Map>('snippets'));
      expect(repo.all(), isEmpty);
      expect(repo.status.value, SyncStatus.localOnly);
      expect(repo.isSynced, isFalse);
      repo.dispose();
    });

    test('save persists a snippet that loadAll returns', () async {
      final repo = SnippetRepository.localOnly(Hive.box<Map>('snippets'));
      final snippet = Snippet(
        title: 'Hello',
        language: 'Dart',
        code: 'print(1);',
        category: 'misc',
      );
      await repo.save(snippet);
      final loaded = repo.all();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, snippet.id);
      expect(loaded.first.title, 'Hello');
      repo.dispose();
    });

    test('delete removes the snippet', () async {
      final repo = SnippetRepository.localOnly(Hive.box<Map>('snippets'));
      final s = Snippet(title: 't', language: 'Dart', code: 'c', category: 'g');
      await repo.save(s);
      expect(repo.all(), hasLength(1));
      await repo.delete(s.id);
      expect(repo.all(), isEmpty);
      repo.dispose();
    });

    test('all() sorts most-recently-updated first', () async {
      final repo = SnippetRepository.localOnly(Hive.box<Map>('snippets'));
      final older = Snippet(
        title: 'old',
        language: 'Dart',
        code: '',
        category: 'g',
        updatedAt: DateTime.utc(2020),
      );
      final newer = Snippet(
        title: 'new',
        language: 'Dart',
        code: '',
        category: 'g',
        updatedAt: DateTime.utc(2026),
      );
      await repo.save(older);
      await repo.save(newer);
      final sorted = repo.all();
      expect(sorted.map((s) => s.title), ['new', 'old']);
      repo.dispose();
    });

    test('changes stream fires for save and delete', () async {
      final repo = SnippetRepository.localOnly(Hive.box<Map>('snippets'));
      final events = <void>[];
      final sub = repo.changes.listen(events.add);

      final s = Snippet(title: 'x', language: 'Dart', code: '', category: 'g');
      await repo.save(s);
      await repo.delete(s.id);
      // Let microtasks drain.
      await Future<void>.delayed(Duration.zero);

      expect(events.length, 2);
      await sub.cancel();
      repo.dispose();
    });
  });
}

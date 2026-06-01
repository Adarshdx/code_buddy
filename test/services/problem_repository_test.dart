import 'package:code_buddy/core/services/problem_repository.dart';
import 'package:code_buddy/shared/models/problem.dart';
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
    await Hive.box('problem_progress').clear();
  });

  group('ProblemRepository progress', () {
    test('readAllProgress is empty when no progress saved', () {
      final repo = ProblemRepository(Hive.box('problem_progress'));
      expect(repo.readAllProgress(), isEmpty);
    });

    test('saveStatus persists and readAllProgress returns it', () async {
      final repo = ProblemRepository(Hive.box('problem_progress'));
      await repo.saveStatus('two-sum', ProgressStatus.attempted);
      await repo.saveStatus('binary-search', ProgressStatus.solved);

      final progress = repo.readAllProgress();
      expect(progress['two-sum'], ProgressStatus.attempted);
      expect(progress['binary-search'], ProgressStatus.solved);
    });

    test('saveStatus overwrites the previous status for the same problem', () async {
      final repo = ProblemRepository(Hive.box('problem_progress'));
      await repo.saveStatus('x', ProgressStatus.attempted);
      await repo.saveStatus('x', ProgressStatus.solved);
      expect(repo.readAllProgress()['x'], ProgressStatus.solved);
    });
  });
}

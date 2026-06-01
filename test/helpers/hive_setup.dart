import 'dart:io';

import 'package:hive/hive.dart';

/// One temp directory used by every test that needs Hive. We register the
/// directory and box list once via [bootstrapHive] and clean up via
/// [shutdownHive].
class HiveTestEnv {
  HiveTestEnv._(this.directory);

  final Directory directory;
}

Future<HiveTestEnv> bootstrapHive({List<String> extraBoxes = const []}) async {
  final dir = await Directory.systemTemp.createTemp('code_buddy_test_');
  Hive.init(dir.path);
  // These are the boxes main.dart opens at startup. Tests can request
  // additional named boxes via [extraBoxes].
  await Hive.openBox<Map>('snippets');
  await Hive.openBox('settings');
  await Hive.openBox('auth');
  await Hive.openBox('editor_docs');
  await Hive.openBox('problem_progress');
  for (final name in extraBoxes) {
    if (!Hive.isBoxOpen(name)) await Hive.openBox(name);
  }
  return HiveTestEnv._(dir);
}

Future<void> shutdownHive(HiveTestEnv env) async {
  await Hive.close();
  try {
    await env.directory.delete(recursive: true);
  } catch (_) {
    // Windows sometimes holds the file open briefly after close — ignore.
  }
}

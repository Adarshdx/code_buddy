import 'package:code_buddy/core/services/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every SyncStatus has a non-empty human label', () {
    for (final s in SyncStatus.values) {
      expect(s.label, isNotEmpty, reason: 'Missing label for $s');
    }
  });

  test('labels are distinct so UI can branch on them safely', () {
    final labels = SyncStatus.values.map((s) => s.label).toSet();
    expect(labels.length, SyncStatus.values.length);
  });
}

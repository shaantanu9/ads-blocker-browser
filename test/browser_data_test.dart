import 'package:flutter_test/flutter_test.dart';
import 'package:open_adblock_browser/browser_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('history is newest first, deduplicated and capped', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BrowserData(await SharedPreferences.getInstance());
    await store.record(
      HistoryEntry(
        url: 'https://one.example',
        title: 'One',
        visitedAt: DateTime(2026),
      ),
    );
    await store.record(
      HistoryEntry(
        url: 'https://two.example',
        title: 'Two',
        visitedAt: DateTime(2026, 1, 2),
      ),
    );
    await store.record(
      HistoryEntry(
        url: 'https://one.example',
        title: 'One again',
        visitedAt: DateTime(2026, 1, 3),
      ),
    );
    expect(store.history().map((e) => e.url), [
      'https://one.example',
      'https://two.example',
    ]);
  });

  test(
    'private tabs can avoid calling record and clear removes local records',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = BrowserData(await SharedPreferences.getInstance());
      await store.setAllowedSites({'example.com'});
      await store.setBookmarks({'https://example.com'});
      await store.clearLocalRecords();
      expect(store.allowedSites(), isEmpty);
      expect(store.bookmarks(), isEmpty);
      expect(store.history(), isEmpty);
    },
  );
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BrowserTab {
  const BrowserTab({
    required this.id,
    required this.url,
    this.title = 'New tab',
    this.isPrivate = false,
  });
  final String id;
  final String url;
  final String title;
  final bool isPrivate;

  BrowserTab copyWith({String? url, String? title}) => BrowserTab(
    id: id,
    url: url ?? this.url,
    title: title ?? this.title,
    isPrivate: isPrivate,
  );
}

class HistoryEntry {
  const HistoryEntry({
    required this.url,
    required this.title,
    required this.visitedAt,
  });
  final String url;
  final String title;
  final DateTime visitedAt;

  Map<String, Object> toJson() => {
    'url': url,
    'title': title,
    'visitedAt': visitedAt.toIso8601String(),
  };
  static HistoryEntry? fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    final at = json['visitedAt'];
    if (url is! String || at is! String) return null;
    final visitedAt = DateTime.tryParse(at);
    return visitedAt == null
        ? null
        : HistoryEntry(
            url: url,
            title: json['title'] as String? ?? url,
            visitedAt: visitedAt,
          );
  }
}

class BrowserData {
  BrowserData(this._prefs);
  final SharedPreferences _prefs;
  static const _historyKey = 'history_v1';
  static const _bookmarksKey = 'bookmarks_v1';
  static const _allowedSitesKey = 'allowed_sites_v1';

  Set<String> allowedSites() => {...?_prefs.getStringList(_allowedSitesKey)};
  Future<void> setAllowedSites(Set<String> sites) =>
      _prefs.setStringList(_allowedSitesKey, sites.toList()..sort());
  Set<String> bookmarks() => {...?_prefs.getStringList(_bookmarksKey)};
  Future<void> setBookmarks(Set<String> urls) =>
      _prefs.setStringList(_bookmarksKey, urls.toList()..sort());

  List<HistoryEntry> history() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return const [];
    final value = jsonDecode(raw);
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => HistoryEntry.fromJson(Map<String, dynamic>.from(row)))
        .whereType<HistoryEntry>()
        .toList();
  }

  Future<void> record(HistoryEntry entry) async {
    final existing = history().where((e) => e.url != entry.url).toList();
    existing.insert(0, entry);
    await _prefs.setString(
      _historyKey,
      jsonEncode(existing.take(100).map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearLocalRecords() async {
    await _prefs.remove(_historyKey);
    await _prefs.remove(_bookmarksKey);
    await _prefs.remove(_allowedSitesKey);
  }
}

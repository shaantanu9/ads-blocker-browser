import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_block.dart';
import 'browser_data.dart';

void main() => runApp(const OpenAdblockBrowser());

class OpenAdblockBrowser extends StatelessWidget {
  const OpenAdblockBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Adblock Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b4d)),
      ),
      home: const BrowserScreen(),
    );
  }
}

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final _address = TextEditingController(text: 'https://example.com');
  final _tabs = <BrowserTab>[
    const BrowserTab(id: 'first', url: 'https://example.com'),
  ];
  final _allowedSites = <String>{};
  final _bookmarks = <String>{};
  BrowserData? _data;
  String _activeTabId = 'first';
  InAppWebViewController? _web;
  Uri? _page;
  bool _loading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  int _blocked = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  BrowserTab get _activeTab =>
      _tabs.firstWhere((tab) => tab.id == _activeTabId);

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _data = BrowserData(prefs);
    if (mounted) {
      setState(() {
        _allowedSites.addAll(_data!.allowedSites());
        _bookmarks.addAll(_data!.bookmarks());
      });
    }
  }

  String get _host => _page?.host.toLowerCase() ?? '';
  bool get _adsAllowed => _host.isNotEmpty && _allowedSites.contains(_host);

  InAppWebViewSettings _settings(bool allowAds) => InAppWebViewSettings(
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: false,
    supportMultipleWindows: false,
    useShouldOverrideUrlLoading: true,
    allowFileAccess: false,
    allowContentAccess: false,
    safeBrowsingEnabled: true,
    contentBlockers: [
      if (!allowAds)
        for (final host in blockedHosts)
          ContentBlocker(
            trigger: ContentBlockerTrigger(urlFilter: hostPattern(host)),
            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
          ),
    ],
  );

  Uri? _toUri(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    return uri != null && uri.hasAuthority
        ? uri
        : Uri.https('www.google.com', '/search', {'q': text});
  }

  Future<void> _openAddress() async {
    final uri = _toUri(_address.text);
    if (uri == null) return;
    await _web?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _refreshNavigation() async {
    final controller = _web;
    if (controller == null) return;
    final back = await controller.canGoBack();
    final forward = await controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = back;
        _canGoForward = forward;
      });
    }
  }

  Future<void> _setAllowed(bool allowed) async {
    final host = _host;
    if (host.isEmpty) return;
    setState(() {
      if (allowed) {
        _allowedSites.add(host);
      } else {
        _allowedSites.remove(host);
      }
    });
    await _data?.setAllowedSites(_allowedSites);
    await _web?.setSettings(settings: _settings(allowed));
    if (allowed) {
      await _web?.evaluateJavascript(source: showAdsScript);
    }
    await _web?.reload();
  }

  void _openProtection() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protection for ${_host.isEmpty ? 'this page' : _host}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _adsAllowed
                  ? 'Ads are allowed for this site.'
                  : 'Known ad and tracker requests are blocked.',
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block_outlined),
              title: Text('$_blocked requests blocked'),
              subtitle: const Text('This page only. Nothing is sent to us.'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow ads on this site'),
              subtitle: const Text(
                'Reloads the page. You can undo this anytime.',
              ),
              value: _adsAllowed,
              onChanged: _host.isEmpty
                  ? null
                  : (value) async {
                      Navigator.pop(sheetContext);
                      await _setAllowed(value);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBookmark() async {
    final url = _page?.toString();
    if (url == null) return;
    setState(() {
      if (_bookmarks.contains(url)) {
        _bookmarks.remove(url);
      } else {
        _bookmarks.add(url);
      }
    });
    await _data?.setBookmarks(_bookmarks);
  }

  void _newTab({bool private = false, String url = 'https://example.com'}) {
    final tab = BrowserTab(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url,
      isPrivate: private,
    );
    setState(() {
      _tabs.add(tab);
      _activeTabId = tab.id;
      _page = Uri.tryParse(url);
      _address.text = url;
      _loading = true;
      _blocked = 0;
    });
  }

  void _openTabs() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final tab in _tabs)
              ListTile(
                leading: Icon(
                  tab.isPrivate
                      ? Icons.visibility_off_outlined
                      : Icons.language,
                ),
                title: Text(tab.title),
                subtitle: Text(
                  tab.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: tab.id == _activeTabId,
                trailing: _tabs.length == 1
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close tab',
                        onPressed: () {
                          setState(() {
                            _tabs.remove(tab);
                            _activeTabId = _tabs.last.id;
                            _address.text = _tabs.last.url;
                            _page = Uri.tryParse(_tabs.last.url);
                          });
                          Navigator.pop(sheetContext);
                        },
                      ),
                onTap: () {
                  setState(() {
                    _activeTabId = tab.id;
                    _address.text = tab.url;
                    _page = Uri.tryParse(tab.url);
                  });
                  Navigator.pop(sheetContext);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New tab'),
              onTap: () {
                Navigator.pop(sheetContext);
                _newTab();
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('New private tab'),
              subtitle: const Text('Does not save history'),
              onTap: () {
                Navigator.pop(sheetContext);
                _newTab(private: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSaved() {
    final history = _data?.history() ?? const <HistoryEntry>[];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Bookmarks'),
                  Tab(text: 'History'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _savedList(
                      _bookmarks
                          .map(
                            (url) => HistoryEntry(
                              url: url,
                              title: Uri.tryParse(url)?.host ?? url,
                              visitedAt: DateTime.now(),
                            ),
                          )
                          .toList(),
                      sheetContext,
                      empty: 'No bookmarks yet.',
                    ),
                    _savedList(
                      history,
                      sheetContext,
                      empty: 'No saved history yet.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savedList(
    List<HistoryEntry> entries,
    BuildContext sheetContext, {
    required String empty,
  }) => entries.isEmpty
      ? Center(child: Text(empty))
      : ListView.builder(
          itemCount: entries.length,
          itemBuilder: (_, index) {
            final entry = entries[index];
            return ListTile(
              title: Text(entry.title),
              subtitle: Text(
                entry.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _newTab(url: entry.url);
              },
            );
          },
        );

  Future<void> _clearData() async {
    await _data?.clearLocalRecords();
    await CookieManager.instance().deleteAllCookies();
    await WebStorageManager.instance().deleteAllData();
    await InAppWebViewController.clearAllCache();
    if (mounted) {
      setState(() {
        _allowedSites.clear();
        _bookmarks.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      titleSpacing: 12,
      title: TextField(
        controller: _address,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _openAddress(),
        decoration: InputDecoration(
          hintText: 'Search or enter address',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: _openAddress,
            tooltip: 'Go',
            icon: const Icon(Icons.arrow_forward),
          ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleBookmark,
          tooltip: 'Bookmark page',
          icon: Icon(
            _bookmarks.contains(_page?.toString())
                ? Icons.star
                : Icons.star_border,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'saved') _openSaved();
            if (value == 'clear') await _clearData();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'saved', child: Text('Bookmarks and history')),
            PopupMenuItem(
              value: 'clear',
              child: Text('Clear local browsing data'),
            ),
          ],
        ),
      ],
    ),
    body: Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: InAppWebView(
            key: ValueKey(_activeTabId),
            initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
            initialSettings: _settings(false),
            initialUserScripts: UnmodifiableListView([
              UserScript(
                source: cosmeticHideScript(),
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
              ),
            ]),
            onWebViewCreated: (controller) => _web = controller,
            onLoadStart: (controller, url) async {
              final page = url == null ? null : Uri.tryParse(url.toString());
              final allow =
                  page != null &&
                  _allowedSites.contains(page.host.toLowerCase());
              await controller.setSettings(settings: _settings(allow));
              if (allow) {
                await controller.evaluateJavascript(source: showAdsScript);
              }
              if (mounted) {
                setState(() {
                  _page = page;
                  _blocked = 0;
                  _loading = true;
                  _address.text = page?.toString() ?? _address.text;
                });
              }
            },
            onLoadStop: (controller, url) async {
              final urlText = url?.toString() ?? _activeTab.url;
              final title =
                  await controller.getTitle() ??
                  Uri.tryParse(urlText)?.host ??
                  urlText;
              if (!_activeTab.isPrivate) {
                await _data?.record(
                  HistoryEntry(
                    url: urlText,
                    title: title,
                    visitedAt: DateTime.now(),
                  ),
                );
              }
              if (mounted) {
                setState(() {
                  _loading = false;
                  final index = _tabs.indexWhere(
                    (tab) => tab.id == _activeTabId,
                  );
                  if (index >= 0) {
                    _tabs[index] = _tabs[index].copyWith(
                      url: urlText,
                      title: title,
                    );
                  }
                });
              }
              await _refreshNavigation();
            },
            onCreateWindow: (controller, action) async => false,
            shouldOverrideUrlLoading: (_, action) async {
              final url = action.request.url;
              return url != null && {'http', 'https'}.contains(url.scheme)
                  ? NavigationActionPolicy.ALLOW
                  : NavigationActionPolicy.CANCEL;
            },
            onLoadResource: (_, resource) {
              final uri = Uri.tryParse(resource.url.toString());
              if (uri != null && isBlockedHost(uri.host) && mounted) {
                setState(() => _blocked += 1);
              }
            },
          ),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: _canGoBack ? () => _web?.goBack() : null,
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(
              onPressed: _openTabs,
              tooltip: 'Tabs',
              icon: Badge(
                label: Text('${_tabs.length}'),
                child: const Icon(Icons.tab),
              ),
            ),
            IconButton(
              onPressed: _openSaved,
              tooltip: 'Bookmarks and history',
              icon: const Icon(Icons.bookmarks_outlined),
            ),
            IconButton(
              onPressed: _canGoForward ? () => _web?.goForward() : null,
              tooltip: 'Forward',
              icon: const Icon(Icons.arrow_forward),
            ),
            IconButton(
              onPressed: () => _web?.reload(),
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh),
            ),
            FilledButton.tonalIcon(
              onPressed: _openProtection,
              icon: Icon(_adsAllowed ? Icons.shield_outlined : Icons.shield),
              label: Text(_adsAllowed ? 'Allowed' : 'Protected'),
            ),
          ],
        ),
      ),
    ),
  );
}

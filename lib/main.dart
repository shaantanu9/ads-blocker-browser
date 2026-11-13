import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_block.dart';

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
  static const _allowedSitesKey = 'allowed_sites_v1';
  final _address = TextEditingController(text: 'https://example.com');
  final _allowedSites = <String>{};
  InAppWebViewController? _web;
  Uri? _page;
  bool _loading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  int _blocked = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAllowedSites());
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _loadAllowedSites() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _allowedSites.addAll(
          prefs.getStringList(_allowedSitesKey) ?? const [],
        ),
      );
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_allowedSitesKey, _allowedSites.toList()..sort());
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
    ),
    body: Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: InAppWebView(
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
              if (mounted) {
                setState(() => _loading = false);
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

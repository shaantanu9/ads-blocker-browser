const blockedHosts = <String>{
  'doubleclick.net',
  'googlesyndication.com',
  'googleadservices.com',
  'adnxs.com',
  'amazon-adsystem.com',
  'criteo.com',
  'pubmatic.com',
  'rubiconproject.com',
  'openx.net',
  'taboola.com',
  'outbrain.com',
  'mgid.com',
  'popads.net',
  'popcash.net',
  'propellerads.com',
  'adsterra.com',
};

bool isBlockedHost(String host) {
  final lower = host.toLowerCase();
  return blockedHosts.any(
    (entry) => lower == entry || lower.endsWith('.$entry'),
  );
}

String hostPattern(String host) =>
    r'^https?://([a-z0-9-]+\.)*' +
    host.replaceAll('.', r'\.') +
    r'([/:?#].*)?$';

const cosmeticSelectors = <String>[
  'ins.adsbygoogle',
  'iframe[id^="google_ads"]',
  '[id^="div-gpt-ad"]',
  '[data-ad-slot]',
  '[data-ad-client]',
  '[id^="taboola-"]',
  '.OUTBRAIN',
  '.trc_related_container',
];

String cosmeticHideScript() =>
    '''(function () {
  var id = 'open-adblock-browser-cosmetic-rules';
  var css = '${cosmeticSelectors.join(', ')} { display: none !important; }';
  function install() {
    if (window.__openAdblockBrowserAllowed || document.getElementById(id)) return;
    var style = document.createElement('style'); style.id = id; style.textContent = css;
    (document.head || document.documentElement).appendChild(style);
  }
  install(); document.addEventListener('DOMContentLoaded', install);
})();''';

const showAdsScript = '''(function () {
  window.__openAdblockBrowserAllowed = true;
  document.getElementById('open-adblock-browser-cosmetic-rules')?.remove();
})();''';

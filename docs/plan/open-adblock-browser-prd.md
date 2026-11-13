# PRD: Open Adblock Browser

Status: approved product direction — 2026-11-13.

Implementation update — 2026-11-13: the Android MVP includes one active lightweight WebView, local tab snapshots,
private tabs, history, bookmarks, a per-site exception and clear-data controls. iOS uses WebKit request rules. Android
uses lightweight bundled cosmetic rules while its native request-filtering engine is built; it deliberately does not
use the WebView plugin's request-classification path because it issues a blocking network `HEAD` request per resource.
Filter update signatures, hardware benchmarking and full multi-WebView tab preservation are not built yet.

## Product summary

Open Adblock Browser is a separate, free and open-source browser. It loads a page directly on the person's device and
locally blocks known advertising, pop-under, redirect and tracking requests. It gives the person a clear per-site
override when a page needs its own ads/scripts to work.

This is not Drishan AI. Drishan's WebView blocker is research evidence only; no Drishan source, user data, brand,
models, paid features or secrets are imported into this project.

## Goals

1. Make ordinary browsing cleaner without collecting browsing data.
2. Be simple: blocking is on by default; exceptions are per site and reversible.
3. Be transparent: show the active protection mode and never invent a blocked-request count.
4. Be auditable: public source, MIT licence, reproducible releases, dependency notices and signed rules.
5. Start Android-first; do not widen into a VPN/proxy product.

## Non-goals

- System-wide ad blocking, VPN, custom DNS, TLS interception or certificate installation.
- Circumventing paywalls, logins, DRM, bot checks, CAPTCHAs or website access restrictions.
- Scraping, indexing, republishing or downloading third-party media.
- Accounts, analytics, advertising, affiliate links, profiles or a project-controlled browsing server.
- Claims of complete ad, tracker, malware or anonymity protection.

## v1 requirements

| ID | Requirement | Priority |
|---|---|---|
| B-01 | Address/search bar, tabs, back, forward, reload/stop, history and bookmarks; all local | P0 |
| B-02 | Native Android host rules cover the host/subdomains and run before matching requests complete, without a Dart callback or network probe per resource | P0 |
| B-03 | Cosmetic rules are a bundled, reviewed stylesheet at document start; updates cannot supply executable JavaScript | P0 |
| B-04 | Block pop-ups, unsolicited cross-site redirects and unsafe external schemes; explain the action | P0 |
| B-05 | Per-site Allow ads switch disables request and cosmetic filtering, then reloads | P0 |
| B-06 | Local diagnostics redact page text, credentials and URL query strings; show a blocked-request count only when sourced by the native filtering engine | P0 |
| B-07 | Android Safe Browsing stays enabled | P0 |
| B-08 | HTTPS-first navigation and warning before an HTTP downgrade | P1 |
| B-09 | Signed/versioned filter updates with checksum, expiry and last-known-good rollback | P1 |
| B-10 | Accessible labels, keyboard/screen-reader support, contrast and touch targets | P1 |
| B-11 | iOS WKContentRuleList parity spike | P2 |
| B-12 | Do not load Chrome Web Store extensions or arbitrary CRX packages; use reviewed declarative filter data only | P0 |

## Privacy/security requirements

- No browsing URL, page text, IP address, identifier, block event or history goes to a project-controlled server.
- Optional rule updates use HTTPS and signed manifests verified against a public key shipped in the app. A failed
  verification retains the previous list; downloaded rules never execute code.
- Pages receive no privileged native bridge. File/content access is off unless the person deliberately selects a file.
- Cookies, cache, permissions and exceptions stay local, are inspectable and can be deleted.
- Every filter-list dependency needs a redistribution-compatible licence, attribution, version and checksum.

## Delivery plan

1. Flutter Android shell, local browser state, safe navigation and clear-data controls.
2. Native Android host matcher, curated starter rules, cosmetic rules, per-site override, navigation protection and false-positive fixtures.
3. Threat model, signed filter manifest, SBOM, dependency/licence review and physical phone QA.
4. Public source plus signed APK, checksum, signing-certificate fingerprint and security-report contact.
5. iOS feasibility only after WKContentRuleList and permitted-distribution review.

## Ready for first public APK

All P0 work passes on a physical Android phone; tests cover blocking, cosmetic hiding, recovery, redirect/popup
protection and local data deletion; the release is signed and has checksum/SBOM; every item in the
[release gate](../legal/compliance.md#release-gate) passes.

## Decisions made

| Decision | Choice |
|---|---|
| Product boundary | Separate project; independently reimplemented behaviour only |
| Platform | Android first; iOS WebKit rules implemented |
| Traffic | Direct device-to-site, no proxy/VPN/DNS/TLS interception |
| Business | Free, no ads, account, analytics or affiliate links |
| Licence | MIT |
| Rule source | Curated project-owned starter rules; external lists only after licence audit |
| Extensions | No Chrome Web Store/CRX loading; reviewed declarative filters only |

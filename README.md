# Open Adblock Browser

A free, open-source, privacy-first Android browser that blocks known advertising, tracking, pop-under and redirect
requests locally on the device. It has no ads, account, analytics, affiliate links, proxy or VPN.

Status: browser foundation. It is not ready for public APK distribution.

## Included foundation

- Direct browsing through Android WebView.
- Fast cosmetic ad hiding, pop-up prevention and Android Safe Browsing. iOS also uses native WebKit request rules.
- A local per-site **Allow ads** setting.
- Local tabs, private tabs, bookmarks, history, and one-tap clear-data controls.
- Product, architecture, privacy, security and compliance documentation.

It never bypasses paywalls, logins, DRM, anti-bot systems, CAPTCHAs, geo-controls or other access controls. It is not a
system-wide VPN/DNS blocker and does not promise complete ad, tracker or malware protection. The current Android build
intentionally avoids WebView's slow per-request content-blocker path; native Android request filtering is the next
performance-focused milestone.

## Documents

- [PRD](docs/plan/open-adblock-browser-prd.md)
- [ADR-001](docs/architecture/adr-001-local-only-browser.md)
- [Compliance checklist](docs/legal/compliance.md)
- [Privacy promise](PRIVACY.md)
- [Security policy](SECURITY.md)
- [Contribution rules](CONTRIBUTING.md)

## Licence

MIT. See [LICENSE](LICENSE).

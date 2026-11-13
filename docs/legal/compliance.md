# Compliance and release plan

Status: planning document, not legal advice — 2026-11-13. Re-check each linked policy immediately before a public or
store release.

## Baseline

Initial distribution is source plus a signed Android APK. Avoiding an app store does not remove copyright, licence,
privacy/consumer law, site-terms or security duties; it only avoids a store submission for that release.

## Required controls

| Control | Requirement |
|---|---|
| Licence | MIT in `LICENSE`; every contribution grants compatible rights. |
| Notices | `NOTICE` and `THIRD_PARTY_NOTICES.md` record dependencies/filter lists, versions and attributions. |
| Privacy | `PRIVACY.md` accurately describes local data, optional rule updates and user-initiated reports. |
| Security | `SECURITY.md`, threat model, dependency review, signed releases/updates and key rotation/revocation. |
| Supply chain | Per-release SBOM, pinned lockfiles, checksum, certificate fingerprint and reproducible-build directions. |

[GitHub licensing guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)
confirms that public source without a licence remains under default copyright.

## Product conduct

- State only that the browser blocks *some known* ad/tracker requests. Do not claim complete, anonymous or malware-proof browsing.
- Never bypass paywalls, logins, DRM, CAPTCHA/anti-bot systems, geo restrictions or access controls; do not scrape, index, host or republish pages/media.
- Never automatically submit URLs/history/diagnostics. User-reviewed reports redact page text, tokens, query strings and identifiers by default.
- Treat each filter list as a dependency: record licence, terms, source/version/checksum and attribution. Ship none whose licence does not allow redistribution.
- Rule manifests are signed data only—not scripts, plugins, libraries or code.

## Android private APK

Keep Android WebView Safe Browsing enabled. Android documents that WebView checks URLs with Google Safe Browsing and
recommends retaining it. [Android WebView Safe Browsing](https://developer.android.com/develop/ui/views/layout/webapps/managing-webview)

Before sharing an APK, test signing/install/update/uninstall, exported components, deep links, downloads, file chooser,
permissions, clear-data, Safe Browsing, filter rollback, accessibility and a no-telemetry network capture. Publish the
APK SHA-256 and signing certificate fingerprint.

## Apple and future Google Play

Do not promise public iPhone distribution yet. It needs an Apple-authorised route and the current programme terms. A
future App Store browser must be a substantive native product, disclose privacy accurately and have required rights to
access third-party services/content. [Apple App Review](https://developer.apple.com/app-store/review/) ·
[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) ·
[App Privacy details](https://developer.apple.com/app-store/app-privacy-details/)

Before Play distribution, complete then-current Data safety, privacy-policy and content-rating requirements. Google
rejects low-value WebView and affiliate-spam apps; this product must retain meaningful browser/privacy features.
[Google Play policy](https://support.google.com/googleplay/android-developer/answer/18265346)

VPN/DNS/proxy scope requires a new legal and platform review.

## Release gate

- [ ] Owner has rights to license authored source MIT.
- [ ] Every dependency/filter list has compatible licence, source, version and notice.
- [ ] No Drishan data, secrets, signing material or proprietary assets are present.
- [ ] Threat model reviewed; no remote executable-update path exists.
- [ ] Privacy statement matches actual traffic.
- [ ] Physical Android, accessibility and security QA pass; Safe Browsing is on.
- [ ] Release is signed with checksum, SBOM, build directions and a vulnerability contact.
- [ ] Qualified legal review occurs where target markets or new functionality make it necessary.

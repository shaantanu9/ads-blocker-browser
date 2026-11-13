# ADR-001: Local-only, Android-first browser

Status: accepted — 2026-11-13.

## Context

The product must be a simple, free, open-source ad-blocking browser that is distinct from Drishan AI. The Drishan
flow proved the desired interaction: block known request hosts, hide leftover ad slots, stop popups/redirects, and let
the person allow ads on a specific site when needed. No implementation files are copied.

## Decision

Build a separate Flutter project, Android first. Pages load directly from the device through the platform WebView. The
app has no backend, account, cloud proxy, analytics or VPN/DNS/TLS-interception capability.

Protection is limited to local host rules, a bundled reviewed cosmetic stylesheet, a navigation guard, a per-site
Allow ads exception, and platform safety features such as Android Safe Browsing. Future filter updates are signed data
verified against a bundled public key; they have version, expiry, checksum and last-known-good rollback, and can never
contain executable code.

## Consequences

- Small privacy/attack surface and no browsing-history custody.
- No system-wide blocking; that is intentional.
- A resistant site gets a visible user exception, never a bypass of its access controls.
- Android ships first. iOS remains uncommitted until a WKContentRuleList parity/distribution review succeeds.
- All code, rules and dependencies require their own licence/attribution audit.

## Alternatives rejected

| Alternative | Reason |
|---|---|
| Add a mode to Drishan | Wrong product and privacy/store boundary |
| VPN/DNS blocker | Privileged/system-wide design and larger platform/jurisdiction risk |
| Cloud proxy | Makes the project custodian of browsing data/content |
| Executable remote rules | Remote-code risk |
| Unlicensed block list | Incompatible with responsible open-source redistribution |

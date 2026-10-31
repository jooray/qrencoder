# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter 3.47+ (stable), fixed by SPEC.md. Packages pinned there: `qr_flutter`, `share_plus`, `receive_sharing_intent`, `file_picker`, `path_provider`, `shared_preferences`, `super_clipboard`. State is plain `StatefulWidget` + controllers with one `AppConfig` value object; no state framework.

Material 3 is a widget library here, not the design language — see Brand Commitments.

## Users

Privacy-minded technical users. They are crypto-aware (they read BOLT 11, EIP-681, BIP 21 and WEP/WPA2 without help), work on desktop, and treat a Wi-Fi password or wallet address as something that must not leave the machine. macOS is the primary environment; Linux is the secondary desktop target; Android is where the same person, or someone sharing a payment/link request with them, arrives through the system share sheet.

They expect instant feedback and would rather set the real parameter than be shielded from it.

## Product Purpose

Replaces the discontinued macOS-only QREncoder (MobilioDevelopment) with a cross-platform tool that turns typed or shared content into a correct, scannable QR code immediately.

Success: the user opens the app, types or shares, and sees a correct code without pressing a Generate button — then exports it at a quality worth printing or shows it to be scanned straight off the display.

## Positioning

Four claims that hold up and that competing tools cannot all make:

1. **Nothing leaves the machine.** No network calls, no telemetry, no accounts, and payload contents are never persisted between launches.
2. **Live redraw on every keystroke**, on desktop as well as mobile — no Generate step anywhere in the product.
3. **Export quality that respects the standard.** The ISO/IEC 18004 four-module quiet zone is baked into every export, module scale is controllable, and dark mode never inverts the symbol.
4. **Crypto payment URIs built properly** — BIP 21, BOLT 11, ZIP 321, EIP-681 and Monero are composed from typed fields and parsed back into fields on import, not pasted as opaque strings.

A browser generator cannot offer (1); a phone's built-in generator does not do (3) or (4); a paid QR app rarely does (2) on desktop.

## Operating Context

- **Desktop (macOS first, Linux second):** keyboard-first use, often launched from the dock or terminal, including a cold-launch CLI argument carrying the payload (`qrencoder "some text"`).
- **Android:** the app arrives through the system share sheet (SEND / SEND_MULTIPLE, `text/plain`) and deep links carrying payment or link URIs.
- **Physical scene:** the code is scanned off the screen by another device (wallet app, guest's phone) or exported as PNG and printed, attached, or embedded.
- **No server, no account, no sync.** Every session is local and disposable.
- **Distribution:** local builds during v1; GitHub Actions CI matrix is explicitly out of scope for v1.

## Capabilities and Constraints

**Confirmed v1 functionality**

- Fourteen templates: Text, URL, Wi-Fi, Email, Phone, SMS, Geo, Calendar event (iCalendar VEVENT), Contact (vCard 3.0), Bitcoin, Lightning invoice, Monero, Zcash, Ethereum/EVM. Each is typed fields → encoded payload, with raw mode always showing and editing the resulting string.
- Error correction L/M/Q/H, default **Q**; module scale for export, default 8 px/module; foreground/background pickers defaulting to black/white with a warning below 4:1 contrast; reset; focus lands in the primary input on launch and after an Android share.
- Toolbar: copy image to clipboard, save as PNG, share via the native sheet. Tapping the preview opens an immersive fullscreen view sized for scanning.
- Dark mode follows the system theme; app chrome adapts, the QR canvas never does. A themed border separates the card from the page.
- Persistence of last content type, colors, EC level and theme — payload contents are deliberately never persisted.

**Constraints**

- Encoding runs synchronously in Dart; target is under ~16 ms per frame for payloads up to a few KB.
- Android `minSdk` 21+.
- No iOS effort in v1 (code compiles only); no logo overlays or stylised dot styles; no history; English strings only.
- **Design language is not Material 3** and is not bound to the look the spec sketched. User override, October 2026: design freely so the interface suits these use cases.
- **Undecided:** the desktop image-clipboard strategy (`super_clipboard` versus writing a temp file and notifying) is deliberately deferred to implementation.

## Brand Commitments

- **Name: QREncoder**, kept on purpose. The identity is fresh — new icon, voice and visual language, with no visual continuity to MobilioDevelopment's app and no implication that its author endorses this one.
- **Voice:** precise, technical, unhurried. These users know the vocabulary, so do not simplify it away; no marketing cadence, no exclamation marks, no reassurance prose.
- **Privacy is a promise, not a feature bullet.** Anything requiring a network call is out of scope by default.
- **Material 3 is not binding** (user, October 2026). Where Android platform guidance and this override disagree, the override wins — that includes Material's component vocabulary, type scale and colour-role rulebook, which are not a default look here.
- **Android still owes its hardware its system behaviours:** the system Back gesture, share-sheet entry, window/IME insets, font scale and reduced-motion settings are honoured on Android regardless of the visual language. What gets replaced is the look, not the operating-system contract.
- Android is a secondary target behind macOS; the shared visual language is designed desktop-first and then has to survive a phone.

## Evidence on Hand

`SPEC.md` at the repository root is the entire brief and the only artifact — there is no code yet, and no screenshots, icon, logo, font, screenshot or copy from the predecessor. There are no testimonials, no named users, no benchmarks and no marketing assets.

Any icon, screenshot, hero image or landing copy has to be created from scratch, and none of it may be presented as pre-existing or as the old app's material.

## Product Principles

1. **Correct before pretty.** Quiet zone, module geometry and contrast are never traded for decoration; a QR that fails to scan has failed completely.
2. **Zero latency is the product.** Any interaction that inserts a confirm step has to justify itself against the live redraw.
3. **Nothing leaves the machine.** A feature whose natural implementation needs a server is out of scope until the user says otherwise.
4. **Respect the user's competence.** Expose the real parameters — EC level, scale, chain ID, escaping — instead of burying them behind presets.
5. **Native entry points, one visual language.** macOS keyboard flow and the Android share sheet behave the way their users expect; the look and the component vocabulary stay shared across platforms.

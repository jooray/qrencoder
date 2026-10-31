# QREncoder — Spec

A cross-platform rewrite of the old macOS-only QREncoder (MobilioDevelopment): **macOS, Linux,
Android**, built with Flutter 3.47+.

This document covers behaviour, payload formats and platform entry points. The visual language,
layout and component vocabulary are governed by `PRODUCT.md` and `DESIGN.md`; where they disagree
with this file, they win.

## Principles

1. **Live redraw.** The symbol re-renders on every keystroke, field edit and toggle. There is no
   Generate button anywhere. Encoding is synchronous and fast enough that a payload of a few KB
   still lands within a frame.
2. **The caret is always in the input.** On launch, after a template change, after a reset and
   after an Android share, focus sits in the payload box (Text) or in the first field of the
   chosen template. Nothing has to be clicked before typing.
3. **Spec-correct quiet zone.** Per ISO/IEC 18004 the symbol carries a 4-module light border. The
   symbol is always the chosen ink on a white plate; dark mode changes the app chrome and never
   the symbol, and never inverts it.
4. **Local only.** No network calls at runtime, no telemetry, no accounts. Payload contents are
   never written to disk.
5. **Minimal copy.** If a thing just works, the interface does not explain it.

## Surfaces

Owned by `DESIGN.md`. In short: a two-pane desktop layout (controls at the left, plate with the
symbol in the centre, apparatus at the right) and a single scrolling phone column with the
symbol directly under the payload and the actions pinned to the bottom. Breakpoint at 900 px.

**Controls**

- Payload type line: the template name as the largest word, its composed format beside it, and a
  `CHANGE` key that opens the template list.
- Template fields, with the composed payload shown underneath — always editable through the
  fields, always readable as the exact string.
- Error correction: L (7 %) / M (15 %) / Q (25 %) / H (30 %), default **Q**.
- Ink: black plus three alternatives (blue, green, rust), all ≥ 9:1 on white.
- Module scale: 8 / 16 / 32 / 64 px, default 8.
- Symbol style: Default / Standard / Liquid.
- Reset.

**Top bar:** wordmark, the accent dot, and the appearance keys Auto / Light / Dark.

## Templates

Fourteen payloads. Each composes its string from typed fields; the result is displayed in a
monospaced box beneath the form. Only the Text template has a free-form payload box.

| Template | Payload | Fields |
|---|---|---|
| Text | plain UTF-8 | payload (multiline) |
| URL | the URL, `https://` added when no scheme is present | url |
| Wi-Fi | `WIFI:T:<auth>;S:<ssid>;P:<pass>;H:<bool>;;` | network name, password, security (WPA2/WPA/WEP/NONE), hidden (NO/YES) |
| Email | `mailto:<to>?subject=<s>&body=<b>` | to, subject, message |
| Phone | `tel:<number>` (punctuation stripped) | number |
| SMS | `SMSTO:<number>:<message>` | number, message |
| Geo | `geo:<lat>,<lng>` | latitude, longitude |
| Calendar | iCalendar VEVENT, CRLF-terminated, `DTSTART`/`DTEND` as `YYYYMMDDTHHmmss` | title, location, starts, ends, notes |
| Contact | vCard 3.0, CRLF-terminated | name, organisation, phone, email, website |
| Bitcoin | BIP 21 `bitcoin:<address>?amount=&label=&message=` | address, amount, label, message |
| Lightning | `lightning:<BOLT 11 invoice>`; an existing `lightning:` prefix is not doubled | invoice |
| Monero | `monero:<address>?tx_amount=&tx_payment_id=&recipient_name=` | address, amount, payment id, recipient |
| Zcash | ZIP 321 `zcash:<address>?amount=&memo=`; the memo is base64url without padding | address, amount, memo |
| Ethereum / EVM | EIP-681 `ethereum:<address>@<chainId>?value=<wei>` | address, chain id, value in wei |

Escaping follows the formats: Wi-Fi escapes `\ ; , : "`; iCalendar and vCard escape `\ ; ,` and
fold newlines into `\n`; amounts and values are only included when numeric. A template whose
essential field is empty encodes nothing and shows an empty plate.

A fresh launch always starts on **Text**; the template choice is not persisted. Reset returns to
Text with every field empty and the caret back in the payload box.

## Symbol styles

One painting routine draws the preview, the style chips and the exported PNG, so they cannot
disagree.

- **Default** — square modules with a 1 px gap, the finder patterns drawn as rings.
- **Standard** — square modules, no gap.
- **Liquid** — modules merged into blobs, isolated modules as circles, finder eyes as rounded
  rings around rounded cores, never touching their inner square.

Colours are ink on white in every style; the quiet zone is white regardless of theme.

## Import

- **Android share.** The app registers as a `text/plain` `ACTION_SEND` target. Shared text is
  handed straight to the editor as a Text payload — from the cold start intent, or through
  `onNewIntent` while it is already running — so sharing a link from another app produces a
  symbol without any further typing. Focus lands in the payload box.
- **Desktop CLI.** A payload can be passed on the command line: `qrencoder "WIFI:…"`. Argument
  handling is unchanged by the share path.

Structured parsing of shared text into a matching template (for example a `bitcoin:` URI opened
as the Bitcoin form) is deferred; everything arriving today becomes Text, which keeps the
payload byte-exact.

## Export

- **Copy image.** macOS writes the PNG straight to `NSPasteboard`; Android caches it behind a
  `FileProvider` and puts the content URI on the clipboard, so the image pastes as an image.
  Both go through the `qrencoder/clipboard` channel. On Linux the button reads `COPY TEXT` and
  copies the payload string, which is what the platform can do without another native
  dependency.
- **Save PNG.** `file_picker`'s save dialog on every platform (NSSavePanel on macOS, SAF document
  picker on Android); the plugin writes the bytes. The file is
  `qrencoder-<timestamp>.png` at `(modules + 8) × scale` pixels. No resampling anywhere: the
  module edge is always an integer number of pixels.
- **Show in Finder.** On macOS, once a file has been saved, the status line offers
  `SHOW IN FINDER`, which reveals the saved file through `NSWorkspace` (the sandbox will not
  allow shelling out to `open`).
- **Fullscreen scan view** (tap the plate to enlarge) is not implemented in this release.

## Theme

- Auto / Light / Dark keys in the top bar; Auto follows the system.
- The choice is persisted. On macOS the title bar follows through the `qrencoder/window`
  channel's `setAppearance`; on Android the status and navigation bar icons flip with it.
- The plate stays white and the symbol stays ink in all three modes.
- Text on the accent is always `#111110`; white on lime collapses to about 1.4:1.

## Persistence

`shared_preferences` stores error correction, ink, module scale, style and theme. Payload text,
template fields and the payload type are deliberately not stored: a Wi-Fi password must not
survive a restart, and a relaunch should present an empty Text box ready to type into.

## Platform code

Two method channels, both optional — when a channel is missing the Dart side falls back rather
than failing:

| Channel | Methods | Platforms |
|---|---|---|
| `qrencoder/clipboard` | `setPng(bytes)` | macOS (NSPasteboard), Android (FileProvider URI) |
| `qrencoder/window` | `setAppearance(auto\|light\|dark)`, `revealPath(path)` | macOS |
| `qrencoder/share` | `consume` (pending shared text), `onText` (callback) | Android |

## Project site

Static GitHub Pages at <https://jooray.github.io/qrencoder/>, served from `docs/` on `main`.

- **Style:** the world of `DESIGN.md` — same palette, type voices and density — taken to page
  scale.
- **Screenshots:** rendered from the real app by the golden tests in `test/goldens_test.dart`, so
  the page can be regenerated from the code it documents. No mockups.
- **Content:** what it does, the payload list, the three styles, spec claims that can be
  demonstrated, the privacy statement, and a short note that the build was a test of free coding
  models (blog link to come).
- **Build:** plain HTML and CSS, no framework, no bundler, no analytics, no third-party fonts.
- The previous version of the site is kept at `docs/archive/` with an ARCHIVED strip rather than
  deleted.

## Tech stack

- Flutter stable; Material is a widget library only. The visual language is not Material 3.
- Packages: `qr` (encoding), `file_picker` (save dialog), `shared_preferences` (preferences).
  Everything else — painting, layout, clipboard and share plumbing — is local code.
- State: `StatefulWidget` with controllers. No state-management package.
- Android: `applicationId io.bednar.qrencoder`, minSdk from the Flutter template (24), targetSdk
  36, release signed with the shared publisher key kept outside the repository.

## Non-goals

- iOS support (the project compiles, but nothing is signed or tested for it)
- Logo overlays, image-in-the-middle codes, Micro QR
- History of generated codes
- Localisation beyond the English strings in the UI
- Any network feature at all

## Milestones

1. Skeleton: two-pane UI, live symbol from raw text, EC selector, copy and save PNG ✅
2. Payload templates with typed fields and escaping ✅
3. Crypto payloads: BIP 21, BOLT 11, Monero, ZIP 321, EIP-681 ✅
4. Android share receive ✅ · fullscreen scan view ⬜
5. Ink, three symbol styles, dark mode with the appearance keys, persistence, README, screenshots ✅
6. Project site in the app's visual world with real screenshots, old site archived ✅
7. Release: signed Android APK, Zapstore listing, GitHub release, macOS app in `/Applications` ✅

# QREncoder — Spec

A modern rewrite of the old macOS-only QREncoder (MobilioDevelopment). Cross-platform: **Linux, macOS, Android**. Built with Flutter 3.47+.

## Principles

1. **Live redraw.** The QR code re-renders on every keystroke / field change / option toggle. No "Generate" button anywhere. This is the core UX of the old app and must stay instant (< ~16 ms per frame; encoding runs synchronously in Dart, which is fast enough for QR payloads up to a few KB).
2. **Focus on launch.** After the app starts (and after receiving an Android share), keyboard focus lands in the primary input box so you can start typing immediately.
3. **Spec-correct quiet zone.** Per ISO/IEC 18004 the symbol needs a ≥ 4-module light-colored border. In dark mode the *symbol* still renders black-on-white inside that white frame; only the surrounding app chrome goes dark. Never invert the modules themselves.
4. **Fast & small.** No network calls, no telemetry, no heavy state framework. Plain `setState` + a couple of controllers is sufficient at this size.

## UI layout

Two-pane on desktop/tablet landscape, stacked on phone portrait:

- **Left/top pane — controls:**
  - Content type dropdown (templates below)
  - Template fields **or** raw text area (toggle via "Edit raw" — mirrors the old app's Edit button)
  - Error correction level: L (7%) / M (15%) / Q (25%) / H (30%), default **Q** (better for screen-scanning and damaged prints than the old app's L default)
  - Module scale for export (default 8 px/module → crisp PNGs; preview always fits its container)
  - Foreground/background color pickers (defaults black/white; warn when contrast ratio < 4:1 since scanners need it)
  - Reset button
- **Right/bottom pane — preview:**
  - QR centered, fills available space, white quiet-zone padding drawn around it regardless of theme
  - Tap/click preview → fullscreen scan-friendly view (old app's "scan it from display")
- **Toolbar actions:** Copy image to clipboard · Save as PNG · Share (Android/native share sheet)

## Templates

Each template = typed form fields → encoded payload string. Raw mode always shows/edits the resulting string.

| Template | Payload format | Fields |
|---|---|---|
| Text | plain UTF-8 | multiline text |
| URL | the URL | url (auto-prefix `https://` if scheme missing) |
| Wi-Fi | `WIFI:T:<type>;S:<ssid>;P:<pass>;H:<hidden>;;` | SSID, password, type (WPA/WPA2, WEP, nopass), hidden flag. Escape `\ ; , : "` per spec |
| Email | `mailto:` URI | to, subject, body |
| Phone | `tel:` URI | number |
| SMS | `SMSTO:<number>:<body>` | number, message |
| Geo location | `geo:<lat>,<lng>` | lat, lng (+ optional label as query param) |
| Calendar event | iCalendar VEVENT one-liner `BEGIN:VEVENT\nSUMMARY:...\nDTSTART:...\nDTEND:...\nLOCATION:...\nDESCRIPTION:...\nEND:VEVENT` | title, start, end, location, description. Dates formatted `YYYYMMDDTHHmmssZ` (UTC) |
| Contact (vCard) | vCard 3.0 | name, company, phone, email, address, address2, website, memo |
| Bitcoin | BIP 21 `bitcoin:<address>?amount=<amt>&label=<lbl>&message=<msg>` | address, amount (optional), label, message |
| Lightning invoice | BOLT 11 `lightning:<invoice>` (+ `?amount=`) | invoice, amount |
| Monero | `monero:<address>?tx_amount=<amt>&recipient_name=<n>&description=<d>` | address, amount, recipient name, payment id, description |
| Zcash | ZIP 321 `zcash:<address>?amount=&memo=&label=` | address, amount, memo (URL-encoded), label |
| Ethereum / EVM chain | EIP-681 `ethereum:<address>@<chainId>?amount=` | address, amount, chain ID (default 1) |

Dropped vs old app (per your instruction): iTunes/App-store URLs, Foursquare, YouTube-iOS, Tweet-on-Twitter, Micro QR, printing-scale-as-size. Barcode/Micro-QR toggles out; keep plain QR only.

## Import (Android share + deep links)

- **Android:** `receive_sharing_intent` registers SEND/SEND_MULTIPLE intent filters (`text/plain`, plus custom schemes). Incoming text pre-fills the matching template:
  - `bitcoin:` / `lightning:` / `lnbc` / `monero:` / `zcash:` / `ethereum:` → respective crypto template, address parsed into fields
  - `http(s)://`, `mailto:`, `tel:`, `smsto:`, `geo:` → URL/email/phone/SMS/geo
  - anything else → Text
- Focus jumps to the first empty relevant field (or the raw box) after import.
- Desktop: accept a cold-launch CLI arg (`qrencoder "some text"`) as the same import path. Nice-to-have, not blocking.

## Export

- **Copy to clipboard:** `share_plus`'s `SharePlus.instance.share(ShareParams(files: [XFile.fromData(png, mimeType: 'image/png')]))` on mobile; on desktop use platform image-clipboard (macOS/Linux: `Clipboard.setDataImage` via `super_clipboard` package or fallback to saving to temp + notifying). Decision during impl: prefer `super_clipboard` for true image-on-clipboard on mac/linux.
- **Save as PNG:** file picker save dialog (desktop) / share-sheet + MediaStore write (Android). Rendered offscreen at moduleScale × modules, with 4-module white quiet zone baked in.
- **Scan from display:** tap preview → immersive fullscreen, black bars top/bottom kept minimal, symbol as large as possible. Back/tap exits.

## Dark mode

- Follows system theme (Light / Dark / System toggle in settings menu).
- App chrome adapts; **the QR canvas never does**: symbol background stays white, modules stay the chosen fg color (default black). A thin themed border separates card from page so it looks intentional in dark mode.

## Persistence

Remember last content type + colors + EC level + theme preference via `shared_preferences`. Do **not** persist payload contents (privacy: Wi-Fi passwords, seed-adjacent data).

## Tech stack

- Flutter stable, Material 3
- Packages: `qr_flutter` (rendering), `share_plus`, `receive_sharing_intent`, `file_picker`, `path_provider`, `shared_preferences`, `super_clipboard` (desktop image clipboard)
- State: plain StatefulWidget + controllers; single `AppConfig` value object recomputed on change
- Android manifest: intent filters for SHARE text/plain; minSdk 21+
- CI later: GitHub Actions matrix (linux/macos build, android apk) — out of scope for v1

## Non-goals (v1)

- iOS support (code compiles for it, but no signing/testing effort)
- Custom logo overlays / stylized dot QR styles
- History of generated codes
- Localization beyond English strings file stub

## Milestones

1. Skeleton: two-pane UI, live QR from raw text, EC selector, copy/save PNG (desktop) ✅ target for first commit
2. Templates + structured↔raw sync, escaping
3. Crypto templates + BIP21/EIP681/ZIP321 parsing on import
4. Android share receive + fullscreen scan mode
5. Colors, dark mode, persistence, polish, README + screenshots
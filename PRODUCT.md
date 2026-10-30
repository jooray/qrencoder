# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter 3.47+ (Dart), Material 3, `qr_flutter`, `share_plus`, `receive_sharing_intent`, `file_picker`, `path_provider`, `shared_preferences`, `super_clipboard`.

## Users

Power users on desktop (macOS, Linux) and mobile (Android) who need to rapidly send data from screen to phone or export QR images. They value speed, keyboard-first operation, and offline privacy above all.

## Product Purpose

QREncoder provides instant, privacy-respecting, zero-click QR code generation for text, URLs, Wi-Fi credentials, contacts, email, geo, and crypto/lightning payments. Success means zero delay between intent and a scannable symbol.

## Positioning

Pure live redraw on every keystroke without a "Generate" button, keyboard-centric controls, spec-correct quiet zones in light and dark modes, zero telemetry or network calls, and rich native crypto/URI payload templates (Bitcoin BIP21, Lightning BOLT11, Monero, Zcash, Ethereum EIP-681).

## Operating Context

- Cold-launch or hotkey launch on desktop: focus lands immediately in the input field.
- Receiving Android shares/intents or deep links: auto-selects template and populates fields.
- Immediate screen scanning from desktop monitor to phone camera, or quick "Copy image to clipboard" / "Save PNG" for insertion into web/docs.

## Capabilities and Constraints

- Instant sync between template fields and raw text representation.
- ISO/IEC 18004 spec-correct quiet zone (≥4 modules light border) preserved even in dark mode.
- Offline-only, zero network dependencies, local preference storage (colors, error correction level, theme) with zero payload history retention for privacy.
- Standard QR codes only (Micro QR, barcodes, custom dot logos explicitly out of scope).

## Brand Commitments

- Name: QREncoder
- Clean, high-contrast, utility-first dark and light themes that respect Material 3 without looking generic.

## Evidence on Hand

- SPEC.md detailing UI layout, template formats, import/export rules, and non-goals.
- Existing Flutter skeleton project (`lib/main.dart`, `pubspec.yaml`).

## Product Principles

1. **Instant feedback over manual triggers:** Live redraw on every keystroke/toggle, zero "Generate" or "Apply" buttons.
2. **Keyboard-first velocity:** Focus is on launch; all template fields, actions, and modes are navigable without touch/mouse friction.
3. **Scan reliability over dark-mode aesthetic:** The QR symbol canvas and quiet zone never invert or compromise scanner readability regardless of dark chrome theme.
4. **Privacy by default:** Pure local synchronous execution; payloads never leave the device or persist across restarts.

## Accessibility & Inclusion

- Keyboard focus traps avoided; clear focus indicators for screen reader and keyboard navigation.
- Minimum 4:1 contrast ratio warning on custom foreground/background color selections.
- Scalable crisp preview and fullscreen scan view for display scanning.

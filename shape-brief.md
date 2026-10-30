# QREncoder — Shape Brief

## Job and audience
Power users on macOS/Linux/Android who need to move data from screen to device in seconds. They work keyboard-first, value zero telemetry, and expect instant live redraw. Mode: Operate — complete a quick encoding task with no friction.

## Outcome and proof
Primary task: select template → fill fields (or paste raw) → see a spec-correct QR immediately. Success = first keystroke focuses input; symbol updates <16 ms; scanner-readable quiet zone preserved in dark mode; zero network. Proof: live redraw demo, color-contrast warning, export to PNG/clipboard/share works offline.

## Selected direction
Visual authority: Editorial/technical specimen sheet inside Material 3. World = a technical reference manual/workshop specimen board, not a consumer app.

- Palette: paper-white QR canvas with ink-black modules. App chrome is near-neutral graphite/ivory, one restrained accent for state. Dark mode keeps QR white-on-white with themed chrome only.
- Type: system UI sans for controls, monospaced figures for code/URIs. Headings set in a crisp text face with tight leading.
- Density: compact, two-pane desktop (controls left/top, preview right/bottom), stacked on phone. Hairline dividers, no drop shadows.
- Signature move: the QR preview is always a specimen: centred on a calibrated white field with a 4-module quiet zone visible as a measurable border, like a print spec sheet. Focus rings and contrast warnings behave as marginalia.

Seed reference: seed:51907c602ca3da24 (operate direction concept-seed c16fe0d5b1bac747ff799aee21c8bcb2, assignment index 7).

## Scope and boundaries
Fidelity: production-ready screen, first viewport + core flow. Breadth: all 13 templates per SPEC.md with structured↔raw sync, EC selector, colors, module scale, copy/save/share, fullscreen scan view. Target: `lib/main.dart` rewrite to real two-pane UI.
What remains untouched: iOS signing/testing, custom logo overlays, history, localization beyond English stub.
Anti-goals: no “Generate” button, no network calls, no decorative gamification.

## States and ranges
Content ranges: raw text up to a few KB; Wi-Fi SSID/pass, URLs up to ~2000 chars, crypto addresses, CSV-ish vCard fields.
States: first-run empty, loading (none, sync is instant), error (invalid payload, contrast <4:1), empty template, import from Android share/deep link, fullscreen scan mode, permissions on first clipboard/save.
Interaction: keyboard-first; focus lands in input on launch; tab order controls → preview → actions.

## Interaction and layout
Hierarchy: template selector top, fields stacked, options row (EC, scale, colors, reset) below. Right/bottom preview dominates space, centred QR with quiet zone. Toolbar actions under preview: Copy image, Save PNG, Share.
Topology: desktop = left controls 38% / right preview 62% with a vertical hairline. Mobile = top controls, bottom preview sticky. Responsive rail collapses controls into a sheet.
Affordances: live redraw on every keystroke; Edit raw toggle mirrors old app. Feedback: inline validation, contrast warning badge, focus ring, hover states.
Constraints: offline-only, accessibility keyboard nav + screen reader, 4:1 contrast warning, Material 3 dark/light following system.

Open decisions: exact font pairing for editorial feel, accent hue, panel collapse priority for narrow widths. Do not invent token values yet — those follow the direction contract.

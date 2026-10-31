---
name: QREncoder
description: A local-only QR generator that treats its symbol like a specimen plate.
colors:
  newsprint: "#F5F3EE"
  ink: "#111110"
  accent: "#D8FF3E"
  muted: "#6B6B62"
  muted-dark: "#9C9C93"
  plate: "#FFFFFF"
  ink-blue: "#16324F"
  ink-green: "#0E4B3A"
  ink-rust: "#6B1F1A"
typography:
  display:
    fontFamily: "Silkscreen, monospace"
    fontSize: "29px"
    fontWeight: 400
    lineHeight: 1.05
    letterSpacing: "0.02em"
  title:
    fontFamily: "Silkscreen, monospace"
    fontSize: "20px"
    fontWeight: 400
    lineHeight: 1.05
    letterSpacing: "0.03em"
  label:
    fontFamily: "Barlow, system-ui, sans-serif"
    fontSize: "9px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.19em"
  body:
    fontFamily: "Barlow, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0em"
  mono:
    fontFamily: "Courier Prime, monospace"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: "0em"
rounded:
  none: "0px"
spacing:
  x1: "4px"
  x2: "8px"
  x3: "12px"
  x4: "18px"
  x5: "24px"
  x6: "32px"
  x7: "40px"
  x8: "56px"
  x9: "76px"
components:
  key-selected:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "0 12px"
    height: "38px"
  key-unselected:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "0 12px"
    height: "38px"
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.newsprint}"
    rounded: "{rounded.none}"
    padding: "9px 14px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "9px 14px"
  input:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "8px 10px"
  chip-style:
    backgroundColor: "{colors.newsprint}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "6px"
  plate:
    backgroundColor: "{colors.plate}"
    rounded: "{rounded.none}"
    padding: "26px"
---

# Design System: QREncoder

## Overview

**The Bitmap Specimen.** The app is a lab plate for a QR symbol: a printed sheet with a big
measured specimen in the middle, the parameters that produced it along the edge, and nothing
else on the page. It borrows the vocabulary of technical printing — hairlines, crop ticks,
tabular figures, silkscreen capitals — and refuses everything that would make it feel like a
consumer app: no cards, no shadows, no rounded corners, no gradients, no Material 3.

The symbol is the only object allowed to be photographic. Everything around it is a rule, a
number, or a control. If a piece of copy is not a label, a number or an error, it is not there.

**Key characteristics**

- Newsprint ground, near-black ink, one acid-lime accent used as a highlighter, never as a fill.
- Three voices with strict jobs: Silkscreen for numbers and names, Barlow for control labels,
  Courier Prime for anything that is an encoded string.
- 1 px hairlines inside a section, 2 px rules around it. Structure is drawn, not shadowed.
- Two pane desktop: controls at 100, plate at 135. Phone: one column, symbol directly under the
  payload, actions pinned.
- The plate is always white and the modules always dark, in both themes.

## Colors

- **Newsprint `#F5F3EE`** — the ground in light mode; the text colour in dark mode.
- **Ink `#111110`** — type, rules, module colour, and the dark ground.
- **Accent `#D8FF3E`** — a highlighter. Selected keys, the brand dot, focus rings, the contrast
  warning. Text on accent is always `#111110`, in both themes; white on lime is unreadable.
- **Muted `#6B6B62` / `#9C9C93`** — captions, hints, disabled labels. 4.7:1 or better on its ground.
- **Plate `#FFFFFF`** — the symbol's quiet zone. Never tinted, never themed.
- **Ink blue / green / rust** — the three alternative module colours, all ≥ 9:1 on white.

Dark mode swaps ground and ink, darkens nothing else. The plate and the modules do not move.

## Typography

- **Silkscreen** for the payload type, section numerals, module counts, scale figures, button
  labels and key letters. All caps, tracked, never below 10 px.
- **Barlow 600** for 8–9 px uppercase section labels at 1.9 px tracking. Lowercase Barlow 400,
  14–15 px, for input text and body sentences.
- **Courier Prime** for composed payload strings, hints inside empty states, and the
  `EXPORT = (MODULES + 8) × SCALE` note on the site.

Numbers are tabular by construction: they sit in their own column (the apparatus) rather than
floating in prose.

## Layout

- Desktop (≥ 900 px): 66 px top bar, then two panes — controls 100, plate 135 — divided by a 2 px
  rule. The apparatus is a 232 px column at the right edge of the plate pane, separated by a 1 px
  hairline; the footer is 60 px and holds status, Copy, Save and Reset.
- Phone (< 900 px): 58 px top bar, one scrolling column in the order payload → symbol → error
  correction → ink → module scale → style → apparatus, with the action bar pinned to the bottom.
- Rhythm: 18 px between controls, 24–26 px between groups, 8–12 px inside a group.
- The plate takes the largest integer module scale that fits, so the symbol is always drawn 1:1
  and never resampled.

## Elevation & Depth

There is no elevation. Depth is expressed with rules and inset frames: 2 px for a boundary the
user is meant to see, 1 px for a subdivision, hairline at 25 % ink for ticks and disabled
outlines. No shadows, no blur, no translucency except the picker scrim (10 % ink).

## Shapes

Square, always. Zero radius on keys, inputs, chips and buttons. The only curves in the product
belong to the symbol itself: the Liquid style rounds module corners, turns isolated modules into
circles and draws the three finder eyes as rounded rings around rounded cores.

## Components

- **Key** (error correction, security, hidden network, appearance): 38 px tall, 1 px ink border
  when idle, 2 px ink border plus accent fill when selected. Text is always the ink colour, so
  the accent never swallows its own label.
- **Text field**: 1 px ink border, 8–10 px inner padding, Barlow 14–15 px. Focus is the caret;
  there is no focus ring beyond the accent selection colour.
- **Payload header**: uppercase Barlow label, 1 px rule beneath, character count in Courier Prime
  at the right.
- **Style chip**: a white plate holding a 48 px live sample of the symbol painted by the same
  routine as the export, the style name beneath in 8 px Barlow.
- **Module ladder**: four scale steps drawn as literal squares of 8, 16, 32 and 64 px, selected
  one marked with a 2 px accent frame and an accent underline; each target is at least 48 px.
- **Template picker**: a bordered panel anchored under the payload type line — lime 4 px cap,
  fourteen rows at 40 px, name in Barlow 600, composed format right-aligned in Courier Prime.
- **Apparatus**: a stack of measurements, each label in 8 px muted Barlow over a Silkscreen value,
  separated by hairlines.

## Do's and Don'ts

**Do**

- Do keep the symbol ink-on-white in every theme, at an integer module scale, with the four-module
  quiet zone intact.
- Do put a control's current value where the control is: the type line names the payload type, the
  scale ladder shows `8 PX`, the apparatus repeats the numbers.
- Do use the accent as a highlight — a fill behind a selected key, a 3 px underline, a 7 px dot.
- Do state failures plainly: `CANNOT ENCODE`, `TOO LONG FOR Q — LOWER THE LEVEL`.

**Don't**

- Don't use rounded corners, cards, shadows, gradients or Material 3 components in the chrome.
- Don't put white text on the lime accent; contrast collapses to 1.4:1.
- Don't leave explanatory prose in the interface. If it works, it does not need to be described.
- Don't theme the plate, the quiet zone or the modules.
- Don't add a Generate button, a spinner, or any confirm step between typing and the symbol.

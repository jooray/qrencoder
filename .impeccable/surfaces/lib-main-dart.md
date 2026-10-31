---
version: 1
slug: "lib-main-dart"
primary_target: "lib/main.dart"
related_targets: []
---

# Surface brief — main editor

## Scope

QREncoder's main editor: the only screen in v1, desktop-first, same surface on Android. Visitor mode: **Operate**.

## Audience and job

A privacy-minded technical user, keyboard-first on macOS, arriving cold or through the Android share sheet with a payload already in hand. They type or receive content, need a correct symbol within a second, then copy it, save it, or hold the screen up to be scanned. No intermediate screen, no confirmation step.

## Task and proof

Type → symbol, live on every keystroke. EC level, module scale and both colours stay visible and measurable; the encoded string stays readable and editable in place. What the surface must prove, and what a browser generator cannot show: the module grid at 1:1 and the export size in whole pixels. Scale is something the user sees, not a number they trust.

## Direction

**The Bitmap Specimen** — dealt challenger 2 of 6, chosen over the assigned 80-Column Record. The world lends type, palette, density and one signature move; it does not lend the layout, the navigation or the controls. Memorable moment: the module ladder and the 1:1 grid sitting in the same frame.

## Boundaries

First viewport defined at 1440×900; responsive behaviour, every state, and the content below the fold are owed by the build. Not Material 3. No shadows, no rounded cards, no icon tiles, no gradients. Untouched: payload formats, quiet zone, never-invert rule, zero network.

## Open decisions

Desktop image clipboard (`super_clipboard` vs. temp file). The Android phone arrangement of this same screen: stacked, ladder retained, measurement margin moved beneath the symbol.

## Direction contract

THESIS: The symbol is the product and the interface is honest to the pixel — every module a whole unit, every number that decides whether it scans printed and measured. It refuses the category's rounded card with a form at left and a decorative code at right.

OWN-WORLD: Newsprint #f5f3ee ground, near-black #111110 ink, one synthetic accent #d8ff3e reserved for the active selection and the measured edge. Silkscreen for the single display figure and measurement numerals, Archivo for every label, control and value, Courier for the encoded string. Square corners, 2–3px rules, no shadows. Density comes from numerals in a margin, never from chips. Signature vocabulary: the module ladder, the 1:1 grid, the tabular measurement column.

STORY: The user types a Wi-Fi password, watches the symbol appear and the module count, export size and contrast recompute as they type, and understands this tool is exact about what it hands them. They copy the image without wondering whether it will scan.

FIRST VIEWPORT: Split 1fr / 1.35fr. Left on newsprint: a Silkscreen display line stating the live scale ("8 PX PER MODULE"), then ruled field rows at 9px tracked labels over 19px values — network, security, password, EC. A module ladder at bottom left: squares at 1×, 2×, 4×, 8× with Silkscreen multipliers. Right on white: the symbol at 1:1 with its module grid exposed and the encoded string beneath, the active field's span marked in accent; a measurement column to its right. Primary action, Copy image, black-filled in a ruled footer bar.

FORM: Dealt challenger 2 of 6 (Emigre bitmap specimen, `emigre-bitmap-specimen`), chosen over assigned candidate 3. `seed:81c94841a248ba47`.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

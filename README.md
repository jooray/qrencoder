# QREncoder

A local-only QR generator for macOS, Linux and Android. Type or paste, or compose one of
fourteen payloads — Wi-Fi, vCard, BIP 21, EIP-681 and the rest — and the symbol is drawn on the
next frame. There is no Generate button, no network call and no stored payload.

The project page lives at <https://jooray.github.io/qrencoder/>.

![The editor](docs/img/editor.png)

## What it does

- **Live redraw.** Every keystroke re-encodes; encoding is synchronous, so there is nothing to
  wait for. The caret is in the payload box the moment the window opens.
- **Fourteen payloads.** Text, URL, Wi-Fi, email, phone, SMS, geo, calendar (iCalendar VEVENT),
  contact (vCard 3.0), Bitcoin (BIP 21), Lightning (BOLT 11), Monero, Zcash (ZIP 321) and
  Ethereum/EVM (EIP-681). Each composes its string from typed fields and shows the result
  underneath.
- **Three symbol styles.** Default (1 px module gap), Standard (plain squares) and Liquid
  (merged blobs with the finder eyes preserved). Preview, style chip and exported PNG come from
  one painting routine.
- **Spec-correct exports.** ISO/IEC 18004 four-module quiet zone, integer module scale, PNG at
  `(modules + 8) × scale` pixels. The symbol is always dark on a white plate; dark mode changes
  the chrome, never the symbol.
- **Theme Auto / Light / Dark**, with the macOS title bar and the Android system bars following
  the choice.
- **Share into it on Android.** Share a link from any app and QREncoder opens with the symbol
  already drawn.
- **Nothing leaves the machine.** No network requests at runtime, no telemetry, no accounts.
  Preferences (error correction, ink, scale, style, theme) are remembered; payload contents
  never are.

## Install

- **macOS** — build it from source ([instructions below](#building-on-macos)). There is no
  signed or notarized macOS download.
- **Android** — `qrencoder-<version>.apk` from the same page, or update it with
  [Obtainium](https://github.com/ImranR98/Obtainium) pointing at those releases. It is also on
  [Zapstore](https://zapstore.dev/apps/io.bednar.qrencoder).
- **Linux** — build and run from source; there is no packaged build yet.

## Build and run

Requires Flutter 3.47 or newer.

```sh
flutter pub get
flutter run -d macos
flutter build macos --release

flutter run -d <android-device>
flutter build apk --release
```

The macOS window opens at 1440 × 900. A payload can also arrive on the command line:

```sh
qrencoder "WIFI:T:WPA2;S:Cafe;P:secret;;"
```

Android release builds are signed with the publisher key at
`~/.apk-signing-keystore/signing.properties`. Without that file `flutter build apk --release`
fails on purpose, rather than quietly producing a debug-signed APK. For a throwaway local test
build use `flutter build apk --debug`, or set `allowDebugSigning=true` in
`~/.gradle/gradle.properties` to get a debug-signed release APK (never publish that one).

### Building on macOS

The macOS app is not signed with an Apple Developer ID and is not notarized, so a downloaded
binary would be blocked by Gatekeeper. Build it yourself instead:

1. Install Xcode (with the command line tools) and Flutter 3.47 or newer.
2. `git clone https://github.com/jooray/qrencoder && cd qrencoder`
3. `flutter pub get && flutter build macos --release`
4. The app is at `build/macos/Build/Products/Release/qrencoder.app`. Copy it to `/Applications`
   or run it where it is.

An app you compiled on your own machine runs normally. If macOS still refuses to open it (for
example after you copied it from another computer), right-click the app, choose Open, and
confirm, or remove the quarantine flag: `xattr -dr com.apple.quarantine /path/to/qrencoder.app`.
Do this only for builds you made yourself or have verified from the source.

## Tests

```sh
flutter test                 # payload composition, widget behaviour, screenshots
flutter test --update-goldens test/goldens_test.dart
```

Screenshots in `docs/img/` are rendered by the golden tests, so the site can be regenerated
from the same code it documents.

## About this build

QREncoder 1.1.0 was built by an agent running on **free tokens** — DeepSeek 4.1 Flash on its free
tier — with nothing paid anywhere in the loop. It is not a demo or a benchmark artefact: it is
the QR generator its author uses, standing in for a Mac app that is no longer maintained.

The app, the site and the release came out of that session working from a written spec
(`SPEC.md`) and a design brief (`DESIGN.md`). The experiment, its numbers, and the rougher first
build from a pool of free models are written up in:

- [Token poverty: can you use freely available AI to do productive work?](https://juraj.bednar.io/en/blog-en/2026/10/31/token-poverty-can-you-use-freely-available-ai-to-do-productive-work/) (English)
- [Tokenová chudoba: dá sa s voľne dostupnou AI robiť produktívna práca?](https://juraj.bednar.io/blog/2026/10/31/tokenova-chudoba-da-sa-s-volne-dostupnou-ai-robit-produktivna-praca/) (Slovak)

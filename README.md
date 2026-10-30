# QREncoder

Modern, lightning-fast, offline-first QR code generator for macOS, Linux, and Android. Built with Flutter, it ensures instant, zero-click QR generation for all your technical and crypto needs.

## Features

- **Live Redraw:** Generates instantly on every keystroke. No generate button required.
- **Templates:**
  - Standard: Text, URL, Wi-Fi, Calendar, vCard, Email, Phone, SMS, Geo location.
  - Crypto: Bitcoin (BIP-21), Lightning (BOLT-11), Monero, Zcash (ZIP-321), and Ethereum (EIP-681).
- **Spec-Correct Quiet Zone:** Complies strictly with ISO/IEC 18004 standards, ensuring a 4-module light-colored border.
- **Android Integration:** Receive text and URLs directly from other apps via Android share intent.
- **Export & Share:** Copy image to clipboard, save as PNG, or share natively via your device's share sheet.
- **Dark Mode Aware:** App chrome adapts to your system theme, while the QR symbol remains high-contrast black-on-white.

## Screenshots

### Main Workspace
![Main Workspace](screenshots/screenshot1.png)

### Crypto Template (Bitcoin)
![Bitcoin Template](screenshots/screenshot2.png)

## Installation

### macOS
Download the latest `.app` from the [Releases](https://github.com/jooray/qrencoder/releases) page.

### Android
Download the latest `.apk` from the [Releases](https://github.com/jooray/qrencoder/releases) page.

### Linux
Download the source or build directly from the repository.

## Build

```bash
flutter pub get
flutter run
flutter build macos --release
flutter build apk --release
```

## License
MIT
EOF

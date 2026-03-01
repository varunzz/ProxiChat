# ProxiChat 📡

A peer-to-peer proximity messaging app built with Flutter that allows users to discover nearby devices and exchange messages **completely offline** — no internet, no server, no accounts required.

---

## Demo

> Two devices discovering each other and exchanging messages in real time over Bluetooth/WiFi Direct with zero internet connectivity.

| Home Screen | Devices Screen | Chat Screen |
|---|---|---|
| <img src="screenshots/user1_home.png" width="200"/> | <img src="screenshots/user1_devices.png" width="200"/> | <img src="screenshots/user1_chat.png" width="200"/> |

## How It Works

ProxiChat uses **Google's Nearby Connections API** to discover and communicate with nearby devices. Under the hood, the API intelligently switches between Bluetooth Low Energy (BLE) and WiFi Direct to establish the fastest and most reliable connection available — all without any internet connection or central server.

```
Device A                          Device B
   |                                 |
   |── startAdvertising() ────────>  |
   |                                 |── startDiscovery()
   |<─────────── Device Found ───────|
   |                                 |
   |<─────── Connect Request ────────|
   |─────── Accept Connection ──────>|
   |                                 |
   |<========= Send Messages =======>|
        (BLE + WiFi Direct, no internet)
```

---

## Features

- 🔍 **Device Discovery** — Automatically finds nearby devices running ProxiChat
- 💬 **Real-time Messaging** — Send and receive text messages instantly
- 📶 **Completely Offline** — Works without internet, WiFi, or mobile data
- 🔒 **No Accounts** — No sign up, no login, no data stored on any server
- ⚡ **Auto-connect** — Devices auto-accept connections for seamless experience
- 🔄 **Multi-device** — Connect and chat with multiple nearby devices simultaneously

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| P2P Communication | Google Nearby Connections API |
| Permissions | permission_handler |
| Platform | Android |

---

## Architecture

```
proxichat/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── screens/
│   │   ├── home_screen.dart       # Username input & app entry
│   │   ├── devices_screen.dart    # Nearby device discovery & connection
│   │   └── chat_screen.dart       # Real-time messaging UI
│   └── services/
│       └── nearby_service.dart    # P2P networking layer (Singleton)
├── android/                       # Android configuration & permissions
└── pubspec.yaml                   # Dependencies
```

The app follows a clean **service-based architecture** where all P2P networking logic is abstracted into `NearbyService` using the Singleton pattern. Screens communicate with the service via callbacks, keeping UI and networking concerns completely separate.

---

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Android Studio
- Two Android devices (API 24+) or one device + emulator

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/proxichat.git
cd proxichat
```

2. Install dependencies
```bash
flutter pub get
```

3. Run on device
```bash
flutter run
```

### Build APK
```bash
flutter build apk --release
```

---

## Permissions Required

ProxiChat requires the following permissions for Nearby Connections to work:

- **Bluetooth** — Device discovery and communication
- **Location** — Required by Android for BLE scanning
- **Nearby WiFi Devices** — WiFi Direct communication

---

## Key Technical Concepts

**Singleton Service Pattern** — A single `NearbyService` instance manages all P2P connections across the app lifecycle, preventing duplicate connections and ensuring consistent state.

**Callback Architecture** — The service layer communicates with the UI layer through function callbacks (`onDeviceFound`, `onMessageReceived` etc.), keeping networking and UI logic fully decoupled.

**Byte Payload Transmission** — Messages are encoded from `String` to `Uint8List` (bytes) before transmission and decoded back on receipt, matching how the Nearby Connections API transfers data.

**Guard Flags** — `_isAdvertising` and `_isDiscovering` boolean guards prevent the Nearby API from being called multiple times simultaneously, avoiding `STATUS_ALREADY_DISCOVERING` errors.

---

## Roadmap

- [ ] Image and file sharing
- [ ] Push-to-talk walkie talkie feature
- [ ] Message notifications when app is in background
- [ ] Message history (local storage)
- [ ] iOS support via Multipeer Connectivity
- [ ] End-to-end encryption

---

## Limitations

- Android only (iOS support planned)
- Both devices must have ProxiChat installed
- Range limited to ~100m (Bluetooth) or ~200m (WiFi Direct)
- No message persistence — messages are lost when app closes

---

## What I Learned

Building ProxiChat gave me hands-on experience with:
- Cross-platform mobile development with **Flutter & Dart**
- **Peer-to-peer networking** using Bluetooth and WiFi Direct
- **Async programming** patterns in Dart
- Android permissions and **manifest configuration**
- **Service-based architecture** and the Singleton design pattern
- Real-world debugging of hardware-level communication issues

---

## License

MIT License — feel free to use this project as a reference or build on top of it.

---

Built with Flutter 💙
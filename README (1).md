# 🎬 AList Flutter App

AList සඳහා ලස්සන Flutter Android App — video streaming, image viewing, සහ high-speed networking සහිතව.

---

## ✨ Features

- 🎥 **High-Performance Video Player** — media_kit භාවිතා කරයි (libmpv)
  - Speed control (0.5x → 2.0x)
  - 10-second skip (double-tap)
  - Volume & brightness sliders
  - Fullscreen / landscape mode
  - 64MB buffer for smooth streaming
- 📁 **File Browser** — List/Grid view toggle
- 🖼️ **Image Viewer** — Zoom, pan with InteractiveViewer
- 🌙 **Beautiful Dark Theme** — Purple/teal gradient design
- 🔐 **Auth Support** — Username/password OR API token
- ⚡ **Fast Networking** — HTTP/Dio with timeout tuning
- 📱 **Android optimized** — cleartext HTTP support, hardware acceleration

---

## 🚀 Setup Instructions

### 1. Prerequisites

```bash
flutter --version   # needs Flutter >= 3.10
```

### 2. Create New Flutter Project

```bash
flutter create alist_app
cd alist_app
```

### 3. Copy Files

Replace/merge these files:
```
lib/
  main.dart
  theme/app_theme.dart
  models/file_model.dart
  models/server_config.dart
  services/alist_service.dart
  screens/home_screen.dart
  screens/server_setup_screen.dart
  screens/file_browser_screen.dart
  screens/video_player_screen.dart
  screens/image_viewer_screen.dart
pubspec.yaml
android/app/src/main/AndroidManifest.xml
```

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Initialize media_kit in main.dart

`main.dart` හි `main()` function ට `MediaKit.ensureInitialized();` add කරන්න:

```dart
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // ← Add this
  runApp(const AlistApp());
}
```

### 6. Build & Run

```bash
flutter run                          # Debug
flutter build apk --release          # Release APK
flutter build apk --split-per-abi    # Smaller APKs per architecture
```

---

## 📦 Key Dependencies

| Package | Purpose |
|--------|---------|
| `media_kit` + `media_kit_video` | High-performance video player (libmpv) |
| `cached_network_image` | Fast image loading with cache |
| `http` / `dio` | AList API communication |
| `shared_preferences` | Save server settings |
| `flutter_animate` | Beautiful animations |

---

## 🔧 AList Server Configuration

1. App open කළාට පස්සේ server URL enter කරන්න (e.g., `http://192.168.1.100:5244`)
2. Username/password හෝ API token enter කරන්න
3. **Connect** tap කරන්න

### Guest Access
Username/password හෝ token නැතිව connect කළ හැකිය (public AList servers).

---

## 🎨 Theme Colors

| Color | Value |
|-------|-------|
| Primary (Purple) | `#6C63FF` |
| Secondary (Teal) | `#00D4AA` |
| Accent (Red) | `#FF6B6B` |
| Background | `#0A0A0F` |

---

## ⚡ High-Speed Network Tips

- `AndroidManifest.xml` හි `android:usesCleartextTraffic="true"` — HTTP support
- `android:largeHeap="true"` — More memory for large files
- `bufferSize: 64 * 1024 * 1024` — 64MB video buffer
- WiFi/LAN streaming optimized

---

## 📝 License

MIT License — Free to use and modify.

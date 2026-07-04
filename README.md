# Depth Wallpaper — iOS-Style Depth Effect on Android

Depth Wallpaper is a feature-rich Flutter application that brings iOS-style depth effect wallpapers to Android. By isolating subjects (people, animals, mountains, buildings, etc.) and rendering them in front of a customizable lock screen clock, the app creates a stunning 3D depth illusion. 

It includes an AI-powered subject segmenter, a manual touch-interactive mask refinement canvas with 6x pinch-to-zoom navigation, customizable clock typography/transforms, and a high-performance native Kotlin Live Wallpaper Service.

---

## 🚀 Features

### 1. Interactive Onboarding & Workspace
* **Step-by-Step Onboarding**: Beautiful animated slides introducing depth effects, AI segmentation, customization, and wallpaper applications.
* **Workspace Dashboard**: 
  * Manage multiple design projects as grid cards with custom staggered scale/fade animations.
  * Deep duplication support (copies physical background/foreground files on disk to prevent path collisions).
  * Dynamic sandbox path resolution to ensure image paths remain valid across app updates.
  * Project deletion with automatic physical file cleanup.

### 2. AI-Powered Subject Segmentation
* **Google ML Kit Integration**: Utilizes local TensorFlow Lite models to isolate the prominent subject automatically on import.
* **Stable Combined Mask Extraction**: Fast and reliable foreground segmentation that works flawlessly with a single tap.

### 3. Manual Mask Refinement Editor
* **Brush Tool**: Paint to add extra regions (displayed as a semi-transparent red overlay) to the depth layer.
* **Eraser Tool**: Use an eraser with `BlendMode.clear` compositing to rub out unwanted mask areas.
* **Brush Size Control**: Scale stroke diameters dynamically from 5px to 60px using a slider.
* **Touch Cursor Indicator**: Displays a Photoshop-like circle outline representing the brush size under the touch coordinates.
* **Undo & Redo Stacks**: Full history memory to easily undo or redo individual paint strokes.
* **Reset Option**: Discard all paint strokes and start fresh with the original AI mask.

### 4. Interactive Zoom & Navigation
* **Zoom/Pan Mode**: Switch to navigation mode to pinch-to-zoom (up to 6x) and drag to pan around.
* **Scale Locking**: Lock the viewport scale when returning to Brush or Eraser modes so you can paint detailed boundaries with high precision.
* **Floating Reset Zoom**: A context-sensitive button appears when zoomed in. Tap it to smoothly snap the viewport back to default scale (1.0).

### 5. Flat Preview Layout Engine
* **Plain Alignment Styling**: Renders the foreground cutout completely flat over the clock, preventing fake drop shadows from making scenic mountains or landscape wallpapers look detached.

### 6. Clock Typography & Customization
* **Typography**: Change font size, letter spacing, and choose from Google Fonts (with automatic online retrieval and system font fallbacks).
* **Visual Effects**: Set custom clock colors, adjust opacity, add outline/stroke styles, and toggle clock drop shadows.
* **Transformations**: 
  * Slide vertical and horizontal position offsets.
  * Stretch clock vertically.
  * Rotate text by degrees.
  * Apply horizontal, vertical, left, and bottom skews for realistic perspective.

### 7. Clock Date Widget
* Choose date format patterns (e.g. `EEE, MMM dd`).
* Force date text in ALL CAPS.
* Customize date font size, colors, bold weights, and shadows.

### 8. Native Android Live Wallpaper Service
* Written in native Kotlin (`DepthWallpaperService`) for high rendering efficiency.
* Directly draws three layers on the wallpaper canvas:
  1. Background Image
  2. Custom clock (inheriting fonts, colors, rotations, skews, and sizes from the project config)
  3. Refined foreground cutout PNG
* Time sync: Triggers time updates at exact minute boundaries to save battery.
* Real-time configuration sync via a broadcast receiver channel when changes are made inside the app.

---

## 🛠️ Architecture & Tech Stack

* **Frontend**: Flutter (Dart)
* **Native Integration**: Kotlin (Android WallpaperService & Broadcast Channels)
* **AI Engine**: Google ML Kit Subject Segmentation (On-Device)
* **Local Storage**: Hive DB (Key-Value Project configurations)
* **State Management**: Standard Flutter state lifecycles with optimized caching controllers

---

## 🧪 Testing Suite
The repository includes a comprehensive testing suite comprising **12 automated tests** verifying:
1. **Model Serialization**: Project and wallpaper configuration mappings.
2. **Settings Repository**: Shared preferences backup flags.
3. **Database CRUD**: Create, read, update, duplicate, and delete project configurations.
4. **UI Widgets**: Onboarding slides, Settings toggles, HomeScreen grid animations, and Brush data structures.

---

## 📲 How to Run & Build

### Prerequisites
* Flutter SDK (3.12.0 or higher recommended)
* Android SDK (Target API 34)

### Clone & Install
```bash
# Clone the repository
git clone https://github.com/dipesht16/Depth.git
cd Depth

# Fetch dependencies
flutter pub get
```

### Run Locally
```bash
# Run in debug mode on connected device
flutter run
```

### Build Release APK
```bash
# Generate release installer APK
flutter build apk --release
```
The generated file will be saved at: `build/app/outputs/flutter-apk/app-release.apk`.

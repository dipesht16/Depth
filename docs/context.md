# Project Context & Progress Log

> [!IMPORTANT]
> **MANDATORY INSTRUCTIONS FOR THE AI AGENT:** 
> 1. You MUST update this file after completing every module or significant implementation step. This file serves as the single source of truth for the project's current state, codebase changes, active configurations, and next steps. Do not skip this update under any circumstances.
> 2. **CRITICAL GIT RULE**: DO NOT run git commit or git push commands or stage files automatically for GitHub until the user has explicitly tested the changes locally and given approval to push.
> 3. **COMMIT MESSAGE RULE**: Do not use the word "Module" with its number in git commit messages (e.g. avoid "Module 1" or "Module 2"). Instead, start the commit message with "Implemented: " followed by a descriptive list of the specific features added (e.g. "Implemented: Image Selection, storage copying, permissions handling, and preview rendering").

## Project Overview
- **Project Name**: DepthWall (`wallpaper`)
- **Objective**: Custom Android Depth Wallpaper App using Flutter for customization UI and Native Kotlin for background rendering with ML Kit Subject Segmentation.
- **Target Platform**: Android-only (API 26+ / Android 8.0+)

---

## Current Status
- **Phase**: Native Wallpaper Service Integration
- **Active Module**: None (Module 8 Completed, ready for Module 9)

---

## Documentation Registry
- **Product Requirements**: [docs/PRD.md](file:///d:/Flutter/Wallpaper/docs/PRD.md)
- **Detailed Module Specifications**: [docs/module.md](file:///d:/Flutter/Wallpaper/docs/module.md)
- **UI & UX Design Guidelines**: [docs/ui_principles.md](file:///d:/Flutter/Wallpaper/docs/ui_principles.md)
- **Project Context Log**: [docs/context.md](file:///d:/Flutter/Wallpaper/docs/context.md)

---

## Implementation Progress

- [x] **Setup & Init**
  - [x] Basic Flutter Android project initialized.
  - [x] Reference documentation created.
- [x] **Module 1**: Project Setup & Navigation Shell
  - [x] Package renamed to `com.yourcompany.depthwallpaper`, minSdk = 26, portrait-only lock.
  - [x] Implemented dark theme in `app_theme.dart`.
  - [x] Scaffolds for `HomeScreen`, `StudioScreen` (with 5 tabs), and full-screen `PreviewScreen` completed.
  - [x] Reusable `CustomAppBar` and premium `SlidePageRoute` transitions added.
- [x] **Module 2**: Image Selection & Storage
  - [x] Added `image_picker`, `path_provider`, `path`, and `permission_handler` dependencies.
  - [x] Declared storage permissions in `AndroidManifest.xml`.
  - [x] Created `WallpaperData` data model.
  - [x] Implemented `FileManager` service for copying original images with unique timestamps inside app documents.
  - [x] Integrated permissions flow and gallery picker on Studio Screen.
  - [x] Added circular loading overlay, BoxFit.cover preview container, reset dialog, and full-screen image preview.
- [x] **Module 3**: ML Kit Subject Segmentation
  - [x] Added `google_mlkit_subject_segmentation` dependency.
  - [x] Added Play Services dependencies auto-download meta-data in `AndroidManifest.xml`.
  - [x] Implemented `SegmentationService` to extract foregroundBitmap bytes.
  - [x] Integrated transparent PNG saving in `FileManager`.
  - [x] Updated Studio Screen to run ML segmentation asynchronously on image selection.
  - [x] Designed double-layer stack rendering (background + transparent cutout subject overlay) in simulated phone preview and full resolution Preview Screen.
- [x] **Module 4**: Static Preview Renderer
  - [x] Created `WallpaperConfig` model for customizing styling settings (font size, position, alignment, font family).
  - [x] Developed reusable `WallpaperPreview` widget maintaining `9/19.5` aspect ratio.
  - [x] Structured three-layer composition logic (Background Image -> Positioned Clock -> Foreground transparent subject cutout PNG).
  - [x] Integrated `WallpaperPreview` inside Studio Workspace screen and borderless inside `PreviewScreen`.
- [x] **Module 5**: Basic Studio Editor (Position & Size)
  - [x] Replaced generic Basics Tab content with custom sliders (Font Size, Horizontal Position, Vertical Position).
  - [x] Designed responsive Yellow active thumb/track slider styling in dark theme.
  - [x] Connected sliders to update `WallpaperConfig` in real-time.
  - [x] Implemented auto-disabling of editor controls when no image is selected.
  - [x] Extended confirmation reset function to restore defaults for `WallpaperConfig`.
- [x] **Module 6**: Typography Customization
  - [x] Integrated `google_fonts` package dependency.
  - [x] Upgraded clock rendering to load custom typefaces dynamically.
  - [x] Built horizontal scrolling font family picker showing styled previews.
  - [x] Built horizontal color swatches selector with checkmark indicators.
  - [x] Programmed selection clicks and individual resets.
- [x] **Module 7**: Effects & Transform
  - [x] Implemented clock text opacity, text shadow toggle, thin edge stroke, and thick text stroke stacking.
  - [x] Implemented full Matrix4 transforms supporting rotation, stretch scaling, and 4-way skews (horizontal, vertical, bottom, left).
  - [x] Developed Effects and Transform tab panels with individual reset controls and haptic feedback.
  - [x] Removed atmospheric depth background blur per user request.

- [x] **Module 8**: Kotlin WallpaperService (Static)
  - [x] Registered live wallpaper permissions and BIND_WALLPAPER service in AndroidManifest.xml.
  - [x] Configured XML metadata descriptor and generated picker thumbnail.
  - [x] Setup com.yourcompany.depthwallpaper/wallpaper MethodChannel bridge in MainActivity.kt.
  - [x] Programmed SharedPreferences saving and ACTION_CHANGE_LIVE_WALLPAPER intents.
  - [x] Built WallpaperConfig parser and OOM-safe downsampling BitmapLoader.
  - [x] Developed native Kotlin DepthWallpaperService canvas rendering pipeline.
  - [x] Added Apply checkmark action in Flutter StudioScreen.

---

## Technical Baseline
- **Flutter Project Directory**: `d:\Flutter\Wallpaper`
- **Git Repository**: https://github.com/dipesht16/Depth.git
- **Android Platform Constraints**:
  - Min SDK Version: API 26 (Android 8.0)
  - Orientation: Portrait Only
  - Build Tweaks: Disabled Kotlin incremental compilation (`kotlin.incremental=false` in [gradle.properties](file:///d:/Flutter/Wallpaper/android/gradle.properties)) to prevent cross-drive relative path build issues.

---

## Module Walkthroughs & Historical Details

### Module 1 Walkthrough: Project Setup & Navigation Shell
- **Changes Implemented**:
  - **Android Host Project Configuration**: Renamed package identifier to `com.yourcompany.depthwallpaper` in [build.gradle.kts](file:///d:/Flutter/Wallpaper/android/app/build.gradle.kts), [AndroidManifest.xml](file:///d:/Flutter/Wallpaper/android/app/src/main/AndroidManifest.xml), and Kotlin packages. Created new [MainActivity.kt](file:///d:/Flutter/Wallpaper/android/app/src/main/kotlin/com/yourcompany/depthwallpaper/MainActivity.kt) and cleaned up old ones. Set `minSdk` to `26` and orientation to `portrait`. Changed app label to `Depth Wallpaper`.
  - **Flutter UI Theme**: Implemented dark theme in [app_theme.dart](file:///d:/Flutter/Wallpaper/lib/theme/app_theme.dart) using `#000000` (canvas background), `#121212` (dark surfaces), `#FFD700` (yellow highlights/indicator), `#FFFFFF` (primary text), and `#B0B0B0` (secondary text).
  - **HomeScreen**: Implemented in [home_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/home_screen.dart) with a glowing empty-state illustration and a FAB to navigate to the Studio screen.
  - **StudioScreen**: Implemented in [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart) with a simulated phone preview (400dp height) and a scrollable `TabBar` for 5 tabs (*Basics, Typography, Effects, Transform, Date*).
  - **PreviewScreen**: Implemented in [preview_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/preview_screen.dart) for full-screen wallpaper testing.
  - **Transitions**: Set up custom page slide transition route helper [slide_page_route.dart](file:///d:/Flutter/Wallpaper/lib/widgets/slide_page_route.dart).
- **Verification Results**:
  - Static Analysis (`flutter analyze`): **No issues found**.
  - Widget Testing (`flutter test`): **All tests passed** (verified Home Screen initialization, AppBar title, empty state text, and FAB rendering).

### Module 2 Walkthrough: Image Selection & Storage
- **Changes Implemented**:
  - **Dependencies Added**: Integrated `image_picker` (gallery photo selection), `path_provider` (local app storage directory), `path` (file extension extraction), and `permission_handler` (storage permissions API).
  - **AndroidManifest Configuration**: Declared `READ_MEDIA_IMAGES` (Android 13+), `READ_EXTERNAL_STORAGE` (maxSdkVersion 32), and `WRITE_EXTERNAL_STORAGE` (maxSdkVersion 29) to request storage access cleanly on all versions.
  - **WallpaperData Data Model**: Built [wallpaper_data.dart](file:///d:/Flutter/Wallpaper/lib/models/wallpaper_data.dart) to encapsulate original, background, and foreground image paths, with `copyWith` and `clear` capabilities.
  - **FileManager Storage Helper**: Built [file_manager.dart](file:///d:/Flutter/Wallpaper/lib/services/file_manager.dart) to automatically create `wallpapers/` subdirectory inside application documents, copy files using `original_[timestamp].[ext]` unique naming convention, delete old background files, and fetch size information.
  - **Studio Workspace Integration**:
    - Built a robust permission request wrapper in [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart) handling normal and permanently denied statuses (shows Settings alert dialog).
    - Wired image picker gallery trigger to top action button with SnackBars reporting states.
    - Added loading overlay with circular indicator during storage copy operations.
    - Updated simulated phone container to show loaded image inside `Image.file` using `BoxFit.cover` or show instructions placeholder.
    - Added reset confirmation dialog that deletes files from disk.
    - Passed file path to [preview_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/preview_screen.dart) to support full resolution wallpaper checking.
- **Verification Results**:
  - Static Analysis (`flutter analyze`): **No issues found** (resolved package import warning by adding `path` to pubspec).
  - Widget Testing (`flutter test`): **All tests passed**.

### Module 3 Walkthrough: ML Kit Subject Segmentation
- **Changes Implemented**:
  - **Dependencies Integrated**: Added `google_mlkit_subject_segmentation: ^0.0.3` to `pubspec.yaml` (using the correct stable version published on pub.dev).
  - **Model Download Configuration**: Injected `com.google.mlkit.vision.DEPENDENCIES` metadata into [AndroidManifest.xml](file:///d:/Flutter/Wallpaper/android/app/src/main/AndroidManifest.xml) to trigger automated Play Services ML model download.
  - **Segmentation Service Creation**: Built [segmentation_service.dart](file:///d:/Flutter/Wallpaper/lib/services/segmentation_service.dart) which creates a `SubjectSegmenter` configured for extracting the combined foreground bitmap, processes input images, retrieves the `foregroundBitmap` byte array directly, saves it, and cleans resources.
  - **FileManager PNG Capabilities**: Added `saveForegroundImage` to [file_manager.dart](file:///d:/Flutter/Wallpaper/lib/services/file_manager.dart) to write the isolated mask PNG bytes to disk.
  - **UI Integration**:
    - Enabled dynamic loading status indicators (*"Loading image..."* then *"Detecting subject..."*) to show active pipeline status.
    - Stacked background image and foreground transparent PNG exactly over each other inside simulated phone frame in [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart) using `BoxFit.cover`.
    - Passed both layers to [preview_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/preview_screen.dart) to show full screen composite preview.
    - Handled fallback gracefully: if no subject is found, show an informative AlertDialog and retain the original image as standard background (no depth overlay).
    - Reset settings now deletes both physical files from storage.
- **Verification Results**:
  - Static Analysis (`flutter analyze`): **No issues found** (resolved type and import issues in file manager).
  - Widget Testing (`flutter test`): **All tests passed**.

### Module 4 Walkthrough: Static Preview Renderer
- **Changes Implemented**:
  - **WallpaperConfig Model**: Designed [wallpaper_config.dart](file:///d:/Flutter/Wallpaper/lib/models/wallpaper_config.dart) to encapsulate all customization parameters (font size, horizontal/vertical positions, color, format, and future-proof skew/effects settings).
  - **WallpaperPreview Widget**: Implemented [wallpaper_preview.dart](file:///d:/Flutter/Wallpaper/lib/widgets/wallpaper_preview.dart) as a reusable widget which locks the aspect ratio to `9/19.5`, draws smartphone borders (if `showFrame` is enabled), and coordinates the layering stack (Background -> Positioned Clock -> Foreground transparent PNG subject).
  - **OOM Image Crash Solution**: Solved OOM crashes on two levels:
    1. Added dynamic screen-size constraints (retrieving the user's physical screen dimensions via `MediaQuery` inside [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart)) to `ImagePicker.pickImage` to natively downscale photos to fit the device's physical screen exactly, protecting both JVM and NDK/ML Kit heap on any device automatically.
    2. Configured dynamic `cacheWidth` decoding constraints in `Image.file` inside `WallpaperPreview` (scaled to `2 * constraints.maxWidth` to fit the viewport exactly) to prevent uncompressed decoding memory spikes in the widget layer.
  - **Clock Position & Visibility Solution**: Resolved clipping/disappearance by centering the clock horizontally by default spanning `left: 0, right: 0` with centered alignment, and applying a sliding offset translation via `Transform.translate` mapped to `config.horizontalPos`.
  - **Foreground 3D Uplift Drop Shadow**: Added a dynamic Gaussian-blurred dark shadow layer (`ui.ImageFilter.blur`) shifted down/right directly underneath the foreground subject, making the cutout pop out in 3D relief against the background and clock.
  - **Studio Screen Integration**: Replaced the previous ad-hoc Stack in [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart) with `WallpaperPreview`, wrapping it with full-screen navigation trigger, "Tap to Preview" overlay, and centered progress overlays.
  - **Preview Screen Integration**: Updated [preview_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/preview_screen.dart) to render `WallpaperPreview` borderless (`showFrame: false`), ensuring edge-to-edge full screen depth composition testing.
- **Verification Results**:
  - Static Analysis (`flutter analyze`): **No issues found** (cleaned up unused import `dart:io` in studio screen).
  - Widget Testing (`flutter test`): **All tests passed**.

### Module 5 Walkthrough: Basic Studio Editor (Position & Size)
- **Changes Implemented**:
  - **Basics Tab Slider Panel**: Built dynamic slider controls in the "Basics" tab of [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart) for adjusting Font Size (range `0.1` to `0.5`), Horizontal Position (range `0.0` to `1.0`), and Vertical Position (range `0.0` to `1.0`).
  - **Premium Donut Dragger UI**: Designed a custom `CustomSliderThumbShape` which renders as a yellow glowing outer circle with a hollow dark center (donut style) on a thick modern track (`trackHeight: 6`).
  - **Expanding Halo Activation Animations**: Programmed the custom thumb painter to dynamically scale the thumb radius by up to 30% and project a glowing translucent yellow halo (`withValues(alpha: ...)`) around itself when pressed/dragged using `activationAnimation.value`.
  - **Integer-Percent Tick Haptics**: Integrated tactile feedback using `HapticFeedback.selectionClick()` on every 1% slider increment, creating a high-end dial-crown mechanical feedback sensation as the user slides the control.
  - **Tactile Reset Buttons**: Injected restore icons (`Icons.restore_rounded`) next to percentage readouts above each slider, triggering `HapticFeedback.mediumImpact()` (strong physical click) and resetting *only* that specific configuration parameter.
  - **Disable-State Integration**: Programmed controls to automatically render greyed-out and disabled (with `onChanged` set to null) until an image is loaded, showing an advisory label: *"Please select an image to unlock controls"*.
  - **Workspace Reset Extension**: Updated the workspace reset routine in [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart) to restore defaults for `_wallpaperConfig` alongside deleting physical files.
- **Verification Results**:
  - Static Analysis (`flutter analyze`): **No issues found**.
  - Widget Testing (`flutter test`): **All tests passed**.

### Module 6 Walkthrough: Typography Customization
- **Changes Implemented**:
  - **Dependencies Added**: Added `google_fonts: ^6.2.0` in [pubspec.yaml](file:///d:/Flutter/Wallpaper/pubspec.yaml).
  - **Dynamic Fonts Preview Engine**: Modified [wallpaper_preview.dart](file:///d:/Flutter/Wallpaper/lib/widgets/wallpaper_preview.dart) to load typefaces (`Outfit`, `Inter`, `Lilita One`, `Rubik`) via `GoogleFonts.getFont`, falling back to standard `Roboto` layout rendering cleanly.
  - **Typography UI Controls**: Replaced the placeholder tab with `_buildTypographyTab()` in [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart). Developed horizontal lists for selecting 5 fonts (rendered using the typeface itself) and 8 color swatches (32dp diameter) with checkmark indicators and selection haptics.
  - **Reset Actions**: Added restore icons next to headers to allow users to reset parameters individually.
- **Verification Results**:
  - Static Analysis (`flutter analyze`): **No issues found** (resolved deprecation of `.value` color check with `toARGB32()`).
  - Widget Testing (`flutter test`): **All tests passed**.

### Module 7 Walkthrough: Effects & Transform
- **Changes Implemented**:
  - **Matrix Transform Engine**: Updated [wallpaper_preview.dart](file:///d:/Flutter/Wallpaper/lib/widgets/wallpaper_preview.dart) to apply rotation, stretch, horizontal/vertical skews, bottom skew H, and left skew using a combined `Matrix4` applied to the clock layers.
  - **Outline & Stroke Stacking**: Stacked text elements to support thin outlines (Edge Stroke) and thicker outlines (Text Stroke) behind the main filled clock face.
  - **Effects & Transform UI Panels**: Added text opacity slider, toggles for Edge Stroke, Shadow, and Text Stroke in the Effects tab, and sliders for 6 transform properties in the Transform tab.
  - **Aesthetics & Haptics**: Implemented yellow accent colors, custom donut shapes, restore icons, and haptic clicks for all inputs.
  - **Correction**: Removed Atmospheric Depth background blur from UI/preview per user request, and resolved deprecation of `scale` in Matrix4 and `activeColor` in SwitchListTile.
- **Verification Results**:
  - Static Analysis (`flutter analyze`): **No issues found**.
  - Widget Testing (`flutter test`): **All tests passed**.

### Module 8 Walkthrough: Kotlin WallpaperService (Static)
- **Changes Implemented**:
  - **Manifest & Resources**: Added `SET_WALLPAPER` permissions, declared `.DepthWallpaperService` BIND_WALLPAPER in [AndroidManifest.xml](file:///d:/Flutter/Wallpaper/android/app/src/main/AndroidManifest.xml), created [wallpaper.xml](file:///d:/Flutter/Wallpaper/android/app/src/main/res/xml/wallpaper.xml) description, and copied generated `wallpaper_thumbnail.png` into `drawable`.
  - **MainActivity Native Bridge**: Programmed `MethodChannel` handler in [MainActivity.kt](file:///d:/Flutter/Wallpaper/android/app/src/main/kotlin/com/yourcompany/depthwallpaper/MainActivity.kt) supporting robust `Number` parsing of Dart config maps into shared preferences and launching the wallpaper picker chooser.
  - **OOM-Safe Bitmap Loading**: Built [BitmapLoader.kt](file:///d:/Flutter/Wallpaper/android/app/src/main/kotlin/com/yourcompany/depthwallpaper/BitmapLoader.kt) utilizing `inSampleSize` calculations to load optimized downsampled bitmaps.
  - **Native Rendering Service**: Built [DepthWallpaperService.kt](file:///d:/Flutter/Wallpaper/android/app/src/main/kotlin/com/yourcompany/depthwallpaper/DepthWallpaperService.kt) to manage canvas drawing (Background -> Vector Clock with rotation/stretch/skews/shadows -> Foreground overlay) and SharedPreferences change listening.
  - **Apply Button**: Added checkmark action button and channel calls in [studio_screen.dart](file:///d:/Flutter/Wallpaper/lib/screens/studio_screen.dart).
- **Verification Results**:
  - Static Analysis (`flutter analyze`): **No issues found** (resolved color value deprecation).
  - Widget Testing (`flutter test`): **All tests passed**.




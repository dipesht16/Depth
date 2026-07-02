# Project Context & Progress Log

> [!IMPORTANT]
> **MANDATORY INSTRUCTIONS FOR THE AI AGENT:** 
> 1. You MUST update this file after completing every module or significant implementation step. This file serves as the single source of truth for the project's current state, codebase changes, active configurations, and next steps. Do not skip this update under any circumstances.
> 2. **CRITICAL GIT RULE**: DO NOT run git commit or git push commands or stage files automatically for GitHub until the user has explicitly tested the changes locally and given approval to push.

## Project Overview
- **Project Name**: DepthWall (`wallpaper`)
- **Objective**: Custom Android Depth Wallpaper App using Flutter for customization UI and Native Kotlin for background rendering with ML Kit Subject Segmentation.
- **Target Platform**: Android-only (API 26+ / Android 8.0+)

---

## Current Status
- **Phase**: Image Selection & Storage
- **Active Module**: None (Module 2 Completed, ready for Module 3)

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
- [ ] **Module 3**: ML Kit Subject Segmentation
- [ ] **Module 4**: Static Preview Renderer
- [ ] **Module 5**: Basic Studio Editor (Position & Size)
- [ ] **Module 6**: Typography Customization
- [ ] **Module 7**: Effects & Transform

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


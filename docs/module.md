📘 Detailed Module Specifications for AI Agent Implementation
🟢 MODULE 1: Project Setup & Navigation Shell
Objective:
Create the foundational app structure with navigation between empty screens, establishing the dark theme UI framework without any functional features.

Detailed Requirements:
1.1 Project Initialization
Create new Flutter project named "depth_wallpaper_app"
Set minimum SDK version to Android 8.0 (API 26)
Configure app to support only portrait orientation
Set app name and package identifier (com.yourcompany.depthwallpaper)
1.2 Theme Configuration
Implement dark theme as primary theme
Color scheme specifications:
Primary background: Pure black (#000000)
Secondary background: Dark gray (#121212)
Accent color: Yellow/Gold (#FFD700)
Text primary: White (#FFFFFF)
Text secondary: Light gray (#B0B0B0)
Inactive elements: Dark gray (#424242)
Apply theme globally to MaterialApp
1.3 Screen Structure
Create three main screens with basic scaffolding:

Home Screen:

AppBar with title "Depth Wallpaper"
Empty body with centered placeholder text: "Projects will appear here"
Floating Action Button (FAB) in bottom-right corner with '+' icon
FAB navigates to Studio Screen when tapped
Background color: primary black
Studio Screen:

AppBar with back button (auto-generated) and title "Studio"
Two action icons in AppBar: gallery icon (image), refresh icon
Body divided into three vertical sections:
Preview area (400dp height, phone-shaped container with rounded corners)
Tab bar (5 tabs: Basics, Typography, Effects, Transform, Date)
Tab content area (fills remaining space)
Preview area has subtle border (2dp, dark gray) and rounded corners (24dp radius)
Tab bar uses yellow indicator for active tab
Each tab shows centered placeholder text with tab name
Preview Screen:

Full-screen container
Black background
Centered placeholder text: "Full preview will appear here"
Close button (X icon) in top-right corner
Will be accessed later from Studio screen
1.4 Navigation Flow
Implement navigation stack:
Home → Studio (push)
Studio → Preview (push)
Back button/gesture returns to previous screen
Use MaterialPageRoute for transitions
Apply slide animation for screen transitions
1.5 Code Organization
Create folder structure:

text

lib/
├── main.dart (MaterialApp entry point)
├── screens/
│   ├── home_screen.dart
│   ├── studio_screen.dart
│   └── preview_screen.dart
├── widgets/
│   └── custom_app_bar.dart (reusable AppBar component)
└── theme/
    └── app_theme.dart (ThemeData configuration)
1.6 Tab Controller Setup
Studio screen uses TabController with SingleTickerProviderStateMixin
TabController manages 5 tabs
Each tab view currently displays static placeholder
Tab switching should be smooth without animation lag
Expected Outcomes:
App launches successfully on Android device/emulator
All three screens navigable
No functional features yet (buttons don't do anything except navigate)
Dark theme consistently applied
No runtime errors or warnings
Tab switching works smoothly
Back navigation works correctly
Testing Criteria:
Launch app → see Home screen
Tap FAB → navigate to Studio screen
Tap back button → return to Home screen
Switch between all 5 tabs → no crashes
Visual inspection: all colors match theme
UI elements properly aligned and sized
🟢 MODULE 2: Image Selection & Storage
Objective:
Implement complete image handling pipeline: user selects photo from gallery, app saves it to internal storage, displays in preview area, and manages file paths.

Detailed Requirements:
2.1 Permission Management
Add storage permission declarations to AndroidManifest.xml
Implement runtime permission request flow:
Android 13+ (API 33+): READ_MEDIA_IMAGES
Android 10-12 (API 29-32): READ_EXTERNAL_STORAGE
Android 9 and below: READ_EXTERNAL_STORAGE + WRITE_EXTERNAL_STORAGE
Show permission dialog with clear explanation when user first attempts to pick image
Handle permission denial gracefully with error message
Use permission_handler package for cross-platform permission checking
2.2 Image Picker Integration
Integrate image_picker package
Add gallery icon button to Studio screen AppBar (already placed in Module 1, now make functional)
On gallery icon tap:
Check storage permission status
Request permission if not granted
Open device gallery picker
Allow user to select single image (not multiple)
Support formats: JPEG, PNG, HEIC
No camera capture in this module (gallery only)
2.3 File Storage System
Use path_provider package to get app's private directory

Create file management service with these methods:

getAppDirectory(): Returns app's documents directory path
saveImage(XFile): Copies selected image to app directory and returns new path
deleteImage(String path): Removes image file from storage
getFileSize(String path): Returns file size in bytes
File naming convention:

Original images: original_[timestamp].jpg
Example: original_1703456789123.jpg
Directory structure to create:

text

/data/data/com.yourcompany.depthwallpaper/files/
└── wallpapers/
    ├── original_[timestamp].jpg
    └── (future files will go here)
2.4 Data Model Creation
Create WallpaperData class to hold file paths:

text

Properties:
- originalImagePath: String? (path to user-selected image)
- backgroundImagePath: String? (will be used in Module 3)
- foregroundImagePath: String? (will be used in Module 3)

Methods:
- Constructor with optional named parameters
- No serialization needed yet (Module 11)
2.5 Image Display in Preview
When image selected and saved:
Update WallpaperData instance with originalImagePath
Trigger UI rebuild (setState)
Display image in preview area of Studio screen
Preview area behavior:
If no image: Show placeholder icon (photo icon) + text "Tap gallery icon to select image"
If image loaded: Display image with BoxFit.cover (fills container, maintains aspect ratio)
Use File widget to load from local path (not network/assets)
2.6 Image Optimization
No compression in this module (raw image loading)
Handle large images gracefully:
Show loading indicator while image loads
Catch and display error if file too large or corrupted
Maximum supported resolution: No limit yet (will optimize in Module 8)
2.7 State Management
Studio screen maintains WallpaperData instance as state variable
When image selected:
Update originalImagePath
Call setState() to rebuild UI
Preview area reflects new image immediately
State persists while on Studio screen
State resets when leaving Studio screen (temporary - persistence in Module 11)
2.8 Error Handling
Handle these scenarios with user-friendly messages:

Permission denied: "Storage permission needed to select photos"
No image selected (user cancels): Silent (no action)
File read error: "Could not load selected image"
Storage full: "Not enough storage space"
Corrupted image: "Selected image is invalid"
2.9 Loading States
Implement loading indicators:

Show circular progress indicator while:
Copying image to app directory
Loading image for display
Overlay loading indicator on preview area (semi-transparent background)
Loading text: "Loading image..."
Expected Outcomes:
Gallery icon button functional in Studio screen
Tapping opens device photo gallery
Selected image appears in preview area
Image file copied to app's internal storage
File path stored in WallpaperData object
Can select different images (replaces previous)
No crashes with large images (10MB+)
Permissions requested and handled properly
Testing Criteria:
Select image from gallery → appears in preview
Select second image → replaces first image in preview
Deny permission → see error message
Grant permission after denial → can select image
Navigate away and back → image lost (expected, no persistence yet)
Select very large image (20MB) → loads without crash
Select HEIC format (iPhone photos) → converts and displays
Cancel gallery picker → no error, preview stays as was
Key Files to Create:
services/file_manager.dart - File operations service
models/wallpaper_data.dart - Data model
Updated screens/studio_screen.dart - Integrate image picker
Dependencies to Add:
YAML

image_picker: ^1.0.4
path_provider: ^2.1.1
permission_handler: ^11.0.1
🟡 MODULE 3: ML Kit Subject Segmentation
Objective:
Integrate Google ML Kit to automatically detect and extract the foreground subject from the selected image, creating a transparent PNG mask that will later appear above the clock widget.

Detailed Requirements:
3.1 ML Kit Package Integration
Add google_mlkit_subject_segmentation package to pubspec.yaml
Configure Android project for ML Kit:
Update minSdkVersion to 21 if lower
Add ML Kit dependencies to build.gradle
Configure ProGuard rules (if using obfuscation)
No iOS configuration needed (Android-only app)
3.2 Segmentation Service Architecture
Create dedicated service class with these responsibilities:

Accept image file path as input
Process image through ML Kit API
Return path to saved foreground mask PNG
Handle processing errors
Report processing progress
Service Interface:

text

Method: segmentSubject(String imagePath)
Returns: Future<String?> (path to foreground PNG, null if failed)
Processing steps:
1. Load image from path
2. Create ML Kit InputImage
3. Configure segmentation options
4. Run segmentation
5. Extract foreground bitmap
6. Convert to PNG with transparency
7. Save to app directory
8. Return file path
3.3 ML Kit Configuration
Configure SubjectSegmenter with these options:

Enable foreground bitmap: true (need the cutout subject)
Enable foreground confidence mask: false (not needed for this module)
Enable multiple subjects: true (detect all subjects, will use primary one)
Subject result options:
Enable confidence mask: false
Enable subject bitmap: true
3.4 Image Processing Pipeline
Step 1: Input Image Preparation

Convert file path to ML Kit InputImage object
InputImage should maintain original resolution
No preprocessing (rotation, scaling) in this module
Step 2: Segmentation Execution

Create SubjectSegmenter instance with configured options
Process image asynchronously (doesn't block UI)
ML Kit returns SubjectSegmentationResult object
Extract foregroundBitmap from result
Close segmenter to free resources
Step 3: Bitmap Processing

ML Kit returns foreground as ui.Image (Flutter's image type)
Foreground has transparent background (alpha channel)
Background pixels = fully transparent (alpha = 0)
Subject pixels = opaque (alpha = 255)
Edge pixels = partially transparent (anti-aliasing)
Step 4: PNG Conversion & Saving

Convert ui.Image to byte array (PNG format)
Use image.toByteData() with PNG format
Save bytes to file with naming: foreground_[timestamp].png
Return file path
3.5 Processing States & UI Feedback
Loading Overlay:
When segmentation starts, show full-screen overlay on Studio screen:

Semi-transparent black background (87% opacity)
Centered circular progress indicator (yellow color)
Text below indicator: "Detecting subject..."
Overlay blocks all user interaction
Cannot cancel processing (deterministic process)
Progress Tracking:

ML Kit doesn't provide progress updates
Show indeterminate circular progress indicator
Processing typically takes 2-10 seconds depending on image size
Success State:

Remove loading overlay
Update WallpaperData with foregroundImagePath
Preview area now shows two layers:
Background image (original)
Foreground subject (transparent PNG)
Visual confirmation: user sees subject isolated
Error State:

Remove loading overlay
Show error dialog with message:
"Could not detect subject in image"
"Please try a different photo with clear subject"
Keep original image in preview (don't clear)
User can retry with different image
3.6 File Management Updates
Extend FileManager service from Module 2:

Add method: saveForegroundImage(Uint8List bytes)
Saves PNG with transparency
Returns file path
File naming: foreground_[timestamp].png
3.7 Data Flow Integration
Current Flow (Module 2):

text

User selects image → Save to storage → Update originalImagePath → Display in preview
Updated Flow (Module 3):

text

User selects image 
  → Save as original 
  → Show loading overlay
  → Run ML Kit segmentation
  → Save foreground mask
  → Update originalImagePath AND foregroundImagePath
  → Hide loading overlay
  → Display layered preview (background + foreground)
3.8 Preview Area Enhancement
Update preview rendering to show layered composition:

Preview Stack (bottom to top):

Background Layer: originalImagePath displayed with BoxFit.cover
Foreground Layer: foregroundImagePath displayed with BoxFit.cover (PNG with transparency)
Both images should:

Fill preview container completely
Maintain aspect ratio
Use same bounds (overlaid perfectly)
Visual Result:
User sees subject cut out from background, creating depth effect preview. No clock yet (Module 4).

3.9 Edge Cases & Error Handling
Scenario 1: No Subject Detected

ML Kit returns null or empty foreground bitmap
Show error: "No clear subject found. Try image with person, pet, or object"
Provide option to use manual selection (future module)
Scenario 2: Multiple Subjects

ML Kit detects multiple subjects (e.g., 2 people)
Use primary subject (ML Kit chooses most prominent)
In future: let user choose which subject (Module 11+)
Scenario 3: Low Quality Segmentation

Subject edges are jagged or incorrect
Still save result (user can retry)
In future: add edge refinement tools (Module 11+)
Scenario 4: Processing Timeout

If segmentation takes > 30 seconds, show timeout error
Rare but possible with very large images (50MB+)
Scenario 5: Out of Memory

Very large images (20MB+) may cause OOM
Catch error, show message: "Image too large, please select smaller image"
In future: auto-compress large images (Module 8)
3.10 Performance Considerations
Run segmentation in isolate (background thread) to prevent UI freeze
ML Kit internally uses native code (already optimized)
Don't process same image twice (check if foreground already exists)
Cache results temporarily (Module 11 will add permanent cache)
3.11 Testing Scenarios
Test Case 1: Person Photo

Select photo with single person
Should detect person as subject
Background should be transparent
Result: person appears "cut out"
Test Case 2: Pet Photo

Select photo of dog/cat
Should detect animal as subject
Works with furry subjects (challenging edges)
Test Case 3: Object Photo

Select photo of product/item on background
Should detect object
Works best with clear contrast
Test Case 4: Complex Background

Select photo with busy background
Segmentation may include some background
Still usable result (good enough for MVP)
Test Case 5: No Clear Subject

Select landscape/scenery photo
ML Kit may fail or segment incorrectly
Handle gracefully with error message
Expected Outcomes:
After selecting image, automatic segmentation runs
Loading indicator shows during processing
Foreground subject extracted as transparent PNG
Preview shows original + foreground overlay
No crashes with various image types
Processing completes within 10 seconds for typical photos
Error messages clear and actionable
Testing Criteria:
Select portrait photo → person detected and isolated
Select pet photo → animal detected
Select landscape → error or partial detection (acceptable)
Process large image (10MB) → completes without crash
Process small image (500KB) → fast processing
Test with different lighting conditions → acceptable results
Verify PNG has transparency (check with image viewer)
Verify file saved to correct directory
Verify naming convention followed
Key Files to Create:
services/segmentation_service.dart - ML Kit integration
Updated services/file_manager.dart - Add PNG saving method
Updated models/wallpaper_data.dart - Add foregroundImagePath field
Updated screens/studio_screen.dart - Integrate segmentation flow
Dependencies to Add:
YAML

google_mlkit_subject_segmentation: ^0.2.0
Critical Notes for AI Agent:
ML Kit requires Google Play Services on device
Test on real Android device (emulator may have limitations)
Processing time varies by device CPU power
Subject detection accuracy ~80-95% depending on image quality
Transparent PNG crucial for depth effect (alpha channel must be preserved)
🟡 MODULE 4: Static Preview Renderer
Objective:
Create layered preview system that renders clock widget between background image and foreground subject, displaying static time to demonstrate depth effect before live wallpaper implementation.

Detailed Requirements:
4.1 Preview Component Architecture
Create dedicated WallpaperPreview widget that:

Acts as reusable component (will be used in Studio and Preview screens)
Accepts two inputs: WallpaperData (image paths) and WallpaperConfig (styling)
Renders three-layer composition in correct order
Updates automatically when config changes
Maintains phone aspect ratio (9:19.5 for modern Android phones)
4.2 Configuration Model Creation
Create WallpaperConfig class to store all customization settings:

Basic Properties (Module 4):

fontSize: double (range 0.1 to 0.5, represents percentage of screen width)
horizontalPos: double (range 0.0 to 1.0, 0=left edge, 1=right edge)
verticalPos: double (range 0.0 to 1.0, 0=top edge, 1=bottom edge)
clockFormat: String (e.g., "HH:MM", will support multiple formats later)
fontColor: Color (clock text color)
fontFamily: String (default "Roboto")
Additional Properties (placeholders for future modules):

letterSpacing: double (default 0.0)
textOpacity: double (default 1.0)
shadowEnabled: bool (default true)
rotation: double (default 0.0 degrees)
stretch: double (default 1.0)
And others... (will be populated in Modules 6-7)
Default Values:

Initialize with sensible defaults in constructor
fontSize: 0.24 (24% of width = large readable clock)
horizontalPos: 0.48 (centered horizontally)
verticalPos: 0.24 (upper third of screen)
fontColor: white
clockFormat: "HH:MM"
4.3 Layer Rendering System
Preview Container Setup:

Use AspectRatio widget with ratio 9/19.5 (modern phone)
Container has rounded corners (24dp radius) matching phone shape
Border: 2dp dark gray (#424242) to simulate phone bezel
ClipRRect to clip content to rounded corners
Uses LayoutBuilder to get actual render dimensions
Layer Order (bottom to top):

Layer 1 - Background Image:

Source: wallpaperData.backgroundImagePath
Widget: Image.file()
Fit: BoxFit.cover (fills entire container, crops if needed)
Full width and height of container
This layer always rendered if image available
Layer 2 - Clock Widget:

Positioned widget using config.horizontalPos and config.verticalPos
Position calculations:
text

x = config.horizontalPos × containerWidth
y = config.verticalPos × containerHeight
Text widget displaying static time "12:30"
Text styling:
Font size: config.fontSize × containerWidth (scales with container)
Color: config.fontColor
Font family: config.fontFamily
Font weight: bold
Shadow: black shadow with 4dp blur radius (for readability)
Anti-aliasing enabled
Layer 3 - Foreground Subject:

Source: wallpaperData.foregroundImagePath
Widget: Image.file()
Fit: BoxFit.cover (same as background)
Full width and height (overlays entire container)
PNG transparency preserved (critical - shows clock through transparent areas)
Only rendered if foreground path available
4.4 Stack Composition
Use Stack widget to overlay layers:

text

Stack(
  children: [
    Background Image (full size),
    Positioned Clock (at calculated x, y),
    Foreground Image (full size, transparent PNG)
  ]
)
Alignment: Positioned clock uses top-left corner as origin (0,0)

4.5 Conditional Rendering Logic
Scenario 1: No images selected yet

Show placeholder: centered icon + text "Select image to begin"
Background: dark gray (#121212)
Scenario 2: Only original image (no segmentation)

Show background layer only
Clock layer (with "12:30")
No foreground layer
User sees clock on background (no depth effect yet)
Scenario 3: Complete (background + foreground)

All three layers render
User sees full depth effect: subject appears in front of clock
4.6 Static Time Display
For this module:

Clock always shows "12:30" (hardcoded)
Format doesn't change text (all formats show same time)
Purpose: visual layout testing only
Live time updates come in Module 9
4.7 Preview Integration
Studio Screen Updates:

Replace placeholder preview area with WallpaperPreview widget
Pass current wallpaperData and wallpaperConfig
Preview area height: 400dp (fixed for Studio screen)
Centers preview within available width
State Management:

Studio screen maintains wallpaperConfig as state variable
Initialize with default WallpaperConfig in initState()
Preview rebuilds when config changes (setState)
4.8 Text Rendering Details
Font Size Calculation:

Config stores fontSize as decimal (0.24 = 24%)
Actual size = fontSize × container width
Example: 24% of 360dp wide container = 86.4dp text
Scales automatically with container size
Position Calculation:

Config stores positions as decimals (0.48 = 48%)
Actual position = percentage × dimension
horizontalPos 0.48 on 360dp width = 172.8dp from left
verticalPos 0.24 on 760dp height = 182.4dp from top
Shadow Implementation:

TextStyle shadows property (list of Shadow objects)
Single shadow:
Color: black with 50% opacity
Offset: (0, 4dp) - slightly below text
Blur radius: 8dp
Purpose: ensure readability on any background color
4.9 Responsive Behavior
Preview adapts to different screen sizes:

AspectRatio maintains phone proportions
Font size scales with width (always 24% of width)
Positions scale with both dimensions
Result: looks consistent on all devices
4.10 Performance Considerations
Use const constructors where possible
Cache Image widgets (don't rebuild unnecessarily)
Avoid rebuilding entire preview when only config changes
LayoutBuilder only rebuilds when size changes
Text rendering is cheap (no complex shapes)
Expected Outcomes:
Preview shows phone-shaped container with rounded corners
Background image fills container
Clock "12:30" appears at default position (upper-middle area)
Foreground subject overlays clock (depth effect visible)
Clock readable with shadow effect
Layout proportional and centered
No performance lag when rendering
Testing Criteria:
Preview matches phone aspect ratio (tall and narrow)
Clock appears between background and foreground layers
Clock text large and readable (not tiny)
Shadow visible on both light and dark backgrounds
Foreground transparency preserved (can see background through empty areas)
Preview responsive to container size changes
No text cutoff or overflow
Borders and corners render cleanly
Visual Verification:
Expected depth effect:

text

View from front:
┌─────────────────┐
│                 │ ← Top area (empty background)
│      12:30      │ ← Clock (white text with shadow)
│   ┌────────┐    │ ← Foreground subject starts
│   │ PERSON │    │ ← Subject overlaps clock bottom
│   │  HEAD  │    │ ← Clock appears "behind" subject
│   │  BODY  │    │ 
│   └────────┘    │
└─────────────────┘

Side view (layer concept):
Background ──────────── (layer 1, farthest back)
Clock ─────────────────── (layer 2, middle)
Foreground ───────────────── (layer 3, front)
Key Files to Create:
models/wallpaper_config.dart - Configuration data model
widgets/wallpaper_preview.dart - Reusable preview component
Updated screens/studio_screen.dart - Integrate preview widget
No New Dependencies:
Uses existing Flutter widgets (Stack, Positioned, Text, Image, AspectRatio)

Critical Notes for AI Agent:
Layer order is critical: bg → clock → fg (do not reorder)
Clock position (0,0) is top-left corner, not center
Font size must scale with container width (not fixed dp value)
PNG transparency in foreground layer is essential for effect
Shadow is not optional (ensures readability)
Static "12:30" is intentional for this module
🟡 MODULE 5: Basic Studio Editor (Position & Size)
Objective:
Implement interactive slider controls in Basics tab that allow users to adjust clock font size and position in real-time, with immediate visual feedback in the preview.

Detailed Requirements:
5.1 Basics Tab Layout
Create BasicsTab widget with vertical scrollable layout containing three slider controls:

Layout Structure:

text

ListView (scrollable)
  ├── Font Size Slider
  │   ├── Label row (left: "Font Size", right: "24%")
  │   └── Slider
  │
  ├── Spacer (24dp)
  │
  ├── Horizontal Position Slider
  │   ├── Label row (left: "Horizontal Position", right: "48%")
  │   └── Slider
  │
  ├── Spacer (24dp)
  │
  └── Vertical Position Slider
      ├── Label row (left: "Vertical Position", right: "24%")
      └── Slider
Padding: 16dp around entire list

5.2 Slider Component Design
Create reusable slider builder method/widget with these specifications:

Visual Appearance:

Track height: 4dp
Active track color: Yellow (#FFD700)
Inactive track color: Dark gray (#424242)
Thumb size: 20dp diameter circle
Thumb color: Yellow (#FFD700)
No tick marks or divisions
Label Row:

Two text elements in Row with SpaceBetween alignment
Left text (label): Light gray (#B0B0B0), 16sp
Right text (value): Yellow (#FFD700), 16sp, bold
Margin below: 8dp before slider
Value Display:

Font Size: Shows percentage (e.g., "24%")
Positions: Show percentage (e.g., "48%")
Calculation: (value × 100).toStringAsFixed(0) + "%"
Updates in real-time as slider moves
5.3 Slider Ranges & Initial Values
Font Size Slider:

Minimum: 0.1 (10% of screen width)
Maximum: 0.5 (50% of screen width)
Initial: 0.24 (24%)
Divisions: None (continuous)
Step size: Smooth (no discrete steps)
Horizontal Position Slider:

Minimum: 0.0 (left edge)
Maximum: 1.0 (right edge)
Initial: 0.48 (slightly left of center)
Note: Value represents left edge of text, not center
Vertical Position Slider:

Minimum: 0.0 (top edge)
Maximum: 1.0 (bottom edge)
Initial: 0.24 (upper quarter)
Note: Value represents top edge of text baseline
5.4 Real-Time Update Mechanism
Data Flow:

text

User drags slider
  → onChanged callback fires
  → Update config property (fontSize/horizontalPos/verticalPos)
  → Call onConfigChanged callback
  → Parent (StudioScreen) receives updated config
  → Parent calls setState()
  → WallpaperPreview rebuilds with new config
  → Clock position/size updates visually
Update Frequency:

Update on every slider movement (not just on release)
Smooth continuous updates (60fps target)
No debouncing or throttling (performance sufficient)
5.5 State Management Architecture
StudioScreen State:

Holds wallpaperConfig instance
Initializes with default values in initState()
Provides callback method: _updateConfig(WallpaperConfig newConfig)
Callback Implementation:

text

Method: _updateConfig(WallpaperConfig newConfig)
Action: setState(() { wallpaperConfig = newConfig; })
Result: Triggers rebuild of preview
BasicsTab Props:

Receives: config (current WallpaperConfig)
Receives: onConfigChanged (callback function)
On slider change: Modifies config object, calls callback
5.6 Slider Interaction Behavior
Drag Interaction:

User can drag thumb smoothly
Track clickable (tap to jump to position)
Haptic feedback on drag start (optional enhancement)
Visual feedback: thumb enlarges slightly when pressed
Value Constraints:

Values clamped to min/max automatically by Slider widget
No overflow or underflow possible
Decimal precision maintained (not rounded until display)
Edge Cases:

Min value: Clock very small/top-left (allowed, not blocked)
Max value: Clock very large/bottom-right (allowed, may overflow preview - user's choice)
Reset: No reset button in this module (user manually adjusts)
5.7 Preview Synchronization
Preview Behavior:

Preview positioned above tab bar (established in Module 4)
Preview receives updated config on every slider change
Clock re-renders at new position/size immediately
Smooth visual feedback (no lag or jank)
Performance Target:

60fps while dragging slider
No dropped frames
Instant visual response (<16ms update time)
5.8 Tab Integration
Studio Screen Updates:

TabController already setup (Module 1)
Replace "Basics tab" placeholder with BasicsTab widget
Other tabs remain placeholders ("Typography tab" text, etc.)
Tab Switching:

User can switch to other tabs (no content yet)
Switching back to Basics tab retains slider positions
Config state persists across tab switches
5.9 Accessibility Considerations
Slider Accessibility:

Sliders have semantic labels ("Font Size", "Horizontal Position", "Vertical Position")
Value announced when changed (screen reader support)
Keyboard control: arrow keys to adjust (Android accessibility feature)
5.10 Visual Polish
Spacing:

24dp vertical spacing between slider groups
8dp between label and slider track
16dp padding around tab content
Alignment:

Labels left-aligned
Values right-aligned
Sliders full width (minus padding)
Typography:

Label text: 16sp, regular weight, gray
Value text: 16sp, bold weight, yellow
Consistent with app theme
5.11 Validation & Bounds
Automatic Bounds:

Slider widget enforces min/max automatically
No manual validation needed
Values always within defined ranges
Visual Bounds:

Clock may overflow preview if positioned at edges with large size
This is expected behavior (user can see and adjust)
No automatic constraint to keep clock fully visible
5.12 Testing Scenarios
Test Case 1: Font Size

Drag to minimum (10%) → clock very small but visible
Drag to maximum (50%) → clock very large, may fill preview
Verify percentage updates in real-time
Test Case 2: Horizontal Position

Drag to 0.0 → clock at left edge
Drag to 1.0 → clock at right edge (may overflow right)
Drag to 0.5 → clock roughly centered
Test Case 3: Vertical Position

Drag to 0.0 → clock at top
Drag to 1.0 → clock at bottom (may overflow)
Drag to 0.3 → clock in upper-middle area
Test Case 4: Combined Adjustments

Adjust size, then position → preview updates correctly
Adjust position, then size → preview updates correctly
Rapid slider changes → no lag or crash
Test Case 5: Tab Switching

Adjust sliders, switch tab → config retained
Switch back to Basics → sliders show previous values
Preview still reflects settings
Expected Outcomes:
Three functional sliders in Basics tab
Slider values displayed as percentages
Preview updates in real-time (smooth, no lag)
Clock size and position directly controlled by sliders
Intuitive user experience (drag = immediate visual change)
No crashes or performance issues
Tab switching preserves settings
Testing Criteria:
Drag font size slider → clock resizes smoothly
Drag position sliders → clock moves smoothly
Percentage values update while dragging
Preview updates without delay (<100ms perceived lag)
No jank or stuttering during drag
Extreme values (min/max) render correctly
Tab switch preserves slider state
Works on different screen sizes
User Experience Flow:
text

User opens Studio screen
  → Sees Basics tab active by default
  → Sees three sliders with default values
  → Preview shows clock at default position/size
  → User drags Font Size slider right
  → Clock grows larger in preview
  → User drags Horizontal Position slider left
  → Clock moves left
  → User drags Vertical Position slider down
  → Clock moves down
  → User satisfied with position
  → Can now switch to Typography tab (next module)
Key Files to Create:
widgets/basics_tab.dart - Basics tab implementation
Updated screens/studio_screen.dart - Add state management for config
widgets/wallpaper_preview.dart - Already created in Module 4, no changes needed
No New Dependencies
Uses existing Flutter Slider widget

Critical Notes for AI Agent:
Config object is modified in-place (not immutable)
setState() in parent triggers preview rebuild
Slider onChanged fires continuously, not just onChangeEnd
Position values are relative (0.0-1.0), not absolute pixels
Clock position is top-left corner of text, not center point
Large font sizes intentionally allowed to overflow (user choice)
Performance is critical - test on real device, not just emulator
🟠 MODULE 6: Typography Customization
Objective:
Implement Typography tab with controls for clock format selection, font family, letter spacing, and color customization, allowing users to fully style the clock appearance.

Detailed Requirements:
6.1 Typography Tab Layout
Create TypographyTab widget with vertical scrollable layout containing five control sections:

Layout Structure:

text

ListView (scrollable, 16dp padding)
  ├── Clock Style Section
  │   ├── Section label: "Clock Style"
  │   └── Horizontal chip selector (HH:MM, HH.MM, HH:MM:SS, etc.)
  │
  ├── Spacer (24dp)
  │
  ├── Depth Layering Section
  │   ├── Section label: "Depth Layering"
  │   └── Chip selector (Standard, Hours Forward, Minutes Forward)
  │
  ├── Spacer (24dp)
  │
  ├── Font Family Section
  │   ├── Section label: "Font Family"
  │   └── Horizontal scrollable chip selector
  │
  ├── Spacer (24dp)
  │
  ├── Letter Spacing Section
  │   ├── Label + value row
  │   └── Slider (same style as Module 5)
  │
  ├── Spacer (24dp)
  │
  ├── Font Color Section
  │   ├── Section label: "Font Color"
  │   └── Color palette grid
  │
  ├── Spacer (24dp)
  │
  └── Secondary Color Section
      ├── Section label: "Secondary Color (Optional)"
      ├── Hint text
      └── Color palette grid
6.2 Clock Style Selector
Purpose:
Allow user to choose time display format

Options (ChoiceChip list):

"HH:MM" - 24-hour format (14:30)
"HH.MM" - Dot separator (14.30)
"HH:MM:SS" - With seconds (14:30:45)
"HH:MM:SS" - 12-hour format (02:30 PM) - optional
"HH/MM" - Slash separator (14/30)
Chip Design:

Unselected: Dark gray background (#424242), white text
Selected: Yellow background (#FFD700), black text
Border radius: 16dp
Padding: 12dp horizontal, 8dp vertical
Spacing between chips: 8dp
Wrap layout (horizontal flow, wraps to next line if needed)
Behavior:

Single selection (radio button behavior)
Tap to select
Updates config.clockFormat property
Preview immediately shows new format
Default: "HH:MM"
6.3 Depth Layering Selector
Purpose:
Control which part of clock appears above/below foreground subject

Options:

"Standard" - Entire clock behind foreground
"Hours Forward" - Hour digits in front, minutes behind
"Minutes Forward" - Minute digits in front, hours behind
Implementation Note:

Store as config.depthMode property
Rendering logic will be implemented in Module 8 (WallpaperService)
For now: just save selection, no visual change in Flutter preview
Preview always shows standard mode (full clock) in this module
Chip Design:
Same style as Clock Style selector

6.4 Font Family Selector
Font Options:
Provide these font choices:

"Default" - System default (Roboto on Android)
"Roboto" - Explicitly use Roboto
"Montserrat" - Modern geometric sans-serif
"Oswald" - Condensed sans-serif
"Bebas Neue" - Tall condensed display font
"Poppins" - Rounded geometric sans-serif
Implementation:

Download font files (.ttf) from Google Fonts
Add to assets folder: assets/fonts/
Declare in pubspec.yaml under fonts section
Use fontFamily property in TextStyle
Layout:

SingleChildScrollView horizontal scroll
Chips in horizontal Row
Can scroll left/right if too many fonts
No wrap (single horizontal line)
Chip Design:

Same as above, but in horizontal scrollable list
Shows font name in its own typeface (preview of font)
6.5 Letter Spacing Control
Purpose:
Adjust spacing between clock characters for stylistic effect

Slider Configuration:

Minimum: -5.0 (characters overlap)
Maximum: 10.0 (wide spacing)
Initial: 0.0 (default spacing)
Display value: letterSpacing.toStringAsFixed(2) (e.g., "2.50")
Behavior:

Negative values: tighten spacing (condensed look)
Positive values: expand spacing (spread out look)
Applied to TextStyle.letterSpacing property
Visual feedback in preview immediately
Slider Style:
Same as Module 5 (yellow active, gray inactive)

6.6 Font Color Picker
Purpose:
Set primary clock text color

Predefined Color Palette:
Provide 8 color options in grid:

White (#FFFFFF)
Black (#000000)
Red (#FF0000)
Green (#00FF00)
Blue (#0000FF)
Yellow (#FFFF00)
Cyan (#00FFFF)
Magenta/Pink (#FF00FF)
Color Circle Design:

Size: 48dp diameter
Shape: Perfect circle
Border: 3dp width
Border color: Yellow when selected, transparent when not
Tap to select
Wrap layout (4 per row on typical phone)
Spacing: 12dp between circles
Behavior:

Single selection
Updates config.fontColor
Preview updates immediately
6.7 Secondary Color Picker
Purpose:
Optional gradient or dual-color effect (for future advanced rendering)

Layout:

Same color palette as primary (8 colors)
Hint text above: "Select a color to use different color for MM or enable gradient"
Text style: 14sp, gray, italic
Behavior:

Optional (can be null)
If selected: stores in config.secondaryColor
If not selected: remains null
In this module: doesn't affect preview (placeholder for Module 8)
User can deselect by tapping selected color again (toggles to null)
6.8 Color Picker Widget
Create reusable ColorPickerWidget component:

Props:

currentColor: Color (currently selected)
onColorChanged: Function(Color) (callback)
allowNull: bool (for secondary color, allows deselection)
Implementation:

Wrap widget around color circles
GestureDetector on each circle
Visual feedback: border on selected color
Rebuild on selection change
6.9 Typography Config Properties
Add to WallpaperConfig model:

text

Properties to add:
- clockFormat: String (e.g., "HH:MM")
- depthMode: String (e.g., "Standard")
- fontFamily: String (e.g., "Roboto")
- letterSpacing: double (e.g., 0.0)
- fontColor: Color (e.g., Colors.white)
- secondaryColor: Color? (nullable, e.g., null or Colors.yellow)
Default Values:

clockFormat: "HH:MM"
depthMode: "Standard"
fontFamily: "Default"
letterSpacing: 0.0
fontColor: Colors.white
secondaryColor: null
6.10 Preview Integration
Update WallpaperPreview widget:

Clock Text Updates:

Format: Use _getFormattedTime() method based on config.clockFormat
Font family: Apply config.fontFamily to TextStyle
Letter spacing: Apply config.letterSpacing to TextStyle
Color: Apply config.fontColor to TextStyle
Secondary color: Ignore in preview for now (Module 8 feature)
Time Formatting Method:

text

Method: _getFormattedTime(String format)
Input: Clock format string
Returns: Formatted current time string
Logic:
- Get current DateTime
- Switch on format:
  - "HH:MM" → "14:30"
  - "HH.MM" → "14.30"
  - "HH:MM:SS" → "14:30:45"
  - "HH/MM" → "14/30"
  - Default → "14:30"
Font Family Mapping:

text

Method: _getFontFamily(String family)
Input: Font family name from config
Returns: FontFamily string for TextStyle
Logic:
- If "Default" → null (uses system default)
- Otherwise → return family name (matches font asset name)
6.11 Section Label Styling
Consistent Section Headers:

Text: White (#FFFFFF)
Size: 16sp
Weight: Medium (500)
Margin below: 12dp
Margin above (except first): 24dp
6.12 Real-Time Updates
Data Flow:
Same pattern as Module 5:

text

User selects chip/color/adjusts slider
  → Update config property
  → Call onConfigChanged callback
  → Parent calls setState()
  → Preview rebuilds with new typography
  → Visual change immediate
6.13 Typography Tab State
No Local State:

All state in config object (passed from parent)
Tab is stateless (receives config, calls callback)
Parent (StudioScreen) manages state
6.14 Font Asset Setup
Add to pubspec.yaml:

YAML

fonts:
  - family: Roboto
    fonts:
      - asset: assets/fonts/Roboto-Regular.ttf
      - asset: assets/fonts/Roboto-Bold.ttf
        weight: 700
  - family: Montserrat
    fonts:
      - asset: assets/fonts/Montserrat-Regular.ttf
      - asset: assets/fonts/Montserrat-Bold.ttf
        weight: 700
  # ... (repeat for all fonts)
Font Files to Include:

Download from fonts.google.com
Include regular and bold weights
Place in assets/fonts/ directory
Ensure naming matches pubspec declarations
Expected Outcomes:
Typography tab fully functional
Five control sections working
Clock format changes reflected in preview
Font family changes visible
Letter spacing adjusts spacing
Color changes update text color
All controls smooth and responsive
Preview updates in real-time
Testing Criteria:
Select each clock format → preview shows correct format
Select each font family → preview uses that font
Adjust letter spacing negative → characters closer
Adjust letter spacing positive → characters spread
Select each color → clock changes color
Select secondary color → saved but no visual change yet
Switch between formats rapidly → no lag
Extreme letter spacing (-5, +10) → renders correctly
Font loading: verify all fonts render (not falling back to default)
User Experience Flow:
text

User switches to Typography tab
  → Sees five control sections
  → Selects "HH.MM" format → preview shows 14.30
  → Selects "Montserrat" font → preview font changes
  → Increases letter spacing to 3.0 → wider spacing visible
  → Selects yellow color → clock turns yellow
  → Preview shows all changes combined
  → User satisfied, can apply or continue customizing
Key Files to Create:
widgets/typography_tab.dart - Typography tab implementation
widgets/color_picker_widget.dart - Reusable color picker
Updated models/wallpaper_config.dart - Add typography properties
Updated widgets/wallpaper_preview.dart - Apply typography to clock text
assets/fonts/ - Font files directory
Dependencies to Add:
YAML

# In pubspec.yaml assets section:
assets:
  - assets/fonts/
External Resources:

Google Fonts (download .ttf files)
Critical Notes for AI Agent:
Font files must be exact match to pubspec family names
Letter spacing can be negative (overlapping characters is valid)
Secondary color doesn't visually work yet (future module)
Clock shows current time (not static 12:30) for format testing
Depth layering selection saved but not visually implemented in preview
Color picker allows null for secondary (deselection feature)
Font preview in chip selector requires font to be loaded
🟠 MODULE 7: Effects & Transform
Objective:
Implement Effects and Transform tabs providing advanced visual styling controls including opacity, shadow, stroke, rotation, stretching, and skewing transformations.

Detailed Requirements:
7.1 Effects Tab Layout
Create EffectsTab widget with vertical scrollable layout:

Layout Structure:

text

ListView (scrollable, 16dp padding)
  ├── Text Opacity Slider
  │   ├── Label + value row
  │   └── Slider
  │
  ├── Spacer (24dp)
  │
  ├── Atmospheric Depth Toggle
  │   ├── SwitchListTile
  │   └── Subtitle description
  │
  ├── Spacer (24dp)
  │
  ├── Adaptive Edge Stroke Toggle
  │   ├── SwitchListTile
  │   └── Subtitle description
  │
  ├── Spacer (24dp)
  │
  ├── Text Shadow Toggle
  │   └── SwitchListTile
  │
  ├── Spacer (24dp)
  │
  └── Text Stroke Toggle
      └── SwitchListTile
7.2 Text Opacity Control
Purpose:
Make clock semi-transparent for subtle effect

Slider Configuration:

Minimum: 0.0 (fully transparent, invisible)
Maximum: 1.0 (fully opaque)
Initial: 1.0 (opaque)
Display: Percentage format "100%"
Calculation: (value × 100).toInt() + "%"
Preview Effect:

Wrap clock Text widget in Opacity widget
Opacity.opacity = config.textOpacity
At 0.5: clock is 50% transparent (can see background through it)
At 0.0: clock invisible (edge case, allowed)
Behavior:

Smooth slider same style as Module 5
Real-time preview update
Works independently of other effects
7.3 Atmospheric Depth Toggle
Purpose:
Add subtle blur gradient to background for enhanced depth perception

UI Component:

SwitchListTile widget
Title: "Enable Atmospheric Depth"
Subtitle: "Adds subtle blur gradient to background"
Active color: Yellow (#FFD700)
Default: false (off)
Config Property:

Add: config.atmosphericDepthEnabled (bool)
Implementation Note:

Visual effect implemented in Module 8 (Kotlin WallpaperService)
In Flutter preview: can implement simplified version (optional)
Basic preview: apply slight blur to background image
Advanced: gradient blur (more blur at bottom, less at top)
Optional Flutter Preview:

Use ImageFiltered widget with blur
Apply BackdropFilter with ImageFilter.blur(sigmaX: 15, sigmaY: 15)
Only to background layer, not foreground
7.4 Adaptive Edge Stroke Toggle
Purpose:
Add outline around clock text for better visibility on busy backgrounds

UI Component:

SwitchListTile
Title: "Enable Edge Stroke"
Subtitle: "Adds outline to text for better visibility"
Active color: Yellow
Default: false
Config Property:

Add: config.edgeStrokeEnabled (bool)
Preview Effect:

When enabled: clock text has stroke (outline)
Implementation: Paint with style = PaintingStyle.stroke
Stroke width: 2dp
Stroke color: White (or contrasting color)
Text rendered twice: stroke first, then fill on top
TextStyle Implementation:

text

Approach 1 (Simple):
- TextStyle foreground: Paint with stroke style
- Separate Text widget with fill

Approach 2 (Stack):
- Stack two Text widgets:
  1. Bottom: stroke version
  2. Top: fill version
7.5 Text Shadow Toggle
Purpose:
Enable/disable drop shadow effect (shadow was default in Module 4)

UI Component:

SwitchListTile
Title: "Enable Shadow"
No subtitle
Default: true (shadow on by default)
Config Property:

Add: config.shadowEnabled (bool)
Preview Effect:

When true: TextStyle.shadows contains shadow
When false: TextStyle.shadows = null or empty list
Shadow spec (when enabled):
Color: Black, 50% opacity
Offset: (0, 4dp)
Blur radius: 8dp
7.6 Text Stroke Toggle
Purpose:
Alternative to edge stroke - filled stroke effect

UI Component:

SwitchListTile
Title: "Enable Stroke"
Subtitle: "Different from edge stroke - filled outline effect"
Default: false
Config Property:

Add: config.strokeEnabled (bool)
Difference from Edge Stroke:

Edge stroke: thin outline only
Text stroke: thicker, filled outline effect
Both can be enabled simultaneously (layered effect)
7.7 Transform Tab Layout
Create TransformTab widget:

Layout Structure:

text

ListView (scrollable, 16dp padding)
  ├── Rotation Slider
  ├── Spacer (24dp)
  ├── Stretch Slider
  ├── Spacer (24dp)
  ├── Horizontal Skew Slider
  ├── Spacer (24dp)
  ├── Vertical Skew Slider
  ├── Spacer (24dp)
  ├── Bottom Skew H Slider
  ├── Spacer (24dp)
  └── Left Skew Slider
7.8 Rotation Control
Purpose:
Rotate clock text for angled effect

Slider Configuration:

Minimum: -180.0 degrees
Maximum: 180.0 degrees
Initial: 0.0 (no rotation)
Display: Degrees with "°" symbol (e.g., "45°")
Config Property:

Add: config.rotation (double)
Preview Effect:

Wrap clock in Transform widget
Transform.rotate or Matrix4.rotationZ
Rotation in radians: rotation × π / 180
Pivot point: center of text (Alignment.center)
Behavior:

Positive values: clockwise rotation
Negative values: counter-clockwise rotation
-180° and 180° produce same result (upside down)
7.9 Stretch Control
Purpose:
Vertically stretch or compress clock text

Slider Configuration:

Minimum: 0.5 (compressed to 50% height)
Maximum: 2.0 (stretched to 200% height)
Initial: 1.0 (normal height)
Display: Decimal with 2 places (e.g., "1.50")
Config Property:

Add: config.stretch (double)
Preview Effect:

Matrix4.scale with different X and Y
X scale: 1.0 (width unchanged)
Y scale: config.stretch (height changed)
Creates tall/narrow or short/wide text
7.10 Horizontal Skew Control
Purpose:
Slant text horizontally (italic-like effect)

Slider Configuration:

Minimum: -1.0 (skew left)
Maximum: 1.0 (skew right)
Initial: 0.0 (no skew)
Display: Decimal "0.50"
Config Property:

Add: config.horizontalSkew (double)
Preview Effect:

Matrix4 with setEntry(0, 1, horizontalSkew)
Creates slanted/italic appearance
Different from true italic font
7.11 Vertical Skew Control
Purpose:
Tilt text vertically (perspective effect)

Slider Configuration:

Minimum: -1.0
Maximum: 1.0
Initial: 0.0
Display: Decimal
Config Property:

Add: config.verticalSkew (double)
Preview Effect:

Matrix4 with setEntry(1, 0, verticalSkew)
Creates top/bottom tilt
Perspective-like distortion
7.12 Bottom Skew H Control
Purpose:
Skew only bottom of text (trapezoidal effect)

Implementation Note:

Complex transformation
In Flutter preview: approximate with vertical skew
Full effect in Kotlin WallpaperService (Module 8)
Config Property:

Add: config.bottomSkewH (double)
Slider Configuration:

Same as other skews (-1.0 to 1.0)
7.13 Left Skew Control
Purpose:
Skew from left side

Similar to Bottom Skew:

Saved in config
Simpli
<truncated 69322 bytes>

NOTE: The output was truncated because it was too long. Use a more targeted query or a smaller range to get the information you need.
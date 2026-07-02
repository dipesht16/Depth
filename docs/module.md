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
Simplified in Flutter preview
Full implementation in Kotlin
Config Property:
Add: config.leftSkew (double)
7.14 Matrix Transformation Implementation
Combining Transformations:
In WallpaperPreview, update clock rendering:
text
Transform widget wrapping clock Text:
- transform: Matrix4.identity()
  ..rotateZ(rotation in radians)
  ..scale(1.0, stretch)
  ..setEntry(0, 1, horizontalSkew)
  ..setEntry(1, 0, verticalSkew)
  ...(additional skew transformations)
- alignment: Alignment.center
- child: Opacity(
  opacity: textOpacity,
  child: Text(...)
  )
Order Matters:
Rotation first
Then scale (stretch)
Then skew transformations
Order affects visual result
7.15 Effects Config Properties
Add to WallpaperConfig:
text
Effects properties:
- textOpacity: double (default 1.0)
- atmosphericDepthEnabled: bool (default false)
- edgeStrokeEnabled: bool (default false)
- shadowEnabled: bool (default true)
- strokeEnabled: bool (default false)
Transform properties:
- rotation: double (default 0.0)
- stretch: double (default 1.0)
- horizontalSkew: double (default 0.0)
- verticalSkew: double (default 0.0)
- bottomSkewH: double (default 0.0)
- leftSkew: double (default 0.0)
7.16 Preview Updates for Effects
Shadow Implementation:
text
TextStyle shadows property:
- If shadowEnabled: [Shadow(...)]
- If not: null or []
Stroke Implementation:
text
Stack approach:
1. Text with stroke (foreground Paint)
2. Text with fill (normal color)
Both layered if edgeStrokeEnabled
Opacity Implementation:
text
Opacity widget wrapping entire Text
7.17 Switch Styling
SwitchListTile Design:
Active color: Yellow (#FFD700)
Inactive color: Gray (#757575)
Title text: White, 16sp
Subtitle text: Gray, 14sp
Switch on right side
Tap anywhere on tile to toggle
7.18 Complex Transform Handling
Edge Cases:
Extreme rotation (±180°): text upside down (allowed)
Extreme stretch (0.5 or 2.0): heavily distorted (allowed)
Multiple skews combined: complex distortion (allowed)
User experimentation encouraged
Performance:
Matrix transformations cheap (GPU accelerated)
No performance impact from complex transforms
Smooth slider interaction maintained
Expected Outcomes:
Effects tab with 5 controls functional
Transform tab with 6 sliders functional
All effects visible in preview
Transformations render correctly
Smooth real-time updates
No performance degradation
Combined effects work together
Testing Criteria:
Effects Tab:
Opacity slider: 0% = invisible, 100% = opaque
Atmospheric depth toggle: visual blur (if implemented in preview)
Edge stroke toggle: outline appears around text
Shadow toggle: shadow appears/disappears
Stroke toggle: different outline effect
Transform Tab:
Rotation: -90° = rotated left, +90° = rotated right
Stretch: 0.5 = squashed, 2.0 = tall
Horizontal skew: -1.0 = left slant, +1.0 = right slant
Vertical skew: creates tilt effect
Combined transforms: rotation + stretch + skew = complex effect
Integration:
Effects + Transform together work correctly
Typography + Effects + Transform all apply simultaneously
No conflicts between different settings
Preview accurately represents all settings
User Experience Flow:
text
User switches to Effects tab
  → Adjusts opacity to 70% → clock semi-transparent
  → Enables shadow → drop shadow appears
  → Enables edge stroke → outline appears
User switches to Transform tab
  → Rotates 15° → slight angle
  → Stretches to 1.5 → taller text
  → Adds horizontal skew 0.3 → italic-like slant
  → Preview shows rotated, stretched, skewed, semi-transparent clock
  → User satisfied with creative styling
Key Files to Create:
widgets/effects_tab.dart - Effects tab implementation
widgets/transform_tab.dart - Transform tab implementation
Updated models/wallpaper_config.dart - Add 11 new properties
Updated widgets/wallpaper_preview.dart - Apply effects and transforms to clock
No New Dependencies
Uses existing Flutter Transform, Opacity, Matrix4 widgets
Critical Notes for AI Agent:
Matrix4 transformations are cumulative (order matters)
Some skew effects simplified in Flutter preview (full in Kotlin)
Rotation uses radians, display shows degrees
Stroke and edge stroke are different effects (can combine)
Atmospheric depth may be simplified in preview (full effect in Kotlin)
Transform alignment must be center for expected rotation behavior
Extreme values allowed (user experimentation feature, not bug)
All sliders use same visual style as Module 5
  MODULE 8: Kotlin WallpaperService (Static)
Objective:
Create native Android WallpaperService in Kotlin that renders the depth wallpaper using saved 
configuration, displaying all layers (background, clock, foreground) on the home screen with static time 
display.
Detailed Requirements:
8.1 WallpaperService Fundamentals
Core Concept:
WallpaperService is NOT an Activity
Runs as background service
Renders directly to SurfaceHolder (canvas)
Persists when Flutter app closes
Managed by Android's WallpaperManager system
Service Lifecycle:
text
System requests wallpaper
  → onCreateEngine() called
  → Creates Engine instance
  → Engine.onCreate()
  → Engine.onSurfaceCreated()
  → Engine.onSurfaceChanged()
  → Draw wallpaper to canvas
  → Wait for visibility/offset changes
  → Update as needed
  → Eventually: onDestroy() cleanup
8.2 Kotlin Project Structure
Create these files in android/app/src/main/kotlin/.../:
text
package_name/
├── DepthWallpaperService.kt (main service)
├── WallpaperConfig.kt (data class)
└── BitmapLoader.kt (helper class)
8.3 WallpaperConfig Data Class
Purpose:
Mirror Flutter's WallpaperConfig, store all customization settings
Properties Needed:
Kotlin
data class WallpaperConfig(
 // Basics
 val fontSize: Float,
 val horizontalPos: Float,
 val verticalPos: Float,
 // Typography
 val clockFormat: String,
 val fontColor: Int,
 val fontFamily: String,
 val letterSpacing: Float,
 val secondaryColor: Int?,
 // Effects
 val textOpacity: Float,
 val shadowEnabled: Boolean,
 val strokeEnabled: Boolean,
 val edgeStrokeEnabled: Boolean,
 val atmosphericDepthEnabled: Boolean,
 // Transform
 val rotation: Float,
 val stretch: Float,
 val horizontalSkew: Float,
 val verticalSkew: Float,
 // File paths
 val backgroundPath: String?,
 val foregroundPath: String?
)
Factory Method:
Kotlin
companion object {
 fun fromSharedPreferences(prefs: SharedPreferences): WallpaperConfig {
 return WallpaperConfig(
 fontSize = prefs.getFloat("fontSize", 0.24f),
 horizontalPos = prefs.getFloat("horizontalPos", 0.48f),
 // ... load all properties with defaults
 )
 }
}
8.4 SharedPreferences Storage
Storage Location:
Name: "wallpaper_config"
Mode: MODE_PRIVATE
Stored in: /data/data/package_name/shared_prefs/
Data Persistence:
Flutter saves config via MethodChannel (see 8.5)
Kotlin reads from SharedPreferences
Survives app restarts
Independent of Flutter app lifecycle
8.5 MethodChannel Integration
MainActivity.kt Setup:
Create MethodChannel handler:
Channel Name:
Kotlin
private val CHANNEL = "com.yourapp/wallpaper"
Methods to Handle:
Method 1: saveConfig
Purpose: Receive config from Flutter, save to SharedPreferences
Arguments: Map<String, Any> containing all config properties
Action: Convert map to SharedPreferences entries
Return: Boolean success
Method 2: setWallpaper
Purpose: Launch system wallpaper picker
Arguments: None
Action: Create Intent for ACTION_CHANGE_LIVE_WALLPAPER
ComponentName: DepthWallpaperService class
Return: Boolean success
Implementation Pattern:
Kotlin
MethodChannel(...).setMethodCallHandler { call, result ->
 when (call.method) {
 "saveConfig" -> {
 val configMap = call.arguments as Map<String, Any>
 saveConfigToPrefs(configMap)
 result.success(true)
 }
 "setWallpaper" -> {
 launchWallpaperPicker()
 result.success(true)
 }
 else -> result.notImplemented()
 }
}
Config Saving Logic:
Kotlin
private fun saveConfigToPrefs(config: Map<String, Any>) {
 val prefs = getSharedPreferences("wallpaper_config", MODE_PRIVATE)
 prefs.edit().apply {
 putFloat("fontSize", (config["fontSize"] as Double).toFloat())
 putFloat("horizontalPos", (config["horizontalPos"] as Double).toFloat())
 putInt("fontColor", config["fontColor"] as Int)
 putString("clockFormat", config["clockFormat"] as String)
 putString("backgroundPath", config["backgroundPath"] as String?)
 // ... save all properties
 apply() // or commit()
 }
}
Type Conversion Notes:
Dart double → Kotlin Float: cast to Double first, then toFloat()
Dart int → Kotlin Int: direct cast
Dart String → Kotlin String: direct cast
Dart Color.value → Kotlin Int (ARGB color)
8.6 DepthWallpaperService Structure
Service Declaration:
Kotlin
class DepthWallpaperService : WallpaperService() {
 override fun onCreateEngine(): Engine {
 return DepthWallpaperEngine()
 }
 inner class DepthWallpaperEngine : Engine() {
 // ... implementation
 }
}
Engine Class Variables:
Kotlin
inner class DepthWallpaperEngine : Engine() {
 private var backgroundBitmap: Bitmap? = null
 private var foregroundBitmap: Bitmap? = null
 private lateinit var config: WallpaperConfig
 private lateinit var clockPaint: Paint
 private lateinit var strokePaint: Paint
 private var canvasWidth: Int = 0
 private var canvasHeight: Int = 0
}
8.7 Engine Lifecycle Implementation
onCreate():
text
Purpose: Initialize resources
Steps:
1. Call super.onCreate()
2. Load config from SharedPreferences
3. Load bitmap images
4. Setup Paint objects
5. Ready for rendering
onSurfaceCreated():
text
Purpose: Surface ready for drawing
Action: Store surfaceHolder reference
onSurfaceChanged():
text
Purpose: Surface dimensions changed
Arguments: format, width, height
Steps:
1. Store canvas dimensions
2. Scale bitmaps if needed
3. Recalculate text size based on width
4. Trigger drawWallpaper()
onSurfaceRedrawNeeded():
text
Purpose: System requests redraw
Action: Call drawWallpaper()
onDestroy():
text
Purpose: Cleanup resources
Steps:
1. Recycle backgroundBitmap
2. Recycle foregroundBitmap
3. Call super.onDestroy()
8.8 Bitmap Loading
BitmapLoader Helper Class:
Purpose: Load and optimize images for wallpaper rendering
Method: loadOptimizedBitmap()
Kotlin
Parameters:
- path: String (file path)
- targetWidth: Int (screen width)
- targetHeight: Int (screen height)
Returns: Bitmap
Logic:
1. Use BitmapFactory.Options
2. Set inJustDecodeBounds = true (get dimensions without loading)
3. Decode file to get width/height
4. Calculate inSampleSize (downsample if too large)
5. Set inJustDecodeBounds = false
6. Set inPreferredConfig = ARGB_8888
7. Decode file with options
8. Scale to exact target size (if needed)
9. Return optimized bitmap
Sample Size Calculation:
Kotlin
Purpose: Reduce memory usage for large images
Logic:
- If image width > target width × 2: inSampleSize = 2
- If image width > target width × 4: inSampleSize = 4
- Powers of 2 for efficiency (2, 4, 8, 16)
- Example: 4000px image for 1080px screen → sample size 4 → loads as 1000px
Memory Considerations:
Full HD image (1920×1080 ARGB_8888): ~8MB memory
Downsample aggressively (wallpaper doesn't need full resolution)
Target: max 2048px on longest side
Recycle bitmaps when done (prevent memory leaks)
8.9 Paint Setup
Clock Text Paint:
Kotlin
clockPaint = Paint().apply {
 color = config.fontColor
 textSize = config.fontSize * canvasWidth
 isAntiAlias = true
 typeface = getTypefaceForFont(config.fontFamily)
 letterSpacing = config.letterSpacing / 100f // Android uses em units
 alpha = (config.textOpacity * 255).toInt()
 if (config.shadowEnabled) {
 setShadowLayer(8f, 0f, 4f, Color.BLACK)
 }
}
Stroke Paint (if enabled):
Kotlin
strokePaint = Paint().apply {
 color = Color.WHITE
 textSize = config.fontSize * canvasWidth
 isAntiAlias = true
 style = Paint.Style.STROKE
 strokeWidth = if (config.edgeStrokeEnabled) 2f else 4f
 typeface = clockPaint.typeface
 letterSpacing = clockPaint.letterSpacing
}
Typeface Loading:
Kotlin
private fun getTypefaceForFont(fontFamily: String): Typeface {
 return when (fontFamily) {
 "Roboto" -> Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
 "Montserrat" -> ResourcesCompat.getFont(this, R.font.montserrat_bold)
 "Oswald" -> ResourcesCompat.getFont(this, R.font.oswald_bold)
 // ... load from assets/fonts/
 else -> Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
 }
}
Font Asset Integration:
Copy .ttf files from Flutter assets to Android res/font/
Access via R.font.font_name
Or use assets folder path
8.10 Drawing Pipeline
Main drawWallpaper() Method:
Kotlin
private fun drawWallpaper() {
 val canvas = surfaceHolder.lockCanvas() ?: return
 try {
 // Layer 1: Background
 drawBackground(canvas)
 // Layer 2: Clock
 drawClock(canvas)
 // Layer 3: Foreground
 drawForeground(canvas)
 } finally {
 surfaceHolder.unlockCanvasAndPost(canvas)
 }
}
Layer 1: Background Drawing:
Kotlin
private fun drawBackground(canvas: Canvas) {
 backgroundBitmap?.let { bitmap ->
 val destRect = Rect(0, 0, canvas.width, canvas.height)
 if (config.atmosphericDepthEnabled) {
 // Apply blur effect
 val blurPaint = Paint().apply {
 maskFilter = BlurMaskFilter(15f, BlurMaskFilter.Blur.NORMAL)
 }
 canvas.drawBitmap(bitmap, null, destRect, blurPaint)
 } else {
 canvas.drawBitmap(bitmap, null, destRect, null)
 }
 }
}
Layer 2: Clock Drawing:
Kotlin
private fun drawClock(canvas: Canvas) {
 val time = getCurrentTime()
 // Calculate position
 val x = config.horizontalPos * canvas.width
 val y = config.verticalPos * canvas.height
 // Save canvas state for transformations
 canvas.save()
 // Apply transformations
 applyTransformations(canvas, x, y)
 // Draw stroke first (if enabled)
 if (config.edgeStrokeEnabled || config.strokeEnabled) {
 canvas.drawText(time, x, y, strokePaint)
 }
 // Draw main text
 canvas.drawText(time, x, y, clockPaint)
 // Restore canvas
 canvas.restore()
}
Transformation Application:
Kotlin
private fun applyTransformations(canvas: Canvas, pivotX: Float, pivotY: Float) {
 // Rotation
 if (config.rotation != 0f) {
 canvas.rotate(config.rotation, pivotX, pivotY)
 }
 // Stretch (scale Y axis)
 if (config.stretch != 1f) {
 canvas.scale(1f, config.stretch, pivotX, pivotY)
 }
 // Skew
 if (config.horizontalSkew != 0f || config.verticalSkew != 0f) {
 val matrix = Matrix()
 matrix.setSkew(config.horizontalSkew, config.verticalSkew, pivotX, pivotY)
 canvas.concat(matrix)
 }
}
Layer 3: Foreground Drawing:
Kotlin
private fun drawForeground(canvas: Canvas) {
 foregroundBitmap?.let { bitmap ->
 val destRect = Rect(0, 0, canvas.width, canvas.height)
 canvas.drawBitmap(bitmap, null, destRect, null)
 }
}
8.11 Time Formatting
getCurrentTime() Method:
Kotlin
private fun getCurrentTime(): String {
 val sdf = when (config.clockFormat) {
 "HH:MM:SS" -> SimpleDateFormat("HH:mm:ss", Locale.getDefault())
 "HH.MM" -> SimpleDateFormat("HH.mm", Locale.getDefault())
 "HH/MM" -> SimpleDateFormat("HH/mm", Locale.getDefault())
 else -> SimpleDateFormat("HH:mm", Locale.getDefault())
 }
 return sdf.format(Date())
}
Note: Time is static in this module (doesn't update). Module 9 adds live updates.
8.12 Android Manifest Configuration
Declare Service:
XML
<service
 android:name=".DepthWallpaperService"
 android:permission="android.permission.BIND_WALLPAPER"
 android:exported="true">
 <intent-filter>
 <action android:name="android.service.wallpaper.WallpaperService" />
 </intent-filter>
 <meta-data
 android:name="android.service.wallpaper"
 android:resource="@xml/wallpaper" />
</service>
Add Permission:
XML
<uses-permission android:name="android.permission.SET_WALLPAPER" />
<uses-permission android:name="android.permission.SET_WALLPAPER_HINTS" />
8.13 Wallpaper Metadata
Create res/xml/wallpaper.xml:
XML
<?xml version="1.0" encoding="utf-8"?>
<wallpaper
 xmlns:android="http://schemas.android.com/apk/res/android"
 android:description="@string/wallpaper_description"
 android:thumbnail="@drawable/wallpaper_thumbnail"
 android:author="@string/app_name" />
Add String Resource:
XML
<!-- res/values/strings.xml -->
<string name="wallpaper_description">Depth effect wallpaper with customizable clock</string>
Thumbnail Image:
Create preview image (512×512px)
Place in res/drawable/wallpaper_thumbnail.png
Shows in system wallpaper picker
8.14 Flutter Integration
Studio Screen - Apply Button:
Add button to Studio AppBar:
dart
IconButton(
 icon: Icon(Icons.check),
 onPressed: _applyWallpaper,
)
Apply Method:
dart
Future<void> _applyWallpaper() async {
 try {
 // Save config to SharedPreferences
 await platform.invokeMethod('saveConfig', {
 'fontSize': wallpaperConfig.fontSize,
 'horizontalPos': wallpaperConfig.horizontalPos,
 'verticalPos': wallpaperConfig.verticalPos,
 'fontColor': wallpaperConfig.fontColor.value,
 'clockFormat': wallpaperConfig.clockFormat,
 'letterSpacing': wallpaperConfig.letterSpacing,
 'textOpacity': wallpaperConfig.textOpacity,
 'shadowEnabled': wallpaperConfig.shadowEnabled,
 'rotation': wallpaperConfig.rotation,
 'stretch': wallpaperConfig.stretch,
 'backgroundPath': wallpaperData.backgroundImagePath,
 'foregroundPath': wallpaperData.foregroundImagePath,
 // ... all config properties
 });
 // Launch wallpaper picker
 await platform.invokeMethod('setWallpaper');
 // Show success message
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('Wallpaper configuration saved! Select "Depth Wallpaper" in picker.')),
 );
 } catch (e) {
 // Show error
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('Error: ${e.toString()}')),
 );
 }
}
8.15 Testing Procedure
Development Testing:
Configure wallpaper in Flutter app
Tap apply button
System wallpaper picker opens
Select "Depth Wallpaper" from list
Preview shows configured wallpaper
Tap "Set wallpaper"
Return to home screen
Verify: wallpaper displays correctly
Verification Checklist:
 Background image fills screen
 Clock appears at correct position
 Clock size matches configuration
 Foreground subject overlays clock
 Depth effect visible (subject in front of clock)
 Clock color correct
 Font family applied
 Rotation/stretch/skew applied
 Shadow/stroke visible if enabled
 No crashes or artifacts
8.16 Error Handling
Scenarios to Handle:
Missing Image Files:
If backgroundPath null or file not found: show solid color background
If foregroundPath null: show only background + clock (no depth effect)
Corrupted Config:
If SharedPreferences missing/corrupted: use default config
Never crash - always fallback to safe defaults
Out of Memory:
Catch OOM in bitmap loading
Log error, use null bitmap (skip that layer)
App continues functioning
Invalid Color Values:
Validate color integers (ARGB range)
Fallback to white if invalid
8.17 Performance Optimization
Drawing Efficiency:
Only redraw when necessary (not every frame)
Cache Paint objects (don't recreate each draw)
Use hardware acceleration (enabled by default)
Minimize canvas operations
Memory Management:
Downsample large images aggressively
Recycle bitmaps in onDestroy()
Don't hold references to Activity/Context
Use WeakReference if needed
Battery Impact:
Static wallpaper = minimal battery use
No animations in this module
Drawing happens on visibility changes only
Expected Outcomes:
Live wallpaper service functional
Appears in system wallpaper picker
Renders all three layers correctly
Configuration from Flutter applied accurately
Smooth performance (no lag)
No memory leaks or crashes
Works on different screen sizes/densities
Persists after app closes
Testing Criteria:
Configure complex wallpaper (all features used)
Apply wallpaper → see in picker
Set as wallpaper → renders correctly on home screen
Lock/unlock device → wallpaper persists
Restart device → wallpaper still there
Change to different wallpaper → service stops cleanly
Return to depth wallpaper → loads config correctly
Test on different devices (resolutions, Android versions)
User Experience Flow:
text
User completes customization in Studio
 → Taps checkmark (apply) button
 → Config saved message appears
 → System wallpaper picker opens
 → "Depth Wallpaper" appears in list with thumbnail
 → User taps it
 → Preview shows full configured wallpaper
 → User taps "Set wallpaper"
 → Returns to home screen
 → Wallpaper displays with depth effect
 → Subject appears in front of clock
 → User satisfied, closes Flutter app
 → Wallpaper persists independently
Key Files to Create:
android/.../DepthWallpaperService.kt - Main service
android/.../WallpaperConfig.kt - Config data class
android/.../BitmapLoader.kt - Image optimization helper
android/.../MainActivity.kt - Add MethodChannel handler
android/app/src/main/res/xml/wallpaper.xml - Service metadata
Updated android/app/src/main/AndroidManifest.xml - Service declaration
No New Dependencies
Uses existing MethodChannel
Critical Notes for AI Agent:
WallpaperService runs in separate process from Flutter
Cannot use Flutter UI widgets in WallpaperService
All rendering is native Android Canvas
Config must persist across app restarts (SharedPreferences)
Image paths must be accessible from WallpaperService context
Time shown is current time but doesn't update yet (static render)
Thorough testing on real device essential (emulator limitations)
Different Android versions may have subtle rendering differences
Always provide fallback for missing resources
Performance critical: test on low-end devices (2GB RAM)
 MODULE 9: Live Time Updates
Objective:
Implement automatic time updates in the WallpaperService so the clock displays real-time and updates every
minute, with proper lifecycle management to conserve battery.
Detailed Requirements:
9.1 Update Mechanism Design
Purpose:
Clock should refresh every minute to show current time without user intervention
Core Approach:
Use Android Handler + Runnable pattern
Post delayed update every 60 seconds (60000 milliseconds)
Only run updates when wallpaper visible
Stop updates when invisible (screen off, different wallpaper, etc.)
Why Not Animation Loop:
Animation loop runs every frame (60fps) - wasteful
Clock only needs update every minute
Handler.postDelayed is battery-efficient
System wakes up once per minute, not continuously
9.2 Handler Implementation
Add to DepthWallpaperEngine:
Class Variables:
Kotlin
inner class DepthWallpaperEngine : Engine() {
 // ... existing variables
 private val handler = Handler(Looper.getMainLooper())
 private var isVisible = false
 private val updateRunnable = object : Runnable {
 override fun run() {
 // Redraw wallpaper with current time
 drawWallpaper()
 // Schedule next update in 60 seconds
 if (isVisible) {
 handler.postDelayed(this, 60000)
 }
 }
 }
}
Runnable Explanation:
object : Runnable creates anonymous Runnable instance
run() contains update logic
Redraws wallpaper (which gets current time)
Reschedules itself after 60 seconds
Only reschedules if wallpaper is visible
9.3 Visibility Lifecycle Management
Override onVisibilityChanged:
Kotlin
override fun onVisibilityChanged(visible: Boolean) {
 super.onVisibilityChanged(visible)
 isVisible = visible
 if (visible) {
 // Wallpaper became visible - start updates
 handler.post(updateRunnable)
 } else {
 // Wallpaper hidden - stop updates
 handler.removeCallbacks(updateRunnable)
 }
}
When Visibility Changes:
Visible = true:
User viewing home screen with this wallpaper
Screen is on
Wallpaper is active (not replaced)
Visible = false:
Screen turned off (lock screen)
User switched to different wallpaper
Device sleeping
App drawer opened (overlays wallpaper)
Battery Optimization:
Stopping updates when invisible crucial for battery life
Avoids unnecessary CPU wake-ups
Only draws when actually displayed
9.4 Initial Update Trigger
Modify onSurfaceChanged:
Kotlin
override fun onSurfaceChanged(
 holder: SurfaceHolder,
 format: Int,
 width: Int,
 height: Int
) {
 super.onSurfaceChanged(holder, format, width, height)
 canvasWidth = width
 canvasHeight = height
 // Initial draw
 drawWallpaper()
 // Start update loop if visible
 if (isVisible) {
 handler.post(updateRunnable)
 }
}
Why Here:
Surface ready for first draw
Dimensions known
Triggers initial render + starts update cycle
9.5 Cleanup on Destroy
Update onDestroy:
Kotlin
override fun onDestroy() {
 super.onDestroy()
 // Stop all scheduled updates
 handler.removeCallbacks(updateRunnable)
 // Cleanup bitmaps
 backgroundBitmap?.recycle()
 foregroundBitmap?.recycle()
}
Importance:
Prevents memory leaks
Removes pending Runnable from message queue
Essential for proper resource cleanup
Handler holds reference to Engine - must clear
9.6 Precise Timing Optimization
Problem:
postDelayed(60000) starts timer from now
If current time 10:30:37, next update at 10:31:37 (not 10:31:00)
Clock appears to skip seconds
Solution - Sync to Minute Boundary:
Kotlin
private fun scheduleNextUpdate() {
 // Get current time
 val now = Calendar.getInstance()
 val seconds = now.get(Calendar.SECOND)
 val milliseconds = now.get(Calendar.MILLISECOND)
 // Calculate delay to next minute boundary
 val delayToNextMinute = (60 - seconds) * 1000 - milliseconds
 // Schedule update at next minute
 handler.postDelayed(updateRunnable, delayToNextMinute.toLong())
}
Enhanced Runnable:
Kotlin
private val updateRunnable = object : Runnable {
 override fun run() {
 drawWallpaper()
 if (isVisible) {
 scheduleNextUpdate() // Use precise scheduling
 }
 }
}
Benefit:
Clock updates exactly at minute change (10:31:00, not 10:31:37)
Feels more accurate and responsive
No perceived drift
9.7 Update on Screen Wake
Override onVisibilityChanged Enhancement:
Kotlin
override fun onVisibilityChanged(visible: Boolean) {
 super.onVisibilityChanged(visible)
 isVisible = visible
 if (visible) {
 // Draw immediately (show current time right away)
 drawWallpaper()
 // Schedule next update
 scheduleNextUpdate()
 } else {
 handler.removeCallbacks(updateRunnable)
 }
}
Why Immediate Draw:
User wakes device, expects to see current time
Without immediate draw, shows stale time until next scheduled update
Better UX - instant feedback
9.8 Testing Time Updates
Manual Testing:
Set wallpaper
Note current time (e.g., 10:30)
Wait until next minute (10:31)
Verify clock updates to 10:31
Lock screen (turn off display)
Wait 2 minutes
Unlock screen
Verify clock shows current time (not frozen)
Automated Testing (ADB Commands):
Bash
# Watch logcat for update events
adb logcat | grep "WallpaperUpdate"
# Simulate screen on/off
adb shell input keyevent KEYCODE_POWER
# Change system time (testing only)
adb shell su -c "date 123123302024.00"
Logging for Debug:
Kotlin
private val updateRunnable = object : Runnable {
 override fun run() {
 Log.d("DepthWallpaper", "Updating time: ${getCurrentTime()}")
 drawWallpaper()
 if (isVisible) {
 scheduleNextUpdate()
 }
 }
}
9.9 Edge Cases & Error Handling
Case 1: Rapid Visibility Changes
User quickly locks/unlocks screen
Multiple updates scheduled
Solution: removeCallbacks before posting new one
Case 2: System Time Change
User changes time zone or time manually
Updates continue at old schedule
Solution: Acceptable (updates at next scheduled interval)
Enhancement: Listen to TIME_CHANGED broadcast (optional)
Case 3: Long Sleep
Device asleep for hours
Wallpaper invisible
No updates during sleep
On wake: immediate draw shows correct time
Works correctly without modification
Case 4: Wallpaper Replaced Mid-Update
User changes wallpaper while update scheduled
onDestroy called
removeCallbacks prevents orphaned Runnable
No memory leak
9.10 Battery Impact Analysis
Measurement:
Baseline: Static wallpaper (Module 8) - minimal impact
With updates: Wake up once per minute
CPU usage: <1% (brief draw operation)
Battery drain: ~1-2% per 8 hours (negligible)
Optimization Achieved:
Updates only when visible
No continuous polling
Efficient canvas redraw (cached bitmaps)
Handler more efficient than AlarmManager for short intervals
9.11 Seconds Display (Optional)
If Clock Format Includes Seconds (HH:MM:SS):
Need more frequent updates:
Kotlin
private fun getUpdateInterval(): Long {
 return if (config.clockFormat.contains("SS")) {
 1000 // Update every second
 } else {
 60000 // Update every minute
 }
}
private val updateRunnable = object : Runnable {
 override fun run() {
 drawWallpaper()
 if (isVisible) {
 handler.postDelayed(this, getUpdateInterval())
 }
 }
}
Battery Trade-off:
Seconds format = 60× more updates
Higher battery usage (still minimal)
User choice - offer warning in UI
9.12 Integration with Existing Code
No Changes to Drawing Logic:
getCurrentTime() already gets current time
drawWallpaper() already redraws clock
Only changes: when to call drawWallpaper()
No Flutter Changes:
Updates happen entirely in Kotlin
Flutter app can be closed
Wallpaper updates independently
9.13 Testing Checklist
Functional Tests:
 Clock updates every minute
 Updates stop when screen off
 Updates resume when screen on
 Time displayed is accurate
 Updates synchronized to minute boundary
 No visible lag or stuttering
 Seconds format updates every second (if implemented)
Battery Tests:
 Monitor battery drain over 8 hours
 Verify CPU usage minimal (<1%)
 Check wake locks (should be none)
 Compare to static wallpaper baseline
Stability Tests:
 Run for 24 hours - no crashes
 Lock/unlock rapidly 100 times - stable
 Change wallpaper multiple times - no memory leak
 Force close app - wallpaper continues updating
Expected Outcomes:
Clock shows current time always
Updates automatically every minute
No manual refresh needed
Battery impact negligible (<2% per day)
Updates stop when screen off (battery saving)
Immediate update on screen wake
No memory leaks or crashes
Smooth operation over days/weeks
Testing Criteria:
Set wallpaper at 10:30 → see 10:30
Wait until 10:31 → clock changes to 10:31
Lock screen, wait 5 minutes → unlock → shows 10:36 (current time)
Keep screen on for 10 minutes → clock updates every minute
Battery drain test: <5% over 24 hours
Memory profiler: no growing memory usage
Logcat: no error messages related to updates
User Experience:
text
User sets wallpaper at 2:30 PM
 → Clock shows 2:30
 → User uses phone normally
 → At 2:31 PM, clock automatically updates
 → User locks phone at 2:35 PM
 → Phone sleeping (updates stopped)
 → User unlocks at 3:15 PM
 → Clock immediately shows 3:15 (not frozen at 2:35)
 → Updates continue every minute
 → User satisfied - "just works"
Key Files to Modify:
android/.../DepthWallpaperService.kt - Add Handler, Runnable, lifecycle methods
No New Dependencies
Uses Android's built-in Handler/Looper system
Critical Notes for AI Agent:
Handler must be on main looper (UI thread)
Always removeCallbacks in onDestroy (memory leak prevention)
postDelayed doesn't guarantee exact timing (close enough for clock)
Visibility management crucial for battery life
Test on real device with screen on/off cycles
Consider seconds format battery impact (warn user)
Handler holds strong reference to Runnable - must clear
Immediate draw on visibility change improves UX significantly
  MODULE 10: Date Widget & Advanced Features
Objective:
Add optional date display below/beside clock with full customization options, plus implement remaining 
advanced features like date settings and visual polish.
Detailed Requirements:
10.1 Date Tab Layout
Create DateTab widget:
Layout Structure:
text
ListView (scrollable, 16dp padding)
 ├── Display Date Toggle
 │ └── SwitchListTile
 │
 ├── Spacer (24dp)
 │
 ├── Font Size Slider
 │ (same style as Basics tab)
 │
 ├── Spacer (24dp)
 │
 ├── Horizontal Position Slider
 │
 ├── Spacer (24dp)
 │
 └── Vertical Position Slider
10.2 Date Display Toggle
Purpose:
User chooses whether to show date widget
UI Component:
text
SwitchListTile
- Title: "Show Date"
- Active color: Yellow (#FFD700)
- Default: false (off)
Config Property:
text
Add to WallpaperConfig:
- showDate: bool (default false)
Behavior:
When enabled: date widget appears in preview
When disabled: date hidden, other settings inactive (grayed out)
Can be toggled on/off anytime
10.3 Date Positioning Controls
Same Slider Design as Clock (Module 5):
Font Size Slider:
Range: 0.01 to 0.1 (1% to 10% of screen width)
Initial: 0.034 (3.4%)
Display: Percentage "3.4%"
Note: Date text smaller than clock
Horizontal Position Slider:
Range: 0.0 to 1.0
Initial: 0.78 (78% from left)
Right-aligned positioning
Vertical Position Slider:
Range: 0.0 to 1.0
Initial: 0.11 (11% from top)
Below clock typically
Config Properties:
text
Add to WallpaperConfig:
- dateFontSize: double (default 0.034)
- dateHorizontalPos: double (default 0.78)
- dateVerticalPos: double (default 0.11)
10.4 Date Settings Tab Layout
Create DateSettingsTab widget:
Layout Structure:
text
ListView (scrollable, 16dp padding)
 ├── Font Color Section
 │ ├── Section label: "Font Color"
 │ └── Color picker (same as Typography tab)
 │
 ├── Spacer (24dp)
 │
 ├── Date Format Section (Optional)
 │ ├── Section label: "Date Format"
 │ └── Chip selector (formats)
 │
 ├── Spacer (24dp)
 │
 └── Text Style Section
 ├── All Caps Toggle (SwitchListTile)
 └── Bold Toggle (SwitchListTile)
10.5 Date Color Picker
Purpose:
Set date text color independently from clock
Implementation:
Reuse ColorPickerWidget from Module 6
Same 8 predefined colors
Separate from clock color
Config Property:
text
Add to WallpaperConfig:
- dateColor: Color (default Colors.white)
10.6 Date Format Options
Purpose:
Choose date display format
Format Choices:
"EEE, MMM dd" → "Mon, Jan 15"
"MMM dd, yyyy" → "Jan 15, 2024"
"dd/MM/yyyy" → "15/01/2024"
"MM-dd-yyyy" → "01-15-2024"
"EEEE, MMMM dd" → "Monday, January 15"
Config Property:
text
Add to WallpaperConfig:
- dateFormat: String (default "EEE, MMM dd")
UI Component:
ChoiceChip selector (same style as clock format)
Horizontal wrap layout
10.7 Text Style Controls
All Caps Toggle:
text
SwitchListTile
- Title: "All Caps"
- Active color: Yellow
- Default: true
Effect:
When enabled: "MON, JAN 15"
When disabled: "Mon, Jan 15"
Bold Toggle:
text
SwitchListTile
- Title: "Bold Text"
- Active color: Yellow
- Default: false
Effect:
When enabled: FontWeight.bold
When disabled: FontWeight.normal
Config Properties:
text
Add to WallpaperConfig:
- dateAllCaps: bool (default true)
- dateBold: bool (default false)
10.8 Preview Integration
Update WallpaperPreview Widget:
Add date layer to Stack (after foreground):
text
Stack(
 children: [
 // Layer 1: Background
 // Layer 2: Clock
 // Layer 3: Foreground
 // Layer 4: Date (if enabled)
 if (config.showDate)
 Positioned(
 left: config.dateHorizontalPos * constraints.maxWidth,
 top: config.dateVerticalPos * constraints.maxHeight,
 child: Text(
 getFormattedDate(config.dateFormat, config.dateAllCaps),
 style: TextStyle(
 fontSize: config.dateFontSize * constraints.maxWidth,
 color: config.dateColor,
 fontWeight: config.dateBold ? FontWeight.bold : FontWeight.normal,
 ),
 ),
 ),
 ]
)
Date Formatting Method:
dart
String getFormattedDate(String format, bool allCaps) {
 final now = DateTime.now();
 final formatter = DateFormat(format);
 String dateText = formatter.format(now);
 return allCaps ? dateText.toUpperCase() : dateText;
}
Layer Order Note:
Date renders AFTER foreground (on top)
Not subject to depth effect
Always visible (not occluded by subject)
Design choice: date as UI element, not part of depth scene
10.9 Kotlin WallpaperService Updates
Add Date Drawing to drawWallpaper():
Kotlin
private fun drawWallpaper() {
 val canvas = surfaceHolder.lockCanvas() ?: return
 try {
 drawBackground(canvas)
 drawClock(canvas)
 drawForeground(canvas)
 // Add date drawing
 if (config.showDate) {
 drawDate(canvas)
 }
 } finally {
 surfaceHolder.unlockCanvasAndPost(canvas)
 }
}
Date Drawing Method:
Kotlin
private fun drawDate(canvas: Canvas) {
 val datePaint = Paint().apply {
 color = config.dateColor
 textSize = config.dateFontSize * canvas.width
 isAntiAlias = true
 typeface = if (config.dateBold) {
 Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
 } else {
 Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
 }
 }
 val dateText = getFormattedDate()
 val x = config.dateHorizontalPos * canvas.width
 val y = config.dateVerticalPos * canvas.height
 canvas.drawText(dateText, x, y, datePaint)
}
Date Formatting in Kotlin:
Kotlin
private fun getFormattedDate(): String {
 val pattern = when (config.dateFormat) {
 "MMM dd, yyyy" -> "MMM dd, yyyy"
 "dd/MM/yyyy" -> "dd/MM/yyyy"
 "MM-dd-yyyy" -> "MM-dd-yyyy"
 "EEEE, MMMM dd" -> "EEEE, MMMM dd"
 else -> "EEE, MMM dd" // Default
 }
 val sdf = SimpleDateFormat(pattern, Locale.getDefault())
 var dateText = sdf.format(Date())
 if (config.dateAllCaps) {
 dateText = dateText.uppercase()
 }
 return dateText
}
10.10 Date Update Schedule
Problem:
Date only changes once per day (at midnight)
Current update: every minute (wasteful)
Solution - Midnight Update:
Kotlin
private fun scheduleNextUpdate() {
 val now = Calendar.getInstance()
 // Schedule for time update (every minute)
 val delayToNextMinute = calculateMinuteDelay(now)
 handler.postDelayed(updateRunnable, delayToNextMinute)
 // If showing date, also schedule midnight update
 if (config.showDate) {
 val delayToMidnight = calculateMidnightDelay(now)
 handler.postDelayed(midnightRunnable, delayToMidnight)
 }
}
private fun calculateMidnightDelay(now: Calendar): Long {
 val tomorrow = Calendar.getInstance().apply {
 add(Calendar.DAY_OF_MONTH, 1)
 set(Calendar.HOUR_OF_DAY, 0)
 set(Calendar.MINUTE, 0)
 set(Calendar.SECOND, 0)
 set(Calendar.MILLISECOND, 0)
 }
 return tomorrow.timeInMillis - now.timeInMillis
}
private val midnightRunnable = Runnable {
 drawWallpaper() // Redraw with new date
 // Schedule next midnight update
 if (isVisible && config.showDate) {
 handler.postDelayed(this, 24 * 60 * 60 * 1000L) // 24 hours
 }
}
Cleanup in onDestroy:
Kotlin
override fun onDestroy() {
 super.onDestroy()
 handler.removeCallbacks(updateRunnable)
 handler.removeCallbacks(midnightRunnable)
 // ... rest of cleanup
}
10.11 Advanced Features
Feature 1: Secondary Color Gradient (Optional)
Purpose:
Use secondary color for gradient effect on clock
Implementation (Kotlin):
Kotlin
private fun createGradientPaint(): Paint {
 val paint = Paint().apply {
 textSize = config.fontSize * canvasWidth
 isAntiAlias = true
 if (config.secondaryColor != null) {
 shader = LinearGradient(
 0f, 0f,
 textSize, 0f,
 config.fontColor,
 config.secondaryColor!!,
 Shader.TileMode.CLAMP
 )
 } else {
 color = config.fontColor
 }
 }
 return paint
}
Feature 2: Depth Layering Modes (Implemented Now)
Recall from Module 6: Hours Forward, Minutes Forward
Implementation:
Kotlin
private fun drawClock(canvas: Canvas) {
 val time = getCurrentTime()
 when (config.depthMode) {
 "Standard" -> {
 // Draw entire clock before foreground
 drawCompleteTime(canvas, time)
 }
 "Hours Forward" -> {
 // Draw minutes
 drawMinutesOnly(canvas, time)
 // Then in separate method after foreground:
 // drawHoursOnly(canvas, time)
 }
 "Minutes Forward" -> {
 // Draw hours
 drawHoursOnly(canvas, time)
 // Then after foreground:
 // drawMinutesOnly(canvas, time)
 }
 }
}
private fun drawMinutesOnly(canvas: Canvas, time: String) {
 // Parse time, extract minutes (e.g., "30" from "14:30")
 val minutes = time.split(":").getOrNull(1) ?: return
 // Draw only minutes at adjusted position
}
private fun drawHoursOnly(canvas: Canvas, time: String) {
 // Parse time, extract hours
 val hours = time.split(":").getOrNull(0) ?: return
 // Draw only hours
}
Drawing Order for "Hours Forward":
Kotlin
private fun drawWallpaper() {
 canvas.lock()
 drawBackground()
 drawMinutesOnly() // Behind foreground
 drawForeground()
 drawHoursOnly() // In front of foreground
 drawDate() // Always on top
 canvas.unlock()
}
10.12 Tab Navigation Update
Add Date Tab to Studio Screen:
Update TabController:
dart
_tabController = TabController(length: 6, vsync: this); // Was 5, now 6
Update TabBar:
dart
TabBar(
 controller: _tabController,
 tabs: [
 Tab(text: 'Basics'),
 Tab(text: 'Typography'),
 Tab(text: 'Effects'),
 Tab(text: 'Transform'),
 Tab(text: 'Date'),
 Tab(text: 'Date Settings'),
 ],
)
Update TabBarView:
dart
TabBarView(
 controller: _tabController,
 children: [
 BasicsTab(...),
 TypographyTab(...),
 EffectsTab(...),
 TransformTab(...),
 DateTab(...), // New
 DateSettingsTab(...), // New
 ],
)
10.13 Config Persistence
Add to MethodChannel saveConfig:
dart
await platform.invokeMethod('saveConfig', {
 // ... existing config
 'showDate': wallpaperConfig.showDate,
 'dateFontSize': wallpaperConfig.dateFontSize,
 'dateHorizontalPos': wallpaperConfig.dateHorizontalPos,
 'dateVerticalPos': wallpaperConfig.dateVerticalPos,
 'dateColor': wallpaperConfig.dateColor.value,
 'dateFormat': wallpaperConfig.dateFormat,
 'dateAllCaps': wallpaperConfig.dateAllCaps,
 'dateBold': wallpaperConfig.dateBold,
});
SharedPreferences in Kotlin:
Kotlin
putBoolean("showDate", config["showDate"] as Boolean)
putFloat("dateFontSize", (config["dateFontSize"] as Double).toFloat())
putFloat("dateHorizontalPos", (config["dateHorizontalPos"] as Double).toFloat())
putFloat("dateVerticalPos", (config["dateVerticalPos"] as Double).toFloat())
putInt("dateColor", config["dateColor"] as Int)
putString("dateFormat", config["dateFormat"] as String)
putBoolean("dateAllCaps", config["dateAllCaps"] as Boolean)
putBoolean("dateBold", config["dateBold"] as Boolean)
Expected Outcomes:
Date widget fully functional
Toggle on/off working
Customizable size, position, color
Multiple format options
All caps/bold styling
Updates at midnight automatically
Depth layering modes working
Gradient effect (if secondary color set)
Preview shows all features
Wallpaper renders correctly
Testing Criteria:
Enable date → appears in preview
Disable date → disappears
Adjust date position → moves correctly
Change date color → updates
Select format → displays in that format
All caps on → uppercase date
Bold toggle → weight changes
Apply wallpaper → date shows on home screen
Wait until midnight → date updates to next day
Hours Forward mode → hours appear above foreground
User Experience Flow:
text
User switches to Date tab
 → Enables "Show Date" toggle
 → Date appears in preview: "MON, JAN 15"
 → Adjusts position below clock
 → Makes text smaller (3%)
User switches to Date Settings tab
 → Changes color to yellow
 → Selects format "Jan 15, 2024"
 → Disables all caps
 → Preview shows: "Jan 15, 2024" in yellow, normal case
User applies wallpaper
 → Home screen shows clock + date
 → Next day at midnight: date automatically updates
Key Files to Create:
widgets/date_tab.dart - Date positioning controls
widgets/date_settings_tab.dart - Date styling controls
Updated models/wallpaper_config.dart - Add 8 date properties
Updated widgets/wallpaper_preview.dart - Render date layer
Updated android/.../DepthWallpaperService.kt - Date drawing + midnight updates
Dependencies:
YAML
intl: ^0.18.1 # For DateFormat in Flutter
Critical Notes for AI Agent:
Date layer renders AFTER foreground (always visible, not depth effect)
Midnight update prevents wasteful minute-by-minute updates when date doesn't change
Date format patterns must match between Dart (DateFormat) and Kotlin (SimpleDateFormat)
All caps transformation happens after formatting
Depth layering mode requires sketching clock into hours/minutes components
Secondary color gradient optional (null check required)
Date and clock can have different colors/sizes (independent styling)
Test midnight update by manually changing system time
 MODULE 11: Project Management & Polish - Detailed Explanation
 MODULE OVERVIEW
Purpose: Transform app from single-use tool to full project management system with professional UI/UX 
polish
Current State (After Module 10):
User can create ONE wallpaper
No way to save/load multiple designs
No history or project organization
Basic UI without animations
Target State (After Module 11):
Multiple saved projects with thumbnails
Edit/Delete/Duplicate functionality
Smooth animations throughout
Professional error handling
First-launch onboarding
Settings screen
 SUB-MODULE 11.1: Local Database Architecture
What You're Building:
A persistent storage system to save multiple wallpaper projects
Why It Matters:
Users want to experiment with different designs
Need to switch between wallpapers easily
Preserve work without re-creating from scratch
Technical Approach:
Option A: Hive (Recommended)
Pros:
 Pure Dart (no platform channels)
 Fast (NoSQL key-value store)
 Type-safe with code generation
 Small footprint
Cons:
 Less flexible for complex queries
 Manual relationship management
Option B: SQLite (sqflite)
Pros:
 Relational database (good for complex queries)
 Industry standard
 Better for large datasets
Cons:
 More boilerplate code
 Requires SQL knowledge
Data Models You'll Create:
1. WallpaperProject
text
Fields:
- id (String) - Unique identifier (UUID)
- name (String) - User-given name or auto "Wallpaper 1"
- createdAt (DateTime) - When project was created
- modifiedAt (DateTime) - Last edit timestamp
- thumbnailPath (String) - Path to preview image
- isActive (bool) - Currently set as wallpaper
- originalImagePath (String) - User's uploaded photo
- backgroundImagePath (String) - Processed background
- foregroundImagePath (String) - Segmented subject
- configJson (String) - Serialized WallpaperConfig
2. AppSettings
text
Fields:
- qualityPreset (String) - "high", "balanced", "battery_saver"
- updateFrequency (int) - Minutes between clock updates
- showOnboardingAgain (bool) - Reset tutorial flag
- lastBackupDate (DateTime) - Last export timestamp
Database Operations You'll Implement:
CREATE:
text
When user completes Studio editing:
1. Generate UUID
2. Save thumbnail (render preview as PNG)
3. Serialize WallpaperConfig to JSON
4. Insert into database
5. Navigate back to home
READ:
text
On Home Screen load:
1. Query all projects
2. Sort by modifiedAt (newest first)
3. Display as grid/list
4. Highlight active project
UPDATE:
text
When user edits existing project:
1. Load project by ID
2. User makes changes in Studio
3. Update modifiedAt timestamp
4. Save updated config
5. Regenerate thumbnail if visual changes
DELETE:
text
When user deletes project:
1. Show confirmation dialog
2. If confirmed:
 - Delete from database
 - Delete associated files (images, thumbnail)
 - If was active, clear active flag
3. Refresh home screen list
 SUB-MODULE 11.2: Home Screen Redesign
What You're Building:
Professional project management interface replacing the empty home screen
Layout Components:
A. Header Section
text
┌─────────────────────────────────────┐
│ Depth Wallpaper [ Settings] │
│ │
│ My Wallpapers (5) [Sort▼] │
└─────────────────────────────────────┘
Features:
App title/logo
Settings gear icon (top-right)
Project count
Sort dropdown (by date, name, recently used)
B. Quick Action Cards
text
┌─────────────────────────────────────┐
│ ┌──────────────┐ ┌──────────────┐│
│ │ + CREATE │ │ IMPORT ││
│ │ NEW │ │ PROJECT ││
│ └──────────────┘ └──────────────┘│
└─────────────────────────────────────┘
Features:
Prominent "Create New" button (same as FAB)
Import button for restoring backed-up projects
C. Project Grid/List
text
Grid View:
┌─────┬─────┬─────┐
│ IMG │ IMG │ IMG │
│12:30│12:30│12:30│
│ │ │ │ ← 3-dot menu
└─────┴─────┴─────┘
List View:
┌─────────────────────────────────────┐
│ [IMG] Project Name │
│ Modified: 2 hours ago │
│ Active │
└─────────────────────────────────────┘
Grid Item Components:
Thumbnail Image (aspect ratio 9:19.5)
Clock Preview (current time rendered)
Active Indicator (badge/border)
3-dot Menu (edit, duplicate, delete, share)
D. Empty State
text
When no projects:
┌─────────────────────────────────────┐
│ │
│ [Large Icon] │
│ │
│ No Wallpapers Yet │
│ Create your first depth │
│ wallpaper to get started │
│ │
│ [+ Create Wallpaper] │
│ │
└─────────────────────────────────────┘
Interaction Flows:
Tap Project Card:
Opens preview dialog
Shows "Set as Wallpaper" and "Edit" buttons
Long-press Card:
Enters selection mode
Allows multi-select for batch delete
3-dot Menu:
text
Options:
- Edit
- Set as Wallpaper
- Duplicate
- Share (export as image/config)
- Delete
 SUB-MODULE 11.3: UI Animations & Transitions
What You're Building:
Smooth, professional animations that guide user attention
Animation Categories:
A. Navigation Transitions
1. Home → Studio (Hero Animation)
text
Concept:
- Project thumbnail smoothly expands into Studio preview
- Creates visual continuity
Implementation approach:
- Wrap thumbnail in Hero widget with unique tag
- Match tag in Studio preview
- Flutter handles morphing automatically
2. Studio → Preview (Slide Up)
text
Concept:
- Full-screen preview slides up from bottom
- Dismissible by dragging down
Implementation approach:
- Use PageRouteBuilder with SlideTransition
- Add DraggableScrollableSheet for dismiss gesture
B. List Animations
1. Staggered Grid Entrance
text
Concept:
- Project cards appear one-by-one with slight delay
- Creates polished loading experience
Implementation approach:
- Use AnimationController with staggered delays
- FadeTransition + SlideTransition combination
- Each item delays by index * 50ms
2. Delete Animation
text
Concept:
- Card scales down while fading out
- Other cards smoothly reposition
Implementation approach:
- AnimatedList for insertions/deletions
- SizeTransition + FadeTransition
- Duration: 300ms
C. Interactive Feedback
1. Slider Value Changes
text
Concept:
- Preview updates smoothly, not instantly
- Percentage display animates numerically
Implementation approach:
- TweenAnimationBuilder for value changes
- Duration: 200ms
- Cubic ease curve
2. Tab Switches
text
Concept:
- Content fades out → new content fades in
- Indicator slides smoothly
Implementation approach:
- AnimatedSwitcher for content
- Duration: 300ms
- Custom SlideTransition for indicator
3. Button Press States
text
Concept:
- Subtle scale effect on tap
- Color change on hold
Implementation approach:
- GestureDetector with onTapDown/onTapUp
- AnimatedContainer for smooth scaling
- InkWell for material ripple effect
D. Loading States
1. Image Processing Overlay
text
Concept:
- Full-screen dimmed overlay
- Spinner with progress text
- Optional percentage if ML Kit provides progress
Visual:
┌─────────────────────────────────────┐
│ [Black overlay 80%] │
│ │
│ Processing... │
│ Detecting subject │
│ ▬▬▬▬▬▬▬░░░░ 60% │
│ │
└─────────────────────────────────────┘
2. Shimmer Placeholders
text
Concept:
- While loading project list, show shimmer skeletons
- Indicates loading without blocking UI
Implementation approach:
- Use shimmer package
- Create placeholder cards matching real card size
- Replace with actual content when loaded
 SUB-MODULE 11.4: Settings Screen
What You're Building:
Configuration hub for app-wide preferences
Settings Categories:
A. Performance Settings
text
Section Header: "Performance"
Quality Preset [Radio Buttons]:
○ High Quality
 - 4K wallpaper rendering
 - Higher battery usage
● Balanced (Default)
 - 1080p rendering
 - Moderate battery
○ Battery Saver
 - 720p rendering
 - Minimal updates
Technical Implementation:
Affects bitmap resolution in ML Kit
Changes canvas rendering size in WallpaperService
Adjusts update frequency
B. Update Behavior
text
Section Header: "Clock Updates"
 Update Every Minute
 When enabled: Clock redraws every 60s
 When disabled: Only updates on screen wake
 Update on Screen Wake
 Always refresh when screen turns on
Time Format [Dropdown]:
▼ 24-hour
 12-hour (AM/PM)
C. Display Options
text
Section Header: "Display"
 Lock Screen Only
 If checked: Only show depth effect on lock screen
 Home screen uses standard wallpaper
 Show Grid in Preview
 Overlay 3×3 grid for positioning assistance
 Show FPS Counter (Debug)
 Display rendering performance
D. Data Management
text
Section Header: "Data & Storage"
Cache Size: 124 MB [Clear Cache]
Projects: 5 [View All]
[Export All Projects]
 → Opens share sheet with .zip file
[Import Projects]
 → File picker for .zip restore
[Reset All Settings]
 → Confirmation dialog → restore defaults
E. About & Legal
text
Section Header: "About"
Version: 1.0.0 (Build 42)
[Privacy Policy]
[Terms of Service]
[Open Source Licenses]
[Rate on Play Store]
[Contact Support]
Made with in [Your Location]
Settings Persistence:
text
Storage mechanism:
- Use SharedPreferences for simple key-value pairs
- Load on app start
- Apply throughout app lifecycle
Example keys:
- quality_preset: "balanced"
- update_every_minute: true
- use_24hour: true
- show_grid: false
 SUB-MODULE 11.5: Onboarding Flow
What You're Building:
First-time user experience explaining app features
Screen Sequence:
Screen 1: Welcome
text
┌─────────────────────────────────────┐
│ │
│ [Animated App Logo] │
│ │
│ Create iOS-Style Wallpapers │
│ on Android │
│ │
│ Transform your photos into │
│ stunning depth effect wallpapers │
│ │
│ [Get Started →] │
│ │
└─────────────────────────────────────┘
Animation: Logo fades in with scale effect
Screen 2: Feature Highlights (PageView)
text
Page 1/3:
┌─────────────────────────────────────┐
│ [Illustration: Photo upload] │
│ │
│ Select Any Photo │
│ │
│ Choose from your gallery or │
│ take a new photo │
│ │
│ ● ○ ○ [Next] │
└─────────────────────────────────────┘
Page 2/3:
┌─────────────────────────────────────┐
│ [Illustration: AI magic] │
│ │
│ AI-Powered Detection │
│ │
│ Our smart algorithm automatically │
│ isolates the subject │
│ │
│ ○ ● ○ [Next] │
└─────────────────────────────────────┘
Page 3/3:
┌─────────────────────────────────────┐
│ [Illustration: Depth effect] │
│ │
│ Customize Everything │
│ │
│ Style your clock with fonts, │
│ colors, effects & more │
│ │
│ ○ ○ ● [Finish] │
└─────────────────────────────────────┘
Interaction:
Swipeable pages
Dot indicators show progress
Skip button in top-right (all screens)
Screen 3: Permissions Request
text
┌─────────────────────────────────────┐
│ We Need Your Permission │
│ │
│ Photo Access │
│ Required to select wallpaper │
│ images from your gallery │
│ │
│ Live Wallpaper │
│ Required to display your │
│ creations on your screen │
│ │
│ [Grant Permissions] │
│ [I'll do this later] │
│ │
└─────────────────────────────────────┘
Flow:
Tap "Grant Permissions"
System permission dialogs appear
If granted → Navigate to Home
If denied → Show warning, still allow entry
Screen 4: Quick Tutorial (Optional)
text
Interactive overlay on first Studio visit:
Step 1: Highlights image picker button
 "Tap here to select a photo"
 [Tooltip with arrow pointing to button]
Step 2: After image selected
 "Great! Now AI will detect the subject"
 [Overlay on preview area]
Step 3: After processing
 "Adjust the clock position and style"
 [Highlights slider controls]
Step 4: Final step
 "Tap here when ready to apply"
 [Highlights checkmark button]
Implementation Strategy:
Use Showcaseview or Tutorial Coach Mark package
Store completion in SharedPreferences
"Don't show again" checkbox
 SUB-MODULE 11.6: Error Handling & Edge Cases
What You're Building:
Robust error management for graceful failures
Error Scenarios & Solutions:
A. Image Processing Errors
1. ML Kit Returns No Subject
text
User Impact:
- Processing completes but foreground is empty
Solution:
┌─────────────────────────────────────┐
│ No Subject Detected │
│ │
│ We couldn't find a clear subject │
│ in this photo. │
│ │
│ [Try Another Photo] │
│ [Continue Anyway] │
│ [Manual Selection] ← Future feature│
└─────────────────────────────────────┘
Fallback behavior:
- If "Continue Anyway": Use full image as background
- Save project with warning flag
2. Image File Corrupted
text
User Impact:
- App crashes when loading saved project
Solution:
- Try-catch around file I/O
- If fails: Show error, remove project from list
- Log error for debugging
Dialog:
"This project is corrupted and can't be loaded.
Would you like to delete it?"
[Delete] [Cancel]
3. Out of Memory (Large Images)
text
User Impact:
- App crashes when loading 20MP+ images
Solution:
- Always downsample images before processing
- Set max resolution to 2048px width
- Show warning if original > 4K:
"This image is very large (8000×6000).
We'll optimize it for better performance."
[OK]
B. Wallpaper Service Errors
1. Service Fails to Start
text
User Impact:
- Wallpaper doesn't appear after applying
Solution:
- Add health check in WallpaperService onCreate
- If critical files missing, show notification:
"Wallpaper couldn't start. Tap to recreate."
Recovery:
- Notification tap → reopens Studio
- Automatically reprocess last project
2. Config Loading Fails
text
User Impact:
- Wallpaper shows with default values
Solution:
- Load default config as fallback
- Log error but don't crash
- Toast message: "Using default settings"
C. Permission Denied
1. Storage Permission Denied
text
User Impact:
- Can't select images
Solution:
When picker returns null:
┌─────────────────────────────────────┐
│ Permission Required │
│ │
│ This app needs storage access │
│ to select wallpaper images. │
│ │
│ [Open Settings] │
│ [Cancel] │
└─────────────────────────────────────┘
[Open Settings] → Launch app settings screen
2. Wallpaper Permission Denied
text
User Impact:
- Can't set as live wallpaper
Solution:
- Not a runtime permission, so educate user:
"To use live wallpapers, select this app
from the system wallpaper picker:
Settings → Wallpaper → Live Wallpapers
→ Depth Wallpaper"
[Copy Instructions] [OK]
D. Network Errors (Future: Cloud Features)
text
For cloud sync/stock images:
- Retry with exponential backoff
- Show offline mode toggle
- Cache failed requests for later
 SUB-MODULE 11.7: Advanced UI Polish
What You're Building:
Professional touches that elevate user experience
Polish Elements:
A. Haptic Feedback
text
When to vibrate:
- Slider reaches min/max value (light impact)
- Color selected (selection click)
- Delete confirmed (medium impact)
- Wallpaper applied successfully (success notification)
Implementation:
Use HapticFeedback class in Flutter
- HapticFeedback.lightImpact()
- HapticFeedback.mediumImpact()
- HapticFeedback.selectionClick()
B. Contextual Tooltips
text
Show on first interaction:
- Slider: "Drag to adjust"
- Color picker: "Tap to select color"
- Preview: "Pinch to zoom"
Auto-dismiss after 2 seconds
Store shown state to avoid repeats
C. Snackbar Notifications
text
Success messages:
 "Wallpaper created successfully"
 "Project saved"
 "Settings updated"
Error messages:
 "Failed to load image"
 "Processing interrupted"
Info messages:
ℹ "This may take a moment..."
ℹ "3 projects remaining (free limit)"
D. Loading Skeletons
text
Instead of spinners, show content placeholders:
Home screen loading:
┌────┬────┬────┐
│████│████│████│ ← Gray pulsing boxes
│░░░░│░░░░│░░░░│
└────┴────┴────┘
Studio loading:
[Large gray rectangle] ← Preview placeholder
[Gray bars] ← Control placeholders
E. Empty States
text
Every list needs an empty state:
No projects:
 [Icon] "No wallpapers yet"
 [Button] "Create your first"
No search results:
 [Icon] "No matches found"
 [Text] "Try different keywords"
No internet (future):
 [Icon] "You're offline"
 [Text] "Some features unavailable"
F. Confirmation Dialogs
text
Before destructive actions:
Delete project:
"Delete 'Sunset Wallpaper'?
This cannot be undone."
[Cancel] [Delete]
Clear cache:
"This will remove 124 MB of cached data."
[Cancel] [Clear]
Reset settings:
"All customizations will be lost."
[Cancel] [Reset]
 SUB-MODULE 11.8: Testing & Quality Assurance
What You're Testing:
A. Unit Tests
text
Test models:
- WallpaperConfig serialization/deserialization
- Project ID generation uniqueness
- File path validation
Test services:
- FileManager creates directories correctly
- Database CRUD operations work
- Config calculations (percentage to pixels)
Example test:
"WallpaperConfig should serialize to JSON correctly"
"Database should retrieve projects in correct order"
"File deletion should also remove thumbnails"
B. Widget Tests
text
Test UI components:
- Slider updates preview in real-time
- Color picker changes font color
- Tab switching preserves state
- Delete dialog appears on long-press
Example test:
"Tapping color should update preview"
"Slider drag should trigger onChanged callback"
C. Integration Tests
text
Test full user flows:
1. Upload image → ML Kit → Preview
2. Customize → Apply → Wallpaper appears
3. Save project → Exit → Reload → Project exists
4. Delete project → Confirm → Project removed
Example test:
"Complete wallpaper creation flow succeeds"
"Edited project saves changes correctly"
D. Platform Tests (Kotlin)
text
Test wallpaper service:
- Renders without crashing
- Updates time correctly
- Handles missing files gracefully
- Memory doesn't leak over time
Use Android Instrumentation tests
E. Performance Tests
text
Measure:
- App startup time (< 2 seconds)
- Image processing time (< 5 seconds for 12MP)
- Database query time (< 100ms for 50 projects)
- Preview rendering FPS (> 30fps)
Tools:
- Flutter DevTools
- Android Profiler
- Firebase Performance Monitoring
F. Device Compatibility Testing
text
Test on:
- Low-end device (2GB RAM, Android 8)
- Mid-range (4GB RAM, Android 11)
- High-end (8GB+ RAM, Android 14)
- Tablet (different aspect ratio)
- Foldable (if possible)
Edge cases:
- Notch/punch-hole screens
- Different screen densities (hdpi to xxxhdpi)
- Various Android versions (API 26-34)

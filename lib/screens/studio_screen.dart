import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/wallpaper_data.dart';
import '../models/wallpaper_config.dart';
import '../models/wallpaper_project.dart';
import '../services/file_manager.dart';
import '../services/project_repository.dart';
import '../services/segmentation_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/slide_page_route.dart';
import '../widgets/wallpaper_preview.dart';
import '../widgets/date_tab.dart';
import '../widgets/date_settings_tab.dart';
import 'preview_screen.dart';

class StudioScreen extends StatefulWidget {
  /// Pass an existing project to enter edit mode; null for new project.
  final WallpaperProject? project;
  const StudioScreen({super.key, this.project});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WallpaperData _wallpaperData;
  late WallpaperConfig _wallpaperConfig;
  bool _isLoading = false;
  bool _isSaving = false;
  String _loadingText = 'Loading image...';
  final GlobalKey _previewKey = GlobalKey();
  final _repo = ProjectRepository();
  
  static const MethodChannel _platform = MethodChannel('com.yourcompany.depthwallpaper/wallpaper');

  final List<String> _tabs = [
    'Basics',
    'Typography',
    'Effects',
    'Transform',
    'Date',
    'Date Settings',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    final p = widget.project;
    if (p != null) {
      // Edit mode: restore saved config and image paths
      _wallpaperConfig = p.config;
      _wallpaperData = WallpaperData(
        originalImagePath: p.originalImagePath,
        foregroundImagePath: p.foregroundImagePath,
      );
    } else {
      _wallpaperData = WallpaperData();
      _wallpaperConfig = WallpaperConfig();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Request storage/photos permissions depending on Android SDK version
  Future<bool> _checkAndRequestPermissions() async {
    // Determine permission type dynamically
    // Android 13+ (API 33+) uses READ_MEDIA_IMAGES (mapped to Permission.photos)
    // Android 12 and below use READ_EXTERNAL_STORAGE (mapped to Permission.storage)
    
    // First, check status of photos permission
    final statusPhotos = await Permission.photos.status;
    if (statusPhotos.isGranted) return true;

    // Check status of storage permission
    final statusStorage = await Permission.storage.status;
    if (statusStorage.isGranted) return true;

    // Request permissions
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.storage,
    ].request();

    final bool isPhotosGranted = statuses[Permission.photos] == PermissionStatus.granted;
    final bool isStorageGranted = statuses[Permission.storage] == PermissionStatus.granted;

    if (isPhotosGranted || isStorageGranted) {
      return true;
    }

    // Handle permanently denied status by showing settings dialog
    final bool isPhotosPermanentlyDenied = statuses[Permission.photos] == PermissionStatus.permanentlyDenied;
    final bool isStoragePermanentlyDenied = statuses[Permission.storage] == PermissionStatus.permanentlyDenied;

    if (isPhotosPermanentlyDenied || isStoragePermanentlyDenied) {
      _showPermissionDeniedDialog(true);
    } else {
      _showPermissionDeniedDialog(false);
    }

    return false;
  }

  // Show user-friendly explanation of why permissions are needed
  void _showPermissionDeniedDialog(bool permanentlyDenied) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Storage Access Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          permanentlyDenied
              ? 'Storage/Photos permission has been permanently denied. Please enable it in the app settings to select images from your gallery.'
              : 'Permission is needed to select a background image from your photo gallery.',
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB0B0B0))),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (permanentlyDenied)
            TextButton(
              child: const Text('Open Settings', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            )
          else
            TextButton(
              child: const Text('Try Again', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage();
              },
            ),
        ],
      ),
    );
  }

  // Handle single image picking and storage copying pipeline
  Future<void> _pickImage() async {
    // Retrieve the device's physical screen size synchronously before any async gaps
    final mediaQuery = MediaQuery.of(context);
    final double physicalWidth = mediaQuery.size.width * mediaQuery.devicePixelRatio;
    final double physicalHeight = mediaQuery.size.height * mediaQuery.devicePixelRatio;

    final double maxWidthConstraint = physicalWidth > 0 ? physicalWidth : 2048;
    final double maxHeightConstraint = physicalHeight > 0 ? physicalHeight : 2048;

    try {
      final isGranted = await _checkAndRequestPermissions();
      if (!isGranted) return;

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidthConstraint,  // Auto-configures resolution to fit the device's physical screen exactly
        maxHeight: maxHeightConstraint,
        imageQuality: 95, // High quality compression to preserve visual fidelity
      );

      if (pickedFile == null) {
        // User cancelled selection - silent return
        return;
      }

      setState(() {
        _isLoading = true;
        _loadingText = 'Loading image...';
      });

      // Copy image file to app's internal documents directory
      final savedPath = await FileManager.saveImage(pickedFile);

      if (!mounted) return;
      setState(() {
        _loadingText = 'Detecting subject...';
      });

      // Run ML Kit Subject Segmentation on the saved image path
      final maskPath = await SegmentationService.segmentSubject(savedPath);

      if (!mounted) return;
      setState(() {
        // Clean up previous files to avoid cluttering internal storage
        if (_wallpaperData.originalImagePath != null) {
          FileManager.deleteImage(_wallpaperData.originalImagePath!);
        }
        if (_wallpaperData.foregroundImagePath != null) {
          FileManager.deleteImage(_wallpaperData.foregroundImagePath!);
        }

        if (maskPath != null) {
          _wallpaperData = _wallpaperData.copyWith(
            originalImagePath: savedPath,
            foregroundImagePath: maskPath,
          );
        } else {
          // If segmentation fails, we keep the original image as background, but no foreground overlay
          _wallpaperData = _wallpaperData.copyWith(
            originalImagePath: savedPath,
            foregroundImagePath: null,
          );
        }
        _isLoading = false;
      });

      if (mounted) {
        if (maskPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject isolated and loaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showNoSubjectDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show a dialog explaining that no subject could be isolated
  void _showNoSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('No Subject Detected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'ML Kit could not detect a clear foreground subject in this photo. '
          'You can still use it as a standard wallpaper, but the depth effect will not be available. '
          'Try selecting an image with a person, animal, or prominent object.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Reset the current workspace settings and clear stored files
  Future<void> _resetSettings() async {
    if (_wallpaperData.originalImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image is currently selected.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Reset Studio', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to reset and clear the selected image?',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB0B0B0))),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _loadingText = 'Resetting...';
      });

      // Clear physical files from storage
      if (_wallpaperData.originalImagePath != null) {
        await FileManager.deleteImage(_wallpaperData.originalImagePath!);
      }
      if (_wallpaperData.foregroundImagePath != null) {
        await FileManager.deleteImage(_wallpaperData.foregroundImagePath!);
      }

      setState(() {
        _wallpaperData = _wallpaperData.clear();
        _wallpaperConfig = WallpaperConfig();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace reset completed.')),
        );
      }
    }
  }

  Future<void> _applyWallpaper() async {
    if (_wallpaperData.originalImagePath == null) return;

    setState(() {
      _isLoading = true;
      _loadingText = 'Applying wallpaper...';
    });

    try {
      await _platform.invokeMethod('saveConfig', {
        'fontSize': _wallpaperConfig.fontSize,
        'horizontalPos': _wallpaperConfig.horizontalPos,
        'verticalPos': _wallpaperConfig.verticalPos,
        'fontColor': _wallpaperConfig.fontColor.toARGB32(),
        'clockFormat': _wallpaperConfig.clockFormat,
        'fontFamily': _wallpaperConfig.fontFamily,
        'letterSpacing': _wallpaperConfig.letterSpacing,
        'textOpacity': _wallpaperConfig.textOpacity,
        'shadowEnabled': _wallpaperConfig.shadowEnabled,
        'strokeEnabled': _wallpaperConfig.strokeEnabled,
        'edgeStrokeEnabled': _wallpaperConfig.edgeStrokeEnabled,
        'atmosphericDepthEnabled': _wallpaperConfig.atmosphericDepthEnabled,
        'rotation': _wallpaperConfig.rotation,
        'stretch': _wallpaperConfig.stretch,
        'horizontalSkew': _wallpaperConfig.horizontalSkew,
        'verticalSkew': _wallpaperConfig.verticalSkew,
        'bottomSkewH': _wallpaperConfig.bottomSkewH,
        'leftSkew': _wallpaperConfig.leftSkew,
        'backgroundPath': _wallpaperData.originalImagePath,
        'foregroundPath': _wallpaperData.foregroundImagePath,
        // Date Widget
        'showDate': _wallpaperConfig.showDate,
        'dateFontSize': _wallpaperConfig.dateFontSize,
        'dateHorizontalPos': _wallpaperConfig.dateHorizontalPos,
        'dateVerticalPos': _wallpaperConfig.dateVerticalPos,
        'dateColor': _wallpaperConfig.dateColor.toARGB32(),
        'dateFormat': _wallpaperConfig.dateFormat,
        'dateAllCaps': _wallpaperConfig.dateAllCaps,
        'dateBold': _wallpaperConfig.dateBold,
      });

      await _platform.invokeMethod('setWallpaper');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallpaper config saved! Select "Depth Wallpaper" in the system picker.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply wallpaper: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Capture preview thumbnail, serialize config, and upsert project to Hive.
  Future<void> _saveProject() async {
    setState(() => _isSaving = true);
    try {
      // Capture thumbnail from RepaintBoundary
      String? thumbPath;
      try {
        final boundary = _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            thumbPath = await FileManager()
                .saveThumbnail(byteData.buffer.asUint8List());
          }
        }
      } catch (_) {
        // Thumbnail capture failure is non-fatal
      }

      final now = DateTime.now();
      final existing = widget.project;
      final configJson = jsonEncode(_wallpaperConfig.toJson());

      final project = WallpaperProject(
        id: existing?.id ?? const Uuid().v4(),
        name: existing?.name ?? 'Wallpaper ${now.day}/${now.month}',
        createdAt: existing?.createdAt ?? now,
        modifiedAt: now,
        thumbnailPath: thumbPath ?? existing?.thumbnailPath,
        isActive: existing?.isActive ?? false,
        originalImagePath: _wallpaperData.originalImagePath,
        foregroundImagePath: _wallpaperData.foregroundImagePath,
        configJson: configJson,
      );

      await _repo.saveProject(project);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓  Project saved'),
            backgroundColor: Color(0xFF1E3A1E),
            duration: Duration(seconds: 2),
          ),
        );
        // Return to Home after short delay
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalImagePath = _wallpaperData.originalImagePath;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.project != null ? 'Edit Project' : 'Studio',
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded),
            tooltip: 'Select Image from Gallery',
            onPressed: _isLoading ? null : _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Settings',
            onPressed: _isLoading ? null : _resetSettings,
          ),
          // Save project button
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFFFD700)))
                : const Icon(Icons.save_rounded),
            tooltip: 'Save Project',
            onPressed: _isLoading || _isSaving || _wallpaperData.originalImagePath == null
                ? null
                : _saveProject,
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Apply Wallpaper',
            onPressed: _isLoading || originalImagePath == null ? null : _applyWallpaper,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Section 1: Preview Area (400dp height, phone-shaped container)
            Center(
              child: GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          SlidePageRoute(
                            child: PreviewScreen(
                              originalImagePath: originalImagePath,
                              foregroundImagePath: _wallpaperData.foregroundImagePath,
                              wallpaperConfig: _wallpaperConfig,
                            ),
                          ),
                        );
                      },
                child: SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        key: _previewKey,
                        child: WallpaperPreview(
                          data: _wallpaperData,
                          config: _wallpaperConfig,
                          showFrame: true,
                        ),
                      ),
                      // Semi-transparent indicator when loaded
                      if (originalImagePath != null)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tap to Preview',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Loading overlay indicator with dynamic text
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(24), // Match border radius of WallpaperPreview
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _loadingText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Section 2: Tab Bar (5 tabs)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((tabName) => Tab(text: tabName)).toList(),
            ),
            // Section 3: Tab Content Area (fills remaining space)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicsTab(),
                  _buildTypographyTab(),
                  _buildEffectsTab(),
                  _buildTransformTab(),
                  DateTab(
                    config: _wallpaperConfig,
                    onConfigChanged: (updated) => setState(() => _wallpaperConfig = updated),
                    isEnabled: _wallpaperData.originalImagePath != null,
                  ),
                  DateSettingsTab(
                    config: _wallpaperConfig,
                    onConfigChanged: (updated) => setState(() => _wallpaperConfig = updated),
                    isEnabled: _wallpaperData.originalImagePath != null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicsTab() {
    final bool isEnabled = _wallpaperData.originalImagePath != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Font Size',
            valueText: '${(_wallpaperConfig.fontSize * 100).toInt()}%',
            value: _wallpaperConfig.fontSize,
            min: 0.1,
            max: 0.5,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentPercent = (val * 100).toInt();
              final int previousPercent = (_wallpaperConfig.fontSize * 100).toInt();
              if (currentPercent != previousPercent) {
                HapticFeedback.selectionClick(); // Tactile tick for every 1% change
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(fontSize: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact(); // Strong tactile click when resetting parameter
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(fontSize: 0.24);
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSliderRow(
            label: 'Horizontal Position',
            valueText: '${(_wallpaperConfig.horizontalPos * 100).toInt()}%',
            value: _wallpaperConfig.horizontalPos,
            min: 0.0,
            max: 1.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentPercent = (val * 100).toInt();
              final int previousPercent = (_wallpaperConfig.horizontalPos * 100).toInt();
              if (currentPercent != previousPercent) {
                HapticFeedback.selectionClick(); // Tactile tick for every 1% change
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(horizontalPos: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact(); // Strong tactile click when resetting parameter
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(horizontalPos: 0.48);
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSliderRow(
            label: 'Vertical Position',
            valueText: '${(_wallpaperConfig.verticalPos * 100).toInt()}%',
            value: _wallpaperConfig.verticalPos,
            min: 0.0,
            max: 1.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentPercent = (val * 100).toInt();
              final int previousPercent = (_wallpaperConfig.verticalPos * 100).toInt();
              if (currentPercent != previousPercent) {
                HapticFeedback.selectionClick(); // Tactile tick for every 1% change
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(verticalPos: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact(); // Strong tactile click when resetting parameter
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(verticalPos: 0.24);
              });
            },
          ),
          if (!isEnabled) ...[
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Please select an image to unlock controls',
                style: TextStyle(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypographyTab() {
    final bool isEnabled = _wallpaperData.originalImagePath != null;

    final List<String> fonts = [
      'Roboto',
      'Outfit',
      'Inter',
      'Lilita One',
      'Rubik',
    ];

    final List<Map<String, dynamic>> colorSwatches = [
      {'name': 'Pure White', 'color': Colors.white},
      {'name': 'Cream', 'color': const Color(0xFFFFFDD0)},
      {'name': 'Warm Amber', 'color': const Color(0xFFFFB300)},
      {'name': 'Pastel Mint', 'color': const Color(0xFFA8E6CF)},
      {'name': 'Soft Sky Blue', 'color': const Color(0xFF95D8EB)},
      {'name': 'Rose Pink', 'color': const Color(0xFFFFB7B2)},
      {'name': 'Lavender', 'color': const Color(0xFFE8D7FF)},
      {'name': 'Highlight Yellow', 'color': const Color(0xFFFFF176)},
    ];

    TextStyle textStyleForFont(String fontName) {
      final base = const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600);
      if (fontName == 'Roboto') {
        return base.copyWith(fontFamily: 'Roboto');
      } else {
        try {
          return GoogleFonts.getFont(fontName, textStyle: base);
        } catch (e) {
          return base.copyWith(fontFamily: fontName);
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader(
            title: 'Font Family',
            isEnabled: isEnabled,
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(fontFamily: 'Roboto');
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fonts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final String font = fonts[index];
                final bool isSelected = _wallpaperConfig.fontFamily == font;

                return GestureDetector(
                  onTap: isEnabled
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _wallpaperConfig = _wallpaperConfig.copyWith(fontFamily: font);
                          });
                        }
                      : null,
                  child: Opacity(
                    opacity: isEnabled ? 1.0 : 0.5,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF2C2C2C),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          font,
                          style: textStyleForFont(font).copyWith(
                            color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader(
            title: 'Font Color',
            isEnabled: isEnabled,
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(fontColor: Colors.white);
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colorSwatches.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final Color swatchColor = colorSwatches[index]['color'] as Color;
                final String colorName = colorSwatches[index]['name'] as String;
                final bool isSelected = _wallpaperConfig.fontColor.toARGB32() == swatchColor.toARGB32();

                return GestureDetector(
                  onTap: isEnabled
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _wallpaperConfig = _wallpaperConfig.copyWith(fontColor: swatchColor);
                          });
                        }
                      : null,
                  child: Opacity(
                    opacity: isEnabled ? 1.0 : 0.5,
                    child: Tooltip(
                      message: colorName,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFD700)
                                : Colors.white.withValues(alpha: 0.15),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: swatchColor,
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.black87,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!isEnabled) ...[
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Please select an image to unlock controls',
                style: TextStyle(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isEnabled,
    required VoidCallback onReset,
  }) {
    final Color titleColor = isEnabled ? Colors.white : Colors.grey;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isEnabled)
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restore_rounded,
                size: 13,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEffectsTab() {
    final bool isEnabled = _wallpaperData.originalImagePath != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Text Opacity',
            valueText: '${(_wallpaperConfig.textOpacity * 100).toInt()}%',
            value: _wallpaperConfig.textOpacity,
            min: 0.0,
            max: 1.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentPercent = (val * 100).toInt();
              final int previousPercent = (_wallpaperConfig.textOpacity * 100).toInt();
              if (currentPercent != previousPercent) {
                HapticFeedback.selectionClick();
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(textOpacity: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(textOpacity: 1.0);
              });
            },
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            label: 'Enable Edge Stroke',
            subtitle: 'Adds outline to text for better visibility',
            value: _wallpaperConfig.edgeStrokeEnabled,
            isEnabled: isEnabled,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(edgeStrokeEnabled: val);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildToggleRow(
            label: 'Enable Shadow',
            subtitle: 'Applies drop shadow behind clock',
            value: _wallpaperConfig.shadowEnabled,
            isEnabled: isEnabled,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(shadowEnabled: val);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildToggleRow(
            label: 'Enable Stroke',
            subtitle: 'Different from edge stroke - filled outline effect',
            value: _wallpaperConfig.strokeEnabled,
            isEnabled: isEnabled,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(strokeEnabled: val);
              });
            },
          ),
          if (!isEnabled) ...[
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Please select an image to unlock controls',
                style: TextStyle(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransformTab() {
    final bool isEnabled = _wallpaperData.originalImagePath != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Rotation',
            valueText: '${_wallpaperConfig.rotation.toInt()}°',
            value: _wallpaperConfig.rotation,
            min: -180.0,
            max: 180.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentVal = val.toInt();
              final int previousVal = _wallpaperConfig.rotation.toInt();
              if (currentVal != previousVal) {
                HapticFeedback.selectionClick();
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(rotation: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(rotation: 0.0);
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSliderRow(
            label: 'Stretch',
            valueText: _wallpaperConfig.stretch.toStringAsFixed(2),
            value: _wallpaperConfig.stretch,
            min: 0.5,
            max: 2.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentVal = (val * 100).toInt();
              final int previousVal = (_wallpaperConfig.stretch * 100).toInt();
              if (currentVal != previousVal) {
                HapticFeedback.selectionClick();
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(stretch: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(stretch: 1.0);
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSliderRow(
            label: 'Horizontal Skew',
            valueText: _wallpaperConfig.horizontalSkew.toStringAsFixed(2),
            value: _wallpaperConfig.horizontalSkew,
            min: -1.0,
            max: 1.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentVal = (val * 100).toInt();
              final int previousVal = (_wallpaperConfig.horizontalSkew * 100).toInt();
              if (currentVal != previousVal) {
                HapticFeedback.selectionClick();
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(horizontalSkew: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(horizontalSkew: 0.0);
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSliderRow(
            label: 'Vertical Skew',
            valueText: _wallpaperConfig.verticalSkew.toStringAsFixed(2),
            value: _wallpaperConfig.verticalSkew,
            min: -1.0,
            max: 1.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentVal = (val * 100).toInt();
              final int previousVal = (_wallpaperConfig.verticalSkew * 100).toInt();
              if (currentVal != previousVal) {
                HapticFeedback.selectionClick();
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(verticalSkew: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(verticalSkew: 0.0);
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSliderRow(
            label: 'Bottom Skew H',
            valueText: _wallpaperConfig.bottomSkewH.toStringAsFixed(2),
            value: _wallpaperConfig.bottomSkewH,
            min: -1.0,
            max: 1.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentVal = (val * 100).toInt();
              final int previousVal = (_wallpaperConfig.bottomSkewH * 100).toInt();
              if (currentVal != previousVal) {
                HapticFeedback.selectionClick();
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(bottomSkewH: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(bottomSkewH: 0.0);
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSliderRow(
            label: 'Left Skew',
            valueText: _wallpaperConfig.leftSkew.toStringAsFixed(2),
            value: _wallpaperConfig.leftSkew,
            min: -1.0,
            max: 1.0,
            isEnabled: isEnabled,
            onChanged: (val) {
              final int currentVal = (val * 100).toInt();
              final int previousVal = (_wallpaperConfig.leftSkew * 100).toInt();
              if (currentVal != previousVal) {
                HapticFeedback.selectionClick();
              }
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(leftSkew: val);
              });
            },
            onReset: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _wallpaperConfig = _wallpaperConfig.copyWith(leftSkew: 0.0);
              });
            },
          ),
          if (!isEnabled) ...[
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Please select an image to unlock controls',
                style: TextStyle(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isEnabled ? Colors.white : Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isEnabled ? const Color(0xFFB0B0B0) : Colors.grey.shade600,
          fontSize: 11,
        ),
      ),
      value: value,
      onChanged: isEnabled ? onChanged : null,
      activeThumbColor: const Color(0xFFFFD700),
      activeTrackColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
      inactiveThumbColor: Colors.grey.shade400,
      inactiveTrackColor: const Color(0xFF2C2C2C),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required bool isEnabled,
    required ValueChanged<double> onChanged,
    required VoidCallback onReset,
  }) {
    final Color titleColor = isEnabled ? Colors.white : Colors.grey;
    final Color valColor = isEnabled ? const Color(0xFFFFD700) : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  style: TextStyle(
                    color: valColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isEnabled) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onReset,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restore_rounded, // Premium subtle restore icon
                        size: 13,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFFFD700),
            inactiveTrackColor: const Color(0xFF2C2C2C),
            overlayColor: const Color(0xFFFFD700).withValues(alpha: 0.12),
            trackHeight: 6, // Thicker track for modern UI feel
            thumbShape: const CustomSliderThumbShape(thumbRadius: 9), // Custom premium donut shape
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            disabledActiveTrackColor: Colors.grey.shade800,
            disabledInactiveTrackColor: Colors.grey.shade900,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: isEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

class CustomSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  const CustomSliderThumbShape({this.thumbRadius = 9.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final bool isEnabled = enableAnimation.value > 0.5;

    // Dynamic scale and glow factors based on activation (user press/drag)
    final double scale = 1.0 + (activationAnimation.value * 0.3); // Grows up to 30% larger
    final double currentRadius = thumbRadius * scale;

    // 1. Draw glowing translucent outer halo when active/dragging (alive feel)
    if (isEnabled && activationAnimation.value > 0.0) {
      final Paint haloPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.18 * activationAnimation.value)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, currentRadius * 1.6, haloPaint);
    }

    // 2. Draw outer thumb border (yellow if enabled, grey if disabled)
    final fillPaint = Paint()
      ..color = isEnabled ? const Color(0xFFFFD700) : Colors.grey.shade600
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, currentRadius, fillPaint);

    // 3. Draw inner dark center (donut shape) for premium aesthetic
    // Inner center scales with the thumb to maintain proportions
    final innerPaint = Paint()
      ..color = const Color(0xFF121212)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, currentRadius * 0.45, innerPaint);
  }
}

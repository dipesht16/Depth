import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/wallpaper_data.dart';
import '../services/file_manager.dart';
import '../services/segmentation_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/slide_page_route.dart';
import 'preview_screen.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WallpaperData _wallpaperData;
  bool _isLoading = false;
  String _loadingText = 'Loading image...';

  final List<String> _tabs = [
    'Basics',
    'Typography',
    'Effects',
    'Transform',
    'Date',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _wallpaperData = WallpaperData();
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
    try {
      final isGranted = await _checkAndRequestPermissions();
      if (!isGranted) return;

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Load original image for maximum quality
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

      setState(() {
        _loadingText = 'Detecting subject...';
      });

      // Run ML Kit Subject Segmentation on the saved image path
      final maskPath = await SegmentationService.segmentSubject(savedPath);

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
      setState(() {
        _isLoading = false;
      });
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
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace reset completed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalImagePath = _wallpaperData.originalImagePath;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Studio',
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
                            ),
                          ),
                        );
                      },
                child: Container(
                  height: 400,
                  width: 400 * (9 / 19.5), // Aspect ratio constraints for phone frame
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF424242),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22), // Fit within border
                    child: Stack(
                      children: [
                        // Background image rendering if loaded
                        if (originalImagePath != null)
                          Positioned.fill(
                            child: Image.file(
                              File(originalImagePath),
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          // Centered Placeholder Text and Icon when empty
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wallpaper_rounded,
                                  size: 48,
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap Gallery Icon',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'to select background image',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFB0B0B0),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Foreground isolated subject rendering if loaded
                        if (_wallpaperData.foregroundImagePath != null)
                          Positioned.fill(
                            child: Image.file(
                              File(_wallpaperData.foregroundImagePath!),
                              fit: BoxFit.cover,
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
                              color: Colors.black.withValues(alpha: 0.7),
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
                children: _tabs.map((tabName) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getTabIcon(tabName),
                          size: 40,
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$tabName Tab Placeholder',
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTabIcon(String tabName) {
    switch (tabName) {
      case 'Basics':
        return Icons.tune_rounded;
      case 'Typography':
        return Icons.text_fields_rounded;
      case 'Effects':
        return Icons.auto_awesome_rounded;
      case 'Transform':
        return Icons.transform_rounded;
      case 'Date':
        return Icons.calendar_today_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

import 'package:flutter/material.dart';
import '../models/wallpaper_data.dart';
import '../models/wallpaper_config.dart';
import '../widgets/wallpaper_preview.dart';

class PreviewScreen extends StatelessWidget {
  final String? originalImagePath;
  final String? foregroundImagePath;
  final WallpaperConfig? wallpaperConfig;

  const PreviewScreen({
    super.key,
    this.originalImagePath,
    this.foregroundImagePath,
    this.wallpaperConfig,
  });

  @override
  Widget build(BuildContext context) {
    // Package paths into WallpaperData for preview rendering
    final wallpaperData = WallpaperData(
      originalImagePath: originalImagePath,
      foregroundImagePath: foregroundImagePath,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full Screen preview rendered borderless (showFrame: false)
            Positioned.fill(
              child: WallpaperPreview(
                data: wallpaperData,
                config: wallpaperConfig ?? WallpaperConfig(),
                showFrame: false,
              ),
            ),
            // Close Button in Top-Right Corner (placed over image)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  tooltip: 'Close Preview',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            // Simulated Home Indicator (UX safe zone helper)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

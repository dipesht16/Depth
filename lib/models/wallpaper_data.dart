class WallpaperData {
  final String? originalImagePath;
  final String? backgroundImagePath;
  final String? foregroundImagePath;

  WallpaperData({
    this.originalImagePath,
    this.backgroundImagePath,
    this.foregroundImagePath,
  });

  // Helper method to create a copy of WallpaperData with modified values
  WallpaperData copyWith({
    String? originalImagePath,
    String? backgroundImagePath,
    String? foregroundImagePath,
  }) {
    return WallpaperData(
      originalImagePath: originalImagePath ?? this.originalImagePath,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      foregroundImagePath: foregroundImagePath ?? this.foregroundImagePath,
    );
  }

  // Clear all images
  WallpaperData clear() {
    return WallpaperData(
      originalImagePath: null,
      backgroundImagePath: null,
      foregroundImagePath: null,
    );
  }
}

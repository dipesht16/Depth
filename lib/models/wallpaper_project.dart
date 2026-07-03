import 'dart:convert';
import 'wallpaper_config.dart';

class WallpaperProject {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? thumbnailPath;
  final bool isActive;
  final String? originalImagePath;
  final String? foregroundImagePath;
  final String configJson; // Serialized WallpaperConfig

  const WallpaperProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    this.thumbnailPath,
    this.isActive = false,
    this.originalImagePath,
    this.foregroundImagePath,
    required this.configJson,
  });

  /// Deserialize WallpaperConfig from stored JSON string.
  WallpaperConfig get config {
    try {
      final map = jsonDecode(configJson) as Map<String, dynamic>;
      return WallpaperConfig.fromJson(map);
    } catch (_) {
      return WallpaperConfig(); // safe default
    }
  }

  WallpaperProject copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? thumbnailPath,
    bool? isActive,
    String? originalImagePath,
    String? foregroundImagePath,
    String? configJson,
  }) {
    return WallpaperProject(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isActive: isActive ?? this.isActive,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      foregroundImagePath: foregroundImagePath ?? this.foregroundImagePath,
      configJson: configJson ?? this.configJson,
    );
  }

  /// Convert to a plain map for Hive storage (Hive stores Maps natively).
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'thumbnailPath': thumbnailPath,
        'isActive': isActive,
        'originalImagePath': originalImagePath,
        'foregroundImagePath': foregroundImagePath,
        'configJson': configJson,
      };

  /// Restore a WallpaperProject from a Hive-stored map.
  factory WallpaperProject.fromMap(Map<dynamic, dynamic> map) {
    return WallpaperProject(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Untitled',
      createdAt: DateTime.parse(map['createdAt'] as String),
      modifiedAt: DateTime.parse(map['modifiedAt'] as String),
      thumbnailPath: map['thumbnailPath'] as String?,
      isActive: map['isActive'] as bool? ?? false,
      originalImagePath: map['originalImagePath'] as String?,
      foregroundImagePath: map['foregroundImagePath'] as String?,
      configJson: map['configJson'] as String? ?? '{}',
    );
  }
}

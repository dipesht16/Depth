import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/wallpaper_project.dart';
import 'file_manager.dart';

/// Hive-backed CRUD repository for WallpaperProject objects.
class ProjectRepository {
  static const String _boxName = 'projects';

  /// Open the Hive box. Call once at app startup.
  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  /// Correct dynamic sandbox directory prefix changes.
  Future<String?> _correctPath(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) return null;
    final fileName = p.basename(storedPath);
    final appDir = await FileManager.getAppDirectory();
    final newPath = p.join(appDir.path, fileName);
    if (File(newPath).existsSync()) {
      return newPath;
    }
    return storedPath; // fallback to original stored path
  }

  /// Return all projects sorted by modifiedAt descending (newest first).
  Future<List<WallpaperProject>> getAllProjects() async {
    final correctedProjects = <WallpaperProject>[];
    try {
      for (final val in _box.values) {
        try {
          final p = WallpaperProject.fromMap(val);
          final thumb = await _correctPath(p.thumbnailPath);
          final orig = await _correctPath(p.originalImagePath);
          final fore = await _correctPath(p.foregroundImagePath);
          correctedProjects.add(p.copyWith(
            thumbnailPath: thumb,
            originalImagePath: orig,
            foregroundImagePath: fore,
          ));
        } catch (_) {
          // Skip corrupted or old schema projects from earlier runs
        }
      }
    } catch (_) {
      // Fallback
    }

    correctedProjects.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return correctedProjects;
  }

  /// Upsert a project (insert if new, replace if id exists).
  Future<void> saveProject(WallpaperProject project) async {
    try {
      await _box.put(project.id, project.toMap());
    } catch (_) {}
  }

  /// Mark one project as active; clear all others.
  Future<void> setActive(String id) async {
    try {
      final all = await getAllProjects();
      for (final p in all) {
        final updated = p.copyWith(isActive: p.id == id);
        await _box.put(updated.id, updated.toMap());
      }
    } catch (_) {}
  }

  /// Duplicate a project by copying its database record and all associated files on disk.
  Future<void> duplicateProject(WallpaperProject project) async {
    try {
      final now = DateTime.now();

      final correctedOrig = await _correctPath(project.originalImagePath);
      final correctedFore = await _correctPath(project.foregroundImagePath);
      final correctedThumb = await _correctPath(project.thumbnailPath);

      final newOriginalPath = await _copyFile(correctedOrig, 'original');
      final newForegroundPath = await _copyFile(correctedFore, 'foreground');
      final newThumbnailPath = await _copyFile(correctedThumb, 'thumb');

      final copy = project.copyWith(
        id: const Uuid().v4(),
        name: '${project.name} Copy',
        createdAt: now,
        modifiedAt: now,
        isActive: false,
        thumbnailPath: newThumbnailPath,
        originalImagePath: newOriginalPath,
        foregroundImagePath: newForegroundPath,
      );

      await saveProject(copy);
    } catch (_) {}
  }

  Future<String?> _copyFile(String? sourcePath, String prefix) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    try {
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) return null;

      final wallpapersDir = await FileManager.getAppDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = const Uuid().v4().substring(0, 8);
      final fileExtension = p.extension(sourcePath).toLowerCase();
      final ext = fileExtension.isNotEmpty ? fileExtension : (prefix == 'original' ? '.jpg' : '.png');
      
      final newFileName = '${prefix}_${timestamp}_$uniqueId$ext';
      final destinationPath = p.join(wallpapersDir.path, newFileName);

      await sourceFile.copy(destinationPath);
      return destinationPath;
    } catch (_) {
      return null;
    }
  }

  /// Delete a project and its associated files from disk.
  Future<void> deleteProject(String id) async {
    try {
      final map = _box.get(id);
      if (map != null) {
        final project = WallpaperProject.fromMap(map);
        final correctedThumb = await _correctPath(project.thumbnailPath);
        final correctedOrig = await _correctPath(project.originalImagePath);
        final correctedFore = await _correctPath(project.foregroundImagePath);

        _deleteFileIfExists(correctedThumb);
        _deleteFileIfExists(correctedOrig);
        _deleteFileIfExists(correctedFore);
      }
      await _box.delete(id);
    } catch (_) {}
  }

  /// Get a single project by ID.
  Future<WallpaperProject?> getProject(String id) async {
    try {
      final map = _box.get(id);
      if (map == null) return null;
      final project = WallpaperProject.fromMap(map);
      return project.copyWith(
        thumbnailPath: await _correctPath(project.thumbnailPath),
        originalImagePath: await _correctPath(project.originalImagePath),
        foregroundImagePath: await _correctPath(project.foregroundImagePath),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the currently active project, or null.
  Future<WallpaperProject?> getActiveProject() async {
    try {
      final all = await getAllProjects();
      return all.firstWhere((p) => p.isActive);
    } catch (_) {
      return null;
    }
  }


  void _deleteFileIfExists(String? path) {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Silently ignore file deletion errors
    }
  }
}

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileManager {
  // Get App's private documents directory
  static Future<Directory> getAppDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final wallpapersDir = Directory(p.join(docsDir.path, 'wallpapers'));
    
    // Create the directory if it doesn't exist
    if (!await wallpapersDir.exists()) {
      await wallpapersDir.create(recursive: true);
    }
    
    return wallpapersDir;
  }

  // Copy selected XFile to app documents directory and return new path
  static Future<String> saveImage(XFile pickedFile) async {
    final wallpapersDir = await getAppDirectory();
    
    // Generate unique file name: original_[timestamp].[extension]
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = p.extension(pickedFile.path).toLowerCase();
    
    // Use fallback extension if empty
    final ext = fileExtension.isNotEmpty ? fileExtension : '.jpg';
    final newFileName = 'original_$timestamp$ext';
    
    final destinationPath = p.join(wallpapersDir.path, newFileName);
    
    // Copy file
    final sourceFile = File(pickedFile.path);
    final copiedFile = await sourceFile.copy(destinationPath);
    
    return copiedFile.path;
  }

  // Remove image file from storage
  static Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Get file size in bytes
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}

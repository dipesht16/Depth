import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'file_manager.dart';

class SegmentationService {
  // Process the original image using Google ML Kit Subject Segmentation
  // Returns the path to the transparent PNG foreground mask, or null if failed
  static Future<String?> segmentSubject(String imagePath) async {
    // Configure segmenter to only request the foreground bitmap
    // This is the most memory-efficient option for our layered wallpaper needs
    final options = SubjectSegmenterOptions(
      enableForegroundBitmap: true,
      enableForegroundConfidenceMask: false,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: false,
        enableSubjectBitmap: false,
      ),
    );

    final segmenter = SubjectSegmenter(options: options);
    final inputImage = InputImage.fromFilePath(imagePath);

    try {
      final result = await segmenter.processImage(inputImage);
      final bytes = result.foregroundBitmap;

      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      // Save PNG bytes to private storage
      final savedMaskPath = await FileManager.saveForegroundImage(bytes);
      return savedMaskPath;
    } catch (e) {
      // Return null to let the UI layer handle the error gracefully
      return null;
    } finally {
      // Always close segmenter to release native resources
      await segmenter.close();
    }
  }
}

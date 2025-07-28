import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service for managing video files for custom drills
/// Handles copying temporary files from image_picker to permanent storage
class VideoFileService {
  static final VideoFileService _instance = VideoFileService._internal();
  static VideoFileService get instance => _instance;
  VideoFileService._internal();

  final _uuid = const Uuid();

  /// Copy a temporary video file to permanent storage
  /// Returns the permanent file path, or null if the copy fails
  Future<String?> copyVideoToPermanentStorage(String tempVideoPath) async {
    try {
      if (kDebugMode) {
        print('🎬 [VideoFileService] Copying video to permanent storage');
        print('🎬 [VideoFileService] Temp path: $tempVideoPath');
      }

      // Check if temporary file exists
      final tempFile = File(tempVideoPath);
      if (!await tempFile.exists()) {
        if (kDebugMode) {
          print('❌ [VideoFileService] Temporary file does not exist: $tempVideoPath');
        }
        return null;
      }

      // Get app documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final videosDirectory = Directory('${documentsDirectory.path}/custom_drill_videos');
      
      // Create videos directory if it doesn't exist
      if (!await videosDirectory.exists()) {
        await videosDirectory.create(recursive: true);
        if (kDebugMode) {
          print('📁 [VideoFileService] Created videos directory: ${videosDirectory.path}');
        }
      }

      // Generate unique filename with extension
      final originalExtension = tempVideoPath.split('.').last.toLowerCase();
      final safeExtension = _validateVideoExtension(originalExtension);
      final uniqueId = _uuid.v4();
      final permanentFileName = 'custom_drill_$uniqueId.$safeExtension';
      final permanentPath = '${videosDirectory.path}/$permanentFileName';

      // Copy the file
      final permanentFile = await tempFile.copy(permanentPath);
      
      if (await permanentFile.exists()) {
        final fileSize = await permanentFile.length();
        if (kDebugMode) {
          print('✅ [VideoFileService] Video copied successfully!');
          print('🎬 [VideoFileService] Permanent path: $permanentPath');
          print('🎬 [VideoFileService] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');
        }
        return permanentPath;
      } else {
        if (kDebugMode) {
          print('❌ [VideoFileService] Failed to copy video file');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VideoFileService] Error copying video: $e');
      }
      return null;
    }
  }

  /// Validate and normalize video file extension
  String _validateVideoExtension(String extension) {
    const validExtensions = ['mov', 'mp4', 'm4v', 'avi'];
    final lowerExtension = extension.toLowerCase();
    
    if (validExtensions.contains(lowerExtension)) {
      return lowerExtension;
    }
    
    // Default to mp4 for unknown extensions
    return 'mp4';
  }

  /// Delete a permanently stored video file
  Future<bool> deletePermanentVideo(String videoPath) async {
    try {
      if (kDebugMode) {
        print('🗑️ [VideoFileService] Deleting permanent video: $videoPath');
      }

      // Only delete files in our custom drill videos directory for safety
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final videosDirectory = '${documentsDirectory.path}/custom_drill_videos';
      
      if (!videoPath.startsWith(videosDirectory)) {
        if (kDebugMode) {
          print('⚠️ [VideoFileService] Skipping deletion - file not in custom videos directory');
        }
        return false;
      }

      final file = File(videoPath);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('✅ [VideoFileService] Video deleted successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ [VideoFileService] Video file already deleted or not found');
        }
        return true; // Consider it successful if already deleted
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VideoFileService] Error deleting video: $e');
      }
      return false;
    }
  }

  /// Check if a video file exists at the given path
  Future<bool> doesVideoExist(String videoPath) async {
    try {
      if (videoPath.isEmpty) return false;
      
      final file = File(videoPath);
      return await file.exists();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VideoFileService] Error checking video existence: $e');
      }
      return false;
    }
  }

  /// Get the size of a video file in bytes
  Future<int> getVideoFileSize(String videoPath) async {
    try {
      final file = File(videoPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VideoFileService] Error getting video file size: $e');
      }
      return 0;
    }
  }

  /// Clean up old video files (for maintenance)
  Future<void> cleanupOldVideos({int maxAgeInDays = 30}) async {
    try {
      if (kDebugMode) {
        print('🧹 [VideoFileService] Cleaning up old videos (older than $maxAgeInDays days)');
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final videosDirectory = Directory('${documentsDirectory.path}/custom_drill_videos');
      
      if (!await videosDirectory.exists()) {
        return;
      }

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: maxAgeInDays));
      int deletedCount = 0;

      await for (final entity in videosDirectory.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      if (kDebugMode && deletedCount > 0) {
        print('🧹 [VideoFileService] Cleaned up $deletedCount old video files');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VideoFileService] Error during cleanup: $e');
      }
    }
  }
}
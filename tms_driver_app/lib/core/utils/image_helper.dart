// 📁 lib/core/utils/image_helper.dart

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../constants/app_config.dart';
import 'logger.dart';

/// Helper class for image processing and optimization
class ImageHelper {
  ImageHelper._();

  /// Compress an image file
  /// Returns the compressed file or original if compression fails
  static Future<File> compressImage(
    File file, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed${path.extension(file.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        Logger.warning('Image compression failed, using original');
        return file;
      }

      final originalSize = await file.length();
      final compressedSize = await result.length();
      final savedBytes = originalSize - compressedSize;
      final savedPercent = (savedBytes / originalSize * 100).toStringAsFixed(1);

      Logger.info(
        'Image compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} (saved $savedPercent%)',
        tag: 'ImageHelper',
      );

      return File(result.path);
    } catch (e) {
      Logger.error('Error compressing image: $e', tag: 'ImageHelper');
      return file;
    }
  }

  /// Check if file size exceeds maximum allowed
  static Future<bool> exceedsMaxSize(File file) async {
    final bytes = await file.length();
    final sizeMB = bytes / (1024 * 1024);
    return sizeMB > AppConfig.maxImageSizeMB;
  }

  /// Get human-readable file size
  static Future<String> getFileSize(File file) async {
    final bytes = await file.length();
    return _formatBytes(bytes);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validate image file
  static Future<String?> validateImage(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      return 'File does not exist';
    }

    // Check file extension
    final ext = path.extension(file.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      return 'Invalid image format. Supported: JPG, PNG, GIF, WebP';
    }

    // Check file size
    if (await exceedsMaxSize(file)) {
      return 'Image size exceeds ${AppConfig.maxImageSizeMB}MB limit';
    }

    return null; // Valid
  }

  /// Compress multiple images in parallel
  static Future<List<File>> compressMultiple(
    List<File> files, {
    int quality = 85,
  }) async {
    return Future.wait(
      files.map((file) => compressImage(file, quality: quality)),
    );
  }
}

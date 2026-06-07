import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageHelper {
  static Future<String?> saveImageLocally(String originalPath) async {
    try {
      final file = File(originalPath);
      final int sizeInBytes = await file.length();
      final double sizeInMb = sizeInBytes / (1024 * 1024);
      if (sizeInMb > 5) {
        throw Exception('File is too large. Max 5MB allowed.');
      }

      final String fileExtension = path.extension(originalPath).toLowerCase();
      if (fileExtension != '.jpg' && fileExtension != '.png' && fileExtension != '.jpeg') {
        throw Exception('Only JPG and PNG formats are allowed.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${const Uuid().v4()}$fileExtension';
      final String savedPath = path.join(directory.path, fileName);

      final File localImage = await file.copy(savedPath);
      return localImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static Future<String?> saveImageLocally(XFile pickedFile) async {
    try {
      final int sizeInBytes = await pickedFile.length();
      final double sizeInMb = sizeInBytes / (1024 * 1024);
      if (sizeInMb > 5) {
        throw Exception('File is too large. Max 5MB allowed.');
      }

      String fileExtension = path.extension(pickedFile.path).toLowerCase();
      if (fileExtension.isEmpty) fileExtension = '.jpg';
      
      if (fileExtension != '.jpg' && fileExtension != '.png' && fileExtension != '.jpeg') {
        throw Exception('Only JPG and PNG formats are allowed.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${const Uuid().v4()}$fileExtension';
      final String savedPath = path.join(directory.path, fileName);

      final bytes = await pickedFile.readAsBytes();
      final File localImage = File(savedPath);
      await localImage.writeAsBytes(bytes, flush: true);
      
      return localImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }
}

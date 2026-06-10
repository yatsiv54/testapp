import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageHelper {
  static late String _documentsDir;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _documentsDir = dir.path;
  }

  static String getAbsolutePath(String pathStr) {
    if (pathStr.isEmpty) return pathStr;
    final fileName = path.basename(pathStr);
    return path.join(_documentsDir, fileName);
  }

  static Future<String?> pickImage(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOption(
                      ctx,
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      source: ImageSource.camera,
                      color: Colors.blueAccent,
                    ),
                    _buildOption(
                      ctx,
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      source: ImageSource.gallery,
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return null;

    // Request permissions based on source
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
        return null;
      } else if (!status.isGranted) {
        return null;
      }
    } else {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return null;
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) return null;
      }
    }

    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        return await saveImageLocally(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
    return null;
  }

  static Widget _buildOption(BuildContext context, {required IconData icon, required String label, required ImageSource source, required Color color}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(source),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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

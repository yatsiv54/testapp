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

    // Explicit permission requests to throw to settings if rejected
    if (source == ImageSource.camera) {
      var status = await Permission.camera.status;
      if (status.isDenied) {
        status = await Permission.camera.request();
      }
      if (status.isPermanentlyDenied) {
        if (context.mounted) await _showSettingsDialog(context, 'Camera');
        return null;
      } else if (!status.isGranted) {
        return null; // Denied but not permanently
      }
    } else {
      if (Platform.isIOS) {
        var status = await Permission.photos.status;
        if (status.isDenied) {
          status = await Permission.photos.request();
        }
        if (status.isPermanentlyDenied) {
          if (context.mounted) await _showSettingsDialog(context, 'Photos');
          return null;
        } else if (!status.isGranted && !status.isLimited) {
          return null;
        }
      } else if (Platform.isAndroid) {
        // On Android 13+ (API 33+), image_picker uses Photo Picker which requires NO storage permissions.
        // On older Android, it might require storage. We'll use image_picker's native handling here 
        // to avoid falsely blocking Android 13+ users, but we will catch PlatformExceptions below.
      }
    }

    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        return await saveImageLocally(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        bool isDenied = e.toString().toLowerCase().contains('denied') || e.toString().toLowerCase().contains('permission');
        if (isDenied) {
           await _showSettingsDialog(context, source == ImageSource.camera ? 'Camera' : 'Photos');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
    return null;
  }

  static Future<void> _showSettingsDialog(BuildContext context, String feature) async {
    final goToSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Access Denied'),
        content: Text('Please grant access to $feature in Settings to use this functionality.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (goToSettings == true) {
      openAppSettings();
    }
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

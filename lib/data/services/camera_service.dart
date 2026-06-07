import 'package:camera/camera.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  List<CameraDescription> _cameras = [];

  Future<void> initialize() async {
    _cameras = await availableCameras();
  }

  List<CameraDescription> get cameras => _cameras;
}

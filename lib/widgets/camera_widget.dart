// lib/widgets/camera_widget.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

class CameraWidget extends StatefulWidget {
  final void Function(File?) onPhotoCaptured;
  final bool autoCapture;

  const CameraWidget({
    super.key,
    required this.onPhotoCaptured,
    this.autoCapture = false,
  });

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRearCamera = true;
  File? _capturedPhoto;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<String> _getPreuvesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final preuvesDir = Directory('${appDir.path}/preuves');
    if (!await preuvesDir.exists()) {
      await preuvesDir.create(recursive: true);
    }
    return preuvesDir.path;
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        print('❌ Aucune caméra disponible');
        return;
      }

      final cameraIndex = _isRearCamera ? 0 : _cameras!.length - 1;
      final camera = _cameras![cameraIndex];

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      if (widget.autoCapture && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _takePicture();
        });
      }
    } catch (e) {
      print('❌ Erreur initialisation caméra: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      final XFile picture = await _controller!.takePicture();
      final preuvesDir = await _getPreuvesDirectory();
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$preuvesDir/$fileName';

      final savedFile = await File(picture.path).copy(filePath);

      if (mounted) {
        setState(() {
          _capturedPhoto = savedFile;
          _isTakingPicture = false;
        });
        widget.onPhotoCaptured(savedFile);
      }
    } catch (e) {
      print('❌ Erreur prise de photo: $e');
      setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _retakePhoto() async {
    setState(() {
      _capturedPhoto = null;
    });
    widget.onPhotoCaptured(null);
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;

    setState(() {
      _isRearCamera = !_isRearCamera;
      _isInitialized = false;
    });

    await _controller?.dispose();
    await _initCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedPhoto != null) {
      return _buildPreview();
    }

    if (!_isInitialized) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
              ),
              SizedBox(height: 12),
              Text(
                'Initialisation caméra...',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CameraPreview(_controller!),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.coral.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Cadrez les colis et appuyez sur le bouton',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isTakingPicture ? null : _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.coral, width: 3),
                  ),
                  child: _isTakingPicture
                      ? const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                    ),
                  )
                      : const Icon(Icons.camera_alt, color: AppColors.coral, size: 32),
                ),
              ),
            ),
          ),
          if (_cameras != null && _cameras!.length > 1)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(_capturedPhoto!),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _retakePhoto,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Reprendre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusCours,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => widget.onPhotoCaptured(_capturedPhoto),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusLivree,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
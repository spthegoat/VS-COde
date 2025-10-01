import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gallery_saver/gallery_saver.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CameraController? controller;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller!.initialize();

      // Lock exposure and white balance
      await Future.wait([
        controller!.setExposureMode(ExposureMode.locked),
        controller!.setFocusMode(FocusMode.locked),
      ]);

      setState(() {
        isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      debugPrint("Camera error ${e.code} : ${e.description}");
    }
  }

  Future<void> _captureSeries() async {
    if (!isCameraInitialized || !controller!.value.isInitialized) return;

    try {
      for (int i = 0; i < 5; i++) {
        XFile file = await controller!.takePicture();
        await GallerySaver.saveImage(file.path);
        await Future.delayed(const Duration(milliseconds: 200));
      }
      debugPrint("Saved 5 images to gallery");
    } catch (e) {
      debugPrint("Error capturing or saving image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: isCameraInitialized
            ? Stack(
                children: [
                  CameraPreview(controller!),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                        onPressed: _captureSeries,
                        child: const Text("Capture 5 Images"),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
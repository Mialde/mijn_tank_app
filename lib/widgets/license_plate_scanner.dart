import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class LicensePlateScanner extends StatefulWidget {
  const LicensePlateScanner({super.key});

  @override
  State<LicensePlateScanner> createState() => _LicensePlateScannerState();
}

class _LicensePlateScannerState extends State<LicensePlateScanner> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isDetecting = false;
  bool _isInitialized = false;
  String? _detectedPlate;
  String _statusMessage = 'Initialiseren...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Check camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() => _statusMessage = 'Camera toegang geweigerd');
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _statusMessage = 'Geen camera gevonden');
        return;
      }

      // Initialize camera controller (back camera)
      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // For Android
      );

      await _cameraController!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Richt camera op kenteken';
      });

      // Start image stream for real-time detection
      _cameraController!.startImageStream(_processCameraImage);
      
    } catch (e) {
      setState(() => _statusMessage = 'Camera fout: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !mounted) return; // ← Check mounted
    _isDetecting = true;

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      // Recognize text
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Look for license plate patterns in recognized text
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
          
          // Dutch license plate patterns (6-8 characters, mix of letters and numbers)
          if (_isValidLicensePlate(text)) {
            if (!mounted) return; // ← Check before setState
            
            setState(() {
              _detectedPlate = text;
              _statusMessage = '✓ Kenteken gevonden: $text';
            });
            
            // Stop image stream immediately
            await _cameraController?.stopImageStream();
            
            // Wait a moment for user to see the detected plate
            await Future.delayed(const Duration(milliseconds: 800));
            
            // Return the result and close
            if (mounted) {
              Navigator.pop(context, text); // ← Return value directly
            }
            
            return; // Exit early
          }
        }
      }
    } catch (e) {
      print('OCR Error: $e');
    } finally {
      if (mounted) { // ← Check before setState
        _isDetecting = false;
      }
    }
  }

  bool _isValidLicensePlate(String text) {
    // Remove all non-alphanumeric characters
    final clean = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    // Dutch plates are 6-8 characters
    if (clean.length < 6 || clean.length > 8) return false;
    
    // Must contain both letters and numbers
    final hasLetters = RegExp(r'[A-Z]').hasMatch(clean);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(clean);
    
    if (!hasLetters || !hasNumbers) return false;
    
    // Common Dutch patterns (not exhaustive, but covers most)
    final patterns = [
      RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{2}$'),     // XX-99-XX
      RegExp(r'^[0-9]{2}[A-Z]{2}[0-9]{2}$'),     // 99-XX-99
      RegExp(r'^[A-Z]{2}[A-Z]{2}[0-9]{2}$'),     // XX-XX-99
      RegExp(r'^[0-9]{2}[0-9]{2}[A-Z]{2}$'),     // 99-99-XX
      RegExp(r'^[0-9]{2}[A-Z]{3}[0-9]{1}$'),     // 99-XXX-9
      RegExp(r'^[0-9]{1}[A-Z]{3}[0-9]{2}$'),     // 9-XXX-99
      RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{1}$'),     // XX-999-X
      RegExp(r'^[A-Z]{1}[0-9]{3}[A-Z]{2}$'),     // X-999-XX
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(clean));
  }

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      // Get image rotation
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;
      
      InputImageRotation? rotation;
      if (sensorOrientation == 90) {
        rotation = InputImageRotation.rotation90deg;
      } else if (sensorOrientation == 180) {
        rotation = InputImageRotation.rotation180deg;
      } else if (sensorOrientation == 270) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotation.rotation0deg;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      // Create InputImage
      final plane = image.planes.first;
      
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      print('Convert error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream().catchError((_) {
      // Image stream might already be stopped
    });
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Kenteken'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Center(
              child: CameraPreview(_cameraController!),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Overlay met scan gebied
          if (_isInitialized)
            CustomPaint(
              painter: _ScanOverlayPainter(),
              child: Container(),
            ),

          // Status text
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Detected plate preview
          if (_detectedPlate != null)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _detectedPlate!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: 120,
    );

    // Draw dark overlay everywhere except scan area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw scan area border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(12)),
      borderPaint,
    );

    // Draw corners
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
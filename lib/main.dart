import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(WasteClassifierApp(camera: firstCamera));
}

class WasteClassifierApp extends StatelessWidget {
  final CameraDescription camera;

  const WasteClassifierApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste Classifier',
      theme: ThemeData.dark(),
      home: ClassifierHomePage(camera: camera),
    );
  }
}

class ClassifierHomePage extends StatefulWidget {
  final CameraDescription camera;

  const ClassifierHomePage({super.key, required this.camera});

  @override
  State<ClassifierHomePage> createState() => _ClassifierHomePageState();
}

class _ClassifierHomePageState extends State<ClassifierHomePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<dynamic> _results = [];
  bool _loading = false;
  ui.Image? _loadedImage;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndClassify() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();
      final imageFile = File(image.path);
      final rawImage = await decodeImageFromList(await imageFile.readAsBytes());

      setState(() {
        _imageFile = imageFile;
        _loadedImage = rawImage;
        _results = [];
        _loading = true;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.12:8000/classify'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final json = jsonDecode(respStr);

        setState(() {
          _results = json['predictions'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to classify image')),
        );
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildImageWithBoxes() {
    if (_imageFile == null || _loadedImage == null) {
      return const Text('No image captured');
    }

    return FittedBox(
      child: SizedBox(
        width: _loadedImage!.width.toDouble(),
        height: _loadedImage!.height.toDouble(),
        child: CustomPaint(
          foregroundPainter: BoundingBoxPainter(
            image: _loadedImage!,
            results: _results,
          ),
          child: Image.file(_imageFile!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
                if (!_loading && _results.isNotEmpty)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: _buildImageWithBoxes(),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FloatingActionButton(
                      onPressed: _takePictureAndClassify,
                      child: const Icon(Icons.camera),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final ui.Image image;
  final List<dynamic> results;

  BoundingBoxPainter({required this.image, required this.results});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textStyle = TextStyle(
      color: Colors.greenAccent,
      fontSize: 16,
      backgroundColor: Colors.black54,
    );

    for (var result in results) {
      if (result.containsKey('box')) {
        final box = result['box'];
        final left = box['x'];
        final top = box['y'];
        final width = box['width'];
        final height = box['height'];

        final rect = Rect.fromLTWH(left, top, width, height);
        canvas.drawRect(rect, paint);

        final label = result['label'];
        final confidence = (result['confidence'] * 100).toStringAsFixed(1);
        final span = TextSpan(text: '$label ($confidence%)', style: textStyle);
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(left, top - tp.height));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


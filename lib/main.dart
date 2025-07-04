import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const WasteClassifierApp());
}

class WasteClassifierApp extends StatelessWidget {
  const WasteClassifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste Classifier',
      theme: ThemeData.dark(),
      home: const ClassifierHomePage(),
    );
  }
}

class ClassifierHomePage extends StatefulWidget {
  const ClassifierHomePage({super.key});

  @override
  State<ClassifierHomePage> createState() => _ClassifierHomePageState();
}

class _ClassifierHomePageState extends State<ClassifierHomePage> {
  File? _image;
  List<dynamic> _results = [];
  bool _loading = false;
  ui.Image? _loadedImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final rawImage = await decodeImageFromList(await imageFile.readAsBytes());

      setState(() {
        _image = imageFile;
        _loadedImage = rawImage;
        _results = [];
      });
      await _classifyImage(imageFile);
    }
  }

  Future<void> _classifyImage(File image) async {
    setState(() {
      _loading = true;
    });

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:8000/classify'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
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
  }

  Widget _buildImageWithBoxes() {
    if (_image == null || _loadedImage == null) {
      return const Text('No image selected');
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
          child: Image.file(_image!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Classifier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : _buildImageWithBoxes(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                  onPressed: () => _getImage(ImageSource.camera),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  onPressed: () => _getImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
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


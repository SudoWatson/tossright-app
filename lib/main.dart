import 'dart:convert';
import 'dart:io';

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

  final ImagePicker _picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _results = [];
      });
      await _classifyImage(_image!);
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

  Widget _buildResultList() {
    if (_results.isEmpty) return const Text('No results');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _results.map((result) {
        return Text(
          '${result['label']}: ${(result['confidence'] * 100).toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 18),
        );
      }).toList(),
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
            if (_image != null)
              Image.file(_image!, height: 200)
            else
              const Text('No image selected'),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : _buildResultList(),
            const Spacer(),
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

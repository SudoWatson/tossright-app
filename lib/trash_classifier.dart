import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TrashClassifier {
  late final Interpreter _interpreter;
  late final List<String> _labels;
  late final Map<String, String> _instructions;
  final int _inputSize = 224;
  final int _numClasses = 6;

  final String modelName = "";

  Future<void> loadModel() async {
    print("-----------------=======================================Test");
    print('models/$modelName');
    _interpreter = await Interpreter.fromAsset('assets/models/trashnet-quantized.tflite');
    _labels = ['cardboard', 'glass', 'metal', 'paper', 'plastic', 'trash'];
    _instructions = {
      'cardboard': "Break down then recycle.",
      'paper': "Can be recycled. If not colored or waxy, can also be composted.",
      'glass': "If intact, can be recycled. If broken, contain all pieces in several layers of garbage bags. Then clearly label as \"BROKEN GLASS\" before throwing into garbage.",
      'metal': "Rinse then recycle.",
      'plastic': "Make sure container is rinsed/cleaned and can be recycled.",
      'trash': "Throw in garbage.",
    };
  }

  Future<Map<String, dynamic>> classifyImage(File imageFile) async {
    // Load and preprocess image
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) {
      return {
        "label": "",
        "confidence": 0,
        "instruction": "",
        "Error": "Could not read image"
      };
    }

    final img.Image resizedImage = img.copyResize(image, width: _inputSize, height: _inputSize);
    Float32List normalizedImage = imageToByteListFloat32(resizedImage);

    final output = List.filled(_numClasses, 0.0).reshape([1, _numClasses]);
    _interpreter.run(normalizedImage.buffer, output);

    final confidences = output[0] as List<double>;
    int mostConfidentIndex = confidences.indexWhere((c) => c == confidences.reduce((a, b) => a > b ? a : b));
    String label = _labels[mostConfidentIndex];
    return {
      "label": label,
      "confidence": confidences[mostConfidentIndex],
      "instruction": _instructions[label]
    };
  }

  Float32List imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(_inputSize * _inputSize * 3);
    int pixelIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        img.Pixel pixel = image.getPixel(x, y);
        convertedBytes[pixelIndex++] = pixel.r / 255.0;
        convertedBytes[pixelIndex++] = pixel.g / 255.0;
        convertedBytes[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return convertedBytes;
  }
}

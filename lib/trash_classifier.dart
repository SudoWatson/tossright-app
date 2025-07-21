import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TrashClassifier {
  late final Interpreter _interpreter;
  late final List<String> _labels;
  late final Map<String, String> _instructions;
  final int _inputSize = 224;
  final int _numClasses = 6;

  final String modelName = "trashnet-quantized.tflite";

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('models/$modelName');
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

  Future<String> classifyImage(File imageFile) async {
    // Load and preprocess image
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) return "Error decoding image";

    final img.Image resizedImage = img.copyResize(image, width: _inputSize, height: _inputSize);

    TensorImage tensorImage = TensorImage.fromImage(resizedImage);
    tensorImage = TensorImage.fromTensorBuffer(TensorBuffer.createFromList(
      resizedImage.getBytes(format: img.Format.rgb),
      TfLiteType.uint8,
    ));

    final output = List.filled(_numClasses, 0.0).reshape([1, _numClasses]);
    _interpreter.run(tensorImage.buffer, output);

    final confidences = output[0] as List<double>;
    int mostConfidentIndex = confidences.indexWhere((c) => c == confidences.reduce((a, b) => a > b ? a : b));
    String label = _labels[mostConfidentIndex];
    return (label: label, confidence: confidences[mostConfidentIndex], instruction: instructions[label])
  }
}

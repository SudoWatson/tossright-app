import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';

final String API_ROOT = "http://192.168.0.59:8000";

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {

  // Setup camera
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.camera});

  final CameraDescription camera;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', camera: camera),
      navigatorObservers: [routeObserver]
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.camera});


  final String title;
  final CameraDescription camera;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RouteAware {
  late CameraController _camController;
  late Future<void> _initializeControllerFuture;

  String _id;
  List<dynamic> _results = [];

  int _counter = 0;
  bool showPreview = true;
  bool isLoading = false;

  ui.Image? _loadedImage;
  File? _imageFile;

  @override
  void initState() {
    super.initState();

    _camController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _camController.initialize();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _camController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // _camController.resumePreview();
    setState(() {
      showPreview = true;
    });
  }

  @override
  void didPushNext() {
    // Called when pushed to a different screen
    // _camController.pausePreview();
    setState(() {
      showPreview = false;
    });
  }

  Future<void> sendImage(String imagePath) async {
    final imageFile = File(imagePath);
    final rawImage = await decodeImageFromList(await imageFile.readAsBytes());

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(API_ROOT + '/classify'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', imagePath),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      setState(() {
        _imageFile = imageFile;
        _loadedImage = rawImage;
        _id = json['id'];
        _results = json['predictions'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to classify image')),
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (!isLoading && showPreview && snapshot.connectionState == ConnectionState.done) {
                  // If the Future is complete, display the preview.
                  return CameraPreview(_camController);
                } else {
                  // Otherwise, display a loading indicator.
                  return const Center(child: CircularProgressIndicator());
                }
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            final image = await _camController.takePicture();
            setState(() {
              isLoading = true;
            });

            if (!context.mounted) return;

            await sendImage(image.path);  // Send image to get classified and update results

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  widget: _buildImageWithBoxes(),
                ),
              ),
            );
          } catch (e) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ErrorScreen(
                  text: e.toString()
                ),
              ),
            );
            print(e);
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        },
        tooltip: 'Detect',
        child: const Icon(Icons.camera),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final Widget widget;

  const DisplayPictureScreen({super.key, required this.widget, });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection Results')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Column(
        children: <Widget>[
          widget,
        ]
      )
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String text;

  const ErrorScreen({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Text(text),
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

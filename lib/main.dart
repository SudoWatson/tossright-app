import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'trash_classifier.dart';

//final String API_ROOT = "http://192.168.0.59:8000";  // PC
final String API_ROOT = "http://192.168.0.107:10000";  // Mercury

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
      title: 'Waste Identifier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: MediaQuery.platformBrightnessOf(context),
          seedColor: Color(0xFF031601),
        ),
      ),
      home: MyHomePage(title: 'Waste Identifier', camera: camera),
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
  final TrashClassifier _trashClassifier = TrashClassifier();

  String _id = "";
  dynamic _results = ();

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
    _trashClassifier.loadModel();
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
    setState(() async {
      _imageFile = imageFile;
      _loadedImage = await decodeImageFromList(await imageFile.readAsBytes());
      _id = '3'; // json['id'];
      _results = _trashClassifier.classifyImage(imageFile);// json['predictions'];
    });
  }

  Future<void> _takePicture() async {
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
            results: _results,
            imagePath: image.path,
            id: _id,
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
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final previewWidth = size.width * 0.9;
    final previewHeight = previewWidth * 512 / 384;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (!isLoading && showPreview && snapshot.connectionState == ConnectionState.done) {
              // If the Future is complete, display the preview.
              return Column(
                children: <Widget>[
                  // Preview
                  Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: previewWidth,
                        height: previewHeight,
                        child:CameraPreview(_camController),
                      ),
                    ),
                  ),
                  // Shutter button
                  Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.camera,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              );
            } else {
              // Otherwise, display a loading indicator.
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final dynamic results;
  final String imagePath;
  final String id;

  const DisplayPictureScreen({super.key, required this.results, required this.imagePath, required this.id });

  void sendRequest (bool accurate) {
    final url = Uri.parse(API_ROOT + '/feedback');
    http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'accurate': accurate,
      }),
    );
    Fluttertoast.showToast(
      msg: "Thanks for your feedback!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey.shade800,
      textColor: Colors.white,
      fontSize: 16.0
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection Results')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: SafeArea( child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[

          Column(
            children: <Widget>[
              Image(
                image: FileImage(File(imagePath)),
                width: 224,
              ),
              Text(
                results.label[0].toUpperCase() + results.label.substring(1),  // Capitalize first letter
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Text(results.instruction),
              ),
            ]),


          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text("Are the results accurate?"),
              ),
              Row(
                children: <Widget>[
                  TextButton(
                    child: Text("Yes"),
                    onPressed: () { sendRequest(true);}
                  ),
                  TextButton(
                    child: Text("Something isn't quite right"),
                    onPressed: () { sendRequest(false); }
                  )
                ]
              ),
            ],
          ),
        ],
      ))
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

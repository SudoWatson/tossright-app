import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trash_classifier.dart';
import 'notices_screen.dart';

//final String API_ROOT = "http://192.168.0.59:8000";  // PC
//final String API_ROOT = "http://192.168.0.107:10000";  // Mercury
final String API_ROOT = "https://129.213.54.200:10000";  // Server

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.camera, required this.routeObserver});

  final String title;
  final CameraDescription camera;
  final RouteObserver<ModalRoute<void>> routeObserver;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RouteAware {
  late CameraController _camController;
  late Future<void> _initializeControllerFuture;
  final TrashClassifier _trashClassifier = TrashClassifier();

  dynamic _results = ();

  int _counter = 0;
  bool showPreview = true;
  bool isLoading = false;

  Future<String>? _uploadImageFuture = null;

  ui.Image? _loadedImage;
  File? _imageFile;

  @override
  void initState() {
    super.initState();

    // SharedPreferences.getInstance().then((prefs) => prefs.setBool('accepted_policy', false));  // Reset privacy policy viewed

    _camController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _camController.initialize();
    _trashClassifier.loadModel();
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    _camController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context)!);
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

  Future<String> uploadImage(String imagePath) async {
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
      return json['id'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to classify image')),
      );
      return "error";
    }
  }

  Future<void> classifyImage(String imagePath) async {
    final imageFile = File(imagePath);
    final rawImage = await decodeImageFromList(await imageFile.readAsBytes());
    final result = await _trashClassifier.classifyImage(imageFile);// json['predictions'];
    setState(() {
      _imageFile = imageFile;
      _loadedImage = rawImage;
      _results = result;
    });
    _uploadImageFuture = uploadImage(imagePath);
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final image = await _camController.takePicture();
      setState(() {
        isLoading = true;
      });

      if (!context.mounted) return;

      await classifyImage(image.path);  // Send image to get classified and update results

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            results: _results,
            imagePath: image.path,
            futureUpload: _uploadImageFuture
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
  final Future<String>? futureUpload;

  const DisplayPictureScreen({super.key, required this.results, required this.imagePath, required this.futureUpload });

  void sendRequest (bool accurate) async {
    final url = Uri.parse(API_ROOT + '/feedback');
    final id = await futureUpload;
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
                results["label"][0].toUpperCase() + results["label"].substring(1),  // Capitalize first letter
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Text(results["instruction"]),
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

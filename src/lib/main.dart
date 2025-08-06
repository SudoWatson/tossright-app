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
import 'home_screen.dart';

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

  Future<bool> hasAcceptedPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('accepted_policy') ?? false;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return FutureBuilder<bool>(
      future: hasAcceptedPolicy(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        bool hasAccepted = snapshot.data!;
        return MaterialApp(
          title: 'TossRight',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              brightness: MediaQuery.platformBrightnessOf(context),
              seedColor: Color(0xFF031601),
            ),
          ),
          home: hasAccepted
            ? MyHomePage(title: 'TossRight', camera: camera, routeObserver: routeObserver)
            : PrivacyScreen(buildAcceptedScreen: (_) => MyHomePage(title: 'TossRight', camera: camera, routeObserver: routeObserver)),
          navigatorObservers: [routeObserver]
        );
      }
    );
  }
}


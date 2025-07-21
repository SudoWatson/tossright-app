import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class PrivacyScreen extends StatelessWidget {
  final WidgetBuilder buildAcceptedScreen;

  const PrivacyScreen({super.key, required this.buildAcceptedScreen});

  Future<void> _acceptAndContinue(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_policy', true);

    // Go to home screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: buildAcceptedScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome")),
      body: SafeArea( child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "By using this app, you agree to the Privacy Policy and the terms of the open-source license. "
                  "The model may collect images for analysis, but nothing is sent to a server. "
                  "You retain full ownership of your photos. etc...",
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _acceptAndContinue(context),
              child: Text("I Agree"),
            ),
          ],
        ),
      )),
    );
  }
}

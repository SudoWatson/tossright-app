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
                  '''
Welcome to RightToss

By using this app, you agree to the following terms regarding data collection, privacy, and license transfer.

---

What We Collect
- When you take or select an image, it is uploaded to our server in the United States of America. This server may be a cloud server managed by a cloud hosting provider.
- If you submit feedback, it is stored alongside the image.
- We do not collect or store any information that can identify you: no names, emails, IP addresses, or device fingerprints.

---

How We Use Your Data
- Uploaded images and feedback may be stored in perpetuity and are used solely to train computer vision models.
- These models may be:
  - Used in commercial products,
  - Shared with research partners, or
  - Released publicly as open-source.

- Note that submitted images and/or feedback may be published, as original or modified, as part of an open-source training dataset, potentially accessible to the general public.

---

About Ownership & License
- You retain ownership of your images.
- By submitting an image and/or feedback, you grant us a non-exclusive, worldwide, royalty-free, perpetual, and irrevocable license to:
  - Use,
  - Reproduce,
  - Modify, and
  - Create derivative works from your image and/or feedback for the purpose of developing and distributing AI models.

---

No Deletion Requests Possible
- Because we do not collect identifying information, it is not technically possible to find or delete any specific user's images after upload.

---

User Age & Agreement
- You must be at least 13 years old (or older, depending on your country) to use this app.
- If you do not agree to these terms, or your country prevents this data from being stored on our servers, you must exit the app and stop using it.
- For any questions send an email to righttoss@pm.me

By continuing, you agree to these terms.
''',
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

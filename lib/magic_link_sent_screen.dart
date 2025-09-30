import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nyc_public_space_map/colors.dart';

class MagicLinkSentScreen extends StatelessWidget {
  final String email;

  const MagicLinkSentScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Magic Link Sent")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.envelope, size: 48,),
            const SizedBox(height: 16),
            const Text(
              'Magic Link Sent!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your inbox at $email.\n\n'
              'If you didn’t receive the email, try checking your spam folder or resend the link.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppStyles.buttonStyle,
              child: const Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}

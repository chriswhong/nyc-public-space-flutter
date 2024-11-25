import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nyc_public_space_map/magic_link_sent_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyc_public_space_map/colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();

  Future<void> _sendSignInLinkToEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    final actionCodeSettings = ActionCodeSettings(
      url:
          'https://nycpublicspaceapp.page.link/qL6j', // Replace with your dynamic link
      handleCodeInApp: true,
      iOSBundleId: 'com.nycpublicspace', // Replace with your iOS bundle ID
      androidPackageName:
          'com.nycpublicspace', // Replace with your Android package name
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      // Save the email to shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sign_in_email', email);

      // Navigate to success screen with the email
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MagicLinkSentScreen(email: email),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Sign in with your email address",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
                   const Text(
              "We will send a magic link to your email. Click the link to sign in.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendSignInLinkToEmail,
              style: AppStyles.buttonStyle,
              child: const Text("Send Magic Link"),
            ),
          ],
        ),
      ),
    );
  }
}

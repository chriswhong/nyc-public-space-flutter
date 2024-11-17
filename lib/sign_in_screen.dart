import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInScreen extends StatefulWidget {
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
        SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    final actionCodeSettings = ActionCodeSettings(
      url: 'https://nycpublicspaceapp.page.link/qL6j', // Replace with your dynamic link
      handleCodeInApp: true,
      iOSBundleId: 'com.nycpublicspace', // Replace with your iOS bundle ID
      androidPackageName: 'com.nycpublicspace', // Replace with your Android package name
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Magic link sent! Check your email.")),
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
      appBar: AppBar(title: Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendSignInLinkToEmail,
              child: Text("Send Magic Link"),
            ),
          ],
        ),
      ),
    );
  }
}

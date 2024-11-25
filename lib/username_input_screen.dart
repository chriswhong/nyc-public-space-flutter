import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:nyc_public_space_map/colors.dart';

class UsernameInputScreen extends StatefulWidget {
  final Function(String) onUsernameCreated;

  const UsernameInputScreen({super.key, required this.onUsernameCreated});

  @override
  UsernameInputScreenState createState() => UsernameInputScreenState();
}

class UsernameInputScreenState extends State<UsernameInputScreen> {
  final _usernameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Regex for username validation: letters, numbers, underscores, dashes
  final _usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');

  Future<void> _submitUsername() async {
    final username = _usernameController.text.trim();

    // Validate username length and format
    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Username cannot be empty.';
      });
      return;
    }

    if (username.length > 30) {
      setState(() {
        _errorMessage = 'Username cannot exceed 30 characters.';
      });
      return;
    }

    if (!_usernameRegex.hasMatch(username)) {
      setState(() {
        _errorMessage =
            'Username can only contain letters, numbers, underscores, and dashes.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not signed in.';
        _isSubmitting = false;
      });
      return;
    }

    try {
      // Check if the username already exists in the "usernames" collection
      final docRef =
          FirebaseFirestore.instance.collection('usernames').doc(username);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        setState(() {
          _errorMessage = 'That username is not available.';
          _isSubmitting = false;
        });
        return;
      }

      // Save the username to the "usernames" collection
      await docRef.set({
        'uid': user.uid,
      });

      // Save the username to the user's document in the "users" collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
      }, SetOptions(merge: true));

      // Notify the provider of the new username
      widget.onUsernameCreated(username);

      // Close the screen
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isSubmitting = false;
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

    Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Set Username'),
          automaticallyImplyLeading: false, // Hides the back arrow

        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              maxLength: 30, // Enforce maximum character limit
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
              ],
              decoration: InputDecoration(
                labelText: 'Username',
                errorText: _errorMessage,
                counterText:
                    '', // Hide the character counter below the text field
              ),
            ),
            const SizedBox(height: 20),
            if (_isSubmitting)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _submitUsername,
                style: AppStyles.buttonStyle,
                child: const Text('Submit'),
              ),
              const SizedBox(height: 20),
            TextButton(
              onPressed: _signOut,
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.dark, // Use a custom link color
                  decoration: TextDecoration.underline, // Underline the text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}

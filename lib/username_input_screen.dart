import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:nyc_public_space_map/colors.dart';

class UsernameInputScreen extends StatefulWidget {
  final Function(String) onUsernameCreated;

  const UsernameInputScreen({Key? key, required this.onUsernameCreated})
      : super(key: key);

  @override
  _UsernameInputScreenState createState() => _UsernameInputScreenState();
}

class _UsernameInputScreenState extends State<UsernameInputScreen> {
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
          _errorMessage = 'Username is already taken.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Set Username')),
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
                child: const Text('Submit'),
                style: AppStyles.buttonStyle,
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsernameInputScreen extends StatefulWidget {
  @override
  _UsernameInputScreenState createState() => _UsernameInputScreenState();
}

class _UsernameInputScreenState extends State<UsernameInputScreen> {
  final _usernameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<bool> _isUsernameUnique(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<void> _submitUsername() async {
    final username = _usernameController.text.trim();

    print('username');
    print(username);

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Username cannot be empty.';
      });
      return;
    }
    print('one');

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    print('two');

    // final isUnique = await _isUsernameUnique(username);

    // if (!isUnique) {
    //   setState(() {
    //     _errorMessage = 'Username is already taken.';
    //     _isSubmitting = false;
    //   });
    //   return;
    // }

    print('checking user');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not signed in.';
        _isSubmitting = false;
      });
      return;
    }

    if (user != null) {
      print('User is signed in with UID: ${user.uid}');
    } else {
      print('No user is signed in.');
      return;
    }

    try {
      final docRef =
          FirebaseFirestore.instance.collection('usernames').doc(username);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        print('Username already exists.');
        setState(() {
          _errorMessage = 'Username is already taken.';
          _isSubmitting = false;
        });
        throw Exception('Username already exists.');
      } else {
        await docRef.set({
          'uid': user.uid,
        });
        print('Username saved successfully.');
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
      }, SetOptions(merge: true));

      Navigator.pop(context);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Username')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                errorText: _errorMessage,
              ),
            ),
            SizedBox(height: 20),
            if (_isSubmitting)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _submitUsername,
                child: Text('Submit'),
              ),
          ],
        ),
      ),
    );
  }
}

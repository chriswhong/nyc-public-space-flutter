import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';

class UserProvider with ChangeNotifier {
  String? _username;
  bool _isAuthenticated = false;

  String? get username => _username;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> fetchUserData(BuildContext context, User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc['username'] != null) {
        _username = userDoc['username'];
      } else {
        _username = null;
        // Navigate to the UsernameInputScreen if no username exists
        navigatorKey.currentState?.pushNamed('/username_input');

      }

      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> initializeAuth(BuildContext context) async {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await fetchUserData(context, user);
      } else {
        _isAuthenticated = false;
        _username = null;
        notifyListeners();
      }
    });
  }

    // Set the username in local state only
  void setUsernameLocally(String? username) {
    _username = username;
    notifyListeners();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _isAuthenticated = false;
    _username = null;
    notifyListeners();
  }
}

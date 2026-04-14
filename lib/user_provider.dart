import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'main.dart';

class UserProvider with ChangeNotifier {
  String? _username;
  bool _isAuthenticated = false;
  bool _isEditor = false;

  String? get username => _username;
  bool get isAuthenticated => _isAuthenticated;
  bool get isEditor => _isEditor;

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

      // Check for editor role via custom claims
      final idTokenResult = await user.getIdTokenResult(true);
      final wasEditor = _isEditor;
      _isEditor = idTokenResult.claims?['role'] == 'editor';

      // Subscribe/unsubscribe from admin FCM topic based on role
      if (_isEditor && !wasEditor) {
        await FirebaseMessaging.instance.subscribeToTopic('admin-notifications');
        debugPrint('Subscribed to admin-notifications topic');
      } else if (!_isEditor && wasEditor) {
        await FirebaseMessaging.instance.unsubscribeFromTopic('admin-notifications');
        debugPrint('Unsubscribed from admin-notifications topic');
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
        _isEditor = false;
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
    if (_isEditor) {
      await FirebaseMessaging.instance.unsubscribeFromTopic('admin-notifications');
    }
    await FirebaseAuth.instance.signOut();
    _isAuthenticated = false;
    _username = null;
    _isEditor = false;
    notifyListeners();
  }
}

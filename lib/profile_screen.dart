import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nyc_public_space_map/sign_in_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ),
            StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Show a loading indicator while waiting for the auth state
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    // User is signed in
                    final user = snapshot.data!;
                    return _buildSignedInContent(context, user);
                  } else {
                    // User is not signed in
                    return _buildSignInButton(context);
                  }
                },
              ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildSignedInContent(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'User:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.uid, // Display the user's UID
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _signOut(context), // Sign-out logic
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Button color
              foregroundColor: Colors.white, // Text color
              fixedSize: const Size(double.infinity, 50), // Full-width button
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

Widget _buildSignInButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: SizedBox(
      width: double.infinity, // Ensures the button is full width
      child: ElevatedButton(
        onPressed: () {
          // Navigate to the Sign In screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignInScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xAA77bb3f), // Button color
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(vertical: 16), // Adjust vertical padding
        ),
        child: const Text(
          'Sign In',
          style: TextStyle(fontSize: 16), // Adjust font size
        ),
      ),
    ),
  );
}

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed out')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
}

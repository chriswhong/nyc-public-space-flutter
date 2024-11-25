import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

import 'user_provider.dart';
import 'sign_in_screen.dart';
import 'colors.dart';
import 'feedback_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // if (!userProvider.isAuthenticated || userProvider.username == null) {
    //   return Scaffold(
    //     backgroundColor: AppColors.pageBackground,
    //     body: Center(
    //       child: _buildSignInButton(context),
    //     ),
    //   );
    // }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
                  color: AppColors.dark,
                ),
              ),
            ),
            Expanded(
              child: _buildSignedInContent(context, userProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserButtonGroup(
      BuildContext context, UserProvider userProvider) {
    if (!userProvider.isAuthenticated || userProvider.username == null) {
      return ProfileButtonGroup(buttons: [
        ProfileButton(
          text: 'Sign in',
          icon: FontAwesomeIcons.user,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SignInScreen(),
              ),
            );
          },
        ),
      ]);
    }

    return ProfileButtonGroup(buttons: [
      ProfileButton(
        textWidget: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Signed in as ',
                style:
                    TextStyle(color: Colors.black, fontSize: 16), // Normal text
              ),
              TextSpan(
                text: userProvider.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16,
                ), // Bold username
              ),
            ],
          ),
        ),
        icon: FontAwesomeIcons.user,
        onTap: () => {},
        showChevron: false,
      ),
      ProfileButton(
        text: 'Sign out',
        icon: FontAwesomeIcons.arrowRightFromBracket,
        onTap: () async {
          final shouldSignOut = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                backgroundColor: AppColors.pageBackground,
                actions: [
                  TextButton(
                    style: AppStyles.buttonStyle,
                    onPressed: () => Navigator.of(context).pop(false), // Cancel
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    style: AppStyles.buttonStyle,
                    onPressed: () => Navigator.of(context).pop(true), // Confirm
                    child: const Text('Sign Out'),
                  ),
                ],
              );
            },
          );

          if (shouldSignOut == true) {
            await userProvider.signOut();
          }
        },
        showChevron: false, // No chevron for this button
      ),
    ]);
  }

  Widget _buildSignedInContent(
      BuildContext context, UserProvider userProvider) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // // Top third with username and icon
          // Expanded(
          //   flex: 1,
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           const Icon(Icons.person, size: 40, color: Colors.black),
          //           const SizedBox(width: 8),
          //           Text(
          //             username,
          //             style: const TextStyle(
          //               fontSize: 32,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          _buildUserButtonGroup(context, userProvider),
          SizedBox(height: 20),
          ProfileButtonGroup(buttons: [
            ProfileButton(
                text: 'Rate the app',
                icon: FontAwesomeIcons.star,
                onTap: () => {}),
            ProfileButton(
                text: 'Send Feedback',
                icon: FontAwesomeIcons.envelope,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedbackScreen(),
                    ),
                  );
                }),
            ProfileButton(
                text: 'Share the app',
                icon: FontAwesomeIcons.shareFromSquare,
                onTap: () => {}),
          ]),
          SizedBox(height: 20),
          ProfileButtonGroup(buttons: [
            ProfileButton(
                text: 'Privacy Policy',
                icon: FontAwesomeIcons.star,
                onTap: () => {
                      launchUrl(Uri.parse(
                          'https://sites.google.com/view/nyc-public-space-privacy/home'))
                    }),
            ProfileButton(
                text: 'Terms of Service',
                icon: FontAwesomeIcons.envelope,
                onTap: () => {})
          ]),

          // // Button with margin
          // Expanded(
          //   flex: 2,
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.start,
          //     children: [
          //       const SizedBox(height: 16),
          //       SizedBox(
          //         width: double.infinity,
          //         child: OutlinedButton(
          //           onPressed: () => ,
          //           style: OutlinedButton.styleFrom(
          //             side: const BorderSide(color: Colors.red, width: 2),
          //             padding: const EdgeInsets.symmetric(vertical: 14),
          //           ),
          //           child: const Text(
          //             'Sign Out',
          //             style: TextStyle(
          //               fontSize: 16,
          //               fontWeight: FontWeight.bold,
          //               color: Colors.red,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SignInScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class ProfileButtonGroup extends StatelessWidget {
  final List<ProfileButton> buttons;

  const ProfileButtonGroup({required this.buttons, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: buttons.asMap().entries.map((entry) {
          int index = entry.key;
          ProfileButton button = entry.value;

          return Column(
            children: [
              if (index != 0) const Divider(height: 1, thickness: 1),
              button,
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  final String? text; // Optional plain text
  final Widget? textWidget; // Optional custom widget for more complex layouts
  final IconData icon;
  final VoidCallback onTap;
  final bool showChevron;

  const ProfileButton({
    this.text,
    this.textWidget,
    required this.icon,
    required this.onTap,
    this.showChevron = true,
    Key? key,
  })  : assert(text != null || textWidget != null,
            'Either text or textWidget must be provided'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(icon, size: 20),
                  const SizedBox(width: 16),
                  // Use textWidget if provided, otherwise display plain text
                  textWidget ??
                      Text(text!, style: const TextStyle(fontSize: 16)),
                ],
              ),
              if (showChevron)
                const FaIcon(FontAwesomeIcons.chevronRight, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
